/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
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

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-09-04   Mendel Guillaume       Created
========+============+=================+===============================================*/

@IsTest
private class IncidentSectionsControllerTest
{
	@TestSetup
	static void createData()
	{
		Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
		insert customer;

		Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
		insert pro;

		MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id, Status__c = 'New');
		insert incident;
	}

	static testMethod void testSave()
	{
		MIIncident__c incident = [SELECT Id, Status__c FROM MIIncident__c];

		System.assertEquals('New', incident.Status__c);

		incident.Status__c = 'In Progress';

		System.assertEquals('Success', IncidentSectionsController.saveIncident(incident));

		incident = [SELECT Id, Status__c FROM MIIncident__c];

		System.assertEquals('In Progress', incident.Status__c);
	}

	static testMethod void testClose()
	{
		MIIncident__c incident = [SELECT Id, Status__c FROM MIIncident__c];

		System.assertEquals('New', incident.Status__c);

		incident.Status__c = 'Closed';
		incident.MICategory__c = 'Unsatisfactory work';
		incident.OutcomeCustomer__c = 'Unresponsive';
		incident.OutcomePro__c = 'Removed';

		System.assertEquals('Success', IncidentSectionsController.closeIncident(incident, 'Test Note', false));

		incident = [SELECT Id, Status__c FROM MIIncident__c];

		System.assertEquals('Closed', incident.Status__c);

		MIIncidentAction__c task = [SELECT Notes__c FROM MIIncidentAction__c
									WHERE RecordTypeId = :MiIncidentActionTriggerHandler.TaskRTId];

		System.assertEquals('Test Note', task.Notes__c);
	}

	static testMethod void testGetIncident()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];
		System.assertNotEquals(null, IncidentSectionsController.getIncident(incident.Id));
	}

	static testMethod void testGetPriorities()
	{
		System.assertNotEquals(0, IncidentSectionsController.getPriorities().size());
	}

	static testMethod void testGetOrigins()
	{
		System.assertNotEquals(0, IncidentSectionsController.getOrigins().size());
	}

	static testMethod void testGetCategories()
	{
		System.assertNotEquals(0, IncidentSectionsController.getCategories().size());
	}

	static testMethod void testGetSubcategories()
	{
		System.assertNotEquals(0, IncidentSectionsController.getSubcategories().size());
	}

	static testMethod void testGetStatuses()
	{
		System.assertNotEquals(0, IncidentSectionsController.getStatuses().size());
	}

	static testMethod void testGetProOutcomes()
	{
		System.assertNotEquals(0, IncidentSectionsController.getProOutcomes().size());
	}

	static testMethod void testGetCustOutcomes()
	{
		System.assertNotEquals(0, IncidentSectionsController.getCustOutcomes().size());
	}

	static testMethod void testGetModiaStatuses()
	{
		System.assertNotEquals(0, IncidentSectionsController.getModiaStatuses().size());
	}

	static testMethod void testGetEscalationTypes()
	{
		System.assertNotEquals(0, IncidentSectionsController.getEscalationTypes().size());
	}

	static testMethod void testGetCategoryMap()
	{
		System.assertNotEquals(0, IncidentSectionsController.getCategoryMap().size());
	}

	static testMethod void testGetCategorySubs()
	{
		System.assert(IncidentSectionsController.getCategorySubs('Concern about user').size() > 0);
	}

	static testMethod void testCreateUpdateQuickCase()
	{
		List<QuickCaseSetting__mdt> settings = [SELECT Id FROM QuickCaseSetting__mdt WHERE IsActive__c = TRUE AND AssignedApp__c = 'Incident Manager' LIMIT 1];

		if(!settings.isEmpty())
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			incident = IncidentSectionsController.getIncident(incident.Id);

			ResponseUtility response = IncidentSectionsController.createQuickCase(incident, settings[0].Id);
			System.assertEquals(true, response.success);

			System.assertEquals(true, IncidentSectionsController.updateQuickCase(((case) response.record).Id).success);
		}
	}
}