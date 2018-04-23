({
	doInit: function(component, event, helper) {
		var enrollment = component.get('v.enrollment');
		component.set('v.funnelStep', enrollment.FunnelStep__c);
	},
	handleEnrollmentModified: function(component, event, helper) {
		var enrollmentId = event.getParam('enrollmentId');
		var funnelStep = event.getParam('funnelStep');
		var enrollment = component.get('v.enrollment');
		if (enrollmentId == enrollment.Id) {
			component.set('v.funnelStep', funnelStep);
		}
	},
	handleActiveTab: function(component, event, helper) {
		var tab = event.getSource();
		var enrollmentId = tab.get('v.id');
		var myUser = component.get('v.myUser');
		$A.createComponent(
			'c:EnrollmentActionManager',
			{
				enrollmentId: enrollmentId,
				myUser: myUser
			},
			function(tabBody, status, error) {
				if (status === 'SUCCESS') {
					tab.set('v.body', tabBody);
				}
			}
		);
		var appEvent = $A.get('e.c:EnrollmentTabSelected');
		appEvent.setParams({
			enrollmentId: enrollmentId
		});
		appEvent.fire();
	}
})