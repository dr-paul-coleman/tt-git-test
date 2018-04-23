/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-10   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

public with sharing class AttachmentTriggerHandler
{
	public static Boolean publishAttachmentEvent = true;
	public static Database.SaveResult[] attachmentEventSaveResults = null;

	public static void onBeforeUpdate(Map<Id, Attachment> newRecordsMap, Map<Id, Attachment> oldRecordsMap)
	{
		List<String> bugIds = new List<String>();

		for(Attachment att: newRecordsMap.values())
		{
			bugIds.add(att.ParentId);
		}

		if(bugIds.size()>0)
		{
			JiraCallout.AttachmentHandler(bugIds, newRecordsMap.values());
		}
	}

	public static void onAfterInsert(Map<Id, Attachment> newRecordsMap)
	{
		publishAttachmentEvents(newRecordsMap.values(), 'New');
	}

	public static void onAfterUpdate(Map<Id, Attachment> newRecordsMap, Map<Id, Attachment> oldRecordsMap)
	{
		publishAttachmentEvents(newRecordsMap.values(), 'Update');
	}

	private static void publishAttachmentEvents(List<Attachment> attachments, String status)
	{
		if(publishAttachmentEvent)
		{
			List<AttachmentEvent__e> events = new List<AttachmentEvent__e>();

			for (Attachment a : attachments)
			{
				events.add(new AttachmentEvent__e(Status__c = status, RecordName__c = a.Name, RecordId__c = a.Id));
			}

			if (!events.isEmpty())
			{
				attachmentEventSaveResults = EventBus.publish(events);
			}
		}
	}
}