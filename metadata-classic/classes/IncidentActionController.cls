public class IncidentActionController {

	@AuraEnabled
	public static List<MIIncidentAction__c> getActions(Id incidentId, String status) {

		List<MIIncidentAction__c> result = new List<MIIncidentAction__c> ();
		if (incidentId != null) {

			String statusFilter = '';
			if (String.isNotBlank(status)) {

				statusFilter = 'And Status__c = :status ';

			}
			result = (List<MIIncidentAction__c>) Database.query(
					'Select ' + String.join(MIUtility.miIncidentActionFields, ', ') + ' From MIIncidentAction__c '
							+ 'Where MIIncident__c = :incidentId '
							+ statusFilter
							+ 'And RecordType.DeveloperName = \'Task\' '
							+ 'And Type__c = \'Follow-up\' '
							+ 'order by DueDate__c '
			);

		}
		return result;

	}

	@AuraEnabled
	public static List<NoteWrapper> getNotes(Id incidentId)
	{
		List<NoteWrapper> notes = new List<NoteWrapper>();
		List<MIIncidentAction__c> result = new List<MIIncidentAction__c>();

		if (incidentId != null)
		{
			result = (List<MIIncidentAction__c>) Database.query(
					'Select ' + String.join(MIUtility.miIncidentActionFields, ', ') + ' From MIIncidentAction__c '
							+ 'Where MIIncident__c = :incidentId '
							+ 'And Type__c = \'Note\' '
							+ 'And RecordType.DeveloperName = \'Task\' '
							+ 'order by CreatedDate desc '
			);

			if(!result.isEmpty())
			{
				for(MIIncidentAction__c r : result)
				{
					notes.add(new NoteWrapper(r));
				}
			}
		}

		return notes;
	}

	@AuraEnabled
	public static MIIncidentAction__c upsertAction(MIIncidentAction__c incidentAction, String dueDate) {

		System.debug(dueDate);
		if (String.isNotBlank(dueDate)) {

			/*List<String> dateArray = dueDate.split('/');
			incidentAction.DueDate__c = Date.newInstance(
				Integer.valueOf(dateArray[2]),
				Integer.valueOf(dateArray[0]),
				Integer.valueOf(dateArray[1])*
			);*/
			Date due = Date.valueOf(dueDate);

			incidentAction.DueDate__c = DateTime.newInstance(due.year(), due.month(), due.day());

		}
		if (incidentAction.RecordTypeId == null) {

			incidentAction.RecordTypeId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();

		}
		upsert incidentAction;
		return incidentAction;

	}

	@AuraEnabled
	public static void deleteAction(Id actionId) {

		delete new MIIncidentAction__c (Id = actionId);

	}

	public class NoteWrapper
	{
		@AuraEnabled
		public Boolean isLongNote{get{return this.record != null && this.record.Notes__c != null && this.record.Notes__c.length() > 300;}}

		@AuraEnabled
		public String partialNote{get{return this.isLongNote ? (this.record.Notes__c.substring(0, 250) + '...') : null;}}

		@AuraEnabled
		public MIIncidentAction__c record{get;set;}

		public NoteWrapper(MIIncidentAction__c action)
		{
			this.record = action;
		}

	}

}