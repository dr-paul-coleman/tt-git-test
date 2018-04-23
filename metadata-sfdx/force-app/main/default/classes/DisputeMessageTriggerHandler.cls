/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/25/18      pcoleman           Created
========+============+=================+===============================================*/
public without sharing class DisputeMessageTriggerHandler extends ThumbtackTriggerHandlerBase
{
    // Recursion Prevention Flags
    private static Boolean isInBeforeProcessing = false;
    private static Boolean isPublishingEvents = false;

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    // SHARED BEFORE INSERT/UPDATE function
    public override void doBeforeProcessing( ThumbtackTriggerContext ctx )
    {
        if( !isInBeforeProcessing )
        {
            isInBeforeProcessing = true;
            try {
                Boolean beforeInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeInsert;
                Boolean beforeUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeUpdate;
                if (beforeInsert || beforeUpdate)
                {
                    DisputeMessage__c[] newRecords = (DisputeMessage__c[])ctx.newRecords;
                    Map<Id, DisputeMessage__c> oldRecordsMap = (Map<Id,DisputeMessage__c>)ctx.oldRecordsMap;

                    this.hashIds( newRecords, oldRecordsMap );

                    if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED MESSSAGES in doBEFORE: ' + JSON.serialize(newRecords)); }
                    if( Test.isRunningTest() && beforeUpdate ) { System.debug(LoggingLevel.WARN, 'OLD MESSAGES VALUES in doBEFORE: ' + JSON.serialize(oldRecordsMap.values())); }
                }
            } finally {  isInBeforeProcessing = false; }
        }
    }

    // SHARED FINAL trigger processing function
    public override void doFinalProcessing( ThumbtackTriggerContext ctx )
    {
        Boolean isAfterInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.afterInsert;

        DisputeMessage__c[] newRecords = (DisputeMessage__c[]) ctx.newRecords;
        try
        {
            // written try/finally to maximize potential that future mods do not supercede
            // order of execution: publish platform events last
            // PLACE FUTURE final processing here (between try/finally), if any
        }
        finally
        {
            if (isAfterInsert)
            {
                //make sure platform events is the last step, non-re-entrant
                if (!isPublishingEvents)
                {
                    isPublishingEvents = true;
                    SolutionCenterUtility.publishSolutionCenterEvents(newrecords);
                }
            }
        }

        if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED MSGs in doFINAL: ' + JSON.serialize(newRecords)); }
    }


    /**
    * @author Paul Coleman
    * @date 2018-01-22
    * @description Ensure every new DisputeMessage record and related records get a hash values for SolutionCenter purposes.
    * @param DisputeMessage__c[] The trigger new array.
    * @param Map<Id, DisputeMessage__c> The trigger old map.
    */
    private void hashIds( DisputeMessage__c[] newDisputes, Map<Id, DisputeMessage__c> oldDisputeMap ) //BEFORE INSERT/UPDATE
    {
        Map<Id, String> idHashMap = new Map<Id, String>();
        Map<String, DisputeMessage__c> msgHashMap = new Map<String, DisputeMessage__c>();
        for (DisputeMessage__c trgMsg : newDisputes )
        {
            if (!String.isEmpty(trgMsg.DisputeMessage__c)) { idHashMap.put(trgMsg.DisputeMessage__c, NULL); }
            if (!String.isEmpty(trgMsg.DisputeOffer__c)) { idHashMap.put(trgMsg.DisputeOffer__c, NULL); }
        }

        // get Message hashes
        for (DisputeMessage__c msg : [SELECT Id, IdHash__c FROM DisputeMessage__c WHERE Id IN :idHashMap.keySet() LIMIT :idHashMap.size()]) { if( !String.isEmpty(msg.IdHash__c ) ) { idHashMap.put(msg.Id, msg.IdHash__c); } }
        // get Offer hashes
        for (DisputeOffer__c offer : [SELECT Id, IdHash__c FROM DisputeOffer__c WHERE Id IN :idHashMap.keySet() LIMIT :idHashMap.size()]) { if( !String.isEmpty(offer.IdHash__c ) ) { idHashMap.put(offer.Id, offer.IdHash__c); } }
        
        Boolean isUpdate = (null != oldDisputeMap);
        // Assign Hash strings if the Id field(s) is changing
        for ( DisputeMessage__c msg : newDisputes )
        {
            if( isUpdate ) // compensate for re-assignment of related records.
            {
                DisputeMessage__c oldDispute = oldDisputeMap.get(msg.Id);
                if (String.isEmpty(msg.IdHash__c)) { msg.IdHash__c = CryptoUtility.getIdHash(msg); msgHashMap.put( msg.IdHash__c, msg ); }
                if (!String.isEmpty(msg.ContactCreatedBy__c)) { msg.CreatedByHash__c = (oldDispute.ContactCreatedBy__c != msg.ContactCreatedBy__c || String.isEmpty(msg.CreatedByHash__c) ) ? CryptoUtility.hashId(msg.ContactCreatedBy__c) : msg.CreatedByHash__c; }
                if (!String.isEmpty(msg.ContactSharedWith__c) ) { msg.SharedWithHash__c = ( oldDispute.ContactSharedWith__c != msg.ContactSharedWith__c || String.isEmpty( msg.SharedWithHash__c ) ) ? CryptoUtility.hashId( msg.ContactSharedWith__c ) : msg.SharedWithHash__c; }
                if (!String.isEmpty(msg.DisputeOffer__c)) { String offerHash = idHashMap.get(msg.DisputeOffer__c); msg.OfferHash__c = ( oldDispute.DisputeOffer__c != msg.DisputeOffer__c || String.isEmpty( msg.OfferHash__c ) ) ? offerHash : msg.OfferHash__c; }
                if (!String.isEmpty(msg.DisputeMessage__c)  ) { String parentHash = idHashMap.get(msg.DisputeMessage__c); msg.ParentMessageHash__c = ( oldDispute.DisputeMessage__c != msg.DisputeMessage__c || String.isEmpty(msg.ParentMessageHash__c) ) ? parentHash : msg.ParentMessageHash__c; }
            } 
            else
            {
                msg.IdHash__c = String.isEmpty( msg.IdHash__c ) ? CryptoUtility.getIdHash( msg ) : msg.IdHash__c;
                msgHashMap.put( msg.IdHash__c, msg );
                msg.CreatedByHash__c = ( !String.isEmpty( msg.ContactCreatedBy__c )  ) ? CryptoUtility.hashId( msg.ContactCreatedBy__c ): msg.CreatedByHash__c;
                msg.SharedWithHash__c = ( !String.isEmpty( msg.ContactSharedWith__c )  ) ? CryptoUtility.hashId( msg.ContactSharedWith__c ) : msg.SharedWithHash__c;
                if( !String.isEmpty(msg.DisputeOffer__c ) ) { msg.OfferHash__c = idHashMap.get(msg.DisputeOffer__c); }
                if( !String.isEmpty(msg.DisputeMessage__c ) ) { msg.ParentMessageHash__c = idHashMap.get(msg.DisputeMessage__c); }

            }
        }

        // unique key insurance, rarity of hash duplication, least of all test code coverage
        if( !msgHashMap.isEmpty() ) { for( DisputeMessage__c existMsg : [SELECT IdHash__c FROM DisputeMessage__c WHERE IdHash__c IN :msgHashMap.keySet() LIMIT :msgHashMap.size()] ) { DisputeMessage__c msg = msgHashMap.get( existMsg.IdHash__c ); msg.IdHash__c = 'M'+ CryptoUtility.generateRandomString(13); } }
    }

}