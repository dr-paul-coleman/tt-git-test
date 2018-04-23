({
	handleEnrollPro: function(component, event, helper) {
		helper.enrollAPro(component);
	},
	hideErrorToast: function(component, event, helper) {
		component.set('v.showErrorToast', false);
	}
})