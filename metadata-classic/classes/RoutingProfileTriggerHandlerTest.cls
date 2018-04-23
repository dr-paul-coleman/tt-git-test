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
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     01-13-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@istest
public with sharing class RoutingProfileTriggerHandlerTest 
{
	
	@isTest static void testThumbtackIDToPRofile()
	{
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');
        Account acc = new Account();
        acc.Name = 'Chester Tester';
        acc.Phone = '8018675309';
        acc.usr_first_name__c = 'Chester';
        acc.usr_last_name__c = 'Tester';
        acc.usr_email__c = 'chester@bogus.thumbtack.com';
        acc.usr_user_id__c = -1;
        insert acc;
        Lead l = new Lead(
        		Email = 'test@tester.com',
        		Phone = '7775556666',
                Account__c = acc.Id,
                FirstName = 'Test First Name ',
                LastName = 'Test Last Name ' ,
                Company = 'Test Company ' ,
                OwnerId = testUser.Id,
                sav_available_service_id__c = 1,
                ThumbtackId__c = 1234             
                );
        insert l;
        RoutingProfile__c rp = new RoutingProfile__c();
		rp.Experiment__c = true;
		rp.Email__c = 'test@tester.com';
		rp.Phone__c = '7775556666';
		rp.Name = 'Test';
		rp.Lead__c = l.Id;
		insert rp;
		System.runAs(testUser) 
        {
			Test.startTest();
				rp.Phone9__c = '8887779999';
				update rp;
			Test.stopTest();
			List<RoutingProfile__c> rp1 = [Select Id,ThumbtackId__c,Lead__c From RoutingProfile__c LIMIT 1];
			for(RoutingProfile__c rp2: rp1)
			{
				system.assertEquals(1234,rp2.ThumbtackId__c);
			}
			system.debug('rp1: '+rp1);
			
		}
	}
	@isTest static void testDelete()
	{
		User testUser = [SELECT Id,Name FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        //insert new JiraAPI__c(Name = 'default',Endpoint__c = 'http://api.salesforce.com/foo/bar',Password__c = 'pass',UserName__c = 'user');
        Account acc = new Account();
        acc.Name = 'Chester Tester';
        acc.Phone = '8018675309';
        acc.usr_first_name__c = 'Chester';
        acc.usr_last_name__c = 'Tester';
        acc.usr_email__c = 'chester@bogus.thumbtack.com';
        acc.usr_user_id__c = -1;
        insert acc;
        Lead l = new Lead(
        		Email = 'test@tester.com',
        		Phone = '7775556666',
                Account__c = acc.Id,
                FirstName = 'Test First Name ',
                LastName = 'Test Last Name ' ,
                Company = 'Test Company ' ,
                OwnerId = testUser.Id,
                sav_available_service_id__c = 1,
                ThumbtackId__c = 1234             
                );
        insert l;

		RoutingProfile__c p = new RoutingProfile__c();
		p.Lead__c = l.Id;
		p.Experiment__c = true;
		p.Email__C = 'test@tester.com';
		p.Phone__c = '7775556666';
		p.Name = 'Test';
		p.CreditFisher__c = false;
		p.CustomerContact__c = false;
		p.Enterprise__c = false;
		p.FrequentCaller__c = false;
		p.ProAssistant__c = false;
		p.ProAssistOnboarding__c = false;
		p.QuotingService__c = false;
		p.TopPro__c = false;
		insert p;
		System.runAs(testUser) 
        {
			Test.startTest();
			p.Experiment__c = false;
			update p;
			Test.stopTest();
			List<RoutingProfile__c> profiles = [Select Id From RoutingProfile__c];
			system.debug(profiles);
			system.assert(profiles.size()==0);
		}
	}
}