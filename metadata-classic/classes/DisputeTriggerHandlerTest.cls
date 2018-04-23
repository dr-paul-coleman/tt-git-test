/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       01/10/18      pcoleman           Created
========+============+=================+===============================================*/
@IsTest
public with sharing class DisputeTriggerHandlerTest
{
    //NOTE: Much of DisputeTriggerHandler's test code coverage and assertions are handled by SolutionCenterControllerTest

    public static final String DEFAULT_DISPUTE_JSON = '{ "attributes" : { "type" : "Dispute__c" }, "Name" : "Dispute between Ben Customer and Ben Professional", "Description__c" : null, "DisputeExpirationDate__c" : null, "OverallDisputeTimeInDays__c" : null, "InitiatorLastLoginDate__c" : null, "MIIncident__c" : null, "Status__c" : "Awaiting", "bid_pk__c" : "1234567", "request_category__c" : "Dog Grooming", "request_city__c" : "Mesa", "request_state__c" : "AZ", "request_zip__c" : "85201", "SolutionCenterStatusLabel__c" : "Awaiting confirmation of dispute details by Ben", "PrePopulatedResolutionAmount__c" : null, "FinalResolution__c" : null, "FinalResolutionAmount__c" : null, "ResponderLastLoginDate__c" : null, "InitiatorContactPkId__c" : null, "MaxofDaysforOffer__c" : 1, "DefaultDisputeSettingsOverridden__c" : false, "Stage__c" : "Initiator confirmation needed", "InitiatorMessageCount__c" : null, "ResponderMessageCount__c" : null, "MaxOfInitiatorOffersAllowed__c" : null, "MaxOfResponderOffersAllowed__c" : null, "MaxOfInitiatorMessagesAllowed__c" : null, "MaxOfResponderMessagesAllowed__c" : null, "InitiatorOfferCount__c" : null, "ResponderOfferCount__c" : null, "MaxOfDaysForInitiatorToReply__c" : 1, "MaxOfDaysForResponderToReply__c" : 1, "WithdrawalReason__c" : null, "MaxOfDaysForInitiatorToConfirm__c" : 1, "MaxOfDaysForResponderFirstAction__c" : 1, "InitiatorConfirmationDate__c" : null, "InitiatorConfirmationDueDate__c" : null, "ResponderFirstActionDate__c" : null, "ResponderFirstActionDueDate__c" : null, "MaxOfDaysAllowedForDispute__c" : 1, "MaxDaysForCalendarPicker__c" : null, "LastStageChangeDate__c" : null, "DisputeStartDate__c" : null, "DisputeClosedDate__c" : null, "DisputeResolutionDueDate__c" : null }';
    public static final String DEFAULT_DISPUTE_EXPERIENCE_JSON = '{ "attributes" : { "type" : "DisputeExperience__c" }, "Name" : "Standard Dispute Experience", "DisputeType__c" : "Standard", "MaxOfInitiatorOffersAllowed__c" : 50.0, "MaxOfResponderOffersAllowed__c" : 50.0, "MaxOfDaysAllowedForDispute__c" : 45.0, "MaxDaysForCalendarPicker__c" : 20.0, "MaxFileSize__c" : 25.0, "MaxofDaysforOffer__c" : 5.0, "HelpCenterExperienceId__c" : "a0m2F000000NxKJ", "MaxOfInitiatorMessagesAllowed__c" : 300.0, "MaxOfResponderMessagesAllowed__c" : 300.0, "MaxOfDaystoAcceptOrCounterOffer__c" : 3.0, "Status__c" : "Published", "MaxOfDaysForInitiatorToConfirm__c" : 3.0, "MaxOfDaysForResponderFirstAction__c" : 3.0, "DefaultExperience__c" : true, "PublishDate__c" : "2017-12-11T23:34:00.000+0000", "ArchiveDate__c" : null, "RecordNumber__c" : "SCC-00001", "MaxOfDaysForInitiatorToReply__c" : 3.0, "MaxOfDaysForResponderToReply__c" : 3.0 }';

    /**
    * @author Paul Coleman
    * @date 2018-01-10
    * @description Inserts a set of four test Accounts.
    */
    @TestSetup
    private static void createTestAccounts()
    {
        TestUtilities.insertFourCoreThumbtackUsers();
        DisputeExperience__c experience = (DisputeExperience__c) JSON.deserialize( DisputeTriggerHandlerTest.DEFAULT_DISPUTE_EXPERIENCE_JSON, DisputeExperience__c.class );
        insert experience;

    }


    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Tests (RULE 18) - Reset applicable due dates and stages when an agent
    *               changes status back from ‘Under review’ to ‘In progress’ or ‘Awaiting’
    *               (Note: Status can be triggered to ‘Under review’ -OR- an agent can
    *               manually set the Status/Stage combo to ‘Under review’ > ‘Stopped’).
    */
//    @IsTest
//    private static void testUnderReviewWithdraw()
//    {
//        Dispute__c newDispute = SolutionCenterControllerTest.loadInitiatorDispute(true);
//
//        User testMIUser = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'MIFrontLineUser' AND Profile.Name = '*Marketplace Integrity' LIMIT 1];
//        User initiator = [SELECT Id FROM User WHERE ContactId = :newDispute.InitiatorContact__c LIMIT 1];
//
//        newDispute.Status__c = 'Awaiting';
//        newDispute.Stage__c = 'Initiator confirmation needed';
//        newDispute.PriorStage__c = null;
//        update newDispute;
//        Dispute__c testDispute;
//
//        Datetime now = System.now();
//        Map<String, Object> offerFields = new Map<String, Object>{ 'DisputeHash__c' => newDispute.IdHash__c, 'ResolutionCompleteByDate__c' => Decimal.valueOf(now.getTime()), 'DesiredResolution__c' => 'I want a full refund.', 'DesiredRefundAmount__c' => 10000, 'Note__c' => 'My master bedroom is missing.' };
//        // create an initial offer as the Dispute Initiator
//        String offerHashWithdrawn;
//        System.runAs( initiator )
//        {
//            offerHashWithdrawn = SolutionCenterController.createOffer(offerFields);
//            // Stage = `Responder first action needed`, prior Stage now = `Initiator confirmation needed`
//        }
//
//        Test.startTest();
//
//            // Test changes from `Under review` to `In progress`
//            System.runAs( initiator )
//            {
//                SolutionCenterController.withdrawDispute(newDispute.IdHash__c, 'Test reason', 'Test notes');
//                // Stage now = `Withdrawn`, prior Stage now = `Responder first action needed`
//            }
//
//            System.runAs(testMIUser)
//            {
//                System.debug( 'POST WITHDRAW: ' + JSON.serialize( [SELECT Stage__c, PriorStatus__c, PriorStage__c, Status__c, (SELECT Id, Status__c, PriorStatus__c, DisputeOfferExpirationDate__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1] ) );
//
//                // Agent re-activates Dispute
//
//                testDispute = new Dispute__c(Id=newDispute.Id,  Status__c = 'In progress',  Stage__c = 'Offer pending');
//                update  testDispute;
//
//                testDispute = [SELECT Stage__c, Status__c, DisputeStartDate__c, InitiatorConfirmationDueDate__c, (SELECT Id, Status__c, PriorStatus__c, DisputeOfferExpirationDate__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
//                System.debug(LoggingLevel.WARN, 'OFFERS: ' + JSON.serialize(testDispute.DisputeOffers__r));
//                System.assertNotEquals( null, testDispute.DisputeStartDate__c, 'Test Dispute DisputeStartDate__c not set');
//                System.assertEquals( 'Pending', testDispute.DisputeOffers__r[0].Status__c, 'Offer Status not reverted from `Withdrawn`.' );
//                System.assertEquals( 'Awaiting', testDispute.Status__c, 'Offer Status not reverted from `Awaiting`.' );
//            }
//        Test.stopTest();
//
//        System.runAs(initiator)
//        {
//            testDispute = [SELECT Id, IdHash__c, DisputeStartDate__c, InitiatorConfirmationDueDate__c, DisputeResolutionDueDate__c, MaxOfDaysForInitiatorToConfirm__c, MaxOfDaysAllowedForDispute__c, DisputeLastView__c, InitiatorHash__c, ResponderHash__c, OwnerId FROM Dispute__c WHERE Id = :newDispute.Id LIMIT 1];
//            System.assertEquals(testDispute.OwnerId, initiator.Id, 'Test Dispute does not have the new Portal User set as OwnerId');
//            System.assertNotEquals( null, testDispute.IdHash__c, 'Test Dispute does not have an IdHash__c set');
//            System.assertNotEquals( null, testDispute.InitiatorHash__c, 'Test Dispute does not have an InitiatorHash__c set');
//            System.assertNotEquals( null, testDispute.DisputeLastView__c, 'Test Dispute does not have an parent DisputeLastView__c set');
//            System.assertNotEquals( null, testDispute.DisputeStartDate__c, 'Test Dispute DisputeStartDate__c not set');
//            System.assertNotEquals( null, testDispute.InitiatorConfirmationDueDate__c, 'Test Dispute InitiatorConfirmationDueDate__c not set');
//            System.assertNotEquals( null, testDispute.DisputeResolutionDueDate__c, 'Test Dispute DisputeResolutionDueDate__c not set');
//            System.assert( testDispute.DisputeResolutionDueDate__c > now, 'Test Dispute DisputeResolutionDueDate__c not set according to ');
//            System.assert( testDispute.InitiatorConfirmationDueDate__c > now, 'Test Dispute InitiatorConfirmationDueDate__c not set according to ');
//        }
//    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Tests (RULE 18) - Reset applicable due dates and stages when an agent
    *               changes status back from ‘Under review’ to ‘In progress’ or ‘Awaiting’
    *               (Note: Status can be triggered to ‘Under review’ -OR- an agent can
    *               manually set the Status/Stage combo to ‘Under review’ > ‘Stopped’).
    */
//    @IsTest
//    private static void testTriggerUnderReviewToAwaiting()
//    {
//        Dispute__c newDispute = SolutionCenterControllerTest.loadInitiatorDispute(true);
//
//        Datetime now = System.now();
//        User testMIUser = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'MIFrontLineUser' AND Profile.Name = '*Marketplace Integrity' LIMIT 1];
//        User initiator = [SELECT Id FROM User WHERE ContactId = :newDispute.InitiatorContact__c LIMIT 1];
//
//        newDispute.Status__c = 'Awaiting';
//        newDispute.Stage__c = 'Initiator confirmation needed';
//        newDispute.PriorStage__c = null;
//        update newDispute;
//        Dispute__c testDispute;
//
//        Map<String, Object> offerFields = new Map<String, Object>{ 'DisputeHash__c' => newDispute.IdHash__c, 'ResolutionCompleteByDate__c' => Decimal.valueOf(now.getTime()), 'DesiredResolution__c' => 'I want a full refund.', 'DesiredRefundAmount__c' => 10000, 'Note__c' => 'My master bedroom is missing.' };
//        // create an initial offer as the Dispute Initiator
//        String offerHash;
//        System.runAs( initiator )
//        {
//            offerHash = SolutionCenterController.createOffer(offerFields);
//        }
//
//
//        testDispute = new Dispute__c(Id=newDispute.Id,  Status__c = 'Under review',  Stage__c = 'Stopped');
//        update  testDispute;
//        System.assertNotEquals( null, [SELECT DisputeStartDate__c FROM Dispute__c WHERE Id = :newDispute.Id].DisputeStartDate__c, 'Test Dispute DisputeStartDate__c not set');
//
//
//
//        Test.startTest();
//            System.runAs(testMIUser)
//            {
//
//                //Test changes from `Under review` to `Awaiting`
//                newDispute.Status__c = 'Awaiting';
//                update newDispute;
//
//                testDispute = [SELECT Stage__c, InitiatorConfirmationDueDate__c FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
//                System.assertEquals( 'Initiator confirmation needed', testDispute.Stage__c, 'Dispute Stage__c update incorrect.' );
//                System.assert( testDispute.InitiatorConfirmationDueDate__c > now, 'Dispute InitiatorConfirmationDueDate__c not reset.' );
//
//            }
//
//        Test.stopTest();
//
//    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Tests (RULE 18) - Reset applicable due dates and stages when an agent
    *               changes status back from ‘Under review’ to ‘In progress’ or ‘Awaiting’
    *               (Note: Status can be triggered to ‘Under review’ -OR- an agent can
    *               manually set the Status/Stage combo to ‘Under review’ > ‘Stopped’).
    */
    @IsTest
    private static void testTriggerUnderReviewExpired()
    {
        Dispute__c newDispute = SolutionCenterControllerTest.loadInitiatorDispute(true);

        Datetime now = System.now();
        User testMIUser = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'MIFrontLineUser' AND Profile.Name = '*Marketplace Integrity' LIMIT 1];
        User initiator = [SELECT Id FROM User WHERE ContactId = :newDispute.InitiatorContact__c LIMIT 1];
        newDispute.MaxOfDaysForResponderFirstAction__c = 1;
        newDispute.Status__c = 'Awaiting';
        newDispute.Stage__c = 'Responder first action needed';
        newDispute.PriorStage__c = null;
        newDispute.MaxofDaysforOffer__c = 1;
        update newDispute;

        Map<String, Object> offerFields = new Map<String, Object>{ 'DisputeHash__c' => newDispute.IdHash__c, 'ResolutionCompleteByDate__c' => Decimal.valueOf(now.getTime()), 'DesiredResolution__c' => 'I want a full refund.', 'DesiredRefundAmount__c' => 10000, 'Note__c' => 'My master bedroom is missing.' };
        // create an initial offer as the Dispute Initiator
        String offerHash;
        System.runAs( initiator )
        {
            offerHash = SolutionCenterController.createOffer(offerFields);
        }

        //SIMULATE Scheduled Batch, checking for expirations, get code coverage for all scenarios
        ScheduledDoDisputeBatch job = new ScheduledDoDisputeBatch();
        Database.QueryLocator loc = job.start(null);
        Dispute__c[] disputes = Database.query(loc.getQuery());
        disputes.clear();

        Dispute__c testDispute = [SELECT Status__c, Stage__c, (SELECT Status__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
        DisputeOffer__c offer = testDispute.DisputeOffers__r[0];
        offer.DisputeOfferExpirationDate__c = now.addDays(-10);
        update offer;
        disputes.add( testDispute );

        testDispute.InitiatorConfirmationDate__c = null;
        testDispute.ResponderFirstActionDate__c = null;
        testDispute.DisputeResolutionDueDate__c = now.addDays(-10);
        testDispute.InitiatorConfirmationDueDate__c = now.addDays(-10);
        testDispute.ResponderFirstActionDueDate__c = now.addDays(-10);
        update  testDispute;

        job.execute( null, disputes );
        System.assertEquals( 'Expired', [SELECT Status__c FROM DisputeOffer__c WHERE Id = :offer.Id].Status__c, 'Offer Status__c not `Expired` after FIRST run of scheduled/batch job.' );

//        offer.DisputeOfferExpirationDate__c = now.addDays(-10);
//        update offer;
//        testDispute.Status__c = 'Awaiting';
//        testDispute.Stage__c = 'Initiator confirmation needed';
//        update testDispute;
//
//        job.execute( null, disputes );

        Test.startTest();
            System.runAs(testMIUser)
            {

                offer.DisputeOfferExpirationDate__c = now.addDays(-10);
                update offer;
                testDispute.Status__c = 'In progress';
                testDispute.Stage__c = 'Offer pending';
                update testDispute;

                job.execute( null, disputes );

                testDispute = [SELECT Status__c, Stage__c, (SELECT Status__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
                System.assertEquals( 'Under review', testDispute.Status__c, 'Dispute Status not `Under review` after scheduled/batch job.' );
                System.assertEquals( 'Expired', testDispute.Stage__c, 'Dispute Stage__c not `Expired` after scheduled/batch job.' );
                System.assertEquals( 'Expired', testDispute.DisputeOffers__r[0].Status__c, 'Offer Status__c not `Expired` after scheduled/batch job.' );

                newDispute.Status__c = 'Awaiting';
                newDispute.Stage__c = 'Responder first action needed';
                update newDispute;

                testDispute = [SELECT Stage__c, ResponderFirstActionDueDate__c, MaxOfDaysForResponderFirstAction__c, MaxofDaysforOffer__c, (SELECT Status__c,DisputeOfferExpirationDate__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
                System.assertEquals( 'Responder first action needed', testDispute.Stage__c, 'Dispute Stage__c update incorrect.' );
                System.assert( testDispute.ResponderFirstActionDueDate__c > now, 'Dispute ResponderFirstActionDueDate__c not reset.' );
                System.assertEquals( 'Pending', testDispute.DisputeOffers__r[0].Status__c, 'Offer Status__c update incorrect.' );

            }

        Test.stopTest();

    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Tests (RULE 18) - Reset applicable due dates and stages when an agent
    *               changes status back from ‘Under review’ to ‘In progress’ or ‘Awaiting’
    *               (Note: Status can be triggered to ‘Under review’ -OR- an agent can
    *               manually set the Status/Stage combo to ‘Under review’ > ‘Stopped’).
    */
    @IsTest
    private static void testTriggerUnderReviewAgreementMade()
    {
        Dispute__c newDispute = SolutionCenterControllerTest.loadInitiatorDispute(true);

        Datetime now = System.now();
        User testMIUser = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'MIFrontLineUser' AND Profile.Name = '*Marketplace Integrity' LIMIT 1];
        User initiator = [SELECT Id FROM User WHERE ContactId = :newDispute.InitiatorContact__c LIMIT 1];
        User responder;
        newDispute.MaxOfDaysForResponderFirstAction__c = 1;
        newDispute.Status__c = 'Awaiting';
        newDispute.Stage__c = 'Responder first action needed';
        newDispute.PriorStage__c = null;
        newDispute.MaxofDaysforOffer__c = 1;
        update newDispute;

        Set<Id> newResponderAccountId = new Set<Id>();

        //create a portal user for the Responder contact for the test to be able to switch parties
        for( Contact ttContact : [SELECT Id, AccountId, Account.user_pk_id__c FROM Contact WHERE Id = :newDispute.ResponderContact__c])
        {
            if( null != ttContact.Account.user_pk_id__c ) //pk id required for User.FederationIdentifier
            {
                newResponderAccountId.add(ttContact.AccountId);
            }
        }

        User[] newUsers = new ThumbtackUserSSOProvisioner().createThumbackUsers( newResponderAccountId );
        insert newUsers;

        responder = [SELECT Id, ContactId, UserType, Username FROM User WHERE ContactId = :newDispute.ResponderContact__c LIMIT 1];

        Map<String, Object> offerFields = new Map<String, Object>{ 'DisputeHash__c' => newDispute.IdHash__c, 'ResolutionCompleteByDate__c' => Decimal.valueOf(now.getTime()), 'DesiredResolution__c' => 'I want a full refund.', 'DesiredRefundAmount__c' => 10000, 'Note__c' => 'My master bedroom is missing.' };
        // create an initial offer as the Dispute Initiator
        String offerHash;
        System.runAs( initiator )
        {
            offerHash = SolutionCenterController.createOffer(offerFields);
        }

        System.runAs( responder )
        {
            SolutionCenterController.acceptOffer( offerHash, now.addDays(1) );
        }

        Dispute__c testDispute;

        Test.startTest();
        System.runAs(testMIUser)
        {

            newDispute.Status__c = 'In progress';
            newDispute.Stage__c = 'Offer pending';
            update newDispute;

            testDispute = [SELECT MaxofDaysforOffer__c, (SELECT Status__c,DisputeOfferExpirationDate__c FROM DisputeOffers__r) FROM Dispute__c WHERE Id =:newDispute.Id LIMIT 1];
            System.assertEquals( 'Accepted', testDispute.DisputeOffers__r[0].Status__c, 'Offer Status__c update incorrect after Accept.' );
            System.assert( testDispute.DisputeOffers__r[0].DisputeOfferExpirationDate__c > now, 'Latest Offer DisputeOfferExpirationDate__c not reset.' );

            newDispute.Status__c = 'Under review';
            newDispute.Stage__c = 'Stopped';
            update newDispute;

        }

        Test.stopTest();

    }
}