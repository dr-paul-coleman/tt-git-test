/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/11/17      jkennington          Created
========+============+=================+===============================================*/
@RestResource(urlMapping='/V1/WorkItem/*')
global with sharing class RESTWorkItemController
{
    @HttpPost
    global static void doPost(WorkItem__c workItem)
    {
        try
        {
            for (WorkItem__c wi : [SELECT Id, RecordTypeId, Status__c FROM WorkItem__c WHERE CreatedDate > :Date.today().addDays(-7) AND usr_user_id__c = :workItem.usr_user_id__c])
            {
                if(wi.RecordTypeId == workItem.RecordTypeId)
                {
                    System.debug('***** setId');
                    workItem.Id = wi.Id;
                }
            }

            upsert workItem;
        }
        catch(DMLException e)
        {
            System.debug(LoggingLevel.ERROR, e);
        }
    }
}