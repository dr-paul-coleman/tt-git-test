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
https://thumbtack--dev.cs17.my.salesforce.com
  */
  @istest
public class ScheduledOverbudgetCheckboxResetTest {
    public static String CRON_EXP = '0 58 23 ? * 7L';
     static testMethod void test1()
    {
        
		User testUser = [SELECT id FROM User WHERE Username like 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {

            
            Account a = new Account(SendOverbudgetEmail__c = true,OverBudgetEmailSent__c=true,Name='Chester Tester',Phone='8018675309',usr_first_name__c='Chester',usr_last_name__c='Tester',usr_email__c='chester@bogus.thumbtack.com',usr_user_id__c=-2);
            insert a;       
            
        
            Test.startTest();
    		    String jobId = System.schedule('ScheduledOverbudgetCheckboxReset',
    		    CRON_EXP, 
    	        new ScheduledOverbudgetCheckboxReset());

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