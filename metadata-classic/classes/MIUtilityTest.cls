@isTest
private class MIUtilityTest
{
	static testMethod void testMiFields()
	{
		List<String> fields = MIUtility.miIncidentFields;

		System.assertNotEquals(0, fields.size());
	}

	static testMethod void testMiIncidentActionFields()
	{
		List<String> fields = MIUtility.miIncidentActionFields;

		System.assertNotEquals(0, fields.size());
	}

	static testMethod void testEmailMessageFields()
	{
		List<String> fields = MIUtility.emailMessageFields;

		System.assertNotEquals(0, fields.size());
	}

	static testMethod void testTaskFields()
	{
		List<String> fields = MIUtility.taskFields;

		System.assertNotEquals(0, fields.size());
	}

	static testMethod void testGetCaseIds()
	{
		Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
		Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
		insert new List<Account>{customer, pro};

		Contact cCust = new Contact(FirstName = 'Test', LastName = 'Customer', AccountId = customer.Id);
		Contact cPro = new Contact(FirstName = 'Test', LastName = 'Pro', AccountId = pro.Id);
		insert new List<Contact>{cCust, cPro};

		MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id, Status__c = 'New');
		insert incident;

		Case c1 = new Case(AccountId = customer.Id, ContactId = cCust.Id, Subject='MI Test Case 1', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
		Case c2 = new Case(AccountId = pro.Id, ContactId = cPro.Id, Subject='MI Test Case 2', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
		Case c3 = new Case(AccountId = pro.Id, ContactId = cPro.Id,  Subject='MI Test Case 3', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
		insert new List<Case>{c1, c2, c3};

		Set<ID> caseIds = MIUtility.getCaseIds(incident.Id, null);

		System.assertEquals(3, caseIds.size());

		caseIds = MIUtility.getCaseIds(incident.Id, cPro.Id);

		System.assertEquals(2, caseIds.size());

		caseIds = MIUtility.getCaseIds(incident.Id, cCust.Id);

		System.assertEquals(1, caseIds.size());
	}
}