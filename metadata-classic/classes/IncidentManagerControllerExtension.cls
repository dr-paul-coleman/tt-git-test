/**
 * Created by SentientGrey on 10/31/17.
 */

public with sharing class IncidentManagerControllerExtension
{
	public MIIncident__c incident{get;set;}
	public Id incidentId {get;set;}

	public IncidentManagerControllerExtension(ApexPages.StandardController stdController)
	{
		this.incidentId = stdController.getId();
		loadRecord();
	}

	private void loadRecord()
	{
		if(this.incidentId != null)
		{
			this.incident = [SELECT Id, ProPhone__c, CustomerPhone__c FROM MIIncident__c WHERE Id = :this.incidentId];
		}
	}

	public void refresh()
	{
		loadRecord();
	}
}