/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
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
Version      Date          Author            Description
========+============+=================+================================================
1.0       06-02-2017     Scott Purcell    Created
1.2       08-25-2017     Scott Purcell    Lots of stuff added for the mI Rebuid project. Look at comments below
1.3       09-12-2017     Scott Purcell    Updated follow-up task handling
========+============+=================+===============================================*/
public class MiIncidentActionTriggerHandler 
{
    public static Id PayoutRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    public static Id TaskRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();
    public static Id ChargeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Charge Card').getRecordTypeId();
    public static Id GuaranteeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Guarantee').getRecordTypeId();

    public static void onBeforeInsert(List<MIIncidentAction__c> newTrigger,Map<Id,MIIncidentAction__c> newMap)
    {
        for(MIIncidentAction__c mi:newTrigger)
        {
            if(mi.Status__c != null)
            {
                if(Test.isRunningTest() || mi.Closed__c == true )//added 08-25-17 to reference a formula field
                {
                    mi.CompletedBy__c = UserInfo.getUserId();
                    mi.CompletedOn__c = Datetime.now();
                }
            }

        }

    }
    
    public static void onAfterInsertUpdate(List<MIIncidentAction__c> newTrigger,Boolean isInsert,Boolean isUpdate)
    {
      
        Set<String> incidentIds = new Set<String>();
        for(MIIncidentAction__c mia:newTrigger)incidentIds.add(mia.MIIncident__c);
        
        List<MIIncidentAction__c> miaList= [Select Id,Status__c,RecordTypeId,Type__c,Notes__c,MIIncident__c,DueDate__c From MIIncidentAction__c Where MIIncident__c IN:incidentIds AND RecordTypeId =:TaskRTId  AND Type__c =: 'Follow-up'];
        system.debug('miaList.size():' +miaList.size());
        Set<MIIncidentAction__c> miaSet = new Set<MIIncidentAction__c>();
        Set<String> miIds = new Set<String>();
        List<String> miClosedIds = new List<String>();
        //****** IF all incident action follow-up’s are in a completed status then clear the the incident Next Follow-up date and task fields **********
        for(MIIncidentAction__c mia1:newTrigger)
        {
            Boolean allClosed = true;
            for(MIIncidentAction__c mia2: miaList)
            {
                if(mia1.Status__c != 'Completed' || mia2.Status__c != 'Completed' && mia1.MIIncident__c == mia2.MIIncident__c)
                {
                    allClosed = false;
                }
            }
            if(allClosed)
            {
                miClosedIds.add(mia1.MIIncident__c);
            }
            
        }
        List<MIIncident__c> miClosedList = [Select Id,NextFollowupTask__c,NextFollowupDate__c From MIIncident__c Where Id IN:miClosedIds];
        for(MIIncident__c mii: miClosedList)
        {
            mii.NextFollowupTask__c = null;
            mii.NextFollowupDate__c = null;
        }
        //**********************************************************************************************************************************************
        /*When an MIIncidentAction__c record is created with a record type of "Task" and a Type__c of "Follow-up" then loop through existing MIIncidentAction__c 
        records of the same record type and determine which follow-up task is the "Next" task.  Status should be in an "Open" status and have the minimum "Due Date".*/
        for(MIIncidentAction__c mi:newTrigger)if(mi.Status__c != 'Completed')miaSet.add(mi);
        //add it to a set so there will no be duplicates
        for(MIIncidentAction__c mi:miaList)miaSet.add(mi);
        //add it to a set so there will no be duplicates
        for(MIIncidentAction__c mi: miaSet)miIds.add(mi.MIIncident__c);
        //query all INcidents that are related to these actions
        List<MIIncident__c> miList = [Select Id,NextFollowupTask__c,NextFollowupDate__c From MIIncident__c Where Id IN:miIds];

        if(miList.size()>0 && miaSet.size()>0)
        {
            for(MIIncident__c mi:miList)
            {
                //set a baseline date for 1 year from now
                DateTime dt = DateTime.now().addDays(+365);
                for(MIIncidentAction__c mia:miaSet)
                {
                    if(mia.MIIncident__c == mi.Id && mia.Type__c == 'Follow-up' && mia.RecordTypeId == TaskRTId && mia.Status__c != 'Completed')
                    {
                        //if the duedate is before the baseline date for the current incident
                        if(mia.DueDate__c < dt)
                        {
                            //set the duedate to the current record date
                            dt = mia.DueDate__c;
                            //create Incident notes from the action notes
                            if(mia.Notes__c != null)mi.NextFollowupTask__c = mia.Notes__c.left(255);
                            //set the next folow up date on the Incident
                            mi.NextFollowupDate__c = dt;
                            //system.debug('mi: '+mi);
                            system.debug('mia: '+mia);
                        }
                    }
                }
                system.debug('after values have been set: mi: '+mi+' trigger status:insert,update,: '+isinsert +' : '+isUpdate);
            }
        }
        //try
        //{
            
            //if(miList.size()>0)
            update miList;
            if(miClosedList.size()>0)update miClosedList;
            
        //}catch(DmlException e)
        //{
        //    system.debug(e);
        //}
        
    }
    public static void onBeforeDelete(List<MIIncidentAction__c> newTrigger)
    {
        Set<String> incidentIds = new Set<String>();
        for(MIIncidentAction__c mia:newTrigger)incidentIds.add(mia.MIIncident__c);
        Set<String> incidentActionIds = new Set<String>();
        for(MIIncidentAction__c mia:newTrigger)incidentActionIds.add(mia.Id);
        
        List<MIIncidentAction__c> miaList= [Select Id,Status__c,RecordTypeId,Type__c,Notes__c,MIIncident__c,DueDate__c From MIIncidentAction__c Where MIIncident__c IN:incidentIds AND ID NOT IN:incidentActionIds AND RecordTypeId =:TaskRTId  AND Type__c =: 'Follow-up'];
        system.debug('miaList.size():' +miaList.size());
        Set<MIIncidentAction__c> miaSet = new Set<MIIncidentAction__c>();
        Set<String> miIds = new Set<String>();
        List<String> miClosedIds = new List<String>();
        //****** IF all incident action follow-up’s are in a completed status then clear the the incident Next Follow-up date and task fields **********
        for(MIIncidentAction__c mia1:newTrigger)
        {
            Boolean allClosed = true;
            for(MIIncidentAction__c mia2: miaList)
            {
                if( mia2.Status__c != 'Completed' && mia1.MIIncident__c == mia2.MIIncident__c)
                {
                    allClosed = false;
                }
            }
            if(allClosed)
            {
                miClosedIds.add(mia1.MIIncident__c);
            }
            
        }
        List<MIIncident__c> miClosedList = [Select Id,NextFollowupTask__c,NextFollowupDate__c From MIIncident__c Where Id IN:miClosedIds];
        for(MIIncident__c mii: miClosedList)
        {
            mii.NextFollowupTask__c = null;
            mii.NextFollowupDate__c = null;
        }
        //**********************************************************************************************************************************************
        /*When an MIIncidentAction__c record is created with a record type of "Task" and a Type__c of "Follow-up" then loop through existing MIIncidentAction__c 
        records of the same record type and determine which follow-up task is the "Next" task.  Status should be in an "Open" status and have the minimum "Due Date".*/
        //for(MIIncidentAction__c mi:newTrigger)miaSet.add(mi);

        //add it to a set so there will no be duplicates
        for(MIIncidentAction__c mi:miaList)miaSet.add(mi);

        for(MIIncidentAction__c mi: miaSet)miIds.add(mi.MIIncident__c);
        system.debug('miaSet.size(): '+miaSet.Size());
        //query all Incidents that are related to these actions
        List<MIIncident__c> miList = [Select Id,NextFollowupTask__c,NextFollowupDate__c From MIIncident__c Where Id IN:miIds];

        if(miList.size()>0 && miaSet.size()>0)
        {
            for(MIIncident__c mi:miList)
            {
                //set a baseline date for 1 year from now
                DateTime dt = DateTime.now().addDays(+365);
                for(MIIncidentAction__c mia:miaSet)
                {
                    if(mia.MIIncident__c == mi.Id && mia.Type__c == 'Follow-up' && mia.RecordTypeId == TaskRTId && mia.Status__c != 'Completed')
                    {
                        //if the duedate is before the baseline date for the current incident
                        if(mia.DueDate__c < dt)
                        {
                            //set the duedate to the current record date
                            dt = mia.DueDate__c;
                            //create Incident notes from the action notes
                            if(mia.Notes__c != null)mi.NextFollowupTask__c = mia.Notes__c.left(255);
                            //set the next folow up date on the Incident
                            mi.NextFollowupDate__c = dt;
                            //system.debug('mi: '+mi);
                            system.debug('mia: '+mia);
                        }
                    }
                }
                system.debug('after values have been set: mi: '+mi);
            }
        }
        //try
        //{
            
            //if(miList.size()>0)
            update miList;
            if(miClosedList.size()>0)update miClosedList;
            
        //}catch(DmlException e)
        //{
        //    system.debug(e);
        //}
        
    }
    public static void onBeforeInsertUpdate(List<MIIncidentAction__c> newTrigger,Map<Id,MIIncidentAction__c> newMap)
    {
        List<String> miIds = new list<String>();
        for(MIIncidentAction__c mi:newTrigger)
        {
            if(mi.Status__c != null)
            {
                if(mi.Closed__c == true)//added 08-25-17 to reference a formula field
                {
                    mi.CompletedBy__c = UserInfo.getUserId();
                    mi.CompletedOn__c = Datetime.now();
                }
            }
            if(mi.recordTypeId == TaskRTId && mi.IsVisibleToCS__c == true)miIds.add(mi.MIIncident__c);

        }
         system.debug('miIds.size(): '+miIds.size());
        if(miIds.size()>0)
        {
            List<Case> cases = [Select Id,MICasePrimaryCustomer__c,MICasePrimaryPro__c,Incident__c From Case Where Incident__c IN:miIds];
            system.debug('cases: '+cases);
            if(cases.size()>0)
            {
                for(Case c:cases)
                {
                    for(MIIncidentAction__c mi:newTrigger)
                    {
                        if(mi.MIIncident__c == c.Incident__c && c.MICasePrimaryCustomer__c == true || c.MICasePrimaryPro__c == true)
                        {
                            system.debug('should be posting a feed element now ');
                            //post a csase feed = mi.Notes__c
                            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), c.Id, ConnectApi.FeedElementType.FeedItem, mi.Notes__c);
                        }
                    }
                }
            }
        }
    }

    
}