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
private class IncidentCasesControllerTest
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

		Case c = new Case(AccountId = customer.Id, Subject='MI Test Case', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
		insert c;
	}

	static testMethod void testGetRecords()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];

		System.assertEquals(1, IncidentCasesController.getRecords(incident.Id).size());
	}

	static testMethod void testDetach()
	{
		Case c = [SELECT Id, MIDoNotRelateIncident__c, Incident__c FROM Case];

		System.assertEquals(false, c.MIDoNotRelateIncident__c);
		System.assertNotEquals(null, c.Incident__c);

		System.assertEquals('success', IncidentCasesController.detachCase(c.Id));

		c = [SELECT Id, MIDoNotRelateIncident__c, Incident__c FROM Case];

		System.assertEquals(true, c.MIDoNotRelateIncident__c);
		System.assertEquals(null, c.Incident__c);
	}

	static testMethod void testSave()
	{
		Case c = [SELECT Id, Status, MIDoNotRelateIncident__c, Incident__c FROM Case];

		System.assertEquals('New', c.Status);

		c.Status = 'Pending Customer';

		System.assertEquals('success', IncidentCasesController.saveCase(c));

		c = [SELECT Id, Status, MIDoNotRelateIncident__c, Incident__c FROM Case];

		System.assertEquals('Pending Customer', c.Status);
	}

	static testMethod void testGetQueues()
	{
		System.assert(IncidentCasesController.getQueues().size() > 0);
	}
}