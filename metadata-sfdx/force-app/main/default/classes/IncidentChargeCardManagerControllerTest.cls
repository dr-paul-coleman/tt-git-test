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
1.0      2017-08-16   Mendel Guillaume       Created
========+============+=================+===============================================*/

@IsTest
private class IncidentChargeCardManagerControllerTest
{
	@TestSetup
	static void createData()
	{
		Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
		insert customer;

		Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
		insert pro;

		MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
		insert incident;
	}

	static testMethod void testSave()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];
		MIIncidentAction__c request = new MIIncidentAction__c(MIIncident__c = incident.Id, Name = 'Request', Amount__c = 100, Last4OfCard__c = '2345', Status__c = 'Open');

		System.assertEquals('Success', IncidentChargeCardManagerController.save(request));
		System.assertNotEquals(null, request.Id);
		System.assertEquals(MiIncidentActionTriggerHandler.ChargeRTId, request.RecordTypeId);
	}

	//No Incident id
	static testMethod void testSaveError()
	{
		MIIncidentAction__c request = new MIIncidentAction__c(Name = 'Request', Amount__c = 100, Last4OfCard__c = '2345', Status__c = 'Open');

		System.assertNotEquals('Success', IncidentChargeCardManagerController.save(request));
	}

	static testMethod void getStatuses()
	{
		System.assertNotEquals(0, IncidentChargeCardManagerController.getStatuses().size());
	}

	static testMethod void testGetRequests()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];
		MIIncidentAction__c request = new MIIncidentAction__c(MIIncident__c = incident.Id, Name = 'Request', Amount__c = 100,
							Last4OfCard__c = '2345', Status__c = 'Open', RecordTypeId = MiIncidentActionTriggerHandler.ChargeRTId);
		insert request;

		System.assertEquals(1, IncidentChargeCardManagerController.getChargeCardRequests(incident.Id).size());
	}
}