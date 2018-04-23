/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.                                     

Version    Date     Author            Description                          
=======+===========+===============+========================================
1.0     2015-05-11  Paul Coleman    Created 
1.1     2015-12-21  Paul Coleman    Removed getEmailCaseCategoryCounts() &
                                    getOldestEmailCaseByCategory functions
1.2     2016-09-19  Kristin Hasna   Removed Tier 1-4 Email queue references   
1.3 	2017-09-25	Meena Pisupati	Deprecate 'ProAssist Support';Update Header	
=======+===========+===============+========================================*/

 global with sharing class CaseController {

    @TestVisible
    private static Id enterpriseQueueId {
        get {

            if (enterpriseQueueId == null) {

                List<QueueSobject> queues = [SELECT Id,QueueId,Queue.Name FROM QueueSobject WHERE SobjectType = 'Case' And Queue.DeveloperName = 'EnterpriseQueue'];
                if (!queues.isEmpty()) {

                    enterpriseQueueId = queues[0].QueueId;

                }

            }
            return enterpriseQueueId;

        } set;
    }

    public CaseController(ApexPages.StandardController stdController) {}

    global class AccountStats {
        WebService String Id {get;set;}
        WebService Integer CaseCount {get;set;}
        WebService Integer OpenCases {get;set;}
        WebService Integer OpenMiCaseCount {get;set;}
        public AccountStats(Id aId) {
            this.Id = aId;
            this.CaseCount = 0;
            this.OpenCases = 0;
            this.OpenMiCaseCount = 0;
        }
    }

    /* A method to execute ajax-based soql
    */
    @AuraEnabled
    @RemoteAction
    global static List<SObject> doSOQL(String soql) {
        RETURN Database.query(soql);
    }

    /* A method to retrieve counts of open Email Cases by Queue Owner (Email Tiers)
    */
    @RemoteAction
    global static List<AggregateResult> getEmailCaseCounts() {
        RETURN [SELECT OwnerId,Owner.Name OwnerName,count(Id) CountOfCases from Case WHERE isClosed=false AND OwnerId IN (SELECT Id from Group WHERE DeveloperName IN ('Tier1Email','Tier2Email','Tier3Email','Tier4Email','TSLEmail','CustomerSupport','CustomerSupportEmail','EnterpriseQueue') ) GROUP BY OwnerId,Owner.Name]; //,'ProAssistSupport'
    }

    /* A method to retrieve the oldest open Email Case Id by Case OwnerId (Tiered Queue)
    */
    @RemoteAction
    global static Case getOldestEmailCaseByQueueOwner(Id OwnerId) {

        List<Case> cases = new List<Case> ();
        if (OwnerId == enterpriseQueueId) {

            cases = getEnterpriseQueueCase(Datetime.now());

        } else {

            cases = [SELECT Id,CaseNumber from Case WHERE isClosed=false AND OwnerId = :OwnerId ORDER BY CasePriorityInteger__c ASC, CreatedDate ASC LIMIT 1];
            
        }
        if(!cases.isEmpty()){
            cases[0].OwnerId = UserInfo.getUserId();
            cases[0].TakeACaseUserId__c = UserInfo.getUserId();
            update cases;
        }
        return !cases.isEmpty()? cases[0]: null;
    }

    @TestVisible
    private static List<Case> getEnterpriseQueueCase(Datetime now) {

        List<Case> cases = new List<Case> ();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        Datetime fourBusinessHours = BusinessHours.add(bh.Id, now, -4 * 60 * 60 * 1000);
        cases = [SELECT Id, CaseNumber from Case WHERE isClosed=false AND OwnerId = :enterpriseQueueId And CreatedDate < :fourBusinessHours ORDER BY CreatedDate ASC LIMIT 1];
        if (cases.isEmpty()) {

            cases = [SELECT Id, CaseNumber from Case WHERE isClosed=false AND OwnerId = :enterpriseQueueId And Account.AccountManager__c = :UserInfo.getUserId() ORDER BY CreatedDate ASC LIMIT 1];
            if (cases.isEmpty()) {

                cases = [SELECT Id, CaseNumber from Case WHERE isClosed=false AND OwnerId = :enterpriseQueueId ORDER BY CreatedDate ASC LIMIT 1];

            }

        }
        return cases;

    }

    /*  A method to pull rollup summary data from Account children,
        particular child records that are not Master-Detail
    */
    @RemoteAction
    global static AccountStats getAccountStats(Id accountId) {
        AccountStats result = new AccountStats(accountId);
        if(accountId != null) {
            List<Account> accounts = [SELECT Id,(SELECT Id,IsClosed,RecordTypeId,RecordType.Name,RecordType.DeveloperName FROM Cases),(SELECT Id FROM Contacts) FROM Account WHERE Id=:accountId LIMIT 1];
            if(!accounts.isEmpty()) {
                result.CaseCount = accounts[0].Cases.size();
                for(Case c: accounts[0].Cases) {
                    result.OpenCases += ( !c.IsClosed )? 1: 0;
                    result.OpenMiCaseCount += ( !c.IsClosed && 'MarketplaceIntegrity'.equals(c.RecordType.DeveloperName) )? 1: 0;
                }
            }
        }
        return result;
    } 

    /*  A method to pull last 10 Task records (Calls) for Case/Account/Contact
        This is a supplemental method for AJAX calls from CaseLast10Calls.page
        in case the complexity of the query surpasses what is supported well
        by the Js Remote Objects AJAX API.
    */
    @RemoteAction
    global static List<Task> getLast10Calls(String caseId, String accountId, String contactId) {
        List<String> whatids = new List<String>();
        if(caseId != null && caseId != '' && caseId.startsWith('500')) { whatids.add(caseId); }
        if(accountId != null && accountId != '' && accountId.startsWith('001')) { whatids.add(accountId); }
        if(contactId != null && contactId != '' && accountId.startsWith('003')) { whatids.add(contactId); } 
        return (contactId != null && contactId!='')? [SELECT Id,Subject,AccountId,WhatId,WhoId,CallDisposition,CallDurationInSeconds,CallObject,Status,OwnerId,CreatedById,CreatedDate,CallType,ActivityDate FROM Task WHERE CallType IN ('Inbound', 'Outbound') AND (WhatId IN :whatids OR WhoId=:contactId) ORDER BY CreatedDate DESC LIMIT 10] :[SELECT Id,Subject,AccountId,WhatId,WhoId,CallDisposition,CallDurationInSeconds,CallObject,Status,OwnerId,CreatedById,CreatedDate,CallType,ActivityDate FROM Task WHERE CallType IN ('Inbound', 'Outbound') AND WhatId IN :whatids ORDER BY CreatedDate DESC LIMIT 10];
    } 


    /*  A method to pull all Active Standard User records for Change Owner combos.
    */
    @AuraEnabled
    @RemoteAction
    global static List<User> getAllStandardUsers() {
        return [SELECT Id,Name,Team__c FROM User WHERE IsActive=true AND UserType='Standard' ORDER BY Name ASC];
    } 

    /*  A method to pull user-accessible Case queues for Change Owner combos.
    */
    @AuraEnabled
    @RemoteAction
    global static List<QueueSobject> getAllCaseQueues() {
        return [SELECT Id,QueueId,Queue.Name FROM QueueSobject WHERE SobjectType = 'Case' ORDER BY Queue.Name ASC];
    }

    @AuraEnabled
    public static void updateCase(Id caseId, Id newOwnerId) {

        update new Case (Id = caseId, OwnerId = newOwnerId);

    }

    @AuraEnabled
    @RemoteAction
    global static String postMsgWithMentions(Id caseId, String msg){
     
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();             
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
     
        //parse @[User Name]
        //use pattern matching group ()  so we can easily extract name later*
        Pattern p = Pattern.compile('\\@\\[([a-z|A-Z|0-9].*?)\\]'); 
     
        //use regex to split all all non-mentions into segments
        String [] textSegments = p.split(msg,-1);
         
        //create a pattern matcher object
        Matcher pm = p.matcher( msg );
     
        //all @[mentions] in order (we will need this to build the segments later**)
        List<String> mentionedNames = new List<String>{};   
     
        Map<String,ConnectApi.MentionSegmentInput> nameToInputMap = new Map<String,ConnectApi.MentionSegmentInput>{};
     
        //iterate through each @mention and build a map of unique @mentions 
        if( pm.find() ){
     
            do {
                //now we can extract the pattern matching group defined earlier*
                String mentionName = pm.group(1);
                //use lowercase to ensure case neutrality later***
                String lcName = mentionName.toLowerCase();
                if(!nameToInputMap.containsKey(lcName)){
                    nameToInputMap.put(lcName, new ConnectApi.MentionSegmentInput());               
                }
                mentionedNames.add(lcName);
            } while(pm.find());
     
        }
     
        ConnectApi.MentionSegmentInput[] mentions = new ConnectApi.MentionSegmentInput[]{};
     
        //check the @[chatter names] against user Names
        for(User u: [SELECT Id, Name FROM User WHERE name IN: mentionedNames]){
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            //making sure to fetch using lowercased name***
            nameToInputMap.get(u.Name.toLowerCase()).id = u.id;
            mentionSegmentInput.id = u.id;   
        }
     
        //Paul C: NOT supporting group mentions yet
        //check the @[chatter names] against Chatter group Names (aka CollaborationGroup)
        //for(CollaborationGroup cg: [SELECT Id, Name FROM CollaborationGroup WHERE name IN: mentionedNames]){
        //    ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        //    //making sure to fetch using lowercased name***
        //    nameToInputMap.get(cg.Name.toLowerCase()).id = cg.id;
        //    mentionSegmentInput.id = cg.id;  
        //}
     
        //shuffle the mentions back in with the text segments
        for(Integer i=0;i<textSegments.size();i++){
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = textSegments[i];
            messageBodyInput.messageSegments.add(textSegmentInput);
            //due to splitting, there should always be one less mention than text segments
            if(mentionedNames.size() > i){
                // now "sandwich" the @mentions into the text Segments in their original order
                messageBodyInput.messageSegments.add(nameToInputMap.get(mentionedNames[i]));
            }
        }
     
        feedItemInput.subjectId = caseId;
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

        ConnectApi.FeedElement e = ConnectApi.ChatterFeeds.postFeedElement(null,feedItemInput,null);

        return JSON.serialize(e);
     
    }

}