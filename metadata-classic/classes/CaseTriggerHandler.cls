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
Script File Name    : CaseTriggerHandler.cls
Script Type         : Standard Apex Trigger Handler Class
Description         : Static Functions to handle Trigger Events

Change List:
------------

Version    Date     Author            Description
=======+===========+=================+=================================
1.0     2015-07-03  Paul Coleman      Created
1.1     2015-08-12  Travis Oliver     Added createCsat() handler
1.2     2015-09-07  Travis Oliver     Updated to include live chat record type
1.3     2015-12-19  Paul Coleman      Added Case Comment Queueable
1.4     2016-02-05  Kristin Hasna     Updated to include Social Media case origin
1.5     2016-04-04  Paul Coleman      Added Suggestion Box to Case Origin query
1.6     2016-05-02  Kristin Hasna     Updated to include App Integration to case origin query
1.7     2016-05-10  Paul Coleman      Added Case to Contact match by SuppliedThumbtackID__c
1.8     2016-09-30  Paul Coleman      Added flagEmailToCaseDupesAsNoise BEFORE INSERT function
1.9     2016-10-10  Paul Coleman      Added Marketplace Integrity filter to CaseCommentQueue CaseComment insert
2.0     2017-06-21  Kristin Hasna     Updated CSAT record type from getFeedback CSAT to Customer Satisfaction
2.1     08-14-2017  Scott Purcell     Added caseStatusUpdate
2.2     08-25-2017  Scott Purcell     Lots of stuff added for the mI Rebuid project. Look at comments below
2.3     2017-09-30  Mendel Guillaume  Code refactoring
2.4     2017-10-30  Paul Coleman      Moved Incident updates and CSAT inserts to a DML Queueable operation
2.4.5   2017-11-13  Paul Coleman      reverted CSAT inserts from a DML Queueable operation to inline
=======+===========+=================+=================================*/
public with sharing class CaseTriggerHandler extends ThumbtackTriggerHandlerBase
{

    public static Boolean runOnce = false;

    public static Group miQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Marketplace Integrity' LIMIT 1];
    public static Group noiseQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Noise' LIMIT 1];
    private static Id ttRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
    public static Id miRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity Restricted').getRecordTypeId();
    public static Id mRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
    public static Id miIncidentRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    public static boolean firstRun = true;

    private static Set<Id> newPostFlagIncidentIds;
    private static Set<Id> newCallFlagIncidentIds;

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onBeforeInsert(ThumbtackTriggerContext ctx)
    {
        onBeforeInsert((List<Case>) ctx.newRecords);
    }

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        onBeforeUpdate((Map<Id, Case>) ctx.newRecordsMap, (Map<Id, Case>) ctx.oldRecordsMap);
    }

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onAfterInsert(ThumbtackTriggerContext ctx)
    {
        onAfterInsert((Map<Id, Case>) ctx.newRecordsMap);
    }

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void onAfterUpdate(ThumbtackTriggerContext ctx)
    {
        onAfterUpdate((Map<Id, Case>) ctx.newRecordsMap, (Map<Id, Case>) ctx.oldRecordsMap);
    }

    private static void onBeforeInsert(List<Case> newRecords)
    {
        //find any Triggered Customer Support Cases that are from Email-To-Case, ignore all others
        List<Case>miCases = new List<Case>();

        List<Case> customerSupportCases = new List<Case>();
        Set<String> customerSupportCaseEmails = new Set<String>();
        Set<Id> incidentCaseAccountIds = new Set<Id>();
        Set<Id> incidentIds = new Set<Id>();

        for(Case c: newRecords)
        {
            if (c.RecordTypeId == CaseHelper.CUSTOMER_SUPPORT_RECORD_TYPE_ID && c.Origin == 'Email' && c.SuppliedEmail != null)
            {
                customerSupportCases.add(c);
                customerSupportCaseEmails.add(c.SuppliedEmail);
            }

            //do not relate incidents if this is checked.
            if(c.MIDoNotRelateIncident__c == false)
            {
                miCases.add(c);

                if(c.AccountId != null && c.BGCReportId__c == null)
                {
                    incidentCaseAccountIds.add(c.AccountId);
                }

                if(c.Incident__c != null)
                {
                    incidentIds.add(c.Incident__c);
                }
            }
        }

        if(!customerSupportCases.isEmpty())
        {
            //using the Case.SuppliedEmail field value, see if that contact already has an open case(s) & if so, set RT to Noise
            flagEmailToCaseDupesAsNoise(customerSupportCases, customerSupportCaseEmails);
        }

        if(!miCases.isEmpty())
        {
            miIncidentHandler(miCases, null, false, incidentCaseAccountIds, incidentIds);
        }
    }

    private static void onBeforeUpdate(Map<Id, Case> newRecordsMap, Map<Id, Case> oldRecordsMap)
    {
        List<Case> miCases = new List<Case>();
        List<Case> bcCases = new List<Case>();
        Set<Id> incidentCaseAccountIds = new Set<Id>();
        Set<Id> incidentIds = new Set<Id>();

        for(Case c : newRecordsMap.values())
        {
            if(c.MIDoNotRelateIncident__c == false)
            {
                miCases.add(c);

                if(c.AccountId != null && c.BGCReportId__c == null)
                {
                    incidentCaseAccountIds.add(c.AccountId);
                }

                if(c.Incident__c != null)
                {
                    incidentIds.add(c.Incident__c);
                }
            }

            if(c.BGCReportId__c != null && c.BackgroundCheck__c == null)
            {
                bcCases.add(c);
            }
        }

        if(!bcCases.isEmpty())
        {
            CaseTriggerHandler.backgroundCheck(bcCases, oldRecordsMap);
        }

        if(CaseTriggerHandler.firstRun)
        {
            miIncidentHandler(miCases, oldRecordsMap, true, incidentCaseAccountIds, incidentIds);
        }

        CaseTriggerHandler.firstRun = false;
    }

    private static void onAfterInsert(Map<Id, Case> newRecordsMap)
    {
        Set<Decimal> usrIDs = new Set<Decimal>();
        List<Id> noContactCaseIds = new List<Id>();
        Map<Id, MIIncident__c> incidentsToUpdateMap = new Map<Id, MIIncident__c>();

        for(Case c : newRecordsMap.values())
        {
            if(c.AccountId == null && c.ContactId == null)
            {
                noContactCaseIds.add(c.Id);
            }

            if(c.Incident__c != null)
            {
                setIncidentNewCaseFlag(c, null, incidentsToUpdateMap);
            }
        }

        QueueableUtility.handleQueueable( new CaseHelper.CaseCommentQueue(Trigger.New) );

        setIncidentNewCallFlag(incidentsToUpdateMap);
        setIncidentNewPostFlag(incidentsToUpdateMap);

        QueueableUtility.handleQueueable( new DMLQueueable( incidentsToUpdateMap.values(), DMLQueueable.Operation.UPDATES ) );

        if(!noContactCaseIds.isEmpty())
        {
            QueueableUtility.handleQueueable( new CaseHelper.CaseQueue(noContactCaseIds) );
        }
    }

    private static void onAfterUpdate(Map<Id, Case> newRecordsMap, Map<Id, Case> oldRecordsMap)
    {
        Set<Id> cSatCasesRecordTypes = new Set<Id>{CaseHelper.CUSTOMER_SUPPORT_RECORD_TYPE_ID, CaseHelper.MARKETPLACE_INTEGRITY_RECORD_TYPE_ID, CaseHelper.LIVE_CHAT_RECORD_TYPE_ID};
        Map<Id, MIIncident__c> incidentsToUpdateMap = new Map<Id, MIIncident__c>();
        Map<Id, Case> cSatCases = new Map<Id, Case>();

        for(Case c : newRecordsMap.values())
        {
            Case oldCase = oldRecordsMap.get(c.Id);

            if(c.Incident__c != null)
            {
                setIncidentNewCaseFlag(c, oldCase, incidentsToUpdateMap);
                setIncidentNewEmailFlag(c, oldCase, incidentsToUpdateMap);
            }

            if(cSatCasesRecordTypes.contains(c.RecordTypeId) && c.CSATEligible__c == 'Eligible' && c.isClosed == true)
            {
                cSatCases.put(c.Id, c);
            }
        }

        setIncidentNewCallFlag(incidentsToUpdateMap);
        setIncidentNewPostFlag(incidentsToUpdateMap);

        QueueableUtility.handleQueueable( new DMLQueueable( incidentsToUpdateMap.values(), DMLQueueable.Operation.UPDATES ) );

        if(!cSatCases.isEmpty())
        {
            createCsat(cSatCases);
        }
    }

    //For Cases that have been created by Email-To-Case, flag dupes by Contact as Noise (to be deleted within the CaseEmailMessage trigger)
    private static void flagEmailToCaseDupesAsNoise(List<Case> customerSupportCases, Set<String> customerSupportCaseEmails)
    {
        try
        {
            //get Noise Owner Id (Queue)
            Id noiseQId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Noise' LIMIT 1].Id;
            Map<String,Case> openCases = new Map<String,Case>();

            for(Case cOpen: [SELECT Id,Subject,SuppliedEmail,OwnerId
            FROM Case
            WHERE Status='New' AND RecordTypeId =: CaseHelper.CUSTOMER_SUPPORT_RECORD_TYPE_ID
            AND SuppliedEmail IN :customerSupportCaseEmails AND Origin='Email' AND isClosed=false
            AND SystemModStamp >= :Datetime.now().addMinutes(-10)])
            {
                openCases.put(cOpen.SuppliedEmail, cOpen);
            }

            //Main run, if triggered case matches a mapped open case, then match on Subject and assign to Noise Q
            //Noise queue in combination with EmailMessage Trigger will delete Case and EmailMessage records
            if(!openCases.isEmpty())
            {
                for(Case c: customerSupportCases)
                {
                    Case openCase = openCases.get(c.SuppliedEmail);

                    //process only triggered Email-To-Case records that match an open case (by non-Null SuppliedEmail value)
                    if (openCase != null)
                    {
                        if(c.Subject  == openCase.Subject)
                        {
                            //assign to Noise Queue for EmailMessage Trigger processing (CaseEmailTrigger/CaseEmailHandler)
                            c.Ownerid = noiseQId;
                        }
                    }
                }
            }
        }
        catch(DmlException e)
        {
            system.debug(e);
        }
    }

    private static MIIncident__c getIncidentToUpdate(Id incidentId, Map<Id, MIIncident__c> incidentsToUpdateMap)
    {
        MIIncident__c incident = incidentsToUpdateMap.get(incidentId);

        if (incident == null)
        {
            incident = new MIIncident__c(Id = incidentId);
            incidentsToUpdateMap.put(incidentId, incident);
        }

        return incident;
    }

    private static void setIncidentNewPostFlag(Map<Id, MIIncident__c> incidentsToUpdateMap)
    {
        if(newPostFlagIncidentIds != null)
        {
            for(Id incidentId : newPostFlagIncidentIds)
            {
                MIIncident__c incident = getIncidentToUpdate(incidentId, incidentsToUpdateMap);

                incident.NewPostFlag__c = true;
            }
        }
    }

    private static void setIncidentNewCallFlag(Map<Id, MIIncident__c> incidentsToUpdateMap)
    {
        if(newCallFlagIncidentIds != null)
        {
            for(Id incidentId : newCallFlagIncidentIds)
            {
                MIIncident__c incident = getIncidentToUpdate(incidentId, incidentsToUpdateMap);

                incident.NewCallFlag__c = true;
            }
        }
    }

    private static void setIncidentNewEmailFlag(Case c, Case oldCase, Map<Id, MIIncident__c> incidentsToUpdateMap)
    {
        if(c.Incident__c != oldCase.Incident__c || c.NewEmailFlag__c != oldCase.NewEmailFlag__c)
        {
            MIIncident__c incident = getIncidentToUpdate(c.Incident__c, incidentsToUpdateMap);

            incident.NewEmailFlag__c = c.NewEmailFlag__c;
        }
    }

    private static void setIncidentNewCaseFlag(Case c, Case oldCase, Map<Id, MIIncident__c> incidentsToUpdateMap)
    {
        if (c.OwnerId != UserInfo.getUserId() && (oldCase == null || c.Incident__c != oldCase.Incident__c))
        {
            MIIncident__c incident = getIncidentToUpdate(c.Incident__c, incidentsToUpdateMap);

            incident.NewCaseFlag__c = true;
        }
    }

    public static void miIncidentHandler(List<Case> miCases, Map<Id,Case> oldMap, Boolean isUpdate, Set<Id> incidentCaseAccountIds, Set<Id> incidentIds)//onBeforeInsert and update
    {
        try
        {
            Map<Id, Map<Id, MIIncident__c>> accountIdToOpenIncidentsMap = new Map<Id, Map<Id, MIIncident__c>>();
            Map<Id,MIIncident__c> miProMap = new Map<Id,MIIncident__c>();
            Map<Id,MIIncident__c> miCustMap = new Map<Id,MIIncident__c>();
            List<MIIncident__c> miToMatch = new List<MIIncident__c>();
            List<String>proIds = new List<String>();
            List<String>miIdToSetToQueue = new List<String>();
            //get all ,MIIncident__c records that contain the accountId in the case .
            Map<Id, MIIncident__c> incidents = new Map<Id, MIIncident__c>([SELECT Id,NewCaseFlag__c,NewPostFlag__c,NewCallFlag__c,Status__c,ProAccount__c,
                    CustomerAccount__c,OwnerId,RecordTypeId
            FROM MIIncident__c
            WHERE (ProAccount__c IN :incidentCaseAccountIds OR CustomerAccount__c IN :incidentCaseAccountIds OR Id IN :incidentIds)
            //      AND (ProAccount__r.MIOpenIncident__c = true OR CustomerAccount__r.MIOpenIncident__c = true)
            AND RecordTypeId =:miIncidentRecordTypeId]);
            newCallFlagIncidentIds = new Set<Id>();
            newPostFlagIncidentIds = new Set<Id>();

            //loop through existing INcidents to get Ids
            for(MIIncident__c mi: incidents.values())
            {
                //Build map of accounts to incident to determine if case is assigned to queue or incident owner
                if(mi.Status__c != 'Closed')
                {
                    if(mi.ProAccount__c != null)
                    {
                        Map<Id, MIIncident__c> accountIncidents = accountIdToOpenIncidentsMap.get(mi.ProAccount__c);

                        if(accountIncidents == null)
                        {
                            accountIncidents = new Map<Id, MIIncident__c>();
                            accountIdToOpenIncidentsMap.put(mi.ProAccount__c, accountIncidents);
                        }

                        accountIncidents.put(mi.Id, mi);
                    }

                    if(mi.CustomerAccount__c != null)
                    {
                        Map<Id, MIIncident__c> accountIncidents = accountIdToOpenIncidentsMap.get(mi.CustomerAccount__c);

                        if(accountIncidents == null)
                        {
                            accountIncidents = new Map<Id, MIIncident__c>();
                            accountIdToOpenIncidentsMap.put(mi.CustomerAccount__c, accountIncidents);
                        }

                        accountIncidents.put(mi.Id, mi);
                    }
                }
            }

            //loop through all the cases in trigger.
            Map<String,Case>caseIncidentMap = new Map<String,Case>();
            for(Case c : miCases)
            {
                Case oldCase = isUpdate ? oldMap.get(c.Id) : null;

                Map<Id, MIIncident__c> accountIncidents = accountIdToOpenIncidentsMap.get(c.AccountId);

                if(accountIncidents != null)
                {
                    ////set Owner on cases that match the accounts with >1 open incidents to MIQueue or to incident owner if there's only 1 incident on Insert
                    if(oldCase == null || c.AccountId != oldCase.AccountId && c.AccountId != null)
                    {
                        if (accountIncidents.size() > 1)
                        {
                            c.OwnerId = miQueue.Id;
                            c.MultipleIncidents__c = true;
                        }
                        else if (accountIncidents.size() == 1)
                        {
                            MIIncident__c incident = accountIncidents.values()[0];

                            c.MultipleIncidents__c = false;
                            c.OwnerId = incident.OwnerId;

                            if(c.Origin == 'Web' || c.Origin == 'Email' || c.Origin == 'Dispute form')
                            {
                                c.RecordTypeId = mRecordTypeId;
                            }

                            if(c.Incident__c == null)
                            {
                                c.Incident__c = incident.Id;
                            }
                        }
                    }
                    else if (oldCase != null && c.Incident__c != oldCase.Incident__c && c.Incident__c != null && c.MIIncidentOwnerId__c != null ) //Update owner to new MIIncident owner if incident is changed
                    {
                        c.OwnerId = c.MIIncidentOwnerId__c;
                    }

                }
                else
                {
                    c.MultipleIncidents__c = false;
                }

                if(c.Incident__c != null && c.Incident__r.RecordTypeId == miIncidentRecordTypeId && c.MultipleIncidents__c == false
                        && c.ManualCaseCreation__c == false && (c.Origin == 'Web' || c.Origin == 'Email' || c.Origin == 'Dispute form') && (c.MICasePrimaryCustomer__c == false
                        && c.MICasePrimaryPro__c == false ) && c.NewEmailFlag__c == false)
                {

                    system.debug('c.Incident__c: '+c.OwnerId);
                    c.Category__c = 'Marketplace Integrity';
                    c.Subcategory__c = 'Duplicate';
                    c.Status = 'Closed';
                    c.Team__c = 'Marketplace Integrity' ;
                    c.RecordTypeId = mRecordTypeId;
                    c.NewEmailFlag__c = true;
                }

                c.MultipleIncidents__c = false;

                //Add Incident ids to sets to be processed after insert/update
                if(c.Incident__c != null && (oldCase == null || c.CaseFeedFlag__c != oldCase.CaseFeedFlag__c))
                {
                    MIIncident__c incident = incidents.get(c.Incident__c);

                    if(incident != null && incident.Status__c != 'New')
                    {
                        if (c.CaseFeedFlag__c == 'Chat Transcript Post' || c.CaseFeedFlag__c == 'Text Post' || c.CaseFeedFlag__c == 'Advanced Test Post')
                        {
                            newPostFlagIncidentIds.add(c.Incident__c);
                            c.CaseFeedFlag__c = null;
                        }
                        else if (c.CaseFeedFlag__c == 'Call Log Feed')
                        {
                            newCallFlagIncidentIds.add(c.Incident__c);
                            c.CaseFeedFlag__c = null;
                        }
                    }
                }
            }

        }
        catch(DmlException e)
        {
            system.debug('CaseTriggerHandler.miIncidentHandler : '+e);
        }
    }

    public static void backgroundCheck(List<Case> cases, Map<Id, Case> oldCasesMap)//before update
    {
        List<BackgroundCheck__c> bCheckList = new List<BackgroundCheck__c>();
        Map<String, Case> caseMap = new Map<String, Case>();
        List<String>caseIds = new List<String>();
        Map<String, BackgroundCheck__c> bCheckMap = new Map<String, BackgroundCheck__c>();

        for (Case cs : cases)
        {
            Case oldCase = oldCasesMap.get(cs.Id);

            if (oldCase.OwnerID == '00531000007OiRr')
            {
                cs.OwnerId = miQueue.Id;
            }

            if (cs.Subject != null && cs.Description != null && cs.Subject.contains('CONSIDER')) //only do these ones
            {
                String body = cs.Description;

                body = body.escapeHtml4();
                body = body.replace('<br>', '');
                body = body.replaceAll('<[/a-zAZ0-9]*>', '');

                String reportID = body.substringBetween('/reports/', 'If you');

                if (reportId == null)
                {
                    reportID = body.substringBetween('eports/', 'If you');
                }

                reportId.replace('<', '');
                reportID = reportID.substring(0, 24);
                cs.BGCReportId__c = reportID;
            }

            caseMap.put(cs.BGCReportId__c, cs);
        }

        List<BackgroundCheck__c> bchecks = [Select Id,ReportId__c From BackgroundCheck__c Where ReportId__c IN :caseMap.keySet()];

        system.debug('matching bchecks.size(): ' + bchecks.size());

        for (BackgroundCheck__c b : bchecks)
        {
            bCheckMap.put(b.ReportId__c, b);
        }

        for (Case c : cases)
        {
            if (bCheckMap.containsKey(c.BGCReportId__c))
            {
                c.BackgroundCheck__c = bCheckMap.get(c.BGCReportId__c).Id;
                system.debug('bCheck updated: ');
            }
            else
            {
                String subject = null;

                if (c.Subject != null)
                {
                    subject = c.Subject.abbreviate(79);
                }

                BackgroundCheck__c b = new BackgroundCheck__c();
                b.Name = subject;//the name will be set in the BackGroundCheckAPI.
                b.ReportId__c = c.BGCReportId__c;
                bCheckList.add(b);
                system.debug('bCheck created: ');
            }

            c.OwnerId = miQueue.Id;
            c.RecordTypeId = miRecordTypeId;
        }

        try
        {
            if (!bCheckList.isEmpty())
            {
                insert bCheckList;
            }

            Map<Id, BackgroundCheck__c> backgroundCheckMap = new Map<Id, BackgroundCheck__c>(bCheckList);

            for (Case c : cases)
            {
                BackgroundCheck__c b = backgroundCheckMap.get(c.BGCReportId__c);

                if(b != null)
                {
                    c.BackgroundCheck__c = b.Id;
                    c.AccountId = null;
                    c.ContactId = null;
                    c.Category__c = 'Other';
                    c.SubCategory__c = 'Background check (not clear)';
                    c.OwnerId = miQueue.Id;
                    c.RecordTypeId = miRecordTypeId;
                }
            }
            //updateCases(caseIds);
        }
        catch (Exception e)
        {
            system.debug(e);
        }
    }

    //For Cases that have been closed and are CSAT Eligible, create a CSAT__c record related to the case
    public static void createCsat(Map<Id, Case> targetCases)
    {
        try
        {
            List<Case> casesWithSurveyResponse = [
                    Select Id,CaseNumber,AccountId,ContactId,Category__c,SubCategory__c,Ownerid, (SELECT ID FROM SurveyResponses__r LIMIT 1)
                    FROM Case
                    WHERE Id IN :targetCases.keySet()
            ];
            List<Csat__c> csats = new List<Csat__c>();
            Id csatRTId = CSAT__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Satisfaction').getRecordTypeId();

            for (Case triggeredCase : casesWithSurveyResponse)
            {
                if (triggeredCase.SurveyResponses__r.isEmpty())
                {
                    csats.add(new Csat__c(Case__c = triggeredCase.id,
                            Name = 'Survey Response for Case ' + triggeredCase.CaseNumber,
                            Account__c = triggeredCase.AccountId,
                            Contact__c = triggeredCase.ContactId,
                            CaseCategory__c = triggeredCase.Category__c,
                            CaseSubcategory__c = triggeredCase.SubCategory__c,
                            Ownerid = triggeredCase.Ownerid,
                            User__c = triggeredCase.Ownerid,
                            RecordTypeId = csatRTId,
                            Status__c = 'Pending'));
                }
            }

            if (!csats.isEmpty())
            {
                insert csats;
            }
        }
        catch (DmlException e)
        {
            system.debug(e);
        }
    }

}