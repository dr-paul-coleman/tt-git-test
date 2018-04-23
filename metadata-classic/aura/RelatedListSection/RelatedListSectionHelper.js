({
	getRelatedListsForPageName : function(component) {
		var sectionName = component.get('v.sectionName');
		var action = component.get('c.getRelatedListsForPageName');
		action.setParams({
			sectionName: sectionName
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var settings = response.getReturnValue();
				component.set('v.settings', settings);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})