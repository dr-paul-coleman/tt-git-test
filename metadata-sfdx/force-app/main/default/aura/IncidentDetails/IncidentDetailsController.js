({
	writeEmail: function(component, event, helper) {
		component.set('v.showEmailComposer', true);
	},
	hideEmail: function(component, event, helper) {
		component.set('v.showEmailComposer', false);
	},
	call: function(component, event, helper) {
		var appEvent = $A.get('e.c:CustomPhoneClicked');
		appEvent.setParams({
			target: component.get('v.phoneTarget')
		});
		appEvent.fire();
	},
	closeIncident: function(component, event, helper) {
		var action = component.get('c.closeMIIncident');
		action.setParams({
			incidentId: component.get('v.incidentId')
		});
		//todo display modal to set ProOutcome__c and CustomerOutcome__c
		var dl = $(".tt-incident-status");
		var status = $(dl).text();
		$(dl).text('Closing...');
		$(dl).css({ 'color' : 'darkblue'});
		action.setCallback(this, function(response) {
			$(dl).css({ 'color' : ''});
			var state = response.getState();
			if (state === 'SUCCESS') {
				$A.log("Incident Closed", response);
				$(dl).text(response.getReturnValue());
			} else if (state === 'ERROR') {
				$(dl).text(status);
				console.error(response.getError());
				$A.log("callback error", response.getError());
			}
		});
		$A.enqueueAction(action);
	}
})