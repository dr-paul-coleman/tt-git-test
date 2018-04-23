public class IncidentDetailsController {

	@AuraEnabled
	public static String closeMIIncident(Id incidentId) {
		update new MIIncident__c(Id=incidentId,Status__c='Closed',NewEmailFlag__c=false);
		return [SELECT Status__c FROM MIIncident__c WHERE Id = :incidentId LIMIT 1].Status__c;
	}

	@AuraEnabled
	public static List<IncidentFeedItem> getFeed(Id incidentId, Id contactId, String filter, String tabName) {

		List<IncidentFeedItem> result = new List<IncidentFeedItem> ();
		if (incidentId != null && String.isNotBlank(filter)) {

			Set<Id> primaryIds = new Set<Id> {incidentId};
			Map<Id, Case> casesMap = MIUtility.getCases(incidentId, contactId);

			//primaryIds.addAll(MIUtility.getCaseIds(incidentId, contactId));
			primaryIds.addAll(casesMap.keySet());
			result.addAll(getEmails(primaryIds, filter).values());

			if(tabName != 'Pro' && tabName != 'Customer')
			{
				result.addAll(getIncidentActionAndHistory(primaryIds, filter).values());
				result.addAll(getIncidentFactors(primaryIds, filter).values());
			}

			result.addAll(getPhoneCalls(casesMap, primaryIds, filter).values());
			result.addAll(getCaseFeedRecords(primaryIds, filter).values());
			result.addAll(getCaseCommentRecords(primaryIds, filter).values());
			result.sort();

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getEmails(Set<Id> primaryIds, String filter) {

		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();
		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && (filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('emails'))) {

			for (EmailMessage email : (List<EmailMessage>) Database.query(
										'Select ' + String.join(MIUtility.emailMessageFields, ', ') + ' From EmailMessage '
										+ 'Where ParentId IN :primaryIds AND Status != \'5\' '
									)) {

				IncidentFeedItem item = new IncidentFeedItem ();
				item.itemType = 'email';
				item.sortDate = email.MessageDate;
				item.personName = email.FromName;
				item.summary = email.TextBody;

				if(String.isNotBlank(email.HtmlBody))
				{
					item.details = email.HtmlBody;
					item.detailType = 'html';
				}
				else
				{
					item.details = email.TextBody;
					item.detailType = 'text';
				}
				item.email = email;
				item.accountId = email.Parent.AccountId;
				item.contactId = email.Parent.ContactId;
				result.put(email.Id, item);

			}

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getIncidentActionAndHistory(Set<Id> primaryIds, String filter) {

		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();
		if (primaryIds != null && !primaryIds.isEmpty()) {

			Map<Id, IncidentFeedItem> actionMap = getIncidentActions(primaryIds, filter);
			result.putAll(actionMap);
			result.putAll(getIncidentActionHistory(primaryIds));

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getIncidentActions(Set<Id> primaryIds, String filter) {

		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();
		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && (filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('actions') || filter.equalsIgnoreCase('tasks') || filter.equalsIgnoreCase('notes'))) {

			for (MIIncidentAction__c action : (List<MIIncidentAction__c>) Database.query(
										'Select ' + String.join(MIUtility.miIncidentActionFields, ', ') + ' From MIIncidentAction__c '
										+ 'Where MIIncident__c IN :primaryIds '
									)) {

				if ((filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('actions')) && action.RecordType.DeveloperName != 'Task') {

					IncidentFeedItem item = new IncidentFeedItem ();
					item.action = action;
					item.sortDate = action.CreatedDate;
					item.personName = action.CreatedBy.Name;
					item.itemType = 'action';
					item.summary = action.Name;
					item.details = action.Id;
					item.detailType = 'link';
					result.put(action.Id, item);

				}
				if ((filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('notes')) && action.RecordType.DeveloperName == 'Task' && action.Type__c == 'Note') {

					IncidentFeedItem item = new IncidentFeedItem ();
					item.action = action;
					item.sortDate = action.CreatedDate;
					item.personName = action.CreatedBy.Name;
					item.itemType = 'note';
					item.summary = action.Notes__c;
					item.details = action.Notes__c;
					item.detailType = 'text';
					result.put(action.Id, item);

				}
				if ((filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('tasks')) && action.RecordType.DeveloperName == 'Task' && action.Type__c == 'Follow-up') {

					IncidentFeedItem item = new IncidentFeedItem ();
					item.action = action;
					item.sortDate = action.CreatedDate;
					item.personName = action.CreatedBy.Name;
					item.itemType = 'task';
					item.summary = action.Notes__c;
					item.details = action.Notes__c;
					item.detailType = 'text';
					result.put(action.Id, item);

				}

			}

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getIncidentActionHistory(Set<Id> incidentActionIds) {

		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();
		if (incidentActionIds != null && !incidentActionIds.isEmpty()) {

			for (MIIncidentAction__History history : [Select Id, OldValue, NewValue, ParentId, Field, CreatedDate, CreatedBy.Name
														From MIIncidentAction__History
														Where ParentId IN :incidentActionIds]) {

				IncidentFeedItem item = new IncidentFeedItem ();
				item.itemType = 'history';
				item.history = history;
				item.sortDate = history.CreatedDate;
				item.personName = history.CreatedBy.Name;
				item.summary = 'Changed ' + history.Field + ' from ' + history.OldValue + ' to ' + history.NewValue;
				item.details = item.summary;
				item.detailType = 'text';
				result.put(history.Id, item);

			}

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getPhoneCalls(Map<Id, Case> casesMap, Set<Id> primaryIds, String filter) {

		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();

		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && (filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('calls'))) {

			for (Task phoneCall : (List<Task>) Database.query(
									'Select ' + String.join(MIUtility.taskFields, ', ') + ' From Task '
									+ 'Where Type = \'Call\' '
									+ 'And WhatId IN :primaryIds '
								)) {

				Case c = casesMap.get(phoneCall.WhatId);
				IncidentFeedItem item = new IncidentFeedItem ();
				item.itemType = 'call';
				item.sortDate = phoneCall.CreatedDate;
				item.personName = phoneCall.CreatedBy.Name;
				item.summary = phoneCall.Description;
				item.details = phoneCall.Description;
				item.detailType = 'text';
				item.phoneCall = phoneCall;
				item.accountId = c == null ? null : c.AccountId;
				item.contactId = c == null ? null : c.ContactId;
				result.put(phoneCall.Id, item);

			}

		}
		return result;

	}

	public static Map<Id, IncidentFeedItem> getCaseFeedRecords(Set<Id> primaryIds, String filter)
	{
		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();

		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && (filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('notes')))
		{
			Set<String> types = new Set<String>{'CallLogPost', 'TextPost'};

			if(filter.equalsIgnoreCase('notes'))
			{
				types.remove('CallLogPost');
			}

			for (CaseFeed cf : [SELECT Id, Title, Body, CreatedDate, CreatedBy.Name, IsRichText, ParentId, Parent.AccountId,
					Parent.ContactId, Type
					FROM CaseFeed WHERE ParentId IN :primaryIds AND Type IN :types])
			{
				IncidentFeedItem item = new IncidentFeedItem();
				item.itemType = cf.Type;
				item.sortDate = cf.CreatedDate;
				item.personName = cf.CreatedBy.Name;
				item.summary = cf.Body != null ? cf.Body.stripHtmlTags() : '';
				item.details = cf.Body;
				item.detailType = cf.IsRichText ? 'html' : 'text';
				item.caseFeed = cf;
				item.accountId = cf.Parent.AccountId;
				item.contactId = cf.Parent.ContactId;
				result.put(cf.Id, item);
			}

		}

		return result;
	}

	public static Map<Id, IncidentFeedItem> getCaseCommentRecords(Set<Id> primaryIds, String filter)
	{
		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();

		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && (filter.equalsIgnoreCase('all') || filter.equalsIgnoreCase('notes')))
		{
			for (CaseComment cc : [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name, ParentId, Parent.AccountId, Parent.ContactId
									FROM CaseComment WHERE ParentId IN :primaryIds])
			{
				IncidentFeedItem item = new IncidentFeedItem();
				item.itemType = 'CaseCommentPost';
				item.sortDate = cc.CreatedDate;
				item.personName = cc.CreatedBy.Name;
				item.summary = cc.CommentBody != null ? cc.CommentBody.stripHtmlTags() : '';
				item.details = cc.CommentBody;
				item.detailType = 'text';
				item.caseComment = cc;
				item.accountId = cc.Parent.AccountId;
				item.contactId = cc.Parent.ContactId;
				result.put(cc.Id, item);
			}

		}

		return result;
	}

	public static Map<Id, IncidentFeedItem> getIncidentFactors(Set<Id> primaryIds, String filter)
	{
		Map<Id, IncidentFeedItem> result = new Map<Id, IncidentFeedItem> ();

		if (primaryIds != null && !primaryIds.isEmpty() && String.isNotBlank(filter) && filter.equalsIgnoreCase('all'))
		{
			List<IncidentFactorAssignment__c> assignments = [
					SELECT Id, Factor__r.Name, Owner.Name, CreatedDate
					FROM IncidentFactorAssignment__c
					WHERE Incident__c IN :primaryIds AND IsDeleted__c != true
					ORDER BY Owner.Name, Factor__r.Name
			];

			for(IncidentFactorAssignment__c a : assignments)
			{
				IncidentFeedItem item = new IncidentFeedItem();
				item.itemType = 'IncidentFactor';
				item.sortDate = a.CreatedDate;
				item.personName = a.Owner.Name;
				item.summary = a.Factor__r.Name;
				item.details = a.Factor__r.Name;
				item.detailType = 'text';
				item.factorAssignment = a;
				result.put(a.Id, item);
			}
		}

		return result;
	}
}