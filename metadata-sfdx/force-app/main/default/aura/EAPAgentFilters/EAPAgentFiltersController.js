({
	doInit : function(component, event, helper) {
		helper.getTeams(component);
		helper.getUserOptions(component);
	},
	handleUserSearchTextChanged: function(component, event, helper) {
		var searchText = component.get('v.userSearchText');
		if ($A.util.isEmpty(searchText)) {
			component.set('v.showUserSearchOptions', false);
		} else {
			if (searchText.length > 1) {
				helper.searchUsers(component, searchText);
			} else {
				component.set('v.showUserSearchOptions', false);
			}
		}
	},
	handleEAPFilterSelected: function(component, event, helper) {
		var eapFilter = event.getParam('eapFilter');
		if (eapFilter.category == 'User') {
			helper.handleUserSelected(component, eapFilter);
		}
	},
	handleSelectedTeamChange: function(component, event, helper) {
		component.set('v.userSearchText', null);
		helper.getUserOptions(component);
	},
	selectAll: function(component, event, helper) {
		var userOptions = component.get('v.userOptions');
		var selectedUsers = [];
		userOptions.forEach(function(option) {
			option.selected = 'yes';
			option.hide = 'yes';
			selectedUsers.push(option);
		});
		component.set('v.userOptions', userOptions);
		component.set('v.selectedUsers', selectedUsers);
		component.set('v.userIds', _.map(selectedUsers, function(selectedUser) {
			return selectedUser.value;
		}));
	},
	selectNone: function(component, event, helper) {
		var userOptions = component.get('v.userOptions');
		userOptions.forEach(function(option) {
			option.selected = 'no';
			option.hide = 'no';
		});
		component.set('v.userOptions', userOptions);
		component.set('v.selectedUsers', []);
		component.set('v.userIds', []);
	},
	hideSaveConfirmationToast: function(component, event, helper) {
		component.set('v.showSaveConfirmationToast', false);
	},
	handleEAPFilterSaved: function(component, event, helper) {
		component.set('v.showSaveConfirmationToast', true);
		setTimeout(
			$A.getCallback(function() {
				component.set('v.showSaveConfirmationToast', false);
			}), 3000
		);
	}
})