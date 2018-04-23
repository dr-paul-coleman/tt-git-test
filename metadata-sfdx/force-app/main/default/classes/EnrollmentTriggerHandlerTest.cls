/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved. 

Version   Date         Author           	Description
========+============+====================+=======================================
1.0       2016-12-05   Travis Oliver     	Created
1.1		  2017-09-25   Meena Pisupati		Updated Header
========+============+====================+=======================================*/
@isTest
private class EnrollmentTriggerHandlerTest
{
	public static Id quotingServiceRecordType = Schema.Sobjecttype.Enrollment__c.getRecordTypeInfosByName().get('Quoting Service').getRecordTypeId();
	public static Id productEnabledRecordType = Schema.Sobjecttype.Enrollment__c.getRecordTypeInfosByName().get('Product Enabled').getRecordTypeId();
	public static Id earlyEnrollmentRecordType = Schema.Sobjecttype.Enrollment__c.getRecordTypeInfosByName().get('Early Enrollment').getRecordTypeId();
	public static Id serviceRT = Schema.Sobjecttype.Service__c.getRecordTypeInfosByName().get('Pro Assistance Service').getRecordTypeId();
	public static Id SMART_ROUTING_RECORD_TYPE_ID = Schema.Sobjecttype.RoutingProfile__c.getRecordTypeInfosByName().get('Smart Routing').getRecordTypeId();

