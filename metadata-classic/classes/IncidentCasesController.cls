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
1.0      2017-08-28   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class IncidentCasesController
{
	@AuraEnabled
	public static List<Case> getRecords(String incidentId)
	{
		return [SELECT Id, CaseNumber, AccountId, Account.Name, Status, Owner.Name, MICasePrimaryCustomer__c,
					MICasePrimaryPro__c, OwnerId, OwnerIsQueue__c
				FROM Case WHERE Incident__c =: incidentId ORDER BY CaseNumber];
	}

	@AuraEnabled
	public static String detachCase(String caseId)
	{
		string result = 'success';

		try
		{
			Case c = new Case(ID = caseId, MIDoNotRelateIncident__c = true, Incident__c = null);

			update c;
		}
		catch(Exception ex)
		{
			result = ex.getMessage();
		}

		return result;
	}

	@AuraEnabled
	public static String saveCase(Case editCase)
	{
		string result = 'success';

		try
		{
			update editCase;
		}
		catch(Exception ex)
		{
			result = ex.getMessage();
		}

		return result;
	}

	@AuraEnabled
	public static List<Group> getQueues()
	{
		return [SELECT Id, Name
				FROM Group
				WHERE Type = 'Queue'
				AND Name IN ('Marketplace Integrity', 'Proactive MI Queue', 'Guarantee Queue', 'Low Dollar Satisfaction Queue',
								'Customer Support', 'Customer Support - Email', 'Pro Services')];
	}
}