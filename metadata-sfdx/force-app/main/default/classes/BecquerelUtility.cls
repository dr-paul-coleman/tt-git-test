/*
  Copyright (c) 2017 Thumbtack  All rights reserved.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-09-17  Paul Coleman      Created to support aspects of remote object execution
                                       NOTE: Many of these functions are called within Becky Queueables
                                         to support test runs where outbound HTTP vis external object
                                         queries is not supported, and therefore get code coverage
                                         within those contexts. To avoid over-testing during production
                                         deployment windows, this class therefore does not have a dedicated
                                         test class.
 1.1     2018-01-26  Kristin Hasna     Added managed account and revenue fields from becquerel_tt_user_for_tack__x
 =======+===========+=================+=================================*/
public with sharing class BecquerelUtility
{
    public static final Boolean IS_TEST_RUN = Test.isRunningTest(); //used to facilitate SF Connect testing (remote oData callouts)
    public static final Decimal PRO_USER_ID =  12345;
    public static final Decimal PRO_USER_PK_ID =  1234512345L;
    public static final String PRO_FIRST_NAME =  'Chester';
    public static final String PRO_LAST_NAME =  'Pro';
    public static final String PRO_FULL_NAME = PRO_FIRST_NAME + ' ' + PRO_LAST_NAME;
    public static final String PRO_EMAIL =  'boguspro@bogus.domainnotvalid.com';
    public static final Decimal CUSTOMER_USER_ID =  54321;
    public static final Decimal CUSTOMER_USER_PK_ID =  5432154321L;
    public static final String CUSTOMER_FIRST_NAME =  'Wiley';
    public static final String CUSTOMER_LAST_NAME =  'Customer';
    public static final String CUSTOMER_FULL_NAME = CUSTOMER_FIRST_NAME + ' ' + CUSTOMER_LAST_NAME;
    public static final String CUSTOMER_EMAIL =  'boguscustomer@bogus.domainnotvalid.com';
    public static final Decimal BID_BID_ID =  77677;

    public static becquerel_tt_user_for_tack__x[] createTestExternalUsers( Integer numberOfObjects, Boolean isPro )
    {
        becquerel_tt_user_for_tack__x[] result = new becquerel_tt_user_for_tack__x[0];
        Integer count =  ( null == numberOfObjects || 0 == numberOfObjects ) ? 1 : numberOfObjects;
        for ( Integer i = 0; i < count; i++ )
        {
            String iStr = String.valueOf(i);
            result.add(new becquerel_tt_user_for_tack__x(
                    sav_business_name__c = (isPro? 'Test Pro': 'Test Customer') + iStr,
                    usr_last_name__c = ( isPro? PRO_LAST_NAME: CUSTOMER_LAST_NAME )  + iStr,
                    usr_first_name__c = ( isPro? PRO_FIRST_NAME: CUSTOMER_FIRST_NAME )  + iStr,
                    usr_email__c = '_' + iStr + ( isPro? PRO_EMAIL: CUSTOMER_EMAIL ),
                    usr_user_id__c = ( isPro? PRO_USER_ID: CUSTOMER_USER_ID )  + i,
                    user_pk_id__c = ( isPro? PRO_USER_PK_ID: CUSTOMER_USER_PK_ID )  + i,
                    phn_phone_number__c = '+' + iStr + '5555555550',
                    usa_state__c = 'NY',
                    usr_timezone__c = 'America/Los_Angeles',
                    user_type__c = (isPro? 'Pro' : 'Customer'),
                    managed_account__c = true,
                    revenue__c = 5000
                )
            );
        }
        return result;
    }

    public static becquerel_mi_incident_project_data__x[] createTestExternalIncidents(Integer numberOfObjects)
    {
        becquerel_mi_incident_project_data__x[] result = new becquerel_mi_incident_project_data__x[0];
        Integer count =  ( null == numberOfObjects || 0 == numberOfObjects ) ? 1 : numberOfObjects;
        Datetime now = DateTime.now();
        for ( Integer i = 0; i < count; i++ )
        {
            String iStr = String.valueOf(i);
            result.add(new becquerel_mi_incident_project_data__x(
                    bid_id__c = BID_BID_ID + i,
                    pro_user_id__c = PRO_USER_ID + i,
                    pro_user_pk_id__c = PRO_USER_PK_ID + i,
                    customer_id__c = CUSTOMER_USER_ID + i,
                    customer_pk_id__c = CUSTOMER_USER_PK_ID + i,
                    pro_email__c = '_' + iStr + PRO_EMAIL,
                    pro_first_name__c = PRO_FIRST_NAME,
                    pro_last_name__c = PRO_LAST_NAME,
                    pro_signup_date__c = now,
                    customer_email__c = '_' + iStr + CUSTOMER_EMAIL,
                    customer_first_name__c = CUSTOMER_FIRST_NAME,
                    customer_last_name__c = CUSTOMER_LAST_NAME,
                    hired__c = false,
                    most_recent_phone_number__c = '123444555' + iStr,
                    request_create_time__c = now,
                    request_id__c = 111 + i,
                    service_id__c = 222 + i
            ));
        }
        return result;
    }

    public static becquerel_concerning_reviews__x[] createTestExternalConcerningReviews(Integer numberOfObjects)
    {
        becquerel_concerning_reviews__x[] result = new becquerel_concerning_reviews__x[0];
        Integer count = null == numberOfObjects || 0 == numberOfObjects ? 1 : numberOfObjects;
        for ( Integer i = 0; i < count; i++ )
        {
            String iStr = String.valueOf(i);
            result.add(  new becquerel_concerning_reviews__x(
                    pro_first_name__c = PRO_FIRST_NAME,
                    pro_last_name__c = PRO_LAST_NAME,
                    pro_email__c = '_' + iStr + PRO_EMAIL,
                    customer_first_name__c = CUSTOMER_FIRST_NAME,
                    customer_last_name__c = CUSTOMER_LAST_NAME,
                    customer_email__c = '_' + iStr + CUSTOMER_EMAIL,
                    bid_bid_id__c = BID_BID_ID + i,
                    review_id__c = 1234+i,
                    rca_name__c = 'name'+iStr
                )
            );
        }
        return result;
    }

    public static becquerel_qs_dollar_balance__x[] createTestExternalDollarBalances(Integer numberOfObjects)
    {
        becquerel_qs_dollar_balance__x[] result = new becquerel_qs_dollar_balance__x[0];
        Integer count = ( null == numberOfObjects || 0 == numberOfObjects )? 1 : numberOfObjects;
        for ( Integer i = 0; i < count; i++ )
        {
            String iStr = String.valueOf(i);
            result.add(  new becquerel_qs_dollar_balance__x(
                    uct_total_promotional_cents__c = 2,
                    uct_balance_state__c = 1,
                    uct_purchased_balance_cents__c = 2,
                    usr_user_id__c = PRO_USER_ID + i,
                    user_pk_id__c = PRO_USER_PK_ID + i
                )
            );
        }
        return result;
    }


    public static becquerel_qs_bid_bids__x[] createTestExternalBids(Integer numberOfObjects)
    {
        becquerel_qs_bid_bids__x[] result = new becquerel_qs_bid_bids__x[0];
        Integer count =  ( null == numberOfObjects || 0 == numberOfObjects ) ? 1 : numberOfObjects;
        Datetime now = DateTime.now();
        for ( Integer i = 0; i < count; i++ )
        {
            String iStr = String.valueOf(i);
            result.add(new becquerel_qs_bid_bids__x(
                    bid_bid_id__c = BID_BID_ID + i,
                    bid_bid_pk__c = BID_BID_ID + i,
                    bid_buyer_first_seen_time__c = now,
                    bid_create_time__c = now,
                    bid_estimate_price_per_unit__c = iStr,
                    bid_estimate_type__c = 1,
                    bid_review_ask_time__c = now,
                    bid_sav_available_service_id__c = 1,
                    bid_sent_time__c = now,
                    bid_status__c = 1,
                    usr_first_name__c = CUSTOMER_FIRST_NAME,
                    usr_last_name__c = CUSTOMER_LAST_NAME,
                    req_usr_user_id__c = CUSTOMER_USER_ID + 1,
                    bid_status_usr_user_id__c = CUSTOMER_USER_ID + i,
                    bid_url_code__c = '1',
                    rca_name__c = 'name',
                    req_needed_time__c = now,
                    req_phn_phone_number_id__c = 2223334444.0,
                    req_schedule_description__c = 'test description',
                    req_status__c = 1,
                    req_url_code__c = '1',
                    bid_usr_user_id__c = PRO_USER_ID + i
                )
            );
        }
        return result;
    }

}