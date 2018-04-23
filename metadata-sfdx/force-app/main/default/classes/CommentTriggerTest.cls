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
1.0     01-13-2017  Scott Purcell      Created
=======+===========+=================+================================================8008242049
*/
@istest
public class CommentTriggerTest {
	public static Id brRecordTypeId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Bug Report').getRecordTypeId();
    @isTest static void testbugInsert() {
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');

		Bug__c bug = new Bug__c();
		bug.Affects__c = 'Customers';
		bug.BugDescription__c='This is a text field';
		bug.DateLogged__c=Date.Today().addDays(-5);
		bug.Urgency__c='Non-Urgent';
		bug.Priority__c = 'High';
		bug.IssueType__c = 'bug';
		//bug.Approved__c = true;
		bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
		insert bug;
		Comments__c note = new Comments__c();
		note.Name ='test note';
		note.Bug__c = bug.Id;
		note.Body__c = 'this is the body';
		System.runAs(testUser) 
        {
			Test.startTest();
			insert note;
			Test.stopTest();
			Comments__c notes = [Select Id,Name,Bug__c From Comments__c where Bug__c =: bug.Id LIMIT 1];
			system.debug(notes);
			system.assert(notes!= null);
			system.assertEquals(bug.Id,notes.Bug__c);
			
		}
	}
	@isTest static void testSupportInsert() {
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';

        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');

		Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
		Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester',SuppliedThumbtackID__c=120);
        insert c;
		SupportProcess__c sp = new SupportProcess__c(Name = 'blah blah',Case__c = c.Id,RecordTypeId = brRecordTypeId);

        insert sp;
		Comments__c note = new Comments__c();
		note.Name ='test note';
		note.SupportProcess__c  = sp.Id;
		note.Body__c = 'this is the body';
		System.runAs(testUser) 
        {
			Test.startTest();
			insert note;
			Test.stopTest();
			Comments__c notes = [Select Id,Name,SupportProcess__c From Comments__c where SupportProcess__c =: sp.Id LIMIT 1];
			system.debug(notes);
			system.assert(notes!= null);
			system.assertEquals(sp.Id,notes.SupportProcess__c);
			
		}
	}

}