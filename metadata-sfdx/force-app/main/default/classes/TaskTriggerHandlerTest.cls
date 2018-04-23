/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : TaskTriggerHandlerTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : Tests for TaskTriggerHandler/TaskTrigger

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-05-13  Paul Coleman      Created
 1.1     2017-09-28  Mendel Guillaume  Test method for first response functionality
 =======+===========+=================+=================================*/
@isTest
private class TaskTriggerHandlerTest
{
	static testMethod void testSetWhoIdFromCaseContact()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Id MIRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
			Account a = new Account(Name = 'Chester Tester');
			insert a;
			Contact ct = new Contact(LastName = 'Tester', FirstName = 'Chester', AccountId = a.Id);
			insert ct;
			Case c = new Case(AccountId = a.Id, Status = 'New', ContactId = ct.Id, RecordTypeId = MIRTId);
			insert c;
			Task t = new Task(WhatId = c.Id, CallType = 'Inbound');

			Test.startTest();
			insert t;
			Test.stopTest();

			System.assert([SELECT Id,WHoId FROM Task WHERE Id = :t.Id LIMIT 1].WhoId == ct.Id, 'Case.ContactId did not transfer to Task record');
		}
	}

	static testMethod void testSetFirstThumbtackResponse()
	{
		Id MIRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
		Account a = new Account(Name = 'Chester Tester');
		insert a;
		Contact ct = new Contact(LastName = 'Tester', FirstName = 'Chester', AccountId = a.Id);
		insert ct;
		Case c = new Case(AccountId = a.Id, Status = 'New', ContactId = ct.Id, RecordTypeId = MIRTId);
		insert c;
		Task t = new Task(WhatId = c.Id, CallType = 'Inbound');

		c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
		System.assertEquals(null, c.FirstThumbtackResponse__c);

		insert t;

		c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
		System.assertNotEquals(null, c.FirstThumbtackResponse__c);
	}
}