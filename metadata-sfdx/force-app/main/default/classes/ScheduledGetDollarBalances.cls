/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/26/17      pcoleman           Created
========+============+=================+===============================================*/
global with sharing class ScheduledGetDollarBalances implements Schedulable
{
    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Kick off a remote Becquerel External Object sync.
    * @param SchedlableContaxt No used.
    */
    global void execute(SchedulableContext sc)
    {
        new BeckyDollarBalanceSyncQueueable().execute( NULL );
    }
}