/*
	Copyright (c) [2015 -] 2018 Thumbtack. All rights reserved.

	Version    Date     Author            Description
	=======+===========+=================+=================================
	1.0     2018-02-09  Mendel Guillaume      Created
	========+============+=================+===============================*/

public class MiIncidentHelper
{
	public static final ID DISPUTE_OFFER_CONFIDENTIAL_RECORD_TYPE_ID = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();
	public static final ID DISPUTE_MESSAGE_CONFIDENTIAL_RECORD_TYPE_ID = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();

	public class MiIncidentQueueable implements Queueable
	{
		public Set<Id> confidentialIncidentIds {get;set;}

		public MiIncidentQueueable()
		{
		}

		public void execute(QueueableContext context)
		{
			try
			{
				if(confidentialIncidentIds != null && !confidentialIncidentIds.isEmpty())
				{
					updateRelatedRecordsToConfidential();
				}
			}
			catch(DmlException e)
			{
				system.debug(e);
			}
		}

		private void updateRelatedRecordsToConfidential()
		{
			List<SObject> objects = new List<SObject>();

			for (Case c : [SELECT Id FROM Case WHERE Incident__c IN :confidentialIncidentIds AND RecordTypeId != :CaseHelper.CONFIDENTIAL_RECORD_TYPE_ID])
			{
				c.RecordTypeId = CaseHelper.CONFIDENTIAL_RECORD_TYPE_ID;
				objects.add(c);
			}

			for(Dispute__c d : [SELECT Id FROM Dispute__c WHERE MIIncident__c IN :confidentialIncidentIds AND RecordTypeId != :DisputeTriggerHandler.CONFIDENTIAL_RECORD_TYPE_ID])
			{
				d.RecordTypeId = DisputeTriggerHandler.CONFIDENTIAL_RECORD_TYPE_ID;
				objects.add(d);
			}

			for(DisputeOffer__c d : [SELECT Id FROM DisputeOffer__c WHERE Dispute__r.MIIncident__c IN :confidentialIncidentIds AND RecordTypeId != :DISPUTE_OFFER_CONFIDENTIAL_RECORD_TYPE_ID])
			{
				d.RecordTypeId = DISPUTE_OFFER_CONFIDENTIAL_RECORD_TYPE_ID;
				objects.add(d);
			}

			for(DisputeMessage__c d : [SELECT Id FROM DisputeMessage__c WHERE DisputeOffer__r.Dispute__r.MIIncident__c IN :confidentialIncidentIds AND RecordTypeId != :DISPUTE_MESSAGE_CONFIDENTIAL_RECORD_TYPE_ID])
			{
				d.RecordTypeId = DISPUTE_MESSAGE_CONFIDENTIAL_RECORD_TYPE_ID;
				objects.add(d);
			}

			if(!objects.isEmpty())
			{
				objects.sort();
				Database.update(objects, false);
			}
		}
	}
}