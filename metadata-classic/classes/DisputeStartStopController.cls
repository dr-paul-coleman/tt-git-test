/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-31   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

public with sharing class DisputeStartStopController
{
	@AuraEnabled
	public static Dispute__c getDispute(String disputeId)
	{
		return [SELECT Id, Status__c, Stage__c, PriorStage__c, PriorStatus__c
				FROM Dispute__c WHERE Id = :disputeId];
	}

	@AuraEnabled
	public static String saveDispute(Dispute__c dispute)
	{
		String success = 'Success';

		try
		{
			update dispute;
		}
		catch (Exception ex)
		{
			success = ex.getMessage();
		}

		return success;
	}

	@AuraEnabled
	public static List<DisputeStartStopController.Option> getStatuses()
	{
		List<DisputeStartStopController.Option> options = new List<DisputeStartStopController.Option>();
		List<Schema.PicklistEntry> ples = Dispute__c.Status__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			if(p.getLabel() != 'Closed' && p.getLabel() != 'Under review')
			{
				options.add(new DisputeStartStopController.Option(p.getLabel(), p.getValue()));
			}
		}

		return options;
	}

	@AuraEnabled
	public static Map<String, List<LightningInnerClass>> getStatusMap()
	{
		Map<String, List<DisputeStartStopController.Option>> optionsMap = new Map<String, List<DisputeStartStopController.Option>>();
		Map<String, List<String>> dependencies = UtilityDependentPicklist.GetDependentOptions('Dispute__c', 'Status__c', 'Stage__c');

		for(String key : dependencies.keySet())
		{
			if(String.isNotBlank(key))
			{
				List<DisputeStartStopController.Option> opts = optionsMap.get(key);

				if (opts == null)
				{
					opts = new List<DisputeStartStopController.Option>();
					optionsMap.put(key, opts);
				}

				for (String d : dependencies.get(key))
				{
					opts.add(new DisputeStartStopController.Option(d, d));
				}
			}
		}

		return optionsMap;
	}

	public class Option implements LightningInnerClass
	{
		@AuraEnabled
		public String label{get;set;}

		@AuraEnabled
		public String value{get;set;}

		public Option(String l, String v)
		{
			this.label = l;
			this.value = v;
		}
	}
}