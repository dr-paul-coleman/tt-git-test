@isTest
private class RelatedListControllerTest {
	
	@isTest static void getRelatedListsForPageName_test() {
		
		Test.startTest();

		List<RelatedListSetting> result = RelatedListController.getRelatedListsForPageName('APEX TEST');

		Test.stopTest();

		System.assert(!result.isEmpty());

	}
	
	@isTest static void getRelatedListInfo_test() {

		Account acc = new Account (
			Name = 'test acc',
			usr_user_id__c = 123456
		);
		insert acc;
		
		List<RelatedListSetting> settings = RelatedListController.getRelatedListsForPageName('APEX TEST');

		Test.startTest();

		RelatedListSetting result = RelatedListController.getRelatedListInfo(settings[0].parentObjectName, settings[0].parentReferenceFieldName, acc.Id, settings[0].objectName, settings[0].queryFieldSetName);

		Test.stopTest();

		System.assertEquals(acc.Id, Id.valueOf(result.referenceId));

	}

	@isTest static void getRecords_test() {
		
		Account acc = new Account (
			Name = 'test acc',
			usr_user_id__c = 123456
		);
		Account acc2 = new Account (
			Name = 'test acc',
			usr_user_id__c = 123457
		);
		insert new Account[] {acc, acc2};

		Test.startTest();

		List<Account> result = (List<Account>) RelatedListController.getRecords('Account', 'Name', acc.Name, new List<String> {'Name', 'usr_user_id__c'}, 'usr_user_id__c', 'ASC', 1, 1);

		Test.stopTest();

		System.assertEquals(acc2.Id, result[0].Id);

	}
	
}