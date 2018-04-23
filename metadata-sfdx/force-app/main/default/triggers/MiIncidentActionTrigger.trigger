/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
******************************************************************************** 
https://thumbtack--dev.cs17.my.salesforce.com
  

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       06-02-2017     Scott Purcell          Created
========+============+=================+===============================================*/
trigger MiIncidentActionTrigger on MiIncidentAction__c (before insert,before update, after update, after insert,before delete) 
{

	if(Trigger.isInsert && Trigger.isBefore)
	{
		MiIncidentActionTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap);
		MiIncidentActionTriggerHandler.onBeforeInsertUpdate(Trigger.new,Trigger.newMap);
	}
	if(Trigger.isUpdate && Trigger.isBefore)
	{
		MiIncidentActionTriggerHandler.onBeforeInsertUpdate(Trigger.new,Trigger.newMap);
	}
	if(Trigger.isBefore && Trigger.isDelete)
	{
		system.debug('******************** In before delete trigger ********************');
		MiIncidentActionTriggerHandler.onBeforeDelete(Trigger.old);
	}

	if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert ))
	{
		system.debug('******************** In after update/insert trigger ********************');
		MiIncidentActionTriggerHandler.onAfterInsertUpdate(Trigger.new,Trigger.isInsert,Trigger.isUpdate);
	}
}