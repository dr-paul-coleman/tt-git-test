/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************  

Change List:
------------
Version      Date          Author            Description
========++============++=================++====================================
1.0       08-01-2017     Scott Purcell     Created
========++============++=================++===================================*/
@isTest
private class IncidentFactorControllerTest {
	
	 public static Id gfRecordTypeId = CSAT__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('GetFeedback CSAT').getRecordTypeId();
    public static Id miRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    @isTest static void testMIInccidentNewUpdate() {
        //User testUser = [SELECT id FROM User WHERE Profile.Name LIKE 'Marketplace Integrity' AND IsActive=true LIMIT 1];        
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

        System.runAs(testUser) {
            Case aCase = new Case(accountId=aPro.Id, Subject='MI Test Case', Status = 'New', Origin = 'Email',RecordTypeId=caseRT);
        insert aCase;
        System.assert(null!=aCase.Id,'Test Case not inserted properly');
        MiIncident__c mii = new MiIncident__c(
            Name='Test', 
            quotes_pro_user_id__c=testProUserId, 
            pro_user_id__c=String.valueOf(testProUserId), 
            customer_id__c = String.valueOf(testCustomerUserId),
            quotes_customer_id__c=testCustomerUserId, 
            quotes_bid_id__c = 1, 
            RequestID__c = '1',
            ResolutionTier__c = 'Tier 0 - Lost Communication',
            MICategory__c = 'Removed',
            MISubcategory__c = 'Other',
            Status__c = 'In Progress', 
            IncidentCategorization__c ='0 - Not enough details');      
            insert mii;
                mii.ProAccount__c =aPro2.Id;
                update mii;  
                 mii.CustomerAccount__c = aCustomer2.Id;
                update mii;  
                mii.ResolutionTier__c = 'Compensation Reason';
                mii.Status__c = 'Closed';
                mii.RecordTypeId = miRecordTypeId;
                mii.OutcomeCustomer__c = 'Flagged';
                mii.OutcomePro__c = 'Unresponsive';
                update mii;
                mii.CSATOfferedPro__c = false;
                //todo-make conditions to pass this formuila
                mii.MICategory__c= 'Property damage';
                mii.DoNotSurveyPro__c = false;
                mii.ClosedDate__c= Date.today(); 
                mii.OutcomePro__c='Pro fixed work';

                update mii;  
            IncidentFactor__c inf = new IncidentFactor__c(
            HelpText__c = 'help text',
			IsActive__c = true,
			Name ='Test') ;
			insert inf;
			IncidentFactorAssignment__c infa = new IncidentFactorAssignment__c(
			Factor__c= inf.Id,
			Incident__c = mii.Id);
			insert infa;

            Test.startTest();
                
            List<Map<String, Object>> mappy =	IncidentFactorController.getFactors(mii.Id);
            system.assert(mappy != null);
            IncidentFactorAssignment__c ifa = IncidentFactorController.createAssignment(mii.Id, inf.Id);
            system.assert(ifa != null);
            IncidentFactorController.deleteAssignment(ifa.Id);

            Test.stopTest(); 
        }
    }
	
}