/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-01   Mendel Guillaume   Created
   1.1      2018-01-03   Mendel Guillaume   Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationProdUpdatesListCtrlTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Case c = new Case(AccountId = customer.Id, Subject = 'Test Case', Status = 'New', Origin = 'Suggestion Box');
			insert c;

			Enrollment__c enrollment = new Enrollment__c(enrollment_id__c = '1',
					Name = 'FN LN 1-1', Account__c = customer.Id, FirstName__c = 'Test First Name ', LastName__c = 'Test Last Name ' ,
					sav_available_service_id__c = 1, user_id__c = '1'  , rca_request_category_id__c = '1', zip_cbsa_code__c = '1',
					zip_cbsa_name__c = 'Utah');
			insert enrollment;

			List<CategorizationDefinition__c> prodUpdates = new List<CategorizationDefinition__c>();
			prodUpdates.add(new CategorizationDefinition__c(Name = 'Prod Update 1', Active__c = true, AvailableOnCase__c = true, Pro__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));
			prodUpdates.add(new CategorizationDefinition__c(Name = 'Prod Update 2', Active__c = true, AvailableOnCase__c = true, Customer__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));

			prodUpdates.add(new CategorizationDefinition__c(Name = 'Account Prod Update 1', Active__c = true, AvailableOnAccount__c = true, Pro__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));
			prodUpdates.add(new CategorizationDefinition__c(Name = 'Account Prod Update 2', Active__c = true, AvailableOnAccount__c = true, Customer__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));

			prodUpdates.add(new CategorizationDefinition__c(Name = 'Enrollment Prod Update 1', Active__c = true, AvailableOnEnrollment__c = true, Pro__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));
			prodUpdates.add(new CategorizationDefinition__c(Name = 'Enrollment Prod Update 2', Active__c = true, AvailableOnEnrollment__c = true, Customer__c = true,
					RecordTypeId = CategorizationProdUpdatesListController.CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID));


			insert prodUpdates;
		}
	}

	@IsTest
	static void testProdUpdatesListController()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			Case c = [SELECT Id FROM Case];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationProdUpdatesListController.getProductUpdates(c.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertEquals(null, cws[0].category.Id, 'Id not null');
			System.assertEquals(null, cws[1].category.Id, 'Id not null');
			System.assertEquals('Prod Update 1', cws[0].category.ProductUpdate__c, 'Not Product Update 1');
			System.assertEquals('Prod Update 2', cws[1].category.ProductUpdate__c, 'Not Product Update 2');

			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(c.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(false, cws[0].category.Deleted__c, 'Category deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');

			cws[0].category.Deleted__c = true;
			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(c.Id);

			Test.stopTest();

			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(true, cws[0].category.Deleted__c, 'Category not deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');
		}
	}

	@IsTest
	static void testProdUpdatesListControllerOnAccount()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			Account a = [SELECT Id FROM Account];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationProdUpdatesListController.getProductUpdates(a.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertEquals(null, cws[0].category.Id, 'Id not null');
			System.assertEquals(null, cws[1].category.Id, 'Id not null');
			System.assertEquals('Account Prod Update 1', cws[0].category.ProductUpdate__c, 'Not Account Product Update 1');
			System.assertEquals('Account Prod Update 2', cws[1].category.ProductUpdate__c, 'Not Account Product Update 2');

			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(a.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(false, cws[0].category.Deleted__c, 'Category deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');

			cws[0].category.Deleted__c = true;
			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(a.Id);

			Test.stopTest();

			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(true, cws[0].category.Deleted__c, 'Category not deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');
		}
	}

	@IsTest
	static void testProdUpdatesListControllerOnEnrollment()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			Enrollment__c e = [SELECT Id FROM Enrollment__c];
			List<CategorizationCategoriesListController.CategoryWrapper> cws = CategorizationProdUpdatesListController.getProductUpdates(e.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertEquals(null, cws[0].category.Id, 'Id not null');
			System.assertEquals(null, cws[1].category.Id, 'Id not null');
			System.assertEquals('Enrollment Prod Update 1', cws[0].category.ProductUpdate__c, 'Not Enrollment Product Update 1');
			System.assertEquals('Enrollment Prod Update 2', cws[1].category.ProductUpdate__c, 'Not Enrollment Product Update 2');

			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(e.Id);
			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(false, cws[0].category.Deleted__c, 'Category deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');

			cws[0].category.Deleted__c = true;
			System.assertEquals('Success', CategorizationProdUpdatesListController.updateCategorization(new List<Categorization__c> {cws[0].category}), 'Update failed');

			cws = CategorizationProdUpdatesListController.getProductUpdates(e.Id);

			Test.stopTest();

			System.assertEquals(2, cws.size(), 'Size not 2');
			System.assertNotEquals(null, cws[0].category.Id, 'Id is null');
			System.assertEquals(true, cws[0].category.Deleted__c, 'Category not deleted');
			System.assertEquals(null, cws[1].category.Id, 'Id null');
		}
	}
}