/************************************************************************************
*                                                                                  *
*                                           ########                               *
*                                            #####                                 *
*   Copyright (c) 2016 Thumbtack             ###                                   *
*     All rights reserved.                  ###                                    *
*                                         #####                                    *
*                                      #########                                   *
*                                         #                                        *
*                                        #                                         *
*                                       #                                          *
*                                      #                                           *
*                                                                                  *
************************************************************************************

Change List:
------------
Version    Date     Author            Description
=======+===========+=================+=================================
1.0     2016-12-06  Scott Purcell     Created
=======+===========+=================+=================================*/
trigger RequestTrigger on Request__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    
    if(Trigger.isInsert && Trigger.isBefore){
        RequestTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    /*
    else if(Trigger.isInsert && Trigger.isAfter){
        RequestTriggerHandler.OnAfterInsert(Trigger.new);
    }*/
    // Before Update 
    if(Trigger.isUpdate && Trigger.isBefore){
        RequestTriggerHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.new);
    }
    /* 
    else if(Trigger.isUpdate && Trigger.isAfter){
        RequestTriggerHandler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }
    
    else if(Trigger.isDelete && Trigger.isBefore){
        RequestTriggerHandler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
   
    else if(Trigger.isDelete && Trigger.isAfter){
        RequestTriggerHandler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }*/
}