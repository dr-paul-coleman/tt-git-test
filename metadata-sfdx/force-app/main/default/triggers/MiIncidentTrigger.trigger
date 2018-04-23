/*
   Copyright (c) 2016 Thumbtack. All rights reserved.

 Change List:                                                               
 ------------
 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-06-08  Travis Oliver     Created (w/Paul Coleman)
 1.1     2016-07-02  Paul Coleman      Refactored with Trigger Handler
 1.2.    09-04-2017  Scott Purcell	    MTS project refactor
 2.0     2017-10-17  Paul Coleman	   Refactored for Trigger Framework
 =======+===========+=================+=================================*/
trigger MiIncidentTrigger on MIIncident__c (before insert, before update, after insert, after update, after delete)
{
    ThumbtackTriggerHandlerBase.doTrigger( 'MiIncidentTriggerHandler' );
}