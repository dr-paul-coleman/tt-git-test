({
	handleShowChange : function(component, event, helper) {
		var show = component.get('v.show');
		if (show) {
			setTimeout(
				$A.getCallback(function() {
					if (component.isValid()) {
						component.set('v.show', false);
					}
				}), 1000
			);
		}
	}
})