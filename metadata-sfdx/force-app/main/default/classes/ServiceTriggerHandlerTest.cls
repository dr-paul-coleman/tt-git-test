/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version    Date     Author            Description
=======+===========+=================+===========================================
1.0     2016-12-13  Scott Purcell     Created
1.1     2016-12-14  Scott Purcell     AddedQuotingService tests
1.3     2017-10-02  Meena Pisupati	  Replaced Proassist with Instant Match; 
									  Updated Header
=======+===========+=================+===========================================*/
@isTest
private class ServiceTriggerHandlerTest {
    public static Id customerSuccessFlagRecTypeId = CustomerSuccessGuidance__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Success Flag').getRecordTypeId();
    static testMethod void OnBeforeInsertOnExistingQuotingServiceCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
                g.CSFlagType__c = 'Quoting Service Program';
                insert g;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = g.Account__c;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('serviceemail@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOnExistingProAssistCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
                g.CSFlagType__c = 'Instant Match Program';
                insert g;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = g.Account__c;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('serviceemail@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOnQuotingService()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Quoting Service' And CSFlagType__c = 'Quoting Service Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOnQuotingServiceDeleteOldCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
                insert serv;

                Service__c serv2 = new Service__c();
                serv2.Name='test service';
                serv2.RecordTypeId = '01231000001Idqs';
                serv2.QuotingServiceStatus__c = 'ON';
                serv2.ProAccount__c = acoun.Id;
                serv2.usr_email__c = 'serviceemail@test.com';
                serv2.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            Test.startTest();  
                insert serv2;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Quoting Service' And CSFlagType__c = 'Quoting Service Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOnProAssist()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Instant Match' And CSFlagType__c = 'Instant Match Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOnProAssistDeleteOldCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                insert serv;

                Service__c serv2 = new Service__c();
                serv2.Name='test service';
                serv2.RecordTypeId = '01231000001Idqs';
                serv2.QuotingServiceStatus__c = 'ON';
                serv2.ProAccount__c = acoun.Id;
                serv2.usr_email__c = 'serviceemail@test.com';
                serv2.ProAssistantSubscriptionType__c = 'Instant Match';
            Test.startTest();  
                insert serv2;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Instant Match' And CSFlagType__c = 'Instant Match Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOff()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
                insert g;
                
                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'OFF';
                serv.ProAccount__c = g.Account__c;
                serv.usr_email__c = 'serviceemail@test.com';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('serviceemail@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
            System.assertEquals(0,cg.size());

        }
        
    }

    static testMethod void OnBeforeInsertOffProAssist()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
                g.CSFlagType__c = 'Instant Match Program';
                insert g;
                
                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'OFF';
                serv.ProAccount__c = g.Account__c;
                serv.usr_email__c = 'serviceemail@test.com';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('serviceemail@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
            System.assertEquals(0,cg.size());

        }
        
    }
    static testMethod void OnBeforeInsertQuotingServiceOff()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account a = ObjectUtility.createAccount();
                insert a;  
                
                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'OFF';
                serv.ProAccount__c = a.Id;
                serv.usr_email__c = 'serviceemail@test.com';
            Test.startTest();  
                insert serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:a.id Limit 1];
            system.assertEquals('serviceemail@test.com', afterTest.UserEmail__c);
             List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: a.Id];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(0,cg.size());
        }
        
    }
    static testMethod void OnBeforeInsertBulk()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        List<Service__c> servList = new List<Service__c>();
        List<String> ids = new List<String>();
        System.runAs(testUser) 
        {  
            CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
            insert g;

            for(Integer i=0;i<200;i++)
            {
                Service__c serv = new Service__c();
                    serv.Name='test service'+i;
                    serv.ProAccount__c = g.Account__c;
                    serv.usr_email__c = 'serviceemail@test.com';
                    serv.RecordTypeId = '01231000001Idqs';
                    serv.QuotingServiceStatus__c = 'ON';
                    serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                    servList.add(serv);
            }
            Test.startTest();  
                insert servList;    
            Test.stopTest();
            for(Service__c s:servList)
            {
                ids.add(s.ProAccount__c);
            }

        
            List<Account> afterTest = [Select Name,Id,UserEmail__c From Account Where Id IN:ids];
            for(Account acc:afterTest)
            {
                system.assertEquals('serviceemail@test.com', acc.UserEmail__c);
            }
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(1,cg.size());
        }
        
    }
