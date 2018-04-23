({
	checkForSurvey: function(component, rule) {
		var showSurvey = false;
		if (!$A.util.isEmpty(rule) && !$A.util.isEmpty(rule.ShowSurveyForOutreachType__c)) {
			var outreachType = component.get('v.outreachType');
			var outreachTypes = rule.ShowSurveyForOutreachType__c.split(';');
			for (var i in outreachTypes) {
				if (outreachTypes[i] == outreachType) {
					showSurvey = true;
					break;
				}
			}
		}
		component.set('v.showSurvey', showSurvey);
		return showSurvey;
	},
	getRuleFromOutcomeAndDetail: function(component, item, checkForSurvey) {
		var rule;
		if (!$A.util.isEmpty(item)) {
			var outcome = component.get('v.outcome');
			if (!$A.util.isEmpty(outcome)) {
				var outcomeRules = item.rulesByOutcome[outcome];
				if (outcomeRules.length == 1) {
					rule = outcomeRules[0];
				} else {
					var detail = component.get('v.detail');
					rule = item.rulesByDetail[detail];
				}
			}
		}
		if (checkForSurvey) {
			this.checkForSurvey(component, rule);
		}
		return rule;
	},
	changeOutcome: function(component) {
		var outcome = component.get('v.outcome');
		var details = null;
		var showDetails = false;
		component.set('v.detail', '');
		var item = component.get('v.item');
		if (!$A.util.isEmpty(outcome)) {
			if (!$A.util.isEmpty(item.detailsByOutcome)) {
				details = item.detailsByOutcome[outcome];
				showDetails = !$A.util.isEmpty(details);
			}
		}
		component.set('v.detailOptions', details);
		component.set('v.showDetails', showDetails);
		this.getRuleFromOutcomeAndDetail(component, item, true);
	},
	createEnrollmentAction : function(component) {
		var enrollmentAction = {
			sobjectType: 'EnrollmentAction__c',
			Type__c: 'Onboarding Step',
			Enrollment__c: component.get('v.enrollmentId')
		};
		var item = component.get('v.item');
		var existingAction = component.get('v.enrollmentAction');
		var oldRuleOutcome;
		if (!$A.util.isEmpty(existingAction)) {
			enrollmentAction.Id = existingAction.Id;
			oldRuleOutcome = item.completedRule.EnrollmentActionOutcome__c;
		}
		if (item.isURLRequired) {
			enrollmentAction.URL__c = component.get('v.url');
		}
		if ($A.util.isEmpty(item.onlyRule)) {
			var rule = this.getRuleFromOutcomeAndDetail(component, item);
			if (!$A.util.isEmpty(rule)) {
				enrollmentAction.Name = rule.Name;
				enrollmentAction.RuleId__c = rule.Id;
				enrollmentAction.Details__c = rule.Details__c;
				enrollmentAction.Outcome__c = rule.EnrollmentActionOutcome__c;
				enrollmentAction.CallbackOutreachType__c = rule.SetEnrollmentCallbackOutreachTypeTo__c;
				item.completedRule = rule;
			}
		} else {
			enrollmentAction.Name = item.onlyRule.Name;
			enrollmentAction.RuleId__c = item.onlyRule.Id;
			enrollmentAction.Outcome__c = item.onlyRule.EnrollmentActionOutcome__c;
			enrollmentAction.CallbackOutreachType__c = item.onlyRule.SetEnrollmentCallbackOutreachTypeTo__c;
			item.completedRule = item.onlyRule;
		}
		var ruleName = item.completedRule.Name;
		var ruleOutcome = item.completedRule.EnrollmentActionOutcome__c;
		var isCallbackRule = item.completedRule.IsCallbackRule__c;
		component.set('v.item', item);
		var action = component.get('c.createEnrollmentAction');
		action.setParams({
			action: enrollmentAction,
			isCallbackRule: isCallbackRule
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var result = response.getReturnValue();
				component.set('v.enrollmentAction', result);
				component.set('v.showCheck', true);
				this.resetModal(component);
				this.fireEnrollmentActionModifiedEvent(component, ruleName, ruleOutcome, true, oldRuleOutcome);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	deleteEnrollmentAction: function(component) {
		var enrollmentAction = component.get('v.enrollmentAction');
		var item = component.get('v.item');
		var ruleName = item.completedRule.Name;
		var ruleOutcome = item.completedRule.EnrollmentActionOutcome__c;
		var action = component.get('c.deleteEnrollmentAction');
		action.setParams({
			actionId: enrollmentAction.Id
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.enrollmentAction', null);
				this.fireEnrollmentActionModifiedEvent(component, ruleName, ruleOutcome, false);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	fireEnrollmentActionModifiedEvent: function(component, ruleName, ruleOutcome, completed, oldRuleOutcome) {
		var enrollmentId = component.get('v.enrollmentId');
		var item = component.get('v.item');
		var appEvent = $A.get('e.c:EnrollmentActionModified');
		appEvent.setParams({
			enrollmentId: enrollmentId,
			ruleName: ruleName,
			ruleOutcome: ruleOutcome,
			completed: completed,
			oldRuleOutcome: oldRuleOutcome
		});
		appEvent.fire();
	},
	resetModal: function(component) {
		component.set('v.showModal', false);
		component.set('v.showDetails', false);
		component.set('v.showSurvey', false);
		// component.set('v.outcome', '');
		// component.set('v.detail', '');
	},
	handleCheck: function(component) {
		var item = component.get('v.item');
		if ($A.util.isEmpty(item.onlyRule) || item.isURLRequired || this.checkForSurvey(component, item.onlyRule)) {
			component.set('v.showModal', true);
		} else {
			component.set('v.showCheck', true);
			this.createEnrollmentAction(component);
		}
	}
})