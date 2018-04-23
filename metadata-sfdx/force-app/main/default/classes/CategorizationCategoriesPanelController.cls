/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-20   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationCategoriesPanelController
{
	public static Id CATEGORIZATION_DEFINITION_CATEGORY_RT_ID = CategorizationDefinition__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Category').getRecordTypeId();

	@AuraEnabled
	public static List<CategoryType> getCategoryTypes(String recordId)
	{
		Map<String, CategoryType> categoryTypeMap = new Map<String, CategoryType>();
		List<CategorizationDefinition__c> catDefs = database.query('SELECT Id, Name, Key__c, Pro__c, Customer__c, Functional__c, HelpText__c, Icon__c, ' +
														 '(SELECT Id, Name, Key__c, Pro__c, Customer__c, Functional__c, HelpText__c, Icon__c ' +
													     'FROM Subcategories__r ' +
														 'WHERE CategoryType__c = \'Subcategory\' AND RecordType.Name = \'Category\' ' +
																'AND Active__c = true AND ' +
																(recordId != null && recordId.startsWith('500') ? 'AvailableOnCase__c = true ' : (recordId != null && recordId.startsWith('001') ? 'AvailableOnAccount__c = true ' : 'AvailableOnEnrollment__c = true ')) +
														 'ORDER BY Name) ' +
													'FROM CategorizationDefinition__c ' +
													'WHERE Active__c = true AND CategoryType__c = \'Category\' AND RecordType.Name = \'Category\' AND ' +
														(recordId != null && recordId.startsWith('500') ? 'AvailableOnCase__c = true ' : (recordId != null && recordId.startsWith('001') ? 'AvailableOnAccount__c = true ' : 'AvailableOnEnrollment__c = true ')) +
													'ORDER BY Name ');
		Set<String> keys = getRecordCategoryKeys(recordId);
		List<CategoryType> catTypes = new List<CategoryType>();
		String accountRecordType = null;

		if(recordId != null)
		{
			if (recordId.startsWith('500'))
			{
				Case caseRecord = [SELECT Id, AccountId, Account.RecordType.Name FROM Case WHERE Id = :recordId];
				accountRecordType = caseRecord.Account.RecordType.Name;
			}
			else if (recordId.startsWith('001'))
			{
				Account accountRecord = [SELECT Id, RecordType.Name FROM Account WHERE Id = :recordId];
				accountRecordType = accountRecord.RecordType.Name;
			}
		}

		for(CategorizationDefinition__c cd : catDefs)
		{
			if(cd.Pro__c)
			{
				setCategoryBucket(cd, 'Pro', categoryTypeMap, keys);
			}

			if(cd.Customer__c)
			{
				setCategoryBucket(cd, 'Customer', categoryTypeMap, keys);
			}

			if(cd.Functional__c)
			{
				setCategoryBucket(cd, 'Other', categoryTypeMap, keys);
			}
		}

		//For display order
		if(categoryTypeMap.containsKey('Pro'))
		{
			CategoryType ct = categoryTypeMap.get('Pro');
			ct.show = accountRecordType == 'Thumbtack Pro';
			catTypes.add(ct);
		}

		if(categoryTypeMap.containsKey('Customer'))
		{
			CategoryType ct = categoryTypeMap.get('Customer');
			ct.show = accountRecordType == 'Customer';
			catTypes.add(ct);
		}

		if(categoryTypeMap.containsKey('Other'))
		{
			CategoryType ct = categoryTypeMap.get('Other');
			ct.show = accountRecordType == null;
			catTypes.add(ct);
		}

		return catTypes;
	}

	private static void setCategoryBucket(CategorizationDefinition__c cd, String type, Map<String, CategoryType> categoryTypeMap, Set<String> keys)
	{
		CategoryType ct = categoryTypeMap.get(type);
		CategoryWrapper cw;

		if(ct == null)
		{
			ct = new CategoryType(type);
			categoryTypeMap.put(type, ct);
		}

		cw = new CategoryWrapper(cd);

		for(CategorizationDefinition__c sub : cd.Subcategories__r)
		{
			CategoryWrapper subWrapper = new CategoryWrapper(sub);
			subWrapper.selected = keys.contains(subWrapper.category.Key__c);
			cw.subCategories.add(subWrapper);
		}

		ct.categories.add(cw);
	}

	private static Set<String> getRecordCategoryKeys(String recordId)
	{
		Set<String> keys = new Set<String>();

		List<Categorization__c> selectedCategorizations = new List<Categorization__c>();

		if(recordId != null)
		{
			selectedCategorizations = [SELECT Id, DefinitionKey__c
										FROM Categorization__c
										WHERE (Case__c = :recordId OR Enrollment__c = :recordId OR Account__c = :recordId) AND Deleted__c = false];
		}

		for(Categorization__c c : selectedCategorizations)
		{
			if(String.isNotBlank(c.DefinitionKey__c))
			{
				keys.add(c.DefinitionKey__c);
			}
		}

		return keys;
	}

	public class CategoryType
	{
		@AuraEnabled
		public String name{get;set;}

		@AuraEnabled
		public Boolean show{get;set;}

		@AuraEnabled
		public List<CategoryWrapper> categories{get;set;}

		public CategorizationCategoriesPanelController.CategoryType(String name)
		{
			this.name = name;
			this.categories = new List<CategoryWrapper>();
			this.show = false;
		}
	}

	public class CategoryWrapper
	{
		@AuraEnabled
		public CategorizationDefinition__c category{get;set;}

		@AuraEnabled
		public Boolean selected{get;set;}

		@AuraEnabled
		public Boolean subSelected
		{
			get
			{
				Boolean sel = false;

				if(this.subCategories != null)
				{
					for(CategoryWrapper cw : this.subCategories)
					{
						if(cw.selected)
						{
							sel = true;
							break;
						}
					}
				}

				return sel;
			}
		}

		@AuraEnabled
		public List<CategoryWrapper> subCategories{get;set;}

		public CategoryWrapper(CategorizationDefinition__c cat)
		{
			this.category = cat;
			this.selected = false;
			this.subCategories = new List<CategoryWrapper>();
		}
	}
}