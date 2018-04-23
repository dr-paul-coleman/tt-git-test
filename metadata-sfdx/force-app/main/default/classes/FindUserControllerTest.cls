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
Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-07   Mendel Guillaume       Created
========+============+=================+===============================================*/

@IsTest
private class FindUserControllerTest
{
	@testSetup
	static void setup()
	{
		List<Account> accts = new List<Account>();
		List<Contact> contacts = new List<Contact>();
		accts.add(new Account(Name = 'Test SFDC1', usr_user_id__c = 12345, usr_last_name__c = 'SFDC1', usr_first_name__c = 'Test1', usr_email__c = 'sfdc1@gmail.com'));
		accts.add(new Account(Name = 'Test SFDC2', usr_user_id__c = 123456, usr_last_name__c = 'SFDC2', usr_first_name__c = 'Test2', usr_email__c = 'sfdc2@gmail.com'));

		insert accts;

		Case c = new Case(Status = 'New', Subject = 'Test Case', Description = 'Test Case');
		insert c;
	}

	static testMethod void testFind()
	{
		List<Account> accounts = [SELECT Id FROM Account];
		List<Contact> contacts = [SELECT id FROM Contact];

		List<Id> fixedSearchResults = new List<Id>();

		fixedSearchResults.add(accounts[0].Id);
		fixedSearchResults.add(accounts[1].Id);
		fixedSearchResults.add(contacts[0].Id);
		fixedSearchResults.add(contacts[1].Id);

		Test.setFixedSearchResults(fixedSearchResults);

		List<FindUserController.FindUserResult> results = FindUserController.findUser('Test');
		System.assertEquals(5, results.size());
		System.assertEquals(contacts[0].Id, results[0].recordId);
		System.assertEquals(contacts[1].Id, results[1].recordId);

		System.assertEquals(accounts[0].Id, results[0].accountId);

		System.assertEquals('Test Ext1', results[2].name);
		System.assertEquals('Test', results[2].first);
		System.assertEquals('Ext1', results[2].last);
		System.assertEquals('12345', results[2].userId);
		System.assertEquals(false, results[2].isContact);
		System.assertEquals('Biz 1', results[2].accountName);
		System.assertEquals('Pro', results[2].recordType);
		System.assertEquals('ext1@gmail.com', results[2].email);
		System.assertEquals(null, results[2].billingCity);
		System.assertEquals('NY', results[2].billingState);
		System.assertEquals('555-555-5550', results[2].phone);
		System.assertEquals(true, results[2].isExternalUser);
	}

	static testMethod void testGetRecordTypes()
	{
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();

		System.assert(!options.isEmpty());
	}

	static testMethod void testGetCase()
	{
		Case c = [SELECT id FROM Case];

		System.assertEquals(c.Id, FindUserController.getCase(c.Id).Id);
	}

	static testMethod void testUpdateCase()
	{
		List<Account> accounts = [SELECT Id FROM Account];
		List<Contact> contacts = [SELECT id FROM Contact];
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		System.assertEquals(true, FindUserController.updateCase(accounts[0].Id, contacts[0].Id, c.Id).success);
	}

	static testMethod void testUpdateCaseError()
	{
		List<Account> accounts = [SELECT Id FROM Account];
		List<Contact> contacts = [SELECT id FROM Contact];
		Case c = [SELECT id, ContactId, AccountId FROM Case];
		delete c;

		System.assertEquals(false, FindUserController.updateCase(accounts[0].Id, contacts[0].Id, c.Id).success);
	}

	static testMethod void testcreateAccountContactFromUserError()
	{
		List<FindUserController.FindUserResult> results = FindUserController.findUser('Test');
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		//user id already in sfdc
		System.assertEquals(false, FindUserController.createAccountContactFromUser(results[0].user, options[0].value, c.Id).success);
	}

	static testMethod void testcreateAccountContactFromUser()
	{
		List<FindUserController.FindUserResult> results = FindUserController.findUser('Test');
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		System.assertEquals(true, FindUserController.createAccountContactFromUser(results[1].user, options[0].value, c.Id).success);
	}

	static testMethod void testUpdateAccountContactFromUser()
	{
		List<FindUserController.FindUserResult> results = FindUserController.findUser('Test');
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		Contact cont = FindUserController.findExistingContact(12345);
		System.assertNotEquals(null, c);

		System.assertEquals(true, FindUserController.updateAccountContactFromUser(results[1].user, cont.AccountId, cont.Id, c.Id).success);
	}

	static testMethod void testcreateNewAccountContact()
	{
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		System.assertEquals(true, FindUserController.createNewAccountContact('test@gmail.com', 'Test3', 'User3', options[0].value, 123, c.Id).success);
	}

	static testMethod void testcreateNewAccountContact2()
	{
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		System.assertEquals(true, FindUserController.createNewAccountContact('test@gmail.com', 'Test3', 'User3', options[1].value, null, c.Id).success);
	}

	static testMethod void testcreateNewAccountContactError()
	{
		List<FindUserController.Option> options = FindUserController.getAccountRecordTypes();
		Case c = [SELECT id, ContactId, AccountId FROM Case];

		//user id already in sfdc
		System.assertEquals(false, FindUserController.createNewAccountContact('test@gmail.com', 'Test3', 'User3', options[0].value, 12345, c.Id).success);
	}
}