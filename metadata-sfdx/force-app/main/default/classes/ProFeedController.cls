public with sharing class ProFeedController {
	
	@AuraEnabled
	public static List<EnrollmentAction__c> getFeedItems(Id accountId, String type, Id enrollmentId) {

		List<EnrollmentAction__c> result = new List<EnrollmentAction__c> ();
		if (accountId != null) {

			result = (List<EnrollmentAction__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
				+ 'Where Enrollment__r.Account__c = :accountId '
				+ 'And Type__c = :type '
				+ (enrollmentId != null ? 'And Enrollment__c = :enrollmentId ' : '')
				+ 'order by CompletedOn__c desc '
			);

		}
		return result;

	}

	@AuraEnabled
	public static List<Map<String, SObject>> getTaskFeedItems(Id accountId, Id enrollmentId) {

		List<Map<String, SObject>> result = new List<Map<String, SObject>> ();
		if (accountId != null) {

			Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c> ((List<Enrollment__c>) Database.query(
				'Select Id, Market__r.rca_name__c, Market__r.zip_cbsa_name__c From Enrollment__c '
				+ 'Where Account__c = :accountId '
				+ (enrollmentId != null ? 'And Id = :enrollmentId ' : '')
			));
			for (Task t : [Select Id, CreatedDate, CallType, Owner.Name, CallRecordingLink__c, WhatId
							From Task
							Where WhatId IN :enrollmentMap.keySet()
							And CallType != null
							order by CreatedDate desc]) {

				result.add(new Map<String, SObject> {
					'Task' => t,
					'Enrollment__r' => enrollmentMap.get(t.WhatId)
				});

			}

		}
		return result;

	}

}