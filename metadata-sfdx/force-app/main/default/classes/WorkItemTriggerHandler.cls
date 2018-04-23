/*
Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.   

Change List:                                                               
------------ 
Version      Date          Author            Description
========+============+=================+================================================
...previous versions in GIT
2.3       2018-03-02    Jared Kennington  Added new field to Quick Case creation 'OriginalQueue__c'
========+============+=================+===============================================
*/
public virtual class WorkItemTriggerHandler extends ThumbtackTriggerHandlerBase
{
    // Recursion Prevention Flags
    private static Boolean isInBeforeInsertProcessing = false;
    private static Boolean isInBeforeUpdateProcessing = false;
    private static Boolean isInAfterUpdateProcessing = false;
    private static Boolean preventMultiRunInSameContext = false;

    //variables needed throughout the code
    private static final Id concerningReviewRecordTypeId = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Concerning Review').getRecordTypeId();

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onBeforeInsert(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeInsertProcessing)
        {
            isInBeforeInsertProcessing = true;
            this.routeWorkItem(ctx.newRecords);
            this.syncAccounts(ctx.newRecords);
            isInBeforeInsertProcessing = false;
        }
    }

    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeUpdateProcessing)
        {
            isInBeforeUpdateProcessing = true;
            //NOTE: syncAccounts must process before manageReviewAudit
            this.manageReviewAudit( ctx.newRecords, this.syncAccounts(ctx.newRecords) );
            isInBeforeUpdateProcessing = false;
        }
    }

    public override void onAfterUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInAfterUpdateProcessing)
        {
            isInAfterUpdateProcessing = true;
            //preventing recursion within the same trigger context, something is firing this trigger multiple times
            //with the same trigger context which was creating multiple cases for one record change.
            if(!preventMultiRunInSameContext)
            {
                preventMultiRunInSameContext = true;
                checkOutcome((Map<Id, WorkItem__c>) ctx.newRecordsMap, (Map<Id, WorkItem__c>) ctx.oldRecordsMap);
            }
            isInAfterUpdateProcessing = false;
        }
    }

    //PRIVATE MEMBER FUNCTIONS

    private void routeWorkItem(List<WorkItem__c> triggerNew)
    {
        Map<String, WorkItemRouter__mdt> wirMap = new Map<String,WorkItemRouter__mdt>();
        Set<String> prosWithOpenMI = new Set<String>();
        Set<String> bidIds = new Set<String>();

        //get active WorkItemRouter's
        // note: WorkItem__c.Type__c is mapped to WorkItemRouter__c.MasterLabel
        for(WorkItemRouter__mdt wir : [SELECT MasterLabel, OwnerId__c, Priority__c, RecordtypeId__c, Status__c From WorkItemRouter__mdt WHERE IsActive__c = true]){wirMap.put(wir.MasterLabel, wir);}

        for (WorkItem__c workItem : triggerNew)
        {
            if(null != workItem.bid_bid_id__c){ bidIds.add(workItem.bid_bid_id__c.toPlainString()); }
        }

        //get open MI incident Bid id's to compare
        for (MIIncident__c mi : [SELECT bid_id__c FROM MIIncident__c WHERE Status__c != 'Closed' AND bid_id__c in :bidIds]){ prosWithOpenMI.add(mi.bid_id__c); }


        //If workitem type is in Router, set specified values
        for(workitem__c w : triggerNew)
        {
            WorkItemRouter__mdt workItemRouter = wirMap.get(w.Type__c);
            if(NULL != workItemRouter)
            {
                //if new record has a value, do not override these fields
                w.Status__c = (w.Status__c == NULL)? workItemRouter.Status__c : w.Status__c;
                w.Priority__c = (w.Priority__c == NULL)? workItemRouter.Priority__c : w.Priority__c;

                //override these fields
                w.RecordTypeId = workItemRouter.RecordtypeId__c;
                w.OwnerId = workItemRouter.OwnerId__c;
            }

            //if there is an open incident, auto complete the workitem
            if(w.RecordTypeId == concerningReviewRecordTypeId && null != w.bid_bid_id__c && prosWithOpenMI.contains(w.bid_bid_id__c.toPlainString()))
            {
                w.ReviewAudit__c = 'Open MTS Incident';
                w.Outcome__c = 'Related to an Open MTS Incident';
                w.Status__c = 'Completed';
            }
        }
    }

    /**
    * @author Jared Kennington
    * @date 2017-10-11
    * @description Used to Upsert accounts so we have the most up to date Account data for the given Work Items.
    * @param trigger array context
    */
    private Map<Decimal, Account> syncAccounts(List<WorkItem__c> triggerNew)
    {
        Id accountProRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accountCustomerRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Map<Decimal, Account> accountsMap = new Map<Decimal, Account>();
        Map<String, Account> accountEmailMap = new Map<String, Account>();
        Map<Decimal, WorkItem__c> workItemMap = new Map<Decimal, WorkItem__c>();
        Account[] newAccounts = new Account[0];

        //get userids to query Accounts
        for (WorkItem__c wi: triggerNew)
        {
            if ( NULL != wi.rev_usr_user_id_reviewed__c ) { // we are only creating missing Pro Accounts
                accountsMap.put( wi.rev_usr_user_id_reviewed__c, NULL);
                workItemMap.put( wi.rev_usr_user_id_reviewed__c, wi );
            }
        }

        System.debug(LoggingLevel.FINEST, 'WorkItemTriggerHandler.accountsMapAfterKeySet: ' + accountsMap.KeySet());
        for( Account accnt: [SELECT Id, usr_user_id__c, RecordTypeId, usr_email__c, (SELECT Id FROM Contacts) FROM Account WHERE usr_user_id__c IN: accountsMap.keySet()]  )
        {
            //capture accounts based of userId and email
            accountsMap.put( accnt.usr_user_id__c, accnt );
            if(String.isNotBlank(accnt.usr_email__c)){ accountEmailMap.put(accnt.usr_email__c, accnt); }
        }

        for( WorkItem__c wi : triggerNew )
        {
            //check for no Pro Account
            if( NULL != wi.rev_usr_user_id_reviewed__c )
            {
                Account existingProAccount = accountsMap.get( wi.rev_usr_user_id_reviewed__c );
                //if we can't find an account based off userId check for email
                if(null == existingProAccount && String.isNotBlank(wi.pro_email__c))
                {
                    existingProAccount = accountEmailMap.get(wi.pro_email__c);
                }
                //if both checks fail, create new one and sync
                if ( NULL == existingProAccount )
                {
                    if ( wi.pro_first_name__c != NULL && wi.pro_last_name__c != NULL )
                    {
                        Account newProAccount = new Account ( RecordTypeId = accountProRtId, Name = wi.pro_first_name__c + ' ' + wi.pro_last_name__c, usr_user_id__c = wi.rev_usr_user_id_reviewed__c, usr_first_name__c = wi.pro_first_name__c, usr_last_name__c = wi.pro_last_name__c, usr_email__c = wi.pro_email__c );
                        newAccounts.add( newProAccount );
                    }
                }
                else
                {
                    wi.ProAccount__c = existingProAccount.Id;
                }
            }
        }

        Id[] newAccountIds = new Id[0];
        for( Database.SaveResult sResult : Database.insert( newAccounts, false ) ) // succeed on as many inserts as possible
        {
            if( sResult.isSuccess() )
            {
                newAccountIds.add( sResult.getId() );
            }
            else
            {
                System.debug( LoggingLevel.ERROR, sResult.getErrors()[0].getMessage() );
                // TODO sendAdmin Email?
            }
        }

        // must replace the accountMap entries for new inserts with ones that include the related contact
        for( Account insertedAccount: [SELECT Id, usr_user_id__c, RecordTypeId, (SELECT Id FROM Contacts) FROM Account WHERE usr_user_id__c IN : accountsMap.keySet()]  )
        {
            accountsMap.put( insertedAccount.usr_user_id__c, insertedAccount );
            WorkItem__c matchingWorkItem = workItemMap.get( insertedAccount.usr_user_id__c );
            // set the newly inserted account ids back onto the matching triggered WorkItem record
            if ( NULL != matchingWorkItem )
            {
                matchingWorkItem.ProAccount__c = ( accountProRtId == insertedAccount.RecordTypeId ) ? insertedAccount.Id : matchingWorkItem.ProAccount__c;
            }
        }

        return accountsMap;
    }

    /**
    * @author Jared Kennington
    * @date 2017-10-11
    * @description Process customer CustomerSuccessGuidance__c and Cases
    */
    private void manageReviewAudit( List<WorkItem__c> triggerNew, Map<Decimal, Account> accountsMap )
    {
        WorkItemOutcome__mdt[] wioList = [SELECT Outcome__c, RecordtypeId__c, ReviewAudit__c, Status__c FROM WorkItemOutcome__mdt];
        for (WorkItem__c workItem : triggerNew)
        {
            //if name is NULL or missing last name, override
            if (NULL != workItem.customer_last_name__c && workItem.RecordTypeId == concerningReviewRecordTypeId && !workItem.Name.contains(workItem.customer_last_name__c))
            {
                workItem.name = (workItem.rev_rating__c + ' Star review from ' + workItem.customer_first_name__c + ' ' + workItem.customer_last_name__c + ' for ' + workItem.pro_first_name__c + ' ' + workItem.pro_last_name__c).left(78);
            }

            //check review audit against the custom metadata and update if needed
            for(WorkItemOutcome__mdt wio : wioList)
            {
                if (null != workItem.ReviewAudit__c && (null == workItem.Status__c || workItem.Status__c != 'Completed') && wio.RecordtypeId__c == workItem.RecordTypeId && wio.ReviewAudit__c == workItem.ReviewAudit__c)
                {
                    workItem.Outcome__c = wio.Outcome__c;
                    workItem.Status__c = wio.Status__c;
                }
            }
        }
    }

    /**
    * @author Jared Kennington
    * @date 2017-12-06
    * @description Used to check outcome to see if we need to create a quick case
    */
    private void checkOutcome(Map<Id, WorkItem__c> newRecordsMap, Map<Id, WorkItem__c> oldRecordsMap )
    {
        Map<Id, WorkItem__c[]> casesToCreate = new Map<Id, WorkItem__c[]>();
        List<QuickCaseSetting__mdt> quickCaseSettings = [SELECT Id, WorkItemReportOutcome__c, WorkItemType__c FROM QuickCaseSetting__mdt WHERE AssignedApp__c = 'WorkItem' AND IsActive__c = true];

        if(null != quickCaseSettings)
        {
            for (WorkItem__c wi : newRecordsMap.values())
            {
                WorkItem__c oldRecord = oldRecordsMap.get(wi.Id);
                String outcomeToCheck = wi.Type__c == 'In Product Fraud Report' ? wi.ReportOutcome__c : wi.Outcome__c;

                if(String.isNotBlank(outcomeToCheck))
                {
                    for(QuickCaseSetting__mdt qcs : quickCaseSettings)
                    {

                        if(qcs.WorkItemType__c == wi.Type__c && qcs.WorkItemReportOutcome__c == outcomeToCheck && (null == oldRecord.Outcome__c || oldRecord.ReportOutcome__c != wi.ReportOutcome__c))
                        {
                            if(!casesToCreate.containsKey(qcs.Id))
                            {
                                casesToCreate.put(qcs.Id, new WorkItem__c[0]);
                            }

                            casesToCreate.get(qcs.Id).add(wi);
                        }
                    }
                }
            }

            System.debug(LoggingLevel.INFO, 'Creating Cases: '+casesToCreate.size());
            if(!casesToCreate.isEmpty())
            {
                for(Id key : casesToCreate.keySet())
                {
                    this.createCases(casesToCreate.get(key), key);
                }
            }
        }
    }

    /**
    * @author Jared Kennington
    * @date 2017-12-06
    * @description Used to create cases based off the given quick case setting
    */
    private void createCases(List<WorkItem__c> workItemList, Id quickCaseSettingId)
    {
        if(null != quickCaseSettingId && null != workItemList && workItemList.size() > 0)
        {
            Case[] casesToInsert = new Case[0];
            Map<Id, String> feedStrings = new Map<Id, String>();
            UtilityQuickCaseSetting uqcs = null;

            try
            {
                for(WorkItem__c wi : workItemList)
                {
                    uqcs = UtilityQuickCaseSetting.getQuickCaseSetting(wi.Id, quickCaseSettingId, WorkItem__c.getSobjectType());

                    //setup case values and replace merge fields with actual data
                    Case quickCase = new Case(RecordTypeId = uqcs.setting.RecordTypeId__c,
                            OwnerId = uqcs.replaceMergeField(uqcs.setting.OwnerId__c),
                            Team__c = uqcs.setting.Team__c,
                            Origin = uqcs.setting.Origin__c,
                            Status = uqcs.setting.Status__c,
                            ManualCaseCreation__c = uqcs.setting.ManualCaseCreation__c,
                            Subject = uqcs.replaceMergeField(uqcs.setting.Subject__c),
                            SuppliedEmail = uqcs.replaceMergeField(uqcs.setting.SuppliedEmail__c),
                            Category__c = uqcs.setting.Category__c,
                            SubCategory__c = uqcs.setting.Subcategory__c,
                            ContactId = uqcs.replaceMergeField(uqcs.setting.ContactId__c),
                            Description = uqcs.replaceMergeField(uqcs.setting.Description__c),
                            OriginalQueue__c = uqcs.setting.OriginalQueue__c,
                            WorkItemId__c = wi.Id,
                            WorkItemReviewAudit__c = wi.ReviewAudit__c);

                            //capture string intended for a CaseFeed entry
                            if(!feedStrings.containsKey(wi.Id) && String.isNotBlank(uqcs.setting.FeedPost__c)){ feedStrings.put(wi.Id, uqcs.replaceMergeField(uqcs.setting.FeedPost__c)); }

                    casesToInsert.add(quickCase);
                }

                if(!casesToInsert.isEmpty())
                {
                    insert casesToInsert;

                    List<FeedItem> feedItemsToInsert = new List<FeedItem>();
                    for(Case c : casesToInsert)
                    {
                        if(feedStrings.containsKey(c.WorkItemId__c))
                        {
                            feedItemsToInsert.add(new FeedItem(
                                    ParentId = c.Id,
                                    Title = 'Auto Created',
                                    Body = feedStrings.get(c.WorkItemId__c),
                                    Type = 'TextPost'));
                        }
                    }

                    if(!feedItemsToInsert.isEmpty())
                    {
                        DMLQueueable dmlQueue = new DMLQueueable(feedItemsToInsert, DMLQueueable.Operation.INSERTS);
                        if (System.isQueueable()){ System.enqueueJob(dmlQueue); } else{ dmlQueue.execute(NULL); }
                    }
                }

            }
            catch (Exception ex)
            {
                System.debug(LoggingLevel.Error, ex.getMessage() + ' - ' + ex.getStackTraceString());
            }
        }
    }
}