({
	doInit: function(component, event, helper) {
		var item = component.get('v.item');
		component.set('v.showCheck', !$A.util.isEmpty(item.action));
		if (!$A.util.isEmpty(item.completedRule)) {
			component.set('v.outcome', item.completedRule.EnrollmentActionOutcome__c);
			component.set('v.detail', item.completedRule.Details__c);
		}
		if (item.isURLRequired) {
			if (!$A.util.isEmpty(item.action)) {
				component.set('v.url', item.action.URL__c);
			} else {
				component.set('v.url', component.get('v.enrollmentSavedURL'));
			}
		}
	},
	check : function(component, event, helper) {
		helper.handleCheck(component);
	},
	handleOutcomeChange: function(component, event, helper) {
		helper.changeOutcome(component);
	},
	handleDetailChange: function(component, event, helper) {
		var item = component.get('v.item');
		helper.getRuleFromOutcomeAndDetail(component, item, true);
	},
	toggleSubSteps: function(component, event, helper) {
		component.set('v.showSubSteps', !component.get('v.showSubSteps'));
		var subStepsElem = component.find('subSteps').getElement();
		$(subStepsElem).slideToggle();
	},
	save: function(component, event, helper) {
		var outcomeSelect = component.find('outcomeSelect');
		var item = component.get('v.item');
		var isValid = false;
		if ($A.util.isEmpty(item.outcomes)) {
			isValid = true;
		} else {
			var outcome = component.get('v.outcome');
			if ($A.util.isEmpty(outcome)) {
				isValid = false;
				outcomeSelect.showHelpMessageIfInvalid();
			} else {
				var detailSelect = component.find('detailSelect');
				var detailOptions = component.get('v.detailOptions');
				if ($A.util.isEmpty(detailOptions)) {
					isValid = true;
				} else {
					var detail = component.get('v.detail');
					if ($A.util.isEmpty(detail)) {
						isValid = false;
						detailSelect.showHelpMessageIfInvalid();
					} else {
						isValid = true;
					}
				}
			}
		}
		var item = component.get('v.item');
		var url = component.get('v.url');
		if (item.isURLRequired && $A.util.isEmpty(url)) {
			isValid = false;
			var urlInput = component.find('urlInput');
			urlInput.showHelpMessageIfInvalid();
		}
		if (isValid) {
			helper.createEnrollmentAction(component);
		}
	},
	saveLink: function(component, event, helper) {
		var action = component.get('c.saveURL');
		action.setParams({
			enrollmentId: component.get('v.enrollmentId'),
			url: component.get('v.url')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.url', response.getReturnValue());
				component.set('v.outcome', null);
				component.set('v.detail', null);
				helper.resetModal(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	cancel: function(component, event, helper) {
		var enrollmentAction = component.get('v.enrollmentAction');
		var item = component.get('v.item');
		if ($A.util.isEmpty(enrollmentAction)) {
			component.set('v.outcome', null);
			component.set('v.detail', null);
			component.set('v.url', null);
		} else {
			component.set('v.outcome', item.completedRule.EnrollmentActionOutcome__c);
			component.set('v.detail', item.completedRule.Details__c);
			component.set('v.url', enrollmentAction.URL__c);
		}
		helper.resetModal(component);
	},
	uncheck: function(component, event, helper) {
		component.set('v.showCheck', false);
		component.set('v.outcome', null);
		component.set('v.detail', null);
		component.set('v.url', null);
		component.set('v.showUncheckModal', false);
		helper.deleteEnrollmentAction(component);
	},
	confirmUncheck: function(component, event, helper) {
		component.set('v.showUncheckModal', true);
	},
	cancelUncheckConfirm: function(component, event, helper) {
		component.set('v.showUncheckModal', false);
	},
	edit: function(component, event, helper) {
		var item = component.get('v.item');
		component.set('v.showModal', true);
		component.set('v.outcome', item.completedRule.EnrollmentActionOutcome__c);
		helper.changeOutcome(component);
		component.set('v.detail', item.completedRule.Details__c);
	},
	callCallbackPhone: function(component, event, helper) {
		var appEvent = $A.get('e.c:CustomPhoneClicked');
		appEvent.setParams({
			phone: component.get('v.item.callbackPhone')
		});
		appEvent.fire();
		helper.handleCheck(component);
	},
	handleAccountPhoneClicked: function(component, event, helper) {
		var isActiveTab = component.get('v.isActiveTab');
		var item = component.get('v.item');
		var showCheck = component.get('v.showCheck');
		if (isActiveTab && item.isCallbackRule && !showCheck) {
			helper.handleCheck(component);
		}
	}
})