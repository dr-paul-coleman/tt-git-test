({
	doInit: function(component, event, helper) {
		helper.getActions(component);
	},
	toggleDatepicker : function(component, event, helper) {
		component.set('v.showDatepicker', !component.get('v.showDatepicker'));
	},
	handleDateSelected: function(component, event, helper) {
		var month = event.getParam('month');
		var day = event.getParam('day');
		var year = event.getParam('year');
		component.set('v.dueDate', month + '/' + day + '/' + year);
		component.set('v.showDatepicker', false);
	},
	createAction: function(component, event, helper) {
	    var dueDate = component.get('v.dueDate');
	    component.set('v.showDueDateError', false);

	    if(dueDate == null || dueDate == '')
	    {
	        component.set('v.showDueDateError', true);
	        return; 
        }

		var incidentAction = {
			sobjectType: 'MIIncidentAction__c',
			Name: 'Follow-up needed',
			MIIncident__c: component.get('v.incidentId'),
			Status__c: 'Open',
			Notes__c: component.get('v.notes'),
			Type__c: 'Follow-up'
		};
		helper.upsertAction(component, incidentAction);
		helper.clearAction(component);
	},
	handleIncidentActionModified: function(component, event, helper) {
		helper.getActions(component);
	},
	handleStatusFilterChange: function(component, event, helper) {
		helper.getActions(component);
	}
})