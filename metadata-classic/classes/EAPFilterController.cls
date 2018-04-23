public class EAPFilterController {

	@AuraEnabled
	public static List<Map<String, String>> getOutreachTypeOptions()
	{

		List<Map<String, String>> result = new List<Map<String, String>>();
		Schema.DescribeFieldResult field = RequestCategory__c.outreach_type__c.getDescribe();
		User usr = getUserInfo();

		for (Schema.PicklistEntry f : field.getPicklistValues())
		{
			if (f.isActive() && (usr.Profile.Name != '*Account Manager' || f.value == 'managed_account'))
			{
				result.add(new Map<String, String>
				{
						'label' => f.getLabel(),
						'value' => f.getValue(),
						'selected' => 'no',
						'hide' => 'no',
						'category' => 'outreach_type__c'
				});
			}
		}

		return result;
	}

	@AuraEnabled
	public static List<Map<String, String>> getOutreachGroupOptions()
	{
		List<Map<String, String>> result = new List<Map<String, String>>();
		Schema.DescribeFieldResult field = Enrollment__c.outreach_group__c.getDescribe();
		User usr = getUserInfo();

		for (Schema.PicklistEntry f : field.getPicklistValues())
		{
			if (f.isActive() && (usr.Profile.Name != '*Account Manager' || f.value == '0_MA'))
			{
				result.add(new Map<String, String>
				{
						'label' => f.getLabel(),
						'value' => f.getValue(),
						'selected' => 'no',
						'hide' => 'no',
						'category' => 'outreach_group__c'
				});
			}
		}

		return result;
	}

	@AuraEnabled
	public static List<Map<String, String>> getRequestCategoryOptions(String lastCategory, List<String> outreachTypes) {

		List<Map<String, String>> result = new List<Map<String, String>>();
		for (RequestCategory__c cat : Database.query(
									'Select Id, rca_name__c, rca_request_category_id__c From RequestCategory__c '
									+ 'Where EnrollAProEnabled__c = true '
									+ 'order by rca_name__c '
									+ 'limit 50 '
								)) {

			result.add(new Map<String, String> {
				'label' => cat.rca_name__c,
				'value' => cat.Id,
				'selected' => 'no',
				'hide' => 'no',
				'category' => 'RequestCategory__c'
			});

		}
		return result;

	}

	@AuraEnabled
	public static List<Map<String, String>> searchRequestCategories(String searchText, List<String> outreachTypes) {

		List<Map<String, String>> result = new List<Map<String, String>>();
		if (String.isNotBlank(searchText) && searchText.length() > 1) {

			String fuzzySearchText = '%' + searchText + '%';
			for (RequestCategory__c cat : [Select Id, rca_name__c, rca_request_category_id__c 
											From RequestCategory__c 
											Where rca_name__c LIKE :fuzzySearchText
											And EnrollAProEnabled__c = true]) {

				result.add(new Map<String, String> {
					'label' => cat.rca_name__c,
					'value' => cat.Id,
					'selected' => 'no',
					'hide' => 'no',
					'category' => 'RequestCategory__c'
				});

			}

		}
		return result;

	}

	@AuraEnabled
	public static List<Map<String, String>> getFunnelStepOptions()
	{
		List<Map<String, String>> result = new List<Map<String, String>>();
		User usr = getUserInfo();

		if(usr.Profile.Name == '*Account Manager')
		{
			ProEnrollmentUtility.outreachType = 'managed_account';
		}

		for (FunnelStepSetting__mdt setting : ProEnrollmentUtility.funnelStepSettings)
		{
			result.add(new Map<String, String>
			{
					'label' => setting.MasterLabel,
					'value' => setting.MasterLabel,
					'selected' => 'no',
					'hide' => 'no',
					'category' => 'FunnelStep__c'
			});
		}

		return result;
	}

	@AuraEnabled
	public static Map<String, List<Map<String, String>>> getUserFilter(Id userId) {

		Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>> ();
		if (userId == null) {

			userId = UserInfo.getUserId();

		}
		User me = [Select EnrollAProFilterJSON__c From User Where Id = :userId];
		if (String.isNotBlank(me.EnrollAProFilterJSON__c)) {

			result = (Map<String, List<Map<String, String>>>) JSON.deserialize(me.EnrollAProFilterJSON__c, Map<String, List<Map<String, String>>>.class);

		}
		return result;

	}

	@AuraEnabled
	public static void saveUserFilter(List<Id> userIds, Map<String, List<Map<String, String>>> filter) {

		List<User> users = new List<User> ();
		String jsonFilter = JSON.serialize(filter);
		if (userIds == null || (userIds != null && userIds.isEmpty())) {

			userIds = new List<Id> {UserInfo.getUserId()};

		}
		for (Id userId : userIds) {

			users.add(new User (
				Id = userId,
				EnrollAProFilterJSON__c = jsonFilter
			));

		}
		update users;

	}

	@AuraEnabled
	public static User getUserInfo()
	{
		return [SELECT Id, ProfileId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
	}

}