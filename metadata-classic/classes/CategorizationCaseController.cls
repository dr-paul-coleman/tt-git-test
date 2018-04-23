/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-26   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationCaseController
{
	@AuraEnabled
	public static List<Option> getCaseStatuses()
	{
		List<Option> options = new List<Option>();

		List<Schema.PicklistEntry> ples = Case.Status.getDescribe().getPicklistValues();

		for( Schema.PicklistEntry ple : ples)
		{
			if(ple.getValue() != 'Escalated')
			{
				options.add(new Option(ple.getLabel(), ple.getValue()));
			}
		}

		return options;
	}

	@AuraEnabled
	public static Case getCase(String caseId)
	{
		if(caseId != null)
		{
			return [SELECT Id, Subject, Status FROM Case WHERE Id = :caseId];
		}

		return null;
	}

	@AuraEnabled
	public static String updateCase(Case caseRecord)
	{
		String result = 'Success';

		try
		{
			update caseRecord;
		}
		catch (Exception ex)
		{
			result = ex.getMessage();
		}

		return result;
	}

	public class Option
	{
		@AuraEnabled
		public String label{get;set;}

		@AuraEnabled
		public String value{get;set;}

		public Option(String label, String value)
		{
			this.label = label;
			this.value = value;
		}
	}
}