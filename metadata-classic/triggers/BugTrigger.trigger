/*******************************************************************************

Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     01-13-2017  Scott Purcell      Created
2.0		11-07-2017	Jared Kennington	Converted to new trigger structure
=======+===========+=================+================================================
*/
trigger BugTrigger on Bug__c (before update, after insert)
{
	ThumbtackTriggerHandlerBase.doTrigger( 'BugTriggerHandler');
}