public with sharing class ProEnrollmentUtility implements Queueable {

	private String queue_method {get; set;}
	private List<SObject> queue_sobjects {get; set;}

	public ProEnrollmentUtility(String methodName, List<SObject> sobjects) {

		queue_method = methodName;
		queue_sobjects = sobjects;

	}

	public void execute(QueueableContext context) {

		if (queue_method == 'createEnrollmentActions')
		{
			List<EnrollmentAction__c> actionsForMethod = new List<EnrollmentAction__c> ();
			EnrollmentAction__c[] actionsForQueue = new EnrollmentAction__c[0];

			//If we have more than 5000
			if (queue_sobjects.size() > 5000)
			{
				Map<Id, EnrollmentAction__c[]> actionsByEnrollment = new Map<Id, EnrollmentAction__c[]> ();
				for (EnrollmentAction__c action : (EnrollmentAction__c[])queue_sobjects)
				{
					System.debug('*****action in queue: ' + action);
					//EnrollmentAction__c[] actionsForEnrollment = actionsByEnrollment.containsKey(action.Enrollment__c) ? actionsByEnrollment.get(action.Enrollment__c) : new EnrollmentAction__c[0];
					//actionsForEnrollment.add(action);
					//actionsByEnrollment.put(action.Enrollment__c, actionsForEnrollment);

					if(!actionsByEnrollment.containsKey(action.Enrollment__c))
					{
						actionsByEnrollment.put(action.Enrollment__c, new EnrollmentAction__c[0]);
					}

					actionsByEnrollment.get(action.Enrollment__c).add(action);
				}
				for (Id enrollmentId : actionsByEnrollment.keySet())
				{

					actionsForMethod.addAll(actionsByEnrollment.remove(enrollmentId));
					if (actionsForMethod.size() > 5000)
					{
						for (EnrollmentAction__c[] actionList : actionsByEnrollment.values())
						{
							actionsForQueue.addAll(actionList);
						}
						break;
					}
				}
			}
			ProEnrollmentUtility.createEnrollmentActions(actionsForMethod);
			if (!actionsForQueue.isEmpty() && Limits.getQueueableJobs() == 0)
			{
				Id jobId = Test.isRunningTest() ? null : System.enqueueJob(new ProEnrollmentUtility('createEnrollmentActions', actionsForQueue));
			}
		}
	}
	
	private static List<String> enrollmentFields = new List<String> (new Set<String> {
		'Id', 
		'Name', 
		'rca_request_category_id__c', 
		'rca_name__c', 
		'zip_cbsa_code__c', 
		'zip_cbsa_name__c', 
		'outreach_group__c', 
		'outreach_type__c',
		'OwnerId', 
		'Owner.Name',
		'enrollment_id__c', 
		'Market__c', 
		'Market__r.outreach_type__c', 
		'Market__r.rca_name__c',
		'Market__r.zip_cbsa_name__c',
		'Market__r.RequestCategory__r.outreach_type__c',
		'Rank__c', 
		'risk_level__c', 
		'FunnelStep__c', 
		'user_id__c', 
		'RecordTypeId', 
		'UnsuccessfulReason__c',
		'OutreachAttemptsRemaining__c',
		'Account__c',
		'Account__r.EnrollmentCallbackDateTime__c',
		'Account__r.EnrollmentAssignedTo__c',
		'Account__r.EnrollmentCallbackPhone__c',
		'Account__r.EnrollmentCallbackOrigin__c',
		'Account__r.EnrollmentCallbackScheduledBy__r.Name',
		'PriorityFinal__c',
		'PricingURL__c',
		'LeadMigratedFrom__c',
		'Market__r.RequestCategory__r.EnrollAProEnabled__c',
		'Market__r.EnrollAProEnabled__c', 
        'SoldBy__c',
		'CallbackOutreachType__c'
	});

	private static List<String> enrollmentRuleFields = new List<String> (new Set<String> {
		'Id',
		'Name',
		'Details__c',
		'EnrollmentActionOrder__c',
		'EnrollmentActionType__c',
		'EnrollmentLink__c',
        'EnrollmentActionColor__c',
		'EnrollmentOutreachDisposition__c',
		'EnrollmentFunnelStep__c',
		'EnrollmentOutreachGroup__c',
		'IsActive__c',
		'IsTest__c',
		'EnrollmentOutreachType__c',
		'SetEnrollmentFunnelStepTo__c',
		'SetEnrollmentRecordtypeTo__c',
		'SetEnrollmentUnsuccessfulReasonTo__c',
		'IsAutonomous__c',
		'IsAutomatedAction__c',
		'EnrollmentActionOutcome__c',
		'EventLogObject__c',
		'EventLogField__c',
		'EventLogObjectEnrollmentRelationship__c',
		'SubSteps__c',
		'URLRequired__c',
		'PrerequisiteRuleName__c',
		'PrerequisiteRuleOutcome__c',
		'IsCallbackRule__c',
		'ShowSurveyForOutreachType__c',
		'ShowSurveyForFunnelStep__c',
		'ShowSurveyAsModalForOutreachType__c',
		'IsRequiredBasedOnPrerequisites__c',
		'SetEnrollmentCallbackOutreachTypeTo__c'
	});

	private static List<String> enrollmentActionFields = new List<String> (new Set<String> {
		'Id',
		'Name',
		'OutreachDisposition__c',
		'Outcome__c',
		'Details__c',
		'Enrollment__c',
		'Enrollment__r.Market__r.rca_name__c',
		'Enrollment__r.Market__r.zip_cbsa_name__c',
		'IsTest__c',
		'Notes__c',
		'RuleId__c',
		'Type__c',
		'CreatedDate', 
		'CreatedBy.Name',
		'LastModifiedDate', 
		'LastModifiedBy.Name',
		'CompletedOn__c',
		'CompletedBy__c',
		'CompletedBy__r.Name',
		'EventLogObject__c',
		'EventLogField__c',
		'EventLogOldFieldValue__c',
		'EventLogNewFieldValue__c',
		'URL__c',
		'CallbackAssignedTo__c',
		'CallbackAssignedTo__r.Name',
		'CallbackDateTime__c',
		'CallbackPhone__c',
		'outreach_type__c',
		'CallbackOutreachType__c'
	});

	private static List<String> userFields = new List<String> (new Set<String> {
		'Id',
		'FirstName',
		'LastName'
	});

	public static String outreachType{get;set;}

	public static List<FunnelStepSetting__mdt> funnelStepSettings
	{
		get
		{
			if (funnelStepSettings == null)
			{
				funnelStepSettings = database.query('Select Id, MasterLabel, DeveloperName, Order__c, EnrollmentOutreachTypeCanChange__c, IsMilestone__c, ' +
						'AvailableforOutreachTypes__c ' +
						'From FunnelStepSetting__mdt ' +
						(outreachType != null ? 'WHERE AvailableforOutreachTypes__c LIKE \'%' + outreachType + '%\' ' : '') +
						'order by Order__c');
			}

			return funnelStepSettings;
		}
		set;
	}

	public static Map<String, Integer> funnelStepOrderMap
	{
		get
		{
			if (funnelStepOrderMap == null)
			{
				funnelStepOrderMap = new Map<String, Integer>();

				for (Integer i = 0; i < funnelStepSettings.size(); i++)
				{
					funnelStepOrderMap.put(funnelStepSettings[i].MasterLabel, i);
				}
			}

			return funnelStepOrderMap;
		}
		set;
	}

	public static Set<String> milestoneFunnelSteps {

		get
		{
			if (milestoneFunnelSteps == null)
			{
				milestoneFunnelSteps = new Set<String> ();
				for (FunnelStepSetting__mdt setting : funnelStepSettings)
				{
					if (setting.IsMilestone__c)
					{
						milestoneFunnelSteps.add(setting.MasterLabel);
					}
				}
			}
			return milestoneFunnelSteps;
		} set;
	}

	private static Map<String, String> ruleToEnrollmentFieldMapping = new Map<String, String>
	{
		'SetEnrollmentFunnelStepTo__c' => 'FunnelStep__c',
		'SetEnrollmentUnsuccessfulReasonTo__c' => 'UnsuccessfulReason__c'
	};

	public static List<String> getEnrollmentFields()
	{

		return enrollmentFields;

	}

	public static List<String> getEnrollmentRuleFields()
	{

		return enrollmentRuleFields;

	}

	public static List<String> getEnrollmentActionFields()
	{

		return enrollmentActionFields;

	}

	public static Map<String, String> getRuleToEnrollmentFieldMapping()
	{

		return ruleToEnrollmentFieldMapping;

	}

	public static User getCurrentUser()
	{
		Id userId = UserInfo.getUserId();
		return (User) Database.query(
			'Select ' + String.join(userFields, ', ') + ' From User Where Id = :userId '
		);
	}

	public static Enrollment__c getEnrollment(Id enrollmentId)
	{
		Enrollment__c result;
		if (enrollmentId != null)
		{
			List<Enrollment__c> enrollments = getEnrollments(new List<Id> {enrollmentId});
			if (!enrollments.isEmpty()) { result = enrollments[0]; }
		}
		return result;
	}

	public static Enrollment__c[] getEnrollments(Id[] enrollmentIds)
	{
		Enrollment__c[] result = new Enrollment__c[0];
		if (enrollmentIds != null && !enrollmentIds.isEmpty())
		{
			result = (List<Enrollment__c>) Database.query('Select ' + String.join(enrollmentFields, ', ') + ' From Enrollment__c Where Id IN :enrollmentIds ');
		}
		return result;
	}

	public static EnrollmentAction__c createEnrollmentAction(EnrollmentAction__c action)
	{

		if (action != null) {

			createEnrollmentActions(new List<EnrollmentAction__c> {action});

		}
		return action;

	}

	public static EnrollmentAction__c[] createEnrollmentActions(EnrollmentAction__c[] actions)
	{
		DateTime now = System.now();
		Id meId = UserInfo.getUserId();
		User me = [Select Team__c, Profile.Name From User Where Id = :meId];
		Map<Id, List<EnrollmentAction__c>> actionsByEnrollment = new Map<Id, List<EnrollmentAction__c>> ();
		for (EnrollmentAction__c action : actions)
		{
			action.CompletedOn__c = now;
			action.CompletedBy__c = meId;
			action.UserTeam__c = me.Team__c;
			action.UserProfile__c = me.Profile.Name;
			List<EnrollmentAction__c> v_actions = actionsByEnrollment.containsKey(action.Enrollment__c) ? actionsByEnrollment.get(action.Enrollment__c) : new List<EnrollmentAction__c> ();
			v_actions.add(action);
			actionsByEnrollment.put(action.Enrollment__c, v_actions);
		}

		Map<Id, Enrollment__c> enrollmentsForUpdate = new Map<Id, Enrollment__c> ();
		for (Enrollment__c enrollment : getEnrollments(new List<Id> (actionsByEnrollment.keySet())))
		{
			for (EnrollmentAction__c action : actionsByEnrollment.get(enrollment.Id))
			{
				action.outreach_type__c = enrollment.Market__r.RequestCategory__r.outreach_type__c;
				if (String.isNotBlank(action.CallbackOutreachType__c))
				{
					enrollment.CallbackOutreachType__c = action.CallbackOutreachType__c;
					enrollmentsForUpdate.put(enrollment.Id, enrollment);
				}
			}
		}

        // PBC: emergency patch for UNABLE TO LOCK ROW all-or-nothing email distros to systems@
		// avoid all-or-nothing DML failures
        Database.update( enrollmentsForUpdate.values(), false );
        EnrollmentAction__c[] resubmitInserts = new EnrollmentAction__c[0];
        EnrollmentAction__c[] resubmitUpdates = new EnrollmentAction__c[0];
        Integer actionIndex = 0;
		for( Database.UpsertResult result: Database.upsert(actions, false) )
		{
			System.debug('*****actoin create: ' + result.isSuccess());
			if( !result.isSuccess() )
            {
                EnrollmentAction__c eAction = actions[actionIndex];
                if( NULL != eAction.Id )
                {
                    resubmitUpdates.add( eAction );
                }
                else
                {
                    resubmitInserts.add( eAction );
                }
            }
            actionIndex++;
		}

        // for failed DML records, attempt to complete the dml asynchronously
        if( !resubmitUpdates.isEmpty() && !Test.isRunningTest())
        {
            QueueableUtility.handleQueueable(new DMLQueueable( resubmitUpdates, DMLQueueable.Operation.UPDATES ) );
        }

        if( !resubmitUpdates.isEmpty() && !Test.isRunningTest())
        {
            QueueableUtility.handleQueueable( new DMLQueueable( resubmitUpdates, DMLQueueable.Operation.INSERTS ) );
		}

        // END emergency patch
		return actions;

	}

	public static Map<String, Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>>> getAllStepRules()
	{

		Map<String, Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>>> result = new Map<String, Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>>> ();
		for (EnrollmentRule__c rule : (List<EnrollmentRule__c>) Database.query(
										'Select ' + String.join(ProEnrollmentUtility.getEnrollmentRuleFields(), ', ') + ' From EnrollmentRule__c '
										+ 'Where IsActive__c = true '
										+ 'And EnrollmentActionType__c IN (\'Onboarding Step\', \'Outreach Attempt\') '
										+ 'And EnrollmentFunnelStep__c != null '
										+ 'And EnrollmentOutreachType__c != null '
										+ 'And EnrollmentOutreachGroup__c != null '
										+ 'order by EnrollmentActionOrder__c '
									))
		{
			Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> ruleMapByGroup = result.get(rule.EnrollmentActionType__c);
			ruleMapByGroup = ruleMapByGroup == null ? new Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> () : ruleMapByGroup;
			for (String outreachGroup : rule.EnrollmentOutreachGroup__c.split(';'))
			{
				Map<String, Map<String, List<EnrollmentRule__c>>> ruleMapByOutreach = ruleMapByGroup.get(outreachGroup);
				ruleMapByOutreach = ruleMapByOutreach == null ? new Map<String, Map<String, List<EnrollmentRule__c>>> () : ruleMapByOutreach;
				for (String outreachType : rule.EnrollmentOutreachType__c.split(';'))
				{
					Map<String, List<EnrollmentRule__c>> rulesByStep = ruleMapByOutreach.get(outreachType);
					rulesByStep = rulesByStep == null ? new Map<String, List<EnrollmentRule__c>> () : rulesByStep;
					for (String step : rule.EnrollmentFunnelStep__c.split(';'))
					{
						List<EnrollmentRule__c> rules = rulesByStep.get(step);
						rules = rules == null ? new List<EnrollmentRule__c> () : rules;
						rules.add(rule);
						rulesByStep.put(step, rules);
					}
					ruleMapByOutreach.put(outreachType, rulesByStep);
				}
				ruleMapByGroup.put(outreachGroup, ruleMapByOutreach);
			}
			result.put(rule.EnrollmentActionType__c, ruleMapByGroup);
		}
		return result;
	}

	public static Map<String, Map<Id, List<EnrollmentAction__c>>> getAllStepActions(Id[] enrollmentIds) {

		Map<String, Map<Id, List<EnrollmentAction__c>>> result = new Map<String, Map<Id, List<EnrollmentAction__c>>> ();
		if (enrollmentIds != null && !enrollmentIds.isEmpty())
		{
			for (EnrollmentAction__c action : (List<EnrollmentAction__c>) Database.query(
												'Select ' + String.join(enrollmentActionFields, ', ') + ' From EnrollmentAction__c '
												+ 'Where Enrollment__c IN :enrollmentIds '
												+ 'And RuleId__c != null '
												+ 'And Type__c IN (\'Onboarding Step\', \'Outreach Attempt\') '
												+ 'order by CreatedDate '
											))
			{
				Map<Id, List<EnrollmentAction__c>> actionsByEnrollment = result.get(action.Type__c);
				actionsByEnrollment = actionsByEnrollment == null ? new Map<Id, List<EnrollmentAction__c>> () : actionsByEnrollment;
				List<EnrollmentAction__c> actions = actionsByEnrollment.get(action.Enrollment__c);
				actions = actions == null ? new List<EnrollmentAction__c> () : actions;
				actions.add(action);
				actionsByEnrollment.put(action.Enrollment__c, actions);
				result.put(action.Type__c, actionsByEnrollment);
			}
		}
		return result;
	}

	public static EnrollmentItem[] getOnboardingSteps(EnrollmentRule__c[] stepRules, EnrollmentAction__c[] stepActions) {

		EnrollmentItem[] result = new EnrollmentItem[0];
		Map<String, EnrollmentItem> itemsByName = new Map<String, EnrollmentItem> ();
		Map<Id, EnrollmentItem> itemsByRule = new Map<Id, EnrollmentItem> ();
		if (stepRules != null)
		{
			for (EnrollmentRule__c rule : stepRules)
			{
				EnrollmentItem item = itemsByName.get(rule.Name);
				item = item == null ? new EnrollmentItem () : item;
				item.addRule(rule);
				itemsByRule.put(rule.Id, item);
				if (!itemsByName.containsKey(rule.Name))
				{
					result.add(item);
				}
				itemsByName.put(rule.Name, item);
			}
			if (!result.isEmpty() && stepActions != null)
			{
				for (EnrollmentAction__c action : stepActions)
				{
					if (itemsByRule.containsKey(action.RuleId__c))
					{
						EnrollmentItem item = itemsByRule.get(action.RuleId__c);
						item.addAction(action);
						EnrollmentRule__c completedRule = item.completedRule;
						if (completedRule != null)
						{
							for (EnrollmentItem dependentItem : result)
							{
								if (String.isNotBlank(dependentItem.prereqRuleName) && dependentItem.prereqRuleName.equalsIgnoreCase(completedRule.Name))
								{
									if (String.isBlank(dependentItem.prereqRuleOutcome) || (String.isNotBlank(dependentItem.prereqRuleOutcome) && dependentItem.prereqRuleOutcome.equalsIgnoreCase(completedRule.EnrollmentActionOutcome__c)))
									{
										dependentItem.showItem = true;
									}
								}
							}
						}
					}
				}
			}
		}
		return result;
	}

	public static List<Enrollment__c> handleEnrollmentUpdate(List<Id> enrollmentIds) {

		Enrollment__c[] enrollments = getEnrollments(enrollmentIds);
		Map<Id, EnrollmentRule__c> ruleByEnrollmentId = new Map<Id, EnrollmentRule__c> ();
		Map<String, Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>>> allStepRules = getAllStepRules();
		Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> allOnboardingStepRules = allStepRules.containsKey('Onboarding Step') ? allStepRules.get('Onboarding Step') : new Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> ();
		Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> allOutreachAttemptRules = allStepRules.containsKey('Outreach Attempt') ? allStepRules.get('Outreach Attempt') : new Map<String, Map<String, Map<String, List<EnrollmentRule__c>>>> ();
		Map<String, Map<Id, List<EnrollmentAction__c>>> allStepActions = getAllStepActions(enrollmentIds);
		Map<Id, List<EnrollmentAction__c>> allOnboardingStepActions = allStepActions.containsKey('Onboarding Step') ? allStepActions.get('Onboarding Step') : new Map<Id, List<EnrollmentAction__c>> ();
		Map<Id, List<EnrollmentAction__c>> allOutreachAttemptActions = allStepActions.containsKey('Outreach Attempt') ? allStepActions.get('Outreach Attempt') : new Map<Id, List<EnrollmentAction__c>> ();

		for (Enrollment__c enrollment : enrollments)
		{
			EnrollmentRule__c rule;
			EnrollmentAction__c[] onboardingStepActions = allOnboardingStepActions.get(enrollment.Id);
			EnrollmentAction__c[] outreachAttemptActions = allOutreachAttemptActions.get(enrollment.Id);
			Map<String, Map<String, List<EnrollmentRule__c>>> onboardingStepRulesByOutreach = allOnboardingStepRules.containsKey(enrollment.outreach_group__c) ? allOnboardingStepRules.get(enrollment.outreach_group__c) : new Map<String, Map<String, List<EnrollmentRule__c>>> ();
			Map<String, Map<String, List<EnrollmentRule__c>>> outreachAttemptRulesByOutreach = allOutreachAttemptRules.containsKey(enrollment.outreach_group__c) ? allOutreachAttemptRules.get(enrollment.outreach_group__c) : new Map<String, Map<String, List<EnrollmentRule__c>>> ();
			Map<String, List<EnrollmentRule__c>> onboardingStepRulesByStep = onboardingStepRulesByOutreach.containsKey(enrollment.outreach_type__c) ? onboardingStepRulesByOutreach.get(enrollment.outreach_type__c) : new Map<String, List<EnrollmentRule__c>> ();
			Map<String, List<EnrollmentRule__c>> outreachAttemptRulesByStep = outreachAttemptRulesByOutreach.containsKey(enrollment.outreach_type__c) ? outreachAttemptRulesByOutreach.get(enrollment.outreach_type__c) : new Map<String, List<EnrollmentRule__c>> ();
			String formerStep = '';
			ProEnrollmentUtility.outreachType = enrollment.outreach_type__c;
			String currentStep = funnelStepSettings[0].MasterLabel;
			if (String.isNotBlank(enrollment.FunnelStep__c) && milestoneFunnelSteps.contains(enrollment.FunnelStep__c))
			{
				currentStep = enrollment.FunnelStep__c;
			}
			while (formerStep != currentStep)
			{
				formerStep = currentStep;
				EnrollmentRule__c outreachRule = determineRuleFromOutreachAttempt(outreachAttemptRulesByStep.get(currentStep), outreachAttemptActions);
				if (outreachRule != null && String.isNotBlank(outreachRule.SetEnrollmentUnsuccessfulReasonTo__c))
				{
					rule = outreachRule;
					break;
				}
				EnrollmentRule__c stepRule = determineRuleFromCompletedSteps(onboardingStepRulesByStep.get(currentStep), onboardingStepActions);
				if (stepRule != null && String.isNotBlank(stepRule.SetEnrollmentUnsuccessfulReasonTo__c))
				{
					rule = stepRule;
					break;
				}
				Integer outreachOrder = 0;
				Integer stepOrder = 0;
				Integer currentOrder = funnelStepOrderMap.get(currentStep);
				if (outreachRule != null && funnelStepOrderMap.containsKey(outreachRule.SetEnrollmentFunnelStepTo__c))
				{
					outreachOrder = funnelStepOrderMap.get(outreachRule.SetEnrollmentFunnelStepTo__c);
				}
				if (stepRule != null && funnelStepOrderMap.containsKey(stepRule.SetEnrollmentFunnelStepTo__c))
				{
					stepOrder = funnelStepOrderMap.get(stepRule.SetEnrollmentFunnelStepTo__c);
				}
				if (outreachOrder > currentOrder || stepOrder > currentOrder)
				{
					if (outreachOrder >= stepOrder && outreachOrder != 0)
					{
						rule = outreachRule;
						currentStep = outreachRule.SetEnrollmentFunnelStepTo__c;
					} else if (stepOrder != 0)
					{
						rule = stepRule;
						currentStep = stepRule.SetEnrollmentFunnelStepTo__c;
					}
				}
			}

			if (rule == null)
			{
				rule = new EnrollmentRule__c (
					SetEnrollmentUnsuccessfulReasonTo__c = '',
					SetEnrollmentFunnelStepTo__c = milestoneFunnelSteps.contains(enrollment.FunnelStep__c) ? enrollment.FunnelStep__c : funnelStepSettings[0].MasterLabel
				);
			}
			ruleByEnrollmentId.put(enrollment.Id, rule);
		}
		return updateEnrollmentFromRule(enrollments, ruleByEnrollmentId);
	}

	public static EnrollmentRule__c determineRuleFromOutreachAttempt(List<EnrollmentRule__c> rules, List<EnrollmentAction__c> actions) {

		EnrollmentRule__c rule;
		if (rules != null) {

			Map<Id, EnrollmentRule__c> ruleMap = new Map<Id, EnrollmentRule__c> (rules);
			if (actions != null) {

				for (EnrollmentAction__c action : actions) {

					if (ruleMap.containsKey(action.RuleId__c)) {

						rule = ruleMap.get(action.RuleId__c);

					}
					EnrollmentRule__c newRule = ruleMap.get(action.RuleId__c);
					Integer ruleOrder = 0;
					Integer newRuleOrder = 0;
					if (newRule != null && String.isNotBlank(newRule.SetEnrollmentUnsuccessfulReasonTo__c)) {

						rule = newRule;
						break;

					} else {

						if (rule != null && funnelStepOrderMap.containsKey(rule.SetEnrollmentFunnelStepTo__c)) {

							ruleOrder = funnelStepOrderMap.get(rule.SetEnrollmentFunnelStepTo__c);

						}
						if (newRule != null && funnelStepOrderMap.containsKey(newRule.SetEnrollmentFunnelStepTo__c)) {

							newRuleOrder = funnelStepOrderMap.get(newRule.SetEnrollmentFunnelStepTo__c);

						}
						if (newRuleOrder >= ruleOrder && newRuleOrder != 0) {

							rule = newRule;

						}

					}

				}

			}

		}
		return rule;

	}

	public static EnrollmentRule__c determineRuleFromCompletedSteps(List<EnrollmentRule__c> stepRules, List<EnrollmentAction__c> stepActions) {

		EnrollmentRule__c rule;
		List<EnrollmentItem> items = getOnboardingSteps(stepRules, stepActions);
		EnrollmentRule__c latestCompleteAutonomousRule;
		EnrollmentRule__c latestCompleteGroupedRule;
		Boolean allGroupedStepsComplete = true;
		for (EnrollmentItem item : items) {

			if (item.isAutonomous) {

				if (item.action != null) {

					latestCompleteAutonomousRule = item.completedRule;

				}

			} else if (item.action != null) {

				latestCompleteGroupedRule = item.completedRule;

			} else if (!item.isRequiredBasedOnPrereqs || (item.isRequiredBasedOnPrereqs && item.showItem)) {

				allGroupedStepsComplete = false;

			}

		}
		if (latestCompleteAutonomousRule != null) {

			rule = latestCompleteAutonomousRule;

		} else if (allGroupedStepsComplete) {

			rule = latestCompleteGroupedRule;

		}
		return rule;

	}

	public static List<Enrollment__c> updateEnrollmentFromRule(List<Enrollment__c> enrollments, Map<Id, EnrollmentRule__c> ruleByEnrollment) {

		if (enrollments != null && ruleByEnrollment != null) {

			for (Enrollment__c enrollment : enrollments) {

				if (ruleByEnrollment.containsKey(enrollment.Id)) {

					EnrollmentRule__c rule = ruleByEnrollment.get(enrollment.Id);
					for (String ruleFieldName : ruleToEnrollmentFieldMapping.keySet()) {

						String enrollmentFieldName = ruleToEnrollmentFieldMapping.get(ruleFieldName);
						String ruleFieldValue = (String) rule.get(ruleFieldName);
						if (String.isNotBlank(ruleFieldValue) || ruleFieldName.equalsIgnoreCase('SetEnrollmentUnsuccessfulReasonTo__c')) {

							enrollment.put(enrollmentFieldName, ruleFieldValue);

						}

					}

				}

			}
			update enrollments;

		}
		return enrollments;

	}

	public static void populateMarketCategory() {

		List<Market__c> marketsMissingCats = [Select Id, RequestCategory__c, rca_request_category_id__c From Market__c Where RequestCategory__c = null And rca_request_category_id__c != null limit 50000];
		if (!marketsMissingCats.isEmpty()) {

			List<String> catIds = new List<String> ();
			for (Market__c market : marketsMissingCats) {

				catIds.add(market.rca_request_category_id__c);

			}
			if (!catIds.isEmpty()) {

				Map<String, Id> catMap = new Map<String, Id> ();
				for (RequestCategory__c cat : [Select Id, rca_request_category_id__c From RequestCategory__c Where rca_request_category_id__c IN :catIds]) {

					catMap.put(cat.rca_request_category_id__c, cat.Id);

				}
				for (Market__c market : marketsMissingCats) {

					market.RequestCategory__c = catMap.get(market.rca_request_category_id__c);

				}

			}
			update marketsMissingCats;

		}

	}

}