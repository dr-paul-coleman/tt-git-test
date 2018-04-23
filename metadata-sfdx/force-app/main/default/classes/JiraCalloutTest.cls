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
=======+===========+=================+================================================
*/
@istest
public with sharing class JiraCalloutTest 
{

	public static testMethod void testSingleCallout() 
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
		
		System.runAs(testUser) 
        {
			Test.startTest();
			insert bug;
			JiraCallout.UpdateIssue(bug.Id);
			Test.stopTest();
			List<Bug__c> bugs = [Select Id,Affects__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,Urgency__c From Bug__c Where Id =:bug.Id];
			system.debug(bugs);
			//Verify response received contains fake values
			String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}

    }
    @isTest static void testSingleNoteInsert() {
    	JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		Note note = new Note();
		note.Title ='test note';
		note.ParentId = bug.Id;
		note.Body = 'this is the body';
		System.runAs(testUser) 
        {
			Test.startTest();
			insert note;
			Test.stopTest();
			Note notes = [Select Id,Title,ParentId From Note where ParentId =: bug.Id LIMIT 1];
			system.debug(notes);
			system.assert(notes!= null);
			system.assertEquals(bug.Id,Notes.ParentId);
			
		}
	}
	@isTest static void testSingleCommentInsert() {
    	JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		List<String> noteList = new List<String>();
		Comments__c note = new Comments__c();
		note.Name ='test note';
		note.Bug__c= bug.Id;
		note.Body__c = 'this is the body';
		insert note;
		noteList.add(note.Id);
		System.runAs(testUser) 
        {
			Test.startTest();
				JiraCallout.addComment(noteList);
			Test.stopTest();
		}
	}
	 public static testMethod void testSingleSupportProcessCallout() 
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		insert sp;
		
		System.runAs(testUser) 
        {
			Test.startTest();
				JiraCallout.createSupportProcessIssue(sp.Id);
				JiraCallout.updateSupportProcessIssue(sp.Id);
			Test.stopTest();
			List<SupportProcess__c> bugs = [Select Id,DateBugFixed__c,IssueSentToJiraStatus__c,JIRALink__c From SupportProcess__c Where Id =:sp.Id];
			system.debug(bugs);
			//Verify response received contains fake values
			String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}

    }
    public static testMethod void testGetComments() 
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		insert sp;
		
		System.runAs(testUser) 
        {
			Test.startTest();
				JiraCallout.getComments(sp.Id,'1234',true);
			Test.stopTest();
			List<SupportProcess__c> bugs = [Select Id,DateBugFixed__c,IssueSentToJiraStatus__c,JIRALink__c From SupportProcess__c Where Id =:sp.Id];
			system.debug(bugs);
			//Verify response received contains fake values
			String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}

    }
    public static testMethod void testSingleCalloutUpdate()                               
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;

		Test.setMock(HttpCalloutMock.class, new JiraMock());
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
		bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
		insert bug;
		
		System.runAs(testUser) 
        {
			Test.startTest();
			bug.Approved__c = true;
			update bug;
			Test.stopTest();
			List<Bug__c> bugs = [Select Id,Affects__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,Urgency__c From Bug__c Where Id =:bug.Id];
			system.debug(bugs);
			//Verify response received contains fake values
			String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}

    }
	public static testMethod void testBulkCallout()
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;
		Test.setMock(HttpCalloutMock.class, new JiraMock());
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');
		List<Bug__c> bugList = new List<Bug__c>();
		for(Integer i = 0;i<100;i++)
		{
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
			bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
			buglist.add(bug);
		}
		System.runAs(testUser) 
        {
			Test.startTest();
			insert bugList;
			Test.stopTest();

			List<Bug__c> bugs = [Select Id,Affects__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,Urgency__c From Bug__c Where Id IN: bugList];
			system.debug(bugs);
			// Verify response received contains fake values
       		String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}
    }
    public static testMethod void testBulkCalloutUpdate()
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;
		Test.setMock(HttpCalloutMock.class, new JiraMock());
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');
		List<Bug__c> bugList = new List<Bug__c>();
		for(Integer i = 0;i<100;i++)
		{
			Bug__c bug = new Bug__c();
			bug.Affects__c = 'Customers';
			bug.BugDescription__c='This is a text field';
			bug.DateFixed__c=Date.Today();
			bug.DateLogged__c=Date.Today().addDays(-5);
			bug.JIRALink__c='http://Google.com';
			bug.Urgency__c='Non-Urgent';
			bug.Priority__c = 'High';
			bug.IssueType__c = 'bug';
			bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
			buglist.add(bug);
			
		}
		insert bugList;
		System.runAs(testUser) 
        {
			Test.startTest();
			for(Bug__c b:bugList)b.Approved__c = true;
			update bugList;
			Test.stopTest();

			List<Bug__c> bugs = [Select Id,Affects__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,Urgency__c From Bug__c Where Id IN: bugList];
			system.debug(bugs);
			// Verify response received contains fake values
       		String contentType = JiraCallout.res.getHeader('Content-Type');
			System.assert(contentType == 'application/json');
			String actualValue = JiraCallout.res.getBody();
			String expectedValue = '{"id":"21466","key":"AV-8940","self":"https://thumbtack.atlassian.net/rest/api/2/issue/21466"}';
			System.assertEquals(actualValue, expectedValue);
			System.assertEquals(200, JiraCallout.res.getStatusCode());
		}
    }
    @isTest static void testUpdateAttachment() 
	{
		JiraAPI__c cs = new JiraAPI__c();
        cs.Name='default';
        cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
        cs.Password__c = 'pass';
        cs.UserName__c = 'user' ;
        //cs.Other fiels values
     	insert cs;
		Test.setMock(HttpCalloutMock.class, new JiraMock());

		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';

		Bug__c bug = new Bug__c();
		bug.Affects__c = 'Customers';
		bug.BugDescription__c='This is a text field';
		bug.DateLogged__c=Date.Today().addDays(-5);
		bug.Urgency__c='Non-Urgent';
		bug.Priority__c = 'High';
		bug.IssueType__c = 'bug';
		bug.Approved__c = false;
		bug.JiraId__c = '123456';
		bug.Labels__c = 'Customer-Support;Customer-Support-Non-Urgent;Customer-Support-Semi-Urgent;Customer-Support-Urgent;Customer-Support-Ongoing';
		insert bug;

		Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=bug.id;
        insert attach;

		System.runAs(testUser) 
        {
			Test.startTest();
        		update attach;
    		Test.stopTest();
    	
	    	List<Attachment> attachments=[Select Id,Name From Attachment Where ParentId =: bug.Id];
	    	System.assertEquals(1, attachments.size());
    	}
	}
	
}