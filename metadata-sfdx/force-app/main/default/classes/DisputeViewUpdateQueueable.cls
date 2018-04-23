/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       3/7/18      pcoleman           Created, A queuable class to update 'Lasted Viewed' stats on Dispute records
========+============+=================+===============================================*/
public without sharing class DisputeViewUpdateQueueable implements Queueable
{
    private String disputeHash;
    private Dispute__c[] disputes;
    private Id contactUsersId;

    public DisputeViewUpdateQueueable(Dispute__c[] dispts, Id contactId)
    {
        this.disputes = dispts;
        this.contactUsersId = contactId;
    }

    public void execute(System.QueueableContext ctx)
    {
        SObject[] updates = new DisputeLastView__c[0];
        
        Datetime now = System.now();
        // assess configurable threshold, default to 60 if not set
        String updateMinutesLbl = Label.SolutionCenterLastViewedTimeIntervalMinutes;
        Integer updateMinutes = String.isEmpty(updateMinutesLbl) ? 60 : Integer.valueOf(updateMinutesLbl);

        // set threshold
        Datetime cutoffDatetime = now.addMinutes(-1 * updateMinutes);

        for (Dispute__c dispute : this.disputes )
        {
            if (null != dispute.DisputeLastView__c)
            {
                // determine if threshold warrants an update
                Boolean updateInitiatorView = null == dispute.DisputeLastView__r.InitiatorLastViewedDate__c || dispute.DisputeLastView__r.InitiatorLastViewedDate__c < cutoffDatetime;
                Boolean updateResponderView = null == dispute.DisputeLastView__r.ResponderLastViewedDate__c || dispute.DisputeLastView__r.ResponderLastViewedDate__c < cutoffDatetime;

                // determine who is the viewer of the dispute data (by active portal user)
                if (this.contactUsersId == dispute.InitiatorContact__c && updateInitiatorView)
                {
                    // UPDATE Dispute's DisputeLastView extension record if last change was within threshold
                    updates.add( new DisputeLastView__c(Id = dispute.DisputeLastView__c, InitiatorLastViewedDate__c = now) ); 
                }
                else if (this.contactUsersId == dispute.ResponderContact__c && updateResponderView)
                {
                    updates.add( new DisputeLastView__c(Id = dispute.DisputeLastView__c, ResponderLastViewedDate__c = now) );
                }

            }
        }

        if ( !updates.isEmpty() )
        {
            String errorString = '';
            for( Database.SaveResult updateResult : Database.update(updates, false) )
            {
                if (!updateResult.success)
                {
                    errorString += updateResult.errors[0].message + '\n';
                }
            }

            if( !String.isEmpty(errorString) )
            {
                TackBotUtility.postTackLogErrorMessage( errorString, 'DisputeViewUpdateQueueable.execute()');
            }
        }
    }
}