public class EnrollmentEventLogUtility {

	private static Map<Id, Map<String, Map<String, Map<String, Set<String>>>>> dupGuard = new Map<Id, Map<String, Map<String, Map<String, Set<String>>>>> ();
	private static Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>();
	private static Map<String, EnrollmentRule__c[]> rulesMap = new Map<String, EnrollmentRule__c[]>();

	public static void handleObjectChanges(SObject[] newRecords, Map<Id, SObject> oldMap)
	{
		if (newRecords != null && !newRecords.isEmpty())
		{
			Schema.DescribeSObjectResult objDescribe = getSOjbectDescribe((Id) newRecords[0].get('Id'));
			if (objDescribe != null)
			{
				EnrollmentRule__c[] rules = getEventLogRules(objDescribe);
				if (!rules.isEmpty())
				{
					Map<Id, List<EnrollmentRule__c>> rulesByObjId = checkForEvents(newRecords, oldMap, rules);
					if (!rulesByObjId.isEmpty())
					{
						Map<Id, List<Id>> enrollmentIdsByObjId = getEnrollmentsForRecords(rulesByObjId.keySet(), rules[0].EventLogObjectEnrollmentRelationship__c);
						if (!enrollmentIdsByObjId.isEmpty())
						{
							createEventLogActions(new Map<Id, SObject> (newRecords), oldMap, rulesByObjId, enrollmentIdsByObjId);
						}
					}
				}
			}
		}
	}

	private static Schema.DescribeSObjectResult getSOjbectDescribe(Id objId)
	{
		Schema.DescribeSObjectResult objDescribe;
		if (objId != null)
		{
			String objPrefix = String.valueOf(objId).substring(0, 3);
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			for (String gdKey : gd.keySet())
			{
				Schema.DescribeSObjectResult v_describe = gd.get(gdKey).getDescribe();
				if (objPrefix == v_describe.getKeyPrefix())
				{
					objDescribe = v_describe;
					break;
				}
			}
		}
		return objDescribe;
	}

	private static EnrollmentRule__c[] getEventLogRules(Schema.DescribeSObjectResult objDescribe)
	{
		EnrollmentRule__c[] result = new EnrollmentRule__c[0];
		if (objDescribe != null)
		{
			String objectName = objDescribe.getName();
			if(rulesMap.containsKey(objectName))
			{
				result = rulesMap.get(objectName);
			}
			else
			{
				result = (EnrollmentRule__c[]) Database.query(
						'Select ' + String.join(ProEnrollmentUtility.getEnrollmentRuleFields(), ', ') + ' From EnrollmentRule__c '
								+ 'Where IsActive__c = true '
								+ 'And EnrollmentActionType__c = \'Event Log\' '
								+ 'And EventLogObject__c = :objectName '
				);
				//add to map for future use if needed
				rulesMap.put(objectName, result);
				System.debug(LoggingLevel.INFO, 'Utility - 63 query');
			}
		}
		return result;
	}

	private static Map<Id, List<EnrollmentRule__c>> checkForEvents(List<SObject> newRecords, Map<Id, SObject> oldMap, List<EnrollmentRule__c> rules)
	{
		Map<Id, List<EnrollmentRule__c>> result = new Map<Id, List<EnrollmentRule__c>> ();
		if (!rules.isEmpty())
		{
			for (SObject newRecord : newRecords)
			{
				SObject oldRecord = oldMap.get((Id) newRecord.get('Id'));
				for (EnrollmentRule__c rule : rules)
				{
					Id objId = (Id) newRecord.get('Id');
					if (newRecord.get(rule.EventLogField__c) != oldRecord.get(rule.EventLogField__c))
					{
						List<EnrollmentRule__c> rulesForObj = result.get(objId);
						rulesForObj = rulesForObj == null ? new List<EnrollmentRule__c> () : rulesForObj;
						rulesForObj.add(rule);
						result.put(objId, rulesForObj);
					}
				}
			}
		}
		return result;
	}

	private static Map<Id, List<Id>> getEnrollmentsForRecords(Set<Id> newRecordIds, String relationship)
	{
		Map<Id, List<Id>> result = new Map<Id, List<Id>> ();
		if (String.isNotBlank(relationship) && !newRecordIds.isEmpty()) {
			System.debug(LoggingLevel.INFO, 'Utility - 105 query');
			for (Enrollment__c enrollment : (List<Enrollment__c>) Database.query( 'Select outreach_type__c,' + relationship + ' From Enrollment__c ' + 'Where ' + relationship + ' IN :newRecordIds ' ))
			{
				if(!enrollmentMap.containsKey(enrollment.Id)){ enrollmentMap.put(enrollment.Id, enrollment); }
				SObject obj = enrollment;
				List<String> relationshipList = relationship.split('\\.');
				for (Integer i = 0; i < relationshipList.size(); i++)
				{
					String fieldName = relationshipList[i];
					if (i < (relationshipList.size() - 1))
					{
						obj = (SObject) obj.getSObject(fieldName);
					} else
					{
						Id objId = (Id) obj.get(fieldName);
						List<Id> enrollmentIds = result.get(objId);
						enrollmentIds = enrollmentIds == null ? new List<Id> () : enrollmentIds;
						enrollmentIds.add(enrollment.Id);
						result.put(objId, enrollmentIds);
					}
				}
			}
		}
		return result;
	}

