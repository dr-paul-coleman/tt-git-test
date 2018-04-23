/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-25   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationSearchController
{
	@AuraEnabled
	public static List<CategorizationDefinition__c> getCategorizationDefinitions(String searchText, String recordId)
	{
		searchText = '%' + searchText + '%';

		return Database.query('SELECT Id, Name, Key__c, ParentCategory__c, ParentCategory__r.Name, ParentCategory__r.Key__c, Pro__c, Customer__c, Functional__c ' +
				'FROM CategorizationDefinition__c ' +
				'WHERE Active__c = true AND ParentCategory__r.Active__c = true AND CategoryType__c = \'Subcategory\' AND ParentCategory__c != null ' +
						'AND (Name LIKE :searchText OR ParentCategory__r.Name LIKE :searchText) AND ' +
						(recordId != null && recordId.startsWith('500') ? 'AvailableOnCase__c = true ' : (recordId != null && recordId.startsWith('001') ? 'AvailableOnAccount__c = true ' : 'AvailableOnEnrollment__c = true ')) +
				'ORDER BY ParentCategory__r.Name, Name ' +
				'LIMIT 500');
	}
}