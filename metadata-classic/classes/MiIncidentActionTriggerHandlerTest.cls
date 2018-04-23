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
========+============+=================+================================================
1.0       06-02-2017   Scott Purcell     Created
1.1       08-25-2017   Scott Purcell     Lots of stuff added for the mI Rebuid project
1.2       09-12-2017   Scott Purcell     Updated tests for follow-up tasks
========+============+=================+===============================================*/
@isTest
private class MiIncidentActionTriggerHandlerTest 
{
    public static Id PayoutRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    public static Id TaskRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();
    public static Id ChargeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Charge Card').getRecordTypeId();
    public static Id GuaranteeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Guarantee').getRecordTypeId();

    @testSetup static void setupTest() 
    {
        // User testUser = [SELECT id FROM User WHERE Profile.Name LIKE 'Marketplace Integrity' AND IsActive=true LIMIT 1];        
        
        Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Id miCaseQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceIntegrity'].Id;
        Decimal testProUserId = 100;
        Decimal testCustomerUserId = 200;
        Account aPro = new Account(Name='Chester Pro', usr_user_id__c=testProUserId, usr_email__c='protester@t.est', RecordTypeId=accProRT);
        Account aPro2 = new Account(Name='Chester Pro2', usr_user_id__c=123, usr_email__c='protester2@t.est', RecordTypeId=accProRT);
        Account aCustomer = new Account(Name='Tester Customer', usr_user_id__c=testCustomerUserId, usr_email__c='customertester@t.est', RecordTypeId=accCustomerRT);
        Account aCustomer2 = new Account(Name='Tester Customer2', usr_user_id__c=12345, usr_email__c='customertester2@t.est', RecordTypeId=accCustomerRT);
        insert new Account[]{aPro,aPro2,aCustomer,aCustomer2};
        
       
        
        MiIncident__c mii = new MiIncident__c(
            Name='Test', 
            quotes_pro_user_id__c = testProUserId, 
            quotes_customer_id__c = testCustomerUserId, 
            quotes_bid_id__c = 1, 
            RequestID__c = '1',
            ResolutionTier__c = 'Tier 0 - Lost Communication',
            MICategory__c = 'Removed',
            MISubcategory__c = 'Other',
            Status__c = 'In Progress', 
            ProAccount__c = aPro2.Id,
            CustomerAccount__c = aCustomer2.Id,
            IncidentCategorization__c = '0 - Not enough details');                
        insert mii; 
         Case aCase = new Case(Category__c ='Phone',Incident__c = mii.Id,accountId=aPro.Id, Subject='MI Test Case', Status = 'New', Origin = 'Email',RecordTypeId=caseRT);
        insert aCase;
        System.assert(null != aCase.Id,'Test Case not inserted properly');
    }   
    @isTest static void onAfterInsertUpdateDelete() 
    {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        MiIncident__c mi = [Select Id FROM MiIncident__c];
        MIIncidentAction__c mia = new MIIncidentAction__c();
        mia.MIIncident__c = mi.Id;
        mia.RecordTypeId = TaskRTId;
        mia.IsVisibleToCS__c = true;
        mia.DueDate__c = DateTime.now().addDays(2);
        mia.Notes__c = 'note 1';
        mia.Type__c = 'Follow-up';

        MIIncidentAction__c mia2 = new MIIncidentAction__c();
        mia2.MIIncident__c = mi.Id;
        mia2.RecordTypeId = TaskRTId;
        mia2.IsVisibleToCS__c = true;
        mia2.DueDate__c = DateTime.now().addDays(3);
        mia2.Notes__c = 'note 2';
        mia2.Type__c = 'Follow-up';
        
        MIIncidentAction__c mia3 = new MIIncidentAction__c();
        mia3.MIIncident__c = mi.Id;
        mia3.RecordTypeId = TaskRTId;
        mia3.IsVisibleToCS__c = true;
        mia3.DueDate__c = DateTime.now().addDays(4);
        mia3.Notes__c = 'note 3';
        mia3.Type__c = 'Follow-up';


        System.runAs(testUser) 
        {
            
            Test.startTest();
            insert mia;
            insert mia2;
            List<MIIncident__c> miList = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
            system.debug('miList: '+miList);
            system.assertEquals('note 1',miList[0].NextFollowupTask__c );

            mia.Status__c ='Completed';
            update mia;
            List<MIIncident__c> miList1 = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
            system.debug('miList1: '+miList1);
            system.assertEquals( 'note 2',miList1[0].NextFollowupTask__c);

            insert mia3;
            List<MIIncident__c> miList2 = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
            system.debug('miList2: '+miList2);
            system.assertEquals('note 2',miList2[0].NextFollowupTask__c );
            
            delete mia2;
            List<MIIncident__c> miList3 = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
            system.debug('miList3: '+miList3);
            system.assertEquals('note 3',miList3[0].NextFollowupTask__c);

            mia3.Status__c='Completed';
            update mia3;
            List<MIIncident__c> miList4 = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
            system.debug('miList4: '+miList4);
            system.assertEquals(null,miList4[0].NextFollowupTask__c);
            
            
            Test.stopTest();
            
            List<MIIncidentAction__c> m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
        }
    }
    @isTest static void testPaymentSent() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.RecordTypeId = PayoutRTId;
      mia.MIIncident__c = mi.Id;
      insert mia;
      System.runAs(testUser) 
      {
            
          Test.startTest();
              mia.Status__c = 'Payment sent';
              update mia;
          Test.stopTest();
          MIIncidentAction__c m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testPaymentSent.m: '+m);
      }
    }
    
    @isTest static void testChargeCard() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = ChargeRTId;
      insert mia;
      System.runAs(testUser) 
        {
            
          Test.startTest();
            
          mia.Status__c = 'Successful';
              update mia;
          Test.stopTest();
          MIIncidentAction__c m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testChargeCard.m: '+m);
      }
    }
    @isTest static void testGuarantee() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = GuaranteeRTId;
      insert mia;
      System.runAs(testUser) 
        {
            
          Test.startTest();
            
          mia.Status__c = 'Paid (under Satisfaction)';
              update mia;
          Test.stopTest();
          MIIncidentAction__c m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testGuarantee.m: '+m);
      }
    }


    @isTest static void testTask() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = TaskRTId;
      mia.IsVisibleToCS__c = true;
      insert mia;
      List<Case> cases = [Select Id,MICasePrimaryCustomer__c,MICasePrimaryPro__c,Incident__c From Case];
      System.runAs(testUser) 
        {
            
          Test.startTest();
          if(Cases.size()>0)
          {
              cases[0].MICasePrimaryPro__c = true;
              cases[0].Incident__c = mi.Id;
              cases[0].Category__c = 'Other';
              cases[0].SubCategory__c = 'Site outage';
          }
          update cases;
          Test.stopTest();
          MIIncidentAction__c m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testTask.m: '+m);
      }
    }
    @isTest static void testTaskCompleted() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = TaskRTId;
      mia.IsVisibleToCS__c = true;
      insert mia;
      List<Case> cases = [Select Id,MICasePrimaryCustomer__c,MICasePrimaryPro__c,Incident__c From Case];
      System.runAs(testUser) 
        {
            
          Test.startTest();
            
          mia.Status__c =  'Completed';
          update mia;
          if(Cases.size()>0)
          {
              cases[0].MICasePrimaryPro__c = true;
              cases[0].Incident__c = mi.Id;
              cases[0].Category__c = 'Other';
              cases[0].SubCategory__c = 'Site outage';
          }
          update cases;
          Test.stopTest();
          MIIncidentAction__c m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testTask.m: '+m);
      }
    }
    @isTest static void onBeforeInsert() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = TaskRTId;
      mia.IsVisibleToCS__c = true;
      mia.DueDate__c = DateTime.now().addDays(2);
      mia.Notes__c = 'note 1';
      mia.Status__c = 'Open';

      MIIncidentAction__c mia2 = new MIIncidentAction__c();
      mia2.MIIncident__c = mi.Id;
      mia2.RecordTypeId = TaskRTId;
      mia2.IsVisibleToCS__c = true;
      mia2.DueDate__c = DateTime.now().addDays(3);
      mia2.Notes__c = 'note 2';
      mia2.Status__c = 'Open';
        
      System.runAs(testUser) 
        {
            
          Test.startTest();
          insert mia;
          insert mia2;
           
            
          Test.stopTest();
          List<MIIncident__c> miList = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
          List<MIIncidentAction__c> m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testTask.m: '+m.size());
      }
    }
    
    @isTest static void onAfterDelete() 
    {
      User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
      MiIncident__c mi = [Select Id FROM MiIncident__c];
      MIIncidentAction__c mia = new MIIncidentAction__c();
      mia.MIIncident__c = mi.Id;
      mia.RecordTypeId = TaskRTId;
      mia.IsVisibleToCS__c = true;
      mia.DueDate__c = DateTime.now().addDays(2);
      mia.Notes__c = 'note 1';

      MIIncidentAction__c mia2 = new MIIncidentAction__c();
      mia2.MIIncident__c = mi.Id;
      mia2.RecordTypeId = TaskRTId;
      mia2.IsVisibleToCS__c = true;
      mia2.DueDate__c = DateTime.now().addDays(3);
      mia2.Notes__c = 'note 2';
      System.runAs(testUser) 
        {
            
          Test.startTest();
          insert mia;
          insert mia2;
          delete mia;
          delete mia2;
            
          Test.stopTest();
          List<MIIncident__c> miList = [Select Id,NextFollowupTask__c,NextFollowupDate__c  From MIIncident__c];
          List<MIIncidentAction__c> m = [Select Id,CompletedBy__c,CompletedOn__c From MIIncidentAction__c];
          system.debug('testTask.m: '+m.size());
      }
    }
}