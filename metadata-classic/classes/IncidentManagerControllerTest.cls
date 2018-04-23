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
private class IncidentManagerControllerTest
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

	static testMethod void testGetIncident()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];

		System.assertEquals(incident.Id, IncidentManagerController.getIncident(incident.Id).Id);
	}

	static testMethod void testGetSubCategories()
	{
		System.assert(IncidentManagerController.getCategorySubs('Concern about user').size() > 0);
		System.assert(IncidentManagerController.getCategorySubs('Unsatisfactory work').size() == 0);
	}
}