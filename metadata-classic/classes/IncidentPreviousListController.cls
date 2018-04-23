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

public with sharing class IncidentPreviousListController
{
	@AuraEnabled
	public static List<MIIncident__c> getProIncidents(String accountId, String incidentId)
	{
		return [SELECT Id, Name, IncidentNumber__c, MICategory__c, Status__c, CreatedDate, Owner.Name
		FROM MIIncident__c WHERE ProAccount__c =:accountId AND Id != :incidentId AND ProAccount__c != null ORDER BY CreatedDate DESC];
	}

	@AuraEnabled
	public static List<MIIncident__c> getCustomerIncidents(String accountId, String incidentId)
	{
		return [SELECT Id, Name, IncidentNumber__c, MICategory__c, Status__c, CreatedDate, Owner.Name
		FROM MIIncident__c WHERE CustomerAccount__c =:accountId AND Id != :incidentId AND CustomerAccount__c != null ORDER BY CreatedDate DESC];
	}
}