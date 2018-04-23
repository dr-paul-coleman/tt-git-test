/**
  Copyright (c) 2017 Thumbtack  All rights reserved.

  Change List:
  ------------

  Version    Date     Author            Description
  =======+===========+=================+=================================
  1.0     2017-12-14  Mendel Guillaume  Created
  =======+===========+=================+=================================
 */

@IsTest
private class ContactTriggerHandlerTest
{
	@IsTest
	static void testContactOwnershipSetToTackbot()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Test.startTest();
			Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(), Name = 'Test Account');
			insert a;

			Contact c = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact');
			insert c;
			Test.stopTest();

			c = [SELECT OwnerId FROM Contact WHERE Id = :c.Id];
			System.assertEquals(TackBotUtility.getTackBotUser().Id, c.OwnerId);
		}
	}

	@IsTest
	static void testContactOwnershipNotSetToTackbot()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Test.startTest();
			Account a = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Managed Account').getRecordTypeId(), Name = 'Test Account');
			insert a;

			Contact c = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact');
			insert c;
			Test.stopTest();

			c = [SELECT OwnerId FROM Contact WHERE Id = :c.Id];
			System.assertNotEquals(TackBotUtility.getTackBotUser().Id, c.OwnerId);
		}
	}
}