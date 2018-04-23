/*
  Copyright (c) 2015, 2016, 2017 Thumbtack.  All rights reserved.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 2.0     2017-10-04  Paul Coleman      Refactored for Trigger Framework
 =======+===========+=================+=================================*/
trigger AccountTrigger on Account (after insert, after update, before insert, before update) {

	ThumbtackTriggerHandlerBase.doTrigger( 'AccountTriggerHandler' );

}