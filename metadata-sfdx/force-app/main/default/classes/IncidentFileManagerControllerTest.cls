/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-09-12   Mendel Guillaume       Created
   1.1      2018-01-03   Mendel Guillaume  Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class IncidentFileManagerControllerTest
{
	@testSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
			insert pro;

			MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
			insert incident;

			Case c = new Case(AccountId = customer.Id, Subject = 'MI Test Case', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box');
			insert c;

			EmailMessage em = new EmailMessage(FromAddress = 'test@email.com', ParentId = c.Id, Incoming = true);
			insert em;

			Attachment att = new Attachment();
			att.ParentId = em.Id;
			att.Name = 'Test Name';
			att.Body = Blob.valueOf('Test Attachment');
			insert att;

			Attachment att2 = new Attachment();
			att2.ParentId = em.Id;
			att2.Name = 'Test Name 2';
			att2.Body = Blob.valueOf('Test Attachment 2');
			insert att2;
		}
	}

	@IsTest
	static void testGetAttachments()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];

			Test.startTest();

			List<IncidentFileManagerController.FileWrapper> atts = IncidentFileManagerController.getAllAttachments(incident.Id);

			Test.stopTest();

			System.assertEquals(2, atts.size(), 'Invalid size');
		}
	}

	@IsTest
	static void testRenameFile()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Attachment att = [SELECT Id, Name FROM Attachment ORDER BY Name LIMIT 1];

			Test.startTest();

			System.assertEquals('Test Name', att.Name, 'Invalid file name');

			IncidentFileManagerController.renameFile(att.Id, 'Updated Name');

			Test.stopTest();

			att = [SELECT Id, Name FROM Attachment WHERE Id = :att.Id];
			System.assertEquals('Updated Name', att.Name, 'File not renamed');
		}
	}

	@IsTest
	static void testDeleteFile()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			List<Attachment> atts = [SELECT Id, Name FROM Attachment ORDER BY Name];

			Test.startTest();

			System.assertEquals(2, atts.size(), 'Invalid size');

			IncidentFileManagerController.deleteFile(atts[0].Id);

			Test.stopTest();

			atts = [SELECT Id, Name FROM Attachment ORDER BY Name];

			System.assertEquals(1, atts.size(), 'File not deleted');
		}
	}

	@IsTest
	static void testSaveFile()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			EmailMessage em = [SELECT Id FROM EmailMessage];
			Test.startTest();

			IncidentFileManagerController.saveTheChunk(em.Id, 'X Name', EncodingUtil.base64Encode(Blob.valueOf('Test Attachment 3')), 'text/plain', null);

			List<Attachment> atts = [SELECT Id, Name FROM Attachment ORDER BY Name];
			System.assertEquals(3, atts.size(), 'Invalid size');

			IncidentFileManagerController.saveTheChunk(em.Id, 'X Name', EncodingUtil.base64Encode(Blob.valueOf('Test Attachment Addendum')), 'text/plain', atts[2].Id);

			Test.stopTest();

			atts = [SELECT Id, Name FROM Attachment ORDER BY Name];
			System.assertEquals(3, atts.size(),  'Invalid size');
		}
	}

	@IsTest
	static void testGetSessionId()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(null, IncidentFileManagerController.getSessionId(), 'Session Id is null');

			Test.stopTest();
		}
	}

}