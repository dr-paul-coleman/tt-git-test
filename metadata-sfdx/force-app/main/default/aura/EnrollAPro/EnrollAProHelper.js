({
	enrollAPro: function(component) {
		var action = component.get('c.enrollAPro');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var enrollmentId = response.getReturnValue();
				if ($A.util.isEmpty(enrollmentId)) {
					component.set('v.showErrorToast', true);
				} else {
					// location.href = '/apex/ProEnrollmentManager?id=' + enrollmentId;
					this.fireProAssignedEvent(component, enrollmentId);
				}
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	fireProAssignedEvent: function(component, enrollmentId) {
		var appEvent = $A.get('e.c:ProAssigned');
		appEvent.setParams({
			enrollmentId: enrollmentId
		});
		appEvent.fire();
	}
})