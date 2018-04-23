({
	setupCategoryBottomDetection: function(component) {
		var categoryDropdownBoxElem = component.find('categoryDropdownBox').getElement();
		var v_this = this;
		$(categoryDropdownBoxElem).scroll($A.getCallback(function() {
			if($(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight) {
	            v_this.getRequestCategoryOptions(component, true);
	        }
		}));
	},
	getOutreachGroupOptions : function(component) {
		var action = component.get('c.getOutreachGroupOptions');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var outreachGroupOptions = response.getReturnValue();
				component.set('v.outreachGroupOptions', outreachGroupOptions);
				this.checkToGetUserFilter(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getOutreachTypeOptions : function(component) {
		var action = component.get('c.getOutreachTypeOptions');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var outreachTypeOptions = response.getReturnValue();
				component.set('v.outreachTypeOptions', outreachTypeOptions);
				this.checkToGetUserFilter(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getSelectedOutreachTypes: function(component) {
		var result = [];
		var selectedOutreachTypes = component.get('v.selectedOutreachTypes');
		if (!$A.util.isEmpty(selectedOutreachTypes)) {
			selectedOutreachTypes.forEach(function(option) {
				result.push(option.value);
			});
			if ($A.util.isEmpty(result)) {
				result = null;
			}
		}
		return result;
	},
	getRequestCategoryOptions: function(component, getMore, applyUserFilter) {
		component.set('v.showCategorySpinner', true);
		var action = component.get('c.getRequestCategoryOptions');
		var existingOptions = component.get('v.requestCategoryOptions');
		var selectedOutreachTypes = this.getSelectedOutreachTypes(component);
		var params = {
			outreachTypes: selectedOutreachTypes
		};
		if (!$A.util.isEmpty(existingOptions) && getMore) {
			var existingOption = existingOptions[existingOptions.length - 1];
			params.lastCategory = existingOption.label;
		}
		action.setParams(params);
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.showCategorySpinner', false);
				var options = response.getReturnValue();
				if (getMore && !$A.util.isEmpty(existingOptions)) {
					options.forEach(function(option) {
						existingOptions.push(option);
					});
					component.set('v.requestCategoryOptions', existingOptions);
				} else {
					component.set('v.requestCategoryOptions', options);
				}
				this.hideSelectedCategories(component);
				if (applyUserFilter) {
					this.applyUserFilterToRequestCategory(component);
				}
				this.checkToGetUserFilter(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	hideSelectedCategories: function(component) {
		var selectedCategories = component.get('v.selectedCategories');
		if (!$A.util.isEmpty(selectedCategories) && selectedCategories.length > 0) {
			var requestCategoryOptions = component.get('v.requestCategoryOptions');
			selectedCategories.forEach(function(selectedCat) {
				var matchedCats = _.where(requestCategoryOptions, {value: selectedCat.value});
				matchedCats.forEach(function(matchedCat) {
					matchedCat.selected = 'yes';
					matchedCat.hide = 'yes';
				});
			});
			component.set('v.requestCategoryOptions', requestCategoryOptions);
		}
	},
	getFunnelStepOptions: function(component) {
		var action = component.get('c.getFunnelStepOptions');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var funnelStepOptions = response.getReturnValue();
				component.set('v.funnelStepOptions', funnelStepOptions);
				this.checkToGetUserFilter(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	searchRequestCategories: function(component, searchText) {
		var action = component.get('c.searchRequestCategories');
		action.setParams({
			searchText: searchText
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var requestCategoryOptions = response.getReturnValue();
				component.set('v.requestCategorySearchOptions', requestCategoryOptions);
				component.set('v.showRequestCategorySearchOptions', true);
				this.filterSearchResults(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	filterSearchResults: function(component) {
		var selectedCategories = component.get('v.selectedCategories');
		var searchResults = component.get('v.requestCategorySearchOptions');
		if (!$A.util.isEmpty(selectedCategories) && !$A.util.isEmpty(searchResults)) {
			selectedCategories.forEach(function(selectedCategory) {
				var searchResult = _.findWhere(searchResults, {value: selectedCategory.value});
				if (!$A.util.isEmpty(searchResult)) {
					searchResult.selected = 'yes';
					searchResult.hide = 'yes';
				}
			});
			component.set('v.requestCategorySearchOptions', searchResults);
		}
	},
	makeOptionVisible: function(component, eapFilterValue, optionsVar) {
		var options = component.get('v.' + optionsVar);
		var option = _.findWhere(options, {value: eapFilterValue});
		if (!$A.util.isEmpty(option)) {
			option.hide = 'no';
			option.selected = 'no';
			component.set('v.' + optionsVar, options);
		}
	},
	handleOutreachTypeSelected: function(component, eapFilter) {
		var selectedOutreachTypes = component.get('v.selectedOutreachTypes');
		if (eapFilter.selected == 'yes') {
			selectedOutreachTypes.push(eapFilter);
		} else if (eapFilter.selected == 'no') {
			selectedOutreachTypes = _.reject(selectedOutreachTypes, function(option) {
				return option.value == eapFilter.value;
			});
		}
		component.set('v.selectedOutreachTypes', selectedOutreachTypes);
		this.getRequestCategoryOptions(component);
		if (component.get('v.showRequestCategorySearchOptions')) {
			this.searchRequestCategories(component, component.get('v.requestCategorySearchText'));
		}
	},
	handleFunnelStepSelected: function(component, eapFilter) {
		var selectedFunnelSteps = component.get('v.selectedFunnelSteps');
		if (eapFilter.selected == 'yes') {
			selectedFunnelSteps.push(eapFilter);
		} else if (eapFilter.selected == 'no') {
			selectedFunnelSteps = _.reject(selectedFunnelSteps, function(option) {
				return option.value == eapFilter.value;
			});
		}
		component.set('v.selectedFunnelSteps', selectedFunnelSteps);
	},
	handleOutreachGroupSelected: function(component, eapFilter) {
		var selectedOutreachGroups = component.get('v.selectedOutreachGroups');
		if (eapFilter.selected == 'yes') {
			selectedOutreachGroups.push(eapFilter);
		} else if (eapFilter.selected == 'no') {
			selectedOutreachGroups = _.reject(selectedOutreachGroups, function(option) {
				return option.value == eapFilter.value;
			});
		}
		component.set('v.selectedOutreachGroups', selectedOutreachGroups);
	},
	handleRequestCategorySelected: function(component, eapFilter) {
		var selectedCategories = component.get('v.selectedCategories');
		if (eapFilter.selected == 'yes') {
			selectedCategories.push(eapFilter);
			selectedCategories = _.sortBy(selectedCategories, 'label');
		} else if (eapFilter.selected == 'no') {
			selectedCategories = _.reject(selectedCategories, function(option) {
				return option.value == eapFilter.value;
			});
			if (component.get('v.showRequestCategorySearchOptions')) {
				this.makeOptionVisible(component, eapFilter.value, 'requestCategorySearchOptions');
			} else {
				this.makeOptionVisible(component, eapFilter.value, 'requestCategoryOptions');
			}
		}
		component.set('v.selectedCategories', selectedCategories);
	},
	checkToGetUserFilter: function(component) {
		var shouldFilterFromUser = component.get('v.shouldFilterFromUser');
		if (shouldFilterFromUser) {
			var numberOfListsPopulated = component.get('v.numberOfListsPopulated');
			numberOfListsPopulated++;
			if (numberOfListsPopulated == 3) {
				component.set('v.shouldFilterFromUser', false);
				this.getUserFilter(component);
			} else {
				component.set('v.numberOfListsPopulated', numberOfListsPopulated);
			}
		}
	},
    unselectOutreachType: function(component){
        component.set('v.selectedOutreachTypes', []);
        this.clearFilter(component, 'outreachTypeOptions');
    },
    unselectRequestCategory: function(component){
        component.set('v.selectedCategories', []);
        this.clearFilter(component, 'requestCategoryOptions');
    },
    unselectFunnelStep: function(component){
        component.set('v.selectedFunnelSteps', []);
        this.clearFilter(component, 'funnelStepOptions');
    },
    unselectOutreachGroup: function(component){
        component.set('v.selectedOutreachGroups', []);
        this.clearFilter(component, 'outreachGroupOptions');
    },
	clearFilters: function(component) {
		component.set('v.selectedOutreachTypes', []);
		component.set('v.selectedCategories', []);
		component.set('v.selectedFunnelSteps', []);
		component.set('v.selectedOutreachGroups', []);
		this.clearFilter(component, 'outreachTypeOptions');
		this.clearFilter(component, 'requestCategoryOptions');
		this.clearFilter(component, 'funnelStepOptions');
		this.clearFilter(component, 'outreachGroupOptions');
	},
	clearFilter: function(component, filterName) {
		var filterList = component.get('v.' + filterName);
		filterList.forEach(function(filterItem) {
			filterItem.selected = 'no';
			filterItem.hide = 'no';
		});
		component.set('v.' + filterName, filterList);
	},
	applyUserFilter: function(component) {
		var userFilter = component.get('v.userFilter');
		if (!$A.util.isEmpty(userFilter)) {
			if (!$A.util.isEmpty(userFilter.outreach_type__c)) {
				this.applyUserFilterToOutreachType(component);
			} else if (!$A.util.isEmpty(userFilter.RequestCategory__c)) {
				this.applyUserFilterToRequestCategory(component);
			}
			if (!$A.util.isEmpty(userFilter.FunnelStep__c)) {
				this.applyUserFilterToFunnelStep(component);
			}
			if (!$A.util.isEmpty(userFilter.outreach_group__c)) {
				this.applyUserFilterToOutreachGroup(component);
			}
		}
	},
	applyUserFilterToOutreachType: function(component) {
		var userFilter = component.get('v.userFilter');
		component.set('v.selectedOutreachTypes', userFilter.outreach_type__c);
		var outreachTypeOptions = component.get('v.outreachTypeOptions');
		userFilter.outreach_type__c.forEach(function(selectedOption) {
			var option = _.findWhere(outreachTypeOptions, {value: selectedOption.value});
			if (!$A.util.isEmpty(option)) {
				option.selected = 'yes';
			}
		});
		component.set('v.outreachTypeOptions', outreachTypeOptions);
		this.getRequestCategoryOptions(component, false, true);
	},
	applyUserFilterToRequestCategory: function(component) {
		var userFilter = component.get('v.userFilter');
		component.set('v.selectedCategories', userFilter.RequestCategory__c);
		var requestCategoryOptions = component.get('v.requestCategoryOptions');
		userFilter.RequestCategory__c.forEach(function(selectedOption) {
			var option = _.findWhere(requestCategoryOptions, {value: selectedOption.value});
			if (!$A.util.isEmpty(option)) {
				option.selected = 'yes';
				option.hide = 'yes';
			}
		});
		component.set('v.requestCategoryOptions', requestCategoryOptions);
	},
	applyUserFilterToFunnelStep: function(component) {
		var userFilter = component.get('v.userFilter');
		component.set('v.selectedFunnelSteps', userFilter.FunnelStep__c);
		var funnelStepOptions = component.get('v.funnelStepOptions');
		userFilter.FunnelStep__c.forEach(function(selectedOption) {
			var option = _.findWhere(funnelStepOptions, {value: selectedOption.value});
			if (!$A.util.isEmpty(option)) {
				option.selected = 'yes';
			}
		});
		component.set('v.funnelStepOptions', funnelStepOptions);
	},
	applyUserFilterToOutreachGroup: function(component) {
		var userFilter = component.get('v.userFilter');
		component.set('v.selectedOutreachGroups', userFilter.outreach_group__c);
		var outreachGroupOptions = component.get('v.outreachGroupOptions');
		userFilter.outreach_group__c.forEach(function(selectedOption) {
			var option = _.findWhere(outreachGroupOptions, {value: selectedOption.value});
			if (!$A.util.isEmpty(option)) {
				option.selected = 'yes';
			}
		});
		component.set('v.outreachGroupOptions', outreachGroupOptions);
	},
	getUserFilter: function(component) {
		var userIds = component.get('v.userIds');
		var allowBlankUserIds = component.get('v.allowBlankUserIds');
		var userId;
		if (!$A.util.isEmpty(userIds) && userIds.length == 1) {
			userId = userIds[0];
		}
		if (allowBlankUserIds || !$A.util.isEmpty(userId)) {
			var action = component.get('c.getUserFilter');
			action.setParams({
				userId: userId
			});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === 'SUCCESS') {
					var userFilter = response.getReturnValue();
					component.set('v.userFilter', userFilter);
					this.applyUserFilter(component);
				} else if (state === 'ERROR') {
					// error handling goes here
				}
			});
			$A.enqueueAction(action);
		}
	},
	saveUserFilter: function(component) {
		var userFilter = {
			outreach_type__c: component.get('v.selectedOutreachTypes'),
			RequestCategory__c: component.get('v.selectedCategories'),
			FunnelStep__c: component.get('v.selectedFunnelSteps'),
			outreach_group__c: component.get('v.selectedOutreachGroups')
		};
		var userIds = component.get('v.userIds');
		var allowBlankUserIds = component.get('v.allowBlankUserIds');
		if (allowBlankUserIds || !$A.util.isEmpty(userIds)) {
			var action = component.get('c.saveUserFilter');
			action.setParams({
				filter: userFilter,
				userIds: component.get('v.userIds')
			});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === 'SUCCESS') {
					var appEvent = $A.get('e.c:EAPFilterSaved');
					appEvent.fire();
				} else if (state === 'ERROR') {
					// error handling goes here
				}
			});
			$A.enqueueAction(action);
		}
	},

	getUserData: function(component)
	{
        var action = component.get('c.getUserInfo');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.user', response.getReturnValue());
            } else if (state === 'ERROR') {
                // error handling goes here
                console.log('error - getUserData')
            }
        });
        $A.enqueueAction(action);
    },
})