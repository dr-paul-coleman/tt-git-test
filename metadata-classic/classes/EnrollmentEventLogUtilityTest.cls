@isTest
private class EnrollmentEventLogUtilityTest {
	
	@isTest static void handleObjectChanges_skipSteps_test() {
		
		EnrollmentRule__c eventRule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Event Log',
			EventLogObject__c = 'Enrollment__c',
			EventLogField__c = 'FunnelStep__c',
			EventLogObjectEnrollmentRelationship__c = 'Id',
			IsActive__c = true
		);
		insert eventRule;

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert rule;

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);

		Test.startTest();

		EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		List<EnrollmentAction__c> result = [Select Id From EnrollmentAction__c Where Type__c = 'Event Log'];

		System.assertEquals(3, result.size());

	}

	@isTest static void handleObjectChanges_reverse_test() {
		
		EnrollmentRule__c eventRule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Event Log',
			EventLogObject__c = 'Enrollment__c',
			EventLogField__c = 'FunnelStep__c',
			EventLogObjectEnrollmentRelationship__c = 'Id',
			IsActive__c = true
		);
		insert eventRule;

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert rule;

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);

		Test.startTest();

		EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		List<EnrollmentAction__c> result = [Select Id From EnrollmentAction__c Where Type__c = 'Event Log'];

		//System.assertEquals(3, result.size());

		delete action;

		EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		result = [Select Id From EnrollmentAction__c Where Type__c = 'Event Log'];

		System.assertEquals(6, result.size());

	}

	@isTest static void handleObjectChanges_outreachTypeChange_test() {
		
		EnrollmentRule__c eventRule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Event Log',
			EventLogObject__c = 'RequestCategory__c',
			EventLogField__c = 'outreach_type__c',
			EventLogObjectEnrollmentRelationship__c = 'Market__r.RequestCategory__c',
			IsActive__c = true
		);
		insert eventRule;

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		cat.outreach_type__c = 'Product_enabled';
		update cat;

		Test.stopTest();

		List<EnrollmentAction__c> result = [Select Id From EnrollmentAction__c Where Type__c = 'Event Log'];

		System.assertEquals(1, result.size());

	}
	
}