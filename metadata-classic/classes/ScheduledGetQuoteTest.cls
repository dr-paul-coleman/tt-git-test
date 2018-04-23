/*

   Copyright (c) 2017 Thumbtack. All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       04/04/2017     Scott Purcell          Created
2.0       10/20/1027   Paul Coleman      Refactored for new Queueables
========+============+=================+===============================================*/
@isTest
private class ScheduledGetQuoteTest {

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Simulate running a remote Becquerel External Object sync.
    */
    @IsTest
    private static void testBeckySyncForQuotes() {

        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            becquerel_qs_bid_bids__x bid = BecquerelUtility.createTestExternalBids(1)[0];
            Quote__c quote = new Quote__c( Name = 'Bogus Name', bid_bid_id__c = bid.bid_bid_id__c );
            insert quote;

            Test.startTest();

                new ScheduledGetQuote().execute(NULL);

            Test.stopTest();

            System.assertEquals( String.valueOf( bid.bid_bid_id__c ), [SELECT Name FROM Quote__c WHERE Id = :quote.Id LIMIT 1].Name, 'ScheduledGetQuote sync did not create Bid => Quote parity on bid_bid_id__c => Name' );


        } //end RunAs
    }
	
}