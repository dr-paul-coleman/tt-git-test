/*
Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-09-05   Mendel Guillaume       Created
1.1		 2017-12-07	  Jared Kennington		 Updated functionality so this can be utilized by WorkItem
========+============+=================+===============================================*/

public class UtilityQuickCaseSetting
{
	public Map<String, String> mergeFieldValues{get;set;}
	public QuickCaseSetting__mdt setting {get;set;}

	public UtilityQuickCaseSetting()
	{
		mergeFieldValues = new Map<String, String>();
	}

	public String replaceMergeField(String text)
	{
		if (text != null && text.contains('{!'))
		{
			for (String key : mergeFieldValues.keySet())
			{
				String value = mergeFieldValues.get(key);

				if(value == null)
				{
					value = '';
				}

				text = text.replace(key, value);
			}
		}

		return text;
	}

	public static UtilityQuickCaseSetting getQuickCaseSetting(ID recordId, ID settingId, sObjectType objectType)
	{
		UtilityQuickCaseSetting uqcs = new UtilityQuickCaseSetting();
		List<QuickCaseSetting__mdt> settings = [SELECT Id, MasterLabel, OriginalQueue__c,DeveloperName, AccountId__c, Category__c, ContactId__c,
						Description__c, ManualCaseCreation__c, Origin__c, OwnerId__c, Priority__c, RecordTypeId__c, RelateToIncident__c,
						Status__c, Subcategory__c, Subject__c, Team__c, SuppliedEmail__c, FeedPost__c
						FROM  QuickCaseSetting__mdt WHERE Id =: settingId];

		if(!settings.isEmpty() && null != recordId)
		{
			Map<String, String> mergeFields = new Map<String, String>();
			Pattern regex = Pattern.compile('\\{!([^}]*)\\}');
			Matcher match = null;

			if(settings[0].AccountId__c != null && settings[0].AccountId__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].AccountId__c, mergeFields);
			}

			if(settings[0].ContactId__c != null && settings[0].ContactId__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].ContactId__c, mergeFields);
			}

			if(settings[0].Description__c != null && settings[0].Description__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].Description__c, mergeFields);
			}

			if(settings[0].OwnerId__c != null && settings[0].OwnerId__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].OwnerId__c, mergeFields);
			}

			if(settings[0].Subject__c != null && settings[0].Subject__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].Subject__c, mergeFields);
			}

			if(settings[0].SuppliedEmail__c != null && settings[0].SuppliedEmail__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].SuppliedEmail__c, mergeFields);
			}

			if(settings[0].FeedPost__c != null && settings[0].FeedPost__c.contains('{!'))
			{
				getMergeFields(regex, settings[0].FeedPost__c, mergeFields);
			}

			if(!mergeFields.isEmpty())
			{
				String query = 'SELECT Id';

				for(String field : mergeFields.values())
				{
					query += ', ' + field;
				}

				if(null != objectType && objectType.getDescribe().getName() == 'MIIncident__c')
				{
					query += ' FROM MIIncident__c WHERE Id = :recordId';
				}
				else if(null != objectType && objectType.getDescribe().getName() == 'WorkItem__c')
				{
					query += ' FROM WorkItem__c WHERE Id = :recordId';
				}

                List<sObject> records = new List<sObject>();
				try{  records = (List<sObject>) Database.query(query); } catch (Exception ex) { System.debug(LoggingLevel.Error, ex.getMessage() + ' - ' + ex.getStackTraceString()); }

				if(records.size() > 0)
				{
					uqcs.setting = settings[0];

					for(String key : mergeFields.keySet())
					{
						String fieldName = mergeFields.get(key);
						String value =  null;

						if(fieldName.contains('.'))
						{
							System.debug(fieldName);
							List<String> fields = fieldName.split('\\.');
							System.debug(fields);
							sObject o = records[0].getSObject(fields[0]);

							fields.remove(0);

							for(Integer i = 0; i < fields.size() - 1; i++)
							{
								if(o != null)
								{
									o = o.getSObject(fields[i]);
								}
							}

							if(o != null)
							{
								value = String.valueOf(o.get(fields[fields.size() - 1]));
							}
						}
						else
						{
							value = String.valueOf(records[0].get(fieldName));
						}

						uqcs.mergeFieldValues.put(key, value);
					}
				}
			}
		}

		return uqcs;
	}

	private static void getMergeFields(Pattern regex, String text, Map<String, String> mergeFields)
	{
		Matcher match = regex.matcher(text);

		while(match.find())
		{
			String token = match.group();
			String fieldName = token.replace('{!MIIncident__c.','').replace('{!WorkItem__c.','').replace('}','');

			mergeFields.put(token, fieldName);
		}
	}
}