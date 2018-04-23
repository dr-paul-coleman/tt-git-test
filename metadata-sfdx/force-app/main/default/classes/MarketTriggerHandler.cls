public class MarketTriggerHandler {

	public static void updateMarkets(List<Market__c> newRecords) {
		
		for (Market__c market : newRecords) {

			market.MarketId__c = market.rca_request_category_id__c + '-' + market.zip_cbsa_code__c;
			market.Name = market.MarketID__c;

		}

	}

	public static void populateCategory(List<Market__c> newRecords) {

		List<String> catIds = new List<String> ();
		List<Market__c> marketsMissingCats = new List<Market__c> ();
		for (Market__c market : newRecords) {

			if (market.RequestCategory__c == null && market.rca_request_category_id__c != null) {
				system.debug('Request Category null');
				catIds.add(market.rca_request_category_id__c);
				marketsMissingCats.add(market);
			}
		}
		if (!catIds.isEmpty()) {
			system.debug('Cat Ids:'+catIds);
			Map<String, Id> catMap = new Map<String, Id> ();
			for (RequestCategory__c cat : [Select Id, rca_request_category_id__c From RequestCategory__c Where rca_request_category_id__c IN :catIds]) {
                catMap.put(cat.rca_request_category_id__c, cat.Id);
            }
			for (Market__c market : marketsMissingCats) {
                market.RequestCategory__c = catMap.get(market.rca_request_category_id__c);
            }
        }
	}

}