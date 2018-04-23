/*

   Copyright (c) 2017 Thumbtack. All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       04/04/2017     Scott Purcell          Created
2.0       10/20/1027   Paul Coleman      Refactored new Queueables
========+============+=================+===============================================*/
global class ScheduledGetQuote implements Schedulable
{

	/**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Kick off remote Becquerel External Object sync.
    * @param SchedulableContext Note used.
    */
	global void execute(SchedulableContext sc)
	{
         new BeckyQuotesSyncQueueable().execute( NULL );
	}
}