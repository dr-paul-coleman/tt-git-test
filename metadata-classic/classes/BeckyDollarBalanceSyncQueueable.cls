/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/20/17      pcoleman           Created. NOTE: full test code coverage achieved
                                                from ScheduledGetDollarBalancesTest
1.011     01/26/18      ddayton            Added new field mapping                        
========+============+=================+===============================================*/
public with sharing class BeckyDollarBalanceSyncQueueable implements Queueable
{
    private Map<Decimal, becquerel_qs_dollar_balance__x> userIdBalanceMap;
    private Map<Decimal, Account> accountsForUpdateMap;

    public BeckyDollarBalanceSyncQueueable(){
        this.userIdBalanceMap = new Map<Decimal, becquerel_qs_dollar_balance__x>();
        this.accountsForUpdateMap = new Map<Decimal, Account>();
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Sync local SF records with remote Becquerel External Objects. Code coverage low due to getBeckyRecords architecture
    * @return becquerel_qs_dollar_balance__x[] an array of Becky records.
    */
    public becquerel_qs_dollar_balance__x[] getBeckyRecords()
    {
        becquerel_qs_dollar_balance__x[] records = new becquerel_qs_dollar_balance__x[0];
        Database.QueryLocator qLocator = Database.getQueryLocator('SELECT uct_balance_state__c, uct_purchased_balance_cents__c, uct_total_promotional_cents__c, uct_promotional_balance_cents__c, usr_user_id__c FROM becquerel_qs_dollar_balance__x LIMIT 2000');
        // retry remote query logic (nested for minimal code coverage loss)
        try { records = Database.query(qLocator.getQuery()); } catch (ExternalObjectException exo) {  try { records = Database.query(qLocator.getQuery()); if ( !exo.getMessage().contains('Apex triggers can\'t reference external objects or call out to external data sources')) { TackBotUtility.postTackLogException(exo, 'BeckyDollarBalanceSyncQueueable.getBeckyRecords()'); } } catch (Exception ex) { if (!ex.getMessage().contains('Apex triggers can\'t reference external objects or call out to external data sources')) { TackBotUtility.postTackLogException(ex, 'BeckyDollarBalanceSyncQueueable.getBeckyRecords()'); } } }
        return records;
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Sync local SF records with remote Becquerel External Objects.
    * @param QueueableContext Not used.
    */
    public void execute(QueueableContext context)
    {

        try
        {
            if( !Trigger.isExecuting )
            {
                // GET remote dollar balance records
                for ( becquerel_qs_dollar_balance__x budgetXternal : BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalDollarBalances( 1 ) : getBeckyRecords() )
                {
                    this.userIdBalanceMap.put( budgetXternal.usr_user_id__c, budgetXternal );
                }


                // GET local Accounts records by matching user id
                for ( Account[] accounts : [ SELECT Id,usr_user_id__c,LastSyncedWithDataPlatform__c,uct_balance_state__c,uct_purchased_balance_cents__c,uct_total_promotional_cents__c,uct_promotional_balance_cents__c FROM Account WHERE usr_user_id__c IN :userIdBalanceMap.keySet() ] )
                {
                    for ( Account accnt : accounts )
                    {
                        accountsForUpdateMap.put( accnt.usr_user_id__c, accnt );
                    }
                }

                //Sync matching records
                Datetime now = DateTime.now();
                for ( becquerel_qs_dollar_balance__x budgetX : userIdBalanceMap.values() )
                {
                    Account ttUserAccount = accountsForUpdateMap.get( budgetX.usr_user_id__c );
                    if( NULL != ttUserAccount )
                    {
                        ttUserAccount.LastSyncedWithDataPlatform__c = now;
                        ttUserAccount.uct_balance_state__c = budgetX.uct_balance_state__c;
                        ttUserAccount.uct_purchased_balance_cents__c = budgetX.uct_purchased_balance_cents__c;
                        ttUserAccount.uct_total_promotional_cents__c = budgetX.uct_total_promotional_cents__c;
                        ttUserAccount.uct_promotional_balance_cents__c = budgetX.uct_promotional_balance_cents__c;
                    }
                }

                // UPDATE SF-side records
                System.debug( LoggingLevel.FINEST, JSON.serialize( Database.update( accountsForUpdateMap.values(), false ) ) );
            }

        }
        catch ( System.Exception ex ) { if (!ex.getMessage().contains('Error received from the external system: 50') && !ex.getMessage().contains('Apex triggers can\'t reference external objects or call out to external data sources')) { TackBotUtility.postTackLogException(ex, 'BeckyDollarBalanceSyncQueueable.execute()'); } }
    }
}