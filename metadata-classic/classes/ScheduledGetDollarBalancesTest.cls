/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/26/17      pcoleman           Created
========+============+=================+===============================================*/
@IsTest
public with sharing class ScheduledGetDollarBalancesTest
{

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Simulate running a remote Becquerel External Object sync.
    */
    @IsTest
    private static void testBeckySyncForDollarBalances() {

        Account testPro = TestUtilities.CORE_ACCOUNT.clone();
        insert testPro;

        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            testPro = TestUtilities.getTestAccountWithContact(testPro.Id);
            becquerel_qs_dollar_balance__x balance = BecquerelUtility.createTestExternalDollarBalances(1)[0];
            testPro.usr_user_id__c = balance.usr_user_id__c;
            testPro.user_pk_id__c = String.valueOf( balance.user_pk_id__c );
            testPro.uct_purchased_balance_cents__c = -1;
            update testPro;

            Test.startTest();

                new ScheduledGetDollarBalances().execute(NULL);

            Test.stopTest();

            System.assertEquals( balance.uct_total_promotional_cents__c, [SELECT uct_total_promotional_cents__c FROM Account WHERE Id = :testPro.Id LIMIT 1].uct_total_promotional_cents__c, 'ScheduledGetDollarBalances sync did not create DollarBalance => Account parity on uct_total_promotional_cents__c' );


        } //end RunAs
    }

}