/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-17   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

public with sharing class QuickTipController
{
	@AuraEnabled
	public static Dispute__c getDispute(String disputeId)
	{
		return [SELECT Id, InitiatorContact__c, InitiatorContact__r.Name, ResponderContact__c, ResponderContact__r.Name,
				InternalLinkInitiator__c, InternalLinkResponder__c,
				(SELECT Id FROM DisputeOffers__r ORDER BY CreatedDate DESC LIMIT 1)
				FROM Dispute__c WHERE Id = :disputeId];
	}

	@AuraEnabled
	public static List<DisputeContentWrapper> getSuccessTips()
	{
		List<DisputeContentWrapper> dcs = new List<QuickTipController.DisputeContentWrapper>();

		for(DisputeContent__c dc : [SELECT Id, Name, MessageTemplate__c, Type__c
				FROM DisputeContent__c
				WHERE Status__c = 'Published' AND Type__c IN ('Automated tip', 'Manual tip') AND RecordType.Name = 'Content Template'])
		{
			dcs.add(new DisputeContentWrapper(dc));
		}

		return dcs;
	}

	@AuraEnabled
	public static Id getUserId(String contactId)
	{
		Id userId = null;

		if(String.isNotBlank(contactId))
		{
			List<User> users = [SELECT Id FROM User WHERE ContactId = :contactId];

			if(!users.isEmpty())
			{
				userId = users[0].Id;
			}
		}

		return userId;
	}

	@AuraEnabled
	public static String saveMessage(DisputeMessage__c message, String cloneId)
	{
		String success = 'Success';
		List<DisputeMessage__c> messages = new List<DisputeMessage__c>();
		List<DisputeOffer__c> offers = [SELECT Id FROM DisputeOffer__c
										WHERE Dispute__c = :message.Dispute__c
										ORDER BY CreatedDate DESC
										LIMIT 1];

		try
		{
			if(!offers.isEmpty() && offers[0].Id != message.DisputeOffer__c)
			{
				message.DisputeOffer__c = offers[0].Id;
			}

			message.RecordTypeId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Success Tip').getRecordTypeId();
			messages.add(message);

			if(String.isNotBlank(cloneId))
			{
				DisputeMessage__c mClone = message.clone();
				mClone.ContactSharedWith__c = cloneId;
				messages.add(mClone);
			}

			insert messages;
		}
		catch (Exception ex)
		{
			success = ex.getMessage();
		}

		return success;
	}

	public class DisputeContentWrapper
	{
		@AuraEnabled
		public String template {get{return this.record != null && this.record.MessageTemplate__c != null ? this.record.MessageTemplate__c.stripHtmlTags() : '';}}

		@AuraEnabled
		public DisputeContent__c record{get;set;}

		public DisputeContentWrapper(DisputeContent__c dc)
		{
			this.record = dc;
		}
	}
}