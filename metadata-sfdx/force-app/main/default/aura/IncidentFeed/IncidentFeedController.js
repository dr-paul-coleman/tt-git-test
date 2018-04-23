({
	doInit : function(component, event, helper) {
		helper.getFeed(component);
	},
	refreshFeed: function(component, event, helper) {
		helper.getFeed(component);
	},
	selectFilter: function(component, event, helper) {
		var filter = event.currentTarget.dataset.filter;
		component.set('v.filter', filter);
		helper.getFeed(component);
	}
})