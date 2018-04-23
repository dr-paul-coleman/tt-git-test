/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-16   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

@IsTest
private class DisputeControllerTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
			insert pro;

			MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id, bid_id__c = '123456');
			insert incident;

			DisputeExperience__c defaultExp = new DisputeExperience__c (DefaultExperience__c = true, Status__c = 'Published',
					Name = 'Default', ResolutionOptions__c = 'Refund;Complete Work');
			DisputeExperience__c de1 = new DisputeExperience__c (DefaultExperience__c = false, Status__c = 'Published',
					Name = 'Dex 1', ResolutionOptions__c = 'Option 1');

			insert new List<DisputeExperience__c>{defaultExp, de1};
		}
	}

	@IsTest
	static void testGetIncident()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];

			Test.startTest();

			System.assertEquals(incident.Id, DisputeController.getIncident(incident.Id).Id);

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetResolutionOptions()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			List<DisputeExperience__c> des = [SELECT Id FROM DisputeExperience__c ORDER BY Name];

			Test.startTest();

			System.assertEquals(2, DisputeController.getResolutions(des[0].Id).size());
			System.assertEquals(1, DisputeController.getResolutions(des[1].Id).size());

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetAndSaveDispute()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			DisputeExperience__c defaultExp = [SELECT Id FROM DisputeExperience__c WHERE DefaultExperience__c = true];
			Dispute__c d = DisputeController.getNewDispute(incident.Id);

			Test.startTest();

			System.assertEquals(defaultExp.Id, d.DisputeExperience__c);
			System.assertEquals('Success', DisputeController.saveDispute(d));

			Test.stopTest();
		}
	}

	@IsTest
	static void testSaveDisputeError()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			Dispute__c d = DisputeController.getNewDispute(incident.Id);
			delete incident;

			Test.startTest();

			System.assertNotEquals('Success', DisputeController.saveDispute(d));

			Test.stopTest();
		}
	}
}