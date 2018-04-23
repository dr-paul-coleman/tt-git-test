/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       11/6/17      jkennington          Created
========+============+=================+===============================================*/
@IsTest
private class BugTriggerHandlerTest
{
    @IsTest
    private static void testBugCreationAndDateFixedUpdate()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            //Support Process Record Type
            Id spRTId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Bug Report').getRecordTypeId();
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();

            Case newCase = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@testing.com',SuppliedName='Phil Painter',SuppliedThumbtackID__c=120);
            insert newCase;

            Bug__c bug = new Bug__c();
            bug.Name = 'Test Bug';
            //bug.User__c = TestUtilities.USER_TACK_BOT.Id;
            bug.Priority__c = 'High';
            bug.BugDescription__c = 'Test Bug Description';
            insert bug;

            SupportProcess__c supportProcess = new SupportProcess__c();
            supportProcess.Case__c = newCase.Id;
            supportProcess.RecordTypeId = spRTId;
            supportProcess.Bug__c = bug.Id;
            insert supportProcess;


            Test.startTest();
            bug.DateFixed__c = System.today();
            update bug;

            Test.stopTest();

            //Assert that the trigger updated the child support process's
            System.assertEquals([SELECT DateBugFixed__c FROM SupportProcess__c WHERE Bug__c = :bug.Id][0].DateBugFixed__c, [SELECT DateFixed__c FROM Bug__c WHERE Id = :bug.Id][0].DateFixed__c,'Support Process and Bug Fixed Dates do not match');
        }
    }
}