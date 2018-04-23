/*
Copyright (c) [2015 -] 2018 Thumbtack. All rights reserved.

Version    Date     Author            Description
=======+===========+=================+=================================
1.0     2016-06-28  Paul Coleman      Created
1.1     2016-07-10  Paul Coleman      Modifed for new MI Trigger Rules and WF replacements
1.2     2017-08-25  Scott Purcell     Lots of stuff added for the mI Rebuid project. Look at comments below
1.3     2017-09-14  Scott Purcell     Added conRecordTypeId to logic
1.4     2017-09-29  Mendel Guillaume  Added first review task action and added additional queue variables
2.0     2017-10-17  Paul Coleman      Refactored for Trigger Framework and new Becky sync utilities
2.1     2017-12-08  Mendel Guillaume  Clear flags on closed and set related incident action tasks as completed
2.2     2018-01-07  Kristin Hasna     Added 'Marketplace Integrity Restricted' record type
2.3     2018-02-15  Mendel Guillaume  Modified to update related records when RT changes to 'Confidential'
=======+===========+=================+=================================*/
public without sharing class MiIncidentTriggerHandler extends ThumbtackTriggerHandlerBase
{

    //get target Record Type Ids for Mi filtering
    public static final Id MI_CASE_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
    public static final Id CSAT_RECORD_TYPE_ID = CSAT__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity CSAT').getRecordTypeId();
    public static final Id MI_RECORD_TYPE_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    public static final Id CONFIDENTIAL_RECORD_TYPE_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
    public static final Id RESTRICTED_RECORD_TYPE_ID = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity Restricted').getRecordTypeId();
    public static final Set<Id> TARGET_RECORD_TYPE_IDS = new Set<Id> {MI_RECORD_TYPE_ID, CONFIDENTIAL_RECORD_TYPE_ID, RESTRICTED_RECORD_TYPE_ID};
    //get target Queue Ids for OwnerId comparisons
    public static final Map<Id,Group> TARGET_QUEUE_IDS = new Map<Id,Group>([SELECT Id FROM Group WHERE Type = 'Queue' AND Name IN ('Marketplace Integrity', 'Proactive MI Queue', 'Low Dollar Satisfaction Queue', 'Guarantee Queue') LIMIT 4] );

    private static Boolean isInAfterInsertProcessing = false;
    private static Boolean isInBeforeInsertProcessing = false;
    private static Boolean isInBeforeUpdateProcessing = false;
    private static Boolean isInAfterDeleteProcessing = false;
    private static Boolean isInAfterUpdateProcessing = false;

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onBeforeInsert(ThumbtackTriggerContext ctx)
    {
        if (!isInBeforeInsertProcessing)
        {
            MIIncident__c[] triggerNew = (MIIncident__c[]) ctx.newRecords;
            if( Test.isRunningTest() ) { System.debug(LoggingLevel.FINEST, 'MTS RECORDS BEFORE INSERTED: ' + JSON.serialize(triggerNew)); }
            isInBeforeInsertProcessing = true;
            try
            {
                Datetime now = Datetime.now();
                // Ensure OwnerAssignedDate__c is set on insert, in support of work flow rules
                for( MIIncident__c mi : triggerNew ) {
                    mi.OwnerAssignedDate__c = now;
                }
            }
            finally
            {
                isInBeforeInsertProcessing = false;
            }
        }
    }

    public override void onAfterInsert(ThumbtackTriggerContext ctx)
    {
        if (!isInAfterInsertProcessing)
        {
            MIIncident__c[] triggerNew = (MIIncident__c[]) ctx.newRecords;
            if( Test.isRunningTest() ) { System.debug(LoggingLevel.FINEST, 'MTS RECORDS AFTER INSERTED: ' + JSON.serialize(triggerNew)); }
            isInAfterInsertProcessing = true;
            try
            {
                this.doBeckySync(triggerNew, false, NULL);
                this.insertUpdateHistories(triggerNew, false, NULL);
                this.syncAccountOpenIncidentFlag(triggerNew, NULL);
            }
            finally
            {
                isInAfterInsertProcessing = false;
            }
        }
    }

    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        if (!isInBeforeUpdateProcessing)
        {
            isInBeforeUpdateProcessing = true;
            MIIncident__c[] triggerNew = (MIIncident__c[]) ctx.newRecords;
            Map<Id, MIIncident__c> triggerNewMap = (Map<Id, MIIncident__c>) ctx.newRecordsMap;
            Map<Id, MIIncident__c> triggerOldMap = (Map<Id, MIIncident__c>) ctx.oldRecordsMap;
            try
            {
                this.doMiBeforeUpdateRules(triggerNew, triggerOldMap, triggerNewMap);
            }
            finally
            {
                isInBeforeUpdateProcessing = false;
            }
        }
    }

    public override void onAfterUpdate(ThumbtackTriggerContext ctx)
    {
        if (!isInAfterUpdateProcessing)
        {
            isInAfterUpdateProcessing = true;
            MIIncident__c[] triggerNew = (MIIncident__c[]) ctx.newRecords;
            Map<Id, MIIncident__c> triggerOldMap = (Map<Id, MIIncident__c>) ctx.oldRecordsMap;
            try
            {
                this.createHistoriesAndMIIncidentActions(triggerNew, triggerOldMap);
                this.syncAccountOpenIncidentFlag(triggerNew, triggerOldMap);
                this.doBeckySync(triggerNew, true, triggerOldMap);
                this.completeRelatedTasks(triggerNew, triggerOldMap);
                this.updateRelatedRecordsToConfidential(triggerNew, triggerOldMap);
            }
            finally
            {
                isInAfterUpdateProcessing = false;
            }
        }
    }

    public override void onAfterDelete(ThumbtackTriggerContext ctx)
    {
        if (!isInAfterDeleteProcessing)
        {
            isInAfterDeleteProcessing = true;
            try
            {
                this.syncAccountOpenIncidentFlag((MIIncident__c[]) ctx.oldRecords, NULL);
            }
            finally
            {
                isInAfterDeleteProcessing = false;
            }
        }
    }


    //PRIVATE MEMBER FUNCTIONS
    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Ensure data synchronization between local records and external objects.
    * @param MIIncident__c[] The trigger New array.
    * @param Boolean A flag indicating if this is an TRIGGER UPDATE event vs INSERT. Normally the bid id should be set during insert.
    * @param  Map<Id,MIIncident__c> The trigger OLD Map, to comp bid ids after update.
    */
    private void doBeckySync(MIIncident__c[] incidents, Boolean isUpdate, Map<Id, MIIncident__c> triggerOldMap)
    {
        MIIncident__c[] incidentsNeedingSync = new MIIncident__c[0];
        for (MIIncident__c incident : incidents)
        {
            MIIncident__c oldIncident = isUpdate ? triggerOldMap.get(incident.Id) : new MIIncident__c();
            if ( NULL == incident.ExternalQuoteData__c && NULL != incident.bid_id__c )
            {
                // only sync after update if this is the transition that sets the bid id to non-NULL (RULES defined by Drew on Oct 17 '17)
                if ( isUpdate && NULL != oldIncident && NULL == oldIncident.bid_id__c )
                {
                    incidentsNeedingSync.add(incident); //only do becky syn after update when bid id was just added to the record
                }
                else if ( !isUpdate )
                {
                    incidentsNeedingSync.add(incident);
                }
            }
        }

        try
        {
            if ( !incidentsNeedingSync.isEmpty() )
            {
                if ( BecquerelUtility.IS_TEST_RUN ) { System.debug(LoggingLevel.INFO, 'INCIDENTS NEEDING SYNC: '+ JSON.serialize( incidentsNeedingSync) ); }
                BeckyMTSIncidentSyncQueueable beckySyncJob = new BeckyMTSIncidentSyncQueueable( incidentsNeedingSync );
                if ( System.isQueueable() ) { beckySyncJob.execute(NULL); } else { System.enqueueJob( beckySyncJob ); }
            } else {
                if ( BecquerelUtility.IS_TEST_RUN ) { System.debug(LoggingLevel.WARN, 'NO INCIDENTS TO SYNC'); }
            }
        }
        catch (Exception mxSyncException) { System.debug(LoggingLevel.ERROR, mxSyncException); }

    } // END doBeckySync


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Ensure sync local records with external objects.
    * @param MIIncident__c[] the trigger New array.
    * @param  Map<Id,MIIncident__c> the trigger OLD Map.
    * @param  Map<Id,MIIncident__c> the trigger New Map.
    */
    private void doMiBeforeUpdateRules(List<MIIncident__c> triggerNew, Map<Id, MIIncident__c> triggerOldMap, Map<Id, MIIncident__c> triggerNewMap)
    {
        //local handler vars
        SObject[] casesForUpdate = new SObject[0];
        CSAT__c[] newCSATs = new CSAT__c[0];
        Set<Id> assignedMIAccountIds = new Set<Id>();
        Datetime now = Datetime.now(); //set all timestamp field values to the same value rather than constantly calling Datetime.now() in context
        Set<Id> miIdsForCaseUpdates = new Set<Id>();

        //DO realtime Account assignments
        Map<Decimal, Account> ttUserToAccountMap = new Map<Decimal, Account>();
        for ( Account miAccount : new BeckyMTSIncidentSyncQueueable(triggerNew).doAccountProcessing() )
        {
            ttUserToAccountMap.put(miAccount.usr_user_id__c, miAccount);
        }

        // loop the triggered records
        for (MIIncident__c mi : triggerNew)
        {
            if ( TARGET_RECORD_TYPE_IDS.contains(mi.RecordTypeId) )
            {
                MIIncident__c oldIncident = triggerOldMap.get(mi.Id);
                if (BecquerelUtility.IS_TEST_RUN) { System.debug(LoggingLevel.INFO, '\n\nMI NEW:' + JSON.serialize(mi) + '\nMI OLD' + JSON.serialize(oldIncident) + '\n\n'); }

                Account proAccount = ttUserToAccountMap.get((NULL == mi.pro_user_id__c ? -999 : Decimal.valueOf(mi.pro_user_id__c)));
                Account customerAccount = ttUserToAccountMap.get((NULL == mi.customer_id__c ? -999 : Decimal.valueOf(mi.customer_id__c)));

                // DECISION FLAGS
                Boolean isStatusChanging = ( oldIncident.Status__c != mi.Status__c );
                Boolean isMIClosed =  'Closed'.equals(mi.Status__c);
                Boolean isBeingClosed = ( isMIClosed && !'Closed'.equals(oldIncident.Status__c) );
                Boolean isOwnerChanging = (mi.OwnerId != oldIncident.OwnerId);
                Boolean isChangingCaseNewEmailFlag = ( false == mi.NewEmailFlag__c && oldIncident.NewEmailFlag__c != mi.NewEmailFlag__c );

                // ensure the Pro and Customer Account Lookup Ids are set
                // set other field value overrides
                mi.ProAccount__c = ( NULL == proAccount ) ? mi.ProAccount__c : proAccount.Id;
                mi.CustomerAccount__c = ( NULL == customerAccount ) ? mi.CustomerAccount__c : customerAccount.Id;
                mi.ProContact__c = ( NULL == proAccount || NULL == proAccount.Contacts || proAccount.Contacts.isEmpty() ) ? mi.ProContact__c : proAccount.Contacts[0].Id;
                mi.CustomerContact__c = ( NULL == customerAccount || NULL == customerAccount.Contacts || customerAccount.Contacts.isEmpty() ) ? mi.CustomerContact__c : customerAccount.Contacts[0].Id;
                mi.ClosedDate__c = isBeingClosed ? now : mi.ClosedDate__c;
                mi.LastStatusChangeDate__c = isStatusChanging ? now : mi.LastStatusChangeDate__c;
                mi.LastStatusChangeDate__c = ( NULL == mi.LastStatusChangeDate__c ) ? now : mi.LastStatusChangeDate__c; // fail safe for incident's last update

                //Clear flags when incident is being closed
                mi.NewCallFlag__c = isBeingClosed? false : mi.NewCallFlag__c;
                mi.NewCaseFlag__c = isBeingClosed? false : mi.NewCaseFlag__c;
                mi.NewEmailFlag__c = isBeingClosed? false : mi.NewEmailFlag__c;
                mi.NextFollowupDate__c = isBeingClosed? null : mi.NextFollowupDate__c;
                mi.NewPostFlag__c = isBeingClosed? false : mi.NewPostFlag__c;

                Boolean isProAssigned = ( NULL != mi.ProAccount__c );
                Boolean isCustomerAssigned = ( NULL != mi.CustomerAccount__c );
                Boolean isProContactAssigned = ( NULL != mi.ProContact__c );
                Boolean isCustomerContactAssigned = ( NULL != mi.CustomerContact__c );

                //Sync NewEmailFlag__c b/n case and miincident if changed
                if ( isChangingCaseNewEmailFlag ) { miIdsForCaseUpdates.add( mi.Id ); }

                if ( isMIClosed )
                {
                    if ( mi.NewEmailFlag__c )
                    {
                        mi.Status__c = 'Reopened';
                    }
                    else
                    {
                        mi.NewPostFlag__c = mi.NewCaseFlag__c = false;

                        if( isBeingClosed && mi.RecordTypeId == MI_RECORD_TYPE_ID ) {

                            miIdsForCaseUpdates.add(mi.Id);

                            //create new CSAT template record with common field values, only added for DML if all criteria are met
                            CSAT__c cSAT = new CSAT__c(
                                    Name = 'Survey Response for MI Incident ' + mi.IncidentNumber__c,
                                    MIIncident__c = mi.Id,
                                    User__c = mi.OwnerId,
                                    RecordTypeId = CSAT_RECORD_TYPE_ID,
                                    OwnerId = mi.OwnerId,
                                    Status__c = 'Pending',
                                    MIIncidentCategory__c = mi.MICategory__c,
                                    MIIncidentSubcategory__c = mi.MISubcategory__c
                            );

                            Boolean isProEligible = 'Eligible'.equals(mi.CSATEligibilityPro__c);
                            Boolean isCustomerEligible = 'Eligible'.equals(mi.CSATEligibilityCustomer__c);

                            // set pro/customer-specific field values based on CSAT eligibility and not already offered
                            if ( isProContactAssigned && isProEligible && false == mi.CSATOfferedPro__c )
                            {
                                CSAT__c proCSAT = cSAT.clone();
                                proCSAT.Account__c = mi.ProAccount__c; proCSAT.Contact__c = mi.ProContact__c; proCSAT.MIIncidentOutcome__c = mi.OutcomePro__c; mi.CSATOfferedPro__c = true;
                                newCSATs.add(proCSAT);
                            }

                            if ( isCustomerContactAssigned && isCustomerEligible && false == mi.CSATOfferedCustomer__c )
                            {
                                CSAT__c customerCAST = cSAT.clone();
                                customerCAST.Account__c = mi.CustomerAccount__c; customerCAST.Contact__c = mi.CustomerContact__c; customerCAST.MIIncidentOutcome__c = mi.OutcomeCustomer__c; mi.CSATOfferedCustomer__c = true;
                                newCSATs.add(customerCAST);
                            }
                        }
                    }

                }
                else // Status is NOT equal to 'Closed'
                {
                    // If MI incident is assigned to an agent or queue then update all related cases with the same agent or queue as the case owner.
                    if ( isOwnerChanging )
                    {
                        mi.Status__c = ( 'New'.equals( oldIncident.Status__c ) && TARGET_QUEUE_IDS.keySet().contains( oldIncident.OwnerId ) ) ? 'In Progress' : mi.Status__c;
                        mi.OwnerAssignedDate__c = now;
                        miIdsForCaseUpdates.add( mi.Id );
                    }

                } // END else Status != 'Closed'
            }
        }

        // INSERT CSAT Records, Asynchronously preferred
        if( BecquerelUtility.IS_TEST_RUN ) { System.debug( LoggingLevel.WARN, 'NEW CSATs FOR INSERT' + JSON.serialize( newCSATs ) ); }
        DMLQueueable dmlCsatJob = new DMLQueueable( newCSATs, DMLQueueable.Operation.INSERTS );
        if (!newCSATs.isEmpty()) { if (System.isQueueable()) {  dmlCsatJob.execute(null); } else {  System.enqueueJob(dmlCsatJob); }  }


        for (Case cas : [SELECT Id, NewEmailFlag__c, Category__c, SubCategory__c, Status, OwnerId, Incident__c, Incident__r.Status__c, Incident__r.NewEmailFlag__c FROM Case WHERE Incident__c IN :miIdsForCaseUpdates])
        {
            MIIncident__c parentIncident = triggerNewMap.get(cas.Incident__c);
            MIIncident__c triggerOldMICaseParent = triggerOldMap.get(cas.Incident__c);

            if ( BecquerelUtility.IS_TEST_RUN )
            {
                System.debug(LoggingLevel.INFO, '\n\nTEST CASE FOR UPDATE:\n' + JSON.serialize(cas) + '\n');
                System.debug(LoggingLevel.INFO, 'TEST CASE PARENT INCIDENT:\n' + JSON.serialize(new MIIncident__c(Id=parentIncident.Id,Status__c=parentIncident.Status__c,NewEmailFlag__c=parentIncident.NewEmailFlag__c)) + '\n');
                System.debug(LoggingLevel.INFO, 'TEST OLD INCIDENT CASE PARENT:\n' + JSON.serialize(new MIIncident__c(Id=triggerOldMICaseParent.Id,Status__c=triggerOldMICaseParent.Status__c,NewEmailFlag__c=triggerOldMICaseParent.NewEmailFlag__c)) + '\n\n');
            }

            if ( NULL != parentIncident && NULL != triggerOldMICaseParent )
            {
                Boolean isMIClosing = ( 'Closed'.equals(parentIncident.Status__c ) && !'Closed'.equals( triggerOldMICaseParent.Status__c ) );
                Boolean isNegatingNewEmailFlag = ( false == parentIncident.NewEmailFlag__c && triggerOldMICaseParent.NewEmailFlag__c );
                Boolean isOwnerChanging = ( parentIncident.OwnerId != triggerOldMICaseParent.OwnerId );

                if ( isMIClosing && !'Closed'.equals(cas.Status) )
                {
                    cas.OwnerId = parentIncident.OwnerId;
                    cas.Status = 'Closed';
                    cas.Category__c = 'Marketplace Integrity';
                    cas.SubCategory__c = 'Incident';
                    cas.ManualCaseCreation__c = false;
                    casesForUpdate.add(cas);
                }
                else
                {
                    cas.NewEmailFlag__c = isNegatingNewEmailFlag ? false : cas.NewEmailFlag__c;
                    cas.OwnerId = isOwnerChanging ? parentIncident.OwnerId : cas.OwnerId;
                    casesForUpdate.add(cas);
                }
            }
        }

        // UPDATE ALL Case Records, Asynchronously preferred
        DMLQueueable dmlCaseJob = new DMLQueueable(casesForUpdate, DMLQueueable.Operation.UPDATES);
        if (!casesForUpdate.isEmpty()) {  if (System.isQueueable()) { dmlCaseJob.execute(null); } else {  System.enqueueJob(dmlCaseJob); }  }

    } // END doMiBeforeUpdateRules()


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Create update histories and MIIncidentAction__c records.
    * @param MIIncident__c[] the trigger NEW array.
    * @param Map<Id, MIIncident__c> the trigger OLD map.
    */
    private void createHistoriesAndMIIncidentActions(MIIncident__c[] triggerNew, Map<Id, MIIncident__c> triggerOldMap)
    {
        this.insertUpdateHistories(triggerNew, true, triggerOldMap);
        Datetime now = Datetime.now();

        MIIncidentAction__c[] taskActions = new MIIncidentAction__c[0];
        for (MIIncident__c mi : triggerNew)
        {
            MIIncident__c oldMi = triggerOldMap.get(mi.id);
            if (oldmi.Status__c != mi.Status__c)
            {
                // create MIIncidentAction__c if status Owner is changing to a user and status is in progress or new
                if ( 'In Progress'.equals(mi.Status__c) && 'New'.equals(oldMi.Status__c) && mi.OwnerId != oldMi.OwnerId && String.valueOf(mi.OwnerId).startsWith('005') )
                {
                    taskActions.add(new MIIncidentAction__c(RecordTypeId = MiIncidentActionTriggerHandler.TaskRTId, Type__c = 'Follow-up', Name = 'First Review Task', DueDate__c = now, Status__c = 'Open', Notes__c = 'Incident assigned; complete first review', MIIncident__c = mi.Id));
                }
            }
        }

        if (!taskActions.isEmpty())
        {
            if (System.isQueueable()) { new DMLQueueable(taskActions, DMLQueueable.Operation.INSERTS).execute(NULL); } else {  System.enqueueJob(new DMLQueueable(taskActions, DMLQueueable.Operation.INSERTS)); }
        }

    } //end createHistoriesAndMIIncidentActions()


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Create Update History records for the MI Change log over time.
    * @param MIIncident__c[] the trigger NEW array.
    * @param Boolean flag indicating whether this is an update or insert trigger context.
    * @param Map<Id, MIIncident__c> the trigger OLD map.
    */
    private void insertUpdateHistories(MIIncident__c[] triggerNew, Boolean isUpdate, Map<Id, MIIncident__c> oldMIMap)
    {
        Id miUpdateHistoryRecordTypeId = MIIncidentUpdateHistory__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident Update History').getRecordTypeId();
        MIIncidentUpdateHistory__c[] newMIUpdateHistories = new MIIncidentUpdateHistory__c[0];
        for (MIIncident__c mi : triggerNew)
        {
            if (!isUpdate)
            {
                newMIUpdateHistories.add( this.getMiUpdateHistoryRecord( mi, NULL, miUpdateHistoryRecordTypeId ) );
            }
            else
            {
                MIIncident__c miOld = oldMIMap.get(mi.Id);
                if (NULL != miOld && mi.Status__c != miOld.Status__c) {  newMIUpdateHistories.add( this.getMiUpdateHistoryRecord(mi, miOld, miUpdateHistoryRecordTypeId) ); }
            }
        }

        if (!newMIUpdateHistories.isEmpty()) {
            if (System.isQueueable()) { new DMLQueueable(newMIUpdateHistories, DMLQueueable.Operation.INSERTS).execute(NULL); } else { System.enqueueJob(new DMLQueueable(newMIUpdateHistories, DMLQueueable.Operation.INSERTS)); }
        }

    } // END insertUpdateHistories


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Map field values unto the update history record (used in both AFTER INSERT and AFTER UPDATE trigger events).
    * @param MIIncident__c the trigger NEW record.
    * @param MIIncident__c the trigger OLD record.
    * @param Id the record type id to set on the update history record.
    */
    private MIIncidentUpdateHistory__c getMiUpdateHistoryRecord(MIIncident__c newRecord, MIIncident__c oldRecord, Id recordTypId)
    {
        Datetime now = DateTime.now();
        return new MIIncidentUpdateHistory__c(
                RecordtypeId = recordTypId,
                MIIncident__c = newRecord.id,
                FromDate__c = (NULL == oldRecord) ? now : oldRecord.LastStatusChangeDate__c,
                ToDate__c = now,
                MIIncidentAgent__c = newRecord.ownerFullName__c,
                MIIncidentPreviousStatus__c = (NULL == oldRecord) ? newRecord.Status__c : oldRecord.Status__c,
                MIIncidentStatus__c = newRecord.Status__c
        );
    } // END getMiUpdateHistoryRecord


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Make sure the open mi incident flag is synchronized based on all related MI records being open or closed. NOTE: this must be done asynchronously to assess the true database commit state.
    * @param MIIncident__c[] the trigger NEW array.
    * @param Map<Id, MIIncident__c> the trigger OLD map.
    */
    public void syncAccountOpenIncidentFlag(MIIncident__c[] incidents, Map<Id, MIIncident__c> oldIncidentMap)
    {
        if (!incidents.isEmpty())
        {
            AccountOpenMTSIncidentSync accountSyncJob = new AccountOpenMTSIncidentSync(incidents, oldIncidentMap);
            if (System.isQueueable())
            {
                accountSyncJob.execute(null);
            }
            else
            {
                System.enqueueJob(accountSyncJob);
            }
        }
    } // END syncAccountOpenIncidentFlag


    /**
    * @author Mendel Guillaume
    * @date 2017-11-13
    * @description Close all MI-related tasks when the MI record is being closed
    * @param MIIncident__c[] the trigger NEW array.
    * @param Map<Id, MIIncident__c> the trigger OLD map.
    */
    private void completeRelatedTasks(List<MIIncident__c> newIncidents, Map<Id, MIIncident__c> oldIncidentsMap)
    {
        Set<Id> closedIds = new Set<Id>();

        for(MIIncident__c mi : newIncidents)
        {
            MIIncident__c old = oldIncidentsMap.get(mi.Id);

            if(mi.Status__c == 'Closed' && old.Status__c != 'Closed')
            {
                closedIds.add(mi.Id);
            }
        }

        if(!closedIds.isEmpty())
        {
            List<MIIncidentAction__c> tasks = [SELECT Id FROM MIIncidentAction__c
                                                WHERE MIIncident__c IN :closedIds AND RecordType.Name = 'Task' AND Status__c != 'Completed'];

            if(!tasks.isEmpty())
            {
                for(MIIncidentAction__c t : tasks)
                {
                    t.Status__c = 'Completed';
                }

                try
                {
                    DMLQueueable taskJob = new DMLQueueable(tasks, DMLQueueable.Operation.UPDATES);
                    if (Limits.getLimitQueueableJobs() > Limits.getQueueableJobs())
                    {
                        try
                        {
                            System.enqueueJob( taskJob );
                        }
                        catch (System.AsyncException ccEx)
                        {
                            System.debug(LoggingLevel.ERROR, ccEx);
                            TackBotUtility.sendExceptionEmail( ccEx, 'MiIncidentTriggerHandler.completeRelatedTasks' );
                            taskJob.execute(NULL);
                        }
                    }
                    else
                    {
                        taskJob.execute(NULL);
                    }
                }
                catch (Exception ex)
                {
                    System.debug(LoggingLevel.ERROR, ex);
                    TackBotUtility.sendExceptionEmail( ex, 'MiIncidentTriggerHandler.completeRelatedTasks' );
                }
            }
        }
    }

    /**
    * @author Mendel Guillaume
    * @date 2018-02-09
    * @description Close all MI-related tasks when the MI record is being closed
    * @param MIIncident__c[] the trigger NEW array.
    * @param Map<Id, MIIncident__c> the trigger OLD map.
    */
    private void updateRelatedRecordsToConfidential(List<MIIncident__c> incidents, Map<Id, MIIncident__c> oldIncidentsMap)
    {
        Set<Id> confidentialIncidentIds = new Set<Id>();

        for(MIIncident__c i : incidents)
        {
            MIIncident__c old = oldIncidentsMap.get(i.Id);

            if(i.RecordTypeId == CONFIDENTIAL_RECORD_TYPE_ID && i.RecordTypeId != old.RecordTypeId)
            {
                confidentialIncidentIds.add(i.Id);
            }
        }

        if(!confidentialIncidentIds.isEmpty())
        {
	        MiIncidentHelper.MiIncidentQueueable miq = new MiIncidentHelper.MiIncidentQueueable();
	        miq.confidentialIncidentIds = confidentialIncidentIds;

	        QueueableUtility.handleQueueable(miq);
        }
    }
}