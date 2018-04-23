({
    doInit : function(component, event, helper) {
		helper.getOutreachTypeOptions(component);
		helper.getRequestCategoryOptions(component);
		helper.getFunnelStepOptions(component);
		helper.getOutreachGroupOptions(component);
    	helper.setupCategoryBottomDetection(component);
    	helper.getUserData(component);
	},
   
 	/**************************************************************
	 * Commented by MP- to handle exception on UI caused by loading 
	 * of underscore JS library. Moved the helper callout to {doInit}
	 **************************************************************
	handleAfterScriptsLoaded: function(component, event, helper) {
		helper.setupCategoryBottomDetection(component);
	},
    **************************************************************/
    
	handleRequestCategorySearchTextChanged: function(component, event, helper) {
		var searchText = component.get('v.requestCategorySearchText');
		if ($A.util.isEmpty(searchText)) {
			component.set('v.showRequestCategorySearchOptions', false);
		} else {
			if (searchText.length > 1) {
				helper.searchRequestCategories(component, searchText);
			} else {
				component.set('v.showRequestCategorySearchOptions', false);
			}
		}
	},
	handleEAPFilterSelected: function(component, event, helper) {
		var eapFilter = event.getParam('eapFilter');
		if (eapFilter.category == 'RequestCategory__c') {
			helper.handleRequestCategorySelected(component, eapFilter);
		} else if (eapFilter.category == 'outreach_type__c') {
			helper.handleOutreachTypeSelected(component, eapFilter);
		} else if (eapFilter.category == 'FunnelStep__c') {
			helper.handleFunnelStepSelected(component, eapFilter);
		} else if (eapFilter.category == 'outreach_group__c') {
			helper.handleOutreachGroupSelected(component, eapFilter);
		}
	},
    unselectOT: function(component, event, helper){
        var option = component.get('v.option');
        helper.unselectOutreachType(component);         
    },
    unselectRC: function(component, event, helper){
        var option = component.get('v.option');
        helper.unselectRequestCategory(component);         
    }, 
    unselectFS: function(component, event, helper){
        var option = component.get('v.option');
        helper.unselectFunnelStep(component);         
    },
    unselectOG: function(component, event, helper){
        var option = component.get('v.option');
        helper.unselectOutreachGroup(component);         
    },
    unselectAllFilters: function(component, event, helper){
        helper.clearFilters(component);
    },
	saveChanges: function(component, event, helper) {
		helper.saveUserFilter(component);
	},
	handleUserIdsChange: function(component, event, helper) {
		var userIds = component.get('v.userIds');
		helper.clearFilters(component);
		if (!$A.util.isEmpty(userIds)) {
			if (userIds.length == 1) {
				helper.getUserFilter(component);
			}
		} else {
			helper.getUserFilter(component);
		}
	}
})