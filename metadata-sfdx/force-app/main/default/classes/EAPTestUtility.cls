public class EAPTestUtility {
	
	public static RequestCategory__c createRequestCategory(Boolean shouldInsert) {

		RequestCategory__c cat = new RequestCategory__c (
			rca_active__c = true,
			rca_request_category_id__c = '23',
			rca_name__c = 'Salesforce Dev',
			outreach_type__c = 'Early_enrollment',
			EnrollAProEnabled__c = true
		);
		if (shouldInsert) {
		
			insert cat;

		}
		return cat;

	}

	public static Market__c createMarket(Id requestCategoryId, Boolean shouldInsert) {

		Market__c market = new Market__c (
			rca_name__c = 'Salesforce Dev',
			zip_cbsa_name__c = 'Utah',
			Deprioritized__c = false,
			TakeaLeadEnabled__c = true,
			rca_request_category_id__c = '23',
			RequestCategory__c = requestCategoryId,
			zip_cbsa_code__c = '24',
			outreach_type__c = 'Early_enrollment',
			EnrollAProEnabled__c = true
		);
		if (shouldInsert) {

			insert market;

		}
		return market;

	}

	public static Account createAccount(Boolean shouldInsert) {

		Account a = new Account(
			Name ='Test Name ',
			usr_user_id__c = 1
		);
		if (shouldInsert) {

			insert a;

		}
		return a;

	}

	public static Enrollment__c createEnrollment(Id accountId, Boolean shouldInsert) {

		Enrollment__c enrollment = new Enrollment__c (
			Name = 'test name',
			Account__c = accountId,
			rca_request_category_id__c = '23',
			zip_cbsa_code__c = '24',
			enrollment_id__c = '1',
			FunnelStep__c = 'Ready',
			outreach_type__c = 'Early_enrollment',
			outreach_group__c = '1_VIP'
		);
		if (shouldInsert) {

			insert enrollment;

		}
		return enrollment;

	}
    
    public static Enrollment__c createNoMarketEnrollment(Id accountId, Boolean shouldInsert) {

		Enrollment__c enrollment = new Enrollment__c (
			Name = 'test enrollment',
			Account__c = accountId,			
			enrollment_id__c = '1',
			FunnelStep__c = 'Call One',
			outreach_type__c = 'pro_onboarding',
			outreach_group__c = '1_VIP'
		);
		if (shouldInsert) {

			insert enrollment;

		}
		return enrollment;

	}

}