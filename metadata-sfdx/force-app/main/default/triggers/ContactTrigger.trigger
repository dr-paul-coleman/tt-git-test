/**
  Copyright (c) 2017 Thumbtack  All rights reserved.

  Change List:
  ------------

  Version    Date     Author            Description
  =======+===========+=================+=================================
  1.0     2017-12-14  Mendel Guillaume  Created
  =======+===========+=================+=================================
 */

trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
	ThumbtackTriggerHandlerBase.doTrigger('ContactTriggerHandler');
}