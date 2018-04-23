/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/19/18      pcoleman           Created
========+============+=================+===============================================*/
public with sharing class MTSDisputeHelper
{

    // code for MI Trigger Handler to cascader RT change for "Confidential"
    private void cascadeMIConfidential( Map<Id, MIIncident__c> triggerNewMap )
    {
        Id miCondentialRTId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
        Id disputeCondentialRTId = Dispute__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
        Id offerCondentialRTId = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
        Id msgCondentialRTId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
        Id caseCondentialRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
        Set<Id> confidentialRTs = new Set<Id>( new Id[]{ disputeCondentialRTId, offerCondentialRTId, msgCondentialRTId,  caseCondentialRTId } );

        String disputeKeyPrefix = Schema.Dispute__c.sObjectType.getDescribe().getKeyPrefix();
        String offerKeyPrefix = Schema.DisputeOffer__c.sObjectType.getDescribe().getKeyPrefix();
        String msgKeyPrefix = Schema.DisputeMessage__c.sObjectType.getDescribe().getKeyPrefix();
        String caseKeyPrefix = Schema.Case.sObjectType.getDescribe().getKeyPrefix();
        Map<String, Id> prefixRTs = new Map<String, Id>{ disputeKeyPrefix => disputeCondentialRTId, offerKeyPrefix => offerCondentialRTId, msgKeyPrefix => msgCondentialRTId, caseKeyPrefix => caseCondentialRTId };

        Map<Id, SObject> recordsForUpdate = new Map<Id, SObject>();
        Map<Id, SObject> allRecords = new Map<Id, SObject>();
        Map<Id, MIIncident__c> targetIncidents = new Map<Id, MIIncident__c>();
        Set<Id> disputeIds = new Set<Id>();

        for( MIIncident__c mi : [SELECT Id, RecordTypeId, (SELECT Id, RecordTypeId FROM Disputes__r), (SELECT Id, RecordType.Name FROM Cases__r) FROM MIIncident__c WHERE Id IN :triggerNewMap.values() LIMIT :triggerNewMap.size()] )
        {
            if( miCondentialRTId == mi.RecordTypeId )
            {
                targetIncidents.put( mi.Id, mi );
                allRecords.putAll(mi.Disputes__r);
                allRecords.putAll(mi.Cases__r);
                for( Dispute__c d: mi.Disputes__r )
                {
                    disputeIds.add( d.Id );
                }

            }
        }

        for( DisputeOffer__c offer: [SELECT Id, RecordTypeId, (SELECT Id, RecordTypeId FROM DisputeMessages__r) FROM DisputeOffer__c WHERE Dispute__c IN : disputeIds] )
        {
            allRecords.put( offer.Id, offer );
            allRecords.putAll( offer.DisputeMessages__r );
        }

        for( SObject record : allRecords.values() )
        {
            if( !confidentialRTs.contains( (Id)record.get( 'RecordTypeId' ) ) ) {

                String prefix = ((String)record.Id).substring(0,3);
                Id recordTypeId = prefixRTs.get( prefix );
                record.put( 'RecordTypeId', recordTypeId );
                recordsForUpdate.put( record.Id, record );
            }
        }

        if( !recordsForUpdate.isEmpty() )
        {
            QueueableUtility.handleQueueable( new DMLQueueable( recordsForUpdate.values(), DMLQueueable.Operation.UPDATES ) );
        }

    }


}