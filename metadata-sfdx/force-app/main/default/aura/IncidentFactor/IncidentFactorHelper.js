({
	createAssignment : function(component) {
		var factor = component.get('v.factor');
		var incidentId = component.get('v.incidentId');
		var action = component.get('c.createAssignment');
		action.setParams({
			factorId: factor.record.Id,
			incidentId: incidentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var assignment = response.getReturnValue();
				component.set('v.assignmentId', assignment.Id);

				this.fireRefreshEvent(component);

			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	deleteAssignment: function(component) {
		var assignmentId = component.get('v.assignmentId');
		var action = component.get('c.deleteAssignment');
		action.setParams({
			assignmentId: assignmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.assignmentId', null);

				this.fireRefreshEvent(component);

			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	fireRefreshEvent: function(component)
	{
	    var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

        refreshIncident.setParams({'name' : 'IncidentFactors' }); 
        refreshIncident.fire();
    },
})