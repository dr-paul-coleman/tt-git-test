@isTest
private class ProEnrollmentManagerControllerTest {

	@isTest static void getAllEnrollments_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, false);
		Enrollment__c enrollment2 = EAPTestUtility.createEnrollment(a.Id, false);
		enrollment2.enrollment_id__c = '2';
		insert new List<Enrollment__c> {enrollment, enrollment2};

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentManagerController.getAllEnrollments(enrollment.Id);

		Test.stopTest();

		System.assertEquals(2, result.size());

	}

	@isTest static void getEnrollment_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		Test.startTest();

		Enrollment__c result = ProEnrollmentManagerController.getEnrollment(enrollment.Id);

		Test.stopTest();

		System.assertEquals(enrollment.Id, result.Id);

	}

	@isTest static void createEnrollmentActions_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

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

		Test.startTest();

		List<EnrollmentAction__c> result = ProEnrollmentManagerController.createEnrollmentActions(new List<EnrollmentAction__c> {action});

		Test.stopTest();

		System.assertEquals(UserInfo.getUserId(), result[0].CompletedBy__c);

	}

	@isTest static void handleEnrollmentUpdates_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

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
		ProEnrollmentManagerController.createEnrollmentActions(new List<EnrollmentAction__c> {action});

		Test.startTest();

		List<Enrollment__c> result = ProEnrollmentManagerController.handleEnrollmentUpdates(new List<Id> {enrollment.Id});

		Test.stopTest();

		System.assertEquals(enrollment.Id, result[0].Id);
		System.assertEquals('Attempted', result[0].FunnelStep__c);

	}

	@isTest static void assignToMe_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(true);

		Test.startTest();

		Boolean result = ProEnrollmentManagerController.assignToMe(a.Id, false);

		Test.stopTest();

		System.assert(result);

		a = [Select EnrollmentAssignedTo__c From Account Where Id = :a.Id];

		System.assertEquals(UserInfo.getUserId(), a.EnrollmentAssignedTo__c);

	}
    
	@isTest static void assignToAgent_test() {
        
		User testUser = [SELECT Id, Name, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName = 'ProServicesManaging_User' and IsActive = true LIMIT 1];
        
		RequestCategory__c catg = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(catg.Id, true);

		Account a = EAPTestUtility.createAccount(true);   	
    
    	Id agId = testUser.Id;

		Test.startTest();

		Boolean result = ProEnrollmentManagerController.assignToAgent(a.Id, agId);

		Test.stopTest();

		System.assert(result);

		a = [Select EnrollmentAssignedTo__c From Account Where Id = :a.Id];

		System.assertEquals(agId, a.EnrollmentAssignedTo__c);

	}
    
    @isTest static void searchUsers_test() {
		
		UserRole role = [Select Id From UserRole Where DeveloperName = 'SAM_Frontline_User'];
		User testUser = [SELECT Id,Name, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' And Id != :UserInfo.getUserId() AND IsActive=true LIMIT 1];
		testUser.UserRoleId = role.Id;
		update testUser;

		Test.startTest();

		List<User> result = ProEnrollmentManagerController.searchUsers(testUser.Name);

		Test.stopTest();

		System.assert(!result.isEmpty());

	}
    
	@isTest static void enrollAPro_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(false);
		a.EnrollmentAssignedTo__c = UserInfo.getUserId();
		Account a2 = EAPTestUtility.createAccount(false);
		a2.usr_user_id__c = 2;
		insert new List<Account> {a, a2};

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a2.Id, true);

		EnrollAProController.testCallbackEnrollments = new List<Enrollment__c> ();
		EnrollAProController.testEnrollments = new List<Enrollment__c> {enrollment};

		Test.startTest();

		Id result = ProEnrollmentManagerController.enrollAPro(a.Id);

		Test.stopTest();

		a = [Select EnrollmentAssignedTo__c From Account Where Id = :a.Id];
		System.assertEquals(null, a.EnrollmentAssignedTo__c);
		System.assertEquals(enrollment.Id, result);

	}

	@isTest static void getUserInfo_test() {

		Test.startTest();

		User result = ProEnrollmentManagerController.getUserInfo();

		Test.stopTest();

		System.assertEquals(UserInfo.getUserId(), result.Id);

	}
	
}