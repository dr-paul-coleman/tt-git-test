@isTest
private class ProHeaderControllerTest {
	
	@isTest static void getAccount_test() {
		
		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		Account result = ProHeaderController.getAccount(enrollment.Id);

		Test.stopTest();

		System.assertEquals(result.Id, acc.Id);

	}

	@isTest static void testGetEnrollment() {

		RequestCategory__c cat = EAPTestUtility.createRequestCategory(true);

		Market__c market = EAPTestUtility.createMarket(cat.Id, true);

		Account acc = EAPTestUtility.createAccount(true);

		Enrollment__c enrollment = EAPTestUtility.createEnrollment(acc.Id, true);

		Test.startTest();

		Enrollment__c result = ProHeaderController.getEnrollment(enrollment.Id);

		Test.stopTest();

		System.assertEquals(result.Id, enrollment.Id);

	}
	
}