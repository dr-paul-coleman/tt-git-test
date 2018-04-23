@isTest
public class QuoteTriggerTest {   
    @isTest static void testQuoteTrigger() {
        Id paRT = Schema.Sobjecttype.Quote__c.getRecordTypeInfosByName().get('Pro Assistance Record Type').getRecordTypeId();
        Id qsRT = Schema.Sobjecttype.Quote__c.getRecordTypeInfosByName().get('Quoting Service Record Type').getRecordTypeId();
        Id servRT = Schema.Sobjecttype.Service__c.getRecordTypeInfosByName().get('Pro Assistance Service').getRecordTypeId();
        User testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        
        List<Service__c> servs = new List<Service__c>();
        for(Integer j=1;j<11;j++) {
            Service__c s = new Service__c(
                Name='Test Service' + j,
                RecordTypeId = servRT,
                OwnerId = testUser.Id,
                ProAssistantSubscriptionType__c = (j < 6 ? 'Full Pro Assistant' : 'Quoting Team Only'),
                ProAssistant__c = testUser.Id,
                sav_available_service_id__c = j
            );
            servs.add(s);
        }
        insert servs;
        
        List<Quote__c> qs = new List<Quote__c>();
        for(Integer i=1;i<12;i++) {
            Quote__c q = new Quote__c(
                Name='Test Quote' + i,
                OwnerId = testUser.Id,
                Status__c = 'Quoted',
                bid_sav_available_service_id__c = i
            );
            qs.add(q);
        }
        
        System.runAs(testUser) {
            
            Test.startTest();
            insert qs;            
            //test for no service__c.sav_available_service_id__c match (one more quote__c is inserted than service__c)
            System.assert(null==[SELECT Id, Service__c FROM Quote__c WHERE bid_sav_available_service_id__c = 11].Service__c, 'Test for bid_sav_available_service_id__c not found (no Service__c match) failed.');            
        }
        
        for( Quote__c proQuote: [SELECT Id, recordTypeId, bid_sav_available_service_id__c, service__c, service__r.sav_available_service_id__c, service__r.proAssistantSubscriptionType__c FROM Quote__c WHERE bid_sav_available_service_id__c < 10]){
            //Id recordIdCheck = proQuote.RecordTypeId == paRt? paRt : proQuote.RecordTypeId == qsRt ? qsRt : null;
            System.assert(proQuote.RecordTypeId == (proQuote.RecordTypeId == paRt? paRt : proQuote.RecordTypeId == qsRt ? qsRt : null), 'Quote__c.RecordTypeId not properly set based on Service.ProAssistantSubscriptionType__c: ' + JSON.serialize(proQuote) );
            System.assert(proQuote.Service__c!=null, 'Quote__c not properly associated to a Service__c: ' + JSON.serialize(proQuote) );
            System.assert(proQuote.bid_sav_available_service_id__c == proQuote.Service__r.sav_available_service_id__c, 'Quote.bid_sav_available_service_id__c does not match Quote.Service__r.sav_available_service_id__c: ' + JSON.serialize(proQuote));
        }
        
        qs[0].Status__c='Cancelled';
        qs[1].Status__c='Cancelled';
        update new Quote__c[]{qs[0],qs[1]};
            
            for( Quote__c proQuote: [SELECT Id,Service__c,LastStatusChangeDate__c,QuoteClosedDate__c ,OwnerId,bid_sav_available_service_id__c FROM Quote__c WHERE bid_sav_available_service_id__c < 3 LIMIT 2]){
                System.assert(null!=proQuote.Service__c, 'Quote__c not properly associated to an Service: ' + JSON.serialize(proQuote) );
                System.assert(proQuote.LastStatusChangeDate__c != null, 'LastStatusChangeDate__c is null');
                System.assert(proQuote.QuoteClosedDate__c != null, 'QuoteClosedDate__c is null');
            }
        
        Test.stopTest();
    }
}