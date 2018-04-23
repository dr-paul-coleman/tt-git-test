/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.                

Version  Date         Author              Description
========+============+===================+================================================
1.0      2017-05-03   Allen Bishop 		  Created
1.1		 2017-09-20	  Meenakshi Pisupati  Updated - Added Header; 
										  Replaced 'ProAssist' with 'Instant Match'	
========+============+===================+===============================================*/
@isTest
private class EnrollmentActionManagerControllerTest {
	
	@isTest static void getFunnelSteps_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		List<String> result = EnrollmentActionManagerController.getFunnelSteps(enrollment.Id);

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getFunnelStepEndpoint_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		String result = EnrollmentActionManagerController.getFunnelStepEndpoint(enrollment.Id);

		Test.stopTest();

		OutreachTypeSetting__mdt setting = [Select FunnelStepEndpoint__c From OutreachTypeSetting__mdt Where MasterLabel = :enrollment.outreach_type__c.toLowerCase()];

		System.assertEquals(setting.FunnelStepEndpoint__c, result);

	}
	
	@isTest static void getProContact_test() {
		
		Account acc = EAPTestUtility.createAccount(true);

		Test.startTest();

		Id result = EnrollmentActionManagerController.getProContact(acc.Id);

		Test.stopTest();

		System.assert(result != null);

	}

	@isTest static void getFeedItems_test() {
		
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

		List<EnrollmentAction__c> result = EnrollmentActionManagerController.getFeedItems(enrollment.Id);

		Test.stopTest();

		System.assertEquals(action.Id, result[0].Id);

	}

	@isTest static void searchUsers_test() {
		
		UserRole role = [Select Id From UserRole Where DeveloperName = 'SAM_Frontline_User'];
		User testUser = [SELECT Id,Name, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' And Id != :UserInfo.getUserId() AND IsActive=true LIMIT 1];
		testUser.UserRoleId = role.Id;
		update testUser;

		Test.startTest();

		List<User> result = EnrollmentActionManagerController.searchUsers(testUser.Name);

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getEnrollment_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.getEnrollment(enrollment.Id);

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
			EnrollmentActionType__c = 'Outreach Attempt',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
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
			CallbackPhone__c = '8046945540'
		);

		Test.startTest();

		EnrollmentActionManagerController.createEnrollmentAction(action, '5/4/2017', '11:30', 'Myself');

		acc = [Select EnrollmentAssignedTo__c From Account Where Id = :acc.Id];

		System.assertEquals(UserInfo.getUserId(), acc.EnrollmentAssignedTo__c);

		User testUser = [SELECT Id,Name, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' And Id != :UserInfo.getUserId() AND IsActive=true LIMIT 1];
		
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);

		EnrollmentActionManagerController.createEnrollmentAction(action2, '5/5/2017', '11:30', testUser.Id);

		Test.stopTest();

		acc = [Select EnrollmentAssignedTo__c From Account Where Id = :acc.Id];

		System.assertEquals(testUser.Id, acc.EnrollmentAssignedTo__c);

	}

	@isTest static void getPrevOnboardingSteps_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment.FunnelStep__c = 'Attempted';
		insert enrollment;

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted'
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			PrerequisiteRuleName__c = 'test rule'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);

		Test.startTest();

		List<EnrollmentItem> result = EnrollmentActionManagerController.getPrevOnboardingSteps(enrollment.Id, new List<String> {'Ready'}, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getOnboardingSteps_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(false);
		acc.EnrollmentCallbackDateTime__c = System.now();
		acc.EnrollmentCallbackOrigin__c = 'Pro Requested';
		acc.EnrollmentCallbackPhone__c = '5555555555';
		insert acc;

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			SubSteps__c = 'sub steps'
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			PrerequisiteRuleName__c = 'test rule',
			EnrollmentActionOutcome__c = 'outcome1'
		);
		EnrollmentRule__c rule3 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			PrerequisiteRuleName__c = 'test rule',
			EnrollmentActionOutcome__c = 'outcome2',
			Details__c = 'detail1'
		);
		EnrollmentRule__c rule4 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentOutreachGroup__c = '1_VIP',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Attempted',
			PrerequisiteRuleName__c = 'test rule',
			EnrollmentActionOutcome__c = 'outcome2',
			Details__c = 'detail2'
		);
		insert new List<EnrollmentRule__c> {rule, rule2, rule3, rule4};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);

		Test.startTest();

		List<EnrollmentItem> result = EnrollmentActionManagerController.getOnboardingSteps(enrollment.Id, 'Ready', 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getOutreachDispositions_test() {
		
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
		insert rule;

		Test.startTest();

		List<EnrollmentRule__c> result = EnrollmentActionManagerController.getOutreachDispositions('Ready', 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals(rule.Id, result[0].Id);

	}

	@isTest static void getOutreachHistory_test() {
		
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

		List<EnrollmentAction__c> result = EnrollmentActionManagerController.getOutreachHistory(enrollment.Id);

		Test.stopTest();

		System.assertEquals(action.Id, result[0].Id);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Contacted', result.FunnelStep__c);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Outreach Attempt',
			OutreachDisposition__c = 'No Attempt Necessary'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Attempted', result.FunnelStep__c);
		System.assertEquals('Not Interested in Instant Match', result.UnsuccessfulReason__c);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Interested', result.FunnelStep__c);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Contacted', result.FunnelStep__c);
		System.assertEquals('Not Interested in Instant Match', result.UnsuccessfulReason__c);

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
			SetEnrollmentFunnelStepTo__c = 'Interested'
		);
		insert new List<EnrollmentRule__c> {rule, rule2, rule3};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Contacted', result.FunnelStep__c);

	}

	@isTest static void handleEnrollmentUpdate_none_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Ready', result.FunnelStep__c);

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
		EnrollmentActionManagerController.createEnrollmentAction(action, null, null, null);
		EnrollmentAction__c action2 = new EnrollmentAction__c (
			Name = rule2.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule2.Id),
			Type__c = 'Onboarding Step'
		);
		EnrollmentActionManagerController.createEnrollmentAction(action2, null, null, null);

		Test.startTest();

		Enrollment__c result = EnrollmentActionManagerController.handleEnrollmentUpdate(enrollment.Id, 'Early_enrollment', '1_VIP');

		Test.stopTest();

		System.assertEquals('Enrolled', result.FunnelStep__c);

	}
	
}