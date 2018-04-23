/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-02-22   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
@IsTest
private class DisputeStartStopControllerTest
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

			insert defaultExp;

			Dispute__c d = new Dispute__c(MIIncident__c = incident.Id, Status__c = 'Awaiting', Stage__c = 'Initiator confirmation needed',
					DisputeExperience__c = defaultExp.Id, request_category__c = 'Test Category',
					request_city__c = 'Salt Lake City', request_state__c = 'UT', request_zip__c = '84044');

			insert d;
		}
	}

	@IsTest
	static void testGetStatuses()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assert(DisputeStartStopController.getStatuses().size() > 0, 'No statuses');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetStatusesMap()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assert(DisputeStartStopController.getStatusMap().size() > 0, 'No statuses');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetAndSaveDispute()
	{
		Dispute__c d = [SELECT Id FROM Dispute__c];

		Test.startTest();

		d = DisputeStartStopController.getDispute(d.Id);
		d.Status__c = 'Under review';

		String result = DisputeStartStopController.saveDispute(d);

		Test.stopTest();

		System.assertEquals('Success', result, 'Dispute not saved');
	}
}