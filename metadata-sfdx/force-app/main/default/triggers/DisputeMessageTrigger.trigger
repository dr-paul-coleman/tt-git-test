/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/25/18      pcoleman           Created
========+============+=================+===============================================*/
trigger DisputeMessageTrigger on DisputeMessage__c (before insert, after insert, before update)
{
    ThumbtackTriggerHandlerBase.doTrigger( 'DisputeMessageTriggerHandler' );
}