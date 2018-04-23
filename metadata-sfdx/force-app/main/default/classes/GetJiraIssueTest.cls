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
1.0     02-27-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@isTest
private class GetJiraIssueTest {
	
	public static testMethod void testSingleCallout() 
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

		Bug__c bug = new Bug__c();
		bug.Affects__c = 'Customers';
		bug.BugDescription__c='This is a text field';
		bug.DateFixed__c=Date.Today();
		bug.DateLogged__c=Date.Today().addDays(-5);
		bug.JIRALink__c='http://Google.com';
		bug.Urgency__c='Non-Urgent';
		bug.Priority__c = 'High';
		bug.IssueType__c = 'bug';
		bug.Approved__c = true;
		bug.JiraId__c = '12345';
		bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
		insert bug;
        Note note = new Note();
		note.Title ='test note';
		note.ParentId = bug.Id;
		note.Body = 'this is the body';
        insert note;
		System.runAs(testUser) 
        {
			Test.startTest();
			List<Bug__c> bugs = [Select Id,Affects__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,Urgency__c From Bug__c Where Id =:bug.Id];
			system.debug(bugs);
			GetJiraIssue.getIssue(bugs[0].Id);
			Test.stopTest();
			
		}

    }
	
}