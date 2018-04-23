/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       01/09/18      pcoleman           Created
========+============+=================+===============================================*/
public without sharing class DisputeTriggerHandler extends ThumbtackTriggerHandlerBase
{
    public static final Id CONFIDENTIAL_RECORD_TYPE_ID = Dispute__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
    public static final Id SOLUTION_CENTER_DISPUTE_RECORD_TYPE_ID = Dispute__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center Dispute').getRecordTypeId();

    // Recursion Prevention Flags
    private static Boolean isInBeforeProcessing = false;
    private static Boolean isInBeforeInsertProcessing = false;
    private static Boolean isInBeforeUpdateProcessing = false;
    private static Boolean isPublishingEvents = false;

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
    public override void doFinalProcessing( ThumbtackTriggerContext ctx )
    {
        Boolean isBeforeInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeInsert;
        Boolean isBeforeUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeUpdate;
        Boolean isAfterUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.afterUpdate;
        Boolean isAfterInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.afterInsert;
        Boolean isUpdate = isBeforeUpdate || isAfterUpdate;

        Dispute__c[] newRecords = (Dispute__c[]) ctx.newRecords;
        Map<Id, Dispute__c> oldRecordsMap = (Map<Id, Dispute__c>) ctx.oldRecordsMap;
        try
        {
            if (isBeforeInsert || isBeforeUpdate)
            {
                this.syncLastChangeDates(newRecords, oldRecordsMap);
            }

            if (isAfterInsert || isAfterUpdate)
            {
                this.syncMIStageAndStatus(newRecords, (isAfterUpdate ? oldRecordsMap : null));

            }
        }
        finally
        {
            // LAST, do Platform events on Status/Stage updates
            if (isAfterUpdate)
            {
                if(!isPublishingEvents )
                {
                    isPublishingEvents = true;
                    this.doPlatformEvents(newRecords, oldRecordsMap); //make sure platform events is the last step
                }
            }
        }

        if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED DISPUTES in doFINAL: ' + JSON.serialize(newRecords)); }
        if( Test.isRunningTest() && isUpdate ) { System.debug(LoggingLevel.WARN, 'OLD DISPUTE VALUES in doFINAL: ' + JSON.serialize(oldRecordsMap.values())); }
    }

    public override void doBeforeProcessing( ThumbtackTriggerContext ctx )
    {
        //SHARED BEFORE INSERT/UPDATE functions
        if( !isInBeforeProcessing )
        {
            isInBeforeProcessing = true;
            try {
                Boolean isBeforeInsert = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeInsert;
                Boolean isBeforeUpdate = ctx.dmlEvent == ThumbtackTriggerContext.TEvent.beforeUpdate;
                Dispute__c[] newRecords = (Dispute__c[]) ctx.newRecords;
                Map<Id, Dispute__c> oldRecordsMap = isBeforeInsert ? null : (Map<Id, Dispute__c>) ctx.oldRecordsMap;

                if( Test.isRunningTest() ) { System.debug(LoggingLevel.WARN, 'TRIGGERED DISPUTES in doBEFORE: ' + JSON.serialize(newRecords)); }
                if( Test.isRunningTest() && isBeforeUpdate ) { System.debug(LoggingLevel.WARN, 'OLD DISPUTE VALUES in doBEFORE: ' + JSON.serialize(oldRecordsMap.values())); }

                if (isBeforeInsert || isBeforeUpdate)
                {
                    this.hashIds( newRecords, oldRecordsMap );
                    this.setDisputeDefaults(newRecords, oldRecordsMap);
                    this.assignDisputeOwner(newRecords, oldRecordsMap);  // NOTE: creates a portal user for dispute Initiator on-the-fly as necessary
                }
            } finally {  isInBeforeProcessing = false; }
        }
    }

    public override void onBeforeInsert(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeInsertProcessing)
        {
            isInBeforeInsertProcessing = true;
            try {
                Dispute__c[] newRecords = (Dispute__c[])ctx.newRecords;

                this.createDisputeLastViewExtensionRecords( newRecords );
            } finally {  isInBeforeInsertProcessing = false; }
        }

    }

    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeUpdateProcessing)
        {
            isInBeforeUpdateProcessing = true;
            try {
                Dispute__c[] newRecords = (Dispute__c[])ctx.newRecords;
                Map<Id, Dispute__c> newRecordsMap = (Map<Id, Dispute__c>)ctx.newRecordsMap;
                Map<Id, Dispute__c> oldRecordsMap = (Map<Id, Dispute__c>)ctx.oldRecordsMap;

                this.doStatusUnderReviewChange( newRecordsMap, oldRecordsMap );
                this.stopAllOffers( newRecords, oldRecordsMap );
            } finally {  isInBeforeUpdateProcessing = false; }
        }
    }

    // *** END Base trigger handler overrides

    /**
    * @author Paul Coleman
    * @date 2018-01-22
    * @description Ensure every new Dispute record gets a hash value for SolutionCenter purposes.
    * @param  Dispute__c[] the Trigger.new array.
    * @param  Map<Id, Dispute__c> the Trigger.oldMap.
    */
    private void hashIds( Dispute__c[] newDisputes, Map<Id, Dispute__c> oldDisputeMap ) //BEFORE PROCESSING
    {
        Boolean isUpdate = (null != oldDisputeMap);
        Map<String, Dispute__c> disputeHashMap = new Map<String, Dispute__c>();
        for ( Dispute__c dispute : newDisputes )
        {
            if( isUpdate )
            {
                Dispute__c oldDispute = oldDisputeMap.get( dispute.Id );
                if (String.isEmpty(dispute.IdHash__c)) { dispute.IdHash__c = CryptoUtility.getIdHash(dispute); disputeHashMap.put( dispute.IdHash__c, dispute ); }
                dispute.InitiatorHash__c = ( !String.isEmpty( dispute.InitiatorContact__c ) && ( oldDispute.InitiatorContact__c != dispute.InitiatorContact__c || String.isEmpty(dispute.InitiatorHash__c) ) ) ? CryptoUtility.hashId( dispute.InitiatorContact__c ): dispute.InitiatorHash__c;
                dispute.ResponderHash__c = ( !String.isEmpty( dispute.ResponderContact__c ) && ( oldDispute.ResponderContact__c != dispute.ResponderContact__c || String.isEmpty( dispute.ResponderHash__c ) ) ) ? CryptoUtility.hashId( dispute.ResponderContact__c ) : dispute.ResponderHash__c;
            }
            else
            {
                dispute.IdHash__c = String.isEmpty( dispute.IdHash__c ) ? CryptoUtility.getIdHash(dispute) : dispute.IdHash__c;
                dispute.InitiatorHash__c =  !String.isEmpty( dispute.InitiatorContact__c ) ? CryptoUtility.hashId( dispute.InitiatorContact__c ): null;
                dispute.ResponderHash__c =  !String.isEmpty( dispute.ResponderContact__c ) ? CryptoUtility.hashId( dispute.ResponderContact__c ) : null;
            }
        }

        // unique key insurance. rarity that hash conflicts will occur, least of test code coverage
        if( !disputeHashMap.isEmpty() ) { for( Dispute__c existDispute : [SELECT IdHash__c FROM Dispute__c WHERE IdHash__c IN :disputeHashMap.keySet() LIMIT :disputeHashMap.size()] ) { Dispute__c dispute = disputeHashMap.get( existDispute.IdHash__c ); dispute.IdHash__c = 'D'+ CryptoUtility.generateRandomString(13); } }

    }


    /**
    * @author Paul Coleman
    * @date 2018-02-05
    * @description Ensure every new Dispute record gets a Name value in aggregate of related contact names.
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> The trigger old map.
    */
    private void setDisputeDefaults( Dispute__c[] disputes, Map<Id, Dispute__c> oldDisputeMap ) //BEFORE PROCESSING
    {
        Boolean isInsert = (null == oldDisputeMap);
        // 1] gather experience ids and contact ids
        Map<Id, DisputeExperience__c> experienceMap = new Map<Id, DisputeExperience__c>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        for( Dispute__c dispt: disputes )
        {
            if( !String.isEmpty( dispt.DisputeExperience__c ) ) { experienceMap.put( dispt.DisputeExperience__c, null ); }
            if( !String.isEmpty( dispt.InitiatorContact__c ) ) { contactMap.put( dispt.InitiatorContact__c, null ); }
            if( !String.isEmpty( dispt.ResponderContact__c ) ) { contactMap.put( dispt.ResponderContact__c, null ); }
        }

        contactMap = new Map<Id,Contact>( [SELECT Id, Name, AccountId, Account.user_pk_id__c FROM Contact WHERE Id IN :contactMap.keySet() LIMIT :contactMap.size() ] );

        // 2] get related experience default values
        for( DisputeExperience__c exp: [SELECT Id, MaxDaysForCalendarPicker__c, MaxOfDaysAllowedForDispute__c, MaxOfDaysForInitiatorToConfirm__c, MaxOfDaysForInitiatorToReply__c, MaxOfDaysForResponderFirstAction__c, MaxOfDaysForResponderToReply__c, MaxOfInitiatorMessagesAllowed__c, MaxOfInitiatorOffersAllowed__c, MaxOfResponderMessagesAllowed__c, MaxOfResponderOffersAllowed__c, MaxofDaysforOffer__c FROM DisputeExperience__c WHERE Id IN :experienceMap.keySet() LIMIT: experienceMap.size()] )
        {
            experienceMap.put( exp.Id, exp );
        }

        // 3] set dispute default values
        Datetime now = Datetime.now();
        for( Dispute__c dispute : disputes )
        {
            String initiatorName = '';
            String responderName = '';

            Contact initiator = contactMap.get( dispute.InitiatorContact__c );
            Contact responder = contactMap.get( dispute.ResponderContact__c );
            if( null != initiator )
            {
                initiatorName = initiator.Name;
                dispute.InitiatorAccount__c = initiator.AccountId;
                dispute.InitiatorPkId__c = initiator.Account.user_pk_id__c;
            }
            if( null != responder )
            {
                responderName = responder.Name;
                dispute.ResponderAccount__c = responder.AccountId;
                dispute.ResponderPkId__c = responder.Account.user_pk_id__c;
            }

            String nameString = 'Dispute between ' + initiatorName + ' and ' + responderName;
            dispute.Name = nameString;

            // load up experience template values on dispute
            DisputeExperience__c experience = experienceMap.get( dispute.DisputeExperience__c );
            Dispute__c oldDispute = isInsert ? null : oldDisputeMap.get( dispute.Id );
            if( null != experience && ( isInsert? true: ( dispute.DisputeExperience__c != oldDispute.DisputeExperience__c ) )  )
            {
                dispute.MaxDaysForCalendarPicker__c = experience.MaxDaysForCalendarPicker__c;
                dispute.MaxOfDaysAllowedForDispute__c = experience.MaxOfDaysAllowedForDispute__c;
                dispute.MaxOfDaysForInitiatorToConfirm__c = experience.MaxOfDaysForInitiatorToConfirm__c;
                dispute.MaxOfDaysForInitiatorToReply__c = experience.MaxOfDaysForInitiatorToReply__c;
                dispute.MaxOfDaysForResponderFirstAction__c = experience.MaxOfDaysForResponderFirstAction__c;
                dispute.MaxOfDaysForResponderToReply__c = experience.MaxOfDaysForResponderToReply__c;
                dispute.MaxofDaysforOffer__c = experience.MaxofDaysforOffer__c;
                dispute.MaxOfInitiatorMessagesAllowed__c = experience.MaxOfInitiatorMessagesAllowed__c;
                dispute.MaxOfInitiatorOffersAllowed__c = experience.MaxOfInitiatorOffersAllowed__c;
                dispute.MaxOfResponderMessagesAllowed__c = experience.MaxOfResponderMessagesAllowed__c;
                dispute.MaxOfResponderOffersAllowed__c = experience.MaxOfResponderOffersAllowed__c;
            }

            // initialize total count fields
            dispute.InitiatorTotalOfferCount__c = (null == dispute.InitiatorTotalOfferCount__c) ? 0 : dispute.InitiatorTotalOfferCount__c;
            dispute.InitiatorTotalMessageCount__c = (null == dispute.InitiatorTotalMessageCount__c) ? 0 : dispute.InitiatorTotalMessageCount__c;
            dispute.ResponderTotalOfferCount__c = (null == dispute.ResponderTotalOfferCount__c) ? 0 : dispute.ResponderTotalOfferCount__c;
            dispute.ResponderTotalMessageCount__c = (null == dispute.ResponderTotalMessageCount__c) ? 0 : dispute.ResponderTotalMessageCount__c;

            // EVAL THE RULES FOR SETTING THE `READY` STATE and set dates based on default dispute values as set by the experience template
            Boolean isStatusReady = 'Awaiting'.equalsIgnoreCase( dispute.Status__c );
            Boolean isStageReady = 'Initiator confirmation needed'.equalsIgnoreCase( dispute.Stage__c );
            Boolean areFieldsReady = !String.isEmpty( dispute.InitiatorContact__c ) && !String.isEmpty( dispute.ResponderContact__c ) && null == dispute.InitiatorConfirmationDueDate__c;
            //only set the dates if they haven't been set before on this record
            if( areFieldsReady && isStatusReady && isStageReady && null == dispute.DisputeStartDate__c )
            {
                dispute.DisputeStartDate__c = now;
                dispute.InitiatorConfirmationDueDate__c = (null == dispute.MaxOfDaysForInitiatorToConfirm__c)? now : now.addDays( dispute.MaxOfDaysForInitiatorToConfirm__c.intValue() );
                dispute.DisputeResolutionDueDate__c = (null == dispute.MaxOfDaysAllowedForDispute__c) ? now : now.addDays( dispute.MaxOfDaysAllowedForDispute__c.intValue() );
            }

            //Set closed date if being closed
            dispute.DisputeClosedDate__c = ( isInsert && 'Closed'.equalsIgnoreCase( dispute.Status__c ) ? now : (( 'Closed'.equalsIgnoreCase( dispute.Status__c ) && !'Closed'.equalsIgnoreCase( oldDispute.Status__c ) ) ?  now:  dispute.DisputeClosedDate__c) );
        }
    }


    /**
    * @author Paul Coleman
    * @date 2018-02-05
    * @description Ensure ClosedDate is set when Status is closed.
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> The trigger oldMap.
    */
    private void stopAllOffers( Dispute__c[] disputes, Map<Id, Dispute__c> oldDisputeMap ) //BEFORE UPDATE
    {
        DisputeOffer__c[] offersForUpdate = new DisputeOffer__c[0];
        Set<Id> disputesForOfferQuery = new Set<Id>();
        for( Dispute__c dispute : disputes )
        {
            Dispute__c oldDispute = oldDisputeMap.get( dispute.Id );
            Boolean isStopping = 'Stopped'.equalsIgnoreCase( dispute.Stage__c ) && !'Stopped'.equalsIgnoreCase( oldDispute.Stage__c );
            if( isStopping && 'Under review'.equalsIgnoreCase( dispute.Status__c ) )
            {
                disputesForOfferQuery.add( dispute.Id );
            }
        }

        // Stop related Offers
        for( DisputeOffer__c[] offers : [SELECT Id, Status__c FROM DisputeOffer__c WHERE Dispute__c IN :disputesForOfferQuery ] )
        {
            for( DisputeOffer__c offer: offers )
            {
                if ('Pending'.equalsIgnoreCase(offer.Status__c))
                {
                    offer.Status__c = 'Stopped';
                    offersForUpdate.add( offer );
                }
            }
        }

        // synchronous updates to ensure SC front-end integrity
        // minimizing the potential for row lock contentions via background dml
        if( !offersForUpdate.isEmpty() ) { new DMLQueueable( offersForUpdate, DMLQueueable.Operation.UPDATES ).execute(null); }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-05
    * @description Set history of status/stage changes and dates.
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> the trigger oldMap.
    */
    private void syncLastChangeDates( Dispute__c[] disputes,  Map<Id, Dispute__c> oldDisputeMap ) //DO FINAL
    {
        Boolean isInsert = ( null == oldDisputeMap );

        Datetime now = Datetime.now();
        for( Dispute__c dispute : disputes )
        {
            Dispute__c oldDispute = isInsert ? null : oldDisputeMap.get( dispute.Id );
            dispute.LastStatusChangeDate__c = isInsert ? now: ( oldDispute.Status__c != dispute.Status__c ? now : dispute.LastStatusChangeDate__c );
            dispute.LastStageChangeDate__c = isInsert ? now: ( oldDispute.Stage__c != dispute.Stage__c ? now : dispute.LastStageChangeDate__c );
            dispute.PriorStatus__c = isInsert ? dispute.Status__c : ( oldDispute.Status__c != dispute.Status__c ? oldDispute.Status__c : dispute.PriorStatus__c) ;
            dispute.PriorStage__c = isInsert ? dispute.Stage__c : ( oldDispute.Stage__c != dispute.Stage__c ? oldDispute.Stage__c : dispute.PriorStage__c) ;
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-09
    * @description Handle the agent-based change for Status from `Under review` to `In progress` or `Awaiting`.
    * @param Map<Id, Dispute__c> the Trigger.newMap.
    * @param Map<Id, Dispute__c> the Trigger.oldMap.
    */
    private void doStatusUnderReviewChange(Map<Id, Dispute__c> disputesMap, Map<Id, Dispute__c> oldDisputeMap) //AFTER UPDATE
    {
        if ( 'Standard'.equals( UserInfo.getUserType() ) ) //only process changes by Agents
        {
            Datetime now = System.now();
            SObject[] offerUpdates = new SObject[0];
            String[] targetStatus  = new String[]{'awaiting','in progress'};
            Map<Id,DisputeOffer__c[]> offerMap = new Map<Id, DisputeOffer__c[]>();
            for( Dispute__c parent: [SELECT Id, (SELECT Id, Status__c, PriorStatus__c FROM DisputeOffers__r ORDER BY CreatedDate DESC) FROM Dispute__c WHERE Id IN :disputesMap.keySet() LIMIT :disputesMap.size() ] )
            {
                offerMap.put( parent.Id, parent.DisputeOffers__r );
            }

            for( Dispute__c dispute : disputesMap.values() )
            {
                DisputeOffer__c[] offers = offerMap.get(dispute.Id);
                DisputeOffer__c latestOffer = (null == offers || offers.isEmpty())? null : offers[0];
                Dispute__c oldDispute = oldDisputeMap.get( dispute.Id );
                Integer maxOfferDays = (null == dispute.MaxofDaysforOffer__c)? 0: dispute.MaxofDaysforOffer__c.intValue();
                Datetime nowPlusMaxDays = now.addDays( maxOfferDays );
                String status = String.isEmpty( dispute.Status__c )? '' : dispute.Status__c.toLowerCase();
                if( Test.isRunningTest() )
                {
                    System.debug(LoggingLevel.WARN, 'DISPUTE: ' + JSON.serialize(dispute));
                    System.debug(LoggingLevel.WARN, 'OLD DISPUTE: ' + JSON.serialize(oldDispute));
                    System.debug(LoggingLevel.WARN, 'OFFERS: ' + JSON.serialize(offers));
                }
                // is status transitioning from Under review to a target active status?
                if( 'Under review'.equalsIgnoreCase( oldDispute.Status__c ) && targetStatus.contains( status ) )
                {
                    // Is Stage being manually changed from stop to the prior status
                    if( 'Stopped'.equalsIgnoreCase(oldDispute.Stage__c) && !'Stopped'.equalsIgnoreCase(dispute.Stage__c) )
                    {
                        if( null != latestOffer )
                        {
                            offerUpdates.add( new DisputeOffer__c( Id = latestOffer.Id, Status__c = 'Pending', DisputeOfferExpirationDate__c = nowPlusMaxDays ) );
                        }
                    }

                    // Is Status being updated from `Under review` to `Awaiting`?
                    if( 'Awaiting'.equalsIgnoreCase(dispute.Status__c) )
                    {
                        //IF Initiator didn’t confirm in time
                        if ('Initiator confirmation needed'.equalsIgnoreCase(dispute.PriorStage__c))
                        {
                            dispute.Stage__c = 'Initiator confirmation needed';
                            dispute.InitiatorConfirmationDueDate__c = now.addDays((null == dispute.MaxOfDaysForInitiatorToConfirm__c) ? 0 : dispute.MaxOfDaysForInitiatorToConfirm__c.intValue());
                        }
                        // IF Responder didn’t take first action in time
                        else if ('Expired'.equalsIgnoreCase(oldDispute.Stage__c) && 'Responder first action needed'.equalsIgnoreCase(dispute.Stage__c))
                        {
                            dispute.ResponderFirstActionDueDate__c = now.addDays( (null == dispute.MaxOfDaysForResponderFirstAction__c) ? 0 : dispute.MaxOfDaysForResponderFirstAction__c.intValue() );
                            //adjust most recent offer if expired
                            if( null != latestOffer && 'Expired'.equalsIgnoreCase(latestOffer.Status__c ) )
                            {
                                offerUpdates.add( new DisputeOffer__c( Id = latestOffer.Id, Status__c = 'Pending', DisputeOfferExpirationDate__c = nowPlusMaxDays ) );
                            }
                        }
                    }
                    // Is Status being updated from `Under review` to `In progress`?
                    else if ( 'In progress'.equalsIgnoreCase(dispute.Status__c) )
                    {
                        //IF Initiator had withdrawn the dispute
                        if ( 'Withdrawn'.equalsIgnoreCase(oldDispute.Stage__c) )
                        {
                            Integer numberOfOffers = dispute.DisputeOffers__r.size();
                            // DEPENDING ON THE OFFER COUNT, RESET Status__c and Stage__c by rule:
                            // 1] when offer count < 2, all initiator prep work is still yet to be done. aka status is overridden
                            //          to `Awaiting` not `In progress`
                            dispute.Status__c = ( numberOfOffers < 2 )? 'Awaiting': dispute.Status__c;
                            // 2] when offer count < 2, Stage is one of two awaiting values depending on a count of 0 or 1
                            dispute.Stage__c = ( 0 == numberOfOffers )? 'Initiator confirmation needed': (1 == numberOfOffers ? 'Responder first action needed' : dispute.Stage__c);
                            // 3] else, offer count is great then 2 -- w/ status already being `In progress`,
                            //          then set Stage to `Offer pending`.
                            dispute.Stage__c = ( numberOfOffers > 1 )? 'Offer pending': dispute.Stage__c;

                            //adjust most recent offer if withdrawn
                            if( null != latestOffer && 'Withdrawn'.equalsIgnoreCase(latestOffer.Status__c ) )
                            {
                                offerUpdates.add( new DisputeOffer__c( Id = latestOffer.Id, Status__c = latestOffer.PriorStatus__c, DisputeOfferExpirationDate__c = nowPlusMaxDays ) );
                            }
                        }
                        // IF Initiator and Responder came to an agreement
                        else if ('Agreement made'.equalsIgnoreCase(oldDispute.Stage__c) && ('Offer pending'.equalsIgnoreCase(dispute.Stage__c) ) )
                        {
                            if( null != latestOffer && 'Accepted'.equalsIgnoreCase(latestOffer.Status__c) )
                            {
                                offerUpdates.add( new DisputeOffer__c( Id = latestOffer.Id, DisputeOfferExpirationDate__c = nowPlusMaxDays ) );
                            }
                        }
                        // IF Dispute or most recent Dispute Offer expired
                        else if ('Expired'.equalsIgnoreCase(oldDispute.Stage__c) && ('Offer pending'.equalsIgnoreCase(dispute.Stage__c) ) )
                        {
                            if( null != latestOffer && 'Expired'.equalsIgnoreCase(latestOffer.Status__c) )
                            {
                                offerUpdates.add(new DisputeOffer__c(Id = latestOffer.Id, Status__c = 'Pending', DisputeOfferExpirationDate__c = nowPlusMaxDays ) );
                            }
                        }
                    }
                }
            }
            
            if(!offerUpdates.isEmpty() )
            {
                String errStr = '';
                for( Database.SaveResult offerResult: Database.update(offerUpdates, false) ) { if( !offerResult.success ) { errStr += offerResult.errors[0].message + '\n'; } }
                if( !String.isEmpty(errStr) ) { TackBotUtility.postTackLogErrorMessage( errStr, 'DisputeTriggerHandler.doStatusUnderReviewChange()');  }
            }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-09
    * @description Create a DisputeLastView__c extension record for each new Dispute.
    *               These records keep track of dispute party `last viewed` dates.
    * @param Dispute__c[] The trigger new array.
    */
    public void createDisputeLastViewExtensionRecords(Dispute__c[] disputes) //BEFORE INSERT
    {
        DisputeLastView__c[] newViews = new DisputeLastView__c[0];
        for( Dispute__c dispute : disputes )
        {
            newViews.add( new DisputeLastView__c(Name = dispute.Name + ' View Stats' ) );
        }

        String dbErrors = '';
        Integer disputeIndex = 0;
        for( Database.SaveResult insertResult : Database.insert( newViews, false) )
        {
            if( insertResult.isSuccess() )
            {
                Dispute__c child =  disputes[disputeIndex];
                child.DisputeLastView__c = insertResult.id;
            }
            else { dbErrors += insertResult.errors[0].message; }

            disputeIndex++;
        }

        if( !String.isEmpty(dbErrors) ) { TackBotUtility.postTackLogErrorMessage( dbErrors, 'DisputeTriggerHandler.createDisputeLastViewExtensionRecords()'); }

    }

    /**
    * @author Paul Coleman
    * @date 2018-01-09
    * @description As appropriate, propogate Status/Stage changes to Mi Incident record.
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> the Trigger.oldMap.
    */
    private void syncMIStageAndStatus(Dispute__c[] disputes, Map<Id, Dispute__c> oldDisputeMap) //AFTER INSERT/UPDATE
    {
        Boolean isInsert = null == oldDisputeMap;
        MIIncident__c[] incidentsForUpdate = new MIIncident__c[0];

        for( Dispute__c dispute : disputes )
        {
            Dispute__c oldDispute = isInsert ? null : oldDisputeMap.get( dispute.Id );
            Boolean isStatusChanged = isInsert || dispute.Status__c != oldDispute.Status__c;
            Boolean isStageChanged = isInsert || dispute.Stage__c != oldDispute.Stage__c;
            if( null != dispute.MIIncident__c && ( isStatusChanged || isStageChanged ) ) { incidentsForUpdate.add( new MIIncident__c(Id = dispute.MIIncident__c, SolutionCenterStage__c = dispute.Status__c + ' > ' + dispute.Stage__c) ); }
        }

        if( !incidentsForUpdate.isEmpty() ) { QueueableUtility.handleQueueable( new DMLQueueable(incidentsForUpdate, DMLQueueable.Operation.UPDATES)); }
    }

     /**
    * @author Paul Coleman
    * @date 2018-01-09
    * @description Ensure that a dispute that is created by an Agent is appropriately assigned/shared with
    *       the related pro/customer (contact) via OwnerId (creating missing portal Users if necessary).
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> the Trigger.oldMap.
    */
    private void assignDisputeOwner(Dispute__c[] disputes, Map<Id, Dispute__c> oldDisputes) //BEFORE PROCESSING
    {
        // Ignore all code when the context User is a portal/community user.
        // This code is intended to be executed when an Agent creates a dispute
        if ( 'Standard'.equals( UserInfo.getUserType() ) )
        {
            Boolean isUpdate = null != oldDisputes;
            Map<Id,User> contactUserMap = new Map<Id,User>();

            // gather non-null contactIds
            for ( Dispute__c dispute : disputes )
            {
                // if contact is not null (and if update, the contact is being first assigned or re-assigned)
                if( null != dispute.InitiatorContact__c && (isUpdate? dispute.InitiatorContact__c != oldDisputes.get(dispute.Id).InitiatorContact__c: true) )
                {
                    contactUserMap.put(dispute.InitiatorContact__c, null);
                }
            }

            // get existing User records for InitiatorContact Ids, if any
            for( User portalUser : [SELECT Id, ContactId from User WHERE ContactId IN :contactUserMap.keySet()])
            {
                contactUserMap.put( portalUser.ContactId, portalUser );
            }

            // find the contacts that do not already have User records (from query above)
            Id[] contactsMissingUsers = new Id[0];
            for( Id contactId : contactUserMap.keySet())
            {
                if( null == contactUserMap.get(contactId)  )
                {
                    contactsMissingUsers.add( contactId );
                }
            }

            // get Account Ids for contacts that do not have related User records (contact ids gathered above)
            Set<Id> accountIdsForNewUsers = new Set<Id>();
            for( Contact ttContact : [SELECT Id, AccountId, Account.user_pk_id__c FROM Contact WHERE Id IN :contactsMissingUsers])
            {
                if( null != ttContact.Account.user_pk_id__c ) //pk id required for User.FederationIdentifier
                {
                    accountIdsForNewUsers.add(ttContact.AccountId);
                }
            }

            // create missing portal users
            User[] newUsers = new ThumbtackUserSSOProvisioner().createThumbackUsers( accountIdsForNewUsers );
            insert newUsers;
            for( User newUser : newUsers )
            {
                contactUserMap.put( newUser.ContactId, newUser );
            }

            // Share dispute records with their portal users by OwnerId
            for( Dispute__c triggeredDispute : disputes )
            {
                if( null != triggeredDispute.InitiatorContact__c )
                {
                    User newOwner = contactUserMap.get(triggeredDispute.InitiatorContact__c);
                    if (null != newOwner && triggeredDispute.OwnerId != newOwner.Id)
                    {
                        triggeredDispute.OwnerId = newOwner.Id;
                    }
                }
            }

        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-09
    * @description Publish platform events on status changes, which can occur from Scheduled job, SC UI, or by an agent.
    * @param Dispute__c[] The trigger new array.
    * @param Map<Id, Dispute__c> the trigger oldMap.
    */
    private void doPlatformEvents( Dispute__c[] disputes,  Map<Id, Dispute__c> oldDisputeMap ) //DO FINAL
    {
       Dispute__c[] statusUpdates = new Dispute__c[0];
       for (Dispute__c dispute : disputes)
       {
           Dispute__c oldDispute = oldDisputeMap.get(dispute.Id);
           Boolean isStatusStageChange = oldDispute.Status__c != dispute.Status__c || oldDispute.Stage__c != dispute.Stage__c;
           Boolean isDescriptionChange = oldDispute.Description__c != dispute.Description__c;
           if (isStatusStageChange || isDescriptionChange)
           {
               statusUpdates.add(dispute);
           }
       }

       if (!statusUpdates.isEmpty())
       {
           SolutionCenterUtility.publishSolutionCenterEvents(statusUpdates);
       }
    }


}