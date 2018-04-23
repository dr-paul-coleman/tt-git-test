/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version  Date     	 Author            	Description                          
=======+============+==================+======================================
1.0      2017-07-21  Adam Schultz       Created 
1.1		 2017-09-21	 Meena Pisupati		Replaced ProAssist with Instant Match,
										Added Header
=======+============+==================+======================================*/
@isTest
private class ProEnrollmentUtilityTest {
	
	@isTest static void getter_test() {

		List<String> enrollmentFields = ProEnrollmentUtility.getEnrollmentFields();

		System.assert(!enrollmentFields.isEmpty());

		List<String> ruleFields = ProEnrollmentUtility.getEnrollmentRuleFields();

		System.assert(!ruleFields.isEmpty());

		List<String> actionFields = ProEnrollmentUtility.getEnrollmentActionFields();

		System.assert(!actionFields.isEmpty());

		Map<String, String> fieldMapping = ProEnrollmentUtility.getRuleToEnrollmentFieldMapping();

		System.assert(!fieldMapping.isEmpty());

	}

	@isTest static void getCurrentUser_test() {

		Test.startTest();

		User result = ProEnrollmentUtility.getCurrentUser();

		Test.stopTest();

		System.assertEquals(UserInfo.getUserId(), result.Id);

	}

	@isTest static void getEnrollment_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		Enrollment__c result = ProEnrollmentUtility.getEnrollment(enrollment.Id);

		Test.stopTest();

		System.assertEquals(enrollment.Id, result.Id);

	}
	
	@isTest static void createEnrollmentAction_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert rule;

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step',
			CallbackOutreachType__c = 'Product_enabled'
		);

		Test.startTest();

		EnrollmentAction__c result = ProEnrollmentUtility.createEnrollmentAction(action);

		Test.stopTest();

		System.assertEquals(action.Id, result.Id);

		enrollment = [Select CallbackOutreachType__c From Enrollment__c Where Id = :enrollment.Id];
		System.assertEquals(action.CallbackOutreachType__c.toLowerCase(), enrollment.CallbackOutreachType__c.toLowerCase());

	}
	
	@isTest static void handleEnrollmentUpdate_outreachAttempt_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted'
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Contacted'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Contacted', result[0].FunnelStep__c);

	}

	@isTest static void handleEnrollmentUpdate_outreachAttempt_unsuccessfulReason_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			SetEnrollmentUnsuccessfulReasonTo__c = 'Not Interested in Instant Match'
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			EnrollmentOutreachDisposition__c = 'No Attempt Necessary',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Contacted'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Attempted', result[0].FunnelStep__c);
		System.assertEquals('Not Interested in Instant Match', result[0].UnsuccessfulReason__c);

	}

	@isTest static void handleEnrollmentUpdate_onboardingStep_test() {
		
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
			SetEnrollmentFunnelStepTo__c = 'Contacted',
			IsAutonomous__c = true
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Interested', result[0].FunnelStep__c);

	}

	@isTest static void handleEnrollmentUpdate_onboardingStep_unsuccessfulReason_test() {
		
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
			SetEnrollmentFunnelStepTo__c = 'Contacted',
			IsAutonomous__c = true,
			SetEnrollmentUnsuccessfulReasonTo__c = 'Not Interested in Instant Match'
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Contacted', result[0].FunnelStep__c);
		System.assertEquals('Not Interested in Instant Match', result[0].UnsuccessfulReason__c);

	}

	@isTest static void handleEnrollmentUpdate_onboardingStepIncomplete_test() {
		
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
			SetEnrollmentFunnelStepTo__c = 'Contacted',
			IsAutonomous__c = true
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		EnrollmentRule__c rule3 = new EnrollmentRule__c (
			Name = 'test rule3',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested',
			PrerequisiteRuleName__c = 'test rule2'
		);
		insert new List<EnrollmentRule__c> {rule, rule2, rule3};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Contacted', result[0].FunnelStep__c);

	}

	@isTest static void handleEnrollmentUpdate_none_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Ready', result[0].FunnelStep__c);

	}

	@isTest static void handleEnrollmentUpdate_milestone_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment.FunnelStep__c = 'Enrolled';
		insert enrollment;

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Contacted',
			IsAutonomous__c = true
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		ProEnrollmentUtility.createEnrollmentAction(action2);

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals('Enrolled', result[0].FunnelStep__c);

	}

	@isTest static void populateMarketCategory_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(null, true);

        Test.startTest();

        ProEnrollmentUtility.populateMarketCategory();

        Test.stopTest();

        market = [Select Id, RequestCategory__c From Market__c Where Id = :market.Id];

        System.assertEquals(cat.Id, market.RequestCategory__c);

    }
	
}