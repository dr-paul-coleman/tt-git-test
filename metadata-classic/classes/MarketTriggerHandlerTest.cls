@isTest
private class MarketTriggerHandlerTest {

    @isTest static void updateMarkets_test() {

        Test.startTest();
		
        RequestCategory__c RC = new RequestCategory__c(Name = 'Salesforce Dev', rca_request_category_id__c = '23');
        Insert RC;
        
        Market__c market = new Market__c (
            rca_name__c = 'Salesforce Dev',
            zip_cbsa_name__c = 'Utah',
            Deprioritized__c = false,
            TakeaLeadEnabled__c = false,
            rca_request_category_id__c = '23',
            zip_cbsa_code__c = '24',
            outreach_type__c = 'Early_enrollment'
        );
        insert market;
        
        market = [Select Id, MarketID__c, RequestCategory__r.rca_request_category_id__c From Market__c Where Id = :market.Id];
		market.RequestCategory__c = null;
        
        update market;
        
        System.assertEquals('23-24', market.MarketID__c);
        system.assertEquals('23', market.RequestCategory__r.rca_request_category_id__c);
        
        Test.stopTest();

    }
    
}