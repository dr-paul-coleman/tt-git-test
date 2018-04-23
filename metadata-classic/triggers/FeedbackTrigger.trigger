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
Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     06-01-2017  Scott Purcell      Created
=======+===========+=================+================================================*/
trigger FeedbackTrigger on ProductFeedback__c (
	before insert, 
	before update,  
	after insert, 
	after update) {

		if (Trigger.isBefore) {
	    	//call your handler.before method
	    	//if(Trigger.isInsert)FeedbackTriggerHandler.isBeforeInsert(Trigger.new,Trigger.newMap);
	    	//if(Trigger.isUpdate)FeedbackTriggerHandler.isBeforeUpdate(Trigger.new,Trigger.old,Trigger.newMap,Trigger.oldMap);
	    
		} else if (Trigger.isAfter) {
	    	//call handler.after method
	    	//FeedbackTriggerHandler.isAfterUpdate(Trigger.new,Trigger.old,Trigger.newMap,Trigger.oldMap);
	    	if(Trigger.isInsert)FeedbackTriggerHandler.isAfterInsert(Trigger.new,Trigger.newMap);
	    
		}
}