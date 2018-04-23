/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-01   Mendel Guillaume   Created
   1.1      2018-01-03   Mendel Guillaume   Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationCategoriesListCtrlTest
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

			Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1',
					Name = 'FN LN 1-1', Account__c = customer.Id, FirstName__c = 'Test First Name ', LastName__c = 'Test Last Name ' ,
					sav_available_service_id__c = 1, user_id__c = '1'  , rca_request_category_id__c = '1', zip_cbsa_code__c = '1',
					zip_cbsa_name__c = 'Utah');
			insert enrollment;

			List<CategorizationDefinition__c> parentCategories = new List<CategorizationDefinition__c>();
			parentCategories.add(new CategorizationDefinition__c(Name = 'Parent 1', Active__c = true, AvailableOnCase__c = true, Pro__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			parentCategories.add(new CategorizationDefinition__c(Name = 'Parent 2', Active__c = true, AvailableOnCase__c = true, Customer__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			parentCategories.add(new CategorizationDefinition__c(Name = 'Account Parent 1', Active__c = true, AvailableOnAccount__c = true, Pro__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			parentCategories.add(new CategorizationDefinition__c(Name = 'Account Parent 2', Active__c = true, AvailableOnAccount__c = true, Customer__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			parentCategories.add(new CategorizationDefinition__c(Name = 'Enrollment Parent 1', Active__c = true, AvailableOnEnrollment__c = true, Pro__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			parentCategories.add(new CategorizationDefinition__c(Name = 'Enrollment Parent 2', Active__c = true, AvailableOnEnrollment__c = true, Customer__c = true,
					CategoryType__c = 'Category', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			insert parentCategories;

			List<CategorizationDefinition__c> categories = new List<CategorizationDefinition__c>();
			categories.add(new CategorizationDefinition__c(Name = 'Child 1a', Active__c = true, AvailableOnCase__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[0].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Child 2a', Active__c = true, AvailableOnCase__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[0].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Child 1b', Active__c = true, AvailableOnCase__c = true,
					Customer__c = true, ParentCategory__c = parentCategories[1].Id,  CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			categories.add(new CategorizationDefinition__c(Name = 'Account Child 1a', Active__c = true, AvailableOnAccount__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[2].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Account Child 2a', Active__c = true, AvailableOnAccount__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[2].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Account Child 1b', Active__c = true, AvailableOnAccount__c = true,
					Customer__c = true, ParentCategory__c = parentCategories[3].Id,  CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			categories.add(new CategorizationDefinition__c(Name = 'Enrollment Child 1a', Active__c = true, AvailableOnEnrollment__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[4].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Enrollment Child 2a', Active__c = true, AvailableOnEnrollment__c = true,
					Pro__c = true, ParentCategory__c = parentCategories[4].Id, CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));
			categories.add(new CategorizationDefinition__c(Name = 'Enrollment Child 1b', Active__c = true, AvailableOnEnrollment__c = true,
					Customer__c = true, ParentCategory__c = parentCategories[5].Id,  CSATEligible__c = 'Eligible',
					CategoryType__c = 'Subcategory', RecordTypeId = CategorizationCategoriesPanelController.CATEGORIZATION_DEFINITION_CATEGORY_RT_ID));

			upsert categories;
		}
	}

	@IsTest
	static void testCategoriesListController()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id FROM Case];
			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Child 1b'];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationCategoriesListController.getCategories(c.Id);
			System.assertEquals(0, cws.size(), 'Categories found');

			CategorizationCategoriesListController.CategoryWrapper newCw = CategorizationCategoriesListController.addCategory(cd.Key__c, c.Id);
			System.assertNotEquals(null, newCw, 'New category not set');
			System.assertEquals(null, newCw.tooltip, 'New category has tooltip');
			System.assertEquals(null, newCw.sentimentScale, 'New category has sentiment scale');
			System.assertEquals(false, newCw.preventRecordCreation, 'New category prevent record creation is true');

			Test.startTest();

			String result = CategorizationCategoriesListController.updateCategorization(new List<Categorization__c> {newCw.category});

			Test.stopTest();

			System.assertEquals('Success', result, 'Update failed');

			cws = CategorizationCategoriesListController.getCategories(c.Id);
			System.assertEquals(1, cws.size(), 'Category size not 1');
			System.assertEquals(cd.Id, cws[0].catDefinition.Id, 'Invalid Category Definition Id');
			System.assertEquals(cd.Key__c, cws[0].category.DefinitionKey__c, 'Invalid key');
		}
	}

	@IsTest
	static void testCategoriesListControllerOnAccount()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account a = [SELECT Id FROM Account];
			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Account Child 1b'];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationCategoriesListController.getCategories(a.Id);
			System.assertEquals(0, cws.size(), 'Categories found');

			CategorizationCategoriesListController.CategoryWrapper newCw = CategorizationCategoriesListController.addCategory(cd.Key__c, a.Id);
			System.assertNotEquals(null, newCw, 'New category not set');
			System.assertEquals(null, newCw.tooltip, 'New category has tooltip');
			System.assertEquals(null, newCw.sentimentScale, 'New category has sentiment scale');
			System.assertEquals(false, newCw.preventRecordCreation, 'New category prevent record creation is true');

			Test.startTest();

			String result = CategorizationCategoriesListController.updateCategorization(new List<Categorization__c> {newCw.category});

			Test.stopTest();

			System.assertEquals('Success', result, 'Update failed');

			cws = CategorizationCategoriesListController.getCategories(a.Id);
			System.assertEquals(1, cws.size(), 'Category size not 1');
			System.assertEquals(cd.Id, cws[0].catDefinition.Id, 'Invalid Category Definition Id');
			System.assertEquals(cd.Key__c, cws[0].category.DefinitionKey__c, 'Invalid key');
		}
	}

	@IsTest
	static void testCategoriesListControllerOnEnrollment()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Enrollment__c e = [SELECT Id FROM Enrollment__c];
			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Enrollment Child 1b'];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationCategoriesListController.getCategories(e.Id);
			System.assertEquals(0, cws.size(), 'Categories found');

			CategorizationCategoriesListController.CategoryWrapper newCw = CategorizationCategoriesListController.addCategory(cd.Key__c, e.Id);
			System.assertNotEquals(null, newCw, 'New category not set');
			System.assertEquals(null, newCw.tooltip, 'New category has tooltip');
			System.assertEquals(null, newCw.sentimentScale, 'New category has sentiment scale');
			System.assertEquals(false, newCw.preventRecordCreation, 'New category prevent record creation is true');

			Test.startTest();

			String result = CategorizationCategoriesListController.updateCategorization(new List<Categorization__c> {newCw.category});

			Test.stopTest();

			System.assertEquals('Success', result, 'Update failed');

			cws = CategorizationCategoriesListController.getCategories(e.Id);
			System.assertEquals(1, cws.size(), 'Category size not 1');
			System.assertEquals(cd.Id, cws[0].catDefinition.Id, 'Invalid Category Definition Id');
			System.assertEquals(cd.Key__c, cws[0].category.DefinitionKey__c, 'Invalid key');
		}
	}

	//Saving PreventRecordCreation__c category
	@IsTest
	static void testCategoriesListController2()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, Category__c, SubCategory__c FROM Case];
			System.assertEquals(null, c.Category__c, 'Case category set');
			System.assertEquals(null, c.SubCategory__c, 'Case subcategory set');

			CategorizationDefinition__c cd = [SELECT Id, Key__c FROM CategorizationDefinition__c WHERE Name = 'Child 1b'];
			cd.PreventRecordCreation__c = true;
			cd.HelpText__c = 'Help';
			cd.SentimentScale__c = '2';
			update cd;

			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationCategoriesListController.getCategories(c.Id);
			System.assertEquals(0, cws.size(), 'Size not 0');

			CategorizationCategoriesListController.CategoryWrapper newCw = CategorizationCategoriesListController.addCategory(cd.Key__c, c.Id);
			System.assertNotEquals(null, newCw, 'New category not set');
			System.assertEquals('Help', newCw.tooltip, 'Invalid tooltip');
			System.assertEquals('2', newCw.sentimentScale, 'Invalid sentiment scale');
			System.assertEquals(true, newCw.preventRecordCreation, 'Prevent record creation not true');

			Test.startTest();
			String result = CategorizationCategoriesListController.updateCategorization(new List<Categorization__c> {newCw.category});
			Test.stopTest();

			cws = CategorizationCategoriesListController.getCategories(c.Id);
			System.assertEquals(0, cws.size(), 'Record created');

			c = [SELECT Id, Category__c, SubCategory__c FROM Case];
			System.assertEquals('Parent 2', c.Category__c, 'Case category not updated');
			System.assertEquals('Child 1b', c.SubCategory__c, 'Case subcategory not updated');
		}
	}

	@IsTest
	static void testgetOrigins()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			List<CategorizationCategoriesListController.Option> opts = CategorizationCategoriesListController.getOrigins();

			Test.stopTest();

			System.assert(opts.size() > 0, 'No origins found.');
		}
	}
}