	@isTest 
    static void testMatchAccountToEnrollment() 
    {    
 		Account a = new Account(
            Name ='Test Name ',
            OwnerId = TestUtilities.USER_TACK_BOT.Id,
            usr_user_id__c = 1
        );            
        
        Account a2 = new Account(
            Name ='Test Name ',
            OwnerId = TestUtilities.USER_TACK_BOT.Id,
            usr_user_id__c = 2
        );

        insert new Account[] {a, a2};
            
        System.runAs(TestUtilities.USER_TACK_BOT) 
        {
            Test.startTest();
            
                Enrollment__c enrollment = new Enrollment__c(
                	RecordTypeId = quotingServiceRecordType,
                	enrollment_id__c = '1',
                    Name = 'FN LN 1-1',
                    Account__c = a.Id,
                    FirstName__c = 'Test First Name ',
                    LastName__c = 'Test Last Name ' ,
                    OwnerId = TestUtilities.USER_TACK_BOT.Id,
                    sav_available_service_id__c = 1,
                    user_id__c = '1'  ,
                    rca_request_category_id__c = '1',
                    zip_cbsa_code__c = '1',
                    zip_cbsa_name__c = 'Utah'         
                );
				insert enrollment;
                enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollment.Id];
                System.assertEquals(a.Id, enrollment.Account__c);
                enrollment.user_id__c = '2';
                update enrollment;             	
                
                Enrollment__c enrollBN = new Enrollment__c(
                        RecordTypeId = productEnabledRecordType,
                        enrollment_id__c = '4',                       
                        BusinessName__c = 'Test Business Name Test Business Name Test First Name Test First Name Test First Name 85' ,
                        OwnerId = TestUtilities.USER_TACK_BOT.Id,
                        sav_available_service_id__c = 1,
                        user_id__c = '3'  ,
                        rca_request_category_id__c = '2',
                        zip_cbsa_code__c = '2',
                        zip_cbsa_name__c = 'Texas'         
                    );
            	insert enrollBN;
            
            Test.stopTest();
            
            enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollment.Id];
        }
    }

    @isTest 
    static void testRelateAccountToEnrollment() 
    {
		Account a = EAPTestUtility.createAccount(true);        
        System.runAs(TestUtilities.USER_TACK_BOT) 
        {
            Test.startTest();
            
                Enrollment__c enrollment = new Enrollment__c(
                    RecordTypeId = quotingServiceRecordType,
                    enrollment_id__c = '1',
                    FirstName__c = 'Test First Name ',
                    LastName__c = 'Test Last Name ' ,
                    OwnerId = TestUtilities.USER_TACK_BOT.Id,
                    sav_available_service_id__c = 1,
                    user_id__c = '1'  ,
                    rca_request_category_id__c = '1',
                    zip_cbsa_code__c = '1',
                    zip_cbsa_name__c = 'Utah',
                    AccountManager__c = TestUtilities.USER_TACK_BOT.Id
                );
                insert enrollment;
                enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollment.Id];
            
            Test.stopTest();
            
            System.assertEquals(a.Id, enrollment.Account__c);
        }

    }

    @isTest static void testRelateAccountToEnrollment_notExistingAccount() 
    {      
        System.runAs(TestUtilities.USER_TACK_BOT) 
        {
            Test.startTest();
            
                Enrollment__c enrollment = new Enrollment__c(
                    RecordTypeId = quotingServiceRecordType,
                    enrollment_id__c = '1',
                    FirstName__c = 'Test First Name ',
                    LastName__c = 'Test Last Name ' ,
                    BusinessName__c = 'test biz',
                    Phone__c = '5555555555',
                    OwnerId = TestUtilities.USER_TACK_BOT.Id,
                    sav_available_service_id__c = 1,
                    user_id__c = '1'  ,
                    rca_request_category_id__c = '1',
                    zip_cbsa_code__c = '1',
                    zip_cbsa_name__c = 'Utah'         
                );
                insert enrollment;
                enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollment.Id];
            
            Test.stopTest();
            
            System.assert(enrollment.Account__c != null);
        }

    }
	
    @isTest static void relateEnrollmentToMarket_test()
    {
        Market__c market = new Market__c (
            rca_name__c = 'Salesforce Dev',
            zip_cbsa_name__c = 'Utah',
            Deprioritized__c = false,
            TakeaLeadEnabled__c = false,
            rca_request_category_id__c = '11',
            zip_cbsa_code__c = '11',
            outreach_type__c = 'Early_enrollment',
            MarketID__c ='11-11'
        );
        Market__c market2 = new Market__c (
            rca_name__c = 'name',
            zip_cbsa_name__c = 'Utah2',
            Deprioritized__c = false,
            TakeaLeadEnabled__c = false,
            rca_request_category_id__c = '1',
            zip_cbsa_code__c = '1',
            outreach_type__c = 'Early_enrollment',
            MarketID__c ='1-1'
        );
        insert new List<Market__c> {market, market2};
        
		Account a = EAPTestUtility.createAccount(true);

        Enrollment__c enrollment = new Enrollment__c(
        	zip_cbsa_code__c = '11',
            zip_cbsa_name__c = 'Utah',
        	enrollment_id__c = '11',
            Account__c = a.Id,
            FirstName__c = 'Test First Name ',
            LastName__c = 'Test Last Name ' ,
            sav_available_service_id__c = 1,
            user_id__c = '1',
            outreach_type__c = 'early_enrollment',
            outreach_group__c = '1_VIP',
            RecordTypeId = productEnabledRecordType ,
            rca_request_category_id__c = '11'
        );
        insert enrollment;
        System.runAs(TestUtilities.USER_TACK_BOT) 
        {
	        Test.startTest();
		        
           		enrollment = [Select Id, Market__c, rca_request_category_id__c From Enrollment__c Where Id = :enrollment.Id];
		        system.debug('market.Id: '+market.Id+', enrollment.Market__c: '+enrollment.Market__c);
		        //System.assertEquals(market.Id, enrollment.Market__c);

		        enrollment.rca_request_category_id__c = '1';
		        enrollment.zip_cbsa_code__c = '1';
		        enrollment.zip_cbsa_name__c = 'Utah2';
		        enrollment.outreach_type__c = 'early_enrollment';
		        enrollment.rca_name__c = 'name';
		        update enrollment;
		        enrollment = [Select Id, Market__c, rca_request_category_id__c From Enrollment__c Where Id = :enrollment.Id];
		        system.debug('market2.Id: '+market2.Id+', enrollment.Market__c: '+enrollment.Market__c);
		        //System.assertEquals(market2.Id, enrollment.Market__c);
		        
	        Test.stopTest();
	    }
    }
    

    @isTest static void relateEnrollmentToMarket_catgeo_test()
    {
        Market__c market = new Market__c (
            rca_name__c = 'Salesforce Dev',
            zip_cbsa_name__c = 'Utah',
            Deprioritized__c = false,
            TakeaLeadEnabled__c = false,
            rca_request_category_id__c = '23',
            zip_cbsa_code__c = '24',
            outreach_type__c = 'Early_enrollment'
        );
        insert market;
        
		Account a = EAPTestUtility.createAccount(true);

        Enrollment__c enrollment = new Enrollment__c(
        	zip_cbsa_code__c = '1',
            zip_cbsa_name__c = 'Utah',
        	enrollment_id__c = '1',
            Account__c = a.Id,
            FirstName__c = 'Test First Name ',
            LastName__c = 'Test Last Name ' ,
            sav_available_service_id__c = 1,
            user_id__c = '1',
            RecordTypeId = productEnabledRecordType ,
            rca_request_category_id__c = '23',
            FunnelStep__c = 'Interested'
        );
        
        System.runAs(TestUtilities.USER_TACK_BOT) 
        {
	        Test.startTest();
            
                insert enrollment;
		        enrollment = [Select Id, Market__c, rca_request_category_id__c From Enrollment__c Where Id = :enrollment.Id];
		        system.debug('market.Id: '+market.Id+', enrollment.Market__c: '+enrollment.Market__c);
		        //System.assertEquals(market.Id, enrollment.Market__c);
	        
            Test.stopTest();
	    }
    }

	@IsTest
	static void testEnrollmentMarketCreated()
	{
		Account a = EAPTestUtility.createAccount(true);
		System.runAs(TestUtilities.USER_TACK_BOT)
        {
			Test.startTest();
            
                Enrollment__c enrollment = new Enrollment__c(zip_cbsa_code__c = '11', zip_cbsa_name__c = 'Utah', enrollment_id__c = '11',
                                                             Account__c = a.Id, FirstName__c = 'First', LastName__c = 'Last', sav_available_service_id__c = 1,
                                                             user_id__c = '1', RecordTypeId = productEnabledRecordType, rca_request_category_id__c = '11',
                                                             outreach_type__c = 'product_enabled', rca_name__c = 'Salesforce Dev');
                insert enrollment;
                
			Test.stopTest();
            
			System.assertEquals(1, [SELECT Id FROM Market__c].size());
		}
	}

	@IsTest
	static void testEnrollmentMarketNotCreated()
	{
    	Account a = EAPTestUtility.createAccount(true);

		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(zip_cbsa_code__c = '11', zip_cbsa_name__c = 'Utah', enrollment_id__c = '11',
                                                             Account__c = a.Id, FirstName__c = 'First', LastName__c = 'Last', sav_available_service_id__c = 1,
                                                             user_id__c = '1', RecordTypeId = productEnabledRecordType, rca_request_category_id__c = '11',
                                                             outreach_type__c = 'managed_account', rca_name__c = 'Salesforce Dev');
                insert enrollment;

			Test.stopTest();

			System.assertEquals(0, [SELECT Id FROM Market__c].size());
		}
	}

	@IsTest
	static void testManagedAccountEnrollmentName()
	{
		Account a = EAPTestUtility.createAccount(true);        
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11', Account__c = a.Id, FirstName__c = 'First', LastName__c = 'Last',
                                                             user_id__c = '1', RecordTypeId = productEnabledRecordType, outreach_type__c = 'managed_account');
                insert enrollment;

			Test.stopTest();

			System.assertEquals('Test Name - Managed account', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}
	
    @IsTest
	static void testManagedAccountEnrollmentFirstLastName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',FirstName__c = 'First', LastName__c = 'Last',
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'managed_account');
                insert enrollment;

			Test.stopTest();

			System.assertEquals('First Last - Managed account', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}

	@IsTest
	static void testManagedAccountEnrollmentLastName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',LastName__c = 'Last',
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'managed_account');
                insert enrollment;

			Test.stopTest();

			System.assertEquals('Last - Managed account', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}

	@IsTest
	static void testManagedAccountEnrollmentFirstName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',FirstName__c = 'First', 
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'managed_account');
                insert enrollment;
            
			Test.stopTest();

			System.assertEquals('First - Managed account', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}
	
	@IsTest
	static void testManagedAccountEnrollmentBusinessName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',BusinessName__c = 'Business', 
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'managed_account');
                insert enrollment;

			Test.stopTest();

			System.assertEquals('Business - Managed account', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}
    
    @IsTest
	static void testProEngagementEnrollmentBusinessName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11', BusinessName__c = 'Business', 
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'pro_engagement');
                insert enrollment;

			Test.stopTest();

			System.assertEquals('Business - Pro engagement', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}
    
    @IsTest
	static void testProOnboardingEnrollmentBusinessName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

                Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',BusinessName__c = 'Business', 
                                                             RecordTypeId = productEnabledRecordType, outreach_type__c = 'pro_onboarding');
                insert enrollment;
                enrollment.outreach_type__c = 'pro_engagement';
                update enrollment;
            
			Test.stopTest();

			System.assertEquals('Business - Pro onboarding', [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name);
		}
	}
    
    static void testEnrollmentNameLength()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

            Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '11',
                                                         BusinessName__c = 'Business',
                                                         Name = 'BusinessBusinessBusinessBusinessBusinessBusinessBusinessBusinessBusinessBusiness',
                                                         RecordTypeId = productEnabledRecordType, outreach_type__c = 'pro_onboarding');
            insert enrollment;
            
			Test.stopTest();
			String enrollmentName = [SELECT Name FROM Enrollment__c WHERE Id = :enrollment.Id][0].Name;
            System.assertEquals(80, enrollmentName.length());

		}
	}

    @isTest
    static void testInsertNewRoutingProfile()
	{
        Account a = new Account(
            AccountManager__c = TestUtilities.USER_TACK_BOT.Id,
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(),
            Name = 'Test Account',
            usr_user_id__c = 1
        );
        Insert a;
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1-Managed account',
                                                         BusinessName__c = 'Business',
                                                         Name = 'Business - Managed Account',
                                                         user_id__c = '1',
                                                         RecordTypeId = productEnabledRecordType,
                                                         Account__c = a.Id,
                                                         SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                                                         outreach_type__c = 'managed_account',
                                                         outreach_group__c = '0_MA', FunnelStep__c = 'Prospecting');
            Insert enrollment;
            Test.stopTest();
        }
    }

    @isTest
    static void testFunnelStepUpdateEnrollment()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account a = new Account(
                AccountManager__c = TestUtilities.USER_TACK_BOT.Id,
                RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(),
                Name = 'Test Account',
                usr_user_id__c = 1
            );
            Insert a;
            Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1-Managed account',
                                                         BusinessName__c = 'Test account',
                                                         Name = 'Business - Managed Account',
                                                         user_id__c = '1',
                                                         RecordTypeId = productEnabledRecordType,
                                                         Phone__c = '1234123412',
                                                         Email__c = 'test@test.com',
                                                         outreach_type__c = 'managed_account',
                                                         outreach_group__c = '0_MA', FunnelStep__c = 'Prospecting');
            Insert enrollment;
            enrollment.FunnelStep__c = 'Pre-Onboarding';
            update enrollment;
            Test.stopTest();
        }
    }

    @isTest
    static void testProspectingFunnelStepEnrollment()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account a = new Account(
                AccountManager__c = TestUtilities.USER_TACK_BOT.Id,
                RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(),
                Name = 'Test Account',
                usr_user_id__c = 1
            );
            Insert a;
            Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1-Managed account',
                                                         BusinessName__c = 'Test account',
                                                         Name = 'Business - Managed Account',
                                                         user_id__c = '1',
                                                         RecordTypeId = productEnabledRecordType,
                                                         Phone__c = '1234123412',
                                                         Email__c = 'test@test.com',
                                                         outreach_type__c = 'managed_account',
                                                         outreach_group__c = '0_MA', FunnelStep__c = 'Prospecting');
            Insert enrollment;
            enrollment.FunnelStep__c = 'Pre-Onboarding';
            update enrollment;
            Test.stopTest();
        }
    }
    
    @isTest
    static void testEnrollmentSOSL()
    {
         Account a = new Account(
            AccountManager__c = TestUtilities.USER_TACK_BOT.Id,
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(),
            Name = 'Test Account',
            usr_user_id__c = 1
        );
        Insert a;
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            RoutingProfile__c rp = new RoutingProfile__c(
                RecordtypeId = SMART_ROUTING_RECORD_TYPE_ID,
                Name = 'Routing Profile for a@b.com',
                Email__c = 'a@b.com',
                Phone__c = '1234567890',
                Phone3__c = '9090909090',
                Sales__c = TRUE
            );
            Insert rp;
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = rp.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            List<List<SObject>> searchList = [FIND '9090909090' IN PHONE FIELDS RETURNING RoutingProfile__c(Id,Phone3__c)];
            system.assert(searchList != null);
            Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1-Managed account',
                                                         BusinessName__c = 'Business',
                                                         Name = 'Business - Managed Account',
                                                         user_id__c = '1',
                                                         RecordTypeId = productEnabledRecordType,
                                                         Account__c = a.Id,
                                                         SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                                                         Phone__c = '9090909090',
                                                         Email__c = 'a@b.com',
                                                         outreach_type__c = 'managed_account',
                                                         outreach_group__c = '0_MA', FunnelStep__c = 'Prospecting');
            Insert enrollment;
            enrollment.FunnelStep__c = 'Pre-Onboarding';
            update enrollment;
            Test.stopTest();
        }
    }
}