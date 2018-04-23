/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/20/17      pcoleman           Created. NOTE: full test code coverage achieved
                                                from ScheduledGetQuoteTest
========+============+=================+===============================================*/
public with sharing class BeckyQuotesSyncQueueable implements Queueable
{

    private Map<Decimal, becquerel_qs_bid_bids__x> bidIdBidsMap;
    private Map<Decimal, Quote__c> quoteRecordsForUpsertMap;
    private Id qsRecordTypeId;


    public BeckyQuotesSyncQueueable() {
        this.bidIdBidsMap = new Map<Decimal, becquerel_qs_bid_bids__x>();
        this.quoteRecordsForUpsertMap = new Map<Decimal, Quote__c>();
        this.qsRecordTypeId = Quote__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Quoting Service Record Type').getRecordTypeId();
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Sync local SF records with remote Becquerel External Objects.
    * @param QueueableContext Not used.
    */
    public void execute(QueueableContext context)
    {

        try
        {
            if( !Trigger.isExecuting )
            {
                // GET External Bid records
                for ( becquerel_qs_bid_bids__x externalBid : BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalBids( 1 ) : [ SELECT bid_req_request_id__c, bid_bid_id__c, bid_buyer_first_seen_time__c, bid_create_time__c, bid_estimate_price_per_unit__c, bid_estimate_type__c, bid_review_ask_time__c, bid_sav_available_service_id__c, req_status__c, usr_first_name__c, bid_sent_time__c, bid_status__c, bid_status_usr_user_id__c, bid_url_code__c, bid_usr_user_id__c, rca_name__c, req_needed_time__c, req_phn_phone_number_id__c, req_schedule_description__c, req_url_code__c, usr_last_name__c FROM becquerel_qs_bid_bids__x LIMIT 2000 ] )
                {
                    this.bidIdBidsMap.put( externalBid.bid_bid_id__c, externalBid );
                }

                // GET SF-side quote records
                for ( Quote__c salesforceQuote : [ SELECT Id, Name, bid_req_request_id__c, bid_bid_id__c, bid_buyer_first_seen_time__c, bid_create_time__c, bid_estimate_price_per_unit__c, bid_estimate_type__c, bid_review_ask_time__c, bid_sav_available_service_id__c, bid_status__c, bid_url_code__c, bid_usr_user_id__c, rca_name__c, req_needed_time__c, req_phn_phone_number__c, req_schedule_description__c, req_status__c, req_url_code__c, req_usr_first_name__c, req_usr_last_name__c FROM Quote__c WHERE bid_bid_id__c IN :this.bidIdBidsMap.keySet() ] )
                {
                    this.quoteRecordsForUpsertMap.put( salesforceQuote.bid_bid_id__c, salesforceQuote );
                }

                //SYNC RECORD DATA
                Decimal i = 1;
                for ( becquerel_qs_bid_bids__x quoteExternal : this.bidIdBidsMap.values() )
                {
                    Quote__c quote = this.quoteRecordsForUpsertMap.get( quoteExternal.bid_bid_id__c );
                    quote = ( NULL == quote ) ? new Quote__c( RecordTypeId = this.qsRecordTypeId ) : quote;
                    quote.Name = String.valueOf( quoteExternal.bid_bid_id__c );
                    quote.req_phn_phone_number__c = ( NULL == quoteExternal.req_phn_phone_number_id__c ) ? null : String.valueOf( quoteExternal.req_phn_phone_number_id__c );
                    quote.bid_req_request_id__c = quoteExternal.bid_req_request_id__c;
                    quote.bid_bid_id__c = quoteExternal.bid_bid_id__c;
                    quote.bid_buyer_first_seen_time__c = quoteExternal.bid_buyer_first_seen_time__c;
                    quote.bid_create_time__c = quoteExternal.bid_create_time__c;
                    quote.bid_estimate_price_per_unit__c = quoteExternal.bid_estimate_price_per_unit__c;
                    quote.bid_estimate_type__c = quoteExternal.bid_estimate_type__c;
                    quote.bid_review_ask_time__c = quoteExternal.bid_review_ask_time__c;
                    quote.bid_sav_available_service_id__c = quoteExternal.bid_sav_available_service_id__c;
                    quote.bid_sent_time__c = quoteExternal.bid_sent_time__c;
                    quote.bid_status__c = quoteExternal.bid_status__c;
                    quote.bid_status_usr_user_id__c = quoteExternal.bid_status_usr_user_id__c;
                    quote.bid_url_code__c = quoteExternal.bid_url_code__c;
                    quote.bid_usr_user_id__c = quoteExternal.bid_usr_user_id__c;
                    quote.rca_name__c = quoteExternal.rca_name__c;
                    quote.req_needed_time__c = quoteExternal.req_needed_time__c;
                    quote.req_schedule_description__c = ( NULL == quoteExternal.req_schedule_description__c ) ? '' : quoteExternal.req_schedule_description__c.abbreviate( 254 );
                    quote.req_status__c = quoteExternal.req_status__c;
                    quote.req_url_code__c = quoteExternal.req_url_code__c;
                    quote.req_usr_first_name__c = quoteExternal.usr_first_name__c;
                    quote.req_usr_last_name__c = quoteExternal.usr_last_name__c;
                    if ( NULL == quote.Id ) { this.quoteRecordsForUpsertMap.put( i, quote ); } //push new record onto list with dummy unique key, for upsert
                    i++;
                }

                // UPSERT SF-side records
                System.debug( LoggingLevel.FINEST, JSON.serialize( Database.upsert(  this.quoteRecordsForUpsertMap.values(), false ) ) );

            }
        }
        catch ( System.Exception ex )
        {
            System.debug(LoggingLevel.ERROR, ex); // skip HTTP 504 Errors when trying to do oData queries
            if( !ex.getMessage().contains( 'Error received from the external system: 50') && !ex.getMessage().contains( 'Apex triggers can\'t reference external objects or call out to external data sources' ) ) { TackBotUtility.sendExceptionEmail( ex, 'BeckyQuotesSyncQueueable.execute()' ); }
        }
    }
}