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
 Script File Name    : CaseEmailHandlerTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : Tests for CaseEmailHandler/CaseEmailTrigger also
                       tests EmailFilterTrigger (after insert)

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-04-15  Paul Coleman      Created 
 =======+===========+=================+=================================*/
@isTest
private class CaseEmailHandlerTest {

    //PBC 2018-03-20
    // commenting out EmailFilter__c-related tests in prep for EmailFilter__c removal and CaseEmailHandler adjustment
    // per instructions from Kristin as part of Solution Center deployment


//    @testSetup
//    static void setupFilterData() {
//        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
//        System.runAs(testUser) {
//            insert new EmailFilter__c(Name='Test Filter',Regex__c='^Testing$',ExampleSubject__c='Testing',EmailFilterMatched__c='Testing',FilterActive__c=true);
//        }
//    }

//    @isTest static void testEmailFilter() {
//        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
//        System.runAs(testUser) {
//            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
//            Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester');
//            insert c;
//
//            Test.startTest();
//                insert new EmailMessage(ParentId=c.Id,Subject='Testing');
//            Test.stopTest();
//
//            Case result = [SELECT EmailFilterMatched__c FROM Case WHERE Id=:c.Id];
//            System.assert(result.EmailFilterMatched__c.equals('Testing'), 'Trigger did not update Case');
//
//        }
//    }

    @isTest static void testdoCheckr() {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) {
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester');
            insert c;

            Test.startTest();
                insert new EmailMessage(ParentId=c.Id,Subject='CONSIDER',HtmlBody = 'The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team');
            Test.stopTest();

            //grab extra code coverage on exception flows
            //try{ CaseEmailHandler.sendAdminMail('Subject','Test Email'); } catch (Exception ex) {}

        }
    }
    
        // @isTest static void testReducingCaseDupes() {
        // User testUser = [SELECT id FROM User WHERE Alias='tackbot' AND IsActive=true LIMIT 1];
        // System.runAs(testUser) {
        //         Id tackbotId=[SELECT Id FROM User WHERE Alias='tackbot' LIMIT 1].Id;
        //         //insert a Email-to-Case record (no related EmailMessage is needed)
        //         Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        //         Case c = new Case(Subject='New Email-to-Case',Status='New',RecordTypeId=caseRTId,Origin='Email',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester');
        //         insert c;
        //         System.debug(LoggingLevel.FINE,'PARENT CASE: ' + JSON.serialize(c));
        //         System.debug(LoggingLevel.FINE,'PARENT CASE AFTER INSERT: '+JSON.serialize([SELECT Subject,Status,RecordType.Name,RecordTypeId,Origin,SuppliedEmail,SuppliedName,OwnerId FROM Case WHERE Id=:c.Id]));
        //         Id noiseQId=[SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Noise' LIMIT 1].Id;
        //     Test.startTest();
        //         //simulate Email-to-Case dupe
        //         Case c2 = new Case(OwnerId=tackbotId,Subject='New Email-to-Case',Status='New',RecordTypeId=caseRTId,Origin='Email',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester');
        //         insert c2;
        //         //insert new EmailMessage related to the duped Parent Case (now owned by Noise Q)
        //         c2 = [SELECT isDeleted,CaseNumber,OwnerId FROM Case WHERE Id=:c2.Id LIMIT 1];
        //         System.debug(LoggingLevel.FINE,'DUPED CASE AFTER INSERT: '+JSON.serialize(c2));
        //         System.assert(noiseQId==c2.ownerId,'Case dupe is not assigned to Noise Q after insert');
        //         insert new EmailMessage(ParentId=c2.Id,Subject='Should be Re-Parented');

        //     Test.stopTest();
            
        //         //assert duped case was deleted and its related EmailMessage was replicated onto the open/existing case
        //         System.assert([SELECT isDeleted FROM Case WHERE Id=:c.id LIMIT 1 ALL ROWS].isDeleted==false,'Open Case was deleted');
        //         System.assert([SELECT isDeleted FROM Case WHERE Id=:c2.id LIMIT 1 ALL ROWS].isDeleted,'Duped Email Case was not deleted');
        //         System.assert([SELECT Id,ParentId FROM EmailMessage WHERE ParentId=:c2.Id].isEmpty(),'Noisy EmailMessage was not deleted with Parent Case');
                
        //         //Assert original email message was replicated unto the previously opened Case
        //         List<EmailMessage> msgs = [SELECT Id FROM EmailMessage WHERE ParentId=:c.Id];
        //         System.assert(!msgs.isEmpty(),'Noisy EmailMessage was not replicated');

        //         //grab extra code coverage on exception flows
        //         try{ CaseEmailHandler.sendAdminMail('Subject','Test Email'); } catch (Exception ex) {}
        //         try{ new CaseEmailHandler.CaseUpdateQueue(new List<Case>()).execute(null); } catch(Exception e2) {}
        // }
    // }
}