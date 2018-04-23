/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/10/17      jkennington      Created - Pulled in and cleaned up functionality from old becquerelutility
========+============+=================+===============================================*/
public with sharing class BeckyWorkItemSyncQueueable implements Queueable
{

    private Map<Decimal,becquerel_concerning_reviews__x> wiXMap;
    private Group wiQueue;
    private Decimal[] accountTTID;
    private String[] accountEmails;
    private Map<Decimal,WorkItem__c> newWorkItemMap;

    public BeckyWorkItemSyncQueueable()
    {
        this.accountTTID = new Decimal[0];
        this.wiXMap = new Map<Decimal, becquerel_concerning_reviews__x>();
        this.newWorkItemMap = new Map<Decimal, WorkItem__c>();
        this.accountEmails = new String[0];
    }

    public void execute(QueueableContext context)
    {
        this.wiQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Proactive MI Queue' LIMIT 1];
        Map<Decimal,Account> newAccountMap = new Map<Decimal,Account>();
        list<WorkItem__c> wiMissingAccounts = new List<WorkItem__c>();
        Map<Decimal,Id> accMap = new Map<Decimal,Id>();
        Map<String, Id> accEmailMap = new Map<String, Id>();
        Map<Decimal,WorkItem__c> wiMap = new Map<Decimal,WorkItem__c>();

        try
        {
            if( !Trigger.isExecuting )
            {
                for ( becquerel_concerning_reviews__x wx : BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalConcerningReviews( 1 ) : [ Select Id,RecordTypeId__c,is_anonymous__c,bid_bid_id__c,category_id_decoded__c,customer_email__c,customer_first_name__c,customer_last_name__c,customer_user_id__c,delete_time__c,feedback_private_to_thumbtack__c,feedback_private_to_user__c, pro_email__c,pro_first_name__c,pro_last_name__c,pro_user_id__c,rating__c,rca_name__c,response_text__c,review_id__c,review_time__c,text__c From becquerel_concerning_reviews__x LIMIT 2000 ] )
                {
                    if ( wx.review_id__c != null ) { this.wiXMap.put( wx.review_id__c, wx ); }
                    //get pro account Id
                    if ( wx.pro_user_id__c != null ) { this.accountTTID.add( wx.pro_user_id__c ); }
                    if ( wx.pro_email__c != null ) { this.accountEmails.add( wx.pro_email__c ); }
                }
            }
        }
        catch ( System.ExternalObjectException ex )
        {
            System.debug(LoggingLevel.ERROR, ex); // skip HTTP 504 Errors when trying to do oData queries
            if( !ex.getMessage().contains( 'Error received from the external system: 50')) { TackBotUtility.sendExceptionEmail( ex, 'BeckyWorkItemSyncQueueable.execute()' ); }
        }
        catch ( System.UnexpectedException ex )
        {
            System.debug( LoggingLevel.ERROR, ex );
            if ( !ex.getMessage().contains( 'Apex triggers can\'t reference external objects or call out to external data sources' ) )
            {
                TackBotUtility.sendExceptionEmail( new ExternalObjectException ( ex.getMessage() ), 'BeckyWorkItemSyncQueueable.execute()' );
            }
        }

        //get workitems based off review ID
        for(WorkItem__c wi : [Select Id,ReviewIsAnonymous__c,Name,ProAccount__c,usr_user_id__c,rev_usr_user_id_reviewed__c,pro_first_name__c,pro_last_name__c,rev_usr_user_id_reviewer__c,customer_first_name__c,customer_last_name__c,customer_email__c,bid_bid_id__c, RequestCategoryId__c,rev_review_id__c,rev_review_time__c,rev_rating__c,rca_name__c,rev_text__c,rev_response_text__c,rev_private_feedback_to_reviewed_user__c,rev_private_feedback_to_thumbtack__c From WorkItem__c Where rev_review_id__c IN:wiXMap.keySet()])
        {
            wiMap.put(wi.rev_review_id__c,wi);
        }

        //get accounts so we can search for missing records
        for(Account a : [Select Id,usr_user_id__c, usr_email__c From Account Where usr_email__c IN :accountEmails OR usr_user_id__c IN :this.accountTTID])
        {
            if(a.usr_user_id__c != null){ accMap.put(a.usr_user_id__c,a.Id); }
            if(a.usr_email__c != null){ accEmailMap.put(a.usr_email__c, a.Id); }
        }

        //create or update WorkItem
        for(becquerel_concerning_reviews__x wiX : wiXMap.values()){ populateWorkItem(wiMap.get(wiX.review_id__c), wiX); }

        //search for missing accounts
        for(WorkItem__c wi : this.newWorkItemMap.values())
        {
            if(wi.ProAccount__c == null){ wi.ProAccount__c = accMap.get(wi.rev_usr_user_id_reviewed__c); }
            if(wi.ProAccount__c == null){ wi.ProAccount__c = accEmailMap.get(wi.pro_email__c); }
            if(wi.ProAccount__c == null && !accMap.containsKey(wi.rev_usr_user_id_reviewed__c) && !newAccountMap.containsKey(wi.rev_usr_user_id_reviewed__c) && !accEmailMap.containsKey(wi.pro_email__c))
            {
                Account acc = new Account(Name = wi.pro_first_name__c +' '+wi.pro_last_name__c,usr_user_id__c = wi.rev_usr_user_id_reviewed__c,usr_first_name__c = wi.pro_first_name__c,usr_last_name__c = wi.pro_last_name__c,usr_email__c = wi.pro_email__c);
                newAccountMap.put(wi.rev_usr_user_id_reviewed__c, acc);
                wiMissingAccounts.add(wi);
            }
        }

        //search for missing accounts
        for(WorkItem__c wi : wiMap.values())
        {
            if(wi.ProAccount__c == null){ wi.ProAccount__c = accMap.get(wi.rev_usr_user_id_reviewed__c); }
            if(wi.ProAccount__c == null){ wi.ProAccount__c = accEmailMap.get(wi.pro_email__c); }

            if(wi.ProAccount__c == null && !accMap.containsKey(wi.rev_usr_user_id_reviewed__c) && !newAccountMap.containsKey(wi.rev_usr_user_id_reviewed__c) && !accEmailMap.containsKey(wi.pro_email__c))
            {
                String name = wi.pro_first_name__c +' '+wi.pro_last_name__c;
                Account acc = new Account(Name = name,usr_user_id__c = wi.rev_usr_user_id_reviewed__c,usr_first_name__c = wi.pro_first_name__c,usr_last_name__c = wi.pro_last_name__c,usr_email__c = wi.pro_email__c);
                if(acc.Name == null){ acc.Name = wi.pro_first_name__c +' '+wi.pro_last_name__c; }
                newAccountMap.put(wi.rev_usr_user_id_reviewed__c, acc);
                wiMissingAccounts.add(wi);
            }
        }

        try
        {
            insert newAccountMap.values();
            for(WorkItem__c wi:wiMissingAccounts)
            {
                wi.ProAccount__c = newAccountMap.get(wi.rev_usr_user_id_reviewed__c).id;
            }
            system.debug(LoggingLevel.INFO, 'BecquerelUtilityQueuable.workitems.size(): ' + wiMap.size());
            update wiMap.values();

            insert newWorkItemMap.values();

        }
        catch(DmlException e){system.debug(e);}

    }

    /**
	* @author Jared Kennington
	* @date 2017-10-11
	* @description Used to update or create new WorkItem
	*/
    private void populateWorkItem(WorkItem__c workItem, becquerel_concerning_reviews__x  wiX)
    {
        Boolean newWorkItem = false;

        if(workItem == null)
        {
            workItem = new WorkItem__c();
            newWorkItem = true;
        }

        workItem.OwnerId = this.wiQueue.Id;
        workItem.Name = (wiX.rating__c +' Star review from '+wiX.customer_first_name__c+' '+wiX.customer_last_name__c + ' for ' +wiX.pro_first_name__c+' '+wiX.pro_last_name__c).left(78);
        //system.debug('BeckyWorkItemSyncQueueable-NEW work item .Name: ' + wi.Name);
        workItem.usr_user_id__c = workItem.usr_user_id__c == null ? wiX.pro_user_id__c : workItem.usr_user_id__c;
        workItem.ReviewIsAnonymous__c = wiX.is_anonymous__c;
        workItem.rev_usr_user_id_reviewed__c = workItem.rev_usr_user_id_reviewed__c == null ?  wiX.pro_user_id__c : workItem.rev_usr_user_id_reviewed__c;
        workItem.pro_first_name__c = wiX.pro_first_name__c;
        workItem.pro_last_name__c = wiX.pro_last_name__c;
        workItem.pro_email__c = wiX.pro_email__c;
        workItem.rev_usr_user_id_reviewer__c = workItem.rev_usr_user_id_reviewer__c == null ? wiX.customer_user_id__c : workItem.rev_usr_user_id_reviewer__c;
        workItem.customer_first_name__c = wiX.customer_first_name__c;
        workItem.customer_last_name__c = wiX.customer_last_name__c;
        workItem.customer_email__c = wiX.customer_email__c;
        workItem.bid_bid_id__c = wiX.bid_bid_id__c;
        workItem.RequestCategoryId__c = wiX.category_id_decoded__c;
        workItem.rev_review_id__c = wiX.review_id__c;
        workItem.rev_review_time__c = wiX.review_time__c;
        workItem.rev_rating__c = wiX.rating__c;
        workItem.rca_name__c = wiX.rca_name__c;
        workItem.rev_text__c = wiX.text__c;
        workItem.rev_response_text__c = wiX.response_text__c;
        workItem.rev_private_feedback_to_reviewed_user__c = wiX.feedback_private_to_user__c;
        workItem.rev_private_feedback_to_thumbtack__c = wiX.feedback_private_to_thumbtack__c;

        //if new record, populate map for further processing
        if(newWorkItem){ newWorkItemMap.put(workItem.rev_review_id__c,workItem); }
    }
}