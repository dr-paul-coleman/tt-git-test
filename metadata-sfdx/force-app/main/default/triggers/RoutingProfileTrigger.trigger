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
1.0     01-13-2017  Scott Purcell      Created
1.1     03-23-2017  Scott Purcell		Added after update
=======+===========+=================+================================================
*/
trigger RoutingProfileTrigger on RoutingProfile__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{

		if (Trigger.isBefore) 
		{
	    	//call your handler.before method
	    	if(Trigger.isUpdate)
	    	{
	    		RoutingProfileTriggerHandler.BeforeUpdate(Trigger.new,Trigger.Old,Trigger.oldMap);
	    	}
		} 
		else if (Trigger.isAfter) 
		{
	    	//call handler.after method
	    	if(Trigger.isUpdate)
	    	{
	    		RoutingProfileTriggerHandler.AfterUpdate(Trigger.new);
	    	}
		}
}