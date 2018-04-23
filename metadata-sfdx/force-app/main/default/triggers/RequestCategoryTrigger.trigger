trigger RequestCategoryTrigger on RequestCategory__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	if (Trigger.isAfter) {

		if (Trigger.isUpdate) {

			EnrollmentEventLogUtility.handleObjectChanges(Trigger.new, Trigger.oldMap);

		}

	}
	if (Trigger.isBefore) {

		if (Trigger.isUpdate) {

			RequestCategoryTriggerHandler.handleUpdate(Trigger.new, Trigger.oldMap);

		}

	}

}