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
1.0      2017-08-18   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class IncidentArbitrationController
{
	@AuraEnabled 
	public static List<IncidentChargeCardManagerController.Option> getStatuses()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = Arbitration__c.Status__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getDisputeChannels()
	{
		List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
		List<Schema.PicklistEntry> ples = Arbitration__c.dispute_channels__c.getDescribe().getPicklistValues();

		for(Schema.PicklistEntry p : ples)
		{
			options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
		}

		return options;
	}

	@AuraEnabled
	public static String save(Arbitration__c arbitration)
	{
		String response = 'Success';
		Savepoint sp = null;
		MIIncident__c incident = null;

		try
		{
			//make sure a new arbitration is not created
			if(arbitration.Id == null)
			{
				Arbitration__c temp = getArbitration(arbitration.Incident__c);

				if(temp.Id != null)
				{
					arbitration.Id = temp.Id;
				}
			}

			upsert arbitration;
			
			incident = getIncident(arbitration.Incident__c);

			if(arbitration.brief_description_of_dispute__c != incident.DescriptionOfDispute__c)
			{
				update new MIIncident__c(Id = incident.Id, DescriptionOfDispute__c = arbitration.brief_description_of_dispute__c);
			}
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
	public static Arbitration__c getArbitration(String incidentId)
	{
		Arbitration__c arbitration = new Arbitration__c();
		List<Arbitration__c> arbs = [SELECT Id, Name, Status__c, dispute_channels__c, dispute_amount__c, dispute_code__c,
										hearing_date__c, arbitrator_decision__c, support_team_member_email__c, support_team_member_name__c,
										claimant_first_name__c, claimant_last_name__c, claimant_phone__c, claimant_email__c,
										respondent_first_name__c, respondent_last_name__c, respondent_phone__c, respondent_email__c,
										brief_description_of_dispute__c, Incident__c, DateSubmitted__c
									FROM Arbitration__c
									WHERE Incident__c =: incidentId
									ORDER BY LastModifiedDate DESC];

		if(!arbs.isEmpty())
		{
			arbitration = arbs[0];
		}
		else
		{
			arbitration.DateSubmitted__c = Date.today();
		}

		return arbitration;
	}

	@AuraEnabled
	public static MIIncident__c getIncident(String incidentId)
	{
		return [SELECT Id, Name, IncidentRef__c, AmountInDispute__c, OwnerId, Owner.Name, Owner.Email, CustomerAccount__c,
					CustomerAccount__r.usr_first_name__c, CustomerAccount__r.usr_last_name__c, CustomerPhone__c,
					CustomerEmail__c, ProAccount__r.usr_first_name__c, ProAccount__c, ProAccount__r.usr_last_name__c, ProPhone__c,
					ProEmail__c, DescriptionOfDispute__c, CustomerContact__c, CustomerContact__r.Name
				FROM MIIncident__c
				WHERE Id =: incidentId];

	}
}