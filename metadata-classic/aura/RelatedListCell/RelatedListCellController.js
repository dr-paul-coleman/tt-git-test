({
	doInit : function(component, event, helper) {
		var record = component.get('v.record');
		var fieldName = component.get('v.fieldName');
		var fieldValue = record[fieldName];
		component.set('v.fieldValue', fieldValue);
	}
})