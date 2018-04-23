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
https://thumbtack--dev.cs17.my.salesforce.com
  

Change List:
------------
Version    Date     Author            Description
=======+===========+=================+=================================
1.0     2016-12-06  Scott Purcell     Created
=======+===========+=================+=================================*/
@istest
public  class RequestTriggerHandlerTest {
    public static Account acc {get;set;}
    public static Service__c service {get;set;}
    public static Request__c request {get;set;}
    
    static testMethod void OnBeforeInsert()
    {
        User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = -2,
            ContactsUsed__c = 850,
            ContactBudget__c = 10,
            CreditBalance__c = 2
            );
        insert acc;
        service = new Service__c(
            Name= 'test Service',
            ProAccount__c = acc.Id
            );
        insert service;
        request = new Request__c(
            Name ='Test Request',
            Status__c = 'New',
            Service__c = service.Id
            );
        System.runAs(testUser) 
        {
            Test.startTest();
                insert request;
            Test.stopTest();
        }
        Request__c r = [Select Id,Status__c From Request__c Where ID =:request.Id LIMIT 1];
        System.assertEquals('New',r.Status__c);
        system.debug('status: '+r.Status__c);
    }
   

    static testMethod void OnBeforeInsertNoCredits()
    {
        User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = -2,
            ContactsUsed__c = 5,
            ContactBudget__c = 10,
            CreditBalance__c = -1
            );
        insert acc;
        service = new Service__c(
            Name= 'test Service',
            ProAccount__c = acc.Id,
            StartDate__c = Date.today().addDays(-16),
            ProAssistantSubscriptionType__c = 'Quoting Service'
            );
        insert service;
        request = new Request__c(
            Name ='Test Request',
            Status__c = 'New',
            Service__c = service.Id
            );
        System.runAs(testUser) 
        {
            Test.startTest();
                insert request;
            Test.stopTest();
        }
        Request__c r = [Select Id,Status__c From Request__c Where ID =:request.Id LIMIT 1];
        System.assertEquals('New',r.Status__c);
        system.debug('status: '+r.Status__c);
    }

    static testMethod void OnBeforeInsertProPAused()
    {
        User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = -2,
            ContactsUsed__c = 850,
            ContactBudget__c = 10,
            CreditBalance__c = 0
            );
        insert acc;
        service = new Service__c(
            Name= 'test Service',
            ProAccount__c = acc.Id,
            QuotingServiceStatus__c = 'Off',
            StartDate__c = Date.today().addDays(-16)
            );
        insert service;
        request = new Request__c(
            Name ='Test Request',
            Status__c = 'New',
            Service__c = service.Id
            );
        System.runAs(testUser) 
        {
            Test.startTest();
                insert request;
            Test.stopTest();
        }
        Request__c r = [Select Id,Status__c From Request__c Where ID =:request.Id LIMIT 1];
        System.assertEquals('Pro Paused',r.Status__c);
        system.debug('status: '+r.Status__c);
    }


    static testMethod void OnBeforeUpdate()
    {
          User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = -2,
            ContactsUsed__c = 850,
            ContactBudget__c = 10,
            CreditBalance__c = 2
            );
        insert acc;
        service = new Service__c(
            Name= 'test Service',
            ProAccount__c = acc.Id
            );
        insert service;
        request = new Request__c(
            Name ='Test Request',
            Service__c = service.Id,
            Status__c = 'New'
            );
        System.runAs(testUser) 
        {
            Test.startTest();
                insert request;
                update request;
            Test.stopTest();
        }

        List<Request__c> rs = [Select Id,Status__c From Request__c];
        
        for(Request__c s:rs)
        {
            system.debug('status: '+s.Status__c);
            System.assertEquals('New',s.Status__c);
        }
        
    }
    static testMethod void OnBeforeUpdateProPaused()
    {
          User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = -2
            );
        insert acc;
        service = new Service__c(
            Name= 'test Service',

            ProAccount__c = acc.Id
            );
        insert service;
        request = new Request__c(
            Name ='Test Request',
            Service__c = service.Id,
            Status__c = 'New'
            );
        System.runAs(testUser) 
        {
            Test.startTest();
                insert request;
                acc.ContactsUsed__c = 850;
                acc.ContactBudget__c = 10;
                acc.CreditBalance__c = 2;
                service.QuotingServiceStatus__c = 'Off';
                update service;
                update acc;
                update request;
            Test.stopTest();
        }
        
        List<Request__c> rs = [Select Id,Status__c From Request__c];
        
        for(Request__c s:rs)
        {
            system.debug('status: '+s.Status__c);
        }
        
    }

}