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
1.0     05-15-2017  Scott Purcell      Created
=======*/
@istest
public with sharing class JIRASupportProcessUpdateTest {
	public static testMethod void testSingleUpdate() 
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new GetJiraIssueMock());
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');

		 Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester',SuppliedThumbtackID__c=120);
        insert c;
		SupportProcess__c sp = new SupportProcess__c();
		sp.DateBugFixed__c=Date.Today();
		sp.JIRASummary__c='summary';
		sp.JIRALink__c='http://Google.com';
		sp.JIRAEscalationNotes__c = 'notes';
		sp.Case__c = c.Id;
		sp.JiraId__c = '1234';
		insert sp;
		System.runAs(testUser) 
        {
			Test.startTest();
				JIRASupportProcessUpdate.getIssue(sp.Id);
			Test.stopTest();
			List<SupportProcess__c> bugs = [Select Id,DateBugFixed__c,IssueSentToJiraStatus__c,JIRALink__c From SupportProcess__c Where Id =:sp.Id];
			system.debug(bugs);
			
		}

    }
}