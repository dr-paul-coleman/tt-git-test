/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-10   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

public with sharing class DisputeController
{
	@AuraEnabled
	public static Dispute__c getNewDispute(Id incidentId)
	{
		List<Dispute__c> disputes = [SELECT Id, Name, Status__c, Stage__c, LastStageChangeDate__c, SolutionCenterLink__c,
											OverallDisputeTimeInDays__c, OverallMessageCount__c, OverallOfferCount__c
										FROM Dispute__c WHERE MIIncident__c = :incidentId LIMIT 1];
		Dispute__c d = null;

		if(disputes.isEmpty())
		{
			MIIncident__c incident = getIncident(incidentId);
			List<DisputeExperience__c> defaultExperiences = [SELECT Id FROM DisputeExperience__c WHERE DefaultExperience__c = true AND Status__c = 'Published'];
			List<becquerel_mi_incident_project_data__x> projectData = null;

			d = new Dispute__c(MIIncident__c = incidentId, Status__c = 'Awaiting', Stage__c = 'Initiator confirmation needed');

			if (!defaultExperiences.isEmpty())
			{
				d.DisputeExperience__c = defaultExperiences[0].Id;
			}

			if (String.isNotBlank(incident.bid_id__c))
			{
				if (Test.isRunningTest())
				{
					projectData = new List<becquerel_mi_incident_project_data__x>
					{
						new becquerel_mi_incident_project_data__x(request_category__c = 'Test Category',
							request_city__c = 'Salt Lake City', request_state__c = 'UT', request_zip__c = '84044', bid_id__c = 123456)
					};
				}
				else
				{
					projectData = [
						SELECT Id, request_category__c, request_city__c, request_state__c, request_zip__c
						FROM becquerel_mi_incident_project_data__x
						WHERE bid_id__c = :Decimal.valueOf(incident.bid_id__c)
						LIMIT 1
					];
				}

				if (!projectData.isEmpty())
				{
					d.request_zip__c = projectData[0].request_zip__c;
					d.request_state__c = projectData[0].request_state__c;
					d.request_city__c = projectData[0].request_city__c;
					d.request_category__c = projectData[0].request_category__c;
				}
			}

			d.PrePopulatedResolutionAmount__c = incident.AmountInDispute__c;
			d.Description__c = incident.DescriptionOfDispute__c;
			d.bid_pk__c = incident.bid_id__c;
			d.InitiatorContact__c = incident.CustomerContact__c;
		}
		else
		{
			d = disputes[0];
		}

		return d;
	}

	@AuraEnabled
	public static MIIncident__c getIncident(Id incidentId)
	{
		return [SELECT Id, ProContact__c, ProAccount__c, ProContact__r.Name, CustomerAccount__c, CustomerContact__c,
					CustomerContact__r.Name, AmountInDispute__c, DescriptionOfDispute__c, bid_id__c,
					ProContact__r.user_pk_id__c, CustomerContact__r.user_pk_id__c
				FROM MIIncident__c WHERE Id = :incidentId];
	}

	@AuraEnabled
	public static List<String> getResolutions(Id disputeExperienceId)
	{
		List<String> options = new List<String>();
		List<DisputeExperience__c> experiences = [SELECT ResolutionOptions__c FROM DisputeExperience__c WHERE Id = :disputeExperienceId AND Status__c = 'Published'];

		if(!experiences.isEmpty() && string.isNotBlank(experiences[0].ResolutionOptions__c))
		{
			options = experiences[0].ResolutionOptions__c.split(';');
		}

		return options;
	}

	@AuraEnabled
	public static String saveDispute(Dispute__c dispute)
	{
		String result = 'Success';

		try
		{
			insert dispute;
		}
		catch (Exception ex)
		{
			result = ex.getMessage();
		}

		return result;
	}
}