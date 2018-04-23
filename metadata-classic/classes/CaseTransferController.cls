/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-11-21   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

public with sharing class CaseTransferController
{
	@AuraEnabled
	public static List<User> getUsersForPersonTransfer()
	{
		return [SELECT Id, Name FROM User WHERE IsActive = true AND AllowCaseTransfer__c IN ('Person', 'Escalation') ORDER BY Name];
	}

	@AuraEnabled
	public static List<User> getUsersForEscalationTransfer()
	{
		return [SELECT Id, Name FROM User WHERE IsActive = true AND AllowCaseTransfer__c = 'Escalation' ORDER BY Name];
	}

	@AuraEnabled
	public static List<Group> getGroupsForTransfer()
	{
		return (List<Group>)Database.query('SELECT Id, Name FROM GROUP WHERE Type = \'Queue\' AND Name IN (' + System.Label.CaseTransferQueueFilter + ') ORDER BY Name');
	}

	@AuraEnabled
	public static Case getCase(String caseId)
	{
		return [SELECT Id, OwnerId, Owner.Name FROM Case WHERE Id = :caseId];
	}

	@AuraEnabled
	public static String assignToMe(String caseId) 
	{
		return assignCase(caseId, UserInfo.getUserId(), null, null);
	}

	@AuraEnabled
	public static String assignCase(String caseId, String ownerId, String comment, String escalationType)
	{
		String result = 'Success';
		Boolean isTeam = ownerId != null && ownerId.startsWith('00G');
		Boolean escalated = String.isNotBlank(escalationType);
		Case c;
		CaseUpdateHistory__c cuh = new CaseUpdateHistory__c(Case__c = caseId, CaseTransferPost__c = comment,
				EscalatedCaseType__c = escalationType,
				RecordTypeId = CaseUpdateHistory__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Case Transfer Update').getRecordTypeId());


		try
		{
			c = [SELECT Id, OwnerId, Owner.Name, Team__c FROM Case WHERE Id = :caseId];

			cuh.EscalatedCase__c = escalated;

			if(isTeam)
			{
				Group ownerGroup = [SELECT Id, Name FROM Group WHERE Id = :ownerId];
				cuh.CaseOwnerTeam__c = ownerGroup.Name;
				cuh.CaseOwner__c = ownerGroup.Name;
			}
			else
			{
				User ownerUser = [SELECT Id, Name, Team__c FROM User WHERE Id = :ownerId];
				cuh.CaseOwner__c = ownerUser.Name;
				cuh.CaseOwnerTeam__c = ownerUser.Team__c;
			}

			if(String.valueOf(c.OwnerId).startsWith('00G'))
			{
				cuh.CasePreviousOwnerTeam__c = c.Owner.Name;
				cuh.CasePreviousOwner__c = c.Owner.Name;
			}
			else
			{
				cuh.CasePreviousOwner__c = c.Owner.Name;
				cuh.CasePreviousOwnerTeam__c = c.Team__c;
			}

			c.OwnerId = ownerId;
			update c;
			insert cuh;

			if(String.isNotBlank(comment))
			{
				CaseController.postMsgWithMentions(caseId, comment);
			}

		}
		catch (Exception ex)
		{
			result = 'Error: ' + ex.getMessage();
		}

		return result;
	}
}