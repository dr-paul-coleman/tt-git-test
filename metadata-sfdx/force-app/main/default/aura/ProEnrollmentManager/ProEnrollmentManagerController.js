({
	doInit : function(component, event, helper) {
		helper.convertIdto18(component);
		helper.getAllEnrollments(component);
		helper.getUserInfo(component);
	},
	handleEAPMenuSelected: function(component, event, helper) {
		var menuValue = event.getParam('value');
		if (menuValue == 'filters') {
			component.set('v.showEAPFilterModal', true);
		}
	},
	cancelEAPFilterModal: function(component, event, helper) {
		component.set('v.showEAPFilterModal', false);
	},
	showEAPFilterModal: function(component, event, helper) {
		component.set('v.showEAPFilterModal', true);
		component.set('v.showEAPErrorModal', false);
	},
	hideEAPErrorModal: function(component, event, helper) {
		component.set('v.showEAPErrorModal', false);
	},
	getNextPro: function(component, event, helper) {
		helper.enrollAProJS(component);
	},
	handleEnrollmentTabSelected: function(component, event, helper) {
		var selectedEnrollmentId = event.getParam('enrollmentId');
		component.set('v.selectedEnrollmentId', selectedEnrollmentId);
	},
	showFeedbackModal: function(component, event, helper) {
		var selectedEnrollmentId = component.get('v.selectedEnrollmentId');
		var enrollments = component.get('v.enrollments');
		var selectedEnrollment;
		enrollments.forEach(function(enrollment) {
			if (enrollment.Id == selectedEnrollmentId) {
				selectedEnrollment = enrollment;
			}
		});
		component.set('v.selectedEnrollment', selectedEnrollment);
		component.set('v.showFeedbackModal', true);
	},
	closeFeedbackModal: function(component, event, helper) {
		component.set('v.showFeedbackModal', false);
		//component.set('v.showGoogleForm', false);
		component.set('v.showGetFeedbackForm', false);
	},
	handleProAssigned: function(component, event, helper) {
		var enrollmentId = event.getParam('enrollmentId');
		location.href = '/apex/ProEnrollmentManager?id=' + enrollmentId;
	},
	showAssignModal: function(component, event, helper) {
		component.set('v.showAssignModal', true);
	},
	closeAssignModal: function(component, event, helper) {
        component.set('v.showAgentModal', false);
		component.set('v.showAssignModal', false);
	},
	assignProToMe: function(component, event, helper) {
		var enrollments = component.get('v.enrollments');
		var accountId = enrollments[0].Account__c;
		var action = component.get('c.assignToMe');
		action.setParams({
			accountId: accountId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				if (response.getReturnValue()) {
					var appEvent = $A.get('e.c:AccountUpdated');
					appEvent.setParams({
						accountId: accountId
					});
					appEvent.fire();
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
		component.set('v.showAssignModal', false);
	},
    handleagentSearchTextChange: function(component, event, helper) {
		var agentSearchText = component.get('v.agentSearchText');
		if (!$A.util.isEmpty(agentSearchText) && agentSearchText.length > 1) {
			helper.searchUsers(component);
		} else {
			component.set('v.Agents', []);
		}
	},	
	selectAgent: function(component, event, helper) {
		var userId = event.currentTarget.dataset.value;
        var userName = event.currentTarget.dataset.name;
        console.log(userId);
        console.log(userName);		
		component.set('v.agentId',userId);
        component.set('v.agentName',userName);
        component.set('v.agentSearchText',userName);
        component.set('v.Agents', null);
	},
	removeAgent: function(component, event, helper) {
		component.set('v.Agent', null);
	},   	
    saveAgent: function(component, event, helper) {	
        var agentId = component.get('v.agentId'); 
        var enrollment = component.get('v.enrollments');
        var accountId = enrollment[0].Account__c;
        helper.saveAgent(component,accountId,agentId);   
    },
    showModal: function(component, event, helper) {
		component.set('v.showAgentModal', true);
	},
	cancelAgentModal:function(component,event,helper){     
        component.set('v.agentSearchText', null);
        component.set('v.Agents', null);
		component.set('v.showAgentModal', false);
        component.set('v.showAssignModal', true);
	},
	removeAssignee: function(component, event, helper) {
		var enrollments = component.get('v.enrollments');
		var accountId = enrollments[0].Account__c;
		var action = component.get('c.assignToMe');
		action.setParams({
			accountId: accountId,
			removeAssignee: true
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				if (response.getReturnValue()) {
					var appEvent = $A.get('e.c:AccountUpdated');
					appEvent.setParams({
						accountId: accountId
					});
					appEvent.fire();
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
		component.set('v.showAssignModal', false);
	},
	/*chooseGoogleForm: function(component, event, helper) {
		component.set('v.showGoogleForm', true);
	},*/
	chooseGetFeedbackForm: function(component, event, helper) {
		component.set('v.showGetFeedbackForm', true);
	},
	toggleInactiveEnrollments: function(component, event, helper) {
		component.set('v.showInactiveEnrollments', !component.get('v.showInactiveEnrollments'));
	},
	toggleFeedShowEnrollmentOnlyTrue: function(component, event, helper) {
		component.set('v.feedShowEnrollmentOnly', true);
	},
	toggleFeedShowEnrollmentOnlyFalse: function(component, event, helper) {
		component.set('v.feedShowEnrollmentOnly', false);
	},
	toggleExpandableState: function (component, event, helper){
        component.set('v.isExpanded',!component.get('v.isExpanded'));
    },

	submitCategorizationClick: function(component, event, helper) {
        var ce = $A.get("e.c:CategorizationEvent");

        component.set('v.categorizationAllowSubmit', false);

        ce.setParam('actionName', 'Save Records');
        ce.setParam('recordId', component.get('v.recordId'));

        ce.fire();
    },
})