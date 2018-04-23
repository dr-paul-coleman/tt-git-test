/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-09-29   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

public with sharing class LiveChatTranscriptTriggerHandler extends ThumbtackTriggerHandlerBase
{
	// Recursion Prevention Flags
	//private static Boolean isInBeforeInsertProcessing = false;
	//private static Boolean isInBeforeUpdateProcessing = false;
	private static Boolean isInAfterInsertProcessing = false;
	private static Boolean isInAfterUpdateProcessing = false;

	// TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
	public override void onAfterInsert(ThumbtackTriggerContext ctx)
	{
		List<LiveChatTranscript> newRecords = (List<LiveChatTranscript>) ctx.newRecords;
		Map<Id, Datetime> caseIdToFirstTranscriptDate = new Map<Id, Datetime>();
		List<LiveChatTranscript> completedLiveChatTranscripts = new List<LiveChatTranscript>();

		if (!isInAfterInsertProcessing)
		{
			isInAfterInsertProcessing = true;

			for(LiveChatTranscript lct : newRecords)
			{
				if(lct.CaseId != null)
				{
					Datetime td = caseIdToFirstTranscriptDate.get(lct.CaseId);

					if(td == null || td > lct.CreatedDate)
					{
						caseIdToFirstTranscriptDate.put(lct.CaseId, lct.CreatedDate);
					}

					if(lct.Status == 'Completed' && String.isNotBlank(lct.Body))
					{
						completedLiveChatTranscripts.add(lct);
					}
				}
			}

			if(!caseIdToFirstTranscriptDate.isEmpty())
			{
				TaskTriggerHandler.setCaseFirstResponse(caseIdToFirstTranscriptDate);
			}

			if(!completedLiveChatTranscripts.isEmpty())
			{
				this.createCaseFeedItems(completedLiveChatTranscripts);
			}
		}
	}

	public override void onAfterUpdate(ThumbtackTriggerContext ctx)
	{
		List<LiveChatTranscript> newRecords = (List<LiveChatTranscript>) ctx.newRecords;
		Map<Id, LiveChatTranscript> oldRecordsMap = (Map<Id, LiveChatTranscript>) ctx.oldRecordsMap;
		List<LiveChatTranscript> completedLiveChatTranscripts = new List<LiveChatTranscript>();

		if (!isInAfterUpdateProcessing)
		{
			isInAfterUpdateProcessing = true;

			for(LiveChatTranscript lct : newRecords)
			{
				LiveChatTranscript old = oldRecordsMap.get(lct.Id);

				if (lct.CaseId != null && lct.Status == 'Completed' && String.isNotBlank(lct.Body)
						&& lct.Status != old.Status)
				{
					completedLiveChatTranscripts.add(lct);
				}
			}

			if(!completedLiveChatTranscripts.isEmpty())
			{
				this.createCaseFeedItems(completedLiveChatTranscripts);
			}
		}
	}

	private void createCaseFeedItems(List<LiveChatTranscript> completedTranscripts)
	{
		List<FeedItem> feedItems = new List<FeedItem>();
		//System.debug('createCaseFeedItems: ' + completedTranscripts);

		for(LiveChatTranscript lct : completedTranscripts)
		{
			String body = lct.Body.replace('</p>', '{br}').replace('<br>', '{br}').replace('<br/>', '{br}').stripHtmlTags().replace('{br}', '<p>&nbsp;</p>');

			feedItems.add(new FeedItem(Type = 'TextPost', IsRichText = true, ParentId = lct.CaseId, Status = 'Published',
					Body = body + '<p>&nbsp;</p>Transcript: ' + lct.Name));
		}

		if(!feedItems.isEmpty())
		{
			insert feedItems;
			//System.debug('createCaseFeedItems - after feed insert:' + feedItems);
		}
	}
}