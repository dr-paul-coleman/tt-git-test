/*
Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.

Change List:
------------ 
Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-21   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class IncidentSectionsController
{
	@AuraEnabled
	public static String saveIncident(MIIncident__c incident)
	{
		String response = 'Success';

		try
		{
			update incident;
		}
		catch (Exception ex)
		{
			response = ex.getMessage();
		}

		return response;
	}

	@AuraEnabled
	public static String closeIncident(MIIncident__c incident, String note, Boolean visibleToCs)
	{
		String response = 'Success';
		List<MIIncidentAction__c> openActions = null;
		List<Arbitration__c> arbitrations = null;
		List<MIIncident__c> incidents = null;
		Savepoint sp = null;
		MIIncidentAction__c task = null;
		Set<String> errors = new Set<String>();
		List<Dispute__c> disputes = new List<Dispute__c>();

		try
		{
			sp = Database.setSavepoint();
			openActions = [SELECT Id, RecordType.Name
							FROM MIIncidentAction__c
							WHERE MIIncident__c = :incident.Id AND Closed__c = false
							AND RecordTypeId != :MiIncidentActionTriggerHandler.TaskRTId];

			arbitrations = [SELECT Id FROM Arbitration__c
							WHERE RecordType.Name = 'Arbitration' AND Closed__c = false AND Incident__c = :incident.Id LIMIT 1];

			incidents = [SELECT Id FROM MIIncident__c
							WHERE Id = :incident.Id AND ModriaCaseNumber__c != null
								AND ModriaStatus__c NOT IN ('Completed','Completed') LIMIT 1];

			disputes = [SELECT Id FROM Dispute__c WHERE MIIncident__c = :incident.Id AND Status__c != 'Closed' LIMIT 1];

			if (!openActions.isEmpty())
			{
				for (MIIncidentAction__c action : openActions)
				{
					if (action.RecordType.Name == 'Payout')
					{
						errors.add('You must complete your open payout request before closing.');
					}
					else if (action.RecordType.Name == 'Charge Card')
					{
						errors.add('You must complete your open charge card action before closing.');
					}
					else if (action.RecordType.Name == 'Guarantee')
					{
						errors.add('You must complete your open guarantee review before closing.');
					}
				}
			}

			if(!arbitrations.isEmpty())
			{
				errors.add('You must complete your open Arbitration claim before closing.');
			}

			if(!incidents.isEmpty())
			{
				errors.add('You must complete your open Modria case before closing.');
			}

			if(!disputes.isEmpty())
			{
				errors.add('There is an open dispute in the Solution Center. Please close the dispute prior to closing this Incident.');
			}

			if(!errors.isEmpty())
			{
				return String.join(new List<String>(errors), '<br/><br/>');
			}


			if (note != null && note != '')
			{
				task = new MIIncidentAction__c(Notes__c = note, MIIncident__c = incident.Id,
						Name = 'Specialist note', Status__c = 'Completed', Type__c = 'Note', IsVisibleToCS__c = visibleToCs,
						RecordTypeId = MiIncidentActionTriggerHandler.TaskRTId);
				insert task;
			}

			incident.Status__c = 'Closed';
			incident.NewEmailFlag__c = false;
			response = saveIncident(incident);

			if(response != 'Success')
			{
				Database.rollback(sp);
			}
		}
		catch (Exception ex)
		{
			response = ex.getMessage();

			if(sp != null)
			{
				Database.rollback(sp);
			}
		}

		return response;
	}

	@AuraEnabled
	public static MIIncident__c getIncident(String incidentId)
	{
		return IncidentManagerController.getIncident(incidentId);
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getPriorities()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.Priority__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getOrigins()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.Origin__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getCategories()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.MICategory__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getSubcategories()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.MISubcategory__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getStatuses()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.Status__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			if(p.getLabel() != 'Closed')
			{
				options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
			}
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getProOutcomes()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.OutcomePro__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getCustOutcomes()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.OutcomeCustomer__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getModiaStatuses()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.ModriaStatus__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getEscalationTypes()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncident__c.EscalationType__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static Map<String, List<IncidentChargeCardManagerController.Option>> getCategoryMap()
	{
		Map<String, List<IncidentChargeCardManagerController.Option>> optionsMap = new Map<String, List<IncidentChargeCardManagerController.Option>>();
		Map<String, List<String>> dependencies = UtilityDependentPicklist.GetDependentOptions('MIIncident__c', 'MICategory__c', 'MISubcategory__c');

		for(String key : dependencies.keySet())
		{
			if(String.isNotBlank(key))
			{
				List<IncidentChargeCardManagerController.Option> opts = optionsMap.get(key);

				if (opts == null)
				{
					opts = new List<IncidentChargeCardManagerController.Option>();
					optionsMap.put(key, opts);
				}

				for (String d : dependencies.get(key))
				{
					opts.add(new IncidentChargeCardManagerController.Option(d, d));
				}
			}
		}

		return optionsMap;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getCategorySubs(string category)
	{
		return IncidentManagerController.getCategorySubs(category);
	}

	@AuraEnabled
	public static ResponseUtility createQuickCase(MIIncident__c incident, String settingId)
	{
		ResponseUtility response = new ResponseUtility();
		Case quickCase = null;
		UtilityQuickCaseSetting uqcs = null;

		try
		{
			uqcs = UtilityQuickCaseSetting.getQuickCaseSetting(incident.Id, settingId, MIIncident__c.getSobjectType());

			quickCase = new Case(RecordTypeId = uqcs.setting.RecordTypeId__c,
								OwnerId = uqcs.replaceMergeField(uqcs.setting.OwnerId__c),
								Team__c = uqcs.setting.Team__c, Origin = uqcs.setting.Origin__c,
								Status = uqcs.setting.Status__c,
								ManualCaseCreation__c = uqcs.setting.ManualCaseCreation__c,
								Incident__c = uqcs.setting.RelateToIncident__c ? incident.Id : null,
								Subject = uqcs.replaceMergeField(uqcs.setting.Subject__c),
								SuppliedEmail = uqcs.replaceMergeField(uqcs.setting.SuppliedEmail__c),
								Category__c = uqcs.setting.Category__c, SubCategory__c = uqcs.setting.Subcategory__c,
								AccountId = uqcs.replaceMergeField(uqcs.setting.AccountId__c),
								ContactId = uqcs.replaceMergeField(uqcs.setting.ContactId__c),
								Description = uqcs.replaceMergeField(uqcs.setting.Description__c));

			insert quickCase;

			response.success = true;
			response.record = quickCase;
		}
		catch (Exception ex)
		{
			response.success = false;
			response.error = ex.getMessage() + ' - ' + ex.getStackTraceString();
			System.debug(ex.getMessage() + ' - ' + ex.getStackTraceString());
		}

		return response;
	}

	@AuraEnabled
	public static ResponseUtility updateQuickCase(String caseId)
	{
		ResponseUtility response = new ResponseUtility();
		Case quickCase = null;
		List<EmailMessage> ems = null;

		try
		{
			ems = [SELECT Id, ToAddress, Subject FROM EmailMessage WHERE ParentId = :caseId ORDER BY CreatedDate LIMIT 1];

			if(!ems.isEmpty())
			{
				List<String> addresses = ems[0].ToAddress.split(';');
				String address = addresses.isEmpty() ? '' : addresses[0];

				quickCase = new Case(Id = caseId, SuppliedEmail = address, Subject = ems[0].Subject);
				update quickCase;
			}

			response.success = true;
			response.record = quickCase;
		}
		catch (Exception ex)
		{
			response.success = false;
			response.error = ex.getMessage();
			System.debug(ex.getMessage() + ' - ' + ex.getStackTraceString());
		}

		return response;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getQuickCaseButtons()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<QuickCaseSetting__mdt> settings = [SELECT Id, Label FROM QuickCaseSetting__mdt WHERE IsActive__c = true AND AssignedApp__c = 'Incident Manager'];

		for(QuickCaseSetting__mdt s : settings)
		{
			options.add(new IncidentChargeCardManagerController.Option(s.Label, s.Id));
		}

		return options;
	}
}