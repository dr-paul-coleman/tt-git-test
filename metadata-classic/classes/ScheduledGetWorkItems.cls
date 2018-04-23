/*
	Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       04/04/2017     Scott Purcell          Created
1.1		  10/17/2017	 Jared Kennington	    Update execute call with new AskBecky router
========+============+=================+===============================================*/

global class ScheduledGetWorkItems implements Schedulable {
	// System.schedule('Sync WorkItems with Becky every four hours', '0 0 */4 ? * *', new ScheduledGetWorkItems());
	
	global void execute(SchedulableContext sc) 
	{
		new BeckyWorkItemSyncQueueable().execute(null);
	}
}