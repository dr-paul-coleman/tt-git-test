({
	getRelatedListInfo: function(component) {
		var setting = component.get('v.setting');
		var recordId = component.get('v.recordId');
		var action = component.get('c.getRelatedListInfo');
		action.setParams({
			parentObjectName: setting.parentObjectName, 
			parentReferenceFieldName: setting.parentReferenceFieldName, 
			recordId: recordId, 
			objectName: setting.objectName,
			fieldSetName: setting.queryFieldSetName
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var listInfo = response.getReturnValue();
				component.set('v.referenceId', listInfo.referenceId);
				component.set('v.fields', listInfo.fields);
				this.getFieldNames(component);
				this.getRecords(component, false);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getFieldNames: function(component) {
		var fields = component.get('v.fields');
		var fieldNames = [];
		fields.forEach(function(field) {
			fieldNames.push(field.name);
		});
		component.set('v.fieldNames', fieldNames);
	},
	getRecords: function(component, appendRecords) {
		component.set('v.showSpinner', true);
		var setting = component.get('v.setting');
		var fieldNames = component.get('v.fieldNames');
		var action = component.get('c.getRecords');
		action.setParams({
			objectName: setting.objectName, 
			relationshipFieldName: setting.relationshipFieldName, 
			referenceId: component.get('v.referenceId'), 
			queryFields: fieldNames, 
			orderField: setting.orderFieldName, 
			sortDirection: setting.sortDirection, 
			recordsPerPage: setting.recordsPerPage, 
			pageNumber: component.get('v.pageNumber')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var result = response.getReturnValue();
				var displayShowMoreButton = !$A.util.isEmpty(result) && result.length == setting.recordsPerPage;
				component.set('v.displayShowMoreButton', displayShowMoreButton);
				if (appendRecords) {
					var records = component.get('v.records');
					result.forEach(function(resultRecord) {
						records.push(resultRecord);
					});
					component.set('v.records', records);
				} else {
					component.set('v.records', result);
				}
				component.set('v.showSpinner', false);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})