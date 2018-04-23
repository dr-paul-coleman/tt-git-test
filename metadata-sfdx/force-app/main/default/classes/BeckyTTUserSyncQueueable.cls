/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/5/17      paulcoleman      Created class to sync remote tt user records to Accounts
                                            (& Contacts by Trigger action)
                                         NOTE: Test code coverage is handled by AccountTriggerHandlerTest
1.1       01/26/18     kristinhasna     Added Managed account fields to sync to Account
========+============+=================+===============================================*/
public without sharing class BeckyTTUserSyncQueueable implements Queueable
{
    private static final Integer BATCH_SIZE = Integer.valueOf(Label.BeckyTTUserSyncBatchSize);

    private Map<Id,Account> thumbtackAccounts;
    private Set<Decimal> thumbtackUserIds;
    private Set<Decimal> thumbtackUserPKIds;
    private Set<String> thumbtackUserEmails;

    public BeckyTTUserSyncQueueable(Account[] accounts)
    {
        Account[] tempAccounts = (null == accounts)? new Account[0]: accounts;
        this.thumbtackAccounts = new Map<Id,Account>();
        this.thumbtackUserEmails = new Set<String>();
        this.thumbtackUserIds = new Set<Decimal>();
        this.thumbtackUserPKIds = new Set<Decimal>();

        for(Account a: tempAccounts)
        {
            if(null != a) //only include non-null list values
            {
                this.thumbtackAccounts.put( a.Id, a.clone(true) ); // Clone records to isolate from TRIGGER Events
            }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-11
    * @description Synchronize Thumbtack User details between Salesforce and the Data platform.
    * @parm Account[] A batch of Accounts to sync.
    * @parm Account[] A list of Accounts to update after sync.
    */
    private void doBatch(  Account[] batch, Account[] recordsForUpdate )
    {
        this.thumbtackUserEmails.clear();
        this.thumbtackUserIds.clear();
        this.thumbtackUserPKIds.clear();
        for( Account a: batch )
        {
            //parse out unique values needed for remote object SOQL WHERE clauses
            if (null != a.usr_email__c && null == a.usr_user_id__c && null == a.user_pk_id__c)
            {
                this.thumbtackUserEmails.add(a.usr_email__c);
            }
            if (null != a.usr_user_id__c && null == a.user_pk_id__c)
            {
                this.thumbtackUserIds.add(a.usr_user_id__c);
            }
            if (null != a.user_pk_id__c)
            {
                this.thumbtackUserPKIds.add(Decimal.valueOf(a.user_pk_id__c));
            }
        }

        try
        {
            Datetime now = DateTime.now();
            for ( becquerel_tt_user_for_tack__x ttuser : ( BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalUsers( 1, true ) : [ SELECT Id,usr_user_id__c,user_pk_id__c,usr_timezone__c,sav_business_name__c,phn_phone_number__c,usr_email__c,usr_first_name__c,usr_last_name__c,sav_phn_phone_number__c,sav_notif_phn_phone_number__c,managed_account__c,revenue__c FROM becquerel_tt_user_for_tack__x WHERE usr_user_id__c IN :this.thumbtackUserIds OR usr_email__c IN :this.thumbtackUserEmails OR user_pk_id__c IN :this.thumbtackUserPKIds LIMIT 2000 ] ) )
            {
                for ( Account acc : batch )
                {
                    String pkId = ( null == ttuser.user_pk_id__c ) ? '-1' : String.valueOf( ttuser.user_pk_id__c );
                    if ( pkId == acc.user_pk_id__c || ttuser.usr_user_id__c == acc.usr_user_id__c || ttuser.usr_email__c == acc.usr_email__c )
                    {
                        acc.SyncedWithBequerel__c = true;
                        acc.LastSyncedWithDataPlatform__c = now;
                        acc.Name = ( null != ttuser.sav_business_name__c ) ? ttuser.sav_business_name__c.left( 80 ) : ( ttuser.usr_first_name__c + ' ' + ttuser.usr_last_name__c ).left( 80 );
                        acc.Phone = ttuser.phn_phone_number__c;
                        acc.usr_user_id__c = ttuser.usr_user_id__c;
                        acc.user_pk_id__c = String.valueOf( ttuser.user_pk_id__c );
                        acc.usr_first_name__c = ttuser.usr_first_name__c;
                        acc.usr_last_name__c = ttuser.usr_last_name__c;
                        acc.usr_email__c = ttuser.usr_email__c;
                        acc.usr_timezone__c = ttuser.usr_timezone__c;
                        acc.sav_notifications_phn_phone_number__c = ttuser.sav_notif_phn_phone_number__c;
                        acc.ManagedAccount__c = ttuser.managed_account__c;
                        acc.ManagedAccountRevenue__c = ttuser.revenue__c;
                        recordsForUpdate.add( acc.clone(true) );
                        break;
                    }
                }
            }

        }
        catch ( System.ExternalObjectException ex )
        {
            System.debug(LoggingLevel.ERROR, ex); // skip HTTP 50x Errors when trying to do oData queries
            if( !ex.getMessage().contains( 'Error received from the external system: 50')) { TackBotUtility.sendExceptionEmail( ex, 'BeckyTTUserSyncQueueable.execute()' ); }
        }
        catch ( System.UnexpectedException ex )
        {
            System.debug(LoggingLevel.ERROR, ex);
            if( !ex.getMessage().contains( 'Apex triggers can\'t reference external objects or call out to external data sources' ) ) { TackBotUtility.sendExceptionEmail( new ExternalObjectException(ex.getMessage()), 'BeckyTTUserSyncQueueable.execute()' ); }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-11
    * @description Synchronize Thumbtack User details between Salesforce and the Data platform.
    * @parm QueueableContext Context object, not used here.
    */
    public void execute(QueueableContext context)
    {
            // remote object SOQL query (outbound HTTP), mocked for test runs
            // LIMIT of 2000 on the external object query is arbitrary
            // as of this writing external objects cannot be used within Trigger execution contexts
            if( !Trigger.isExecuting )
            {
                Account[] recordsForUpdate = new Account[0];
                Account[] batch = new Account[0];
                for( Account a: this.thumbtackAccounts.values() )
                {
                    batch.add(a);
                    if( BATCH_SIZE == batch.size() )
                    {
                        this.doBatch( batch, recordsForUpdate );
                        batch.clear();
                    }
                }

                if( !batch.isEmpty() ) // any leftovers?
                {
                    this.doBatch( batch, recordsForUpdate );
                }

                // UPSERT Accounts w/All-Or-None = false, serialize save results to execution log for root-cause analysis if req'd
                // UPSERT here because this utility might be used for record inserts as well, e.g., in the BeckyMTSIncidentSyncQueueable
                if( !recordsForUpdate.isEmpty() )
                {
                    System.debug(LoggingLevel.FINEST, JSON.serialize(Database.upsert(recordsForUpdate, false)));
                }
            }

    }
}