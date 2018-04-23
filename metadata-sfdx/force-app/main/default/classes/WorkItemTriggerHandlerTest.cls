/*

Change List:                                                               
------------                                                               

Version    Date     Author            Description                          
=======+===========+=================+=================================
1.3     2016-12-19  Scott Purcell     Created
1.4     2017-07-05  Travis Oliver     Added testRouteWorkItem
1.5     2017-10-18  Jared Kennington  Cleaned up and used TestUtilities class
1.6     2017-12-13  Jared Kennington  Added testAutoCaseCreation
=======+===========+=================+=================================
*/
@isTest
private class WorkItemTriggerHandlerTest {
    private static final String testProEmail = 'protester@t.est';
    private static final String testCustomerEmail = 'customertester@t.est';
    private static final Decimal testProUserId = 12345;
    private static final String testProUserIdString = String.valueOf(testProUserId);
    private static final Decimal testCustomerUserId = 123456;
    private static final String actionNeededStr = 'Warn and Flag';
    private static final String immediateMiActionNeededStr = 'Immediate MI Action Needed';
    private static final String actionNeededOutcomeStr = 'Warned and Flagged';
    private static final String noActionOutcomeStr = 'No Action Taken';
    private static final String warningFlagExplanationStr = 'Automated flag: Concerning Review';
    private static final User testUser = TestUtilities.getTestUserByProfile('*Marketplace Integrity');

    @TestSetup
    private static void setupTestData()
    {
        TestUtilities.insertFourCoreThumbtackUsers();
    }

    /*@IsTest
    private static void testReviewTriggerPhases1And2() {

        System.runAs(testUser) {

            WorkItem__c r = new WorkItem__c(customer_last_name__c='cust last',rev_rating__c = 1,customer_first_name__c = 'cusfirst',pro_first_name__c='first',pro_last_name__c = 'last',Name='Test Review', rev_usr_user_id_reviewed__c=testProUserId, rev_usr_user_id_reviewer__c=testCustomerUserId, pro_email__c=testProEmail,customer_email__c=testProEmail);
            insert r;

            System.assert(null!=[SELECT ProAccount__c FROM WorkItem__c WHERE Id=:r.Id LIMIT 1].ProAccount__c, 'Trigger Failed to set WorkItem__c.ProAccount__c to account corresponding to usr_user_id__c = '+String.valueOf(testProUserId));
            Test.startTest();

            //Phase 1 simple outcome text set
            r.ReviewAudit__c = 'No Action Needed';
            update r;
            System.assert(noActionOutcomeStr==[SELECT Outcome__c FROM WorkItem__c WHERE Id=:r.Id LIMIT 1].Outcome__c, 'Trigger failed to set Outcome__c to ' + noActionOutcomeStr);

            //Phase 2, insert asynchronous records
            r.ReviewAudit__c = actionNeededStr;
            r.Outcome__c = null;
            update r;
            System.assert(actionNeededOutcomeStr==[SELECT Outcome__c FROM WorkItem__c WHERE Id=:r.Id LIMIT 1].Outcome__c, 'Trigger failed to set Outcome__c to ' + actionNeededOutcomeStr);

            Test.stopTest();

            Account tAcc = [SELECT Id FROM Account WHERE usr_user_id__c=:testProUserId LIMIT 1];
            System.assert(1==[SELECT count() FROM CustomerSuccessGuidance__c WHERE Account__c = :tAcc.Id],'No CustomerSuccessGuidance__c inserted after ReviewAudit__c update to '+actionNeededStr);

        }
    }
    @IsTest
    private static void testReviewTriggerPhases3And4() {

        System.runAs(testUser) {

            Account tAcc = [SELECT Id FROM Account WHERE usr_user_id__c=:testProUserId LIMIT 1];
            WorkItem__c r = new WorkItem__c(Name='Test Review', rev_usr_user_id_reviewed__c=testProUserId, rev_usr_user_id_reviewer__c=testCustomerUserId, pro_email__c=testProEmail,customer_email__c=testProEmail);
            insert r;
            update r; //create guidance (will be async)
            //insert phase two result, existing guidance record, to ensure one exists for the scenario three case and mi inserts
            insert new CustomerSuccessGuidance__c (
                    Account__c = tAcc.Id,
                    MIFlagType__c = 'Concerning Review',
                    Name = warningFlagExplanationStr,
                    FlagExplanation__c = warningFlagExplanationStr
            );

            Test.startTest();

            //Phase 3, insert asynchronous records with existing Guidance record
            r.ReviewAudit__c = actionNeededStr;
            r.Outcome__c = null;
            update r;

            Test.stopTest();

            system.debug('workitem r:'+r);
            system.assertEquals('Warn and Flag',r.ReviewAudit__c);
            update r; //code covarge for scenario 4
        }
    }

    //test MiAction flow
    @IsTest
    private static void testReviewTriggerScenario5() {

        System.runAs(testUser) {

            WorkItem__c r = new WorkItem__c(Name='Test Review', rev_usr_user_id_reviewed__c=testProUserId, rev_usr_user_id_reviewer__c=testCustomerUserId, pro_email__c=testProEmail,customer_email__c=testProEmail);
            insert r;
            Test.startTest();

            //phase five
            r.ReviewAudit__c = immediateMiActionNeededStr;
            update r;
            //System.assert(immediateMiActionOutcomeStr==[SELECT Outcome__c FROM WorkItem__c WHERE Id=:r.Id LIMIT 1].Outcome__c, 'Trigger failed to set ' + immediateMiActionOutcomeStr);
            Test.stopTest();
            system.assertEquals('Immediate MI Action Needed',r.ReviewAudit__c);
            Account tAcc = [SELECT Id FROM Account WHERE usr_user_id__c=:testProUserId LIMIT 1];

            List<MiIncident__c> miRecs = [SELECT Id from MiIncident__c WHERE pro_user_id__c = :testProUserIdString];
            System.assert(!miRecs.isEmpty(),'No MI Incident inserted after ReviewAudit__c update to '+immediateMiActionNeededStr);
        }
    }*/
    @IsTest
    private static void testRouteWorkItem()
    {
        System.runAs(testUser) {

            WorkItem__c w = new WorkItem__c
                    (
                            type__c = 'Review Message',
                            name = 'Test Name',
                            details__c = 'Test Details',
                            rev_usr_user_id_reviewed__c = 1236548,
                            pro_first_name__c = 'Test',
                            pro_last_name__c = 'Pro'
                    );

            Test.startTest();
            insert w;
            Test.stopTest();
            WorkItem__c wTest = [SELECT Id, Type__c, Status__c, Priority__c, RecordTypeId, OwnerId, Details__c FROM WorkItem__c WHERE Type__c = 'Review Message' LIMIT 1][0];
            Map<String, WorkItemRouter__mdt> wirMap = new Map<String,WorkItemRouter__mdt>();
            for(WorkItemRouter__mdt wir : [SELECT MasterLabel, OwnerId__c, Priority__c, RecordtypeId__c, Status__c From WorkItemRouter__mdt WHERE IsActive__c = true])
            {
                wirMap.put(wir.MasterLabel, wir);
            }
            System.assert(wTest.status__c == wirMap.get(w.type__c).status__c,'Status not equal to Custom Setting Status');
            System.assert(wTest.priority__c == wirMap.get(w.type__c).priority__c,'Priority not equal to Custom Setting Priority');
            System.assert(wTest.recordtypeid == wirMap.get(w.type__c).recordtypeid__c,'RecordTypeId not equal to Custom Setting RecordTypeId');
            System.assert(wTest.ownerid == wirMap.get(w.type__c).ownerid__c,'OwnerId not equal to Custom Setting OwnerId');
        }
    }

