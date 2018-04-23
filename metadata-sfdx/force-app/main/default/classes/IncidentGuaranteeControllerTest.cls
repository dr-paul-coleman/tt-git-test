/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-08-18   Mendel Guillaume       Created
   1.1      2018-01-03   Mendel Guillaume  Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class IncidentGuaranteeControllerTest
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

			MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
			insert incident;
		}
	}

	@IsTest
	static void testSave()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			MIIncidentAction__c request = new MIIncidentAction__c(MIIncident__c = incident.Id, Name = 'Request');

			Test.startTest();

			System.assertEquals('Success', IncidentGuaranteeController.save(request, incident), 'Save failed');

			Test.stopTest();

			System.assertEquals(MiIncidentActionTriggerHandler.GuaranteeRTId, request.RecordTypeId, 'Invalid record type');
		}
	}

	@IsTest
	static void testSaveError()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];

			Test.startTest();

			System.assertNotEquals('Success', IncidentGuaranteeController.save(null, incident), 'Save successful');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetStatuses()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, IncidentGuaranteeController.getStatuses().size(), 'No Statuses');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetAdjusterStatuses()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, IncidentGuaranteeController.getAdjusterStatuses().size(), 'No Adjuster Statuses');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetGuaranteeTypes()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, IncidentGuaranteeController.getGuaranteeTypes().size(), 'No Guarantee Types');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetGuaranteeMap()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, IncidentGuaranteeController.getGuaranteeMap().size(), 'No Guarantee Types Map');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetEligibilityFactors()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals(0, IncidentGuaranteeController.getEligibilityFactors().size(), 'No Eligibility Factors');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetRequests()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			MIIncidentAction__c request = new MIIncidentAction__c(MIIncident__c = incident.Id, Name = 'Request',
					RecordTypeId = MiIncidentActionTriggerHandler.GuaranteeRTId);

			Test.startTest();

			insert request;

			Test.stopTest();

			System.assertEquals(request.Id, IncidentGuaranteeController.getRequest(incident.Id).Id, 'Request not found');
		}
	}

	@IsTest
	static void testGetIncident()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];

			Test.startTest();

			System.assertEquals(incident.Id, IncidentGuaranteeController.getIncident(incident.Id).Id, 'Incident not found');

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetIncidentActionFieldsAccess()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Map<String, String> fieldsAccess = IncidentGuaranteeController.getIncidentActionFieldsAccess();

			Test.startTest();
			Schema.DescribeFieldResult dfr = MIIncidentAction__c.AdjusterStatus__c.getDescribe();

			if (dfr.isUpdateable())
			{
				System.assertEquals('edit', fieldsAccess.get('AdjusterStatus__c'));
			}
			else if (dfr.isAccessible())
			{
				System.assertEquals('read', fieldsAccess.get('AdjusterStatus__c'));
			}
			else
			{
				System.assertEquals('none', fieldsAccess.get('AdjusterStatus__c'));
			}
			Test.stopTest();
		}
	}
}