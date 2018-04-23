({
	doInit : function(component, event, helper) {
		helper.getRelatedListInfo(component);
	},
	showMore: function(component, event, helper) {
		var pageNumber = component.get('v.pageNumber');
		pageNumber++;
		component.set('v.pageNumber', pageNumber);
		helper.getRecords(component, true);
	}
})