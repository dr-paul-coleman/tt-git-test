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
1.0       2016-12-12     Scott Purcell          Created
========+============+=================+========================================*/
@istest
public class EmailFilterTriggerHandlerTest 
 { 
	public static testMethod void OnBeforeInsert()
    {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
        	Test.startTest();
            	insert new EmailFilter__c(Name='Test Filter',Regex__c='^Testing$',ExampleSubject__c='Testing',EmailFilterMatched__c='Testing',FilterActive__c=true);
            Test.stopTest();
        }
    }
    public static testMethod void OnBeforeInsertBulk()
    {
    	List<EmailFilter__c> filterList = new List<EmailFilter__c>();
    	User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        for(Integer i=0;i<200;i++)
        {
        	EmailFilter__c fil = new EmailFilter__c(Name='Test Filter',Regex__c='^Testing$',ExampleSubject__c='Testing',EmailFilterMatched__c='Testing',FilterActive__c=true);
        	filterList.add(fil);
        }
        System.runAs(testUser) 
        {
        	Test.startTest();
            	insert filterList;
            Test.stopTest();
        }
        
    }
	//******************************************
   /* public static testMethod void OnAfterInsert()
    {
    	
    }
    public static testMethod void OnAfterInsertBulk()
    {
      for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
	//******************************************
    public static testMethod void OnBeforeUpdate()
    {
    	User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
        	
            EmailFilter__c fil = new EmailFilter__c(Name='Test Filter',Regex__c='^Testing$',ExampleSubject__c='Testing',EmailFilterMatched__c='Testing',FilterActive__c=true);
            insert fil;
            Test.startTest();
            	Update fil;
            Test.stopTest();
        }
        
    }
    public static testMethod void OnBeforeUpdateBulk()
    {
        List<EmailFilter__c> filterList = new List<EmailFilter__c>();
    	User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        for(Integer i=0;i<200;i++)
        {
        	EmailFilter__c fil = new EmailFilter__c(Name='Test Filter',Regex__c='^Testing$',ExampleSubject__c='Testing',EmailFilterMatched__c='Testing',FilterActive__c=true);
        	filterList.add(fil);
        }
        insert filterList;
        
        System.runAs(testUser) 
        {
        	Test.startTest();
            	update filterList;
            Test.stopTest();
        }
        
    }
	//******************************************
  /* public static testMethod void OnAfterUpdate()
    {
        
    }
    public static testMethod void OnAfterUpdateBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
	//******************************************
   /* public static testMethod void OnBeforeDelete()
    {
    	
    }
    static testMethod void OnBeforeDeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
	//******************************************
  /*  public static testMethod void OnAfterDelete()
    {
    	
    }
    public static testMethod void OnAfterDeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
	//******************************************
  /*  public static testMethod void OnUndelete()
	{
		
    }
    public static testMethod void OnUndeleteBulk()
    {
        for(Integer i=0;i<200;i++)
        {
            
        }
    }*/
}