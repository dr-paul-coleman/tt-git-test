public class IncidentManagerController {
	
	@AuraEnabled
	public static MIIncident__c getIncident(Id incidentId) {

		MIIncident__c result;
		if (incidentId != null) {

			result = (MIIncident__c) Database.query(
				'Select ' + String.join(MIUtility.miIncidentFields, ', ') + ' From MIIncident__c '
				+ 'Where Id = :incidentId '
			);

		}
		return result;

	}

	@AuraEnabled
	public static List<IncidentChargeCardManagerController.Option> getCategorySubs(string category)
	{
		List<String> dependencies = UtilityDependentPicklist.GetDependentOptions('MIIncident__c', 'MICategory__c', 'MISubcategory__c', category);
		List<IncidentChargeCardManagerController.Option> opts = new List<IncidentChargeCardManagerController.Option>();


		for (String d : dependencies)
		{
			opts.add(new IncidentChargeCardManagerController.Option(d, d));
		}

		return opts;
	}

	@AuraEnabled
	public static becquerel_mi_incident_project_data__x getIncidentProjectData(Integer bidId)
	{
		becquerel_mi_incident_project_data__x ipd = null;
		List<becquerel_mi_incident_project_data__x> ipds = [SELECT bid_id__c, customer_is_disabled__c, pro_is_disabled__c
						FROM becquerel_mi_incident_project_data__x WHERE bid_id__c = :bidId];

		if(!ipds.isEmpty())
		{
			ipd = ipds[0];
		}

		return ipd;
	}

}