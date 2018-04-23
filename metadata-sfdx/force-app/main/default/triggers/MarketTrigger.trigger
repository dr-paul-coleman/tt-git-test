trigger MarketTrigger on Market__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    if (Trigger.isBefore) {
        
        if (Trigger.isInsert) {
           
            MarketTriggerHandler.updateMarkets(Trigger.new);
            MarketTriggerHandler.populateCategory(Trigger.new);
            
        }
        if (Trigger.isUpdate) {
           
          MarketTriggerHandler.populateCategory(Trigger.new);
            
        }

    }
    
}