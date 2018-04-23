/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/25/18      pcoleman           Created
========+============+=================+===============================================*/
trigger DisputeOfferTrigger on DisputeOffer__c (after insert, before update, before insert, after update)
{
    ThumbtackTriggerHandlerBase.doTrigger( 'DisputeOfferTriggerHandler' );
}