/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-27   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationProdUpdatesListController
{
	public static Id CATEGORIZATION_PRODUCT_UPDATE_RT_ID = Categorization__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Product Update').getRecordTypeId();
	public static Id CATEGORIZATION_DEFINITION_PRODUCT_UPDATE_RT_ID = CategorizationDefinition__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Product Update').getRecordTypeId();

	@AuraEnabled
	public static List<CategorizationCategoriesListController.CategoryWrapper> getProductUpdates(String recordId)
	{
		List<Categorization__c> cats = new List<Categorization__c>();
		List<CategorizationCategoriesListController.CategoryWrapper> categoryWrappers = new List<CategorizationCategoriesListController.CategoryWrapper>();
		Map<String, Categorization__c> keyToCategorizationsMap = new Map<String, Categorization__c>();
		List<CategorizationDefinition__c> catDefs = database.query('SELECT Id, Name, Key__c, ParentCategory__c, ParentCategory__r.Name, ' +
				'ParentCategory__r.Key__c, SentimentScale__c, PreventRecordCreation__c, ' +
				'ParentCategory__r.PreventRecordCreation__c, Active__c, HelpText__c, Icon__c, Placeholder__c, CSATEligible__c, ' +

					'(SELECT Id, Name, Key__c, ParentCategory__c, ParentCategory__r.Name, ' +
						'ParentCategory__r.Key__c, SentimentScale__c, PreventRecordCreation__c, ' +
						'ParentCategory__r.PreventRecordCreation__c, Active__c, HelpText__c, Icon__c, Placeholder__c, CSATEligible__c ' +
					'FROM Subcategories__r ' +
					'WHERE RecordType.Name = \'Product Update\' AND '+
					(recordId != null && recordId.startsWith('500') ? 'AvailableOnCase__c = true ' : (recordId != null && recordId.startsWith('001') ? 'AvailableOnAccount__c = true ' : 'AvailableOnEnrollment__c = true ')) +
					'ORDER BY SortOrder__c NULLS LAST, Name) ' +

				'FROM CategorizationDefinition__c ' +
				'WHERE RecordType.Name = \'Product Update\' AND ParentCategory__c = null AND '+
					(recordId != null && recordId.startsWith('500') ? 'AvailableOnCase__c = true ' : (recordId != null && recordId.startsWith('001') ? 'AvailableOnAccount__c = true ' : 'AvailableOnEnrollment__c = true ')) +
				'ORDER BY SortOrder__c NULLS LAST, Name');

		if (recordId != null)
		{
			cats = [SELECT Id, Name, Case__c, Category__c, DefinitionKey__c, Enrollment__c, Feedback__c, Notes__c, SubProductUpdate__c,
							Primary__c, Sentiment__c, Subcategory__c, ParentDefinitionKey__c, ProductUpdate__c, Deleted__c, CSATEligible__c
					FROM Categorization__c
					WHERE RecordTypeId = :CATEGORIZATION_PRODUCT_UPDATE_RT_ID AND (Case__c = :recordId OR Enrollment__c = :recordId OR Account__c = :recordId)
					ORDER BY Name];

			for(Categorization__c c : cats)
			{
				if(c.DefinitionKey__c != null)
				{
					keyToCategorizationsMap.put(c.DefinitionKey__c, c);
				}
			}

			for(CategorizationDefinition__c cd : catDefs)
			{
				CategorizationCategoriesListController.CategoryWrapper cw = getCategoryWrapper(cd, keyToCategorizationsMap.get(cd.Key__c), recordId);

				if(cw != null)
				{
					//Add child product updates
					if (!cd.Subcategories__r.isEmpty())
					{
						for (CategorizationDefinition__c ccd : cd.Subcategories__r)
						{
							cw.childCategories.add(getCategoryWrapper(ccd, keyToCategorizationsMap.get(ccd.Key__c), recordId));
						}
					}

					categoryWrappers.add(cw);
				}
			}
		}

		return categoryWrappers;
	}

	private static CategorizationCategoriesListController.CategoryWrapper getCategoryWrapper(CategorizationDefinition__c cd, Categorization__c existingRecord, String recordId)
	{
		CategorizationCategoriesListController.CategoryWrapper cw = null;

		if(existingRecord != null)
		{
			existingRecord.CSATEligible__c = cd.CSATEligible__c;

			//Update existing records to have parent info on save - SYS-1609
			if(cd.ParentCategory__c != null && existingRecord.SubProductUpdate__c == null)
			{
				existingRecord.ProductUpdate__c = cd.ParentCategory__r.Name;
				existingRecord.SubProductUpdate__c = cd.Name;
				existingRecord.ParentDefinitionKey__c = cd.ParentCategory__r.Key__c;
			}

			cw = new CategorizationCategoriesListController.CategoryWrapper(existingRecord, cd, cd.Active__c, !existingRecord.Deleted__c);
		}
		else if(cd.Active__c)
		{
			cw = newProductUpdate(cd, recordId);
		}

		return cw;
	}

	@AuraEnabled
	public static String updateCategorization(List<Categorization__c> catsToSave)
	{
		return CategorizationCategoriesListController.saveCategorization(catsToSave, CATEGORIZATION_PRODUCT_UPDATE_RT_ID);
	}

	private static CategorizationCategoriesListController.CategoryWrapper newProductUpdate(CategorizationDefinition__c cd, String recordId)
	{
		CategorizationCategoriesListController.CategoryWrapper cw = null;
		Categorization__c	cat = new Categorization__c();
		cat.SubProductUpdate__c = cd.ParentCategory__c != null ? cd.Name : null;
		cat.ProductUpdate__c =  cd.ParentCategory__c != null ? cd.ParentCategory__r.Name : cd.Name;
		cat.DefinitionKey__c = cd.Key__c;
		cat.Feedback__c = false;
		cat.Notes__c = '';
		cat.Primary__c = false;
		cat.Sentiment__c = null;
		cat.Subcategory__c = null;
		cat.ParentDefinitionKey__c = cd.ParentCategory__c != null ? cd.ParentCategory__r.Key__c : null;
		cat.RecordTypeId = CATEGORIZATION_PRODUCT_UPDATE_RT_ID;
		cat.CSATEligible__c = cd.CSATEligible__c;

		if (recordId.startsWith('500'))
		{
			Case c = [SELECT Origin FROM Case WHERE Id = :recordId];

			cat.Case__c = recordId;
			cat.Origin__c = c.Origin;
		}
		else if (recordId.startsWith('001'))
		{
			cat.Account__c = recordId;
		}
		else
		{
			Enrollment__c e = [SELECT Account__c FROM Enrollment__c WHERE Id =: recordId];

			cat.Enrollment__c = recordId;
			cat.Feedback__c = false;
			cat.Account__c = e.Account__c;
		}

		cw = new CategorizationCategoriesListController.CategoryWrapper(cat, true);
		cw.catDefinition = cd;

		return cw;
	}
}