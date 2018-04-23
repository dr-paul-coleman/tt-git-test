/*
Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.

Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     01-13-2017  Scott Purcell      Created-to replace bug Process builder
2.0     11-06-2017  Jared Kennington   Updated to new Trigger structure & added "DateFixed" functionality
=======+===========+=================+================================================
*/
public class BugTriggerHandler extends ThumbtackTriggerHandlerBase
{
    // Recursion Prevention Flags
    private static Boolean isInBeforeUpdateProcessing = false;
    private static Boolean isInAfterInsertProcessing = false;

    //Supporting Variables
    sObject[] recordsToUpdate = new sObject[0];

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onAfterInsert(ThumbtackTriggerContext ctx)
    {
        if(!isInAfterInsertProcessing)
        {
            isInAfterInsertProcessing = true;
            createJiraIssues((Bug__c[]) ctx.newRecords);
            dateFixedCheck((Map<Id, Bug__c>)ctx.newRecordsMap);
            isInAfterInsertProcessing = false;
        }
        else
        {
            this.doRecursiveProcessing(ctx);
        }

    }

    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeUpdateProcessing)
        {
            isInBeforeUpdateProcessing = true;
            updateJiraIssues((Bug__c[]) ctx.newRecords);
            dateFixedCheck((Map<Id, Bug__c>)ctx.newRecordsMap);
            isInBeforeUpdateProcessing = false;
        }
    }


    //Helper Methods
    private void createJiraIssues(Bug__c[] bugs)
    {
        List<String> bugIds = new List<String>();

        for(Bug__c bug:bugs)
        {
            if(bug.Approved__c == true && bug.TackLabels__c == null){ bugIds.add(bug.Id); }
        }

        if(bugIds.size()>0){ JiraCallout.handler(bugIds,true); }//create issue in jira
    }

    private void updateJiraIssues(Bug__c[] bugs)
    {
        List<String> bugIds = new List<String>();
        List<String> bugIdsUpdate = new List<String>();

        for(Bug__c bug:bugs)
        {
            if(true == bug.Approved__c && null == bug.JiraId__c && null == bug.TackLabels__c && null == bug.IssueSentToJiraStatus__c && false == bug.IssueCreated__c)
            {
                bugIds.add(bug.Id);
                bug.IssueSentToJiraStatus__c = 'Issue Sent To JIRA';
                bug.IssueCreated__c = true;
            }
        }

        if(bugIds.size()>0){ JiraCallout.handler(bugIds,true); }//create issue in jira
    }

    private void dateFixedCheck(Map<Id, Bug__c> triggerMap)
    {
        for (SupportProcess__c process : [SELECT Bug__c, DateBugFixed__c FROM SupportProcess__c WHERE DateBugFixed__c = null AND Bug__c IN :triggerMap.keySet()])
        {
            Bug__c bug = triggerMap.get(process.Bug__c);

            //for each support process, if DateFixed doesn't match update it
            if(null != bug && bug.Id == process.Bug__c && null != bug.DateFixed__c && null == process.DateBugFixed__c)
            {
                process.DateBugFixed__c = bug.DateFixed__c;
                recordsToUpdate.add(process);
            }
        }

        if(!recordsToUpdate.isEmpty())
        {
            if(Limits.getQueueableJobs()<=1){System.enqueueJob( new DMLQueueable(recordsToUpdate, DMLQueueable.Operation.UPDATES) );}
            else{new DMLQueueable(recordsToUpdate, DMLQueueable.Operation.UPDATES).execute(null);}
        }
    }
}