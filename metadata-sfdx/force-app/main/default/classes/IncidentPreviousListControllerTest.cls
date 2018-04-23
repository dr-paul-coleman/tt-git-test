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
private class IncidentPreviousListControllerTest
{
	@TestSetup
	static void createData()
	{
		Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
		insert customer;

		Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
		insert pro;

		List<MIIncident__c> incidents = new List<MIIncident__c>();

		incidents.add(new MIIncident__c(CustomerAccount__c = customer.Id));
		incidents.add(new MIIncident__c(CustomerAccount__c = customer.Id));
		incidents.add(new MIIncident__c(ProAccount__c = pro.Id));
		incidents.add(new MIIncident__c(ProAccount__c = pro.Id));
		incidents.add(new MIIncident__c(ProAccount__c = pro.Id));
		insert incidents;
	}

	static testMethod void testGetCustomerIncidents()
	{
		Account a = [SELECT Id FROM Account WHERE Name = 'Customer Account'];
		MIIncident__c incident = [SELECT Id FROM MIIncident__c WHERE CustomerAccount__c = :a.Id LIMIT 1];

		System.assertEquals(1, IncidentPreviousListController.getCustomerIncidents(a.Id, incident.Id).size());
	}

	static testMethod void testGetProIncidents()
	{
		Account a = [SELECT Id FROM Account WHERE Name = 'Pro Account'];
		MIIncident__c incident = [SELECT Id FROM MIIncident__c WHERE ProAccount__c = :a.Id LIMIT 1];

		System.assertEquals(2, IncidentPreviousListController.getProIncidents(a.Id, incident.Id).size());
	}
}