/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-16   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

@IsTest
private class LeadMarketInsightsControllerTest
{
	@IsTest (SeeAllData='true')
	static void testReportById()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			List<Report> reports = [SELECT Id FROM Report WHERE Name = 'UNIT TEST REPORT - DO NOT DELETE/MODIFY' LIMIT 1];

			if (!reports.isEmpty())
			{
				List<Lead> leads = new List<Lead>();

				leads.add(new Lead(FirstName = 'Test1', LastName = 'Lead1', Company = 'TestCompanyxyz'));
				leads.add(new Lead(FirstName = 'Test2', LastName = 'Lead2', Company = 'TestCompanyxyz'));
				leads.add(new Lead(FirstName = 'Test3', LastName = 'Lead3', Company = 'TestCompanyxyz'));

				insert leads;

				Test.startTest();

				ReportUtility.TabularReport tabReport = LeadMarketInsightsController.getReport(reports[0].Id, '{"COMPANY":"TestCompanyxyz"}');

				Test.stopTest();

				System.assert(tabReport.dataRows.size() >= 3, 'Report failed');
			}
		}
	}

	@IsTest (SeeAllData='true')
	static void testReportByName()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			List<Lead> leads = new List<Lead>();

			leads.add(new Lead(FirstName = 'Test1', LastName = 'Lead1', Company = 'TestCompanyxyz'));
			leads.add(new Lead(FirstName = 'Test2', LastName = 'Lead2', Company = 'TestCompanyxyz'));
			leads.add(new Lead(FirstName = 'Test3', LastName = 'Lead3', Company = 'TestCompanyxyz'));

			insert leads;

			Test.startTest();

			ReportUtility.TabularReport tabReport = LeadMarketInsightsController.getReport('UNIT TEST REPORT - DO NOT DELETE/MODIFY', '"COMPANY":"TestCompanyxyz"');

			Test.stopTest();

			System.assert(tabReport.dataRows.size() >= 3, 'Report failed');
		}
	}
}