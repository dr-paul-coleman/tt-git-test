trigger QuoteTrigger on Quote__c (before insert, before update) {
    Id paRT = Schema.Sobjecttype.Quote__c .getRecordTypeInfosByName().get('Pro Assistance Record Type').getRecordTypeId();
    Id qsRT = Schema.Sobjecttype.Quote__c .getRecordTypeInfosByName().get('Quoting Service Record Type').getRecordTypeId();
    Map < Integer, Service__c> ServicesMap = new Map < Integer, Service__c > ();
    for (Quote__c  recordtoaddtoset: trigger.new) {
        if (null != recordtoaddtoset.bid_sav_available_service_id__c) {
            ServicesMap.put(Integer.valueOf(recordtoaddtoset.bid_sav_available_service_id__c), null);
        }
    }
    for (Service__c Serv: [SELECT Id, sav_available_service_id__c, ProAssistantSubscriptionType__c, ProAssistant__r.Id, ProAssistant__r.isactive FROM Service__c WHERE sav_available_service_id__c IN: ServicesMap.keySet()]) {
        if (null != Serv.sav_available_service_id__c ) {
            ServicesMap.put(Integer.valueOf(Serv.sav_available_service_id__c ), Serv);
        }
    }
    for (Quote__c  quote: trigger.new) {
        Integer serviceid = Integer.valueOf(quote.bid_sav_available_service_id__c);     
        If (serviceid > 0){
            if (null != ServicesMap.get(serviceid) && ServicesMap.get(serviceid).ProAssistantSubscriptionType__c == 'Full Pro Assistant'){
                quote.RecordTypeId = paRT;
            }
            else if (null != ServicesMap.get(serviceid) && ServicesMap.get(serviceid).ProAssistantSubscriptionType__c == 'Quoting Team Only'){
                quote.RecordTypeId = qsRT;
            }
        }
        quote.Service__c = (null == quote.Service__c  && null != serviceid && null != ServicesMap.get(serviceid)) ? ServicesMap.get(serviceid).Id : quote.Service__c;
        quote.OwnerId = (null != ServicesMap.get(serviceid) && null != ServicesMap.get(serviceid).ProAssistant__r.Id && ServicesMap.get(serviceid).ProAssistant__r.isactive) ? ServicesMap.get(serviceid).ProAssistant__r.Id : quote.OwnerId;
        quote.Status__c = trigger.isInsert ? 'Quoted' : (Trigger.oldMap.get(quote.id).Status__c != quote.ProAssistanceCalculatedStatus__c && quote.recordtypeid == paRT) ? quote.ProAssistanceCalculatedStatus__c : (Trigger.oldMap.get(quote.id).Status__c != quote.QuotingCalculatedStatus__c && quote.recordtypeid == qsRT) ? quote.QuotingCalculatedStatus__c : quote.Status__c;
        if (trigger.isUpdate && trigger.newMap.get(quote.id).Status__c != Trigger.oldMap.get(quote.id).Status__c){
            quote.LastStatusChangeDate__c = DateTime.Now();
            if (quote.QuoteClosedDate__c == null && ((quote.recordtypeid == paRT && (quote.Status__c == 'Cancelled' || quote.Status__c == 'Lost' || quote.Status__c == 'Inactive')) || (quote.recordtypeid == qsRT && (quote.Status__c == 'Cancelled' || quote.Status__c == 'Inactive' || quote.Status__c == 'Contact Fee Collected' || quote.Status__c == 'Contacted but No Intent')))) {
                quote.QuoteClosedDate__c = Date.Today();
            }
        }
    }
}