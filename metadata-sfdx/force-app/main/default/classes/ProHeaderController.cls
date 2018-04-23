public with sharing class ProHeaderController {
	
	@AuraEnabled
	public static Account getAccount(Id enrollmentId) {

		Account result;
		if (enrollmentId != null) {

			Enrollment__c enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollmentId];
			if (enrollment.Account__c != null) {

				result = [Select Id, AdminLinkLoginAsUser__c,Name, usr_first_name__c, usr_last_name__c, ThumbtackUserID__c, sav_phn_phone_number__c, usr_email__c,usr_timezone__c, Phone,
							BillingStreet, BillingCity, BillingState, BillingPostalCode, EnrollmentAssignedTo__c, EnrollmentAssignedTo__r.Name,
								(Select Id From Cases Where IsClosed = false),
								(Select Id From Enrollments__r Where top_pro__c = true limit 1)
							From Account Where Id = :enrollment.Account__c];

			}

		}
		return result;

	}

	@AuraEnabled
	public static Enrollment__c getEnrollment(Id enrollmentId)
	{
		Enrollment__c result;

		if (enrollmentId != null)
		{
			result = ProEnrollmentUtility.getEnrollment(enrollmentId);
		}

		return result;
	}
	
}