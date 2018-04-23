/*
  Copyright (c) 2015 - 2017 Thumbtack  All rights reserved.

 Change List:
 ------------

 Version    Date     Author            Description
 =======+===========+=================+=================================
 1.0     2015-12-19  Paul Coleman      Created 
 1.0     2018-04-09  Paul Coleman      Modified doCaseQuery() query filter
                                          parms for changing pl values.
                                          Used TestUtilities functions
 =======+===========+=================+=================================*/
@IsTest
private class LiveOpsInboundScreenPopControllerTest {

    private static final String TEST_ANI = '9990008888';

    /**
   * @author Paul Coleman
   * @date 2018-04-09
   * @description Inserts a set of four test Accounts.
   */
    @TestSetup
    private static void createTestAccounts()
    {
        TestUtilities.insertFourCoreThumbtackUsers();
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description A test that should redirect the screen pop page to a Case by record id.
    */
    @IsTest
    private static void testInitializeLiveOps() {

        Account[] users = TestUtilities.getAllTestAccounts().values();
        for( Account user: users )
        {
            user.sav_notifications_phn_phone_number__c = TEST_ANI;
            user.sav_phn_phone_number__c = TEST_ANI;
            user.Contacts[0].Phone = TEST_ANI;
        }
        update users;

        Test.setFixedSearchResults(new String[]{ users[0].Id, users[0].contacts[0].Id});

        User testCSUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = '*Customer Success - TSL' LIMIT 1];
        System.runAs( testCSUser )
        {

            // exception flow (no query string parms)
            LiveOpsInboundScreenPopController cxt = new LiveOpsInboundScreenPopController(new ApexPages.StandardController(users[0]));

            Test.startTest();

                //normal flow, find one contact, redirect to new Case
                PageReference pageRef = Page.LiveOpsInboundScreenPop;
                Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
                pageRef.getParameters().putAll(parms);
                Test.setCurrentPage(pageRef);

                PageReference redirectedPage = new LiveOpsInboundScreenPopController().initialize();
                System.assertNotEquals( NULL, redirectedPage.getRedirect(), 'LiveOpsInboundScreenPopControllerTest.initalize expected redirect to Case. ');
                Case[] cases = [SELECT Id,OwnerId FROM Case WHERE AccountId =:users[0].Id];
                System.assert( 1==cases.size(), 'Case not inserted properly by initialize function. ');
                System.debug( LoggingLevel.WARN, cases );
                System.assertEquals( cases[0].Id, redirectedPage.getParameters().get('id'), 'Case Id not added to page query parameters. ');
                System.assertEquals( cases[0].OwnerId , testCSUser.Id, 'Case OwnerId should have changed for current test user. ');

            Test.stopTest();

            //doSOSL code coverage
            LiveOpsInboundScreenPopController.doSOSL('FIND {bogusness} RETURNING CONTACT(Id)');
        }
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description A test that should return null from the controller intitialize function for finding multiple contacts.
    */
    @IsTest
    private static void testInitializeLiveOpsMultipleContactRecords()
    {

        Account[] users = TestUtilities.getAllTestAccounts().values();
        for( Account user: users )
        {
            user.sav_notifications_phn_phone_number__c = TEST_ANI;
            user.sav_phn_phone_number__c = TEST_ANI;
            user.Contacts[0].Phone = TEST_ANI;
        }
        update users;

        Test.setFixedSearchResults(new String[]{ users[0].Id, users[0].contacts[0].Id, users[1].Id, users[1].contacts[0].Id});

        User testCSUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = '*Customer Success - TSL' LIMIT 1];
        System.runAs( testCSUser )
        {

            Test.startTest();

                //code coverage for dupe Contacts (same phone number)
                PageReference popRef = Page.LiveOpsInboundScreenPop;
                Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
                popRef.getParameters().putAll(parms);

            Test.setCurrentPage(popRef);

            System.assert( NULL == new LiveOpsInboundScreenPopController().initialize(), 'Expected null PageReference from "MULTIPLE Contacts FOUND" condition');

            Test.stopTest();
        }

    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description A test that result in a new case, but with ContactId/AccountId null (NOT FOUND), then a revisit to the page should NOT create another case (AKA phone call no answered).
    */
    @IsTest
    private static void testInitializeLiveOpsNoContactDupePrevention() {

        User testCSUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = '*Customer Success - TSL' LIMIT 1];
        System.runAs( testCSUser )
        {

            Test.startTest();

                //code coverage for dupe Contacts (same phone number)
                PageReference popRef = Page.LiveOpsInboundScreenPop;
                Test.setCurrentPage(popRef);
                Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
                popRef.getParameters().putAll(parms);
                LiveOpsInboundScreenPopController ctx = new LiveOpsInboundScreenPopController(); //should result in a new blank case
                ctx.initialize();

                Case[] resultCases = [SELECT Id, ContactId, AccountId, Origin, IsClosed, RecordTypeId, RecordType.Name, OwnerId, Owner.Name, ANI__c, DNIS__c  FROM Case WHERE ANI__c = :TEST_ANI];
                System.assertEquals( 1, resultCases.size(), 'Screen pop did not create a new Case' );
                Case resultCase = resultCases[0];
                System.debug( LoggingLevel.WARN, JSON.serialize(resultCase) );
                System.assert( NULL == resultCase.ContactId && NULL == resultCase.AccountId, 'New case has a Contact or Account assigned' );

                Case searchedCase =  ctx.doCaseQuery( NULL, TEST_ANI, TEST_ANI);
                System.assertEquals( resultCase.Id, searchedCase.Id, 'New case by ANI not found after insert. Changed by WorkFlow?' );

                // test for duplicate Case creation by ANI
                new LiveOpsInboundScreenPopController().initialize(); //should NOT result in a new blank case for same ANI

            Test.stopTest();

            System.assertNotEquals( 2, [SELECT count() FROM Case WHERE ANI__c = :TEST_ANI], 'Screen pop created a duplicate case' );

        }

    }
}