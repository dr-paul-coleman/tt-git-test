({
	doInit : function(component, event, helper) {
		var factor = component.get('v.factor');
		var assignmentId = factor.assignmentId;
		component.set('v.checked', !$A.util.isEmpty(assignmentId));
		component.set('v.assignmentId', assignmentId);
	},
	handleChange: function(component, event, helper) {
		var checked = component.get('v.checked');
		if (checked) {
			helper.createAssignment(component);
		} else {
			helper.deleteAssignment(component);
		}
	}
})