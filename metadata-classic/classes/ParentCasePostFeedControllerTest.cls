/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-12-06   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

@IsTest
private class ParentCasePostFeedControllerTest
{
	@IsTest
	static void test()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Suggestion Box');
			insert c;

			Test.startTest();

			ParentCasePostFeedController.submit('Testing', c.Id);

			Test.stopTest();

			System.assertEquals(1, [SELECT Id FROM FeedItem WHERE ParentId = :c.Id].size());
		}
	}

	@IsTest
	static void testError()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			System.assertNotEquals('Success', ParentCasePostFeedController.submit('Testing', null));

			Test.stopTest();
		}
	}
}