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
1.0     04-12-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
trigger BackgroundCheckTrigger on BackgroundCheck__c (before insert, before update, after insert, after update) 
{

		if (Trigger.isBefore) 
		{
			if (Trigger.isInsert)
			{
				BackgroundCheckTriggerHandler.beforeInsert(Trigger.new);
			}
			if (Trigger.isUpdate)
			{
				BackgroundCheckTriggerHandler.beforeUpdate(Trigger.new,Trigger.old);
			}
	    	
	    
		}
}