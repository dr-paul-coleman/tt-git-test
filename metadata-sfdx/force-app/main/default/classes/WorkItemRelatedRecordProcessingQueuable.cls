/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/12/17      jkennington          Created
========+============+=================+===============================================*/
public with sharing class WorkItemRelatedRecordProcessingQueuable implements Queueable
{
    private List<SObject> records;
    private List<SObject> firstInserts;
    private List<Case> miCasesToInsert;

    public WorkItemRelatedRecordProcessingQueuable(List<SObject> insertRecords)
    {
        this.records = (null == insertRecords) ? new List<SObject>() : insertRecords;
        this.firstInserts = new List<SObject>();
        this.miCasesToInsert = new List<Case>();
    }

    //function to create a feeditem for each case, to be sumbitted in batch
    public ConnectApi.BatchInput getCaseFeedItem(Id caseId, String description)
    {
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.subjectId = caseId;
        ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
        body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = description;
        body.messageSegments.add(textSegment);
        input.body = body;
        return new ConnectApi.BatchInput(input);
    }

    public void execute(QueueableContext context)
    {
        //get Guidance and MIIncident records for single DML insert. gather Cases for later insert
        for (SObject s : records)
        {
            String sType = String.valueOf(s.getSObjectType()).toLowerCase();
            if ('customersuccessguidance__c'.equals(sType) || 'miincident__c'.equals(sType))
            {
                firstInserts.add(s);
            }
            else if ('case'.equals(sType))
            {
                miCasesToInsert.add((Case) s);
            }
        }

        if (!firstInserts.isEmpty())
        {
            //ensure only two transitions of SObject types per insert list
            firstInserts.sort();
            System.debug(LoggingLevel.FINEST, JSON.serialize(Database.insert(firstInserts, false)));

            //gather MIIncident inserts that succeeded
            List<MIIncident__c> miIncidentsToInsert = new List<MIIncident__c>();
            for (Sobject so : firstInserts)
            {
                if (null != so.Id && 'miincident__c'.equals(String.valueOf(so.getSObjectType()).toLowerCase()))
                {
                    miIncidentsToInsert.add((MIIncident__c) so);
                }
            }

            //set Incident__c Id on Cases to be inserted, matching Case Account's TT userid to MI's quotes_pro_user_id__c
            if (!miCasesToInsert.IsEmpty() && !miIncidentsToInsert.IsEmpty())
            {
                List<Id> accountIds = new List<Id>();
                for (Case cse : miCasesToInsert)
                {
                    accountIds.add(cse.AccountId);
                }
                Map<Id, Account> caseAccounts = new Map<Id, Account>([Select Id,usr_user_id__c FROM Account WHERE Id IN :accountIds]);
                for (MiIncident__c mi2i : miIncidentsToInsert)
                {
                    for (Case case2i : miCasesToInsert)
                    {
                        Account a = caseAccounts.containsKey(case2i.AccountId) ? caseAccounts.get(case2i.AccountId) : null;
                        //if Case and Mi share the same pro user id, relate the case to its MI parent
                        if (null != a && null != a.usr_user_id__c && mi2i.quotes_pro_user_id__c == a.usr_user_id__c)
                        {
                            case2i.Incident__c = mi2i.Id;
                            break;
                        }
                    }
                }
            }
            try
            {
                insert miCasesToInsert;

                //POST CASE FEED ITEMS
                List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
                for (Case insertedCase : miCasesToInsert){batchInputs.add(getCaseFeedItem(insertedCase.Id, insertedCase.Description));}
                if (!batchInputs.isEmpty() && !Test.isRunningTest()){ConnectApi.ChatterFeeds.postFeedElementBatch(null, batchInputs);}
            }
            catch (DMLException e)
            {
                System.debug(LoggingLevel.Error, e);
            }
        }
    }
}