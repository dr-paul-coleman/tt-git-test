/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/5/17      paulcoleman          Created. NOTE: full test code coverage achieved
                                                from ScheduledGetQuoteTest
========+============+=================+===============================================*/
public without sharing class BeckyMTSIncidentSyncQueueable implements Queueable
{
    public static final Id MI_CASE_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
    public static final Id MI_RECORD_TYPE_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    public static final Id CONFIDENTIAL_RECORD_TYPE_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
    public static final Set<Id> TARGET_RECORD_TYPE_IDS = new Set<Id> {MI_RECORD_TYPE_ID, CONFIDENTIAL_RECORD_TYPE_ID};

    private Set<Decimal> bidIdsThatAreNotClosed; //for oData remote queries
    private Map<Decimal, MIIncident__c> mtsIncidents;
    private Map<Decimal, becquerel_mi_incident_project_data__x> externalMiRecords;

    public BeckyMTSIncidentSyncQueueable( MIIncident__c[] incidents )
    {
        // place constructor parm in temporary array to de-dupe and de-NULL
        MIIncident__c[] tempIncidents = ( NULL == incidents ) ? new MIIncident__c[0] : incidents;
        this.mtsIncidents = new Map<Decimal,MIIncident__c>();
        this.bidIdsThatAreNotClosed = new Set<Decimal>();
        for ( MIIncident__c incident : tempIncidents )
        {
            //only add incidents that are not NULL. Decimal conversion for Incident SOQL
            if (NULL != incident && NULL != incident.bid_id__c )
            {
                Decimal bidId = Decimal.valueOf(incident.bid_id__c);
                this.mtsIncidents.put( bidId, incident.clone(true) ); // Clone records to isolate from TRIGGER Events
                if( !'Closed'.equals( incident.Status__c ) ) { this.bidIdsThatAreNotClosed.add(bidId); }
            }
        }

        this.externalMiRecords = new Map<Decimal,becquerel_mi_incident_project_data__x>();
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Sync local SF records with remote Becquerel External Objects.
    * @param QueueableContext Standard q parm, not used here.
    */
    public void execute( QueueableContext context )
    {
        try
        {
            if ( !Trigger.isExecuting )
            {
                for ( becquerel_mi_incident_project_data__x externalIncident : ( BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalIncidents( 1 ) : [ SELECT bid_id__c, pro_quotes_last_30__c, pro_num_reviews__c, customer_id__c, customer_email__c, pro_email__c, pro_user_id__c, pro_user_pk_id__c, customer_pk_id__c, most_recent_phone_number__c, hired__c, request_create_time__c, request_id__c, service_id__c, customer_first_name__c, customer_last_name__c, pro_first_name__c, pro_last_name__c, request_category__c, pro_signup_date__c, hired_time__c FROM becquerel_mi_incident_project_data__x WHERE bid_id__c IN :this.bidIdsThatAreNotClosed LIMIT 2000 ] ) )
                {
                    if ( !BecquerelUtility.IS_TEST_RUN )
                    {
                        System.debug( LoggingLevel.FINE, 'EXTERNAL INCIDENT: ' + JSON.serialize( externalIncident ) );
                    }

                    // save external incidents for later access to Pro/Customer First names
                    this.externalMiRecords.put( externalIncident.bid_id__c, externalIncident );
                    MIIncident__c incidentUpdate = this.mtsIncidents.get( externalIncident.bid_id__c );

                    // 1] update matching incident records with remote object data
                    if ( NULL != incidentUpdate )
                    {
                        // cloning MIIncident for update, not uncessarily updating records that may not have a remote match
                        incidentUpdate.Name = ( 'Incident for ' + externalIncident.customer_first_name__c + ' ' + externalIncident.customer_last_name__c ).left( 80 );
                        incidentUpdate.CustomerName__c = (externalIncident.customer_first_name__c + ' ' + externalIncident.customer_last_name__c).left(50);
                        incidentUpdate.service_id__c = String.valueOf( externalIncident.service_id__c );
                        incidentUpdate.request_id__c = String.valueOf( externalIncident.request_id__c );
                        incidentUpdate.request_category__c = externalIncident.request_category__c;
                        incidentUpdate.request_create_time__c = externalIncident.request_create_time__c;
                        incidentUpdate.quotes_hired__c = externalIncident.hired__c;
                        incidentUpdate.pro_user_id__c = String.valueOf( externalIncident.pro_user_id__c );
                        incidentUpdate.customer_id__c = String.valueOf( externalIncident.customer_id__c );
                        incidentUpdate.ProEmail__c = externalIncident.pro_email__c;
                        incidentUpdate.ProPhone__c = externalIncident.most_recent_phone_number__c;
                        incidentUpdate.CustomerEmail__c = externalIncident.customer_email__c;
                        incidentUpdate.ProfessionalName__c = (externalIncident.pro_first_name__c + ' ' + externalIncident.pro_last_name__c).left(50);
                        incidentUpdate.pro_signup_date__c = externalIncident.pro_signup_date__c.date();
                        incidentUpdate.pro_quotes_last_30__c = String.valueOf( externalIncident.pro_quotes_last_30__c );
                        incidentUpdate.pro_num_reviews__c = String.valueOf( externalIncident.pro_num_reviews__c );
                        incidentUpdate.hired_time__c = externalIncident.hired_time__c;
                        incidentUpdate.ExternalQuoteData__c = String.valueOf( externalIncident.bid_id__c );
                        // TODO FUTURE: add pk user id sync when MIIncident__c has the field
                        //incidentUpdate.pro_user_pk_id__c = String.valueOf(externalIncident.pro_user_pk_id__c);
                        //incidentUpdate.customer_pk_id__c = String.valueOf(externalIncident.customer_pk_id__c);

                        // incident record updates occur in finally block below (last step)
                    }
                }
            }

            try
            {
                // 2] UPSERT the related MTS Accounts (creating missing accounts if necessary)
                Account[] allMIAccounts = this.doAccountProcessing();

                // 3] CREATE MI Cases when they do not exist
                this.doCaseProcessing( allMIAccounts );

            }
            finally
            {
                // 4] UPDATE matching MTS Incident records with field updates, even if account or case processing fails
                //    MI UPDATE IS LAST because doAccountProcessing() and doCaseProcessing() may update the Pro/Contact Account and Contact field values
                //    DML UPDATE ONLY OCCURS within the Queueable (remote query context) to allow BEFORE MI INCIDENT TRIGGER EVENT processing
                if( !this.externalMiRecords.isEmpty() )
                {
                    if( System.isQueueable() )
                    {
                        System.debug( LoggingLevel.FINEST, JSON.serialize( Database.update( this.mtsIncidents.values(), false ) ) );
                    }
                    else
                    {
                        System.enqueueJob(new DMLQueueable( this.mtsIncidents.values(), DMLQueueable.Operation.UPDATES ));
                    }
                }
            }

        }
        catch ( System.ExternalObjectException ex )
        {
            System.debug(LoggingLevel.ERROR, ex); // skip HTTP 504 Errors when trying to do oData queries
            if( !ex.getMessage().contains( 'Error received from the external system: 50')) { TackBotUtility.sendExceptionEmail( ex, 'BeckyMTSIncidentSyncQueueable.execute()' ); }
        }
        catch ( System.UnexpectedException ex )
        {
            System.debug(LoggingLevel.ERROR, ex);
            if( !ex.getMessage().contains( 'Apex triggers can\'t reference external objects or call out to external data sources' ) ){ TackBotUtility.sendExceptionEmail( new ExternalObjectException(ex.getMessage()), 'BeckyMTSIncidentSyncQueueable.execute()' ); }
        }

    } // END execute


    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Assign Accounts to MI record fields, creating missing Accounts if necessary. Recursion supported.
    * @return Account[] The aggregate list of processed Accounts with related child Contact.
    * */
    public Account[] doAccountProcessing() {

        //query existing accounts, ensures user_id assignment if necessary
        Map<String, Account> ttuserIdToAccountMap = this.getExistingAccounts();

        //create missing accounts, if any
        this.getMissingAccounts(ttuserIdToAccountMap); //missing accounts will be added to the map after insert

        // loop MI records for Account assignment rules
        for ( MIIncident__c miForAccountDML : this.mtsIncidents.values() )
        {
            String proUserId =  ( NULL == miForAccountDML.pro_user_id__c )? '-3' : miForAccountDML.pro_user_id__c;
            String customerUserId = ( NULL == miForAccountDML.customer_id__c ) ? '-4' : miForAccountDML.customer_id__c;
            Account proAccount = ttuserIdToAccountMap.get(proUserId);
            Account customerAccount = ttuserIdToAccountMap.get(customerUserId);
            Boolean isProFound = ( NULL != proAccount );
            Boolean isCustomerFound = ( NULL != customerAccount );

            // 2.1] check for an existing account assignment, missing accounts should have been
            // inserted in the getMissingAccounts() function call, unless A DML error occurred
            if ( this.needsAccountAssignment( miForAccountDML ) )
            {
                // 2.2.1] see if pro user Account exists
                if ( isProFound && NULL == miForAccountDML.ProAccount__c  )
                {
                    setMIAccount( miForAccountDML, proAccount );
                }

                // 2.2.2] see if customer user Account exists
                if ( isCustomerFound && NULL == miForAccountDML.CustomerAccount__c )
                {
                    setMIAccount( miForAccountDML, customerAccount );
                }
            }
        }

        // 2.3] do Account DML
        String emailBody = '';
        Account[] retries = new Account[0];
        Integer accountIndex = 0;
        for( Database.SaveResult updateResult: Database.update( ttuserIdToAccountMap.values(),false ) )
        {
            // Check for any created Accounts, reprocess if necessary
            if( !updateResult.isSuccess() )
            {
                retries.add( ttuserIdToAccountMap.values()[accountIndex] );
                String errorStr = ( updateResult.getErrors().isEmpty()? '' : updateResult.getErrors()[0].getMessage() );
                emailBody += errorStr + ( ''.equals(errorStr)? '' : '<br/>' );
                System.debug(LoggingLevel.ERROR, 'New MTS Account UPDATE FAILED. ' +  errorStr);
            }
            accountIndex++;
        }

        if( !retries.isEmpty() )
        {
            try
            {
                QueueableUtility.handleQueueable(new DMLQueueable(retries, DMLQueueable.Operation.UPDATES));
            } catch( Exception exc ){
                TackBotUtility.postTackLogException(exc, 'BeckyMTSIncidentSyncQueueable.doAccountProcessing');
            }
        }
        // 2.4] After DML, return Account => Contact resultset for Case processing
        return ttuserIdToAccountMap.values();
    }



    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Find MTS-related Accounts, making sure each has a usr_user_id and pk id (some accounts are created only with usr_email)
    * @return Map<String,Account> accounts by userid Map.
    * */
    private Map<String, Account> getExistingAccounts()
    {
        Map<String, Account> accountResultMap = new Map<String, Account>();
        Account[] ttusersEmailOnly = new Account[0];

        //GATHER ACCOUNT LOOKUP CRITERIA
        Decimal[] ttUserIds = new Decimal[0];
        String[] ttUserPkIds = new String[0];
        String[] ttUserEmails = new String[0];

        // get SOQL WHERE-filter Parms
        for ( MIIncident__c miForAccountDML : this.mtsIncidents.values() )
        {
            // LOOKUP VARS
            Decimal customerId;
            Decimal proId;
            String customerPkId;
            String proPkId;
            String customerEmail;
            String proEmail;

            // REMOTE EXTERNAL RECORD
            if ( !Trigger.isExecuting )
            {
                becquerel_mi_incident_project_data__x externalBid = this.externalMiRecords.get( Decimal.valueOf( miForAccountDML.bid_id__c ) );
                if ( NULL != externalBid )
                {
                    customerId = ( NULL == externalBid.customer_id__c ) ? -1 : externalBid.customer_id__c;
                    proId = ( NULL == externalBid.pro_user_id__c ) ? -2 : externalBid.pro_user_id__c;
                    ttUserIds.addAll( new Decimal[] { customerId, proId } );

                    // collect user pk ids for Account soql
                    customerPkId = ( NULL == externalBid.customer_pk_id__c ) ? '-5' : String.valueOf( externalBid.customer_pk_id__c );
                    proPkId = ( NULL == externalBid.pro_user_pk_id__c ) ? '-6' : String.valueOf( externalBid.pro_user_pk_id__c );
                    ttUserPkIds.addAll( new String[] { customerPkId, proPkId } );

                    // collect usr email addrs for Account soql
                    customerEmail = ( NULL == externalBid.customer_email__c ) ? 'no email' : externalBid.customer_email__c;
                    proEmail = ( NULL == externalBid.pro_user_pk_id__c ) ? 'no email' : externalBid.pro_email__c;
                    ttUserEmails.addAll( new String[] { customerEmail, proEmail } );
                }
            }
            else
            {
                customerId = ( NULL == miForAccountDML.customer_id__c ) ? -7 : Decimal.valueOf( miForAccountDML.customer_id__c );
                proId = ( NULL == miForAccountDML.pro_user_id__c ) ? -8 : Decimal.valueOf( miForAccountDML.pro_user_id__c );
                ttUserIds.addAll( new Decimal[] { customerId, proId } );

                // TODO FUTURE: collect user pk ids for Account soql (NOT YET ADDED TO MIIncident__c
                // customerPkId = ( NULL == miForAccountDML.customer_pk_id__c ) ? '-9' : String.valueOf( miForAccountDML.customer_pk_id__c );
                // proPkId = ( NULL == miForAccountDML.pro_user_pk_id__c ) ? '-10' : String.valueOf( miForAccountDML.pro_user_pk_id__c );
                // ttUserPkIds.addAll( new String[] { customerPkId, proPkId } );

                // collect usr email addrs for Account soql
                customerEmail = ( NULL == miForAccountDML.CustomerEmail__c ) ? 'no email' : miForAccountDML.CustomerEmail__c;
                proEmail = ( NULL == miForAccountDML.ProEmail__c ) ? 'no email' : miForAccountDML.ProEmail__c;
                ttUserEmails.addAll( new String[] { customerEmail, proEmail } );
            }
        }


        if( BecquerelUtility.IS_TEST_RUN ) { System.debug(LoggingLevel.INFO, 'Account filter lists from MI records:\n' + JSON.serialize(ttUserIds)+'\n'+JSON.serialize(ttUserPkIds)+'\n'+JSON.serialize(ttUserEmails)); }
        // gather usr_user_id => Account map and email => Account list for Accounts with matching email but no user_id (yet)
        for ( Account accnt : this.getAccountsBySOQL(ttUserPkIds, ttUserEmails, ttUserIds, NULL) )
        {
            // TODO FUTURE: shift to pk id
            // if Account was created with only an email value (e.g., email to case), try to do a Becky sync to pull in user id/pk field values
            if( NULL != accnt.usr_user_id__c ) { accountResultMap.put( String.valueOf(accnt.usr_user_id__c), accnt );  } else { ttusersEmailOnly.add( accnt ); }
        }


        if( !ttusersEmailOnly.isEmpty() && System.isQueueable() ) {
            // attempt to sync accounts with becquerel to make sure the accounts have user ids assigned (for accounts that only have email addresses when created)
            // Run the normal TT USER => Account Sync to try and set the Missing User Id and User PK Id values on the email-only Accounts
            new BeckyTTUserSyncQueueable( ttusersEmailOnly ).execute(NULL);
            for ( Account newSyncedAccount :  this.getAccountsBySOQL( null, null, null, ttusersEmailOnly ) ) { if( NULL != newSyncedAccount.usr_user_id__c ) { accountResultMap.put( String.valueOf(newSyncedAccount.usr_user_id__c), newSyncedAccount ); } }
        }

        return accountResultMap;
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Get the Accounts => Contact Pro/Customer user with required field list.
    * @param Map<String,Account> accounts by userid Map.
    * */
    private Account[] getAccountsBySOQL( String[] pkIds, String[] emailAddrs, Decimal[] userIds, Account[] ttusersEmailOnly )
    {
        Map<Id,Account> result = new Map<Id,Account>();  //use a map to ensure a unqiue account array is returned
        Boolean isTTUserLookup = ( NULL != ttusersEmailOnly );
        Set<String> uniquePkIds = new Set<String>();
        Set<Decimal> uniqueUserIds = new Set<Decimal>();
        Set<String> uniqueEmailAddrs = new Set<String>();
        Set<Id> scrubbedAccountIds = new Set<Id>();
        if( !isTTUserLookup )
        {
            // gather unique lookup values for maximizing Account matching by three critical identifiers
            for (String pkid : pkIds) { if ( !String.isBlank(pkid) && pkid.isNumeric() && Long.valueOf(pkid) > 0 ) { uniquePkIds.add(pkid); } }
            for (Decimal userId : userIds) { if (NULL != userId && userId > 0) { uniqueUserIds.add(userId); } }
            for ( String email : emailAddrs )
            {
                if ( !String.isBlank( email ) )
                {
                    uniqueEmailAddrs.add( email );
                }
            }

            // Using 3 selective Account queries here instead of one query with three OR clauses (Non-selectivity was a frequent problem)
            // large data volume for-each List/Array SOQL pattern
            for ( Account[] emailAccounts : [ SELECT Id, usr_user_id__c, usr_email__c, user_pk_id__c, ( SELECT Id FROM Contacts ) FROM Account WHERE usr_email__c IN :uniqueEmailAddrs LIMIT :uniqueEmailAddrs.size() ] )
            {
                for ( Account emailAccount : emailAccounts )
                {
                    result.put( emailAccount.Id, emailAccount );
                }
            }

            if( !uniqueUserIds.isEmpty() )
            {
                for ( Account[] userIdAccounts : [ SELECT Id, usr_user_id__c, usr_email__c, user_pk_id__c, ( SELECT Id FROM Contacts ) FROM Account WHERE usr_user_id__c IN :uniqueUserIds LIMIT :uniqueUserIds.size() ] )
                {
                    for( Account userIdAccount : userIdAccounts )
                    {
                        result.put( userIdAccount.Id, userIdAccount );
                    }
                }
            }

            if( !uniquePkIds.isEmpty() )
            {
                for ( Account[] pkAccounts : [ SELECT Id, usr_user_id__c, usr_email__c, user_pk_id__c, ( SELECT Id FROM Contacts ) FROM Account WHERE user_pk_id__c IN :uniquePkIds LIMIT :uniquePkIds.size() ] )
                {
                    for( Account pkAccount : pkAccounts )
                    {
                        result.put( pkAccount.Id, pkAccount );
                    }
                }
            }

        }
        else
        {
            // This query is for Accounts that have only usr email values (probably created by Email To Case services).
            // These accounts are sent to the BeckyTTUser sync to try and resolve their email address to a user id
            for( Account a: ttusersEmailOnly ) { if( NULL != a && NULL != a.Id ) { scrubbedAccountIds.add(a.Id); } }
            if( !scrubbedAccountIds.isEmpty() )
            {
                for ( Account[] accounts : [ SELECT Id, usr_user_id__c, usr_email__c, user_pk_id__c, ( SELECT Id FROM Contacts ) FROM Account WHERE Id IN :scrubbedAccountIds LIMIT :scrubbedAccountIds.size() ] )
                {
                    for( Account accnt : accounts )
                    {
                        result.put( accnt.Id, accnt );
                    }
                }
            }
        }
        return result.values();
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Find MTS records that are missing Accounts, create them, and pass them back for ProAccount/CustomerAccount assignment.
    * @param Map<String,Account> accounts by userid Map.
    * */
    private Account[] getMissingAccounts(Map<String,Account> existingAccounts)
    {

        Id accountProRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accountCustomerRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account[] newAccounts = new Account[0];

        // loop MI records for missing accounts
        for ( MIIncident__c miForAccountDML : this.mtsIncidents.values() )
        {
            becquerel_mi_incident_project_data__x externalBid = this.externalMiRecords.get(Decimal.valueOf(miForAccountDML.bid_id__c));

            String proUserId =  ( NULL == miForAccountDML.pro_user_id__c )? '-2' : miForAccountDML.pro_user_id__c;
            String customerUserId = ( NULL == miForAccountDML.customer_id__c ) ? '-2' : miForAccountDML.customer_id__c;
            Account proAccount = existingAccounts.get(proUserId);
            Account customerAccount = existingAccounts.get(customerUserId);
            Boolean isProFound = ( NULL != proAccount );
            Boolean isCustomerFound = ( NULL != customerAccount );
            String proName = ( NULL == miForAccountDML.ProfessionalName__c ) ? miForAccountDML.Name : miForAccountDML.ProfessionalName__c.left(80);
            String customerName = ( NULL == miForAccountDML.CustomerName__c ) ? miForAccountDML.Name : miForAccountDML.CustomerName__c.left(80);

            // 2.1] check for an existing account assignment, if there is not one, then create a new account
            if ( this.needsAccountAssignment( miForAccountDML ) )
            {

                // 2.2.1] see if pro user Account exists
                if ( NULL == miForAccountDML.ProAccount__c && !isProFound && !'-2'.equals( proUserId ) )
                {
                    Account newProAccount = new Account( RecordTypeId = accountProRtId, Name = proName, usr_user_id__c = Integer.valueOf(proUserId), usr_email__c = miForAccountDML.ProEmail__c, MIOpenIncident__c = true);
                    String[] proNames = proName.split(' ');
                    newProAccount.usr_first_name__c = ( NULL == externalBid )? ((proNames.size() > 1)? proNames[0]: '') : externalBid.pro_first_name__c;
                    Integer proLastNamePos = proName.indexOf(' ');
                    newProAccount.usr_last_name__c = ( NULL == externalBid )? ( (proNames.size() > 1)? proName.substring(proLastNamePos): proName) : externalBid.pro_last_name__c;
                    newAccounts.add(newProAccount);
                }

                // 2.2.2] see if customer user Account exists
                if ( NULL == miForAccountDML.CustomerAccount__c && !isCustomerFound && !'-2'.equals( customerUserId ) )
                {
                    Account newCustomerAccount = new Account( RecordTypeId = accountCustomerRtId, Name = customerName, usr_user_id__c = Integer.valueOf(customerUserId), usr_email__c = miForAccountDML.CustomerEmail__c, MIOpenIncident__c = true);
                    String[] customerNames = customerName.split(' ');
                    newCustomerAccount.usr_first_name__c = ( NULL == externalBid )? ( (customerNames.size() > 1)? customerNames[0]: '' ) : externalBid.customer_first_name__c;
                    Integer customerLastNamePos = customerName.indexOf(' ');
                    newCustomerAccount.usr_last_name__c = ( NULL == externalBid )? ( (customerNames.size() > 1)? customerName.substring(customerLastNamePos): customerName ) : externalBid.customer_last_name__c;
                    newAccounts.add(newCustomerAccount);
                }
            }
        }

        // insert new accounts
        Integer accountIndex = 0;
        String dmlErrorEmailBody = '';
        List<Account> newAccountList = new List<Account>();
        for( Database.SaveResult insertResult: Database.insert(newAccounts,false) )
        {
            // Check for any created Accounts, reprocess if necessary
            if( insertResult.isSuccess() )
            {
                newAccountList.add( new Account( Id=insertResult.getId() ) );

            } else {
                String insertErrorStr = ( insertResult.getErrors().isEmpty()? '' : insertResult.getErrors()[0].getMessage() );
                dmlErrorEmailBody += insertErrorStr + ( ''.equals(insertErrorStr)? '' : '<br/>' );
                System.debug(LoggingLevel.ERROR, 'New MTS Account INSERT FAILED. ' + ( insertResult.getErrors().isEmpty()? '' : insertResult.getErrors()[0].getMessage() ) );
            }
            accountIndex++;
        }

        for ( Account successfulAccount : this.getAccountsBySOQL( null, null, null, newAccountList ) )
        {
            if( NULL != successfulAccount.usr_user_id__c )
            {   // TODO FUTURE: shift to pk id in future
                existingAccounts.put( String.valueOf(successfulAccount.usr_user_id__c), successfulAccount );
            }
        }

        if( !''.equals(dmlErrorEmailBody) ) { TackBotUtility.sendAdminMail( 'Account INSERT DML Errors during MI Sync', dmlErrorEmailBody ); }

        return newAccounts;
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description evaluate if an MIIncident__c record requires Account assignment(s).
    * @param MIIncident__c the MI Record.
    * */
    private Boolean needsAccountAssignment(MIIncident__c miRecord)
    {
        return TARGET_RECORD_TYPE_IDS.contains( miRecord.RecordtypeId ) && ( NULL == miRecord.ProAccount__c || NULL == miRecord.CustomerAccount__c || NULL == miRecord.ProContact__c || NULL == miRecord.CustomerContact__c );
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description create missing Cases that should be bound to Account and Incident Records.
    * @param Account[] the list of all Accounts that been updated or created as part of the MTS Sync.
    * */
    private void doCaseProcessing(Account[] allMIAccounts)
    {

        Set<String> casePrimarySet = new Set<String>();
        Case[] newMTSCases = new Case[0];
        String HPC = 'HasPrimaryCustomer';
        String HPP = 'HasPrimaryPro';

        for ( Case[] cases : [SELECT Id, MICasePrimaryCustomer__c, MICasePrimaryPro__c, Incident__c FROM Case WHERE Incident__c IN :this.mtsIncidents.values()] )
        {
            //search for a primary pro and/or primary customer case(s), if found add to Set by MIIncident record Id, for use in matching below
            for( Case cse: cases )
            {
                if( cse.MICasePrimaryCustomer__c ) { casePrimarySet.add( HPC + cse.Incident__c ); }
                if( cse.MICasePrimaryPro__c ) { casePrimarySet.add( HPP + cse.Incident__c ); }
            }
        }

        for ( MIIncident__c miForCaseDML : this.mtsIncidents.values() )
        {
            if ( TARGET_RECORD_TYPE_IDS.contains( miForCaseDML.RecordtypeId ) )
            {
                Case mtsCase = getCaseShell(miForCaseDML);

                // casePrimarySet.contains() == true in the following lines means: no case creation required
                Boolean hasPrimaryCustomer = casePrimarySet.contains( HPC + miForCaseDML.Id );
                Boolean hasPrimaryPro = casePrimarySet.contains( HPP + miForCaseDML.Id );

                // if the incident does not currently have a primary pro and/or primary customer case(s), create them
                if ( NULL != miForCaseDML.ProAccount__c && !hasPrimaryPro )
                {
                    // assess Pro elements of Case
                    Case proCase = mtsCase.clone(); // ensure each new case has its own reference pointer
                    proCase.AccountId = miForCaseDML.ProAccount__c;
                    proCase.ContactId = miForCaseDML.ProContact__c;
                    proCase.MICasePrimaryPro__c = true;
                    newMTSCases.add(proCase);
                }

                if ( NULL != miForCaseDML.CustomerAccount__c && !hasPrimaryCustomer )
                {
                    // assess Customer elements of Case
                    Case customerCase = mtsCase.clone(); // ensure each new case has its own reference pointer
                    customerCase.AccountId = miForCaseDML.CustomerAccount__c;
                    customerCase.ContactId = miForCaseDML.CustomerContact__c;
                    customerCase.MICasePrimaryCustomer__c = true;
                    newMTSCases.add(customerCase);
                }
            }
        }

        this.doCaseInsertsAndFeedPosts( newMTSCases );
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description set MI Pro and Customer (+Contacts) field values, if matched and unassigned (failsafe field assignments)
    * @param MIIncident__c The MTS record to update.
    * @param Account The Account to evaluate and assign, if matched.
    * @return Boolean if the Account was matched to the MTS record by usr_user_id
    * */
    private void setMIAccount(MIIncident__c incident, Account accnt)
    {
        Boolean isProIdMatch = (NULL != incident.pro_user_id__c && accnt.usr_user_id__c == Integer.valueOf(incident.pro_user_id__c));
        Boolean isCustomerIdMatch = (incident.customer_id__c != NULL && accnt.usr_user_id__c == Integer.valueOf(incident.customer_id__c));

        // MODIFICATIONS OF MI RECORD'S RELATED ACCOUNTS FIELD DATA
        if ( isProIdMatch )
        {
            incident.ProAccount__c = ( NULL == incident.ProAccount__c ) ? accnt.Id : incident.ProAccount__c;
            incident.ProContact__c = ( NULL == incident.ProContact__c ) ? (accnt.Contacts.isEmpty() ? NULL : accnt.Contacts[0].Id) : incident.ProContact__c;
        }
        else if ( isCustomerIdMatch )
        {
            incident.CustomerAccount__c = ( NULL == incident.CustomerAccount__c ) ? accnt.Id : incident.CustomerAccount__c;
            incident.CustomerContact__c = ( NULL == incident.CustomerContact__c ) ? (accnt.Contacts.isEmpty() ? NULL : accnt.Contacts[0].Id) : incident.CustomerContact__c;
        }
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description set MI Pro and Customer (+Contacts) field values, if matched.
    * @param MIIncident__c The MTS record to update.
    * @param Account The Account to evaluate and assign, if matched.
    * @return Case a new Case shell loaded from the incident record.
    * */
    private Case getCaseShell(MIIncident__c incident)
    {
        Case newCase = new Case( Status = 'Pending Thumbtack', Category__c = 'Marketplace Integrity', Subcategory__c = 'Incident', Team__c = 'Marketplace Integrity', Origin = 'App Integration', Subject = 'Follow up from Thumbtack Support', Description = 'Case created automatically from Marketplace Trust and Safety incident management as part of the ' + incident.Name );
        newCase.RecordTypeId = MI_CASE_RECORD_TYPE_ID;
        newCase.OwnerId = incident.OwnerId;
        newCase.Priority = incident.Priority__c;
        newCase.Incident__c = incident.Id;
        return newCase;

    }


    /**
    * @author Paul Coleman
    * @date 2018-03-30
    * @description Insert new MI Cases and Post to Case Feed on successful DML records.
    * @param Case[] Cases for INSERT.
    * */
    private void doCaseInsertsAndFeedPosts(Case[] cases) {
        String networkId = Network.getNetworkId();
        ConnectApi.BatchInput[] feedItems = new ConnectApi.BatchInput[0];
        String[] errorMsgs = new String[0];
        Integer recordIndex = 0;
        SObject[] errorCases = new SObject[0];
        //INSERT new MTSCases, if any
        for( Database.SaveResult caseResult:  Database.insert( cases , false ) )
        {
            if( caseResult.success )
            {
                ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
                input.subjectId = caseResult.id;

                ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
                body.messageSegments = new List<ConnectApi.MessageSegmentInput>();

                ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = 'Case created automatically from Marketplace Trust and Safety incident management and is currently in queue.';

                body.messageSegments.add(textSegment);
                input.body = body;

                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
                feedItems.add(batchInput);
            }
            else
            {
                SObject errObject = cases[recordIndex];
                errorCases.add(errObject);
                String errString = ( caseResult.errors.isEmpty()? 'Case Insert Failed (retrying)' : 'Retrying Case Insert due to error `'+ caseResult.errors[0].getMessage()+'`' );
                errorMsgs.add('Case DML Error msg: ' + errString + '<br/> Case Error Record: ' + JSON.serialize(errObject) );
            }
            recordIndex++;
        }

        // retry inserts, will not result in feeditems, but will at least insert records that errored
        // due to unable to lock related account or MI records
        if( !errorCases.isEmpty() ) { QueueableUtility.handleQueueable( new DMLQueueable(errorCases, DMLQueueable.Operation.INSERTS) ); }

        //CANNOT POST FEEDITEMS IN SILOED Test RUNS
        if( !feedItems.isEmpty() ) {
            Integer feedIndex = 0;
            for( ConnectApi.BatchResult feedResult : ( BecquerelUtility.IS_TEST_RUN? new ConnectApi.BatchResult[0] :ConnectApi.ChatterFeeds.postFeedElementBatch(networkId, feedItems)) )
            {
                if( !feedResult.isSuccess() ) { ConnectApi.BatchInput errObject = feedItems[feedIndex]; errorMsgs.add('FeedItem DML Error msg: ' + feedResult.errorMessage + '<br/> Error Record: ' + JSON.serialize(errObject) ); } feedIndex++;
            }
        }

        if( !errorMsgs.isEmpty() )
        {
            String errorString = 'BeckyMTSIncidentSyncQueueable Case/FeedItem Insert Database Errors for user ' + UserInfo.getUserName() + ' [' + UserInfo.getUserId() + ']<br/></br>';
            errorString += String.join(errorMsgs, '<br/><br/>');
            TackBotUtility.postTackLogErrorMessage(errorString, 'BeckyMTSIncidentSyncQueueable.doCaseInsertsAndFeedPosts()');
            System.debug(LoggingLevel.INFO, 'ERROR LOG: ' + errorString);
        }

    }

}