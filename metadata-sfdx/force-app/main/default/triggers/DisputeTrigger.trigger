/*
  Copyright (c) 2015, 2016, 2017 Thumbtack.  All rights reserved.

 Change List:
 ------------

 Version    Date     Author            Description
 =======+===========+=================+=================================
 2.0     2017-10-04  Paul Coleman      Created
 =======+===========+=================+=================================*/
trigger DisputeTrigger on Dispute__c ( before insert, before update, after insert, after update )
{

    ThumbtackTriggerHandlerBase.doTrigger( 'DisputeTriggerHandler' );

}