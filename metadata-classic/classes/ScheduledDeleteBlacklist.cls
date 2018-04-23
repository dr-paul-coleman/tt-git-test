/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reacced.                ###                                 *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
******************************************************************************** 
Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       04/10/2017     Scott Purcell          Created
========+============+=================+===============================================*/
global class ScheduledDeleteBlacklist implements Schedulable {
	public static String CRON_EXP = '0 0 0 3 9 ? 2022';//for testing

	
	global void execute(SchedulableContext sc) 
	{
		DeleteBlacklisted.blackListed();
	}
}
/*//this is run in the execute anonymous window
ScheduledDeleteBlacklist m = new ScheduledDeleteBlacklist();
String sch = '0 0 4 * * ?';every 4hrs
String jobID = system.schedule('getworkitems every 4hrs', sch, m);
*/