/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-01   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationSearchControllerTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
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
	static void testSearch()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();
			List<CategorizationDefinition__c> cds = CategorizationSearchController.getCategorizationDefinitions('x', '500');
			System.assertEquals(0, cds.size());

			cds = CategorizationSearchController.getCategorizationDefinitions('Child', '500');
			System.assertEquals(4, cds.size());

			cds = CategorizationSearchController.getCategorizationDefinitions('Parent 1', '500');
			System.assertEquals(2, cds.size());

			cds = CategorizationSearchController.getCategorizationDefinitions('Parent 2', '500');
			System.assertEquals(1, cds.size());
			Test.stopTest();
		}
	}
}