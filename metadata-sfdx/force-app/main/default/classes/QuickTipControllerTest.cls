/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-17   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

@IsTest
private class QuickTipControllerTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
			insert new List<Account>{customer, pro};

			Contact customerContact = new Contact(LastName = 'Customer', AccountId = customer.Id, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			Contact proContact = new Contact(LastName = 'Pro', AccountId = pro.Id, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
			insert new List<Contact>{customerContact, proContact};

			MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id,
					bid_id__c = '123456', CustomerContact__c = customerContact.Id, ProContact__c = proContact.Id);
			insert incident;

			DisputeExperience__c defaultExp = new DisputeExperience__c (DefaultExperience__c = true, Status__c = 'Published',
					Name = 'Default', ResolutionOptions__c = 'Refund;Complete Work');

			insert defaultExp;

			Dispute__c d = new Dispute__c(Name = 'Test Dispute', InitiatorContact__c = customerContact.Id, InitiatorAccount__c = customer.Id,
				ResponderContact__c = proContact.Id, ResponderAccount__c = pro.Id, MIIncident__c = incident.Id, DisputeExperience__c = defaultExp.Id);
			insert d;

			DisputeOffer__c offer = new DisputeOffer__c(Name = 'Test offer', Dispute__c = d.Id);
			insert offer;

			DisputeContent__c successTip = new DisputeContent__c(Name = 'Test', Status__c = 'Published', Type__c = 'Automated tip',
					RecordTypeId = Schema.SObjectType.DisputeContent__c.getRecordTypeInfosByName().get('Content Template').getRecordTypeId());
			insert successTip;

			User newUser = new User();
			newUser.alias = 'custTest';
			newUser.email = 'zzzz@test.com';
			newUser.emailencodingkey = 'UTF-8';
			newUser.firstname = 'Contact';
			newUser.lastname = 'Customer';
			newUser.languagelocalekey = 'en_US';
			newUser.localesidkey = 'en_US';
			newUser.timezonesidkey = 'America/Los_Angeles';
			newUser.username = 'dsfkl@dslngsdn.omf';
			newUser.Country = 'United States';
			newUser.ProfileId = [SELECT id FROM Profile WHERE Name = 'Thumbtack User' LIMIT 1].Id;
			newUser.contactId = customerContact.Id;

			insert newUser;
		}
	}

	@IsTest
	static void testGetDispute()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Dispute__c dispute = [SELECT Id FROM Dispute__c];

			Test.startTest();

			System.assertEquals(dispute.Id, QuickTipController.getDispute(dispute.Id).Id);

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetUserId()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Customer'];

			Test.startTest();

			System.assertNotEquals(null, QuickTipController.getUserId(customer.Id));

			Test.stopTest();
		}
	}

	@IsTest
	static void testGetSuccessTips()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assert(!QuickTipController.getSuccessTips().isEmpty());

			Test.stopTest();
		}
	}

	@IsTest
	static void testSaveMessage()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Dispute__c dispute = [SELECT Id, (Select Id FROM DisputeOffers__r) FROM Dispute__c];
			Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Customer'];
			DisputeMessage__c dm = new DisputeMessage__c(Message__c = 'Testing', DisputeOffer__c = dispute.DisputeOffers__r[0].Id, ContactSharedWith__c = customer.Id);

			Test.startTest();

			System.assertEquals('Success', QuickTipController.saveMessage(dm, null));

			Test.stopTest();
		}
	}

	@IsTest
	static void testSaveMessageError()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Dispute__c dispute = [SELECT Id, (Select Id FROM DisputeOffers__r) FROM Dispute__c];
			Contact customer = [SELECT Id FROM Contact WHERE LastName = 'Customer'];
			DisputeMessage__c dm = new DisputeMessage__c(Message__c = 'Testing', DisputeOffer__c = dispute.DisputeOffers__r[0].Id, ContactSharedWith__c = customer.Id);
			delete new DisputeOffer__c(Id = dispute.DisputeOffers__r[0].Id);

			Test.startTest();

			System.assertNotEquals('Success', QuickTipController.saveMessage(dm, null));

			Test.stopTest();
		}
	}
}