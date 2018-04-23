/*
   Copyright (c) [2016 -] 2018 Thumbtack. All rights reserved.

Change List:                                                               
------------                                                               

Version    Date     Author            Description                          
=======+===========+=================+=================================
1.0     2016-06-21  Travis Oliver     Created
1.1     2016-07-10  Paul Coleman      Modified for Trigger Handler Mods
1.2     08-25-2017  Scott Purcell     Lots of stuff added for the mI Rebuid project
2.0     2017-10-27  Paul Coleman      Refactored for new Becky Queuables and Trigger Framework
2.1     2017-12-08  Mendel Guillaume  Clear flags on closed and set related incident action tasks as completed
2.2     2018-02-15  Mendel Guillaume  Modified for Confidential RT updates
=======+===========+=================+=================================*/
@isTest
public class MiIncidentTriggerTest {

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Inserts a set of four test Accounts.
    */
    @testSetup
    private static void createTestAccounts()
    {
        TestUtilities.insertFourCoreThumbtackUsers();
        System.debug(LoggingLevel.FINEST, 'Test Account Count: ' + [SELECT count() FROM Account]);
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Utility function for loading up an MiIncident record from a fabricated becquerel_mi_incident_project_data__x external object record.
    * @parm becquerel_mi_incident_project_data__x A fabricated external object record.
    * @return MIIncident__c A test MIIncident__c record.
    */
    public static MIIncident__c loadIncident( becquerel_mi_incident_project_data__x externalIncident )
    {

        return new MIIncident__c(
            bid_id__c = String.valueOf( BecquerelUtility.BID_BID_ID ),
            pro_user_id__c = String.valueOf(externalIncident.pro_user_id__c),
            customer_id__c = String.valueOf(externalIncident.customer_id__c),
            Name = ('Incident for ' + externalIncident.customer_first_name__c + ' ' + externalIncident.customer_last_name__c).left(80),
            CustomerName__c = externalIncident.customer_first_name__c + ' ' + externalIncident.customer_last_name__c,
            service_id__c = String.valueOf(externalIncident.service_id__c),
            request_id__c = String.valueOf(externalIncident.request_id__c),
            request_category__c = externalIncident.request_category__c,
            request_create_time__c = externalIncident.request_create_time__c,
            quotes_hired__c = externalIncident.hired__c,
            ProEmail__c = externalIncident.pro_email__c,
            ProPhone__c = externalIncident.most_recent_phone_number__c,
            CustomerEmail__c = externalIncident.customer_email__c,
            ProfessionalName__c = externalIncident.pro_first_name__c + ' ' + externalIncident.pro_last_name__c,
            pro_signup_date__c = externalIncident.pro_signup_date__c.date(),
            pro_quotes_last_30__c = String.valueOf(externalIncident.pro_quotes_last_30__c),
            pro_num_reviews__c = String.valueOf(externalIncident.pro_num_reviews__c),
            hired_time__c = externalIncident.hired_time__c,
            Status__c = 'New',
            RecordTypeId = MiIncidentTriggerHandler.MI_RECORD_TYPE_ID,
            NewEmailFlag__c = true,
            CSATOfferedPro__c = false,
            CSATOfferedCustomer__c = false,
            IsTestData__c = false,
            ExternalQuoteData__c = NULL // MIIncidentTriggerHandler only invokes a full BeckyMTSIncidentSyncQueueable when is NULL
        );
        // TODO FUTURE: add pk user id sync when MIIncident__c has the field
        //testIncident.pro_user_pk_id__c = String.valueOf(externalIncident.pro_user_pk_id__c);
        //testIncident.customer_pk_id__c = String.valueOf(externalIncident.customer_pk_id__c);
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Tests that the test MI record ends up with ProAccount__c and CustomerAccount__c assignments (by user_id keys).
    */
    @IsTest
    private static void testMTSIncidentToAccountSync()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Map<Decimal,Account> accounts = TestUtilities.getTestAccounts( (Set<Id>)NULL );
            Account proAccount = accounts.get( TestUtilities.PRO_USR_USER_ID );
            Account customerAccount = accounts.get( TestUtilities.CUSTOMER_USR_USER_ID );

            // build a test MI Incident from a corresponding test external incident
            MIIncident__c testIncident = MiIncidentTriggerTest.loadIncident( BecquerelUtility.createTestExternalIncidents(1)[0] );

            // ensure externalIncident => testIncident => Account parity before test run
            proAccount.usr_user_id__c = Decimal.valueOf(testIncident.pro_user_id__c);
            proAccount.usr_email__c = testIncident.ProEmail__c;
            customerAccount.usr_user_id__c = Decimal.valueOf(testIncident.customer_id__c);
            customerAccount.usr_email__c = testIncident.CustomerEmail__c;
            update new Account[]{ proAccount,customerAccount };
            Test.setFixedSearchResults( new Id[]{ proAccount.Id, customerAccount.Id } );

            insert testIncident;

            Test.startTest();
                // Assert record parity
                System.assertEquals( String.valueOf( proAccount.usr_user_id__c ), testIncident.pro_user_id__c, 'The test Pro Account usr_user_id__c and test MI Incident pro_user_id__c are not equal: \nTEST PRO ACCOUNT: ' + JSON.serialize(proAccount) + '\nTEST INCIDENT: ' + JSON.serialize(testIncident) );
                System.assertEquals( String.valueOf( customerAccount.usr_user_id__c ), testIncident.customer_id__c, 'The test Customer Account usr_user_id__c and test MI Incident customer_user_id__c are not equal: \nTEST CUSTOMER ACCOUNT: ' + JSON.serialize(proAccount) + '\nTEST INCIDENT: ' + JSON.serialize(testIncident) );

                testIncident.NewEmailFlag__c = false;
                testIncident.OwnerId = TestUtilities.USER_TACK_BOT.Id;

                update testIncident;

                // Assert MI was related to Accounts
                System.assertNotEquals( 0, [ SELECT count() FROM MIIncident__c WHERE Id = :testIncident.Id AND ProAccount__c = :proAccount.Id AND CustomerAccount__c = :customerAccount.Id ], 'NO MI Incident has been related to the test Pro Account and Customer Account');

                testIncident.NewEmailFlag__c = true;
                testIncident.Status__c = 'Closed';
	            testIncident.MICategory__c = 'Other';
                testIncident.ExternalQuoteData__c = NULL; //reset sync flag

                insert new Case( AccountId = proAccount.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Email', RecordTypeId = MiIncidentTriggerHandler.MI_CASE_RECORD_TYPE_ID, Incident__c = testIncident.Id );

                update testIncident;

            Test.stopTest();

            proAccount = TestUtilities.getTestAccountWithContact(proAccount.Id);
            System.assertEquals( true, proAccount.MIOpenIncident__c, 'Pro Account\'s MIOpenIncident__c is false, expected TRUE from BEFORE UPDATE trigger event' );
            customerAccount = TestUtilities.getTestAccountWithContact(customerAccount.Id);
            System.assertEquals( true, customerAccount.MIOpenIncident__c, 'Customer Account\'s MIOpenIncident__c is false, expected TRUE from BEFORE UPDATE trigger event' );

            delete testIncident; //grabbing code coverage for after delete, assertion would be the same as above (asynchronous updates to Account for MIOpenIncident flag)

        } //end RunAs
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Tests CSAT__c rules after Closing UPDATE trigger action.
    */
    @IsTest
    private static void testMTSIncidentCSAT()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Map<Decimal,Account> accounts = TestUtilities.getTestAccounts( (Set<Id>)NULL );
            Account proAccount = accounts.get( TestUtilities.PRO_USR_USER_ID );
            Account customerAccount = accounts.get( TestUtilities.CUSTOMER_USR_USER_ID );

            // build a test MI Incident from a corresponding test external incident
            MIIncident__c testIncident = MiIncidentTriggerTest.loadIncident( BecquerelUtility.createTestExternalIncidents(1)[0] );

            // ensure externalIncident => testIncident => Account parity before test run
            proAccount.usr_user_id__c = Decimal.valueOf(testIncident.pro_user_id__c);
            proAccount.usr_email__c = testIncident.ProEmail__c;
            customerAccount.usr_user_id__c = Decimal.valueOf(testIncident.customer_id__c);
            customerAccount.usr_email__c = testIncident.CustomerEmail__c;
            update new Account[]{ proAccount,customerAccount };
            Test.setFixedSearchResults( new Id[]{ proAccount.Id, customerAccount.Id } );

            testIncident.ProAccount__c = proAccount.Id;
            testIncident.CustomerAccount__c = customerAccount.Id;
            testIncident.ProContact__c = proAccount.Contacts[0].Id;
            testIncident.CustomerContact__c = customerAccount.Contacts[0].Id;

            insert testIncident;
            insert new Case( AccountId = proAccount.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Email', RecordTypeId = MiIncidentTriggerHandler.MI_CASE_RECORD_TYPE_ID, Incident__c = testIncident.Id );

            Test.startTest();

                // ensure 'Eligible' conditions are met for a CSAT to be inserted upon Close
                testIncident.Status__c = 'In Progress';
                testIncident.MICategory__c = 'Deposit no show';
                testIncident.MISubcategory__c = NULL;
                testIncident.NewEmailFlag__c = false;

                ////    CSAT Eligiblity for Pro
                testIncident.OutcomePro__c = 'Other';
                testIncident.DoNotSurveyPro__c = false;
                testIncident.CSATOfferedPro__c = false;

                ////    CSAT Eligibility for Customer
                testIncident.OutcomeCustomer__c = 'Other';
                testIncident.DoNotSurveyCustomer__c = false;
                testIncident.CSATOfferedCustomer__c = false;
                testIncident.Status__c = 'Closed';
                testIncident.OwnerId = TestUtilities.USER_TACK_BOT.Id;

                System.debug(LoggingLevel.WARN, 'CLOSING MI UPDATE testMTSIncidentCSAT');
                update testIncident;

                MIIncident__c assertIncident = [ SELECT CSATEligibilityPro__c, CSATEligibilityCustomer__c , ProAccount__c, CustomerAccount__c, CSATOfferedCustomer__c, CSATOfferedPro__c, RecordTypeId, Status__c FROM MIIncident__c WHERE Id = :testIncident.Id LIMIT 1];
                System.debug( LoggingLevel.WARN, 'INCIDENT FOR ASSERTIONS: ' + JSON.serialize(assertIncident) );
                System.assertEquals( true, MiIncidentTriggerHandler.TARGET_RECORD_TYPE_IDS.contains(assertIncident.RecordTypeId), 'MI RecoredType is no longer a target Value: ' + JSON.serialize(MiIncidentTriggerHandler.TARGET_RECORD_TYPE_IDS) );
                System.assertEquals( proAccount.Id, assertIncident.ProAccount__c, 'MI ProAccount__c does not match test Pro Account' );
                System.assertEquals( customerAccount.Id, assertIncident.CustomerAccount__c, 'MI CustomerAccount__c does not match test Customer Account' );
                System.assertEquals( true, assertIncident.CSATOfferedPro__c, 'MI CSATOfferedPro__c was not set to true' );
                System.assertEquals( true, assertIncident.CSATOfferedCustomer__c, 'MI CSATOfferedCustomer__c was not set to true' );
                System.assertEquals( 'Closed', assertIncident.Status__c, 'MI is not closed from AFTER UPDATE trigger event' );

            Test.stopTest();

            System.assertNotEquals( 0, [SELECT count() FROM CSAT__c WHERE MIIncident__c = :testIncident.Id], 'No CSATs were generated AFTER UPDATE trigger event' );

            Case[] testCases = [SELECT Status,  MICasePrimaryCustomer__c, MICasePrimaryPro__c FROM Case WHERE Incident__c = :testIncident.Id];
            System.debug( LoggingLevel.INFO, testCases );
            System.assertEquals( 'Closed', testCases[0].Status, 'Test Case is not closed during AFTER UPDATE trigger event' );

        } //end RunAs
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Tests that the Becky Sync occurs after insert.
    */
    @IsTest
    private static void testMTSIncidentToBeckySyncAndCaseCreation()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Map<Decimal,Account> accounts = TestUtilities.getTestAccounts( (Set<Id>)NULL );
            Account proAccount = accounts.get( TestUtilities.PRO_USR_USER_ID );
            Account customerAccount = accounts.get( TestUtilities.CUSTOMER_USR_USER_ID );

            // build a test MI Incident from a corresponding test external incident
            becquerel_mi_incident_project_data__x externalIncident = BecquerelUtility.createTestExternalIncidents(1)[0];
            MIIncident__c testIncident = MiIncidentTriggerTest.loadIncident( externalIncident );

            // ensure externalIncident => testIncident => Account parity before test run
            proAccount.usr_user_id__c = Decimal.valueOf(testIncident.pro_user_id__c);
            proAccount.usr_email__c = testIncident.ProEmail__c;
            customerAccount.usr_user_id__c = Decimal.valueOf(testIncident.customer_id__c);
            customerAccount.usr_email__c = testIncident.CustomerEmail__c;
            update new Account[]{ proAccount,customerAccount };

            Test.setFixedSearchResults( new Id[]{ proAccount.Id, customerAccount.Id } );

            Test.startTest();

                // conditions required for Becky sync to fire AFTER INSERT
                testIncident.bid_id__c = String.valueOf(externalIncident.bid_id__c);
                testIncident.ExternalQuoteData__c = null;

                // Ensure SF record has a value other than what is set in the Queueable test code
                //   via BecquerelUtility.createTestExternalIncidents(1)
                testIncident.quotes_hired__c = true;
                insert testIncident;
                // INSERT should invoke the after insert trigger logic and kick off Becky sync as
                //    testIncident.ExternalQuoteData__c will be null

            Test.stopTest();

            MIIncident__c afterSyncIncident = [ SELECT Id, quotes_hired__c FROM MIIncident__c WHERE Id = :testIncident.Id LIMIT 1 ];
            System.assertEquals( false, afterSyncIncident.quotes_hired__c, 'Incident quotes_hired__c was not reset by Becky Sync Queueable' );

            //assert UpdateHistory was inserted after MI Insert
            System.assertEquals( 1, [SELECT count() FROM MIIncidentUpdateHistory__c WHERE MIIncident__c = :afterSyncIncident.Id], 'Test MIIncidentUpdateHistory__c was not created during AFTER INSERT trigger event' );

            // Assert Primary Pro Case and Primary Customer Case creation during Becky Sync job -- after Test.stopTest()
            Case[] testCases = [SELECT Status, ContactId, AccountId, MICasePrimaryCustomer__c, MICasePrimaryPro__c FROM Case WHERE Incident__c = :testIncident.Id];
            System.debug( LoggingLevel.INFO, testCases );
            System.assertEquals( 2, testCases.size(), 'Test Cases were not created during AFTER UPDATE trigger event' );
            for( Case c: testCases )
            {
                if( c.AccountId == proAccount.Id )
                {
                    System.assertEquals( true, c.MICasePrimaryPro__c, 'Test Pro Case is not Primary after Becky sync' );
                }
                else if ( c.AccountId == customerAccount.Id )
                {
                    System.assertEquals( true, c.MICasePrimaryCustomer__c, 'Test Customer Case is not Primary after Becky sync' );
                }
            }
        } //end RunAs
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Tests that the test MI record ends up with NEWly CREATED ProAccount__c and CustomerAccount__c assignments (by user_id keys).
    */
    @IsTest
    private static void testMTSIncidentNoExistingAccounts()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            // make sure there are no accounts to match Incident by user id
            delete [SELECT Id FROM Account];

            // build a test MI Incident from a corresponding test external incident
            becquerel_mi_incident_project_data__x externalIncident = BecquerelUtility.createTestExternalIncidents(1)[0];
            MIIncident__c testIncident = MiIncidentTriggerTest.loadIncident( externalIncident );

            Test.startTest();

            // conditions required for Becky sync to fire AFTER INSERT and create missing Accounts
            testIncident.bid_id__c = String.valueOf(externalIncident.bid_id__c);
            testIncident.ExternalQuoteData__c = null;
            testIncident.pro_user_id__c = String.valueOf(externalIncident.pro_user_id__c);
            testIncident.customer_id__c = String.valueOf(externalIncident.customer_id__c);
            insert testIncident;

            Test.stopTest();

            MIIncident__c afterSyncIncident = [ SELECT ProAccount__c, ProContact__c, CustomerAccount__c, CustomerContact__c FROM MIIncident__c WHERE Id = :testIncident.Id LIMIT 1 ];
            System.assertEquals( false, NULL == afterSyncIncident.ProAccount__c, 'Incident ProAccount__c was not set after Account creation within Becky Sync Queueable' );
            System.assertEquals( false, NULL == afterSyncIncident.ProContact__c, 'Incident ProContact__c was not set after Account/Contact creation within Becky Sync Queueable' );
            System.assertEquals( false, NULL == afterSyncIncident.CustomerAccount__c, 'Incident CustomerAccount__c was not set after Account creation within Becky Sync Queueable' );
            System.assertEquals( false, NULL == afterSyncIncident.CustomerContact__c, 'Incident CustomerContact__c was not set after Account/Contact creation within Becky Sync Queueable' );

        } //end RunAs
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-09
    * @description Tests that the inserted test MI record (minimum field values) ends up with a related Update History record.
    */
    @IsTest
    private static void testMTSMinimumViableIncidentUpdateHistoryInsert()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            // make sure there are no accounts to match Incident by user id
            delete [SELECT Id FROM Account];

