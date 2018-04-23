/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : CaseControllerTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : Tests for CaseControllerTest

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-05-11  Paul Coleman      Created 
 1.1     2015-12-21  Paul Coleman      removed testGetEmailCaseCategoryCounts &
                                       testGetOldestEmailCaseByCategory tests
 =======+===========+=================+=================================*/
@isTest
private class CaseControllerTest {

    @isTest
    private static void testGetAllCaseQueues() {
    	CaseController cxt = new CaseController(null);
    	System.assert( CaseController.getAllCaseQueues()!=null, 'getAllCaseQueues returned NULL instead of List');
    }

    @IsTest(SeeAllData=true) //connectAPI test
    private static void testGetAccountStats() {
        Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
    	Account a = new Account(Name='Chester Tester');
    	insert a;
    	Case c = new Case(AccountId=a.Id,Status='New',RecordTypeId=MIRTId);
    	insert c;
    	Test.startTest();
    		System.assert( CaseController.getAccountStats(a.Id)!=null, 'getAccountStats returned NULL instead of AccountStats obj');
            CaseController.postMsgWithMentions(c.Id, 'Hello World @[Travis Oliver]');
    	Test.stopTest();
    }

    @isTest
    private static void testGetAllStandardUsers() {
    	System.assert( CaseController.getAllStandardUsers()!=null, 'getAllStandardUsers returned NULL instead of List');
    }

    @isTest
    private static void testGetLast10Calls() {
    	System.assert( CaseController.getLast10Calls(null,null,null)!=null, 'getLast10Calls returned NULL instead of List');
    }

    @isTest
    private static void testGetEmailCaseCounts() {
        System.assert( CaseController.getEmailCaseCounts()!=null, 'getEmailCaseCounts returned NULL instead of List');
    }

    @isTest
    private static void testGetOldestEmailCaseByQueueOwner() {
        Id ownerId = UserInfo.getUserId();
        System.assert( CaseController.getOldestEmailCaseByQueueOwner(ownerId)==null, 'getOldestEmailCaseByQueueOwner returned non-NULL');
    }

    @isTest
    private static void getEnterpriseQueueCase_olderThan4Hours_test() {

        Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Account a = new Account(Name='Chester Tester');
        insert a;
        Case c = new Case(AccountId=a.Id,Status='New',RecordTypeId=MIRTId, OwnerId = CaseController.enterpriseQueueId);
        insert c;
        c.OwnerId = CaseController.enterpriseQueueId;
        update c;

        Test.startTest();

        List<Case> result = CaseController.getEnterpriseQueueCase(Datetime.now().addHours(6));

        Test.stopTest();

        System.assertEquals(c.Id, result[0].Id);

    }

    @isTest
    private static void getEnterpriseQueueCase_accountManager_test() {

        Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Account a = new Account(Name='Chester Tester', AccountManager__c = UserInfo.getUserId());
        insert a;
        Case c = new Case(AccountId=a.Id,Status='New',RecordTypeId=MIRTId, OwnerId = CaseController.enterpriseQueueId);
        insert c;
        c.OwnerId = CaseController.enterpriseQueueId;
        update c;

        Test.startTest();

        Case result = CaseController.getOldestEmailCaseByQueueOwner(CaseController.enterpriseQueueId);

        Test.stopTest();

        System.assertEquals(c.Id, result.Id);

        result = [Select OwnerId From Case Where Id = :result.Id];
        System.assertEquals(UserInfo.getUserId(), result.OwnerId);

    }

    @isTest
    private static void getEnterpriseQueueCase_fifo_test() {

        Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Account a = new Account(Name='Chester Tester');
        insert a;
        Case c = new Case(AccountId=a.Id,Status='New',RecordTypeId=MIRTId, OwnerId = CaseController.enterpriseQueueId);
        insert c;
        c.OwnerId = CaseController.enterpriseQueueId;
        update c;

        Test.startTest();

        Case result = CaseController.getOldestEmailCaseByQueueOwner(CaseController.enterpriseQueueId);

        Test.stopTest();

        System.assertEquals(c.Id, result.Id);

        result = [Select OwnerId From Case Where Id = :result.Id];
        System.assertEquals(UserInfo.getUserId(), result.OwnerId);

    }

    @isTest
    private static void updateCase_test() {

        Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Account a = new Account(Name='Chester Tester');
        insert a;
        Case c = new Case(AccountId=a.Id,Status='New',RecordTypeId=MIRTId, OwnerId = CaseController.enterpriseQueueId);
        insert c;
        c.OwnerId = CaseController.enterpriseQueueId;
        update c;

        Test.startTest();

        CaseController.updateCase(c.Id, UserInfo.getUserId());

        Test.stopTest();

        Case result = [Select OwnerId From Case Where Id = :c.Id];
        System.assertEquals(UserInfo.getUserId(), result.OwnerId);

    }

    @isTest
    private static void testDoSOQL() {
        System.assert( !CaseController.doSOQL('SELECT count(id) from USER').isEmpty(), 'doSOQL returned empty list, expected count result');
    }
}