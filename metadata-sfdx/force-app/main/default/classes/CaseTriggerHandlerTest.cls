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

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-07-03  Paul Coleman      Created 
 1.1     2016-05-10  Paul Coleman      Test mods for  SuppliedThumbtackID__c
 1.2     2017-10-06  Mendel Guillaume  Case activity to Incident (Process builder Flow)
 1.3     2017-10-30  Paul Coleman      Emergency Fix for recursive MI => Case => MI DML
 =======+===========+=================+=================================*/
 @isTest
 public with sharing class CaseTriggerHandlerTest
 {
     @isTest static void testCloseCaseMiIncidentHandler()
     {
         User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
         System.runAs(testUser)
         {
             Id caseRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
             Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
             Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
             Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
             Decimal testProUserId = 100;
             Decimal testCustomerUserId = 200;
             Account aPro = new Account(Name = 'Chester Pro', usr_user_id__c = testProUserId, usr_email__c = 'protester@t.est', RecordTypeId = accProRT, MIOpenIncident__c = true);
             Account aCustomer = new Account(Name = 'Tester Customer', usr_user_id__c = testCustomerUserId, usr_email__c = 'customertester@t.est', RecordTypeId = accCustomerRT, MIOpenIncident__c = true);
             insert new Account[] {aPro, aCustomer};

             Case aCase = new Case(accountId = aPro.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Email', RecordTypeId = caseRT, MICasePrimaryPro__c = false, MICasePrimaryCustomer__c = false);
             insert aCase;
             System.assert(null != aCase.Id, 'Test Case not inserted properly');
             MiIncident__c mii = new MiIncident__c(
                     Name = 'Test',
                     quotes_pro_user_id__c = testProUserId,
                     quotes_customer_id__c = testCustomerUserId,
                     quotes_bid_id__c = 1,
                     RequestID__c = '1',
                     ResolutionTier__c = 'Tier 0 - Lost Communication',
                     MICategory__c = 'Removed',
                     MISubcategory__c = 'Other',
                     Status__c = 'In Progress',
                     ProAccount__c = aPro.Id,
                     IncidentCategorization__c = '0 - Not enough details');
             insert mii;
             Test.startTest();

                 //insert new case to trigger new logic
                 Case c = new Case(AccountId = aPro.Id, RecordTypeId = caseRTId, Origin = 'Email', SuppliedEmail = 'tester@bogus.testing.com', SuppliedName = 'Chester CaseTester', SuppliedThumbtackID__c = 120, MICasePrimaryPro__c = false, MICasePrimaryCustomer__c = false);
                 insert c;
                 Case c2 = new Case(Category__c = 'Marketplace Integrity', Subcategory__c = 'Incident', AccountId = aCustomer.Id, RecordTypeId = caseRTId, Origin = 'Email', SuppliedEmail = 'tester@bogus.testing.com', SuppliedName = 'Chester CaseTester', SuppliedThumbtackID__c = 120, MICasePrimaryPro__c = false, MICasePrimaryCustomer__c = false);
                 insert c2;
                 c.Category__c = 'Marketplace Integrity';
                 c.Subcategory__c = 'Incident';
                 update c;
                 update c2;

             Test.stopTest();

             //REQ'd TODO add assertion
         }

     }

     @isTest static void testAddBCheckAndCsatToCase()
     {
         insert new CheckerAPISettings__c(Name = 'default', BaseURL__c = 'http://api.salesforce.com/foo/bar', Password__c = '1', UserName__c = 'user' );
         Case cas;
         Case casse;

         System.runAs(TestUtilities.USER_TACK_BOT)
         {
             Id caseRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
             Account acct = new Account(
                     Name = 'Chester Tester',
                     Phone = '8018675309',
                     usr_first_name__c = 'Chester',
                     usr_last_name__c = 'Tester',
                     usr_email__c = 'chester@bogus.thumbtack.com',
                     usr_user_id__c = -2
             );
             insert acct;

             Contact[] contct = [select Id From Contact Where AccountId = :acct.Id LIMIT 1];
             cas = new Case(Subject = 'CONSIDER', Description = 'The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team', Status = 'New', ContactId = contct[0].Id, RecordTypeId = caseRTId, Origin = 'Phone', AccountId = acct.Id, IsTestData__c = false, Category__c = 'Phone', SubCategory__c = 'Trigger Testing', SuppliedEmail = 'test@test.com');
             casse = new Case(Status = 'New', RecordTypeId = caseRTId, Origin = 'Phone', ContactId = contct[0].Id, AccountId = acct.Id, IsTestData__c = false, Category__c = 'Phone', SubCategory__c = 'Trigger Testing');
             insert casse;
             insert cas;

             Test.startTest();
                cas.BGCReportId__c = '1234';
                update cas;

                casse.Status = 'Closed';
                update casse;

             Test.stopTest();

             for( Case cs: [SELECT Id, BackgroundCheck__c, (SELECT Id FROM SurveyResponses__r WHERE Status__c = 'Pending' ) From Case] )
             {
                 if( cs.Id == casse.Id )
                 {
                     System.assertNotEquals( true, cs.SurveyResponses__r.isEmpty(), 'CSAT__c NOT inserted');
                 }
                 else if ( cs.Id == cas.Id )
                 {
                     System.assertNotEquals( NULL, cs.BackgroundCheck__c, 'BackgroundCheck__c NOT inserted');
                 }
             }

         }
     }

     @IsTest
     static void testCaseActivityToIncidentCallLogInsert()
     {
         User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
         System.runAs(testUser)
         {
             Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
             insert customer;

             Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
             insert pro;

             MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id,
                     NewCallFlag__c = false, Status__c = 'In Progress', RecordTypeId = CaseTriggerHandler.miIncidentRecordTypeId);
             insert incident;

             Test.startTest();

                 Case c = new Case(AccountId = customer.Id, Subject = 'MI Test Case', Status = 'New',
                         Incident__c = incident.Id, Origin = 'Suggestion Box', CaseFeedFlag__c = 'Call Log Feed');
                 insert c;

             Test.stopTest();

             c = [SELECT Id, CaseFeedFlag__c FROM Case WHERE Id = :c.Id];
             System.assertEquals(null, c.CaseFeedFlag__c);

         }
     }

 }