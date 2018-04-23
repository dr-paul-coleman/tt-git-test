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
1.0       2016-12-12     Scott Purcell       Moved from Trigger
========+============+=================+=========================================*/
public with sharing class EmailFilterTriggerHandler 
{

	public static void OnBeforeInsert(List<EmailFilter__c> newObjects)
	{
        for(EmailFilter__c filter: newObjects) 
        {
			if(null!=filter.Regex__c && !''.equals(filter.Regex__c.trim())) 
			{
				Pattern.compile(filter.Regex__c);
			}
		}
    }

   /* public static void OnAfterInsert(List<EmailFilter__c> newObjects)
    {
        // EXECUTE AFTER INSERT LOGIC
    }*/

    public static void OnBeforeUpdate(List<EmailFilter__c> updatedObjects, List<EmailFilter__c> oldObjects, Map<Id,EmailFilter__c> newMap)
	{
        for(EmailFilter__c filter: updatedObjects) 
        {
			if(null!=filter.Regex__c && !''.equals(filter.Regex__c.trim())) 
			{
				Pattern.compile(filter.Regex__c);
			}
		}
    }

   /* public static void OnAfterUpdate(List<EmailFilter__c> updatedObjects, List<EmailFilter__c> oldObjects, Map<Id,EmailFilter__c> newMap,Map<Id,EmailFilter__c> oldMap)
	{
        // AFTER UPDATE LOGIC
    }*/

   /* public static void OnBeforeDelete(List<EmailFilter__c> ObjectsToDelete, Map<Id,EmailFilter__c> newMap)
    {
        // BEFORE DELETE LOGIC
    }*/

    /*public static void OnAfterDelete(List<EmailFilter__c> deletedObjects, Map<Id,EmailFilter__c> newMap)
    {
        // AFTER DELETE LOGIC
    }*/

    /*public void OnUndelete(EmailFilter__c[] restoredObjects)
    {
        // AFTER UNDELETE LOGIC
    }*/
}