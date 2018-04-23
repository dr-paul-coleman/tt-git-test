({
	toggleVisibility : function(component, event, helper) {
		component.set('v.isOpen', !component.get('v.isOpen'));
		var bodyContainer = component.find('accordion-body').getElement();
		$(bodyContainer).slideToggle();
	}
})