/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/17/17      jkennington          Created
========+============+=================+===============================================*/
@IsTest
private class BeckyWorkItemSyncQueueableTest
{
    @isTest
    private static void getConcerningReviewsWithWorkItemsFromBeckyTest()
    {

        Id rId = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Concerning Review').getRecordTypeId();
        WorkItem__c wi = new WorkItem__c(rev_review_id__c = 1234, RecordTypeId = rId, usr_user_id__c = TestUtilities.CUSTOMER_USER_PK_ID_INT, Name = 'testIsAfterInsert', Type__c = 'Blacklisted Number', ReviewAudit__c = 'No Action Needed');
        insert wi;
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
                new BeckyWorkItemSyncQueueable().execute(null);
            Test.stopTest();
            List<WorkItem__c> wi2 = [select Id From WorkItem__c];
            system.debug('wi2: ' + wi2);
            system.assert(wi2.size() == 1);
        }
    }

    @isTest
    private static void getConcerningReviewsWithNoWorkItemsFromBeckyTest()
    {
        TestUtilities.insertFourCoreThumbtackUsers();

        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
                new ScheduledGetWorkItems().execute(NULL);
            Test.stopTest();

            List<WorkItem__c> wi2 = [select Id From WorkItem__c];
            system.debug('wi2: ' + wi2);
            system.assert(wi2.size() == 1);

        }

    }
}