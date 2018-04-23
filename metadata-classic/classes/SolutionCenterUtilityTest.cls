/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       3/2/18      pcoleman           Created to test utility functions
========+============+=================+===============================================*/
@IsTest
public with sharing class SolutionCenterUtilityTest
{
    /**
    * @author Paul Coleman
    * @date 2018-03-02
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
    * @date 2018-03-02
    * @description Tests the insert of a Case with related Dispute from Help Center via the caseCreate() VFRMO dml override function.
    */
    @IsTest
    private static void testInsertDisputeCase()
    {
        User initiator; // to be created on the fly
        Dispute__c newDispute;
        System.runAs( TestUtilities.USER_TACK_BOT )
        {
            newDispute = SolutionCenterControllerTest.loadInitiatorDispute(true);
            SolutionCenterControllerTest.insertIncident(newDispute);
        }

        Test.startTest();

            initiator = [SELECT Id FROM User WHERE ContactId = :newDispute.InitiatorContact__c LIMIT 1];
            System.runAs( initiator )
            {
                Map<String, Object> caseFields = new Map<String, Object>{
                        'DisputeIdHash__c' => newDispute.IdHash__c,
                        'OwnerId' => [SELECT Id FROM Group WHERE Name = 'Marketplace Integrity' AND Type = 'Queue'].Id, //mark
                        'Description' => 'Halp.',
                        'Subject' => 'Testing on more time',
                        'Category__c' => 'Marketplace Integrity',
                        'SubCategory__c' => 'Incident',
                        'HelpCenterVisitSubTopic__c' => 'MTS Subtopic 2',
                        'HelpCenterVisitTopic__c' => 'MTS Topic 2',
                        'Origin' => 'Web',
                        'SuppliedEmail' => 'ben@ben.ben',
                        'SuppliedName' => 'Ben Ben',
                        'RecordTypeId' => Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId()
                };
                HCControllerRMO.caseCreate( 'Case', caseFields );
            }

        Test.stopTest();

        //assert related offer
        Case[] insertedCase = [SELECT Id, Dispute__c, Incident__c FROM Case WHERE Dispute__c = :newDispute.Id LIMIT 1];
        System.assertEquals( false, insertedCase.isEmpty(), 'Case not created related to Dispute.');
        System.assertEquals( newDispute.MIIncident__c, insertedCase[0].Incident__c, 'Inserted Case not related to Dispute Incident.');

        // Grabbing code coverage for potential Database DML Errors in functions supporting SolutionCenterController
        // functions like createOffer(), createMessage(), updateDisputeDescription() etc:
        try
        {
            SolutionCenterUtility.createRecord(new Dispute__c(Id = newDispute.Id), SolutionCenterUtility.DisputeDML.GET_ID_HASH);
        } catch (SolutionCenterUtility.SolutionCenterException se) {}

        try
        {
            SolutionCenterUtility.updateRecord( new Dispute__c(), SolutionCenterUtility.DisputeDML.GET_ID_HASH );
        } catch (SolutionCenterUtility.SolutionCenterException se) {}
    }

}