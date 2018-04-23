/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
******************************************************************************** 
  

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       06-19-2017     Scott Purcell          Created
1.1       2018-01-03   Mendel Guillaume  Updated to follow template/guidelines
1.1       2018-01-04   Mendel Guillaume  Updated to account for response object
========+============+=================+===============================================*/
@IsTest
private class MIIncidentBidCheckApexControllerTest
{
    public static Id gfRecordTypeId = CSAT__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('GetFeedback CSAT').getRecordTypeId();
    public static Id miRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();

    @TestSetup
    private static void createData()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Case c = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Email',
                    RecordTypeId = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId());

            insert c;
        }
    }

    @IsTest
    static void testMIInccidentNewUpdate()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
            Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
            Id miCaseQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceIntegrity'].Id;
            Decimal testProUserId = 100;
            Decimal testCustomerUserId = 200;
            Account aPro = new Account(Name = 'Chester Pro', usr_user_id__c = testProUserId, usr_email__c = 'protester@t.est', RecordTypeId = accProRT);
            Account aPro2 = new Account(Name = 'Chester Pro2', usr_user_id__c = 123, usr_email__c = 'protester2@t.est', RecordTypeId = accProRT);
            Account aCustomer = new Account(Name = 'Tester Customer', usr_user_id__c = testCustomerUserId, usr_email__c = 'customertester@t.est', RecordTypeId = accCustomerRT);
            Account aCustomer2 = new Account(Name = 'Tester Customer2', usr_user_id__c = 12345, usr_email__c = 'customertester2@t.est', RecordTypeId = accCustomerRT);
            insert new Account[] {aPro, aPro2, aCustomer, aCustomer2};

            Case c = [SELECT Id FROM Case];
            c.AccountId = aPro.Id;
            update c;

            MiIncident__c mii = new MiIncident__c(
                    Name = 'Test',
                    pro_user_id__c = String.valueOf(testProUserId),
                    customer_id__c = String.valueOf(testCustomerUserId),
                    quotes_pro_user_id__c = testProUserId,
                    quotes_customer_id__c = testCustomerUserId,
                    quotes_bid_id__c = 1,
                    RequestID__c = '1',
                    ResolutionTier__c = 'Tier 0 - Lost Communication',
                    MICategory__c = 'Removed',
                    MISubcategory__c = 'Other',
                    Status__c = 'In Progress',
                    IncidentCategorization__c = '0 - Not enough details');
            insert mii;
            mii.ProAccount__c = aPro2.Id;
            mii.CustomerAccount__c = aCustomer2.Id;
            mii.ResolutionTier__c = 'Compensation Reason';
            mii.Status__c = 'Closed';
            mii.RecordTypeId = miRecordTypeId;
            mii.OutcomeCustomer__c = 'Flagged';
            mii.OutcomePro__c = 'Unresponsive';
            mii.CSATOfferedPro__c = false;
            mii.MICategory__c = 'Property damage';
            mii.DoNotSurveyPro__c = false;
            mii.ClosedDate__c = Date.today();
            mii.OutcomePro__c = 'Pro fixed work';
            update mii;

            MiIncident__c mii2 = new MiIncident__c(
                    Name = 'Testy',
                    pro_user_id__c = '110',
                    customer_id__c = '210',
                    quotes_pro_user_id__c = 110,
                    quotes_customer_id__c = 210,
                    quotes_bid_id__c = 2,
                    RequestID__c = '2',
                    ResolutionTier__c = 'Tier 0 - Lost Communication',
                    MICategory__c = 'Removed',
                    MISubcategory__c = 'Other',
                    Status__c = 'In Progress',
                    IncidentCategorization__c = '0 - Not enough details');

            Test.startTest();

            MiIncident__c testIncident = (MIIncident__c)MIIncidentBidCheckApexController.getIncidentFromBecky(1234, mii).record;
            System.Assert(testIncident != null, 'Incident not found');
            MiIncident__c testIncident2 = (MIIncident__c)MIIncidentBidCheckApexController.insertNewIncident(mii2, c.Id, true, false,
                    new Contact(usr_user_id__c = 11111, FirstName = 'Test', LastName = 'Customer'),
                    new Contact(usr_user_id__c = 11112, FirstName = 'Test', LastName = 'Pro')).record;
            System.Assert(testIncident2 != null, 'Incident not found');
            Case c1 = MIIncidentBidCheckApexController.getCaseValues(c.Id);
            System.Assert(c1 != null, 'Case not found');
            MiIncident__c testIncident3 = MIIncidentBidCheckApexController.createInitialIncident(c.Id);
            System.Assert(testIncident3 != null, 'Incident not created');
            List<String> values = MIIncidentBidCheckApexController.getPicklistOptions('MIIncident__c', 'Origin__c');
            System.Assert(values.size() > 0, 'No Origin options');

            Test.stopTest();
        }
    }

    @IsTest
    static void testInsertNewIncidentFromExternal()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Case c = [Select Id FROM Case];
            MIIncident__c incident = MIIncidentBidCheckApexController.createInitialIncident(c.Id);

            System.assertEquals(null, incident.Id);

            incident.customer_id__c = '11111';
            incident.CustomerEmail__c = 'test@cust.com';
            incident.CustomerName__c = 'Test Customer';
            incident.pro_user_id__c = '11112';
            incident.ProEmail__c = 'test@pro.com';
            incident.ProfessionalName__c = 'Test Pro';
            incident.bid_id__c = null;

            Test.startTest();

            MIIncidentBidCheckApexController.insertNewIncidentFromExternal(incident, c.Id, true, false);

            Test.stopTest();

            System.assertNotEquals(null, incident.Id, 'Incident created');
        }
    }

    @IsTest
    static void testFindUser1()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();

            System.assertEquals(null, MIIncidentBidCheckApexController.findThumbtackUser(11111), 'User found');

            Test.stopTest();
        }
    }

    @IsTest
    static void testFindUser2()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();

            System.assertNotEquals(null, MIIncidentBidCheckApexController.findThumbtackUser(11112), 'User not found');

            Test.stopTest();
        }
    }

	//Existing contact
	@IsTest
	static void testFindUser3()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account a = new Account(Name = 'Chester Tester', usr_user_id__c = 11111);
			insert a;

			Test.startTest();

			System.assertNotEquals(null, MIIncidentBidCheckApexController.findThumbtackUser(11111), 'User not found');

			Test.stopTest();
		}
	}

    @IsTest
    static void testGetCategories()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();

            System.assertNotEquals(0, MIIncidentBidCheckApexController.getCategories().size(), 'No categories');

            Test.stopTest();
        }
    }

    @IsTest
    static void testGetCategoriesMap()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();

            System.assertNotEquals(0, MIIncidentBidCheckApexController.getCategoryMap().size(), 'No categories map');

            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateGoodSamaritanIncidentExistingUser()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Case c = [Select Id FROM Case];
            MIIncident__c incident = MIIncidentBidCheckApexController.createInitialIncident(c.Id);
            FindUserController.FindUserResult user = MIIncidentBidCheckApexController.findThumbtackUser(11112);

            Test.startTest();

            MIIncidentBidCheckApexController.createGoodSamaritanIncidentExistingUser(incident, c.Id, user.user, true);

            Test.stopTest();

            System.assertNotEquals(null, incident.Id, 'Incident not created');
        }
    }

    @IsTest
    static void testCreateGoodSamaritanIncidentExistingContact()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Case c = [Select Id FROM Case];

            Account a = new Account(Name = 'Chester Tester');
            insert a;
            Contact ct = new Contact(LastName = 'Tester', FirstName = 'Chester', AccountId = a.Id);
            insert ct;

            MIIncident__c incident = MIIncidentBidCheckApexController.createInitialIncident(c.Id);

            Test.startTest();

            MIIncidentBidCheckApexController.createGoodSamaritanIncidentExistingContact(incident, c.Id, ct, false);

            Test.stopTest();

            System.assertNotEquals(null, incident.Id, 'Incident not created');
        }
    }

    @IsTest
    static void testCreateGoodSamaritanIncidentNewUser()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Case c = [Select Id FROM Case];
            MIIncident__c incident = MIIncidentBidCheckApexController.createInitialIncident(c.Id);

            Test.startTest();

            MIIncidentBidCheckApexController.createGoodSamaritanIncidentNewUser(incident, c.Id, 'test@cust.com', 'Test', 'Cust', false);

            Test.stopTest();

            System.assertNotEquals(null, incident.Id, 'Incident not created');
        }
    }

	//No email
	@IsTest
	static void testCreateGoodSamaritanIncidentNewUser2()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [Select Id FROM Case];
			MIIncident__c incident = MIIncidentBidCheckApexController.createInitialIncident(c.Id);

			Test.startTest();

			MIIncidentBidCheckApexController.createGoodSamaritanIncidentNewUser(incident, c.Id, '', 'Test', 'Cust', false);

			Test.stopTest();

			System.assertNotEquals(null, incident.Id, 'Incident not created');
		}
	}

    @IsTest
    static void testCreateNewAccountContact()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();

            System.assertNotEquals(null, MIIncidentBidCheckApexController.createNewAccountContact('test@test.com', 'Test', 'Test', MIIncidentBidCheckApexController.cRTId, 0), 'Contact not created');

            Test.stopTest();
        }
    }

	@IsTest
	static void testGetQueues()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, MIIncidentBidCheckApexController.getQueues().size(), 'No queues');

			Test.stopTest();
		}
	}
}