({
	cancelCallbackOwnerModal: function(component) {
		component.set('v.showCallbackOwnerModal', false);
		component.set('v.otherOwner', null);
		//component.set('v.callbackOwnerChoice', null);
	},
	getFeedItems: function(component) {
		var enrollmentId = component.get('v.enrollmentId');
		var action = component.get('c.getFeedItems');
		action.setParams({
			enrollmentId: enrollmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var feedItems = response.getReturnValue();
				component.set('v.feedItems', feedItems);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	searchUsers: function(component) {
		var searchText = component.get('v.otherOwnerSearchText');
		var action = component.get('c.searchUsers');
		action.setParams({
			searchText: searchText
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var otherOwners = response.getReturnValue();
				component.set('v.otherOwners', otherOwners);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	getFunnelSteps: function(component)
	{
		var action = component.get('c.getFunnelSteps');

		action.setParams({'enrollmentId': component.get('v.enrollmentId')});

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var funnelSteps = response.getReturnValue();
				component.set('v.funnelSteps', funnelSteps);
				this.getEnrollment(component, true);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	getFunnelStepEndpoint: function(component) {
		var action = component.get('c.getFunnelStepEndpoint');
		action.setParams({
			enrollmentId: component.get('v.enrollmentId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var funnelStepEndpoint = response.getReturnValue();
				component.set('v.funnelStepEndpoint', funnelStepEndpoint);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getEnrollment : function(component, shouldGetOnboardingSteps) {
		var enrollmentId = component.get('v.enrollmentId');
		var action = component.get('c.getEnrollment');
		action.setParams({
			enrollmentId: enrollmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var enrollment = response.getReturnValue();
				component.set('v.enrollment', enrollment);             		
                console.log('enrollment.outreach_type__c: '+enrollment.outreach_type__c);
                if (enrollment.outreach_type__c == 'managed_account'){                    
                   component.set('v.callbackOwnerChoice', 'Myself');
                   component.set('v.callbackOwnerName', 'Myself');
                }else{
                   component.set('v.callbackOwnerChoice', 'Pro Services');
                   component.set('v.callbackOwnerName', 'Pro Services');
                }
				component.set('v.funnelStep', enrollment.FunnelStep__c);
				if (shouldGetOnboardingSteps) {
					// this.getOnboardingSteps(component, true);
					this.getPrevOnboardingSteps(component);
					this.getOutreachDispositions(component);
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getPrevOnboardingSteps: function(component) {
		component.set('v.showOnboardingStepsSpinner', true);
		var funnelSteps = component.get('v.funnelSteps');
		var currentFunnelStep = component.get('v.funnelStep');
		var prevFunnelSteps = [];
		if (!$A.util.isEmpty(funnelSteps) && !$A.util.isEmpty(currentFunnelStep)) {
			for (var i = 0; i < funnelSteps.length; i++) {
				var funnelStep = funnelSteps[i];
				if (funnelStep == currentFunnelStep) {
					break;
				} else {
					prevFunnelSteps.push(funnelStep);
				}
			}
			var enrollment = component.get('v.enrollment');
			var action = component.get('c.getPrevOnboardingSteps');
			action.setParams({
				funnelSteps: prevFunnelSteps,
				enrollmentId: enrollment.Id,
				outreachType: enrollment.outreach_type__c,
				outreachGroup: enrollment.outreach_group__c
			});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === 'SUCCESS') {
					var prevSteps = response.getReturnValue();
					var prevOnboardingStepNames = [];
					prevSteps.forEach(function(step) {
						prevOnboardingStepNames.push(step.name);
					});
					component.set('v.prevOnboardingStepNames', prevOnboardingStepNames);
					component.set('v.prevOnboardingSteps', prevSteps);
					component.set('v.onboardingSteps', []);
					this.getOnboardingSteps(component);
				} else if (state === 'ERROR') {
					// error handling goes here
				}
			});
			$A.enqueueAction(action);
		}
	},
	getAllPrevOnboardingSteps: function(component) {
		var funnelSteps = component.get('v.funnelSteps');
		var currentFunnelStep = component.get('v.funnelStep');
		// component.set('v.prevOnboardingStepNames', []);
		// component.set('v.prevOnboardingSteps', []);
		if (!$A.util.isEmpty(funnelSteps)) {
			for (var i = 0; i < funnelSteps.length; i++) {
				var funnelStep = funnelSteps[i];
				if (funnelStep == currentFunnelStep) {
					break;
				} else {
					this.getPrevOnboardingStepsForFunnelStep(component, funnelStep);
				}
			}
		}
	},
	getPrevOnboardingStepsForFunnelStep: function(component, funnelStep) {
		var enrollment = component.get('v.enrollment');
		var action = component.get('c.getOnboardingSteps');
		action.setParams({
			enrollmentId: enrollment.Id,
			funnelStep: funnelStep,
			outreachType: enrollment.outreach_type__c,
			outreachGroup: enrollment.outreach_group__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var prevSteps = response.getReturnValue();
				this.addToPreviousOnboardingSteps(component, funnelStep, prevSteps);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	addToPreviousOnboardingSteps: function(component, funnelStep, prevSteps) {
		var onboardingStepNames = component.get('v.onboardingStepNames');
		var prevOnboardingSteps = component.get('v.prevOnboardingSteps');
		var prevOnboardingStepNames = component.get('v.prevOnboardingStepNames');
		prevSteps.forEach(function(prevStep) {
			if (!_.contains(onboardingStepNames, prevStep.name) && !_.contains(prevOnboardingStepNames, prevStep.name)) {
				prevOnboardingStepNames.push(prevStep.name);
				prevOnboardingSteps.push(prevStep);
			}
		});
		prevOnboardingSteps = _.sortBy(prevOnboardingSteps, 'displayOrder');
		component.set('v.prevOnboardingSteps', prevOnboardingSteps);
		component.set('v.prevOnboardingStepNames', prevOnboardingStepNames);
	},
	getOnboardingSteps: function(component) {
		var enrollment = component.get('v.enrollment');
		var funnelStep = component.get('v.funnelStep');
		var action = component.get('c.getOnboardingSteps');
		action.setParams({
			enrollmentId: enrollment.Id,
			funnelStep: funnelStep,
			outreachType: enrollment.outreach_type__c,
			outreachGroup: enrollment.outreach_group__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var onboardingSteps = response.getReturnValue();
				var onboardingStepNames = [];
				onboardingSteps.forEach(function(step) {
					onboardingStepNames.push(step.name);
				});
				component.set('v.onboardingStepNames', onboardingStepNames);
				component.set('v.onboardingSteps', onboardingSteps);
				var prevOnboardingStepNames = component.get('v.prevOnboardingStepNames');
				var intersectionNames = _.intersection(prevOnboardingStepNames, onboardingStepNames);
				if (!$A.util.isEmpty(intersectionNames)) {
					var prevOnboardingSteps = component.get('v.prevOnboardingSteps');
					prevOnboardingSteps = _.reject(prevOnboardingSteps, function(step) {
						return _.contains(intersectionNames, step.name);
					});
					prevOnboardingStepNames = _.difference(prevOnboardingStepNames, intersectionNames);
					component.set('v.prevOnboardingStepNames', prevOnboardingStepNames);
					component.set('v.prevOnboardingSteps', prevOnboardingSteps);
				}
				component.set('v.showOnboardingStepsSpinner', false);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getOutreachDispositions: function(component) {
		var enrollment = component.get('v.enrollment');
		var action = component.get('c.getOutreachDispositions');
		action.setParams({
			funnelStep: enrollment.FunnelStep__c,
			outreachType: enrollment.outreach_type__c,
			outreachGroup: enrollment.outreach_group__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var dispositionRules = response.getReturnValue();
				component.set('v.dispositionRules', dispositionRules);
				component.set('v.showAttemptSurvey', false);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	handleEnrollmentUpdate: function(component, refreshSteps) {
		//component.set('v.showOnboardingStepsSpinner', true);
		var enrollment = component.get('v.enrollment');
		var action = component.get('c.handleEnrollmentUpdate');
		action.setParams({
			enrollmentId: enrollment.Id,
			outreachType: enrollment.outreach_type__c,
			outreachGroup: enrollment.outreach_group__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var result = response.getReturnValue();
				var currentFunnelStep = enrollment.FunnelStep__c;
				var newFunnelStep = result.FunnelStep__c;
				component.set('v.enrollment', result);
				component.set('v.funnelStep', newFunnelStep);
				if (currentFunnelStep != newFunnelStep || refreshSteps) {
					// this.addCurrentStepsToPrevOnboardingSteps(component);
					// this.getOnboardingSteps(component, true);
					this.getPrevOnboardingSteps(component);
					this.getOutreachDispositions(component);
					this.fireEnrollmentModifiedEvent(component);
				} else {
					component.set('v.showOnboardingStepsSpinner', false);
				}
				this.fireProFeedRefreshNeededEvent(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	addCurrentStepsToPrevOnboardingSteps: function(component) {
		var prevOnboardingSteps = component.get('v.prevOnboardingSteps');
		var prevOnboardingStepNames = component.get('v.prevOnboardingStepNames');
		var onboardingSteps = component.get('v.onboardingSteps');
		onboardingSteps.forEach(function(step) {
			prevOnboardingSteps.push(step);
			prevOnboardingStepNames.push(step.name);
		});
		prevOnboardingSteps = _.sortBy(prevOnboardingSteps, 'displayOrder');
		component.set('v.prevOnboardingSteps', prevOnboardingSteps);
		component.set('v.prevOnboardingStepNames', prevOnboardingStepNames);
		component.set('v.onboardingSteps', []);
		component.set('v.onboardingStepNames', []);
	},
	saveAttempt: function(component, callbackDate, callbackTime, callbackOwner) {
		var attempt = component.get('v.attempt');
		var action = component.get('c.createEnrollmentAction');
		action.setParams({
			action: attempt,
			callbackDate: callbackDate,
			callbackTime: callbackTime,
			callbackOwner: callbackOwner
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				attempt = response.getReturnValue();
				component.set('v.attempt', attempt);
				this.showAttemptConfirmation(component);
				this.handleEnrollmentUpdate(component, !$A.util.isEmpty(callbackDate) && !$A.util.isEmpty(callbackTime) && !$A.util.isEmpty(callbackOwner));
				if (!$A.util.isEmpty(callbackDate)) {
					this.fireAccountUpdated(component);
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	fireAccountUpdated: function(component) {
		var enrollment = component.get('v.enrollment');
		var appEvent = $A.get('e.c:AccountUpdated');
		appEvent.setParams({
			accountId: enrollment.Account__c
		});
		appEvent.fire();
	},
	fireProFeedRefreshNeededEvent: function(component) {
		var appEvent = $A.get('e.c:ProFeedRefreshNeeded');
		appEvent.fire();
	},
	fireEnrollmentModifiedEvent: function(component) {
		var enrollment = component.get('v.enrollment');
		var appEvent = $A.get('e.c:EnrollmentModified');
		appEvent.setParams({
			funnelStep: enrollment.FunnelStep__c,
			enrollmentId: enrollment.Id
		});
		appEvent.fire();
	},
	updateDependentEnrollmentItems: function(component, ruleName, ruleOutcome, completed, oldRuleOutcome) {
		var onboardingSteps = component.get('v.onboardingSteps');
		onboardingSteps.forEach(function(item) {
			if (!$A.util.isEmpty(item.prereqRuleName) && item.prereqRuleName == ruleName) {
				if ($A.util.isEmpty(item.prereqRuleOutcome) || (!$A.util.isEmpty(item.prereqRuleOutcome) && item.prereqRuleOutcome == ruleOutcome)) {
					if (completed) {
						item.showItem = true;
					} else {
						item.showItem = false;
					}
				} else if (item.prereqRuleOutcome == oldRuleOutcome) {
					item.showItem = false;
				}
			}
		});
		component.set('v.onboardingSteps', onboardingSteps);
	},
	showAttemptConfirmation: function(component) {
		$('.outreach-attempt-details').animate({
			left: "-110%"
		});
		$('.outreach-attempt-confirmation').animate({
			left: 0
		});
	},
	hideAttemptConfirmation: function(component) {
		$('.outreach-attempt-details').animate({
			left: 0
		});
		$('.outreach-attempt-confirmation').animate({
			left: "110%"
		});
	}
})