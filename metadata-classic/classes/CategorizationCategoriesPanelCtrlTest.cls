/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-01   Mendel Guillaume   Created
   1.1      2018-01-03   Mendel Guillaume   Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationCategoriesPanelCtrlTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Case c = new Case(AccountId = customer.Id, Subject='Test Case', Status = 'New', Origin = 'Suggestion Box' );
			insert c;

			List<CategorizationDefinition__c> categories = new List<CategorizationDefinition__c>();
			categories.add(new CategorizationDefinition__c(Name = 'Parent 1', Active__c = true, AvailableOnCase__c = true, Pro__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Parent 2', Active__c = true, AvailableOnCase__c = true, Customer__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Parent 3', Active__c = true, AvailableOnCase__c = true, Functional__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			insert categories;

			categories.add(new CategorizationDefinition__c(Name = 'Child 1a', Active__c = true, AvailableOnCase__c = true,
					Pro__c = true, ParentCategory__c = categories[0].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Child 2a', Active__c = true, AvailableOnCase__c = true,
					Pro__c = true, ParentCategory__c = categories[0].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Child 1b', Active__c = true, AvailableOnCase__c = true,
					Customer__c = true, ParentCategory__c = categories[1].Id,  CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Child 1c', Active__c = true, AvailableOnCase__c = true,
					Functional__c = true, ParentCategory__c = categories[2].Id,  CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			upsert categories;
		}
	}

	@IsTest
	static void testGetCategoryTypes()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id FROM Case];

			Test.startTest();

			List<CategorizationCategoriesPanelController.CategoryType> cTypes = CategorizationCategoriesPanelController.getCategoryTypes(c.Id);

			Test.stopTest();

			System.assertEquals(3, cTypes.size(), 'Invalid size');
			System.assertEquals('Pro', cTypes[0].name, 'Invalid name');
			System.assertEquals('Customer', cTypes[1].name, 'Invalid name');
			System.assertEquals('Other', cTypes[2].name, 'Invalid name');
			System.assertEquals(1, cTypes[0].categories.size(), 'Invalid size');
			System.assertEquals(1, cTypes[1].categories.size(), 'Invalid size');
			System.assertEquals(1, cTypes[2].categories.size(), 'Invalid size');
			System.assertEquals(2, cTypes[0].categories[0].subCategories.size(), 'Invalid size');
			System.assertEquals(1, cTypes[1].categories[0].subCategories.size(), 'Invalid size');
			System.assertEquals(1, cTypes[2].categories[0].subCategories.size(), 'Invalid size');
			System.assertEquals(false, cTypes[0].categories[0].subSelected, 'Category selected');
			System.assertEquals(false, cTypes[1].categories[0].subSelected, 'Category selected');
			System.assertEquals(false, cTypes[2].categories[0].subSelected, 'Category selected');
		}
	}

	//Inactive Categorization Definition
	@IsTest
	static void testGetCategoryTypes2()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id FROM Case];
			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Parent 2'];
			cd.Active__c = false;

			Test.startTest();

			update  cd;
			List<CategorizationCategoriesPanelController.CategoryType> cTypes = CategorizationCategoriesPanelController.getCategoryTypes(c.Id);

			Test.stopTest();

			System.assertEquals(2, cTypes.size(), 'Invalid size');
			System.assertEquals('Pro', cTypes[0].name, 'Invalid name');
			System.assertEquals('Other', cTypes[1].name, 'Invalid name');
		}
	}

	//Existing Categorization records
	@IsTest
	static void testGetCategoryTypes3()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id FROM Case];
			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Child 1b'];

			Test.startTest();
			CategorizationCategoriesListController.CategoryWrapper newCw = CategorizationCategoriesListController.addCategory(cd.Key__c, c.Id);
			String result = CategorizationCategoriesListController.updateCategorization(new List<Categorization__c> {newCw.category});
			List<CategorizationCategoriesPanelController.CategoryType> cTypes = CategorizationCategoriesPanelController.getCategoryTypes(c.Id);
			Test.stopTest();

			System.assertEquals('Success', result, 'Update failed');
			System.assertEquals(3, cTypes.size(), 'Invalid size');
			System.assertEquals('Pro', cTypes[0].name, 'Invalid name');
			System.assertEquals('Customer', cTypes[1].name, 'Invalid name');
			System.assertEquals('Other', cTypes[2].name, 'Invalid name');
			System.assertEquals(false, cTypes[0].categories[0].subSelected, 'Category selected');
			System.assertEquals(true, cTypes[1].categories[0].subSelected, 'Category not selected');
			System.assertEquals(false, cTypes[2].categories[0].subSelected, 'Category selected');
		}
	}
}