/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-14   Mendel Guillaume   Created
   1.1      2018-01-03   Mendel Guillaume   Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationContainerControllerTest
{
	@IsTest
	static void testCategorySettings()
	{
		User u = new User(Username = 'testThumbtack@testuser.com', Email = 'testThumbtack@testuser.com', FirstName = 'Test',
				LastName = 'User', ProfileId = UserInfo.getProfileId(), Alias = 'testusrx', TimeZoneSidKey = 'America/Phoenix',
				LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');

		System.runAs(u)
		{
			CategorizationSettings__c cs = CategorizationContainerController.getUserSettings();

			System.assertNotEquals(null, cs);
			System.assertEquals(false, cs.ShowCategoryTree__c);

			Test.startTest();

			CategorizationContainerController.toggleTreeSetting();

			cs = CategorizationContainerController.getUserSettings();

			Test.stopTest();

			System.assertEquals(true, cs.ShowCategoryTree__c, 'Settings not updated');
		}
	}
}