    @isTest
    private static void testAutoCaseCreation()
    {
        System.runAs(testUser)
        {
            QuickCaseSetting__mdt[] qcs = [SELECT Id, WorkItemReportOutcome__c, WorkItemType__c, FeedPost__c, Category__c, OwnerId__c FROM QuickCaseSetting__mdt WHERE AssignedApp__c = 'WorkItem' AND IsActive__c = true LIMIT 1];


            WorkItem__c w = new WorkItem__c
                    (
                        Type__c = qcs[0].WorkItemType__c,
                        name='Test WI',
                        details__c = 'Test Case Creation'
                    );

            Test.startTest();
            insert w;
            w.ReportOutcome__c = qcs[0].WorkItemReportOutcome__c;
            update w;
            Test.stopTest();

            Case[] casesCreated = [SELECT Id, WorkItemId__c, OwnerId, Category__c FROM Case WHERE WorkItemId__c = :w.Id];
            CaseFeed[] feedItemsCreated = casesCreated.isEmpty() ? null : [SELECT Id FROM CaseFeed WHERE ParentId = :casesCreated[0].Id];

            //Case creation
            System.assert(casesCreated.size() > 0, 'Did not create a case');
            System.assert((casesCreated.size() > 0 && casesCreated.size() == 1), 'Created more than one case');

            //Feed Item creation
            System.assert((!feedItemsCreated.isEmpty() && feedItemsCreated.size() > 0), 'Did not create a feed item');
            System.assert((!feedItemsCreated.isEmpty() && feedItemsCreated.size() > 0 && feedItemsCreated.size() == 1), 'Created more than one feed item');

            //Values check
            System.assert(casesCreated[0].OwnerId == qcs[0].OwnerId__c, 'Values did not populate correctly on Case' );
        }
    }

}