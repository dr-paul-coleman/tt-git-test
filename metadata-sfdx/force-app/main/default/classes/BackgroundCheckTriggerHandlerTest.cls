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
=======+===========+=================+================================================
1.0     04-12-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@isTest
private class BackgroundCheckTriggerHandlerTest {
	
	@isTest static void testAddBCheckToCase() {
        CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;

        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) {
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            Id accountRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account a = new Account(Name='Chester Tester',RecordTypeId=accountRTId,usr_email__c = 'test@test.com');
            insert a;
            Case cas = new Case(Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Phone',SubCategory__c='Trigger Testing',SuppliedEmail='test@test.com',Subject ='CONSIDER',Description ='The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team');
            
            insert cas;
            Test.startTest();
            cas.BGCReportId__c = '1234';
            update cas;

          
            BackgroundCheck__c bc = [Select Id,CandidateId__c From BackgroundCheck__c];
            bc.CandidateId__c = '123456';
            update bc;
            bc.AdverseItems__c = 'advers item 1,advers item2';
            update bc;
            Test.stopTest();
            system.assert(bc != null);
            Case c = [Select Id,BackgroundCheck__c From Case];
            system.assertEquals(c.BackgroundCheck__c , bc.Id);
        }
    } 
	
	
	
}