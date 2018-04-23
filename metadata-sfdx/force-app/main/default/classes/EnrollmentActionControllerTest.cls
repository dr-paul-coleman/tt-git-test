@isTest
private class EnrollmentActionControllerTest {
	
	@isTest static void createEnrollmentAction_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(false);
		a.EnrollmentCallbackDateTime__c = System.now();
		insert a;

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted'
		);
		insert rule;

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary',
			URL__c = 'https://www.google.com'
		);

		Test.startTest();

		EnrollmentAction__c result = EnrollmentActionController.createEnrollmentAction(action, true);

		Test.stopTest();

		System.assertEquals(UserInfo.getUserId(), result.CompletedBy__c);

		a = [Select EnrollmentCallbackDateTime__c From Account Where Id = :a.Id];

		System.assertEquals(null, a.EnrollmentCallbackDateTime__c);

		enrollment = [Select PricingURL__c From Enrollment__c Where Id = :enrollment.Id];

		System.assertEquals('https://www.google.com', enrollment.PricingURL__c);

	}

	@isTest static void saveURL_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		String result = EnrollmentActionController.saveURL(enrollment.Id, 'https://www.google.com');

		Test.stopTest();

		enrollment = [Select PricingURL__c From Enrollment__c Where Id = :enrollment.Id];

		System.assertEquals('https://www.google.com', enrollment.PricingURL__c);

	}
	
	@isTest static void deleteEnrollmentAction_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(false);
		a.EnrollmentCallbackDateTime__c = System.now();
		insert a;

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted'
		);
		insert rule;

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		EnrollmentActionController.createEnrollmentAction(action, false);

		Test.startTest();

		EnrollmentActionController.deleteEnrollmentAction(action.Id);

		Test.stopTest();

		List<EnrollmentAction__c> result = [Select Id From EnrollmentAction__c Where Id = :action.Id];

		System.assert(result.isEmpty());

	}
	
}