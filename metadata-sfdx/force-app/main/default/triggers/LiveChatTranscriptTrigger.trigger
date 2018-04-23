/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-09-29   Mendel Guillaume    Created
  2.0      2018-02-01   Mendel Guillaume    Trigger framework
  ========+============+=================+===============================================
*/

trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
	ThumbtackTriggerHandlerBase.doTrigger('LiveChatTranscriptTriggerHandler');
}