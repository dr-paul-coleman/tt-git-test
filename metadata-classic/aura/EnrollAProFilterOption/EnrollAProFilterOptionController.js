({
	toggleSelect : function(component, event, helper) {
		var option = component.get('v.option');
		if (option.selected === 'no') {
			option.selected = 'yes';
			option.hide = 'yes';
		} else {
			option.selected = 'no';
			option.hide = 'no';
		}
		component.set('v.option', option);
		var compEvent = component.getEvent('EAPFilterSelected');
		compEvent.setParams({
			eapFilter: option
		});
		compEvent.fire();
	}
})