/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-05   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class ContentVersionTriggerHandler extends ThumbtackTriggerHandlerBase
{
	// Recursion Prevention Flags
	//private static Boolean isInBeforeInsertProcessing = false;
	//private static Boolean isInBeforeUpdateProcessing = false;
	private static Boolean isInAfterInsertProcessing = false;
	private static Boolean isInAfterUpdateProcessing = false;
	public static Boolean publishAttachmentEvent = true;
	public static Database.SaveResult[] attachmentEventSaveResults = null;

	// TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
	public override void onAfterInsert(ThumbtackTriggerContext ctx)
	{
		if (!isInAfterInsertProcessing)
		{
			isInAfterInsertProcessing = true;
			this.publishAttachmentEvents((List<ContentVersion>) ctx.newRecords, 'New');
		}
	}

	public override void onAfterUpdate(ThumbtackTriggerContext ctx)
	{
		if (!isInAfterUpdateProcessing)
		{
			isInAfterUpdateProcessing = true;
			this.publishAttachmentEvents((List<ContentVersion>) ctx.newRecords, 'Update');
		}
	}

	private void publishAttachmentEvents(List<ContentVersion> cvs, String status)
	{
		if(publishAttachmentEvent)
		{
			List<AttachmentEvent__e> events = new List<AttachmentEvent__e>();

			for (ContentVersion cv : cvs)
			{
				events.add(new AttachmentEvent__e(Status__c = status, RecordName__c = cv.Title, RecordId__c = cv.Id));
			}

			if (!events.isEmpty())
			{
				attachmentEventSaveResults = EventBus.publish(events);
			}
		}
	}
}