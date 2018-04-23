/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : TaskTrigger.cls  
 Script Type         : Standard Apex Trigger Class 
 Description         : Trigger actions on Task (Activity) records

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-04-24  Paul Coleman      Created
 1.1     2017-09-28  Mendel Guillaume  Refactored to support first response functionality
 =======+===========+=================+=================================*/
trigger TaskTrigger on Task (before insert, before update, after insert, after update, after delete)
{
	if(Trigger.isBefore)
	{
		if(Trigger.isInsert)
		{
			TaskTriggerHandler.onBeforeInsert(Trigger.new);
		}
		else if(Trigger.isUpdate)
		{
			TaskTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
		}
	}
	else if(Trigger.isAfter)
	{
		if(Trigger.isInsert)
		{
			TaskTriggerHandler.onAfterInsert(Trigger.newMap);
		}
	}

	/*//Before Insert/Update, if WhatId is Case, attempt to set WhoId to ContactId
	if( Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		Boolean targetLocated = false;
		//find any Triggered Tasks that have a Case as WhatId
		for(Task t: Trigger.New) {
			String wId = t.WhatId;
			if(wId != null && wId.startsWith('500')){
				targetLocated = true;
				break;
			}
		}
		if(targetLocated) {
			TaskTriggerHandler.setWhoIdFromCaseContact(Trigger.New);
		}
	}*/
}