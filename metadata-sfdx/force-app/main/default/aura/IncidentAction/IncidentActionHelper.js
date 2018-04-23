({
	upsertAction : function(component, incidentAction) {
		var action = component.get('c.upsertAction');
		action.setParams({
			incidentAction: incidentAction
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var compEvent = component.getEvent('IncidentActionModified');
				compEvent.fire();

				var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

                refreshIncident.setParams({'name' : 'Incident' });
                refreshIncident.fire();

			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	
	deleteAction: function(component) {
		var incidentAction = component.get('v.incidentAction');
		var action = component.get('c.deleteAction');
		action.setParams({
			actionId: incidentAction.Id
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var compEvent = component.getEvent('IncidentActionModified');
				compEvent.fire();

				var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

                refreshIncident.setParams({'name' : 'Incident' });
                refreshIncident.fire();

			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})