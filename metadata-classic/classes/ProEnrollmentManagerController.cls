public with sharing class ProEnrollmentManagerController {

	@AuraEnabled
	public static List<Enrollment__c> getAllEnrollments(Id enrollmentId) {

		List<Enrollment__c> result = new List<Enrollment__c> ();
		if (enrollmentId != null) {

			Enrollment__c enrollment = [Select Id, Account__c From Enrollment__c Where Id = :enrollmentId];
			if (enrollment.Account__c != null) {

				Id accountId = enrollment.Account__c;
				result = (List<Enrollment__c>) Database.query(
					'Select ' + String.join(ProEnrollmentUtility.getEnrollmentFields(), ', ') + ' From Enrollment__c Where Account__c = :accountId '
				);

			}

		}
		return result;

	}

	@AuraEnabled
	public static Enrollment__c getEnrollment(Id enrollmentId) {

		return ProEnrollmentUtility.getEnrollment(enrollmentId);

	}

	@AuraEnabled
	public static List<EnrollmentAction__c> createEnrollmentActions(List<EnrollmentAction__c> actions) {

		return ProEnrollmentUtility.createEnrollmentActions(actions);

	}

	@AuraEnabled
	public static List<Enrollment__c> handleEnrollmentUpdates(List<Id> enrollmentIds) {

		return ProEnrollmentUtility.handleEnrollmentUpdate(enrollmentIds);

	}

	@AuraEnabled
	public static Boolean assignToMe(Id accountId, Boolean removeAssignee) {

		Boolean result = false;
		if (accountId != null) {

			Database.SaveResult sr = Database.update(new Account (
				Id = accountId,
				EnrollmentAssignedTo__c = removeAssignee == true ? null : UserInfo.getUserId()
			));
			result = sr.isSuccess();

		}
		return result;

	}
    
	@AuraEnabled
	public static List<User> searchUsers(String searchText) {

		List<User> result = new List<User> ();
		if (String.isNotBlank(searchText)) {        
			List<String> roleDeveloperNames = new List<String> {
				'ProServicesManaging_User', 'ProServicesFrontLineUser', 'SAM_Frontline_User', 'SAM_Managing_User'
			}; 
			String fuzzySearchText = '%' + searchText + '%';
			result = [Select Id, Name From User 
						Where Name LIKE :fuzzySearchText
						And UserRole.DeveloperName IN :roleDeveloperNames
						order by Name];

		}
		return result;

	}
    
    @AuraEnabled
	public static Boolean assignToAgent(Id accountId, Id agentId) {

		Boolean result = false;
		if (accountId != null && agentId != null) {
			
			Database.SaveResult sr = Database.update(new Account (
				Id = accountId,
				EnrollmentAssignedTo__c = agentId
			));
			result = sr.isSuccess();

		}
		return result;

	}
	@AuraEnabled
	public static Id enrollAPro(Id accountId) {

		if (accountId != null) {

			Account acc = [Select Id, EnrollmentAssignedTo__c, EnrollmentCallbackDateTime__c From Account Where Id = :accountId];
			if (acc.EnrollmentCallbackDateTime__c == null) {

				acc.EnrollmentAssignedTo__c = null;
				update acc;

			}

		}
		return EnrollAProController.enrollAPro();

	}

	@AuraEnabled
	public static User getUserInfo() {

		return ProEnrollmentUtility.getCurrentUser();

	}

}