            Test.startTest();

            MIIncident__c testIncident = new MIIncident__c(Name = 'Test',
                    MICategory__c = 'Deposit no show',
                    Origin__c = 'Live Chat',
                    Priority__c = 'Tier 1',
                    Status__c = 'New',
                    bid_id__c = '65688053'); // purposefully will not match the test MI record mock
            insert testIncident;

            Test.stopTest();

            System.assertEquals( 1, [ SELECT count() FROM MIIncidentUpdateHistory__c WHERE MIIncident__c = :testIncident.Id ], 'MTS Trigger AFTER INSERT event did not produce an MI Update History record when neither pro nor customer user ids are present.' );

        } //end RunAs
    }

    /**
    * @author Mendel Guillaume
    * @date 2017-11-13
    * @description Tests that related MI tasks are Closed when the MI record is being closed. Also tests that MI flag fields are set per reqs on MI close.
    */
    @IsTest
	private static void testIncidentCompleted()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c mi = new MIIncident__c(Name = 'Test Incident', NewCallFlag__c = true, NewCaseFlag__c = true,
					NewEmailFlag__c = true, NewPostFlag__c = true, NextFollowupDate__c = Date.today(), Status__c = 'New');
			insert mi;

			List<MIIncidentAction__c> tasks = new List<MIIncidentAction__c>();
			tasks.add(new MIIncidentAction__c(Name = 'Task 1', Status__c = 'Open', MIIncident__c = mi.Id));
			tasks.add(new MIIncidentAction__c(Name = 'Task 2', Status__c = 'Open', MIIncident__c = mi.Id));
			insert tasks;

			mi = [SELECT Id, NewCallFlag__c, NewCaseFlag__c, NewEmailFlag__c, NewPostFlag__c, NextFollowupDate__c, Status__c,
						(SELECT Id, Status__c FROM MIIncidentActions__r)
					FROM MIIncident__c];
			System.assertEquals(true, mi.NewCallFlag__c);
			System.assertEquals(true, mi.NewCaseFlag__c);
			System.assertEquals(true, mi.NewEmailFlag__c);
			System.assertEquals(true, mi.NewPostFlag__c);
			System.assertEquals(Date.today(), mi.NextFollowupDate__c);

			for(MIIncidentAction__c t : mi.MIIncidentActions__r)
			{
				System.assertEquals('Open', t.Status__c);
			}

            Test.startTest();

                mi.Status__c = 'Closed';
                mi.MICategory__c = 'Other';
                update mi;

            Test.stopTest();

			mi = [SELECT Id, NewCallFlag__c, NewCaseFlag__c, NewEmailFlag__c, NewPostFlag__c, NextFollowupDate__c, Status__c,
						(SELECT Id, Status__c FROM MIIncidentActions__r)
					FROM MIIncident__c];
			System.assertEquals(false, mi.NewCallFlag__c);
			System.assertEquals(false, mi.NewCaseFlag__c);
			System.assertEquals(false, mi.NewEmailFlag__c);
			System.assertEquals(false, mi.NewPostFlag__c);
			System.assertEquals(null, mi.NextFollowupDate__c);

			for(MIIncidentAction__c t : mi.MIIncidentActions__r)
			{
				System.assertEquals('Completed', t.Status__c);
			}
		}
	}

    /**
    * @author Mendel Guillaume
    * @date 2018-02-09
    * @description Tests that related objects (Cases, Disputes, Dispute Offers, Dispute Messages) records are updated to confidential record type when incident rt is updated to confidential.
    */
    @IsTest
    private static void testConfidentialRtUpdate()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            MIIncident__c mi = new MIIncident__c(Name = 'Test Incident', NewCallFlag__c = true, NewCaseFlag__c = true,
                    NewEmailFlag__c = true, NewPostFlag__c = true, NextFollowupDate__c = Date.today(), Status__c = 'New');
            insert mi;
            List<Case> cases = new List<Case>();
            List<Dispute__c> disputes = new List<Dispute__c>();
            List<DisputeOffer__c> disputeOffers = new List<DisputeOffer__c>();
            List<DisputeMessage__c> messages = new List<DisputeMessage__c>();

            cases.add(new Case(Subject = 'Test Case', Incident__c = mi.Id, RecordTypeId = CaseHelper.MARKETPLACE_INTEGRITY_RECORD_TYPE_ID));
            cases.add(new Case(Subject = 'Test Case 2', Incident__c = mi.Id, RecordTypeId = CaseHelper.MARKETPLACE_INTEGRITY_RECORD_TYPE_ID));
            cases.add(new Case(Subject = 'Test Case 3', Incident__c = mi.Id, RecordTypeId = CaseHelper.MARKETPLACE_INTEGRITY_RECORD_TYPE_ID));
            insert cases;

            disputes.add(new Dispute__c(Name = 'Test Dispute 1', MIIncident__c = mi.Id, RecordTypeId = DisputeTriggerHandler.SOLUTION_CENTER_DISPUTE_RECORD_TYPE_ID));
            disputes.add(new Dispute__c(Name = 'Test Dispute 2', MIIncident__c = mi.Id, RecordTypeId = DisputeTriggerHandler.SOLUTION_CENTER_DISPUTE_RECORD_TYPE_ID));
            disputes.add(new Dispute__c(Name = 'Test Dispute 3', MIIncident__c = mi.Id, RecordTypeId = DisputeTriggerHandler.SOLUTION_CENTER_DISPUTE_RECORD_TYPE_ID));
            insert disputes;

            disputeOffers.add(new DisputeOffer__c(Name = 'Test Offer 1', Dispute__c = disputes[0].Id,
                    RecordTypeId = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center Offer').getRecordTypeId()));
            disputeOffers.add(new DisputeOffer__c(Name = 'Test Offer 2', Dispute__c = disputes[1].Id,
                    RecordTypeId = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center Offer').getRecordTypeId()));
            disputeOffers.add(new DisputeOffer__c(Name = 'Test Offer 3', Dispute__c = disputes[2].Id,
                    RecordTypeId = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center Offer').getRecordTypeId()));
            insert disputeOffers;

            messages.add(new DisputeMessage__c(Name = 'Test Message 1', DisputeOffer__c = disputeOffers[0].Id,
                    RecordTypeId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Message').getRecordTypeId()));
            messages.add(new DisputeMessage__c(Name = 'Test Message 2', DisputeOffer__c = disputeOffers[1].Id,
                    RecordTypeId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Message').getRecordTypeId()));
            messages.add(new DisputeMessage__c(Name = 'Test Message 3', DisputeOffer__c = disputeOffers[2].Id,
                    RecordTypeId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Message').getRecordTypeId()));
            insert messages;

            Test.startTest();

            mi.RecordTypeId = MiIncidentTriggerHandler.CONFIDENTIAL_RECORD_TYPE_ID;
            update mi;

            Test.stopTest();

	        System.assertEquals(3, [SELECT Id FROM Case WHERE Incident__c = :mi.Id AND RecordTypeId = :CaseHelper.CONFIDENTIAL_RECORD_TYPE_ID].size(), 'Cases not updated.');
	        System.assertEquals(3, [SELECT Id FROM Dispute__c WHERE MIIncident__c = :mi.Id AND RecordTypeId = :DisputeTriggerHandler.CONFIDENTIAL_RECORD_TYPE_ID].size(), 'Disputes not updated.');
	        System.assertEquals(3, [SELECT Id FROM DisputeOffer__c WHERE Dispute__r.MIIncident__c = :mi.Id AND RecordTypeId = :DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId()].size(), 'Dispute Offers not updated.');
	        System.assertEquals(3, [SELECT Id FROM DisputeMessage__c WHERE DisputeOffer__r.Dispute__r.MIIncident__c = :mi.Id AND RecordTypeId = :DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId()].size(), 'Dispute Messages not updated.');
        }
    }

}