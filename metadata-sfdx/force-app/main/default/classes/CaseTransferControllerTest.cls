/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-11-21   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

@IsTest
private class CaseTransferControllerTest
{
	@TestSetup
	static void createData()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Case c = new Case(AccountId = customer.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Suggestion Box');
			insert c;
		}
	}

	@IsTest
	static void testGetCase()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = [SELECT Id FROM Case];
			System.assertEquals(testUser.Id, CaseTransferController.getCase(c.Id).OwnerId);
		}
	}

	@IsTest
	static void testAssignToMe()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = [SELECT Id FROM Case];

			CaseTransferController.assignToMe(c.Id);

			c = [SELECT Id, OwnerId FROM Case];
			System.assertEquals(c.OwnerId, UserInfo.getUserId());
		}
	}

	@IsTest
	static void testAssignToQueue()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = [SELECT Id FROM Case];
			Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name Like '%Noise' LIMIT 1];

			CaseTransferController.assignCase(c.Id, g.Id, 'Testing', null);

			c = [SELECT Id, OwnerId FROM Case];
			System.assertEquals(c.OwnerId, g.Id);

			CaseUpdateHistory__c cuh = [SELECT EscalatedCaseType__c, EscalatedCase__c FROM CaseUpdateHistory__c WHERE Case__c = :c.Id
											AND RecordTypeId = :CaseUpdateHistory__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Case Transfer Update').getRecordTypeId()
										ORDER BY CreatedDate desc];

			System.assertEquals(null, cuh.EscalatedCaseType__c);
			System.assertEquals(false, cuh.EscalatedCase__c);
		}
	}

	@IsTest
	static void testEscalation()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = [SELECT Id FROM Case];

			CaseTransferController.assignCase(c.Id, UserInfo.getUserId(), 'Testing', 'Callback');

			c = [SELECT Id, OwnerId FROM Case];
			System.assertEquals(c.OwnerId, UserInfo.getUserId());

			CaseUpdateHistory__c cuh = [SELECT EscalatedCaseType__c, EscalatedCase__c FROM CaseUpdateHistory__c WHERE Case__c = :c.Id
											AND RecordTypeId = :CaseUpdateHistory__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Case Transfer Update').getRecordTypeId()
										ORDER BY CreatedDate desc];
			System.assertEquals('Callback', cuh.EscalatedCaseType__c);
			System.assertEquals(true, cuh.EscalatedCase__c);
		}
	}

	@IsTest
	static void testGetUsersForPersonTransfer()
	{
		System.assertNotEquals(null, CaseTransferController.getUsersForPersonTransfer());
	}

	@IsTest
	static void testGetUsersForEscalationTransfer()
	{
		System.assertNotEquals(null, CaseTransferController.getUsersForEscalationTransfer());
	}

	@IsTest
	static void testGetGroupsForTransfer()
	{
		System.assertNotEquals(null, CaseTransferController.getGroupsForTransfer());
	}
}