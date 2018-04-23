@isTest
private class EAPFilterControllerTest {
	
	@isTest static void getOutreachTypeOptions_test() {
		
		Test.startTest();

		List<Map<String, String>> result = EAPFilterController.getOutreachTypeOptions();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getOutreachGroupOptions_test() {
		
		Test.startTest();

		List<Map<String, String>> result = EAPFilterController.getOutreachGroupOptions();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getRequestCategoryOptions_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		Test.startTest();

		List<Map<String, String>> result = EAPFilterController.getRequestCategoryOptions('Apple Picker', new List<String> {'Early_enrollment'});

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void searchRequestCategories_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		Test.startTest();

		List<Map<String, String>> result = EAPFilterController.searchRequestCategories('sa', new List<String> {'Early_enrollment'});

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getFunnelStepOptions_test() {
		
		Test.startTest();

		List<Map<String, String>> result = EAPFilterController.getFunnelStepOptions();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getUserFilter_test() {
		
		String userFilter = JSON.serialize(new Map<String, List<Map<String, String>>> {
			'FunnelStep__c' => new List<Map<String, String>> {
				new Map<String, String> {
					'label' => 'Ready',
					'value' => 'Ready',
					'selected' => 'yes',
					'hide' => 'no',
					'category' => 'FunnelStep__c'
				}
			}
		});
		User testUser = [SELECT Id,Name FROM User WHERE Profile.Name = 'System Administrator' And Id != :UserInfo.getUserId() AND IsActive=true LIMIT 1];
		Id myUserId = UserInfo.getUserId();
		System.runAs(testUser) {

			update new User (
				Id = myUserId,
				EnrollAProFilterJSON__c = userFilter
			);

		}
		Test.startTest();

		Map<String, List<Map<String, String>>> result = EAPFilterController.getUserFilter(null);

		Test.stopTest();

		System.assert(!result.get('FunnelStep__c').isEmpty());

	}

	@isTest static void saveUserFilter_test() {
		
		Map<String, List<Map<String, String>>> userFilter = new Map<String, List<Map<String, String>>> {
			'FunnelStep__c' => new List<Map<String, String>> {
				new Map<String, String> {
					'label' => 'Ready',
					'value' => 'Ready',
					'selected' => 'yes',
					'hide' => 'no',
					'category' => 'FunnelStep__c'
				}
			}
		};
		Test.startTest();

		EAPFilterController.saveUserFilter(null, userFilter);

		Test.stopTest();

		User me = [Select EnrollAProFilterJSON__c From User Where Id = :UserInfo.getUserId()];

		System.assert(String.isNotBlank(me.EnrollAProFilterJSON__c));

	}
	
}