/*
  Copyright (c) 2017 Thumbtack.  All rights reserved.

 Change List:
 ------------

 Version    Date     Author            Description
 =======+===========+=================+=================================
 1.0     5/19/2017   Adam Schultz      Created
 =======+===========+=================+=================================*/
@isTest
private class EAPAgentFiltersControllerTest {
	
	@isTest static void getTeams_test() {

		Test.startTest();
		
		List<String> result = EAPAgentFiltersController.getTeams();

		Test.stopTest();

		System.assert(!result.isEmpty());

	}
	
	@isTest static void getUserOptions_test() {
		
		List<String> teams = EAPAgentFiltersController.getTeams();

		Test.startTest();

		List<Map<String, String>> result = EAPAgentFiltersController.getUserOptions(teams[0]);

		Test.stopTest();

		System.assert(!result.isEmpty());

	}

	@isTest static void searchUsers_test() {
		
		List<String> teams = EAPAgentFiltersController.getTeams();
		List<Map<String, String>> userOptions = EAPAgentFiltersController.getUserOptions(teams[0]);

		Test.startTest();

		List<Map<String, String>> result = EAPAgentFiltersController.searchUsers(userOptions[0].get('label'), teams[0]);

		Test.stopTest();

		System.assert(!result.isEmpty());

	}
	
}