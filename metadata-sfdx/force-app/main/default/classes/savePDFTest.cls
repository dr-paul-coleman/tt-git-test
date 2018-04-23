@isTest
private class savePDFTest {
    
    @isTest static void test_method_one() {
        //User testUser = [SELECT id FROM User WHERE Profile.Name LIKE 'Marketplace Integrity' AND IsActive=true LIMIT 1];        
        User testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
        
        System.runAs(testUser) 
        { 
        Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Id miCaseQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceIntegrity'].Id;
        Decimal testProUserId = 100;
        Decimal testCustomerUserId = 200;
        Account aPro = new Account(Name='Chester Pro', usr_user_id__c=testProUserId, usr_email__c='protester@t.est', RecordTypeId=accProRT);
        Account aPro2 = new Account(Name='Chester Pro2', usr_user_id__c=123, usr_email__c='protester2@t.est', RecordTypeId=accProRT);
        Account aCustomer = new Account(Name='Tester Customer', usr_user_id__c=testCustomerUserId, usr_email__c='customertester@t.est', RecordTypeId=accCustomerRT);
        Account aCustomer2 = new Account(Name='Tester Customer2', usr_user_id__c=12345, usr_email__c='customertester2@t.est', RecordTypeId=accCustomerRT);
        insert new Account[]{aPro,aPro2,aCustomer,aCustomer2};
        
        //Case aCase = new Case(accountId=aPro.Id, Subject='MI Test Case', Status = 'New', Origin = 'Email',RecordTypeId=caseRT);
        //insert aCase;
        //System.assert(null!=aCase.Id,'Test Case not inserted properly');
        MiIncident__c mii = new MiIncident__c(
            Name='Test', 
            quotes_pro_user_id__c=testProUserId, 
            quotes_customer_id__c=testCustomerUserId, 
            quotes_bid_id__c = 1, 
            RequestID__c = '1',
            ResolutionTier__c = 'Tier 0 - Lost Communication',
            MICategory__c = 'Removed',
            MISubcategory__c = 'Other',
            Status__c = 'In Progress',
            ProAccount__c = apro.Id,
            OutcomePro__c = 'Flagged',
            OutcomeCustomer__c = 'Unresponsive',
            CustomerAccount__c = aCustomer.Id,
            IncidentCategorization__c ='0 - Not enough details');  
            insert mii;   
            MIIncidentAction__c m = new MIIncidentAction__c();
            m.MIIncident__c = mii.id;  
            insert m;         
            //PageReference pageRef = Page.MIPayoutsPDF();
            //Test.setCurrentPage(pageRef);
        
            Test.startTest();
                savePDF s = new savePDF(new ApexPages.StandardController(m));
                s.saveAttachement();
            Test.stopTest();
        }

    }
    
    
}