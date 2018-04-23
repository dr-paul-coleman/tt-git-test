/*
Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2016-12-19     Scott Purcell          Created
1.1		  2017-07-05     Travis Oliver          Added routeWorkItem
2.0		  2017-10-11	 Jared Kennington	    New Trigger structure
2.1       2017-12-07     Jared Kennington       
========+============+=================+================================================
*/
trigger WorkItemTrigger on WorkItem__c (before insert, before update, after update) {
		ThumbtackTriggerHandlerBase.doTrigger( 'WorkItemTriggerHandler');
}