/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/18/17      jkennington          Created
========+============+=================+===============================================*/
@IsTest
private class RESTWorkItemTest
{
    @IsTest
    static void doPostTest()
    {

        WorkItem__c wi = new WorkItem__c(Name = 'Review Message for Intent', CreatedDate = Date.today().addDays(-8), RecordTypeId = '01231000000y2AlAAI', BidId__c = '74t2kfgj', Details__c = 'TT Test Details', Priority__c = 'Medium', Status__c = 'New', Type__c = 'Concerning Review', usr_user_id__c = 12345);
        WorkItem__c wi2 = new WorkItem__c(Name = 'Review', RecordTypeId = '01231000000y2AlAAI', BidId__c = '74t2kfgj', Details__c = 'TT Test Details', Priority__c = 'High', Status__c = 'New', Type__c = 'Concerning Review', usr_user_id__c = 12345);
        WorkItem__c wi3 = new WorkItem__c(Name = 'Review', RecordTypeId = '01231000000y2AlAAI', BidId__c = '74t2kfgj', Details__c = 'TT Test Details', Priority__c = 'High', Status__c = 'New', Type__c = 'Concerning Review', usr_user_id__c = 12345);

        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            RESTWorkItemController.doPost(wi);
            RESTWorkItemController.doPost(wi2);
            System.assertEquals([SELECT Count() FROM WorkItem__c WHERE usr_user_id__c = 12345 AND RecordTypeId = :wi.RecordTypeId], 2, 'Did not create second record');
            Test.stopTest();

            RESTWorkItemController.doPost(wi3);
        }
        System.assertEquals([SELECT Count() FROM WorkItem__c WHERE usr_user_id__c = 12345  AND RecordTypeId = :wi.RecordTypeId], 2, 'Did not update record');
        System.assertEquals([SELECT Priority__c FROM WorkItem__c WHERE usr_user_id__c = 12345 AND CreatedDate > :Date.today().addDays(-7) AND RecordTypeId = :wi2.RecordTypeId LIMIT 1][0].Priority__c, 'High', 'Record not updated');
    }
}