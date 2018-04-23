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
public with sharing class DeleteBlacklistedTest {
	 @isTest static void  deleteBlacklistedTest1()
	{
		
        User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        
        System.runAs(testUser) 
        {
            WorkItem__c w = new WorkItem__c();
			w.rev_usr_user_id_reviewed__c = 1234;
			w.Type__c ='Blacklisted Number';
			insert w;

			Account acc = new Account(
            Name='Chester Tester',
            Phone='8018675309',
            usr_first_name__c = 'Chester',
            usr_last_name__c = 'Tester',
            usr_email__c = 'chester@bogus.thumbtack.com',
            usr_user_id__c = 1234,
            WhiteListed__c = true
            );
            insert acc;
         
            Test.startTest();
            	DeleteBlacklisted.Blacklisted();
            
            Test.stopTest();
            List<WorkItem__c> wiList = [Select Id From WorkItem__c];
            system.debug(wiList.size());
            system.assertEquals(0,wiList.size());
		}
	}
}