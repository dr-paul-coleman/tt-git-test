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
private class IncidentPayoutRequestManagerCtrlTest
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

		MIIncidentAction__c action = new MIIncidentAction__c(MIIncident__c = incident.Id, Amount__c = 0, RecordTypeId = MiIncidentActionTriggerHandler.PayoutRTId);
		insert action;
	}

	static testMethod void testSave()
	{
		MIIncidentAction__c action = [SELECT Id, Amount__c FROM MIIncidentAction__c];

		System.assertEquals(0, action.Amount__c);

		action.Amount__c = 100;
		System.assertEquals('Success', IncidentPayoutRequestManagerController.save(action));

		action = [SELECT Id, Amount__c FROM MIIncidentAction__c];

		System.assertEquals(100, action.Amount__c);
	}

	static testMethod void testGetStatuses()
	{
		System.assertNotEquals(0, IncidentPayoutRequestManagerController.getStatuses().size());
	}

	static testMethod void testGetApprovedBy()
	{
		System.assertNotEquals(0, IncidentPayoutRequestManagerController.getApprovedByOptions().size());
	}

	static testMethod void testGetTypes()
	{
		System.assertNotEquals(0, IncidentPayoutRequestManagerController.getTypes().size());
	}

	static testMethod void testGetPayoutRequests()
	{
		MIIncident__c incident = [SELECT Id FROM MIIncident__c];

		System.assertEquals(1, IncidentPayoutRequestManagerController.getPayoutRequests(incident.Id).size());
	}
}