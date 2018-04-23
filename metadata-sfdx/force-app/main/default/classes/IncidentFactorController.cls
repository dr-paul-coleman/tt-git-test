/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
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
------------
Version      Date          Author            Description
========++============++=================++====================================
1.0       08-01-2017     Adam Schulz     Created
========++============++=================++===================================*/
public class IncidentFactorController
{

	@AuraEnabled
	public static List<Map<String, Object>> getFactors(Id incidentId)
	{

		List<Map<String, Object>> result = new List<Map<String, Object>>();
		if (incidentId != null)
		{

			Map<Id, Map<String, Object>> factorsById = new Map<Id, Map<String, Object>>();
			for (IncidentFactor__c factor : [
					Select Id, Name, HelpText__c
					From IncidentFactor__c
					Where IsActive__c = true AND Name != null
					order by Name
			])
			{

				Map<String, Object> factorMap = new Map<String, Object>
				{
						'record' => factor
				};
				factorsById.put(factor.Id, factorMap);
				result.add(factorMap);

			}
			if (!factorsById.isEmpty())
			{

				for (IncidentFactorAssignment__c assignment : [
						Select Id, Factor__c
						From IncidentFactorAssignment__c
						Where Incident__c = :incidentId
						And Factor__c IN :factorsById.keySet() AND IsDeleted__c = false
				])
				{

					factorsById.get(assignment.Factor__c).put('assignmentId', assignment.Id);

				}

			}

		}
		return result;

	}

	@AuraEnabled
	public static IncidentFactorAssignment__c createAssignment(Id incidentId, Id factorId)
	{
		List<IncidentFactorAssignment__c> assignments = [SELECT Id FROM IncidentFactorAssignment__c
															WHERE Incident__c =: incidentId AND Factor__c = :factorId];
		IncidentFactorAssignment__c result = null;

		if(assignments.isEmpty())
		{
			result = new IncidentFactorAssignment__c (Incident__c = incidentId, Factor__c = factorId);
		}
		else
		{
			result = assignments[0];
			result.IsDeleted__c = false;
		}

		upsert result;

		return result;
	}

	@AuraEnabled
	public static void deleteAssignment(Id assignmentId)
	{
		IncidentFactorAssignment__c result = new IncidentFactorAssignment__c(Id = assignmentId, IsDeleted__c = true);
		update result;
	}
}