/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : TaskTriggerHandler.cls  
 Script Type         : Standard Apex Trigger Handler Class 
 Description         : Static Functions to handle Trigger Events

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-04-24  Paul Coleman      Created

 1.1     2017-09-28  Mendel Guillaume  Refactored and added thumbtack
                                       first response functionality
 =======+===========+=================+=================================*/

public with sharing class TaskTriggerHandler
{
	public static void onBeforeInsert(List<Task> newRecords)
	{
		Map<Id, List<Task>> caseIdToTasksMap = new Map<Id, List<Task>>();

		for(Task t : newRecords)
		{
			if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500'))
			{
				List<Task> caseTasks = caseIdToTasksMap.get(t.WhatId);

				if(caseTasks == null)
				{
					caseTasks = new List<Task>();
					caseIdToTasksMap.put(t.WhatId, caseTasks);
				}

				caseTasks.add(t);
			}
		}

		if(!caseIdToTasksMap.isEmpty())
		{
			setWhoIdFromCaseContact(caseIdToTasksMap);
		}
	}

	public static void onBeforeUpdate(Map<Id, Task> newRecordsMap, Map<Id, Task> oldRecordsMap)
	{
		Map<Id, List<Task>> caseIdToTasksMap = new Map<Id, List<Task>>();

		for(Task t : newRecordsMap.values())
		{
			Task old = oldRecordsMap.get(t.Id);

			if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500') && t.WhatId != old.WhatId)
			{
				List<Task> caseTasks = caseIdToTasksMap.get(t.WhatId);

				if(caseTasks == null)
				{
					caseTasks = new List<Task>();
					caseIdToTasksMap.put(t.WhatId, caseTasks);
				}

				caseTasks.add(t);
			}
		}

		if(!caseIdToTasksMap.isEmpty())
		{
			setWhoIdFromCaseContact(caseIdToTasksMap);
		}
	}

	public static void onAfterInsert(Map<Id, Task> newRecordsMap)
	{
		Map<Id, Datetime> caseIdFirstResponseMap = new Map<Id, Datetime>();

		for(Task t : newRecordsMap.values())
		{
			if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500'))
			{
				Datetime fr = caseIdFirstResponseMap.get(t.WhatId);

				//Use earliest due date for each task (bulk insert)
				if(fr == null || fr > t.CreatedDate)
				{
					caseIdFirstResponseMap.put(t.WhatId, t.CreatedDate);
				}
			}
		}

		if(!caseIdFirstResponseMap.isEmpty())
		{
			setCaseFirstResponse(caseIdFirstResponseMap);
		}
	}

	private static void setWhoIdFromCaseContact(Map<Id, List<Task>> caseIdToTasksMap)
	{
		List<Case> cases = [SELECT Id,ContactId FROM Case WHERE Id IN :caseIdToTasksMap.keySet()];

		for(Case c : cases)
		{
			List<Task> caseTasks = caseIdToTasksMap.get(c.Id);

			if(caseTasks != null)
			{
				for(Task t : caseTasks)
				{
					t.WhoId = c.ContactId;
				}
			}
		}

	}

	public static void setCaseFirstResponse(Map<Id, Datetime> caseIdFirstResponseMap)
	{
		List<Case> cases = [SELECT Id FROM Case WHERE ID IN :caseIdFirstResponseMap.keySet() AND FirstThumbtackResponse__c = null];
		List<Case> casesToUpdate = new List<Case>();

		for(Case c : cases)
		{
			Datetime fr = caseIdFirstResponseMap.get(c.Id);

			if(fr == null)
			{
				fr = Datetime.now();
			}

			c.FirstThumbtackResponse__c = fr;

			casesToUpdate.add(c);
		}

		if(!casesToUpdate.isEmpty())
		{
			update casesToUpdate;
		}
	}


	/*
	private TaskTriggerHandler() {}

	// before insert/update
	// set Task.WhoId to Case.ContactId
	public static void setWhoIdFromCaseContact(List<Task> TriggerNew) {
		
		//collect Case record Ids from Task.WhatId, if any
		Set<Id> caseIds = new Set<Id>();
		for(Task tk: TriggerNew) {
			String taskWhatId = tk.WhatId;
			if(taskWhatId != null && taskWhatId.startsWith('500')){
				caseIds.add(taskWhatId);
			}
		}

		//set the Task.WhoId to the related Case.ContactId, if any
		Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,ContactId FROM Case WHERE Id IN :caseIds]);
		for(Task tsk: TriggerNew) {
			String whatId = tsk.WhatId;
			if(whatId != null && whatId.startsWith('500')){
				Case c = caseMap.get(tsk.WhatId);
				tsk.WhoId = c != null? c.ContactId: tsk.WhoId;
			}
		}
	}*/
}