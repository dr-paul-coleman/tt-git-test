/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-13   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class ReportUtility
{
	public static TabularReport getReport(Id reportId, String params)
	{
		TabularReport tabReport = new TabularReport();
		Reports.ReportMetadata repMetadata = Reports.ReportManager.describeReport(reportId).getReportMetadata();

		if(String.isNotBlank(params))
		{
			try
			{
				if(!params.startsWith('{'))
				{
					params = '{' + params;
				}

				if(!params.endsWith('}'))
				{
					params += '}';
				}

				List<Reports.ReportFilter> filters = new List<Reports.ReportFilter>();
				Map<String, Object> paramsMap = (Map<String, Object>)JSON.deserializeUntyped(params);

				for(String key : paramsMap.keySet())
				{
					Reports.ReportFilter f = new Reports.ReportFilter();
					f.setColumn(key);
					f.setValue('"' + (String)paramsMap.get(key) + '"');
					f.setOperator('equals');

					filters.add(f);
				}

				if (!filters.isEmpty())
				{
					repMetadata.setReportFilters(filters);
				}
			}
			catch (Exception ex)
			{
				System.debug(ex);
			}
		}

		Reports.ReportResults results = Reports.ReportManager.runReport(reportId, repMetadata, true);
		List<String> detailColumns = repMetadata.getDetailColumns();
		Reports.ReportExtendedMetadata repExtendedMetadata = results.getReportExtendedMetadata();
		Map<String, Reports.DetailColumn> detailColumnMap = repExtendedMetadata.getDetailColumnInfo();
		Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');
		List<Reports.ReportDetailRow> reportDetailRows = factWithDetails.getRows();

		//Get table column name, label and data type
		for(String columnName : detailColumns)
		{
			Reports.DetailColumn dc = detailColumnMap.get(columnName);

			tabReport.columns.add(new FieldDef(dc.getName(), dc.getLabel(), dc.getDataType().name()));
		}

		for(Reports.ReportDetailRow rdr : reportDetailRows)
		{
			List<CellData> row = new List<CellData>();
			Integer counter = 0;

			for(Reports.ReportDataCell cell : rdr.getDataCells())
			{
				row.add(new CellData((String)cell.getLabel(), cell.getValue(), tabReport.columns[counter].dataType));
				counter++;
			}

			tabReport.dataRows.add(row);
		}

		return tabReport;
	}

	public class TabularReport implements LightningInnerClass
	{
		@AuraEnabled
		public List<FieldDef> columns{get;set;}
		@AuraEnabled
		public List<List<CellData>> dataRows{get;set;}

		public TabularReport()
		{
			this.columns = new List<ReportUtility.FieldDef>();
			this.dataRows = new List<List<ReportUtility.CellData>>();
		}
	}

	public class FieldDef
	{
		@AuraEnabled
		public String name{get;set;}
		@AuraEnabled
		public String label{get;set;}
		@AuraEnabled
		public String dataType{get;set;}

		public FieldDef(String fieldName, String fieldLabel, String dataType)
		{
			this.dataType = dataType;
			this.label = fieldLabel;
			this.name = fieldName;
		}
	}

	public class CellData
	{
		@AuraEnabled
		public Object value{get;set;}
		@AuraEnabled
		public String label{get;set;}
		@AuraEnabled
		public String dataType {get;set;}
		@AuraEnabled
		public Boolean isHyperlink{get;set;}

		public CellData(String fieldLabel, Object fieldValue, String dataType)
		{
			this.dataType = dataType;
			this.label = fieldLabel;
			this.value = fieldValue;
			this.isHyperlink = false;
		}
	}
}