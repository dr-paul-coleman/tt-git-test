/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version  Date     	 Author            	Description                          
=======+============+==================+======================================
1.0      2017-07-21  Adam Schultz       Created 
1.1		 2017-09-21	 Meena Pisupati		Replaced ProAssist with Instant Match,
										Added Header
=======+============+==================+======================================*/
@isTest
private class RequestCategoryTriggerHandlerTest {
	
	@isTest static void handleOutreachTypeChange() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment.FunnelStep__c = 'Enrolled';
		Enrollment__c enrollment2 = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment2.enrollment_id__c = '2';
		insert new List<Enrollment__c> {enrollment, enrollment2};

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Enrolled',
			IsAutonomous__c = true
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Live on Instant Match',
			IsAutomatedAction__c = true,
			CategoryOutreachTypeAutomatedTarget__c = 'Product_enabled'
		);
		insert new List<EnrollmentRule__c> {rule, rule2};

		EnrollmentAction__c action = new EnrollmentAction__c (
			Name = rule.Name,
			Enrollment__c = enrollment.Id,
			RuleId__c = String.valueOf(rule.Id),
			Type__c = 'Onboarding Step',
			CallbackOutreachType__c = 'Product_enabled'
		);
		ProEnrollmentUtility.createEnrollmentAction(action);
		
		Test.startTest();

		cat.outreach_type__c = 'Product_enabled';
		update cat;

		Test.stopTest();

		List<EnrollmentAction__c> result = [Select Id From EnrollmentAction__c Where RuleId__c = :String.valueOf(rule2.Id)];

		System.assert(!result.isEmpty());

		acc = [Select EnrollmentCallbackDateTime__c, EnrollmentCallbackOrigin__c From Account Where Id = :acc.Id];
		System.assertEquals('System', acc.EnrollmentCallbackOrigin__c);
		System.assert(acc.EnrollmentCallbackDateTime__c != null);

	}

	@isTest static void handleOutreachTypeChange2() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(false);
		cat.outreach_type__c = 'Product_enabled';
		insert cat;

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment.FunnelStep__c = 'Live on Instant Match';
		Enrollment__c enrollment2 = EAPTestUtility.createEnrollment(acc.Id, false);
		enrollment2.enrollment_id__c = '2';
		insert new List<Enrollment__c> {enrollment, enrollment2};

		EnrollmentRule__c rule = new EnrollmentRule__c (
			Name = 'test rule',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Ready',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Enrolled',
			IsAutonomous__c = true
		);
		EnrollmentRule__c rule2 = new EnrollmentRule__c (
			Name = 'test rule2',
			EnrollmentActionType__c = 'Onboarding Step',
			EnrollmentOutreachType__c = 'Early_enrollment',
			EnrollmentFunnelStep__c = 'Contacted',
			IsActive__c = true,
			SetEnrollmentFunnelStepTo__c = 'Live on Instant Match',
			IsAutomatedAction__c = true,
			CategoryOutreachTypeAutomatedTarget__c = 'Product_enabled'
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

		cat.outreach_type__c = 'Early_enrollment';
		update cat;

		Test.stopTest();

		List<EnrollmentAction__c>  result = [Select Id From EnrollmentAction__c Where RuleId__c = :String.valueOf(rule2.Id)];

		System.assert(result.isEmpty());

	}

	@isTest static void disableMarkets_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(false);
		cat.EnrollAProEnabled__c = false;
		insert cat;

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);
		// market was inserted in EAPTestUtility.createMarket

		Test.startTest();

		cat.outreach_type__c = 'product_enabled';
		update cat;

		Test.stopTest();

		market = [Select Id, EnrollAProEnabled__c From Market__c Where Id = :market.Id];
		System.assert(market != null);
        System.assert(market.EnrollAProEnabled__c == false);

	}
	
}