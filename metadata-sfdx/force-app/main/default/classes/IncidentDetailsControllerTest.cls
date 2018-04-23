@isTest
private class IncidentDetailsControllerTest
{
    public static Id miRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    public static Id PayoutRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    public static Id ChargeRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Charge Card').getRecordTypeId();
    //public static Id SolutionRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center').getRecordTypeId();
    public static Id GuaranteeRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Guarantee').getRecordTypeId();
    // public static Id CollectionsRTId  = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
    // public static Id ArbitrationRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Arbitration').getRecordTypeId();
    public static Id TaskRTId = MIIncidentAction__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();

    @isTest static void test1()
    {

        User testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive = true LIMIT 1];
        Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Id miCaseQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceIntegrity'].Id;
        Decimal testProUserId = 100;
        Decimal testCustomerUserId = 200;
        Account aPro = new Account(Name = 'Chester Pro', usr_user_id__c = testProUserId, usr_email__c = 'protester@t.est', RecordTypeId = accProRT);
        Account aPro2 = new Account(Name = 'Chester Pro2', usr_user_id__c = 123, usr_email__c = 'protester2@t.est', RecordTypeId = accProRT);
        Account aCustomer = new Account(Name = 'Tester Customer', usr_user_id__c = testCustomerUserId, usr_email__c = 'customertester@t.est', RecordTypeId = accCustomerRT);
        Account aCustomer2 = new Account(Name = 'Tester Customer2', usr_user_id__c = 12345, usr_email__c = 'customertester2@t.est', RecordTypeId = accCustomerRT);
        insert new Account[] {aPro, aPro2, aCustomer, aCustomer2};
        Contact con = new Contact(LastName = 'Last', FirstName = 'First', AccountId = aPro.Id);
        insert con;
        Case aCase = new Case(accountId = aPro.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Email', RecordTypeId = caseRT);
        insert aCase;
        System.assert(null != aCase.Id, 'Test Case not inserted properly');
        Set<Id> primaryIds = new Set<Id>();
        primaryIds.add(aCase.Id);
        MiIncident__c mii = new MiIncident__c(
                Name = 'Test',
                pro_user_id__c = String.valueOf(testProUserId),
                customer_id__c = String.valueOf(testCustomerUserId),
                quotes_pro_user_id__c = testProUserId,
                quotes_customer_id__c = testCustomerUserId,
                quotes_bid_id__c = 1,
                RequestID__c = '1',
                ResolutionTier__c = 'Tier 0 - Lost Communication',
                MICategory__c = 'Removed',
                MISubcategory__c = 'Other',
                Status__c = 'In Progress',
                IncidentCategorization__c = '0 - Not enough details');
        insert mii;
        primaryIds.add(mii.Id);
        mii.ProAccount__c = aPro2.Id;
        mii.CustomerAccount__c = aCustomer2.Id;
        mii.ResolutionTier__c = 'Compensation Reason';
        mii.Status__c = 'Closed';
        mii.RecordTypeId = miRecordTypeId;
        mii.OutcomeCustomer__c = 'Flagged';
        mii.OutcomePro__c = 'Unresponsive';
        mii.CSATOfferedPro__c = false;
        mii.MICategory__c = 'Property damage';
        mii.DoNotSurveyPro__c = false;
        mii.ClosedDate__c = Date.today();
        mii.OutcomePro__c = 'Pro fixed work';
        update mii;

        MiIncident__c mii2 = new MiIncident__c(
                Name = 'Testy',
                pro_user_id__c = '110',
                customer_id__c = '210',
                quotes_pro_user_id__c = 110,
                quotes_customer_id__c = 210,
                quotes_bid_id__c = 2,
                RequestID__c = '2',
                ResolutionTier__c = 'Tier 0 - Lost Communication',
                MICategory__c = 'Removed',
                MISubcategory__c = 'Other',
                Status__c = 'In Progress',
                IncidentCategorization__c = '0 - Not enough details');

        MIIncidentAction__c mia = new MIIncidentAction__c();
        mia.RecordTypeId = PayoutRTId;

        mia.MIIncident__c = mii.Id;
        insert mia;

        Task t = new Task();
        t.OwnerId = testUser.Id;
        t.Subject = 'Hello';
        t.Status = 'Open';
        t.Priority = 'Normal';
        t.WhatId = mii.Id;
        t.Type = 'Call';
        insert t;

        EmailMessage newEmail = new EmailMessage();
        newEmail.FromAddress = 'test@email.com';
        newEmail.ParentId = aCase.Id;
        insert newEmail;
        Test.startTest();
        String response = IncidentDetailsController.closeMIIncident(mii.Id);
        System.Assert(response != null);

        List<IncidentFeedItem> ifi = IncidentDetailsController.getFeed(mii.Id, con.Id, 'emails', null);
        System.Assert(ifi.size() == 0);

        Map<Id, IncidentFeedItem> ifi2 = IncidentDetailsController.getEmails(primaryIds, 'emails');
        System.Assert(ifi2.size() > 0);

        Map<Id, IncidentFeedItem> ifi3 = IncidentDetailsController.getIncidentActionAndHistory(primaryIds, 'emails');
        System.Assert(ifi3.size() == 0);

        Map<Id, IncidentFeedItem> ifi4 = IncidentDetailsController.getIncidentActions(primaryIds, 'all');
        System.Assert(ifi4.size() > 0);

        Map<Id, Case> caseMap = new Map<Id, Case>();
        caseMap.put(aCase.Id, aCase);

        Map<Id, IncidentFeedItem> ifi6 = IncidentDetailsController.getPhoneCalls(caseMap, primaryIds, 'all');
        System.Assert(ifi6.size() > 0);

        Test.stopTest();

    }
    @isTest static void test2()
    {

        User testUser = [SELECT id FROM User WHERE UserName LIKE 'salesforceintegration@thumbtack.com%' AND IsActive = true LIMIT 1];
        Id accProRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        Id accCustomerRT = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id caseRT = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        Id miCaseQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceIntegrity'].Id;
        Decimal testProUserId = 100;
        Decimal testCustomerUserId = 200;
        Account aPro = new Account(Name = 'Chester Pro', usr_user_id__c = testProUserId, usr_email__c = 'protester@t.est', RecordTypeId = accProRT);
        Account aPro2 = new Account(Name = 'Chester Pro2', usr_user_id__c = 123, usr_email__c = 'protester2@t.est', RecordTypeId = accProRT);
        Account aCustomer = new Account(Name = 'Tester Customer', usr_user_id__c = testCustomerUserId, usr_email__c = 'customertester@t.est', RecordTypeId = accCustomerRT);
        Account aCustomer2 = new Account(Name = 'Tester Customer2', usr_user_id__c = 12345, usr_email__c = 'customertester2@t.est', RecordTypeId = accCustomerRT);
        insert new Account[] {aPro, aPro2, aCustomer, aCustomer2};
        Contact con = new Contact(LastName = 'Last', FirstName = 'First', AccountId = aPro.Id);
        insert con;
        Case aCase = new Case(accountId = aPro.Id, Subject = 'MI Test Case', Status = 'New', Origin = 'Email', RecordTypeId = caseRT);
        insert aCase;
        System.assert(null != aCase.Id, 'Test Case not inserted properly');
        Set<Id> primaryIds = new Set<Id>();
        MiIncident__c mii = new MiIncident__c(
                Name = 'Test',
                pro_user_id__c = String.valueOf(testProUserId),
                customer_id__c = String.valueOf(testCustomerUserId),
                quotes_pro_user_id__c = testProUserId,
                quotes_customer_id__c = testCustomerUserId,
                quotes_bid_id__c = 1,
                RequestID__c = '1',
                ResolutionTier__c = 'Tier 0 - Lost Communication',
                MICategory__c = 'Removed',
                MISubcategory__c = 'Other',
                Status__c = 'In Progress',
                IncidentCategorization__c = '0 - Not enough details');
        insert mii;
        primaryIds.add(mii.Id);
        mii.ProAccount__c = aPro2.Id;
        mii.CustomerAccount__c = aCustomer2.Id;
        mii.ResolutionTier__c = 'Compensation Reason';
        mii.Status__c = 'Closed';
        mii.RecordTypeId = miRecordTypeId;
        mii.OutcomeCustomer__c = 'Flagged';
        mii.OutcomePro__c = 'Unresponsive';
        mii.CSATOfferedPro__c = false;
        mii.MICategory__c = 'Property damage';
        mii.DoNotSurveyPro__c = false;
        mii.ClosedDate__c = Date.today();
        mii.OutcomePro__c = 'Pro fixed work';
        update mii;

        MiIncident__c mii2 = new MiIncident__c(
                Name = 'Testy',
                pro_user_id__c = '110',
                customer_id__c = '210',
                quotes_pro_user_id__c = 110,
                quotes_customer_id__c = 210,
                quotes_bid_id__c = 2,
                RequestID__c = '2',
                ResolutionTier__c = 'Tier 0 - Lost Communication',
                MICategory__c = 'Removed',
                MISubcategory__c = 'Other',
                Status__c = 'In Progress',
                IncidentCategorization__c = '0 - Not enough details');

        MIIncidentAction__c mia = new MIIncidentAction__c();
        mia.RecordTypeId = TaskRTId;
        mia.MIIncident__c = mii.Id;
        mia.Type__c = 'Follow-up';
        insert mia;

        //System.runAs(testUser) {
        Test.startTest();

        Map<Id, IncidentFeedItem> ifi1 = IncidentDetailsController.getIncidentActions(primaryIds, 'all');
        mia.Type__c = 'Note';
        update mia;
        Map<Id, IncidentFeedItem> ifi2 = IncidentDetailsController.getIncidentActions(primaryIds, 'all');

        Test.stopTest();
        // }
    }

