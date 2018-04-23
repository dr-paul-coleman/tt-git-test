/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-03   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

public with sharing class WorkItemTransferController
{
	@AuraEnabled
	public static List<WorkItemGroup> getWorkItemsByType()
	{
		AggregateResult[] ars = [SELECT Count(Id) items, Type__c
								FROM WorkItem__c
								WHERE Status__c != 'Completed' AND OwnerIsQueue__c = true AND Type__c != null
									 AND RecordTypeId = :WorkItemHelper.STANDARD_WORK_ITEM_RECORD_TYPE_ID
								GROUP BY Type__c];
		Map<String, WorkItemGroup> groupsMap = new Map<String, WorkItemGroup>();
		List<Schema.PicklistEntry> ples = WorkItem__c.Type__c.getDescribe().getPicklistValues();
		List<WorkItemGroup> groups = new List<WorkItemGroup>();

		for(AggregateResult ar : ars)
		{
			groupsMap.put((String)ar.get('Type__c'), new WorkItemGroup((String)ar.get('Type__c'), (Integer)ar.get('items')));
		}

		//Using picklist order
		for(Schema.PicklistEntry p : ples)
		{
			if (!groupsMap.containsKey(p.getValue()))
			{
				groups.add(new WorkItemGroup(p.getValue(), 0));
			}
			else
			{
				groups.add(groupsMap.get(p.getValue()));
			}
		}

		return groups;
	}

	@AuraEnabled
	public static List<WorkItemGroup> getWorkItemsByRecordType()
	{
		AggregateResult[] ars = [SELECT Count(Id) items, RecordType.Name rt
									FROM WorkItem__c
									WHERE Status__c != 'Completed' AND OwnerIsQueue__c = true
										AND (RecordTypeId = :WorkItemHelper.BLACKLISTED_NUMBER_RECORD_TYPE_ID OR
												RecordTypeId = :WorkItemHelper.CONCERNING_REVIEW_RECORD_TYPE_ID)
									GROUP BY RecordType.Name];
		Map<String, WorkItemGroup> groupsMap = new Map<String, WorkItemGroup>();
		List<Schema.PicklistEntry> ples = WorkItem__c.Type__c.getDescribe().getPicklistValues();
		List<WorkItemGroup> groups = new List<WorkItemGroup>();

		for(AggregateResult ar : ars)
		{
			groupsMap.put((String)ar.get('rt'), new WorkItemGroup((String)ar.get('rt'), (Integer)ar.get('items')));
		}

		if(groupsMap.containsKey('Blacklisted Number'))
		{
			groups.add(groupsMap.get('Blacklisted Number'));
		}
		else
		{
			groups.add(new WorkItemGroup('Blacklisted Number', 0));
		}

		if(groupsMap.containsKey('Concerning Review'))
		{
			groups.add(groupsMap.get('Concerning Review'));
		}
		else
		{
			groups.add(new WorkItemGroup('Concerning Review', 0));
		}

		return groups;
	}

	@AuraEnabled
	public static WorkItem__c takeWorkItem(String type)
	{
		List<WorkItem__c> items = [SELECT Id, Name FROM WorkItem__c
									WHERE Type__c = :type  AND Status__c != 'Completed' AND OwnerIsQueue__c = true
									ORDER BY CreatedDate ASC LIMIT 1];
		WorkItem__c wi = null;

		if(!items.isEmpty())
		{
			wi = items[0];
			wi.OwnerId = UserInfo.getUserId();
			update wi;
		}

		return wi;
	}

	@AuraEnabled
	public static WorkItem__c takeWorkItemRT(String recordTypeName)
	{
		List<WorkItem__c> items = [SELECT Id, Name FROM WorkItem__c
									WHERE RecordType.Name = :recordTypeName  AND Status__c != 'Completed' AND OwnerIsQueue__c = true
									ORDER BY CreatedDate ASC LIMIT 1];
		WorkItem__c wi = null;

		if(!items.isEmpty())
		{
			wi = items[0];
			wi.OwnerId = UserInfo.getUserId();
			update wi;
		}

		return wi;
	}

	public class WorkItemGroup
	{
		@AuraEnabled
		public String name{get;set;}

		@AuraEnabled
		public Integer count{get;set;}

		public WorkItemGroup(String name, Integer count)
		{
			this.name = name;
			this.count = count;
		}
	}
}