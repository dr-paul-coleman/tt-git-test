/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-12-01   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

@IsTest
private class QuickCaseControllerTest
{
	@IsTest
	static void testSubmitCase()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = new Case(Subject = 'Test', SuppliedEmail = 'testpro@test.com', SuppliedName = 'Test Pro', Origin = 'Email');

			QuickCaseController.QuickCaseResult res = QuickCaseController.submitCase(c);
			System.assertEquals('Success', res.result);
			System.assertNotEquals(null, res.caseRecord.Id);
			System.assertNotEquals(null, res.caseRecord.CaseNumber);
		}
	}

	@IsTest
	static void testSubmitCaseError()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = new Case(Subject = 'Test', SuppliedEmail = 'testpro@test', SuppliedName = 'Test Pro', Origin = 'Email');

			QuickCaseController.QuickCaseResult res = QuickCaseController.submitCase(c);
			System.assertNotEquals('Success', res.result);
		}
	}

	@IsTest
	static void testGetDefaultCase()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			Case c = QuickCaseController.getDefaultCase();
		}
	}

	@IsTest
	static void testGetOrigins()
	{
		User testUser = [SELECT id FROM User WHERE Profile.Name = '*Customer Success - TSL' AND IsActive = true LIMIT 1];
		System.runAs(testUser)
		{
			System.assertNotEquals(0, QuickCaseController.getCaseOrigins().size());
		}
	}
}