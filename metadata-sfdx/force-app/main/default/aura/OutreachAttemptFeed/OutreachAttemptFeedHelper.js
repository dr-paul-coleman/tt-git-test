({
	getFeedItems : function(component) {
		var action = component.get('c.getFeedItems');
		var params = {
			accountId: component.get('v.accountId'),
			type: 'Outreach Attempt'
		};
		var enrollmentOnly = component.get('v.enrollmentOnly');
		if (enrollmentOnly) {
			params.enrollmentId = component.get('v.enrollmentId');
		}
		action.setParams(params);
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var feedItems = response.getReturnValue();
				component.set('v.feedItems', feedItems);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})