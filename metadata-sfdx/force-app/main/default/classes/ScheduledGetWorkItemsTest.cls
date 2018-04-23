/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
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
1.0       04/04/2017     Scott Purcell          Created
========+============+=================+===============================================*/
@isTest
private class ScheduledGetWorkItemsTest {
	
	public static String CRON_EXP = '0 58 23 ? * 7L';
     static testMethod void test1()
    {
        
    User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
            Test.startTest();
            String jobId = System.schedule('ScheduledGetWorkItems',
            CRON_EXP, 
              new ScheduledGetWorkItems());

              // Get the information from the CronTrigger API object
              CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
              NextFireTime FROM CronTrigger WHERE id = :jobId];

                // Verify the expressions are the same
              //System.assertEquals(TestScheduledApex.CRON_EXP, 
              // ct.CronExpression);

              // Verify the job has not run
              System.assertEquals(0, ct.TimesTriggered);
          Test.stopTest();
        }
    }
	
}