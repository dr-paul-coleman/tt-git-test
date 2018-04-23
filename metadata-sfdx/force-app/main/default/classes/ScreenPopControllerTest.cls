/*
  Copyright (c) 2015, 2016, 2017 Thumbtack  All rights reserved.

 Change List:
 ------------

 Version    Date     Author            Description
 =======+===========+=================+=================================
 1.0     2015-12-19  Paul Coleman      Created
 =======+===========+=================+=================================*/
@IsTest
private class ScreenPopControllerTest {

	private static final String TEST_ANI = '9990008888';

	/**
	* @author Paul Coleman
	* @date 2017-10-17
	* @description A test that should redirect the screen pop page to a Case by record id.
	*/
	@IsTest
	private static void testInitializeLiveOps() {

		Account a = new Account(Name='Chester Tester',Phone=TEST_ANI);
		insert a;
		Contact c = [SELECT Id,AccountId,Phone FROM Contact WHERE AccountId = :a.Id];
		Test.setFixedSearchResults(new String[]{a.Id,c.Id});
		User u = [SELECT Id FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' LIMIT 1];
		System.runAs(u) {

			Test.startTest();
			//exception flow
			ScreenPopController cxt = new ScreenPopController(new ApexPages.StandardController(a));
			cxt.initialize(); //No query string parms

			//normal flow, find one contact, redirect to new Case
			PageReference pageRef = Page.ScreenPop;
			Test.setCurrentPage(pageRef);
			Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
			pageRef.getParameters().putAll(parms);

			PageReference redirectedPage = new ScreenPopController().initialize();
			System.assertNotEquals( NULL, redirectedPage.getRedirect(), 'ScreenPopControllerTest.initalize expected redirect to Case. ');
			Case[] cases = [SELECT Id FROM Case WHERE AccountId =:a.Id];
			System.assert( !cases.isEmpty(), 'Case not inserted properly by initalize function. ');
			System.assertEquals( cases[0].Id, redirectedPage.getParameters().get('id'), 'Case Id not added to page query parameters. ');

			Test.stopTest();

			//doSOSL code coverage
			ScreenPopController.doSOSL('FIND {bogusness} RETURNING CONTACT(Id)');
		}
	}


	/**
	* @author Paul Coleman
	* @date 2017-10-17
	* @description A test that should NOT change the Case OwnerId when the Record Type is a MTS/MI Id.
	*/
	//@IsTest
//    private static void testInitializeLiveOpsMTSRecordType() {
//
//        Account a = new Account(Name='Chester Tester',Phone=TEST_ANI);
//        insert a;
//        Contact c = [SELECT Id,AccountId,Phone FROM Contact WHERE AccountId = :a.Id];
//        Test.setFixedSearchResults(new String[]{a.Id,c.Id});
//        Id MI_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
//
//        User tackBot = [SELECT Id FROM User WHERE Username LIKE 'tsl-sysadmins@%' AND IsActive = true LIMIT 1];
//        System.runAs(tackBot) {
//
//            User notTackBot = [SELECT Id FROM User WHERE UserRole.Name = 'MI Front Line User' AND  IsActive = true AND Id != :tackBot.Id LIMIT 1];
//            Case cse = new Case( AccountId=a.Id, ContactId=c.Id, OwnerId=notTackBot.Id, Team__c='Marketplace Integrity', ANI__c=TEST_ANI, DNIS__c=TEST_ANI);
//            insert cse;
//            cse.RecordTypeId = MI_RECORD_TYPE_ID;
//            update cse;
//
//            Test.startTest();
//
//                PageReference pageRef = Page.ScreenPop;
//                Test.setCurrentPage(pageRef);
//                Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
//                pageRef.getParameters().putAll(parms);
//
//                ScreenPopController cxt = new ScreenPopController(new ApexPages.StandardController(a));
//                cxt.initialize();
//
//            Test.stopTest();
//
//            Case resultCase = [SELECT OwnerId, RecordTypeId FROM Case WHERE Id = :cse.Id LIMIT 1];
//            System.assertEquals( cse.RecordTypeId, resultCase.RecordTypeId, 'Case Record Type Id is not Marketplace Integrity, changed during code execution.');
//            System.assertEquals( notTackBot.Id, resultCase.OwnerId, 'Case OwnerId should not have changed for MTS Case record type.');
//
//        }
//    }

	/**
	* @author Paul Coleman
	* @date 2017-10-17
	* @description A test that should change the Case OwnerId when the Record Type is NOT a MTS/MI Id.
	*/
	@IsTest
	private static void testInitializeLiveOpsChangeOwnerId() {

		Account a = new Account(Name='Chester Tester',Phone=TEST_ANI);
		insert a;
		Contact c = [SELECT Id,AccountId,Phone FROM Contact WHERE AccountId = :a.Id];
		Test.setFixedSearchResults(new String[]{a.Id,c.Id});
		User tackBot = [SELECT Id FROM User WHERE Username LIKE 'tsl-sysadmins@%' AND IsActive = true LIMIT 1];
		System.runAs(tackBot) {

			User notTackBot = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' AND Id != :tackBot.Id LIMIT 1];
			Case cse = new Case(AccountId=a.Id,ContactId=c.Id,RecordTypeId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId(),OwnerId=notTackBot.Id,Team__c='Marketplace Integrity');
			insert cse;

			Test.startTest();

			PageReference pageRef = Page.ScreenPop;
			Test.setCurrentPage(pageRef);
			Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
			pageRef.getParameters().putAll(parms);

			ScreenPopController cxt = new ScreenPopController(new ApexPages.StandardController(a));
			cxt.initialize();

			Test.stopTest();

			System.assertNotEquals( 0, [SELECT count() FROM Case WHERE OwnerId = :tackBot.Id ], 'Case OwnerId should have changed for current test user. ');

		}
	}

	/**
	* @author Paul Coleman
	* @date 2017-10-17
	* @description A test that should return null from the controller intitialize function for finding multiple contacts.
	*/
	@IsTest
	private static void testInitializeLiveOpsMultipleContactRecords() {

		Account a = new Account(Name='Chester Tester');
		insert a;
		Contact c = [SELECT Id,AccountId,Phone FROM Contact WHERE AccountId = :a.Id];
		Contact c2 = new Contact(AccountId=a.Id,LastName='Tester2',FirstName='c2',Phone=TEST_ANI,Email='c2@testing.com');
		insert c2;
		User tackBot = [SELECT Id FROM User WHERE Username LIKE 'tsl-sysadmins@%' AND IsActive = true LIMIT 1];
		System.runAs(tackBot) {

			Test.startTest();

			//code coverage for dupe Contacts (same phone number)
			Test.setFixedSearchResults(new String[]{a.Id,c.Id,c2.Id});
			PageReference popRef = Page.ScreenPop;
			Test.setCurrentPage(popRef);
			Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
			popRef.getParameters().putAll(parms);
			System.assert( NULL == new ScreenPopController().initialize(), 'Expected null PageReference from "MULTIPLE Contacts FOUND" condition');

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

		User tackBot = [SELECT Id FROM User WHERE Username LIKE 'tsl-sysadmins@%' AND IsActive = true LIMIT 1];
		System.runAs(tackBot) {

			Test.startTest();

			//code coverage for dupe Contacts (same phone number)
			PageReference popRef = Page.ScreenPop;
			Test.setCurrentPage(popRef);
			Map<String,String> parms = new Map<String, String>{'ANI'=>TEST_ANI,'DNIS'=>TEST_ANI};
			popRef.getParameters().putAll(parms);
			new ScreenPopController().initialize(); //should result in a new blank case

			Case[] resultCases = [SELECT Id, ContactId, AccountId FROM Case WHERE ANI__c = :TEST_ANI];
			System.assertEquals( 1, resultCases.size(), 'Screen pop did not create a new Case' );
			Case resultCase = resultCases[0];
			System.assert( NULL == resultCase.ContactId && NULL == resultCase.AccountId, 'New case has a Contact or Account assigned' );

			new ScreenPopController().initialize(); //should result in a new blank case

			Test.stopTest();

			Case[] run2Cases = [SELECT Id, ContactId, AccountId FROM Case WHERE ANI__c = :TEST_ANI];
			System.assertEquals( 1, resultCases.size(), 'Screen pop created a duplicate Case' );

		}

	}
}