//******************************************
/*   static testMethod void OnAfterInsert()
    {

    }
    static testMethod void OnAfterInsertBulk()
    {
      for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
//******************************************
static testMethod void OnBeforeUpdateCreateCSGNOMAtch()
    {
        
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            Account acc = new Account(Name='Chester Tester',Phone='8018675309',usr_first_name__c='Chester',usr_last_name__c='Tester',usr_email__c='chester@bogus.thumbtack.com',usr_user_id__c=-1);
            insert acc;
            Service__c serv = new Service__c();
            serv.Name='test service';
            serv.ProAccount__c = acc.Id;
            serv.usr_email__c = 'serviceemail@test.com';
            serv.RecordTypeId = '01231000001Idqs';
            serv.QuotingServiceStatus__c = 'ON';
            serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            insert serv; 

            Test.startTest(); 
                serv.ProAssistantManagedBy__c = 'Sales & Account Management';//changed from 'Enterprise' to 'Sales & Account Management'
                update serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> csgList = [Select Id FROM CustomerSuccessGuidance__c];
            system.debug('OnBeforeUpdateCreateCSG.csgList: '+csgList);
        }
    }
    static testMethod void OnBeforeUpdateCreateCSGWithMatch()
    {
        
        User testUser = [SELECT id,Name FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
            Account acc = new Account(Name='Chester Tester',Phone='8018675309',usr_first_name__c='Chester',usr_last_name__c='Tester',usr_email__c='chester@bogus.thumbtack.com',usr_user_id__c=-1);
            insert acc;

            Service__c serv = new Service__c();
            serv.Name='test service';
            serv.ProAccount__c = acc.Id;
            serv.usr_email__c = 'serviceemail@test.com';
            serv.RecordTypeId = '01231000001Idqs';
            serv.QuotingServiceStatus__c = 'ON';
            serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            insert serv; 
            CustomerSuccessGuidance__c csg = new CustomerSuccessGuidance__c(
                                RecordTypeID = customerSuccessFlagRecTypeId,
                                OwnerId = testUser.id,
                                Account__c = acc.Id,
                                Name = testUser.Name,
                                CSFlagType__c = 'Sales & Account Management'
                            );//changed from 'Enterprise' to 'Sales & Account Management'
            insert csg;
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acc.Id];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(2,cg.size());

            Test.startTest(); 
                serv.ProAssistantManagedBy__c = 'Sales & Account Management'; //changed from 'Enterprise' to 'Sales & Account Management'
                update serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> csgList = [Select Id FROM CustomerSuccessGuidance__c];
            system.debug('OnBeforeUpdateCreateCSG.csgList: '+csgList);
        }
    }
    static testMethod void OnBeforeUpdate()
    {
        
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
            insert g;

            Service__c serv = new Service__c();
            serv.Name='test service';
            serv.ProAccount__c = g.Account__c;
            serv.usr_email__c = 'serviceemail@test.com';
            serv.RecordTypeId = '01231000001Idqs';
            serv.QuotingServiceStatus__c = 'ON';
            serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            insert serv; 

            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(1,cg.size());

            Service__c serv2 = new Service__c();
            serv2.Name='test service2';
            serv2.ProAccount__c = g.Account__c;
            serv2.usr_email__c = 'serviceemail2@test.com';
            serv2.RecordTypeId = '01231000001Idqs';
            serv2.QuotingServiceStatus__c = 'OFF';
            serv2.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            insert serv2;

            Test.startTest(); 
                serv.usr_email__c = 'updatetest@test.com';
                serv.QuotingServiceStatus__c = 'OFF';
                update serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('updatetest@test.com', afterTest.UserEmail__c);
            cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(0,cg.size());
        }
    }

    static testMethod void OnBeforeUpdateOffDeleteExistingCSG()
    {
        
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
            insert g;

            Service__c serv = new Service__c();
            serv.Name='test service';
            serv.ProAccount__c = g.Account__c;
            serv.usr_email__c = 'serviceemail@test.com';
            serv.RecordTypeId = '01231000001Idqs';
            serv.QuotingServiceStatus__c = 'ON';
            serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
            insert serv; 

            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(1,cg.size());

            Test.startTest(); 
                serv.QuotingServiceStatus__c = 'OFF';
                update serv;    
            Test.stopTest();
        
            cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(0,cg.size());
        }
    }

    static testMethod void OnBeforeUpdateOnQuotingService()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'OFF';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                insert serv;
                
            Test.startTest();  
                serv.QuotingServiceStatus__c = 'ON';
                update serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Quoting Service' And CSFlagType__c = 'Quoting Service Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeUpdateOnQuotingServiceDeleteOldCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
                insert serv;
                
            Test.startTest();  
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                update serv;    
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Quoting Service' And CSFlagType__c = 'Quoting Service Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeUpdateOnProAssist()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'OFF';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
                insert serv;

            Test.startTest();  
                serv.QuotingServiceStatus__c = 'ON';
                update serv;   
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Instant Match' And CSFlagType__c = 'Instant Match Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeUpdateOnProAssistDeleteOldCSG()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
                Account acoun = ObjectUtility.createAccount();
                insert acoun;

                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.ProAccount__c = acoun.Id;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                insert serv;

            Test.startTest();  
                serv.ProAssistantSubscriptionType__c = 'Instant Match';
                update serv;   
            Test.stopTest();
        
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: acoun.Id And Name = 'Instant Match' And CSFlagType__c = 'Instant Match Program'];
            System.assertEquals(1,cg.size());

        }
        
    }

    static testMethod void OnBeforeUpdateNoMatch()
    {
        
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            Account a = ObjectUtility.createAccount();

            Service__c serv = new Service__c();
            serv.Name='test service';
            serv.ProAccount__c = a.id;
            serv.usr_email__c = 'serviceemail@test.com';
            serv.RecordTypeId = '01231000001Idqs';
            serv.QuotingServiceStatus__c = 'ON';
            serv.sav_available_service_id__c = 1;
            serv.sav_usr_user_id__c = 1;
            serv.usr_first_name__c = 'First Name';
            serv.usr_last_name__c = 'Last Name';
            insert serv; 

            Test.startTest(); 
                serv.usr_email__c = 'updatetest@test.com';
                update serv;    
            Test.stopTest();
        
            List<Account> afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:a.Id Limit 1];
             system.debug('afterTest: '+afterTest);
            //system.assertEquals('updatetest@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =:a.Id];
             system.debug('cgsize: '+cg.size());
            //System.assertEquals(1,cg.size());
        }
    }
    static testMethod void OnBeforeUpdateQuotingServiceOff()
    {
        
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
            insert g;
               
                Service__c serv = new Service__c();
                serv.Name='test service';
                serv.ProAccount__c = g.Account__c;
                serv.usr_email__c = 'serviceemail@test.com';
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'Off';
                insert serv; 
            Test.startTest(); 
                serv.usr_email__c = 'updatetest@test.com';
                update serv;    
            Test.stopTest();
        
            Account afterTest = [Select Name,Id,UserEmail__c From Account Where Id =:g.Account__c Limit 1];
            system.assertEquals('updatetest@test.com', afterTest.UserEmail__c);
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(0,cg.size());
        }
    }
    static testMethod void OnBeforeUpdateBulk()
    {
        User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        List<Service__c> servList = new List<Service__c>();
        List<String> ids = new List<String>();
        System.runAs(testUser) 
        {

            CustomerSuccessGuidance__c g = ObjectUtility.createCustomerSuccessGuidance();
            insert g;
            for(Integer i=0;i<200;i++)
            {
                Service__c serv = new Service__c();
                serv.Name='test service'+i;
                serv.ProAccount__c = g.Account__c;
                serv.RecordTypeId = '01231000001Idqs';
                serv.QuotingServiceStatus__c = 'ON';
                serv.usr_email__c = 'serviceemail@test.com';
                serv.ProAssistantSubscriptionType__c = 'Quoting Team Only';
                servList.add(serv);
            }
            insert servList;
            for(Service__c s:servList)
            {
                s.usr_email__c = 'updatedemail@test.com';
                ids.add(s.Id);
            }  
            Test.startTest(); 
                update servList;  
            Test.stopTest();
        
            List<Account> afterTest = [Select Name,Id,UserEmail__c From Account Where Id IN:ids];
            for(Account acc:afterTest)
            {
                system.assertEquals('updatedemail@test.com', acc.UserEmail__c);
            }
            List<CustomerSuccessGuidance__c> cg = [Select Name,Id From CustomerSuccessGuidance__c Where Account__c =: g.Account__c];
             //system.debug('cgsize: '+cg.size());
            System.assertEquals(1,cg.size());
        }
        
    }
//******************************************
    /*static testMethod void OnAfterUpdate()
    {
        
    }
    static testMethod void OnAfterUpdateBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
//******************************************
   /* static testMethod void OnBeforeDelete()
    {
        
    }
    static testMethod void OnBeforeDeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
//******************************************
    /*static testMethod void OnAfterDelete()
    {
        
    }
    static testMethod void OnAfterDeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
//******************************************
   /* static testMethod void OnUndelete()
    {
        
    }
    static testMethod void OnUndeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
    
}