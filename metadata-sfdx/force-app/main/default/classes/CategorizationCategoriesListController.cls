/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-24   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationCategoriesListController
{
	public static Id CATEGORIZATION_CATEGORY_RT_ID = Categorization__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Category').getRecordTypeId();

	@AuraEnabled
	public static List<CategorizationCategoriesListController.CategoryWrapper> getCategories(String recordId)
	{
		List<Categorization__c> cats = new List<Categorization__c>();
		List<CategorizationCategoriesListController.CategoryWrapper> categoryWrappers = new List<CategorizationCategoriesListController.CategoryWrapper>();
		Set<String> selectedKeys = new Set<String>();
		Set<String> inactiveKeys = new Set<String>();
		Map<String, CategorizationDefinition__c> keyToDefinitionMap = new Map<String, CategorizationDefinition__c>();

		if (recordId != null)
		{
			cats = [SELECT Id, Name, Case__c, Category__c, DefinitionKey__c, Enrollment__c, Feedback__c, Notes__c,
						Primary__c, Sentiment__c, Subcategory__c, ParentDefinitionKey__c, ProductUpdate__c, Deleted__c,
						CSATEligible__c, Origin__c
					FROM Categorization__c
					WHERE RecordTypeId = :CATEGORIZATION_CATEGORY_RT_ID AND (Case__c = :recordId OR Enrollment__c = :recordId OR Account__c = :recordId)
					ORDER BY Name];

			for(Categorization__c c : cats)
			{
				if(c.ParentDefinitionKey__c != null)
				{
					selectedKeys.add(c.ParentDefinitionKey__c);
				}

				if(c.DefinitionKey__c != null)
				{
					selectedKeys.add(c.DefinitionKey__c);
				}
			}

			if(!selectedKeys.isEmpty())
			{
				for(CategorizationDefinition__c cd : [SELECT Id, Name, Key__c, ParentCategory__c, ParentCategory__r.Name,
																ParentCategory__r.Key__c, SentimentScale__c, PreventRecordCreation__c,
																ParentCategory__r.PreventRecordCreation__c, Active__c, HelpText__c,
																Icon__c, Placeholder__c, CSATEligible__c
														FROM CategorizationDefinition__c
														WHERE Key__c IN :selectedKeys])
				{
					if(!cd.Active__c)
					{
						inactiveKeys.add(cd.Key__c);
					}

					keyToDefinitionMap.put(cd.Key__c, cd);
				}
			}

			for(Categorization__c c : cats)
			{
				CategoryWrapper cw = new CategorizationCategoriesListController.CategoryWrapper(c,
						!inactiveKeys.contains(c.DefinitionKey__c) && !inactiveKeys.contains(c.ParentDefinitionKey__c));
				CategorizationDefinition__c cd = keyToDefinitionMap.get(c.DefinitionKey__c);

				if(cd != null)
				{
					cw.catDefinition = cd;
					cw.category.CSATEligible__c = cd.CSATEligible__c;

					categoryWrappers.add(cw);
				}
			}
		}

		return categoryWrappers;
	}

	@AuraEnabled
	public static CategorizationCategoriesListController.CategoryWrapper addCategory(String catDefKey, String recordId)
	{
		List<CategorizationDefinition__c> catDefs = [SELECT Id, Name, Key__c, ParentCategory__c, ParentCategory__r.Name,
														ParentCategory__r.Key__c, SentimentScale__c, PreventRecordCreation__c,
														ParentCategory__r.PreventRecordCreation__c, Active__c, HelpText__c,
														Icon__c, Placeholder__c, CSATEligible__c
													FROM CategorizationDefinition__c
													WHERE Key__c = :catDefKey];
		Categorization__c cat = null;
		CategorizationCategoriesListController.CategoryWrapper cw = null;

		if (!catDefs.isEmpty() && recordId != null)
		{
			cat = new Categorization__c();
			cat.Feedback__c = false;
			cat.Category__c = catDefs[0].ParentCategory__r.Name;
			cat.DefinitionKey__c = catDefs[0].Key__c;
			cat.Notes__c = '';
			cat.Primary__c = false;
			cat.Sentiment__c = null;
			cat.Subcategory__c = catDefs[0].Name;
			cat.ParentDefinitionKey__c = catDefs[0].ParentCategory__r.Key__c;
			cat.RecordTypeId = CATEGORIZATION_CATEGORY_RT_ID;
			cat.CSATEligible__c = catDefs[0].CSATEligible__c;

			if (recordId.startsWith('500'))
			{
				Case c = [SELECT Origin FROM Case WHERE Id = :recordId];

				cat.Case__c = recordId;
				cat.Origin__c = c.Origin;
			}
			else if(recordId.startsWith('001'))
			{
				cat.Account__c = recordId;
				cat.Feedback__c = true;
			}
			else
			{
				Enrollment__c e = [SELECT Account__c FROM Enrollment__c WHERE Id =: recordId];

				cat.Enrollment__c = recordId;
				cat.Feedback__c = true;
				cat.Account__c = e.Account__c;
			}

			cw = new CategorizationCategoriesListController.CategoryWrapper(cat, catDefs[0], true, false);
		}

		return cw;
	}

	@AuraEnabled
	public static String updateCategorization(List<Categorization__c> catsToSave)
	{
		return saveCategorization(catsToSave, CATEGORIZATION_CATEGORY_RT_ID);
	}

	public static String saveCategorization(List<Categorization__c> catsToSave, Id recordTypeId)
	{
		String result = 'Success';
		Savepoint sp = null;
		Categorization__c updateRecordCat = null;
		FeedItem feed = new FeedItem(Type = 'TextPost', IsRichText = true);
		String updatedCategoriesFeed = '';
		String deletedCategoriesFeed = '';
		Map<Id, Categorization__c> existingCategoriesMap = new Map<Id, Categorization__c>();
		Boolean logFeedItem = false;

		try
		{
			sp = Database.setSavepoint();

			if(catsToSave != null && !catsToSave.isEmpty())
			{
				List<Categorization__c> temp = new List<Categorization__c>();
				Set<String> allKeys = new Set<String>();
				Set<String> preventRecordCreateKeys = new Set<String>();

				if(recordTypeId == CATEGORIZATION_CATEGORY_RT_ID)
				{
					feed.Title = 'Categorization';
					updatedCategoriesFeed = '<b>New/Updated Categories</b><ul>';
					deletedCategoriesFeed = '<p>&nbsp;</p><b>Deleted Categories</b><ul>';
				}
				else
				{
					feed.Title = 'Product Updates';
					updatedCategoriesFeed = '<b>New/Updated Product Updates</b><ul>';
					deletedCategoriesFeed = '<p>&nbsp;</p><b>Deleted Product Updates</b><ul>';
				}

				if(catsToSave[0].Case__c != null)
				{
					feed.ParentId = catsToSave[0].Case__c;
					existingCategoriesMap = new Map<Id, Categorization__c>([SELECT Id, Notes__c, Deleted__c, Feedback__c
																FROM Categorization__c WHERE Case__c = :feed.ParentId]);
				}

				for (Integer i = 0; i < catsToSave.size(); i++)
				{
					catsToSave[i].RecordTypeId = recordTypeId;

					if (catsToSave[i].DefinitionKey__c != null)
					{
						allKeys.add(catsToSave[i].DefinitionKey__c);
					}

					if (catsToSave[i].ParentDefinitionKey__c != null)
					{
						allKeys.add(catsToSave[i].ParentDefinitionKey__c);
					}
				}

				preventRecordCreateKeys = getPreventRecordCreateKeys(allKeys);

				for (Integer i = 0; i < catsToSave.size(); i++)
				{
					if(!(catsToSave[i].Id == null && catsToSave[i].Deleted__c == true))
					{
						Categorization__c ec = null;

						if(catsToSave[i].Id != null)
						{
							ec = existingCategoriesMap.get(catsToSave[i].Id);
						}

						//Only log if there's a change (deleted, new, updated)
						if(catsToSave[i].Deleted__c == true && ec != null && ec.Deleted__c == false)
						{
							deletedCategoriesFeed += addCategoryEntry(catsToSave[i]);
							logFeedItem = true;
						}
						else if(catsToSave[i].Deleted__c == false &&
								(ec == null || ec.Notes__c != catsToSave[i].Notes__c || ec.Feedback__c != catsToSave[i].Feedback__c || ec.Deleted__c == true))
						{
							updatedCategoriesFeed += addCategoryEntry(catsToSave[i]);
							logFeedItem = true;
						}

						if (catsToSave[i].Deleted__c == false &&
							(preventRecordCreateKeys.contains(catsToSave[i].DefinitionKey__c) || preventRecordCreateKeys.contains(catsToSave[i].ParentDefinitionKey__c)))
						{
							updateRecordCat = catsToSave[i];

							break;
						}
						else
						{
							temp.add(catsToSave[i]);
						}
					}
				}

				if (updateRecordCat != null)
				{
					if (updateRecordCat.Case__c != null)
					{
						update new Case(Id = updateRecordCat.Case__c, Category__c = updateRecordCat.Category__c, SubCategory__c = updateRecordCat.Subcategory__c);
					}
				}
				else
				{
					upsert temp;
				}

				if(feed.ParentId != null && logFeedItem)
				{
					feed.Body = updatedCategoriesFeed + '</ul>' + deletedCategoriesFeed + '</ul>';
					insert feed;
				}
			}
		}
		catch (Exception ex)
		{
			if (sp != null)
			{
				Database.rollback(sp);
			}

			result = 'Error: ' + ex.getMessage();
		}

		return result;
	}

	private static Set<String> getPreventRecordCreateKeys(Set<String> keys)
	{
		Set<String> preventRecordKeys = new Set<String>();
		List<CategorizationDefinition__c> catDefs = [SELECT Key__c
													FROM CategorizationDefinition__c
													WHERE PreventRecordCreation__c = true AND Key__c IN :keys];

		for(CategorizationDefinition__c cd : catDefs)
		{
			preventRecordKeys.add(cd.Key__c);
		}

		return preventRecordKeys;
	}

	private static string addCategoryEntry(Categorization__c categorization)
	{
		if(categorization.RecordTypeId == CATEGORIZATION_CATEGORY_RT_ID)
		{
			return String.format('<li>{0} - {1}: {2}&nbsp;&nbsp;{3}</li>', new List<String>{categorization.Category__c, categorization.Subcategory__c, categorization.Notes__c,
				categorization.Feedback__c == true ? '&#10004;' : ''});
		}
		else
		{
			return String.format('<li>{0}: {1}</li>', new List<String>{categorization.ProductUpdate__c, categorization.Notes__c});
		}
	}

	@AuraEnabled
	public static List<CategorizationCategoriesListController.Option> getOrigins()
	{
		List<Option> options = new List<Option>();
		List<Schema.PicklistEntry> ples = Categorization__c.Origin__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	public class CategoryWrapper implements LightningInnerClass
	{
		@AuraEnabled
		public CategorizationDefinition__c catDefinition{get;set;}

		@AuraEnabled
		public Categorization__c category{get;set;}

		@AuraEnabled
		public Boolean isActive {get;set;}

		@AuraEnabled
		public Boolean selected {get;set;}

		@AuraEnabled
		public String tooltip {get{return catDefinition != null ? catDefinition.HelpText__c : null;}}

		@AuraEnabled
		public String sentimentScale {get{return catDefinition != null ? catDefinition.SentimentScale__c : null;}}

		@AuraEnabled
		public Boolean preventRecordCreation{get{return catDefinition != null ? (catDefinition.PreventRecordCreation__c || (catDefinition.ParentCategory__c != null && catDefinition.ParentCategory__r.PreventRecordCreation__c)) : false;}}

		@AuraEnabled
		public List<CategoryWrapper> childCategories{get;set;}

		@AuraEnabled
		public Boolean isParent {get {return this.childCategories != null && !this.childCategories.isEmpty();}}

		public CategoryWrapper(Categorization__c cat, Boolean active)
		{
			this.category = cat;
			this.isActive = active;
			this.selected = false;
			this.childCategories = new List<CategorizationCategoriesListController.CategoryWrapper>();
		}

		public CategoryWrapper(Categorization__c cat, CategorizationDefinition__c definition, Boolean active, Boolean selected)
		{
			this.category = cat;
			this.isActive = active;
			this.selected = selected;
			this.catDefinition = definition;
			this.childCategories = new List<CategorizationCategoriesListController.CategoryWrapper>();
		}
	}

	public class Option
	{
		@AuraEnabled
		public String value{get;set;}
		@AuraEnabled
		public String label{get;set;}

		public Option(String label, String value)
		{
			this.label = label;
			this.value = value;
		}
	}
}