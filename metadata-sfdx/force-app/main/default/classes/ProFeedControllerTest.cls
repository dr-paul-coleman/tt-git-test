@isTest
private class ProFeedControllerTest {
	
	@isTest static void getFeedItems_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);

		Test.startTest();

		List<EnrollmentAction__c> result = ProFeedController.getFeedItems(acc.Id, 'Outreach Attempt', enrollment.Id);

		Test.stopTest();

		System.assertEquals(action.Id, result[0].Id);

	}

	@isTest static void getTaskFeedItems_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Task t = new Task (
			CallType = 'Outbound',
			WhatId = enrollment.Id
		);
		insert t;

		Test.startTest();

		List<Map<String, SObject>> result = ProFeedController.getTaskFeedItems(acc.Id, enrollment.Id);

		Test.stopTest();

		System.assertEquals(enrollment.Id, result[0].get('Enrollment__r').Id);
		System.assertEquals(t.Id, result[0].get('Task').Id);

	}
	
}