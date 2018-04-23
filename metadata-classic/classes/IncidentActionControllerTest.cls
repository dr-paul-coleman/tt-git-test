@isTest
private class IncidentActionControllerTest {
	public static Id miRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
	public static Id PayoutRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    public static Id ChargeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Charge Card').getRecordTypeId();
   // public static Id SolutionRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center').getRecordTypeId();
    public static Id GuaranteeRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Guarantee').getRecordTypeId();
   // public static Id CollectionsRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
    //public static Id ArbitrationRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Arbitration').getRecordTypeId();
    public static Id TaskRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();
	
	@isTest static void test1() {
	
	User testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive=true LIMIT 1];
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
         Contact con = new Contact( LastName = 'Last',FirstName = 'First', AccountId = aPro.Id);
        insert con;
        Case aCase = new Case(accountId=aPro.Id, Subject='MI Test Case', Status = 'New', Origin = 'Email',RecordTypeId=caseRT);
        insert aCase;
        System.assert(null!=aCase.Id,'Test Case not inserted properly');
        Set<Id> primaryIds = new Set<Id>();
        MiIncident__c mii = new MiIncident__c(
            Name='Test',
            pro_user_id__c=String.valueOf(testProUserId), 
            customer_id__c = String.valueOf(testCustomerUserId),
            quotes_pro_user_id__c=testProUserId, 
            quotes_customer_id__c=testCustomerUserId, 
            quotes_bid_id__c = 1, 
            RequestID__c = '1',
            ResolutionTier__c = 'Tier 0 - Lost Communication',
            MICategory__c = 'Removed',
            MISubcategory__c = 'Other',
            Status__c = 'In Progress', 
            IncidentCategorization__c ='0 - Not enough details');     
            insert mii;
            primaryIds.add(mii.Id);
            mii.ProAccount__c =aPro2.Id; 
            mii.CustomerAccount__c = aCustomer2.Id;
            mii.ResolutionTier__c = 'Compensation Reason';
            mii.Status__c = 'Closed';
            mii.RecordTypeId = miRecordTypeId;
            mii.OutcomeCustomer__c = 'Flagged';
            mii.OutcomePro__c = 'Unresponsive';
            mii.CSATOfferedPro__c = false;
            mii.MICategory__c= 'Property damage';
            mii.DoNotSurveyPro__c = false;
            mii.ClosedDate__c= Date.today(); 
            mii.OutcomePro__c='Pro fixed work';
            update mii;   

            MiIncident__c mii2 = new MiIncident__c(
            Name='Testy', 
            pro_user_id__c='110', 
            customer_id__c = '210',
            quotes_pro_user_id__c=110, 
            quotes_customer_id__c=210, 
            quotes_bid_id__c = 2, 
            RequestID__c = '2',
            ResolutionTier__c = 'Tier 0 - Lost Communication',
            MICategory__c = 'Removed',
            MISubcategory__c = 'Other',
            Status__c = 'In Progress', 
            IncidentCategorization__c ='0 - Not enough details');     
            
            MIIncidentAction__c mia = new MIIncidentAction__c();
			mia.RecordTypeId = TaskRTId;
			mia.MIIncident__c = mii.Id;
			mia.Type__c = 'Follow-up';
			mia.Status__c = 'Open';
			insert mia;

			MIIncidentAction__c mia2 = new MIIncidentAction__c();
			mia2.MIIncident__c = mii.Id;
			mia2.Type__c = 'Note';
			mia2.Status__c = 'Open';
			mia2.RecordTypeId = TaskRTId;
			insert mia2;

			MIIncidentAction__c mia3 = new MIIncidentAction__c();
			mia3.MIIncident__c = mii.Id;
			//mia3.Type__c = 'Note';
			mia3.Status__c = 'Open';
			insert mia3;
        //System.runAs(testUser) { 
            Test.startTest();

                List<MIIncidentAction__c> miList = IncidentActionController.getActions(mii.Id, 'Open');
            
                List<IncidentActionController.NoteWrapper> miList2 = IncidentActionController.getNotes(mii.Id);
                MIIncidentAction__c miareturn = IncidentActionController.upsertAction(mia3, '2017-08-10');
                IncidentActionController.deleteAction(mia3.Id);
        
            Test.stopTest();
       // }
    }
	
}