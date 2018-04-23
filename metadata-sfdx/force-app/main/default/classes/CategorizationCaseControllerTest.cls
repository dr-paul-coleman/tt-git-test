/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-01   Mendel Guillaume   Created
   1.1      2018-01-03   Mendel Guillaume   Updated to follow template/guidelines
   ========+============+=================+===============================================
*/

@IsTest
private class CategorizationCaseControllerTest
{
	@TestSetup
	static void createData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
			insert customer;

			Case c = new Case(AccountId = customer.Id, Subject='Test Case', Status = 'New', Origin = 'Suggestion Box' );
			insert c;
		}
	}

	@IsTest
	static void testGetStatuses()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.startTest();

			List<CategorizationCaseController.Option> options = CategorizationCaseController.getCaseStatuses();

			Test.stopTest();

			System.assert(options.size() > 0, 'No case statuses');
		}
	}

	@IsTest
	static void testGetCase()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, Subject FROM Case];

			Test.startTest();

			String subject = CategorizationCaseController.getCase(c.Id).Subject;

			Test.stopTest();

			System.assertEquals(c.Subject, subject, 'Wrong case returned');
		}
	}

	@IsTest
	static void testUpdateCase()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, Subject FROM Case];
			c.Subject = 'Updated Case';

			Test.startTest();

			String result = CategorizationCaseController.updateCase(c);

			Test.stopTest();

			System.assertEquals('Success', result, 'Update failed');
		}
	}

	@IsTest
	static void testUpdateCaseError()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, Subject FROM Case];
			c.Subject = 'Updated Case';

			Test.startTest();
			delete c;
			String result  = CategorizationCaseController.updateCase(c);
			Test.stopTest();

			System.assertNotEquals('Success', result, 'Updated');
		}
	}
}