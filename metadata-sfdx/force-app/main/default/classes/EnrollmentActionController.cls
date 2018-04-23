public with sharing class EnrollmentActionController {
	
	@AuraEnabled
	public static EnrollmentAction__c createEnrollmentAction(EnrollmentAction__c action, Boolean isCallbackRule) {

		Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(action.Enrollment__c);
		action.OutreachGroup__c = enrollment.outreach_group__c;
		if (isCallbackRule) {

			Account acc = new Account (
				Id = enrollment.Account__c,
				EnrollmentCallbackDateTime__c = null,
				EnrollmentCallbackOrigin__c = null,
				EnrollmentCallbackScheduledBy__c = null
			);
			update acc;

		}
		if (String.isNotBlank(action.URL__c)) {

			enrollment = new Enrollment__c (
				Id = action.Enrollment__c,
				PricingURL__c = action.URL__c
			);
			update enrollment;

		}
		return ProEnrollmentUtility.createEnrollmentAction(action);

	}

	@AuraEnabled
	public static String saveURL(Id enrollmentId, String url) {

		String result;
		if (enrollmentId != null && String.isNotBlank(url)) {

			Enrollment__c enrollment = new Enrollment__c (
				Id = enrollmentId,
				PricingURL__c = url
			);
			update enrollment;
			result = url;

		}
		return result;

	}

	@AuraEnabled
	public static void deleteEnrollmentAction(Id actionId) {

		delete new EnrollmentAction__c (Id = actionId);

	}

}