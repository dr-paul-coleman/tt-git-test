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
1.0     04-11-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
trigger SupportProcessTrigger on SupportProcess__c (before insert,before update) 
{

	if (Trigger.isBefore) 
	{
		if(Trigger.isInsert)
		{
			SupportProcessTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap);
		}
		//if(Trigger.isUpdate)
		//{
		//	for(SupportProcess__c sp:Trigger.new)
		//	{
		//		for(SupportProcess__c spo:Trigger.old)
		//		{
		//			//system.debug(sp.Name +', '+ spo.Name);
		//			if(sp.Name != spo.Name)sp.Name = spo.Name;
		//		}
		//	}
		//}
    	
    
	} 
}