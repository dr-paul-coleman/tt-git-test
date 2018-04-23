/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-07   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

@IsTest
private class WorkItemTransferControllerTest
{
	@TestSetup
	static void createData()
	{
		User testUser = [SELECT Id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Group lowIntent = [SELECT Id FROM Group WHERE Name = 'Low Intent Disputes' LIMIT 1];
			WorkItem__c item = new WorkItem__c(Type__c = 'BGC Identity Mismatch', Name = 'Wi1', Status__c = 'New',
					OwnerId = lowIntent.Id, RecordTypeId = WorkItemHelper.STANDARD_WORK_ITEM_RECORD_TYPE_ID);
			WorkItem__c item1 = new WorkItem__c(Name = 'Wi2', Status__c = 'New', OwnerId = lowIntent.Id,
					RecordTypeId = WorkItemHelper.BLACKLISTED_NUMBER_RECORD_TYPE_ID);
			insert new List<WorkItem__c>{item, item1};
		}
	}

	@IsTest
	static void testGetItems()
	{
		User testUser = [SELECT Id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			List<WorkItemTransferController.WorkItemGroup> groups = WorkItemTransferController.getWorkItemsByType();

			for (WorkItemTransferController.WorkItemGroup g : groups)
			{
				if (g.name == 'BGC Identity Mismatch')
				{
					System.assertEquals(1, g.count);
				}
				else
				{
					System.assertEquals(0, g.count);
				}
			}
		}
	}

	@IsTest
	static void testTakeItem()
	{
		User testUser = [SELECT Id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			WorkItem__c item = WorkItemTransferController.takeWorkItem('BGC Identity Mismatch');

			System.assertNotEquals(null, item);
		}
	}

	@IsTest
	static void testGetItemsRT()
	{
		User testUser = [SELECT Id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			List<WorkItemTransferController.WorkItemGroup> groups = WorkItemTransferController.getWorkItemsByRecordType();

			for (WorkItemTransferController.WorkItemGroup g : groups)
			{
				if (g.name == 'Blacklisted Number')
				{
					System.assertEquals(1, g.count);
				}
				else
				{
					System.assertEquals(0, g.count);
				}
			}
		}
	}

	@IsTest
	static void testTakeItemRT()
	{
		User testUser = [SELECT Id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			WorkItem__c item = WorkItemTransferController.takeWorkItemRT('Blacklisted Number');

			System.assertNotEquals(null, item);
		}
	}
}