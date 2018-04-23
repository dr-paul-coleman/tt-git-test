/*
  Copyright (c) 2016 Thumbtack, All rights reserved.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-05-17  Paul Coleman      Created
 1.1     2017-08-11  Mendel Guillaume  Verify account and contact record type and owner match
 1.2     2017-10-02  Paul Coleman      Verify Account => Contact Synchronous Creation
 1.3     2017-12-14  Mendel Guillaume  Verify account ownership set to tackbot when account record type != 'Managed Account'
 1.4     2018-02-19	 Meena Pisupati	   Update Routing Profile on Account Manager Update
 1.5     2018-04-01	 Meena Pisupati	   Added testAccountManagerUpdate method
 =======+===========+=================+=================================*/ 
@IsTest
private class AccountTriggerHandlerTest
{

    @TestSetup
    private static void createTestAccount()
    {
        insert TestUtilities.CORE_ACCOUNT.clone();
    }

    @IsTest
    private static void verifyAccountToContactRecordTypeAndOwnerSync()
    {
        //test as tackbot
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Account testAccount = TestUtilities.getTestAccountWithContact(); //only one was inserted in testSetup
            User newOwner = [SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Id != :TestUtilities.USER_TACK_BOT.Id LIMIT 1];

            Test.startTest();

                System.assertEquals( false, testAccount.Contacts.isEmpty(), 'Account Trigger did not produce a related Contact');
                System.assertEquals( testAccount.Contacts[0].RecordTypeId, TestUtilities.CONTACT_PRO_RECORD_TYPE_ID, 'Account\'s Record Type does not match the corresponding Contact\'s Record Type (Thumbtack Pro)');

                //** BEFORE UPDATE Handler **//
                // Account ContactBudgetPercentage__c > 80; a read only formula field = ContactsUsed__c / ContactBudget__c, a condition in Before Update Trigger
                testAccount.ContactsUsed__c = 850;
                testAccount.ContactBudget__c = 10;
                testAccount.OverBudgetEmailSent__c = false;

                testAccount.LastSyncedWithDataPlatform__c = DateTime.now().addMinutes(-60);
                // Switch Record Type from Pro to Customer, and switch Owner Id to see if the changes propagate to the related Contact
                testAccount.RecordTypeId = TestUtilities.ACCOUNT_CUSTOMER_RECORD_TYPE_ID;
                testAccount.OwnerId = newOwner.Id;

                update testAccount;

            Test.stopTest();

            testAccount = TestUtilities.getTestAccountWithContact(); //get updated field values

            // assert results
            System.assertEquals( testAccount.Contacts[0].RecordTypeId, TestUtilities.CONTACT_CUSTOMER_RECORD_TYPE_ID, 'Account\'s Record Type does not match the corresponding Contact\'s Record Type (Customer)');
            System.assertEquals( testAccount.Contacts[0].OwnerId, testAccount.OwnerId, 'Account\'s OwnerId does not equal the related Contact\'s OwnerId AFTER UPDATE trigger event');
            System.assertEquals( true, testAccount.SendOverbudgetEmail__c, 'Account\'s SendOverbudgetEmail__c is false, expected TRUE from BEFORE UPDATE trigger event');

        } //end RunAs
    }

    @IsTest
    static void testAccountOwnershipSetToTackbot()
    {
        User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
        System.runAs(testUser)
        {
            Test.startTest();
            Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(), Name = 'Test Account');
            insert a;
            Test.stopTest();

            a = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
            System.assertEquals(TackBotUtility.getTackBotUser().Id, a.OwnerId);
        }
    }

    @IsTest
    static void testAccountOwnershipNotSetToTackbot()
    {
        User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
        System.runAs(testUser)
        {
            Test.startTest();
            Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Managed Account').getRecordTypeId(), Name = 'Test Account');
            insert a;
            Test.stopTest();

	        a = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
            System.assertNotEquals(TackBotUtility.getTackBotUser().Id, a.OwnerId);
        }
    }
    
    @IsTest
    static void testOnAfterUpdate()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(), Name = 'Test Account');
            Insert a;            
            Enrollment__c enroll = new Enrollment__c(enrollment_id__c = '1-Lead acquisition',
                                                     BusinessName__c = 'Business', 
                                                     Name = 'Business - Lead Acquisition',   
                                                     Phone__c = '1234123412',
                                                     Email__c = 'test@test.com',
                                                     user_id__c = '1',
                                                     Account__c = a.Id,
                                                     SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                                                     outreach_type__c = 'lead_acquisition',
                                                     outreach_group__c = '0_MA', FunnelStep__c = 'Pre-Onboarding'
                                                    );
            Insert enroll;
            RoutingProfile__c rp = new RoutingProfile__c(Name = 'Routing profile for test@test.com',                                                         
                                                         Phone__c = '1234123412',
                                                         Email__c = 'test@test.com',
                                                         Account__c = a.Id,
                                                         Enrollment__c = enroll.Id
            );
            Insert rp;
            a.AccountManager__c = TestUtilities.USER_TACK_BOT.Id;
            update a;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testRouteToEnterprise()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(), Name = 'Test Account', AccountManager__c = TestUtilities.USER_TACK_BOT.Id);
            Insert a;            
            Enrollment__c enroll = new Enrollment__c(enrollment_id__c = '1-Lead acquisition',
                                                     BusinessName__c = 'Business', 
                                                     Name = 'Business - Lead Acquisition',   
                                                     Phone__c = '1234123412',
                                                     Email__c = 'test@test.com',
                                                     user_id__c = '1',
                                                     Account__c = a.Id,
                                                     SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                                                     outreach_type__c = 'lead_acquisition',
                                                     outreach_group__c = '0_MA', FunnelStep__c = 'Pre-Onboarding'
                                                    );
            Insert enroll;
            RoutingProfile__c rp = new RoutingProfile__c(Name = 'Routing profile for test@test.com',                                                         
                                                         Phone__c = '1234123412',
                                                         Email__c = 'test@test.com',
                                                         Account__c = a.Id,
                                                         Enrollment__c = enroll.Id
            );
            Insert rp;
            a.AccountManager__c = NULL;
            update a;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testAccountManagerUpdate()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(), Name = 'Test Account');
            Insert a;            
            Enrollment__c enroll = new Enrollment__c(enrollment_id__c = '1-Lead acquisition',
                                                     BusinessName__c = 'Business', 
                                                     Name = 'Business - Lead Acquisition',   
                                                     Phone__c = '1234123412',
                                                     Email__c = 'test@test.com',
                                                     user_id__c = '1',
                                                     Account__c = a.Id,
                                                     SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                                                     outreach_type__c = 'lead_acquisition',
                                                     outreach_group__c = '0_MA', FunnelStep__c = 'Pre-Onboarding'
                                                    );
            Insert enroll;
            RoutingProfile__c rp = new RoutingProfile__c(Name = 'Routing profile for test@test.com',                                                         
                                                         Phone__c = '1234123412',
                                                         Email__c = 'test@test.com',
                                                         Account__c = a.Id                                       
            );
            Insert rp;
            a.AccountManager__c = TestUtilities.USER_TACK_BOT.Id;
            update a;
            Test.stopTest();
        }
    }
}