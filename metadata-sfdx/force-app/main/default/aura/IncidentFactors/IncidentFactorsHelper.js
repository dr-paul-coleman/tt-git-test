({
	getFactors : function(component) {
		var incidentId = component.get('v.incidentId');
		var action = component.get('c.getFactors');
		action.setParams({
			incidentId: incidentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var factors = response.getReturnValue();
				component.set('v.factors', factors);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})