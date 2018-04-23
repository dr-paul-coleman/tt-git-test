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
  global class ScheduledOverbudgetCheckboxReset Implements Schedulable
{
    //use for prod-every sunday night at 11:58pm
    //public static String CRON_EXP = '0 58 23 ? * 7L';
    global void execute(SchedulableContext sc)
    {
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                FROM CronTrigger WHERE Id = :sc.getTriggerId()];
		system.debug('ct.id: '+ct.Id);
        //System.assertEquals(CRON_EXP, ct.CronExpression);
        //System.assertEquals(0, ct.TimesTriggered);
        unCheck();
    }
    
    public void unCheck()
    {
        List<Account> acc = [Select Id,OverBudgetEmailSent__c,SendOverbudgetEmail__c From Account Where SendOverbudgetEmail__c =: True OR OverBudgetEmailSent__c =:true];
        for(Account a:acc)
        {
        	a.OverBudgetEmailSent__c = false;
        	a.SendOverbudgetEmail__c = false;
        }
        update acc;
        
    }
}
/*ScheduledOverbudgetCheckboxReset m = new ScheduledOverbudgetCheckboxReset();
//use for prod-every sunday night at 11:58pm
//String sch = '0 58 23 ? * 7L';
//use for testing
String sch = '0 20 * * * ?';
String jobID = system.schedule('unCheck Job', sch, m);
System.Debug('jobID: '+jobID);
*/
// System.abortJob('08eg000000MokBr');