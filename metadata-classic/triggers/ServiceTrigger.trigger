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
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     2016-12-13  Scott Purcell             Created
=======+===========+=================+===============================================*/
trigger ServiceTrigger on Service__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{

    

    // Before Insert 
    if(Trigger.isInsert && Trigger.isBefore)
    {
        ServiceTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    // After Insert 
    /*else if(Trigger.isInsert && Trigger.isAfter)
    {
        ServiceTriggerHandler.OnAfterInsert(Trigger.new);
    }*/
    // Before Update 
    else if(Trigger.isUpdate && Trigger.isBefore)
    {
        ServiceTriggerHandler.OnBeforeUpdate(Trigger.new,Trigger.old,Trigger.newMap,Trigger.oldMap);
    }
    // After Update 
    /*else if(Trigger.isUpdate && Trigger.isAfter)
    {
        ServiceTriggerHandler.OnAfterUpdate(Trigger.new,Trigger.old,Trigger.newMap);
    }*/
    // Before Delete 
    /*else if(Trigger.isDelete && Trigger.isBefore)
    {
        ServiceTriggerHandler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }*/
    // After Delete 
    /*else if(Trigger.isDelete && Trigger.isAfter)
    {
        ServiceTriggerHandler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }*/

    // After Undelete 
    /*else if(Trigger.isUnDelete){
        ServiceTriggerHandler.OnUndelete(Trigger.new);
    }*/
}