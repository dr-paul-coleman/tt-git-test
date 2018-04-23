/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-17   Mendel Guillaume       Created
1.1      2017-11-16   Kristin Hasna          Added 60 day documentation overdue option 
                                             to Eligiblity Factors
========+============+=================+===============================================*/

public with sharing class IncidentGuaranteeController
{
	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getStatuses()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		//TODO: use custom metadata type for list?

		options.add(new IncidentChargeCardManagerController.Option('Open', 'Open'));
		//options.add(new IncidentChargeCardManagerController.Option('Completed', 'Completed'));
		options.add(new IncidentChargeCardManagerController.Option('Pre-adjuster resolution process', 'Pre-adjuster resolution process'));
		options.add(new IncidentChargeCardManagerController.Option('Claim sent to adjuster', 'Claim sent to adjuster'));
		options.add(new IncidentChargeCardManagerController.Option('Claim in process', 'Claim in process'));
		options.add(new IncidentChargeCardManagerController.Option('Paid (under Property Damage Guarantee)', 'Paid (under Property Damage Guarantee)'));
		options.add(new IncidentChargeCardManagerController.Option('Paid (under Money Back Guarantee)', 'Paid (under Money Back Guarantee)'));
		options.add(new IncidentChargeCardManagerController.Option('Paid (under Satisfaction)', 'Paid (under Satisfaction)'));
		options.add(new IncidentChargeCardManagerController.Option('Not paid', 'Not paid'));

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getAdjusterStatuses()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncidentAction__c.AdjusterStatus__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getEligibilityFactors()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncidentAction__c.EligibilityFactors__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getGuaranteeTypes()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = MIIncidentAction__c.GuaranteeType__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static Map<String, List<IncidentChargeCardManagerController.Option>> getGuaranteeMap()
	{
		Map<String, List<IncidentChargeCardManagerController.Option>> optionsMap = new Map<String, List<IncidentChargeCardManagerController.Option>>();
		Map<String, List<String>> dependencies = UtilityDependentPicklist.GetDependentOptions('MIIncidentAction__c', 'GuaranteeType__c', 'EligibilityFactors__c');

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
	public static String save(MIIncidentAction__c request, MIIncident__c incident)
	{
		String response = 'Success';
		Savepoint sp = null;

		try
		{
			System.debug('Apex save');
			sp = Database.setSavepoint();
			update incident;

			//make sure a new guarantee is not created
			if(request.Id == null)
			{
				MIIncidentAction__c temp = getRequest(request.MIIncident__c);

				if(temp.Id != null)
				{
					request.Id = temp.Id;
				}
				else
				{
					request.RecordTypeId = MiIncidentActionTriggerHandler.GuaranteeRTId;
				}
			}

			upsert request;
		}
		catch(Exception ex)
		{
			if(sp != null)
			{
				Database.rollback(sp);
			}

			response = ex.getMessage() + ' - ' + ex.getStackTraceString();
		}

		return response;
	}

	@AuraEnabled
	public static MIIncidentAction__c getRequest(String incidentId)
	{
		MIIncidentAction__c request = new MIIncidentAction__c(RecordTypeId = MiIncidentActionTriggerHandler.GuaranteeRTId);
		List<MIIncidentAction__c> reqs = [SELECT Id, Name, Status__c, EligibilityFactors__c, PDGEligibility__c,
												AdjusterStatus__c, Notes__c, GuaranteeType__c
											FROM MIIncidentAction__c
											WHERE RecordTypeId =: MiIncidentActionTriggerHandler.GuaranteeRTId AND MIIncident__c =: incidentId
											ORDER BY LastModifiedDate DESC];

		if(!reqs.isEmpty())
		{
			request = reqs[0];
		}

		return request;
	}

	@AuraEnabled
	public static MIIncident__c getIncident(String incidentId)
	{
		return [SELECT Id, Name, request_create_time__c, hired_time__c, ElapsedHiredTimeDays__c, RecognizedDamageDate__c, 
					ReportedDate__c, ElapsedReportedTimeDays__c
				FROM MIIncident__c
				WHERE Id =: incidentId];

	}

	@AuraEnabled
	public static Map<String, String> getIncidentActionFieldsAccess()
	{
		List<String> queryFields = new List<String>{'Name', 'Status__c', 'EligibilityFactors__c', 'PDGEligibility__c', 'AdjusterStatus__c', 'Notes__c'};
		Map<String,Schema.SObjectField> fields = Schema.SObjectType.MIIncidentAction__c.fields.getMap();
		Map<String, String> fieldsAccess = new Map<String, String>();

		for(String qf : queryFields)
		{
			String access = 'none';
			Schema.DescribeFieldResult dfr = fields.get(qf).getDescribe();

			if(dfr.isAccessible())
			{
				access = 'read';

				if(dfr.isUpdateable())
				{
					access = 'edit';
				}
			}

			fieldsAccess.put(qf, access);
		}

		return fieldsAccess;
	}
}