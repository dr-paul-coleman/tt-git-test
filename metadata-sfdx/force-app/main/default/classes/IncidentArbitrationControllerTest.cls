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
1.0      2017-08-18   Mendel Guillaume       Created
========+============+=================+===============================================*/

@IsTest
private class IncidentArbitrationControllerTest
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
		Arbitration__c arb = new Arbitration__c(Incident__c = incident.Id, Name = 'Request');

		System.assertEquals('Success', IncidentArbitrationController.save(arb));
		System.assertNotEquals(null, arb.Id);
	}

	static testMethod void testGetStatuses()
	{
		System.assertNotEquals(0, IncidentArbitrationController.getStatuses().size());
	}

	static testMethod void testGetDisputeChannels()
	{
		System.assertNotEquals(0, IncidentArbitrationController.getDisputeChannels().size());
	}

	static testMethod void testGetArbitration()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];
		Arbitration__c arb = new Arbitration__c(Incident__c = incident.Id, Name = 'Request');
		insert arb;

		System.assertEquals(arb.Id, IncidentArbitrationController.getArbitration(incident.Id).Id);
	}

	static testMethod void testGetIncident()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];

		System.assertEquals(incident.Id, IncidentArbitrationController.getIncident(incident.Id).Id);
	}
}