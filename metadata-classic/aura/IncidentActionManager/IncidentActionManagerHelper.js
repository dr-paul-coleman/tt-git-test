({
	getActions: function(component) {
		var incidentId = component.get('v.incidentId');
		var status;
		var statusFilter = component.get('v.statusFilter');
		if (!$A.util.isEmpty(statusFilter)) {
			status = statusFilter;
		}
		var action = component.get('c.getActions');
		action.setParams({
			incidentId: incidentId,
			status: status
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var incidentActions = response.getReturnValue();
				component.set('v.incidentActions', incidentActions);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	upsertAction : function(component, incidentAction) {
		var dueDate = component.get('v.dueDate');
		var action = component.get('c.upsertAction');
		action.setParams({
			incidentAction: incidentAction,
			dueDate: dueDate
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				this.getActions(component);

				var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

                refreshIncident.setParams({'name' : 'Incident' });
                refreshIncident.fire();

			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	clearAction: function(component) {
		component.set('v.dueDate', null);
		component.set('v.dueDay', null);
		component.set('v.dueMonth', null);
		component.set('v.dueYear', null);
		component.set('v.notes', null);
	}
})