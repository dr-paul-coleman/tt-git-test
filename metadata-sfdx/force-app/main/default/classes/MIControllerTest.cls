/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : MIControllerTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : Tests for MIController

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-08-21  Paul Coleman      Created 
 1.1     2017-09-05  Scott Purcell     Removed reference to OriginalCase__c
 =======+===========+=================+=================================*/
@isTest
private class MIControllerTest {

    @testSetup
    private static void setupData() {
        User testUser = [SELECT Id from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {

            Id MIRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
            Id CSRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            Account a = new Account(Name='Chester Tester');
            insert a;
            Contact contct = new Contact(AccountId=a.Id,FirstName='Chester',LastName='Tester',Phone='(801) 824-1461');
            insert contct;
            Case c = new Case(Subject='MI Testing',ContactId=contct.Id,AccountId=a.Id,Status='New',RecordTypeId=MIRTId,Origin='LiveOps Inbound Support Call',Priority='Medium',SuppliedEmail='test@test.com');
            Case c2 = new Case(Subject='MI Testing 2',ContactId=contct.Id,AccountId=a.Id,Status='New',RecordTypeId=CSRTId,Origin='LiveOps Inbound Support Call',Priority='Medium',SuppliedEmail='test@test.com');
            insert new Case[]{c,c2};
            MIIncident__c mi = new MIIncident__c(Status__c='In Progress',Name=c.Subject);
            insert mi;
            c.Incident__c = mi.Id;
            c2.Incident__c = mi.Id;
            update new Case[]{c,c2};
            EmailMessage em = new EmailMessage(ParentId=c.Id,TextBody='Testing',Subject='Testing',FromAddress='chester@tester.com',FromName='Chester Tester');
            EmailMessage em2 = new EmailMessage(ParentId=c2.Id,TextBody='Testing 2',Subject='Testing 2',FromAddress='chester@tester.com',FromName='Chester Tester');
            EmailMessage em3 = new EmailMessage(ParentId=c.Id,TextBody='Testing 3',Subject='Testing 3',FromAddress='chester@tester.com',FromName='Chester Tester');
            insert new EmailMessage[]{em,em2,em3};
            Attachment a1 = new Attachment(ParentId=c.Id,Name='a1',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            Attachment a2 = new Attachment(ParentId=em.Id,Name='a2',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            Attachment a3 = new Attachment(ParentId=mi.Id,Name='a3',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            Attachment a4 = new Attachment(ParentId=em2.Id,Name='a4',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            Attachment a5 = new Attachment(ParentId=c2.Id,Name='a5',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            Attachment a6 = new Attachment(ParentId=em3.Id,Name='a6',ContentType='text/plain',Body=Blob.valueOf('Testing'));
            insert new Attachment[]{a1,a2,a3,a4,a5,a6};
            MIFile__c mf1 = new MIFile__c(MIIncident__c=mi.Id,Name=a1.Name,NewAttachmentId__c='00P56000000LqaK',AttachmentParentId__c=c.Id,AttachmentId__c=a1.Id);
            MIFile__c mf2 = new MIFile__c(MIIncident__c=mi.Id,Name=a2.Name,NewAttachmentId__c=a3.Id,AttachmentParentId__c=a2.ParentId,AttachmentId__c=a2.Id);
            insert new MIFile__c[]{mf1,mf2};
        }
    }

    @isTest
    private static void testReplicateAttachment() {
        User testUser = [SELECT Id from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Id miId = [SELECT Id FROM MIIncident__c LIMIT 1].Id;
            Id aId = [SELECT Id FROM Attachment WHERE Name = 'a1'].Id;
                MIFile__c mf = MIController.replicateAttachment(aId,miId);
                System.assert( null!=mf && miId.equals(mf.MIIncident__c), 'MIFile__c not created successfully');
            Test.stopTest();
        }
    }

    @isTest
    private static void testGetAttachmentsByMIId() {
        User testUser = [SELECT Id from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                String json = MIController.getAttachmentsByMIId([SELECT Id FROM MIIncident__c LIMIT 1].Id);
                System.assert(json.contains('Attachments'), 'MI Attachments JSON result not valid');
            Test.stopTest();
            //grabbing constructor code coverage
            MIController mc = new MIController(null);
        }
    }

}