/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2/7/18      pcoleman           Created to handle Periodic Dispute-related
                                            processes, such as expiration dates.
========+============+=================+===============================================*/
public with sharing class ScheduledDoDisputeBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful
{

    //NOTE: Code coverage for this class is handled in DisputeTriggerHandlerTest

    public void execute(SchedulableContext ctx)
    {
        Database.executeBatch( new ScheduledDoDisputeBatch(), 2000 );
        //TO SCHEDULE EVERY 4 hours:
        //System.schedule('Dispute Batch', '0 0 */4 ? * *', new ScheduledDoDisputeBatch());
        //TO SCHEDULE EVERY 24 hours at 11pm:
        //System.schedule('Dispute Batch', '0 0 23 ? * *', new ScheduledDoDisputeBatch());

    }

    public void execute(Database.BatchableContext ctx, SObject[] disputes)
    {
        Datetime now = Datetime.now();
        Date tomorrow = System.today().addDays(1);
        Map<Id,SObject> expiredUpdates = new Map<Id, SObject>();
        for( SObject dispt : disputes )
        {
            Dispute__c dispute =  (Dispute__c)dispt;
            // Dispute  RULE 12
            Boolean isAwaitingInitatorExpired = ( NULL == dispute.InitiatorConfirmationDate__c && tomorrow > dispute.InitiatorConfirmationDueDate__c &&
                'Awaiting'.equalsIgnoreCase( dispute.Status__c ) &&
                'Initiator confirmation needed'.equalsIgnoreCase( dispute.Stage__c ) );

            // Dispute RULE 13
            Boolean isAwaitingResponderExpired = ( NULL == dispute.ResponderFirstActionDate__c && tomorrow > dispute.ResponderFirstActionDueDate__c &&
                'Awaiting'.equalsIgnoreCase( dispute.Status__c ) &&
                'Responder first action needed'.equalsIgnoreCase( dispute.Stage__c ) );

            // Dispute RULE 15
            Boolean isInProgressExpired = ( NULL != dispute.DisputeResolutionDueDate__c && tomorrow > dispute.DisputeResolutionDueDate__c &&
                'In progress'.equalsIgnoreCase( dispute.Status__c ) &&
                'Offer pending'.equalsIgnoreCase( dispute.Stage__c ) );

            if( isAwaitingInitatorExpired || isAwaitingResponderExpired || isInProgressExpired )
            {
                expiredUpdates.put( dispute.Id, new Dispute__c( Id = dispute.Id, DisputeExpirationDate__c = now, Status__c = 'Under review', Stage__c = 'Expired' ) );

                for( DisputeOffer__c offer : dispute.DisputeOffers__r ) { if( 'Pending'.equalsIgnoreCase( offer.Status__c ) && !expiredUpdates.containsKey(offer.Id) ) { expiredUpdates.put( offer.Id,  new DisputeOffer__c( Id = offer.Id, Status__c = 'Expired' ) ); } }
            }

            // Dispute-Offer RULE 5
            // check for all other Offer-related expirations
            for( DisputeOffer__c offer : dispute.DisputeOffers__r )
            {
                if( NULL != offer.DisputeOfferExpirationDate__c &&
                    tomorrow > offer.DisputeOfferExpirationDate__c  &&
                    'Pending'.equals(offer.Status__c ) )
                {
                    if( !expiredUpdates.containsKey(dispute.Id) ) { expiredUpdates.put( dispute.Id, new Dispute__c( Id = dispute.Id, Status__c = 'Under review', Stage__c = 'Expired' ) ); }
                    if( !expiredUpdates.containsKey(offer.Id) ) { expiredUpdates.put( offer.Id,  new DisputeOffer__c( Id = offer.Id, Status__c = 'Expired' ) ); }
                }

            }
        }

        String errString = '';
        SObject[] retries = new SObject[0];
        if (!expiredUpdates.isEmpty())
        {
            SObject[] updateRecords = expiredUpdates.values();
            updateRecords.sort();
            Integer recIndex = 0;
            for (Database.SaveResult saveResult : Database.update(updateRecords, false))
            {
                if (!saveResult.success)
                {
                    if( saveResult.errors[0].message.contains('unable to obtain exclusive access to this record')) { retries.add(updateRecords[recIndex].clone(true)); }
                    else { errString += saveResult.errors[0].message + '\n'; }
                }
                recIndex++;
            }
        }
        if( !String.isEmpty(errString) ) { TackBotUtility.postTackLogErrorMessage( errString, 'ScheduledDoDisputeBatch.execute()'); }

        if(!retries.isEmpty()) { QueueableUtility.handleQueueable( new DMLQueueable(retries,DMLQueueable.Operation.UPDATES) ); }

    }

    public void finish(Database.BatchableContext ctx) {}

    public Database.QueryLocator start(Database.BatchableContext ctx)
    {
        return Database.getQueryLocator( [SELECT Id,
                ResponderFirstActionDate__c,
                ResponderFirstActionDueDate__c,
                InitiatorConfirmationDate__c,
                InitiatorConfirmationDueDate__c,
                DisputeResolutionDueDate__c,
                Status__c,
                Stage__c,
                (SELECT Id, Status__c, ResolutionCompleteByDate__c, DisputeOfferExpirationDate__c FROM DisputeOffers__r)
            FROM Dispute__c] );
    }


}