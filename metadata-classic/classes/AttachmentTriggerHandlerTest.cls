/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-10   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

@IsTest
private class AttachmentTriggerHandlerTest
{
	public static final Id MI_INCIDENT_RT_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();

	@IsTest
	static void testAttachmentEventOnInsert()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			MIIncident__c incident = new MIIncident__c(Status__c = 'In Progress', RecordTypeId = MI_INCIDENT_RT_ID);
			insert incident;

			Attachment attach = new Attachment(Name = 'Test Attachment', Body = Blob.valueOf('Test content'), ParentId = incident.Id);

			Test.startTest();
			insert attach;
			Test.stopTest();

			System.assertNotEquals(null, AttachmentTriggerHandler.attachmentEventSaveResults);
			System.assertEquals(true, AttachmentTriggerHandler.attachmentEventSaveResults[0].isSuccess());
		}
	}

	@IsTest
	static void testAttachmentEventOnUpdate()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			MIIncident__c incident = new MIIncident__c(Status__c = 'In Progress', RecordTypeId = MI_INCIDENT_RT_ID);
			insert incident;

			Attachment attach = new Attachment(Name = 'Test Attachment', Body = Blob.valueOf('Test content'), ParentId = incident.Id);
			insert attach;

			Test.startTest();
			attach.Name = 'Test';
			update attach;
			Test.stopTest();

			System.assertNotEquals(null, AttachmentTriggerHandler.attachmentEventSaveResults);
			System.assertEquals(true, AttachmentTriggerHandler.attachmentEventSaveResults[0].isSuccess());
		}
	}
}