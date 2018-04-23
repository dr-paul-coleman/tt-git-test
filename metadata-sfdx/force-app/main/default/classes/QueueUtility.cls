public class QueueUtility {

	private static Map<String, Id> enrollmentQueueMap {

		get {

			if (enrollmentQueueMap == null) {

				enrollmentQueueMap = new Map<String, Id> ();
				for (QueueSobject qObject : [Select Queue.DeveloperName, QueueId From QueueSobject Where SobjectType = 'Enrollment__c']) {

					enrollmentQueueMap.put(qObject.Queue.DeveloperName, qObject.QueueId);

				}

			}
			return enrollmentQueueMap;

		} set;

	}

	private static Map<String, Id> workItemQueueMap {

		get {

			if (workItemQueueMap == null) {

				workItemQueueMap = new Map<String, Id> ();
				for (QueueSobject qObject : [Select Queue.DeveloperName, QueueId From QueueSobject Where SobjectType = 'WorkItem__c']) {

					workItemQueueMap.put(qObject.Queue.DeveloperName, qObject.QueueId);

				}

			}
			return workItemQueueMap;

		} set;

	}

	public static Id getEnrollmentQueueId(String developerName) {

		return enrollmentQueueMap.get(developerName);

	}

	public static List<Id> getAllEnrollmentQueueIds() {

		return enrollmentQueueMap.values();

	}

	public static Id getWorkItemQueueId(String developerName) {

		return workItemQueueMap.get(developerName);

	}

	public static List<Id> getAllWorkItemQueueIds() {

		return workItemQueueMap.values();

	}

}