	private static void createEventLogActions(Map<Id, SObject> newMap, Map<Id, SObject> oldMap, Map<Id, List<EnrollmentRule__c>> rulesByObjId, Map<Id, List<Id>> enrollmentIdsByObjId) {

		EnrollmentAction__c[] actionsForInsert = new EnrollmentAction__c[0];
		Id[] enrollmentIds = new Id[0];

		for (Id objId : rulesByObjId.keySet())
		{
			for (EnrollmentRule__c rule : rulesByObjId.get(objId))
			{
				for (Id enrollmentId : enrollmentIdsByObjId.get(objId))
				{
					SObject newRecord = newMap.get(objId);
					SObject oldRecord = oldMap.get(objId);
					actionsForInsert.addAll(
						populateEventLogAction(enrollmentId, String.valueOf(oldRecord.get(rule.EventLogField__c)), String.valueOf(newRecord.get(rule.EventLogField__c)), rule)
					);
				}
			}
		}
		System.debug(LoggingLevel.INFO,'actionsForInsert: ' + actionsForInsert.size());
		ProEnrollmentUtility.createEnrollmentActions(actionsForInsert);
		//QueueableUtility.handleQueueable(new ProEnrollmentUtility('createEnrollmentActions', actionsForInsert));

	}

	private static Boolean hasDupEventLog(Id enrollmentId, String oldValue, String newValue, EnrollmentRule__c rule) {

		Boolean result = false;
		Map<String, Map<String, Map<String, Set<String>>>> objMap = dupGuard.containsKey(enrollmentId) ? dupGuard.get(enrollmentId) : new Map<String, Map<String, Map<String, Set<String>>>> ();
		Map<String, Map<String, Set<String>>> fieldMap = objMap.containsKey(rule.EventLogObject__c) ? objMap.get(rule.EventLogObject__c) : new Map<String, Map<String, Set<String>>> ();
		Map<String, Set<String>> oldValMap = fieldMap.containsKey(rule.EventLogField__c) ? fieldMap.get(rule.EventLogField__c) : new Map<String, Set<String>> ();
		Set<String> newValSet = oldValMap.containsKey(oldValue) ? oldValMap.get(oldValue) : new Set<String> ();
		result = newValSet.contains(newValue);
		newValSet.add(newValue);
		oldValMap.put(oldValue, newValSet);
		fieldMap.put(rule.EventLogField__c, oldValMap);
		objMap.put(rule.EventLogObject__c, fieldMap);
		dupGuard.put(enrollmentId, objMap);
		return result;

	}

	private static EnrollmentAction__c[] populateEventLogAction(Id enrollmentId, String oldValue, String newValue, EnrollmentRule__c rule)
	{
		EnrollmentAction__c[] result = new EnrollmentAction__c[0];

		if (!hasDupEventLog(enrollmentId, oldValue, newValue, rule))
		{
			EnrollmentAction__c action = new EnrollmentAction__c(
					Type__c = 'Event Log',
					Details__c = rule.Details__c,
					Enrollment__c = enrollmentId,
					RuleId__c = String.valueOf(rule.Id),
					EventLogObject__c = rule.EventLogObject__c,
					EventLogField__c = rule.EventLogField__c,
					EventLogOldFieldValue__c = oldValue,
					EventLogNewFieldValue__c = newValue,
					Name = rule.Name
			);
			result.add(action); 

			if (rule.EventLogField__c == 'FunnelStep__c')
			{
				Enrollment__c enrollment = enrollmentMap.get(enrollmentId);
				ProEnrollmentUtility.outreachType = null == enrollment ? ProEnrollmentUtility.outreachType : enrollment.outreach_type__c;
				Integer oldValueOrder = ProEnrollmentUtility.funnelStepOrderMap.get(oldValue);
				Integer newValueOrder = ProEnrollmentUtility.funnelStepOrderMap.get(newValue);

				if (oldValueOrder != null && newValueOrder != null && (oldValueOrder + 1) != newValueOrder && (oldValueOrder - 1) != newValueOrder)
				{
					String v_old = oldValue;

					if (oldValueOrder < newValueOrder)
					{
						v_old = ProEnrollmentUtility.funnelStepSettings[oldValueOrder + 1].MasterLabel;
						action.EventLogNewFieldValue__c = v_old;
					}
					else if (oldValueOrder > newValueOrder)
					{
						v_old = ProEnrollmentUtility.funnelStepSettings[oldValueOrder - 1].MasterLabel;
						action.EventLogNewFieldValue__c = v_old;
					}

					result.addAll(populateEventLogAction(enrollmentId, v_old, newValue, rule));
				}
			}
		}

		System.debug(LoggingLevel.INFO, 'Event result size: ' + result.size());
		return result;
	}

}