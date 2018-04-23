/*
  Copyright (c) 2017 Thumbtack.  All rights reserved.

 Change List:
 ------------

 Version    Date     Author            Description
 =======+===========+=================+=================================
 1.0     5/19/2017   Adam Schultz      Created
 1.1     10/04/2017  Paul Coleman      Added EAPRoleNameFilter label and getTeams mod
 =======+===========+=================+=================================*/
public class EAPAgentFiltersController {

	public static String[] roles = Label.EAPRoleNameFilter.replaceAll(' ','').split(',');

	@AuraEnabled
	public static List<String> getTeams()
	{

		List<String> result = new List<String> ();
		for (AggregateResult ar : [Select COUNT(Id), Team__c
						From User
						Where UserRole.DeveloperName IN :roles
						group by Team__c
						order by Team__c]) {

			String teamName = (String)ar.get('Team__c');
			if( null != teamName ) { result.add(teamName); }

		}
		return result;

	}
	
	@AuraEnabled
	public static List<Map<String, String>> getUserOptions(String team) {

		List<Map<String, String>> result = new List<Map<String, String>>();
		for (User u : Database.query(
						'Select Id, Name '
						+ 'From User '
						+ 'Where UserRole.DeveloperName IN :roles '
						+ (String.isNotBlank(team) ? 'And Team__c = :team ' : '')
						+ 'order by Name ')) {

			result.add(new Map<String, String> {
				'label' => u.Name,
				'value' => u.Id,
				'selected' => 'no',
				'hide' => 'no',
				'category' => 'User'
			});

		}
		return result;

	}

	@AuraEnabled
	public static List<Map<String, String>> searchUsers(String searchText, String team) {

		List<Map<String, String>> result = new List<Map<String, String>>();
		if (String.isNotBlank(searchText) && searchText.length() > 1) {

			String fuzzySearchText = '%' + searchText + '%';
			for (User u : Database.query(
							'Select Id, Name '
							+ 'From User '
							+ 'Where UserRole.DeveloperName IN :roles '
							+ 'And Name LIKE :fuzzySearchText '
							+ (String.isNotBlank(team) ? 'And Team__c = :team ' : '')
							+ 'order by Name ')) {

				result.add(new Map<String, String> {
					'label' => u.Name,
					'value' => u.Id,
					'selected' => 'no',
					'hide' => 'no',
					'category' => 'User'
				});

			}

		}
		return result;

	}

}