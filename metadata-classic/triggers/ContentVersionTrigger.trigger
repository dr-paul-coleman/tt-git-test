/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-05   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

trigger ContentVersionTrigger on ContentVersion (after insert, after update)
{
	ThumbtackTriggerHandlerBase.doTrigger('ContentVersionTriggerHandler');
}