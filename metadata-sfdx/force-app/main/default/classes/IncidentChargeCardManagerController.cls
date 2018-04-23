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
1.0      2017-08-15   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class IncidentChargeCardManagerController
{
	@AuraEnabled
	public static String save(MIIncidentAction__c request)
	{
		String response = 'Success';

		try
		{
			System.debug(request);
			request.RecordTypeId = MiIncidentActionTriggerHandler.ChargeRTId;
			upsert request;

		}
		catch(Exception ex)
		{
			response = ex.getMessage() + ' - ' + ex.getStackTraceString();
		}

		return response;
	}

	@AuraEnabled
	public static List<Option> getStatuses()
	{
		List<Option> options = new List<IncidentChargeCardManagerController.Option>();
		//TODO: use custom metadata type for list of statuses

		options.add(new Option('Open', 'Open'));
		options.add(new Option('Soft decline', 'Soft decline'));
		options.add(new Option('Hard decline', 'Hard decline'));
		options.add(new Option('No charge possible', 'No charge possible'));
		options.add(new Option('Successful', 'Successful'));
		options.add(new Option('Refunded', 'Refunded'));

		return options;
	}

	@AuraEnabled
	public static List<MIIncidentAction__c> getChargeCardRequests(String incidentId)
	{
		return [SELECT Id, Name, Status__c, LastModifiedBy.Name, LastModifiedDate, Amount__c FROM MIIncidentAction__c
				WHERE RecordTypeId =: MiIncidentActionTriggerHandler.ChargeRTId AND MIIncident__c =: incidentId
				ORDER BY LastModifiedDate DESC];
	}

	public class Option
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