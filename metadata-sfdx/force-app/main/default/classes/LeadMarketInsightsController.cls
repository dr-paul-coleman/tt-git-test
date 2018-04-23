/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-16   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
public with sharing class LeadMarketInsightsController
{
	@AuraEnabled
	public static ReportUtility.TabularReport getReport(String reportId, String filters)
	{
		ReportUtility.TabularReport tabRep = null;

		if(reportId.startsWith('00O'))
		{
			tabRep = ReportUtility.getReport(reportId, filters);
		}
		else
		{
			List<Report> reports = [SELECT Id FROM Report WHERE Name = :reportId LIMIT 1];

			if (!reports.isEmpty())
			{
				tabRep = ReportUtility.getReport(reports[0].Id, filters);
			}
		}

		//Remove duplicate entries from report
		if (tabRep != null && !tabRep.dataRows.isEmpty())
		{
			List<List<ReportUtility.CellData>> dataRows = new List<List<ReportUtility.CellData>>();
			Set<String> keys = new Set<String>();

			for (List<ReportUtility.CellData> row : tabRep.dataRows)
			{
				String key = String.valueOf(row);

				if (!keys.contains(key))
				{
					keys.add(key);
					dataRows.add(row);
				}
			}

			tabRep.dataRows = dataRows;
		}

		return tabRep;
	}
}