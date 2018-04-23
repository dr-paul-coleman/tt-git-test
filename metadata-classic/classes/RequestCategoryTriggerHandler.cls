public class RequestCategoryTriggerHandler {

	public static void handleUpdate(List<RequestCategory__c> newRecords, Map<Id, RequestCategory__c> oldMap) {

		Boolean shouldExecuteOutreachTypeBatchJob = false;
		List<RequestCategory__c> catsEnabled = new List<RequestCategory__c> ();
		for (RequestCategory__c cat : newRecords) {

			RequestCategory__c oldCat = oldMap.get(cat.Id);
			if (cat.outreach_type__c != oldCat.outreach_type__c && String.isNotBlank(cat.outreach_type__c)) {

				cat.OutreachTypeChanged__c = true;
				shouldExecuteOutreachTypeBatchJob = true;

			}
			if (cat.outreach_type__c != oldCat.outreach_type__c && cat.outreach_type__c == 'product_enabled') {

				catsEnabled.add(cat);

			}

		}
		if (shouldExecuteOutreachTypeBatchJob) {

			Database.executeBatch(new RequestCategoryOutreachTypeBatch());

		}
		if (!catsEnabled.isEmpty()) {

			disableMarkets(catsEnabled);

		}

	}

	private static void disableMarkets(List<RequestCategory__c> newRecords) {

		if (!newRecords.isEmpty()) {

			Map<Id, RequestCategory__c> catMap = new Map<Id, RequestCategory__c> (newRecords);
			List<Market__c> markets = [SELECT Id, EnrollAProEnabled__c FROM Market__c Where RequestCategory__c IN :catMap.keySet()];
            for (Market__c market : markets) {

				market.EnrollAProEnabled__c = false;

			}
			update markets;

		}

	}

}