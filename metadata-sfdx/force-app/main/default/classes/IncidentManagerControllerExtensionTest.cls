/**
 * Created by SentientGrey on 10/31/17.
 */

@IsTest
private class IncidentManagerControllerExtensionTest
{
	@TestSetup
	static void createData()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
			insert pro;

			MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
			insert incident;
		}
	}

	static testMethod void testRefresh()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			MIIncident__c incident = [SELECT Id FROM MIIncident__c];
			IncidentManagerControllerExtension ctrl = new IncidentManagerControllerExtension(new ApexPages.StandardController(incident));

			System.assertEquals(null, ctrl.incident.ProPhone__c);
			System.assertEquals(null, ctrl.incident.CustomerPhone__c);

			incident.ProPhone__c = '555-555-5555';
			incident.CustomerPhone__c = '555-555-5556';
			update incident;

			ctrl.refresh();
			System.assertEquals(incident.ProPhone__c, ctrl.incident.ProPhone__c);
			System.assertEquals(incident.CustomerPhone__c, ctrl.incident.CustomerPhone__c);
		}
	}
}