/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       3/7/18      pcoleman           Created a Queueable to publish platform events
========+============+=================+===============================================*/
public without sharing class SolutionCenterEventQueueable implements Queueable
{
    public class SolutionCenterEventException extends Exception {}
    public enum Event_object {  DISPUTE, OFFER, MSG, FILE_MESSAGE }


    String msgId;
    String versionId;
    String disputeId;
    String offId;
    Event_object type;

    public SolutionCenterEventQueueable( String fileVersionId, Id disputeMessageId )
    {
        if( String.isEmpty(fileVersionId) || String.isEmpty(disputeMessageId) ) { throw new SolutionCenterEventException('fileVersionId and disptuteMessageId are required fields'); }
        this.msgId = disputeMessageId;
        this.versionId = fileVersionId;
        this.type = Event_object.FILE_MESSAGE;
    }

    public void execute(QueueableContext ctx)
    {

    }

}