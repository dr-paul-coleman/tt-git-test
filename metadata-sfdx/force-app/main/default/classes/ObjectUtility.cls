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
  

Change List:
------------
Version      Date          Author            Description
========+============+=================+========================================
1.0       2016-12-28     Scott Purcell          Created
========+============+=================+========================================*/
@isTest
public with sharing class ObjectUtility {

public static User testUser {
	get
	{
		if(testUser == null)
		{
			testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
		}
		return testUser;
	}
		set;
	}
	public static Id MIRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
	public static Account acc {get;set;}
	public static Contact con {get;set;}
//*********************************************************************** Lead *********************************************************************** 
//	public static Lead createLead()
//	{
//		Lead l = new Lead(
//                FirstName = 'Test First Name ' ,
//                LastName = 'Test Last Name ' ,
//                Company = 'Test Company ' ,
//                Status = 'New',
//                OwnerId = testUser.Id,
//                sav_available_service_id__c = 1,
//                ThumbtackId__c = 1,
//                RecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Outreach Lead').getRecordTypeId()
//            );
//		return l;
//	}
//	public static List<Lead> createLeadBulk(Integer amountToBeCreated)
//	{
//		List<Lead> leadList = new List<Lead>();
//		for(Integer i = 0;i<amountToBeCreated;i++)
//		{
//			Lead l = new Lead(
//                FirstName = 'Test First Name ' +i,
//                LastName = 'Test Last Name ' ,
//                Company = 'Test Company ' ,
//                Status = 'New',
//                OwnerId = testUser.Id,
//                sav_available_service_id__c = 1,
//                ThumbtackId__c = 1,
//                RecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Outreach Lead').getRecordTypeId()
//            );
//            leadList.add(l);
//		}
//
//		return leadList;
//	}

//*********************************************************************** Case *********************************************************************** 
public static Case createCase()
{
	
	con = createContact();
	Case c = new Case(AccountId=acc.Id,Status='New',ContactId=con.Id,RecordTypeId=MIRTId);
	return c;
}
public static List<Case> createCaseBulk(Integer amountToBeCreated)
{
	
	con = createContact();
	List<Case> caseList = new List<Case>();
	for(Integer i = 0;i<amountToBeCreated;i++)
	{
		Case c = new Case(AccountId=acc.Id,Status='New',ContactId=con.Id,RecordTypeId=MIRTId);
		caseList.add(c);
	}
	return caseList;
}

//*********************************************************************** Contact *********************************************************************** 
public static Contact createContact()
{
	Account ac = createAccount();
	insert ac;
	con = new Contact(LastName='Tester1',FirstName='Chester1',AccountId=ac.Id);
	return con;
}
public static List<Contact> createContactBulk(Integer amountToBeCreated)
{
	system.debug('acc: '+acc);
	if(acc==null)acc = createAccount();
	insert acc;
	List<Contact> contactList = new List<Contact>();
	for(Integer i = 0;i<amountToBeCreated;i++)
	{
		Contact ct = new Contact(LastName='Tester2',FirstName='Chester2: '+i,AccountId=acc.Id);
		contactList.add(ct);
	}
	return contactList;
}
//*********************************************************************** Account *********************************************************************** 

	public static Account createAccount()
	{
		system.debug('acc: '+acc);
		if(acc==null)
		 	acc = new Account(Name='Chester Tester 2',Phone='8018675309',usr_first_name__c='Chester2',usr_last_name__c='Tester2',usr_email__c='chester2@bogus.thumbtack.com',usr_user_id__c=1);      
		return acc;
	}
	public static List<Account> createAccountBulk(Integer amountToBeCreated)
	{
		List<Account> accList = new List<Account>();
		for(Integer i = 0;i<amountToBeCreated;i++)
		{
			Account ac = new Account(Name='Chester Tester3: ' + i,Phone='8018675309',usr_first_name__c='Chester3' + i,usr_last_name__c='Tester3',usr_email__c='chester3@bogus.thumbtack.com',usr_user_id__c=1);
	        accList.add(ac);
		}
		return accLIst;
	}

//*********************************************************************** Service__c *********************************************************************** 

	public static Service__c createService()
	{
		Account accc = createAccount();
		insert accc;
            service__c service = new service__c(
                Name = 'Test Name ',
                ProAccount__c = accc.Id,
                OwnerId = testUser.Id,
                sav_available_service_id__c = 1,
                sav_usr_user_id__c = 1,
                usr_first_name__c = 'First Name',
                usr_last_name__c = 'Last Name'
            );
          
        return service;
	}
	public static List<Service__c> createServiceBulk(Integer amountToBeCreated)
	{
		Account accc = createAccount();
		insert accc;
		List<service__c> services = new List<service__c>();
        //Note to test service insertion, there should always be less services created from this list than leads updated later in the test. 
        for(Integer i=0;i<amountToBeCreated;i++) 
        {
            service__c s = new service__c(
                Name = 'Test Name ' + i,
                ProAccount__c = accc.Id,
                OwnerId = testUser.Id,
                sav_available_service_id__c = i,
                sav_usr_user_id__c = i,
                usr_first_name__c = 'First Name',
                usr_last_name__c = 'Last Name'
            );
            services.add(s);
        } 
        return services;
	}

//*********************************************************************** CustomerSuccessGuidance__c *********************************************************************** 

	public static CustomerSuccessGuidance__c createCustomerSuccessGuidance()
	{
		Account acoun = createAccount();
		insert acoun;
		CustomerSuccessGuidance__c g = new CustomerSuccessGuidance__c();
		g.RecordTypeID = CustomerSuccessGuidance__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Success Flag').getRecordTypeId();
		g.Name = 'Quoting Service';
		g.OwnerId = testUser.Id;
		g.Account__c = acoun.Id;
		g.CSFlagType__c = 'Quoting Service Program';
		g.FlagExplanation__c = 'This professional is currently working with the Quoting Service program.';
		
		return g;
	}
	public static List<CustomerSuccessGuidance__c> createCustomerSuccessGuidanceBulk(Integer amountToBeCreated)
	{
		Account acoun = createAccount();
		insert acoun;
		List<CustomerSuccessGuidance__c> csgList = new List<CustomerSuccessGuidance__c>();
		for(Integer i = 0;i<amountToBeCreated;i++)
		{
			CustomerSuccessGuidance__c g = new CustomerSuccessGuidance__c();
			g.RecordTypeID = CustomerSuccessGuidance__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Success Flag').getRecordTypeId();
			g.Name = 'Quoting Service';
			g.OwnerId = testUser.Id;
			g.Account__c = acoun.Id;
			g.CSFlagType__c = 'Quoting Service Program';
			g.FlagExplanation__c = 'This professional is currently working with the Quoting Service program.';
			csgList.add(g);
		}
		
		
		return csgList;
	}

//*********************************************************************** createGroupAndQueue *********************************************************************** 

	public static QueuesObject createGroupAndQueue()
	{
		
		    Group testGroup = new Group(Name='test group', Type='Queue');
	        insert testGroup;
	        
        
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            insert testQueue;
            
	    }
	   return testQueue;
	}
	
}