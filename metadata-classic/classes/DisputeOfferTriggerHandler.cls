/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/25/18      pcoleman           Created
========+============+=================+===============================================*/
public without sharing class DisputeOfferTriggerHandler extends ThumbtackTriggerHandlerBase
{

    // Recursion Prevention Flags
    private static Boolean isInBeforeProcessing = false;
    private static Boolean isPublishingEvents = false;

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    // SHARED FINAL TRIGGER processing function
    public override void doFinalProcessing( ThumbtackTriggerContext ctx )
    {
        Boolean isBeforeInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeInsert;
        Boolean isBeforeUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeUpdate;
        Boolean isAfterUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.afterUpdate;
        Boolean isAfterInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.afterInsert;
        Boolean isUpdate = isBeforeUpdate || isAfterUpdate;

        DisputeOffer__c[] newRecords = (DisputeOffer__c[])ctx.newRecords;
        Map<Id, DisputeOffer__c> oldRecordsMap = (Map<Id, DisputeOffer__c>)ctx.oldRecordsMap;

        try
        {
            if (isBeforeInsert || isBeforeUpdate)
            {
                this.syncLastChangeDates(newRecords, oldRecordsMap);
            }

        }
        finally
        {
            if( isAfterUpdate || isAfterInsert)  //Status updates
            {
                if( !isPublishingEvents )
                {
                    isPublishingEvents = true;
                    this.doPlatformEvents(newRecords, (isAfterUpdate ? oldRecordsMap : null));//make sure platform events is the last step
                }
            }
        }

        if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED OFFERS in doFINAL: ' + JSON.serialize(newRecords)); }
        if( Test.isRunningTest() && isUpdate ) { System.debug(LoggingLevel.WARN, 'OLD OFFERS VALUES in doFINAL: ' + JSON.serialize(oldRecordsMap.values())); }
    }

    //SHARED BEFORE INSERT/UPDATE functions
    public override void doBeforeProcessing( ThumbtackTriggerContext ctx )
    {
        if( !isInBeforeProcessing )
        {
            isInBeforeProcessing = true;
            try {
                Boolean isBeforeInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeInsert;
                Boolean isBeforeUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeUpdate;
                if (isBeforeInsert || isBeforeUpdate)
                {
                    DisputeOffer__c[] newRecords = (DisputeOffer__c[])ctx.newRecords;
                    Map<Id, DisputeOffer__c> oldRecordsMap = (Map<Id, DisputeOffer__c>)ctx.oldRecordsMap;

                    this.hashIds( newRecords, oldRecordsMap );

                    if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED OFFERS in doBEFORE: ' + JSON.serialize(newRecords)); }
                    if( Test.isRunningTest() && isBeforeUpdate ) { System.debug(LoggingLevel.WARN, 'OLD OFFER VALUES in doBEFORE: ' + JSON.serialize(oldRecordsMap.values())); }
                }
            } finally {  isInBeforeProcessing = false; }
        }
    }


    /**
    * @author Paul Coleman
    * @date 2018-01-22
    * @description Ensure every new DisputeOffer record gets a hash value(s) for SolutionCenter purposes.
    * @param DisputeOffer__c[] the Trigger.new array.
    * @param Map<Id, DisputeOffer__c> the Trigger.old map.
    */
    private void hashIds( DisputeOffer__c[] newOffers, Map<Id, DisputeOffer__c> oldDisputeMap ) //BEFORE INSERT/UPDATE
    {
        Boolean isUpdate = (null != oldDisputeMap);
        Map<Id, String> idHashMap = new Map<Id, String>();
        Map<String, DisputeOffer__c> offerHashMap = new Map<String, DisputeOffer__c>();
        for (DisputeOffer__c trgOffer : newOffers)
        {
            if ( !String.isEmpty( trgOffer.Dispute__c) )
            {
                idHashMap.put( trgOffer.Dispute__c, NULL);
            }
        }

        // get Message hashes
        for (Dispute__c dispute : [SELECT Id, IdHash__c FROM Dispute__c WHERE Id IN :idHashMap.keySet() LIMIT :idHashMap.size()])
        {
            if( !String.isEmpty(dispute.IdHash__c ) ) { idHashMap.put(dispute.Id, dispute.IdHash__c); }
        }

        for ( DisputeOffer__c offer : newOffers )
        {
            if( isUpdate )
            {
                DisputeOffer__c oldDispute = oldDisputeMap.get( offer.Id );
                if (String.isEmpty(offer.IdHash__c)) { offer.IdHash__c = CryptoUtility.getIdHash(offer); offerHashMap.put( offer.IdHash__c, offer ); }
                if (!String.isEmpty(offer.ContactCreatedBy__c)) { offer.CreatedByHash__c = ( oldDispute.ContactCreatedBy__c != offer.ContactCreatedBy__c  || String.isEmpty( offer.CreatedByHash__c ) ) ? CryptoUtility.hashId( offer.ContactCreatedBy__c ): offer.CreatedByHash__c; }
                if (!String.isEmpty(offer.ContactSharedWith__c) ) { offer.SharedWithHash__c = ( oldDispute.ContactSharedWith__c != offer.ContactSharedWith__c || String.isEmpty( offer.SharedWithHash__c ) ) ? CryptoUtility.hashId( offer.ContactSharedWith__c ) : offer.SharedWithHash__c; }
                if (!String.isEmpty(offer.Dispute__c)) { String disputeHash = idHashMap.get(offer.Dispute__c); offer.DisputeHash__c =  ( oldDispute.Dispute__c != offer.Dispute__c || String.isEmpty( offer.DisputeHash__c ) ) ? disputeHash:  offer.DisputeHash__c; }

            }
            else
            {
                offer.IdHash__c = String.isEmpty( offer.IdHash__c ) ? CryptoUtility.getIdHash(offer) : offer.IdHash__c;
                offer.DisputeHash__c = ( !String.isEmpty( offer.Dispute__c )  ) ? CryptoUtility.hashId( offer.Dispute__c ) : offer.DisputeHash__c;
                offer.InitiatorMessageCount__c = (null == offer.InitiatorMessageCount__c) ? 0 : offer.InitiatorMessageCount__c;
                offer.ResponderMessageCount__c = (null == offer.ResponderMessageCount__c) ? 0 : offer.ResponderMessageCount__c;
                offer.CreatedByHash__c = ( !String.isEmpty( offer.ContactCreatedBy__c )  ) ? CryptoUtility.hashId( offer.ContactCreatedBy__c ): offer.CreatedByHash__c;
                offer.SharedWithHash__c = ( !String.isEmpty( offer.ContactSharedWith__c )  ) ? CryptoUtility.hashId( offer.ContactSharedWith__c ) : offer.SharedWithHash__c;
                if( !String.isEmpty(offer.Dispute__c ) ) { offer.DisputeHash__c = idHashMap.get(offer.Dispute__c); }
            }
        }

        // unique key insurance, rarity conflicts will occur, least of all test code coveraged
        if( !offerHashMap.isEmpty() ) { for( DisputeOffer__c existMsg : [SELECT IdHash__c FROM DisputeOffer__c WHERE IdHash__c IN :offerHashMap.keySet() LIMIT :offerHashMap.size() ] ) { DisputeOffer__c offer = offerHashMap.get( existMsg.IdHash__c ); offer.IdHash__c = 'O'+ CryptoUtility.generateRandomString(13); } }

    }

    /**
    * @author Paul Coleman
    * @date 2018-02-05
    * @description Set history of status changes.
    * @param DisputeOffer__c[] The trigger new array.
    * @param Map<Id, DisputeOffer__c> the trigger oldMap.
    */
    private void syncLastChangeDates( DisputeOffer__c[] offers,  Map<Id, DisputeOffer__c> oldOfferMap ) //BEFORE INSERT & UPDATE
    {
        Boolean isInsert = ( null == oldOfferMap );
        Datetime now = Datetime.now();
        for( DisputeOffer__c offer : offers )
        {
            DisputeOffer__c oldOffer = isInsert ? null : oldOfferMap.get( offer.Id );
            offer.LastStatusChangeDate__c = isInsert? now: ( oldOffer.Status__c != offer.Status__c ? now : offer.LastStatusChangeDate__c );
            offer.PriorStatus__c =  isInsert ? offer.Status__c : ( oldOffer.Status__c != offer.Status__c ? oldOffer.Status__c : offer.PriorStatus__c);
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-05
    * @description Publish platform events on status changes, which can occur from Scheduled job, SC UI, or by an agent.
    * @param DisputeOffer__c[] The trigger new array.
    * @param Map<Id, DisputeOffer__c> the trigger oldMap.
    */
    private void doPlatformEvents( DisputeOffer__c[] offers,  Map<Id, DisputeOffer__c> oldOfferMap ) //AFTER UPDATE
    {
        Boolean isInsert = (null == oldOfferMap);
        DisputeOffer__c[] statusUpdates = (isInsert ? offers : new DisputeOffer__c[0]);
        if (!isInsert)
        {
            for (DisputeOffer__c offer : offers)
            {
                DisputeOffer__c oldOffer = oldOfferMap.get(offer.Id);
                if (oldOffer.Status__c != offer.Status__c)
                {
                    statusUpdates.add(offer);
                }
            }
        }

        if (!statusUpdates.isEmpty())
        {
            SolutionCenterUtility.publishSolutionCenterEvents(statusUpdates);
        }
    }

}