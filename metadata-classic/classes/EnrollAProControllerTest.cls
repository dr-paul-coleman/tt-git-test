/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version  Date     	 Author            	Description                          
=======+===========+==================+======================================
1.0      2017-03-27  Travis Oliver      Created 
1.1		 2017-09-21	 Meena Pisupati		Added Header										
=======+===========+==================+======================================*/
@isTest
private class EnrollAProControllerTest {
	
	@isTest static void enrollAPro_test() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account a = EAPTestUtility.createAccount(false);
		a.EnrollmentCallbackDateTime__c = Datetime.now();
		insert a;

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(a.Id, true);

		EnrollAProController.testCallbackEnrollments = new List<Enrollment__c> ();
		EnrollAProController.testEnrollments = new List<Enrollment__c> {enrollment};

		String userFilter = JSON.serialize(new Map<String, List<Map<String, String>>> {
			'RequestCategory__c' => new List<Map<String, String>> {
				new Map<String, String> {
					'label' => cat.rca_name__c,
					'value' => cat.Id,
					'selected' => 'yes',
					'hide' => 'no',
					'category' => 'RequestCategory__c'
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

		Id result = EnrollAProController.enrollAPro();

		Test.stopTest();

		System.assertEquals(enrollment.Id, result);

	}
    
    @isTest static void enrollAPro_test_no_markets() {

		Account a = EAPTestUtility.createAccount(false);
		a.EnrollmentCallbackDateTime__c = Datetime.now();
		insert a;

		Enrollment__c enrollment = EAPTestUtility.createNoMarketEnrollment(a.Id, true);

		EnrollAProController.testCallbackEnrollments = new List<Enrollment__c> ();
		EnrollAProController.testEnrollments = new List<Enrollment__c> {enrollment};

		String userFilter = JSON.serialize(new Map<String, List<Map<String, String>>> {
			'outreach_type__c' => new List<Map<String, String>> {
				new Map<String, String> {
					'label' => 'Pro onboarding',
                    'value' => 'pro_onboarding',
                    'selected' => 'yes',
                    'hide' => 'yes',
                    'category' => 'outreach_type__c'
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

		Id result = EnrollAProController.enrollAPro();

		Test.stopTest();

		System.assertEquals(enrollment.Id, result);

	}


}