    static testMethod void testGetCaseFeed()
    {
        Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert customer;

        Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
        insert pro;

        MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
        insert incident;

        Case c = new Case(AccountId = customer.Id, Subject='MI Test Case', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
        insert c;

        FeedItem fi1 = new FeedItem(ParentId = c.Id, Body = 'Test Feed 1', Type = 'TextPost');
        FeedItem fi2 = new FeedItem(ParentId = c.Id, Body = 'Test Feed 2', Type = 'TextPost');
        insert new List<FeedItem>{fi1, fi2};

        List<IncidentFeedItem> feedItems = IncidentDetailsController.getFeed(incident.Id, null, 'all', null);
        System.assertEquals(2, feedItems.size());
    }

    static testMethod void testGetCaseComments()
    {
        Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert customer;

        Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
        insert pro;

        MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
        insert incident;

        Case c = new Case(AccountId = customer.Id, Subject='MI Test Case', Status = 'New', Incident__c = incident.Id, Origin = 'Suggestion Box' );
        insert c;

        CaseComment cc1 = new CaseComment(ParentId = c.Id, CommentBody = 'Test Comment 1');
        CaseComment cc2 = new CaseComment(ParentId = c.Id, CommentBody = 'Test Comment 2');
        insert new List<CaseComment>{cc1, cc2};

        List<IncidentFeedItem> feedItems = IncidentDetailsController.getFeed(incident.Id, null, 'all', null);
        System.assertEquals(2, feedItems.size());
    }

    static testMethod void testGetIncidentFactors()
    {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser)
        {
            Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
            insert customer;

            Account pro = new Account(Name = 'Pro Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId());
            insert pro;

            MIIncident__c incident = new MIIncident__c(CustomerAccount__c = customer.Id, ProAccount__c = pro.Id);
            insert incident;

            List<IncidentFactor__c> factors = new List<IncidentFactor__c>();
            factors.add(new IncidentFactor__c(Name = 'Factor 1', IsActive__c = true));
            factors.add(new IncidentFactor__c(Name = 'Factor 2', IsActive__c = true));
            insert factors;

            List<IncidentFactorAssignment__c> assignments = new List<IncidentFactorAssignment__c>();
            assignments.add(new IncidentFactorAssignment__c(Factor__c = factors[0].Id, Incident__c = incident.Id));
            assignments.add(new IncidentFactorAssignment__c(Factor__c = factors[1].Id, Incident__c = incident.Id));
            insert assignments;

            List<IncidentFeedItem> items = IncidentDetailsController.getFeed(incident.Id, null, 'all', null);
            System.assertEquals(2, items.size());
        }
    }
}