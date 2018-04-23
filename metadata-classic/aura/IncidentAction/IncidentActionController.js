({
	doInit: function(component, event, helper) {
		var incidentAction = component.get('v.incidentAction');
		var completed = incidentAction.Status__c == 'Completed';
		component.set('v.completed', completed);
	},
	completeAction: function(component, event, helper) {
		var incidentAction = component.get('v.incidentAction');
		if (incidentAction.Status__c == 'Open') {
			incidentAction.Status__c = 'Completed';
		} else {
			incidentAction.Status__c = 'Open';
		}
		helper.upsertAction(component, incidentAction);
	},
	removeAction: function(component, event, helper) {
		helper.deleteAction(component);
	}
})