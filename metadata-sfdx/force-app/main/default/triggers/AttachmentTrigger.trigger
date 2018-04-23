trigger AttachmentTrigger on Attachment (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
	if (Trigger.isBefore)
	{
        if(Trigger.isUpdate)
        {
            AttachmentTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
	}
	else if(Trigger.isAfter)
	{
		if(Trigger.isInsert)
		{
			AttachmentTriggerHandler.onAfterInsert(Trigger.newMap);
		}
		else if(Trigger.isUpdate)
		{
			AttachmentTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
		}
	}
}