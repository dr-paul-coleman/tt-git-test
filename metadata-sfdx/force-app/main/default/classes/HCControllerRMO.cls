/*
    Copyright (c) 2017 Thumbtack,  All rights reserved.

Change List:
------------

Version    Date     Author            Description
=======+===========+=================+=================================
 ... previous log entries committed to git
1.5     11/21/17      pcoleman       Modified requestACall function to use
                                        Queueable instead of JSONObject trigger
1.6     2018-03-05    pcoleman       Added createCase() VFRMO override
=======+===========+=================+=================================*/
global with sharing class HCControllerRMO
{
    global class HelpCenterException extends Exception{}
    global static Map<String,Id> QIds {get;set;}
    global String metadesc {get;set;}
    global String metatitle {get;set;}
    global String metacanonical {get;set;}
    global String isWebview {get;set;}
    global String useragent {get;set;}
    global String mainScript {get;set;}
    global String mainStylesheet {get;set;}

    static {
        QIds = new Map<String,Id>();
        for( Group g: [SELECT Id, Name, DeveloperName, RelatedId,Type FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('MarketplaceIntegrity','SupportContent','ProductFeedbackCase','ProductFeedback') LIMIT 4] )
        {
            QIds.put(g.DeveloperName,g.Id);
        }
    }

    global HCControllerRMO() {
        PageReference currentPage = ApexPages.currentPage();

        this.metatitle = 'Thumbtack Help Center';
        this.metadesc = 'Find answers quickly. Get back to doing what you love.';
        this.metacanonical = '';
        this.isWebview = currentPage.getHeaders().get('X-Is-Webview');

        String ar = currentPage.getParameters().get('ar');
        if (ar != null) {
            PublicArticle__kav article = getArticleById(ar);
            if (article != null) {
                this.metatitle = article.Title;
                this.metadesc = article.Summary;
                this.metacanonical = 'https://help.thumbtack.com/article/' + article.UrlName;
            }
        }
        String vw = currentPage.getParameters().get('vw');
        if(vw != null)
        {
            if (vw == 'sg')
            {
                this.metatitle = 'Suggestion Box';
                this.metadesc = 'How can we improve? Share your suggestions here.';
                this.metacanonical = 'https://help.thumbtack.com/suggestions';
            }
            else if (vw == 'pg')
            {
                this.metatitle = 'Report a dispute with a pro';
                this.metadesc = '';
                this.metacanonical = 'https://help.thumbtack.com/report-a-concern';
            }
            else if (vw == 'vd')
            {
                this.metatitle = 'Video Library';
                this.metadesc = 'Check out our videos to learn about Thumbtack and get useful tips.';
                this.metacanonical = 'https://help.thumbtack.com/videos';
            }
        }
    }

    public PageReference initialize()
    {
        return null;
    }

    global static PublicArticle__kav getArticleById(String knowledgeArticleId)
    {
        PublicArticle__kav article;
        for(PublicArticle__kav[] articles: [SELECT Id,MetaImage__Length__s,MetaImage__ContentType__s,MetaDescription__c,MetaImage__Name__s,MetaImage__Body__s,MetaTitle__c,KnowledgeArticleId,Title,Summary,UrlName,Audience__c, (Select DataCategoryName From DataCategorySelections) From PublicArticle__kav WHERE (Id = :knowledgeArticleId OR KnowledgeArticleId = :knowledgeArticleId OR UrlName = :knowledgeArticleId) AND IsVisibleInPkb = true AND PublishStatus ='Online' AND Language = 'en_US' LIMIT 1]) {
            for(PublicArticle__kav ar: articles)
            {
                article = ar;
                break;
            }
        }
        return article;
    }

    /**
 * @author Paul Coleman
 * @date 2018-02-21
 * @description Overriddes the default RemoteObjectController.create() function.
 * @param String The SObject type for record insertion.
 * @param Map<String, Object> A map of field names and values for the new record's insert.
 * @return Map<String, Object> An object that represents save result of the insert dml.
 */
    @RemoteAction
    global static Map<String, Object> caseCreate(String type, Map<String, Object> fields)
    {
        Map<String, Object> result = new Map<String, Object>{ 'id' => '500000000000000QAW', 'success' => true, 'errors' => new Map<String,String>() };
        Boolean isOverride = false;
        // do not allow dispute-based inserts by anyone other than portal users
        if( 'CspLitePortal'.equalsIgnoreCase( UserInfo.getUserType() ) )
        {
            if ( 'Case'.equalsIgnoreCase(type) )
            {
                Object disputeHash = fields.get('DisputeIdHash__c');
                if( NULL != disputeHash && (disputeHash instanceof String) )
                {
                    SolutionCenterUtility.insertDisputeCase(fields);
                    isOverride = true;
                }
            }
        }
        return isOverride ? result: RemoteObjectController.create(type, fields);
    }

    @RemoteAction
    global static String getArticleDraftById(String knowledgeArticleId)
    {
        return !'Standard'.equals(UserInfo.getUserType())?'[]':JSON.serialize([Select Id,KnowledgeArticleId,iPhonePublicContent__c,AndroidPublicContent__c,Title,Summary,UrlName,HelpCenterPublicContent__c,Audience__c,ContainsVideo__c, (Select DataCategoryName From DataCategorySelections) From PublicArticle__kav WHERE (Id = :knowledgeArticleId OR KnowledgeArticleId = :knowledgeArticleId OR UrlName = :knowledgeArticleId) AND IsVisibleInPkb = true AND PublishStatus ='Draft' AND Language = 'en_US']);
    }

    @RemoteAction
    global static String searchArticles(String searchTerm, String category, String audience, Integer lim)
    {
        String searchString = 'FIND {'+searchTerm+'} IN ALL FIELDS RETURNING PublicArticle__kav(Id,HelpCenterPublicContent__c,iPhonePublicContent__c,AndroidPublicContent__c,KnowledgeArticleId,Title,Summary,VersionNumber,UrlName,Audience__c,ContainsVideo__c WHERE IsVisibleInPkb=true AND PublishStatus = \'Online\' AND Language = \'en_US\' AND IsLatestVersion=true '+ (null!=audience && !''.equals(audience.trim())?' AND Audience__c IN (\''+audience+'\',\'Customer and Pro Facing\')' :'') +' ) WITH DATA CATEGORY Thumbtack__c BELOW ThumbtackSupport__c '+ (null==lim? '':' LIMIT '+String.valueOf(lim));
        return JSON.serialize((PublicArticle__kav[])(search.query( searchString )[0]));
    }

    @RemoteAction
    global static String searchKb(String searchTerm)
    {
        String term = searchTerm.replaceAll('([\\?\\&\\|\\!\\{\\}\\[\\]\\(\\)\\^\\~\\*\\:\\\"\'\\+\\-])', '\\$1');
        Sobject[] recs = (SObject[])[FIND :term IN ALL FIELDS RETURNING PublicArticle__kav(Id,HelpCenterPublicContent__c,iPhonePublicContent__c,AndroidPublicContent__c,KnowledgeArticleId,Title,Summary,VersionNumber,UrlName,Audience__c,ContainsVideo__c WHERE PublishStatus = 'Online' AND Language = 'en_US' AND IsLatestVersion=true AND Audience__c != 'Unsearchable') ][0];
        return JSON.serialize(recs);
    }

    @RemoteAction
    global static String createCallRequest(String leadJSON) {
        try { System.enqueueJob( new RequestACallQueueable( leadJSON ) ); } catch (Exception ex) {  TackBotUtility.postTackLogException(ex, 'HCControllerRMO.createCallRequest'); }
        return '{"id":"0012F000008uTC9QAM","success":true,"errors":[],"warnings":[]}';
    }

    @RemoteAction
    global static String getProductFeedbackPickLists()
    {
        Map<String,Schema.DescribeFieldResult> meta = new Map<String,Schema.DescribeFieldResult>();
        Schema.SObjectField[] fields = Schema.SObjectType.ProductFeedback__c.fields.getMap().values();
        for(Schema.SObjectField f: fields)
        {
            Schema.DescribeFieldResult d = f.getDescribe();
            if('picklist'==String.valueOf(d.getType()).toLowerCase() ) {meta.put(d.getName(),d);}
        }
        return JSON.serialize(meta);
    }
}