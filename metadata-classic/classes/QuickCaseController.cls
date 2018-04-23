/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-12-01   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

public with sharing class QuickCaseController
{
	@AuraEnabled
	public static Case getDefaultCase()
	{
		QuickCaseSetting__mdt setting = [SELECT Id, MasterLabel, DeveloperName, AccountId__c, Category__c, ContactId__c,
				Description__c, ManualCaseCreation__c, Origin__c, OwnerId__c, Priority__c, RecordTypeId__c, RelateToIncident__c,
				Status__c, Subcategory__c, Subject__c, Team__c, SuppliedEmail__c
				FROM  QuickCaseSetting__mdt WHERE DeveloperName = 'GenericQuickCaseSetting'];
		Case c = new Case();

		c.Priority = setting.Priority__c;
		c.RecordTypeId = setting.RecordTypeId__c;
		c.Status = setting.Status__c;
		c.Origin = setting.Origin__c;
		c.Subject = setting.Subject__c;
		c.OwnerId = setting.OwnerId__c == '{$User.Id}' ? UserInfo.getUserId() : setting.OwnerId__c;

		if(setting.RecordTypeId__c != null)
		{
			c.RecordTypeId = setting.RecordTypeId__c;
		}

		c.ManualCaseCreation__c = setting.ManualCaseCreation__c;
		c.Description = setting.Description__c != null ? setting.Description__c.left(32000) : '';

		return c;
	}

	@AuraEnabled
	public static List<String> getCaseOrigins()
	{
		return System.Label.QuickCaseAvailableOrigins.replaceAll(', ', ',').split(',');
	}

	@AuraEnabled
	public static QuickCaseResult submitCase(Case c)
	{
		String result;

		try
		{
			insert c;

			result = 'Success';

			c = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id];
		}
		catch (Exception ex)
		{
			result = ex.getMessage();
		}

		return new QuickCaseResult(c, result);
	}

	public class QuickCaseResult
	{
		@AuraEnabled
		public String result {get;set;}

		@AuraEnabled
		public Case caseRecord {get;set;}

		public QuickCaseResult(Case c, String result)
		{
			this.caseRecord = c;
			this.result = result;
		}
	}
}