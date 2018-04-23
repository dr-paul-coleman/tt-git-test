@isTest
private class QueueUtilityTest {

	@isTest static void getEnrollmentQueueId_test() {

		QueueSObject enrollmentQueue = [Select QueueId, Queue.DeveloperName From QueueSObject Where SobjectType = 'Enrollment__c' limit 1];
		
		Test.startTest();

		Id result = QueueUtility.getEnrollmentQueueId(enrollmentQueue.Queue.DeveloperName);

		Test.stopTest();

		System.assertEquals(enrollmentQueue.QueueId, result);

	}
	
	@isTest static void getAllEnrollmentQueueIds_test() {
		
		Test.startTest();

		List<Id> result = QueueUtility.getAllEnrollmentQueueIds();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void getWorkItemQueueId_test() {

		QueueSObject workItemQueue = [Select QueueId, Queue.DeveloperName From QueueSObject Where SobjectType = 'WorkItem__c' limit 1];
		
		Test.startTest();

		Id result = QueueUtility.getWorkItemQueueId(workItemQueue.Queue.DeveloperName);

		Test.stopTest();

		System.assertEquals(workItemQueue.QueueId, result);

	}
	
	@isTest static void getAllWorkItemQueueIds_test() {
		
		Test.startTest();

		List<Id> result = QueueUtility.getAllWorkItemQueueIds();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}
	
}