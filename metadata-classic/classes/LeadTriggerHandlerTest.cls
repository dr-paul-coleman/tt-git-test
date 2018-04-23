/*
 Copyright (c) 2016 Thumbtack. All rights reserved.

 Change List:                                                               
 ------------
 Version    Date     Author            Description                          
 =======+===========+=================+==================================================
 1.0     2018-02-05  Meena Pisupati    Test class for LeadTrigger and LeadTriggerHandler
 =======+===========+=================+==================================================*/
@isTest
public class LeadTriggerHandlerTest {
    public static Id LEAD_MA_RECORD_TYPE_ID = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Account Lead').getRecordTypeId();
	public static Id ENROLL_PRODUCT_ENABLED_RECORD_TYPE_ID = Schema.Sobjecttype.Enrollment__c.getRecordTypeInfosByName().get('Product Enabled').getRecordTypeId();
    public static Id SMART_ROUTING_RECORD_TYPE_ID = RoutingProfile__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Smart Routing').getRecordTypeId();              

    @IsTest
    static void testCreateEnrollment()
    {
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test company',
            OwnerId = TestUtilities.USER_TACK_BOT.Id,
            RecordTypeId = LEAD_MA_RECORD_TYPE_ID,
            Status = 'Prospecting',
            LeadSource = 'Email',
            Email = 'a@b.com',
            Phone = '1231231234',
            AccountManager__c = TestUtilities.USER_TACK_BOT.Id
        );
        Insert ld;
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            ld.UserID__c = 100;
            update ld;
            Test.stopTest();        
        }
    }
    
    @isTest
    static void testUpdateEnrollment()
    {
        Account a = new Account(
            AccountManager__c = TestUtilities.USER_TACK_BOT.Id,
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId(), 
            Name = 'Test Account',
            usr_user_id__c = 1            
        );
        Insert a;        
        RoutingProfile__c rp = new RoutingProfile__c(
                RecordtypeId = SMART_ROUTING_RECORD_TYPE_ID,
                Name = 'Routing Profile for a@b.com',
                Email__c = 'a@b.com',
                Phone__c = '1234567890',
                Phone3__c = '1231231234',
                Sales__c = TRUE
            );
        Insert rp; 
        Enrollment__c en = new Enrollment__c(
            enrollment_id__c = '1-Lead Acquisition', 
            Account__c = a.Id, 
            FirstName__c = 'First', 
            LastName__c = 'Last',
            user_id__c = '1', 
            RecordTypeId = ENROLL_PRODUCT_ENABLED_RECORD_TYPE_ID, 
            outreach_type__c = 'lead_acquisition',
            outreach_group__c = '0_MA',
            FunnelStep__c = 'Pre-Onboarding',
            Email__c = 'a@b.com',
            Phone__c = '1231231234'
        );
        Insert en;
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test company2',
            OwnerId = TestUtilities.USER_TACK_BOT.Id,
            RecordTypeId = LEAD_MA_RECORD_TYPE_ID,
            Status = 'Prospecting',
            LeadSource = 'Email',
            Email = 'a@b.com',
            Phone = '1231231234'
        );
        Insert ld;
        ld = [SELECT Id,UserID__c,SalesRep__c FROM Lead WHERE Id = :ld.Id LIMIT 1];
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            ld.UserID__c = 1;
            update ld;
            Test.stopTest();        
        }
    }
     
    @isTest
    static void testCreateRoutingProfileSOSL()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
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
            Lead ld = new Lead(
                RecordTypeId = LEAD_MA_RECORD_TYPE_ID,
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test company',
                OwnerId = TestUtilities.USER_TACK_BOT.Id,
                SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                Status = 'Prospecting',
                LeadSource = 'Email',
                Email = 'a@b.com',
                Phone = '9090909090'
            );
            Insert ld;    
            Test.startTest();             
            ld.UserID__c = 1;
            Update ld;
            Test.stopTest();        
        }
    }
    
    @isTest
    static void testMissingEmail()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
             Lead ld = new Lead(
                RecordTypeId = LEAD_MA_RECORD_TYPE_ID,
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test company',
                OwnerId = TestUtilities.USER_TACK_BOT.Id,
                SalesRep__c = TestUtilities.USER_TACK_BOT.Id,
                Status = 'Prospecting',
                LeadSource = 'Email',
                Phone = '9090909090'
            );
            Test.startTest();             
           	Insert ld;          
            Test.stopTest();              
        }
    }
    
    @isTest
    static void testMissingPhone()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
             Lead ld = new Lead(
                RecordTypeId = LEAD_MA_RECORD_TYPE_ID,
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test company',
                OwnerId = TestUtilities.USER_TACK_BOT.Id,
                Status = 'Prospecting',
                LeadSource = 'Email'
             );
            Test.startTest();             
           	Insert ld;
            ld.SalesRep__c = TestUtilities.USER_TACK_BOT.Id;
            update ld;
            Test.stopTest();              
        }
    }
}