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
========+============+=================+=========================================
1.0       2016-12-11     Scott Purcell         Moved to TriggerHandler
========+============+=================+=========================================*/
trigger WiseptWisePredictionTrigger on wisespt__WisePrediction__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    

    // Before Insert 
    /*if(Trigger.isInsert && Trigger.isBefore){
        WiseptWisePredictionTriggerHandler.OnBeforeInsert(Trigger.new);
    }*/
    // After Insert 
    if(Trigger.isInsert && Trigger.isAfter){
        WiseptWisePredictionTriggerHandler.OnAfterInsertUpdate(Trigger.new);
    }
    // Before Update 
    /*else if(Trigger.isUpdate && Trigger.isBefore){
        WiseptWisePredictionTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }*/
    // After Update 
    else if(Trigger.isUpdate && Trigger.isAfter){
        WiseptWisePredictionTriggerHandler.OnAfterInsertUpdate(Trigger.new);
    }
    // Before Delete 
    /*
    else if(Trigger.isDelete && Trigger.isBefore){
        WiseptWisePredictionTriggerHandler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }*/
    // After Delete 
    /*else if(Trigger.isDelete && Trigger.isAfter){
        WiseptWisePredictionTriggerHandler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }*/

    // After Undelete 
    /*
    else if(Trigger.isUnDelete){
        WiseptWisePredictionTriggerHandler.OnUndelete(Trigger.new);
    }*/
      
}