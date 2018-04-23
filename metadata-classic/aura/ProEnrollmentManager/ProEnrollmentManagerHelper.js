({
	getUserInfo: function(component) {
		var action = component.get('c.getUserInfo');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var myUser = response.getReturnValue();
				component.set('v.myUser', myUser);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	convertIdto18: function(component) {
		var recordId = component.get('v.recordId');
		var recordId18 = recordId;
		if (recordId.length == 15) {
			var suffix = '';
			var flags;
			for (var i = 0; i < 3; i++) {
				flags = 0;
				for (var j = 0; j < 5; j++) {
					var c = recordId.substring(i * 5 + j, i * 5 + j + 1);
					if (c.toUpperCase() == c && c >= 'A' && c <= 'Z') {
						flags = flags + (1 << j);
					}
				}
				if (flags <= 25) {
					suffix = suffix + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.substring(flags, flags + 1);
				} else {
					suffix = suffix + '012345'.substring(flags - 25, flags - 24);
				}
			}
			recordId18 += suffix;
		}
		component.set('v.recordId18', recordId18);
	},
    searchUsers: function(component) {
		var searchText = component.get('v.agentSearchText');
		var action = component.get('c.searchUsers');
		action.setParams({
			searchText: searchText
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var Agents = response.getReturnValue();
				component.set('v.Agents', Agents);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getAllEnrollments : function(component) {
		var enrollmentId = component.get('v.recordId');
		var action = component.get('c.getAllEnrollments');
		action.setParams({
			enrollmentId: enrollmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var enrollments = response.getReturnValue();
				component.set('v.enrollments', enrollments);
				var hasInactiveEnrollments = false;
                var showAssigntoProServices = true;
				enrollments.forEach(function(enrollment) {
					if (enrollment.outreach_type__c == 'managed_account' || enrollment.outreach_type__c == 'pro_engagement' || enrollment.outreach_type__c == 'pro_onboarding' || enrollment.outreach_type__c == 'pro_success' || enrollment.outreach_type__c == 'lead_acquisition' || !enrollment.Market__r.EnrollAProEnabled__c || !enrollment.Market__r.RequestCategory__r.EnrollAProEnabled__c) {
						hasInactiveEnrollments = true;                       
					}
                    if (enrollment.outreach_type__c == 'managed_account' || enrollment.outreach_type__c == 'lead_acquisition'){
                         showAssigntoProServices = false;
                    }
				});
				component.set('v.hasInactiveEnrollments', hasInactiveEnrollments);
                component.set('v.showAssigntoProServices', showAssigntoProServices);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
    saveAgent: function(component,accountId,agentId){     
		var action = component.get('c.assignToAgent');
		action.setParams({
			accountId: accountId,
            agentId: agentId            
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				if (response.getReturnValue()) {
					var appEvent = $A.get('e.c:AccountUpdated');
					appEvent.setParams({
						accountId: accountId,
                        agentId: agentId
					});
					appEvent.fire();
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
        component.set('v.showAgentModal', false);
		component.set('v.showAssignModal', false);
    },
	enrollAProJS: function(component) {
		var enrollments = component.get('v.enrollments');
		var action = component.get('c.enrollAPro');
		action.setParams({
			accountId: enrollments[0].Account__c
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var enrollmentId = response.getReturnValue();
				if ($A.util.isEmpty(enrollmentId)) {
					component.set('v.showEAPErrorModal', true);
				} else {
					var appEvent = $A.get('e.c:EnrollAProClicked');
					appEvent.setParams({
						enrollmentId: enrollmentId
					});
					appEvent.fire();
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})