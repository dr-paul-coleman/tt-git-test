({
	getFeed : function(component) {
		var incidentId = component.get('v.incidentId');
		var contactId = component.get('v.contactId');
		var filter = component.get('v.filter');
		var tabName = component.get('v.tabName');
		var action = component.get('c.getFeed');
		action.setParams({
			incidentId: incidentId,
			contactId: contactId,
			filter: filter,
			tabName: tabName
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var feed = response.getReturnValue();
				component.set('v.feed', feed);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})