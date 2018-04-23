({
	doInit : function(component, event, helper) {
		helper.getFeedItems(component);
	},
	handleEnrollmentOnlyChange: function(component, event, helper) {
		helper.getFeedItems(component);
	},
	handleEnrollmentIdChange: function(component, event, helper) {
		var enrollmentOnly = component.get('v.enrollmentOnly');
		if (enrollmentOnly) {
			helper.getFeedItems(component);
		}
	},
	handleProFeedRefreshNeeded: function(component, event, helper) {
		helper.getFeedItems(component);
	}
})