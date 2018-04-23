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
      
 Script File Name    : EmailFilterTrigger.cls  
 Script Type         : Standard Apex Trigger Class 
 Description         : Tests Regex on the filter records

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-04-15  Paul Coleman       Created 
 1.1     2016-12-12  Scott Purcell		Moved to Trigger Handler
 =======+===========+=================+=================================*/
 trigger EmailFilterTrigger on EmailFilter__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
 {

    

    // Before Insert 
    if(Trigger.isInsert && Trigger.isBefore)
    {
        EmailFilterTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    // After Insert 
    /*else if(Trigger.isInsert && Trigger.isAfter)
    {
        EmailFilterTriggerHandler.OnAfterInsert(Trigger.new);
    }*/
    // Before Update 
    else if(Trigger.isUpdate && Trigger.isBefore)
    {
        EmailFilterTriggerHandler.OnBeforeUpdate(Trigger.new,Trigger.old,Trigger.newMap);
    }
    // After Update 
   /* else if(Trigger.isUpdate && Trigger.isAfter)
    {
        EmailFilterTriggerHandler.OnAfterUpdate(Trigger.new,Trigger.old,Trigger.newMap);
    }*/
    // Before Delete 
    /*else if(Trigger.isDelete && Trigger.isBefore)
    {
        EmailFilterTriggerHandler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }*/
    // After Delete 
    /*else if(Trigger.isDelete && Trigger.isAfter)
    {
        EmailFilterTriggerHandler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }*/

    /* After Undelete */
    /*else if(Trigger.isUnDelete)
    {
        EmailFilterTriggerHandler.OnUndelete(Trigger.new);
    }*/

}