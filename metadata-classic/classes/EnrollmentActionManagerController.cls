public with sharing class EnrollmentActionManagerController {

	@AuraEnabled
	public static List<String> getFunnelSteps(Id enrollmentId)
	{
		List<String> result = new List<String>();
		List<Enrollment__c> enrollments = [SELECT outreach_type__c FROM Enrollment__c WHERE Id = :enrollmentId];

		if (!enrollments.isEmpty() && enrollments[0].outreach_type__c != null)
		{
			ProEnrollmentUtility.outreachType = enrollments[0].outreach_type__c;

			for (FunnelStepSetting__mdt setting : ProEnrollmentUtility.funnelStepSettings)
			{
				result.add(setting.MasterLabel);
			}
		}

		return result;
	}

	@AuraEnabled
	public static String getFunnelStepEndpoint(Id enrollmentId) {

		String result;
		if (enrollmentId != null) {

			Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(enrollmentId);
			if (String.isNotBlank(enrollment.Market__r.RequestCategory__r.outreach_type__c)) {

				String outreachType = enrollment.Market__r.RequestCategory__r.outreach_type__c.toLowerCase();
				List<OutreachTypeSetting__mdt> settings = [Select FunnelStepEndpoint__c From OutreachTypeSetting__mdt Where MasterLabel = :outreachType And FunnelStepEndpoint__c != null];
				if (!settings.isEmpty()) {

					result = settings[0].FunnelStepEndpoint__c;

				}

			}

		}
		return result;

	}

	@AuraEnabled
	public static Id getProContact(Id accountId) {

		Id result;
		if (accountId != null) {

			Contact con = [Select Id From Contact Where AccountId = :accountId limit 1];
			result = con.Id;

		}
		return result;

	}

	@AuraEnabled
	public static List<EnrollmentAction__c> getFeedItems(Id enrollmentId) {

		List<EnrollmentAction__c> result = new List<EnrollmentAction__c> ();
		if (enrollmentId != null) {

			result = (List<EnrollmentAction__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
				+ 'Where Enrollment__c = :enrollmentId '
				+ 'And Type__c = \'Outreach Attempt\' '
				+ 'order by CompletedOn__c desc '
			);

		}
		return result;

	}

	@AuraEnabled
	public static List<User> searchUsers(String searchText) {

		List<User> result = new List<User> ();
		if (String.isNotBlank(searchText)) {
        //Added ProServices user roles - MP -7/27
			List<String> roleDeveloperNames = new List<String> {
				'ProServicesManaging_User', 'ProServicesFrontLineUser', 'SAM_Frontline_User' ,'SAM_Managing_User'
			}; 
			String fuzzySearchText = '%' + searchText + '%';
			result = [Select Id, Name From User 
						Where Name LIKE :fuzzySearchText
						And UserRole.DeveloperName IN :roleDeveloperNames
						order by Name];

		}
		return result;

	}

	@AuraEnabled
	public static Enrollment__c getEnrollment(Id enrollmentId) {

		return ProEnrollmentUtility.getEnrollment(enrollmentId);

	}

	@AuraEnabled
	public static EnrollmentAction__c createEnrollmentAction(EnrollmentAction__c action, String callbackDate, String callbackTime, String callbackOwner) {

		Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(action.Enrollment__c);
		action.OutreachGroup__c = enrollment.outreach_group__c;
		Account acc = new Account (
			Id = enrollment.Account__c,
			LastEnrollmentOutreachAttempt__c = System.now()
		);
		if (String.isNotBlank(callbackDate) && String.isNotBlank(callbackTime) && String.isNotBlank(callbackOwner)) {

			List<String> dateArray = callbackDate.split('/');
			List<String> timeArray = callbackTime.split(':');
			action.CallbackDateTime__c = Datetime.newInstance(
				Integer.valueOf(dateArray[2]), 
				Integer.valueOf(dateArray[0]), 
				Integer.valueOf(dateArray[1]), 
				Integer.valueOf(timeArray[0]), 
				Integer.valueOf(timeArray[1]), 0
			);
			if (callbackOwner.equalsIgnoreCase('Myself')) {

				action.CallbackAssignedTo__c = UserInfo.getUserId();

			} else if (callbackOwner instanceof Id) {

				action.CallbackAssignedTo__c = callbackOwner;

			}
			acc.EnrollmentAssignedTo__c = action.CallbackAssignedTo__c;
			acc.EnrollmentCallbackDateTime__c = action.CallbackDateTime__c;
			acc.EnrollmentCallbackOrigin__c = 'Agent Scheduled';
			acc.EnrollmentCallbackScheduledBy__c = UserInfo.getUserId();
			if (String.isNotBlank(action.CallbackPhone__c)) {

				acc.EnrollmentCallbackPhone__c = action.CallbackPhone__c;

			}

		}
		update acc;
		return ProEnrollmentUtility.createEnrollmentAction(action);

	}

	@AuraEnabled
	public static List<EnrollmentItem> getPrevOnboardingSteps(Id enrollmentId, List<String> funnelSteps, String outreachType, String outreachGroup) {

		List<EnrollmentItem> result = new List<EnrollmentItem> ();
		if (enrollmentId != null && funnelSteps != null && !funnelSteps.isEmpty() && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(enrollmentId);
			Map<String, List<EnrollmentRule__c>> ruleMap = getStepRulesByFunnelStep(funnelSteps, outreachType, outreachGroup, enrollment.Account__r.EnrollmentCallbackDateTime__c != null);
			Map<Id, EnrollmentAction__c> actionMap = getStepActionsByRuleId(enrollmentId);
			Map<String, EnrollmentItem> itemsByNameMasterMap = new Map<String, EnrollmentItem> ();
			for (String funnelStep : funnelSteps) {

				if (ruleMap.containsKey(funnelStep)) {

					Map<String, EnrollmentItem> itemsByName = new Map<String, EnrollmentItem> ();
					List<String> ruleIds = new List<String> ();
					List<EnrollmentItem> funnelStepItems = new List<EnrollmentItem> ();
					for (EnrollmentRule__c rule : ruleMap.get(funnelStep)) {

						if (!itemsByNameMasterMap.containsKey(rule.Name)) {

							EnrollmentItem item = itemsByName.get(rule.Name);
							item = item == null ? new EnrollmentItem () : item;
							item.addRule(rule);
							if (actionMap.containsKey(rule.Id)) {

								item.addAction(actionMap.get(rule.Id));

							}
							if (!itemsByName.containsKey(rule.Name)) {

								funnelStepItems.add(item);

							}
							itemsByName.put(rule.Name, item);

						}

					}
					itemsByNameMasterMap.putAll(itemsByName);
					result.addAll(funnelStepItems);

				}

			}
			if (!result.isEmpty()) {

				for (EnrollmentItem item : result) {

					EnrollmentRule__c completedRule = item.completedRule;
					if (completedRule != null) {

						for (EnrollmentItem dependentItem : result) {

							if (item.name != dependentItem.name && String.isNotBlank(dependentItem.prereqRuleName) && dependentItem.prereqRuleName.equalsIgnoreCase(completedRule.Name)) {

								if (String.isBlank(dependentItem.prereqRuleOutcome) || (String.isNotBlank(dependentItem.prereqRuleOutcome) && dependentItem.prereqRuleOutcome.equalsIgnoreCase(completedRule.EnrollmentActionOutcome__c))) {

									dependentItem.showItem = true;

								}

							}

						}

					}

				}

			}

		}
		return result;

	}

	@AuraEnabled
	public static List<EnrollmentItem> getOnboardingSteps(Id enrollmentId, String funnelStep, String outreachType, String outreachGroup) {

		List<EnrollmentItem> result = new List<EnrollmentItem> ();
		Map<String, EnrollmentItem> itemsByName = new Map<String, EnrollmentItem> ();
		Map<Id, EnrollmentItem> itemsByRule = new Map<Id, EnrollmentItem> ();
		List<String> ruleIds = new List<String> ();
		if (enrollmentId != null && String.isNotBlank(funnelStep) && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(enrollmentId);
			ProEnrollmentUtility.outreachType = enrollment.outreach_type__c;

			for (EnrollmentRule__c rule : getStepRules(funnelStep, outreachType, outreachGroup, enrollment.Account__r.EnrollmentCallbackDateTime__c != null)) {

				EnrollmentItem item = itemsByName.get(rule.Name);
				item = item == null ? new EnrollmentItem (enrollment) : item;
				item.addRule(rule);
				itemsByRule.put(rule.Id, item);
				ruleIds.add(rule.Id);
				if (!itemsByName.containsKey(rule.Name)) {

					result.add(item);

				}
				itemsByName.put(rule.Name, item);

			}
			if (!result.isEmpty()) {

				for (EnrollmentAction__c action : getStepActions(enrollmentId, ruleIds)) {

					if (itemsByRule.containsKey(action.RuleId__c)) {

						EnrollmentItem item = itemsByRule.get(action.RuleId__c);
						item.addAction(action);
						EnrollmentRule__c completedRule = item.completedRule;
						if (completedRule != null) {

							for (EnrollmentItem dependentItem : result) {

								if (String.isNotBlank(dependentItem.prereqRuleName) && dependentItem.prereqRuleName.equalsIgnoreCase(completedRule.Name)) {

									if (String.isBlank(dependentItem.prereqRuleOutcome) || (String.isNotBlank(dependentItem.prereqRuleOutcome) && dependentItem.prereqRuleOutcome.equalsIgnoreCase(completedRule.EnrollmentActionOutcome__c))) {

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

	private static List<EnrollmentRule__c> getStepRules(String funnelStep, String outreachType, String outreachGroup, Boolean hasCallback) {

		List<EnrollmentRule__c> result = new List<EnrollmentRule__c> ();
		if (String.isNotBlank(funnelStep) && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			result = (List<EnrollmentRule__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentRuleFields(), ', ') + ' From EnrollmentRule__c '
				+ 'Where EnrollmentFunnelStep__c includes (:funnelStep) '
				+ 'And EnrollmentOutreachType__c includes (:outreachType) '
				+ 'And EnrollmentOutreachGroup__c includes (:outreachGroup) '
				+ 'And IsActive__c = true '
				+ 'And EnrollmentActionType__c = \'Onboarding Step\' '
				+ (hasCallback ? '' : 'And IsCallbackRule__c = false ')
				+ 'order by EnrollmentActionOrder__c '
			);

		}
		return result;

	}

	private static Map<String, List<EnrollmentRule__c>> getStepRulesByFunnelStep(List<String> funnelSteps, String outreachType, String outreachGroup, Boolean hasCallback) {

		Map<String, List<EnrollmentRule__c>> result = new Map<String, List<EnrollmentRule__c>> ();
		if (funnelSteps != null && !funnelSteps.isEmpty() && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			String funnelStepCriteria = '\'' + String.join(funnelSteps, '\',\'') + '\'';

			for (EnrollmentRule__c rule : (List<EnrollmentRule__c>) Database.query(
									'Select ' + String.join(ProEnrollmentUtility.getEnrollmentRuleFields(), ', ') + ' From EnrollmentRule__c '
									+ 'Where EnrollmentFunnelStep__c includes (' + funnelStepCriteria + ') '
									+ 'And EnrollmentOutreachType__c includes (:outreachType) '
									+ 'And EnrollmentOutreachGroup__c includes (:outreachGroup) '
									+ 'And IsActive__c = true '
									+ 'And EnrollmentActionType__c = \'Onboarding Step\' '
									+ (hasCallback ? '' : 'And IsCallbackRule__c = false ')
									+ 'order by EnrollmentActionOrder__c '
								)) {

				for (String step : rule.EnrollmentFunnelStep__c.split(';')) {

					List<EnrollmentRule__c> rules = result.get(step);
					rules = rules == null ? new List<EnrollmentRule__c> () : rules;
					rules.add(rule);
					result.put(step, rules);

				}

			}

		}
		return result;

	}

	private static List<EnrollmentAction__c> getStepActions(Id enrollmentId, List<String> ruleIds) {

		List<EnrollmentAction__c> result = new List<EnrollmentAction__c> ();
		if (enrollmentId != null && ruleIds != null && !ruleIds.isEmpty()) {

			result = (List<EnrollmentAction__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
				+ 'Where Enrollment__c = :enrollmentId '
				+ 'And RuleId__c IN :ruleIds '
				+ 'And Type__c = \'Onboarding Step\' '
				+ 'order by CreatedDate '
			);

		}
		return result;

	}

	private static Map<Id, EnrollmentAction__c> getStepActionsByRuleId(Id enrollmentId) {

		Map<Id, EnrollmentAction__c> result = new Map<Id, EnrollmentAction__c> ();
		if (enrollmentId != null) {

			for (EnrollmentAction__c action : (List<EnrollmentAction__c>) Database.query(
									'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
									+ 'Where Enrollment__c = :enrollmentId '
									+ 'And Type__c = \'Onboarding Step\' '
									+ 'order by CreatedDate '
								)) {

				result.put(action.RuleId__c, action);

			}

		}
		return result;

	}

	@AuraEnabled
	public static List<EnrollmentRule__c> getOutreachDispositions(String funnelStep, String outreachType, String outreachGroup) {

		List<EnrollmentRule__c> result = new List<EnrollmentRule__c> ();
		if (String.isNotBlank(funnelStep) && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			result = (List<EnrollmentRule__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentRuleFields(), ', ') + ' From EnrollmentRule__c '
				+ 'Where EnrollmentFunnelStep__c includes (:funnelStep) '
				+ 'And EnrollmentOutreachType__c includes (:outreachType) '
				+ 'And EnrollmentOutreachGroup__c includes (:outreachGroup) '
				+ 'And IsActive__c = true '
				+ 'And EnrollmentActionType__c = \'Outreach Attempt\' '
				+ 'order by EnrollmentActionOrder__c '
			);

		}
		return result;

	}

	@AuraEnabled
	public static List<EnrollmentAction__c> getOutreachHistory(Id enrollmentId) {

		List<EnrollmentAction__c> result = new List<EnrollmentAction__c> ();
		if (enrollmentId != null) {

			result = (List<EnrollmentAction__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
				+ 'Where Enrollment__c = :enrollmentId '
				+ 'And Type__c = \'Outreach Attempt\' '
				+ 'order by CreatedDate '
			);

		}
		return result;

	}

	private static Enrollment__c updateEnrollmentFromRule(Id enrollmentId, EnrollmentRule__c rule) {

		Enrollment__c enrollment;
		if (enrollmentId != null && rule != null) {

			enrollment = (Enrollment__c) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentFields(), ', ') + ' From Enrollment__c Where Id = :enrollmentId '
			);
			for (String ruleFieldName : ProEnrollmentUtility.getRuleToEnrollmentFieldMapping().keySet()) {

				String enrollmentFieldName = ProEnrollmentUtility.getRuleToEnrollmentFieldMapping().get(ruleFieldName);
				String ruleFieldValue = (String) rule.get(ruleFieldName);
				if (String.isNotBlank(ruleFieldValue) || ruleFieldName.equalsIgnoreCase('SetEnrollmentUnsuccessfulReasonTo__c')) {

					enrollment.put(enrollmentFieldName, ruleFieldValue);

				}

			}
			update enrollment;

		}
		return enrollment;

	}

	@AuraEnabled
	public static Enrollment__c handleEnrollmentUpdate(Id enrollmentId, String outreachType, String outreachGroup) {

		Enrollment__c enrollment = ProEnrollmentUtility.getEnrollment(enrollmentId);
		EnrollmentRule__c rule;
		String formerStep = '';
		ProEnrollmentUtility.outreachType = enrollment.outreach_type__c;
		String currentStep = ProEnrollmentUtility.funnelStepSettings[0].MasterLabel;

		if (String.isNotBlank(enrollment.FunnelStep__c) && ProEnrollmentUtility.milestoneFunnelSteps.contains(enrollment.FunnelStep__c)) {

			currentStep = enrollment.FunnelStep__c;
		}
		while (formerStep != currentStep) {
			formerStep = currentStep;
			EnrollmentRule__c outreachRule = determineRuleFromOutreachAttempt(enrollmentId, currentStep, outreachType, outreachGroup);
			if (outreachRule != null && String.isNotBlank(outreachRule.SetEnrollmentUnsuccessfulReasonTo__c)) {

				rule = outreachRule;
				break;

			}
			EnrollmentRule__c stepRule = determineRuleFromCompletedSteps(enrollmentId, currentStep, outreachType, outreachGroup);
			if (stepRule != null && String.isNotBlank(stepRule.SetEnrollmentUnsuccessfulReasonTo__c)) {

				rule = stepRule;
				break;

			}
			Integer outreachOrder = 0;
			Integer stepOrder = 0;
			Integer currentOrder = ProEnrollmentUtility.funnelStepOrderMap.get(currentStep);
			if (outreachRule != null && ProEnrollmentUtility.funnelStepOrderMap.containsKey(outreachRule.SetEnrollmentFunnelStepTo__c)) {

				outreachOrder = ProEnrollmentUtility.funnelStepOrderMap.get(outreachRule.SetEnrollmentFunnelStepTo__c);

			}
			if (stepRule != null && ProEnrollmentUtility.funnelStepOrderMap.containsKey(stepRule.SetEnrollmentFunnelStepTo__c)) {

				stepOrder = ProEnrollmentUtility.funnelStepOrderMap.get(stepRule.SetEnrollmentFunnelStepTo__c);

			}
			if (outreachOrder > currentOrder || stepOrder > currentOrder) {

				if (outreachOrder >= stepOrder && outreachOrder != 0) {

					rule = outreachRule;
					currentStep = outreachRule.SetEnrollmentFunnelStepTo__c;

				} else if (stepOrder != 0) {

					rule = stepRule;
					currentStep = stepRule.SetEnrollmentFunnelStepTo__c;
				}

			}

		}
		if (rule == null) {

			rule = new EnrollmentRule__c (
				SetEnrollmentUnsuccessfulReasonTo__c = '',
				SetEnrollmentFunnelStepTo__c = ProEnrollmentUtility.milestoneFunnelSteps.contains(enrollment.FunnelStep__c) ? enrollment.FunnelStep__c : ProEnrollmentUtility.funnelStepSettings[0].MasterLabel
			);

		}
		return updateEnrollmentFromRule(enrollmentId, rule);

	}

	private static EnrollmentRule__c determineRuleFromOutreachAttempt(Id enrollmentId, String funnelStep, String outreachType, String outreachGroup) {

		EnrollmentRule__c rule;
		if (enrollmentId != null && String.isNotBlank(funnelStep) && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {
			ProEnrollmentUtility.outreachType = outreachType;
			List<String> ruleIds = new List<String> ();
			Map<Id, EnrollmentRule__c> ruleMap = new Map<Id, EnrollmentRule__c> ();
			for (EnrollmentRule__c outreachRule : getOutreachDispositions(funnelStep, outreachType, outreachGroup)) {

				ruleIds.add(String.valueOf(outreachRule.Id));
				ruleMap.put(outreachRule.Id, outreachRule);

			}
			List<EnrollmentAction__c> actions = (List<EnrollmentAction__c>) Database.query(
				'Select ' + String.join(ProEnrollmentUtility.getEnrollmentActionFields(), ', ') + ' From EnrollmentAction__c '
				+ 'Where RuleId__c IN :ruleIds '
				+ 'And Enrollment__c = :enrollmentId '
				+ 'order by CreatedDate '
			);
			for (EnrollmentAction__c action : actions) {

				EnrollmentRule__c newRule = ruleMap.get(action.RuleId__c);
				Integer ruleOrder = 0;
				Integer newRuleOrder = 0;
				if (newRule != null && String.isNotBlank(newRule.SetEnrollmentUnsuccessfulReasonTo__c)) {

					rule = newRule;
					break;

				} else {

					if (rule != null && ProEnrollmentUtility.funnelStepOrderMap.containsKey(rule.SetEnrollmentFunnelStepTo__c)) {

						ruleOrder = ProEnrollmentUtility.funnelStepOrderMap.get(rule.SetEnrollmentFunnelStepTo__c);

					}
					if (newRule != null && ProEnrollmentUtility.funnelStepOrderMap.containsKey(newRule.SetEnrollmentFunnelStepTo__c)) {

						newRuleOrder = ProEnrollmentUtility.funnelStepOrderMap.get(newRule.SetEnrollmentFunnelStepTo__c);

					}
					if (newRuleOrder >= ruleOrder && newRuleOrder != 0) {

						rule = newRule;

					}

				}

			}

		}
		return rule;

	}

	private static EnrollmentRule__c determineRuleFromCompletedSteps(Id enrollmentId, String funnelStep, String outreachType, String outreachGroup) {

		EnrollmentRule__c rule;
		if (enrollmentId != null && String.isNotBlank(funnelStep) && String.isNotBlank(outreachType) && String.isNotBlank(outreachGroup)) {

			List<EnrollmentItem> items = getOnboardingSteps(enrollmentId, funnelStep, outreachType, outreachGroup);
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

		}
		return rule;

	}

}