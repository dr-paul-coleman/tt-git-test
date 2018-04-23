({
	getTeams: function(component) {
		var action = component.get('c.getTeams');
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var teams = response.getReturnValue();
				component.set('v.teams', teams);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	getUserOptions: function(component) {
		var action = component.get('c.getUserOptions');
		action.setParams({
			team: component.get('v.selectedTeam')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var options = response.getReturnValue();
				component.set('v.userOptions', options);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	searchUsers: function(component, searchText) {
		var action = component.get('c.searchUsers');
		action.setParams({
			searchText: searchText,
			team: component.get('v.selectedTeam')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var userOptions = response.getReturnValue();
				component.set('v.userSearchOptions', userOptions);
				component.set('v.showUserSearchOptions', true);
				this.filterSearchResults(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	filterSearchResults: function(component) {
		var selectedUsers = component.get('v.selectedUsers');
		var searchResults = component.get('v.userSearchOptions');
		if (!$A.util.isEmpty(selectedUsers) && !$A.util.isEmpty(searchResults)) {
			selectedUsers.forEach(function(selectedUser) {
				var searchResult = _.findWhere(searchResults, {value: selectedUser.value});
				if (!$A.util.isEmpty(searchResult)) {
					searchResult.selected = 'yes';
					searchResult.hide = 'yes';
				}
			});
			component.set('v.userSearchOptions', searchResults);
		}
	},
	handleUserSelected: function(component, eapFilter) {
		var selectedUsers = component.get('v.selectedUsers');
		if (eapFilter.selected == 'yes') {
			selectedUsers.push(eapFilter);
			selectedUsers = _.sortBy(selectedUsers, 'label');
		} else if (eapFilter.selected == 'no') {
			selectedUsers = _.reject(selectedUsers, function(option) {
				return option.value == eapFilter.value;
			});
			if (component.get('v.showUserSearchOptions')) {
				this.makeOptionVisible(component, eapFilter.value, 'userSearchOptions');
			} else {
				this.makeOptionVisible(component, eapFilter.value, 'userOptions');
			}
		}
		component.set('v.selectedUsers', selectedUsers);
		component.set('v.userIds', _.map(selectedUsers, function(selectedUser) {
			return selectedUser.value;
		}));
	},
	makeOptionVisible: function(component, eapFilterValue, optionsVar) {
		var options = component.get('v.' + optionsVar);
		var option = _.findWhere(options, {value: eapFilterValue});
		if (!$A.util.isEmpty(option)) {
			option.hide = 'no';
			option.selected = 'no';
			component.set('v.' + optionsVar, options);
		}
	}
})