/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       3/7/18      pcoleman           Created, A queuable class to update message
                                            counts on Dispute and Offer records
========+============+=================+===============================================*/
public without sharing class DisputeMessageCountQueueable implements Queueable
{
    private DisputeMessage__c newMsg;

    public DisputeMessageCountQueueable(DisputeMessage__c msg)
    {
        this.newMsg = msg.clone(true);
    }

    public void execute(System.QueueableContext ctx)
    {
        SObject[] countUpdates = new SObject[0];
        // do dispute message counts by Dispute and Offer related to this.newMsg
        if (null != this.newMsg.Dispute__c)
        {
            //Get Dispute-related messages by Dispute.Id (msg.Dispute__c)
            for (Dispute__c dispute : [SELECT Id, (SELECT Id, ContactCreatedBy__c FROM DisputeMessages__r WHERE RecordType.Name = 'Message'), InitiatorTotalMessageCount__c, ResponderTotalMessageCount__c, InitiatorContact__c, ResponderContact__c FROM Dispute__c WHERE Id = :newMsg.Dispute__c LIMIT 1])
            {
                Integer initiatorCount = 0;
                Integer responderCount = 0;
                // Count messages for the parent dispute by Initiator vs Responder
                for (DisputeMessage__c msg : dispute.DisputeMessages__r)
                {
                    Boolean isInitiator = msg.ContactCreatedBy__c == dispute.InitiatorContact__c;
                    Boolean isResponder = msg.ContactCreatedBy__c == dispute.ResponderContact__c;
                    if (isInitiator) { initiatorCount++; }
                    else if (isResponder) { responderCount++; } // data integrity/security insurance vs a stand-alone `else`
                }
                // add dispute to records for update
                countUpdates.add(new Dispute__c(Id = dispute.Id, InitiatorTotalMessageCount__c = initiatorCount, ResponderTotalMessageCount__c = responderCount));
            }
        }

        // do offer msg counts
        if (null != newMsg.DisputeOffer__c)
        {
            // Get Offer-related messages by Offer.Id (msg.Offer__c)
            for (DisputeOffer__c offer : [SELECT Id, (SELECT Id, ContactCreatedBy__c FROM DisputeMessages__r WHERE RecordType.Name = 'Message'), InitiatorMessageCount__c, ResponderMessageCount__c, Dispute__r.InitiatorContact__c, Dispute__r.ResponderContact__c FROM DisputeOffer__c WHERE Id = :newMsg.DisputeOffer__c LIMIT 1])
            {
                Integer initiatorCount = 0;
                Integer responderCount = 0;
                // Count messages for the parent offer by Initiator vs Responder
                for (DisputeMessage__c msg : offer.DisputeMessages__r)
                {
                    Boolean isInitiator = msg.ContactCreatedBy__c == offer.Dispute__r.InitiatorContact__c;
                    Boolean isResponder = msg.ContactCreatedBy__c == offer.Dispute__r.ResponderContact__c;
                    if (isInitiator) { initiatorCount++; } else if (isResponder) { responderCount++; } // data integrity/security insurance vs a stand-alone `else`
                }
                countUpdates.add(new DisputeOffer__c(Id = offer.Id, InitiatorMessageCount__c = initiatorCount, ResponderMessageCount__c = responderCount));
            }
        }

        if (!countUpdates.isEmpty())
        {
            QueueableUtility.handleQueueable(new DMLQueueable(countUpdates, DMLQueueable.Operation.UPDATES));
        }
    }
}