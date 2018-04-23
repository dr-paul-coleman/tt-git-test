({
	doInit : function(component, event, helper) {
		// helper.getFunnelSteps(component);
		// helper.getEnrollment(component, true);
		// var attempt = component.get('v.attempt');
		// attempt.Enrollment__c = component.get('v.enrollmentId');
		// component.set('v.attempt', attempt);
	},
	handleScriptsLoaded: function(component, event, helper) {
		helper.getFunnelStepEndpoint(component);
		helper.getFunnelSteps(component);
		helper.getFeedItems(component);
		// helper.getEnrollment(component, true);
		var attempt = component.get('v.attempt');
		attempt.Enrollment__c = component.get('v.enrollmentId');
        component.set('v.attempt', attempt);        
        
	},
	handleDateSelected: function(component, event, helper) {
		var month = event.getParam('month');
		var day = event.getParam('day');
		var year = event.getParam('year');
		var callbackDate = month + '/' + day + '/' + year;
		component.set('v.callbackDate', callbackDate);
		component.set('v.showDatepicker', false);
	},
	handleEnrollmentActionModified: function(component, event, helper) {
		var enrollmentId = component.get('v.enrollmentId');
		var eventEnrollmentId = event.getParam('enrollmentId');
		if (enrollmentId == eventEnrollmentId) {
			helper.handleEnrollmentUpdate(component);
			helper.updateDependentEnrollmentItems(component, event.getParam('ruleName'), event.getParam('ruleOutcome'), event.getParam('completed'), event.getParam('oldRuleOutcome'));
		}
	},
	handleFunnelStepClicked: function(component, event, helper) {
		// var funnelStep = event.getParam('funnelStep');
		// component.set('v.funnelStep', funnelStep);
		// helper.getOnboardingSteps(component);
	},
	handleAttemptDispositionChange: function(component, event, helper) {
		var attempt = component.get('v.attempt');
		var dispositionRules = component.get('v.dispositionRules');
		var ruleFound = false;
		var showAttemptSurvey = false;
		var attemptSurveyInModal = false;
		var enrollment = component.get('v.enrollment');
		dispositionRules.forEach(function(rule) {           
			if (rule.Id == attempt.RuleId__c) {
				attempt.OutreachDisposition__c = rule.EnrollmentOutreachDisposition__c;
				attempt.Name = rule.Name;
				ruleFound = true;
				if (!$A.util.isEmpty(rule.ShowSurveyForFunnelStep__c)) {
					var funnelSteps = rule.ShowSurveyForFunnelStep__c.split(';');
					for (var i in funnelSteps) {
						if (enrollment.FunnelStep__c == funnelSteps[i]) {
							showAttemptSurvey = true;                           
							break;
						}
					}                    
				}
				if ((showAttemptSurvey || $A.util.isEmpty(rule.ShowSurveyForFunnelStep__c)) && !$A.util.isEmpty(rule.ShowSurveyForOutreachType__c)) {					
                    var outreachTypes = rule.ShowSurveyForOutreachType__c.split(';');
					for (var i in outreachTypes) {
						if ((enrollment.outreach_type__c != 'managed_account' && enrollment.outreach_type__c != 'pro_onboarding' && enrollment.outreach_type__c != 'pro_engagement' && enrollment.Market__r.RequestCategory__r.outreach_type__c == outreachTypes[i]) || enrollment.outreach_type__c == 'managed_account') {
							showAttemptSurvey = true;
							break;
						}
					}
				}
				if (showAttemptSurvey && !$A.util.isEmpty(rule.ShowSurveyAsModalForOutreachType__c)) {
					var outreachTypes = rule.ShowSurveyAsModalForOutreachType__c.split(';');
					for (var i in outreachTypes) {
						if ((enrollment.outreach_type__c != 'managed_account' && enrollment.outreach_type__c != 'pro_onboarding' && enrollment.outreach_type__c != 'pro_engagement'&& enrollment.Market__r.RequestCategory__r.outreach_type__c == outreachTypes[i]) ) {
							attemptSurveyInModal = true;
							break;
						}
					}
				}
			}
		});
		if (!ruleFound) {
			attempt.OutreachDisposition__c = null;
			attempt.Name = null;
		}
		component.set('v.attempt', attempt);
		component.set('v.showAttemptSurvey', showAttemptSurvey);
		component.set('v.attemptSurveyInModal', attemptSurveyInModal);
	},
	showAttemptSurveyModal: function(component, event, helper) {
		component.set('v.showAttemptSurveyModal', true);
	},
	closeAttemptSurveyModal: function(component, event, helper) {
		component.set('v.showAttemptSurveyModal', false);
	},
	saveAttempt: function(component, event, helper) {
		var attempt = component.get('v.attempt');
		var showCallbackDateError = false;
		if ($A.util.isEmpty(attempt.OutreachDisposition__c)) {
			var attemptSelect = component.find('attemptSelect');
			attemptSelect.showHelpMessageIfInvalid();
		} else if (attempt.OutreachDisposition__c == 'Callback Scheduled') {
			var callbackDate = component.get('v.callbackDate');
			if ($A.util.isEmpty(callbackDate)) {
				showCallbackDateError = true;
			} else {
				var callbackTime = component.get('v.callbackTime');
				if ($A.util.isEmpty(callbackTime)) {
					var callbackTimeSelect = component.find('callbackTimeSelect');
					callbackTimeSelect.showHelpMessageIfInvalid();
				} else {
					var callbackOwner = component.get('v.callbackOwnerName');
					if (callbackOwner != 'Pro Services' && callbackOwner != 'Myself') {
						callbackOwner = component.get('v.callbackOwnerId');
					}
					if ($A.util.isEmpty(attempt.CallbackPhone__c)) {
						helper.saveAttempt(component, callbackDate, callbackTime, callbackOwner);
					} else {
						var callbackPhoneInput = component.find('callbackPhone');
						var validity = callbackPhoneInput.get('v.validity');
						if (validity.valid) {
							helper.saveAttempt(component, callbackDate, callbackTime, callbackOwner);
						} else {
							callbackPhoneInput.showHelpMessageIfInvalid();
						}
					}
				}
			}
		} else {
			helper.saveAttempt(component);
		}
		component.set('v.showCallbackDateError', showCallbackDateError);
	},
	editAttempt: function(component, event, helper) {
		helper.hideAttemptConfirmation(component);
	},
	toggleDatepicker: function(component, event, helper) {
		component.set('v.showDatepicker', !component.get('v.showDatepicker'));
	},
	showCallbackOwnerModal: function(component, event, helper) {
		//component.set('v.callbackOwnerChoice', 'Pro Services');
		component.set('v.showCallbackOwnerModal', true);
	},
	cancelCallbackOwnerModal: function(component, event, helper) {
		helper.cancelCallbackOwnerModal(component);
	},
	handleCallbackOwnerOptionSelected: function(component, event, helper) {
		var radio = event.getSource();
		component.set('v.callbackOwnerChoice', radio.get('v.value'));
	},
	handleOtherOwnerSearchTextChange: function(component, event, helper) {
		var otherOwnerSearchText = component.get('v.otherOwnerSearchText');
		if (!$A.util.isEmpty(otherOwnerSearchText) && otherOwnerSearchText.length > 1) {
			helper.searchUsers(component);
		} else {
			component.set('v.otherOwners', []);
		}
	},
	selectOtherOwner: function(component, event, helper) {
		var userId = event.currentTarget.dataset.userId;
		var otherOwners = component.get('v.otherOwners');
		var otherOwner = _.findWhere(otherOwners, {Id: userId});
		component.set('v.otherOwner', otherOwner);
	},
	removeOtherOwner: function(component, event, helper) {
		component.set('v.otherOwner', null);
	},
	saveCallbackOwner: function(component, event, helper) {
		var callbackOwnerChoice = component.get('v.callbackOwnerChoice');
		var isValid = true;
		switch (callbackOwnerChoice) {
			case 'Pro Services':
				component.set('v.callbackOwnerId', null);
				component.set('v.callbackOwnerName', 'Pro Services');
				break;
			case 'Myself':
				component.set('v.callbackOwnerId', null);
				component.set('v.callbackOwnerName', 'Myself');
				break;
			case 'other':
				var otherOwner = component.get('v.otherOwner');
				if ($A.util.isEmpty(otherOwner)) {
					isValid = false;
					var otherOwnerSearch = component.find('otherOwnerSearch');
					otherOwnerSearch.showHelpMessageIfInvalid();
				} else {
					component.set('v.callbackOwnerId', otherOwner.Id);
					component.set('v.callbackOwnerName', otherOwner.Name);
				}
				break;
		}
		if (isValid) {
			helper.cancelCallbackOwnerModal(component);
		}
	},
	showSendEmailModal: function(component, event, helper) {
		var enrollment = component.get('v.enrollment');
		var action = component.get('c.getProContact');
		action.setParams({
			accountId: enrollment.Account__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var contactId = response.getReturnValue();
				var appEvent = $A.get('e.c:SendEmailClicked');
				appEvent.setParams({
					enrollmentId: enrollment.Id,
					contactId: contactId
				});
				appEvent.fire();
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
		// component.set('v.showSendEmailModal', true);
	},
	closeSendEmailModal: function(component, event, helper) {
		component.set('v.showSendEmailModal', false);
	},
	openStandardDetail: function(component, event, helper) {
		var enrollment = component.get('v.enrollment');
		var appEvent = $A.get('e.c:StandardEnrollmentDetailClicked');
		appEvent.setParams({
			enrollmentId: enrollment.Id,
			enrollmentName: enrollment.Name
		});
		appEvent.fire();
	},
	handleEnrollmentTabSelected: function(component, event, helper) {
		var activeId = event.getParam('enrollmentId');
		var enrollmentId = component.get('v.enrollmentId');
		var isActiveTab = false;
		if (activeId.substring(0, 15) == enrollmentId.substring(0, 15)) {
			isActiveTab = true;
		}
		component.set('v.isActiveTab', isActiveTab);
	}
})