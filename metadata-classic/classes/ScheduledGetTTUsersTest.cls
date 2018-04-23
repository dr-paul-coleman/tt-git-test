/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       11/8/17      paulcoleman          Created
========+============+=================+===============================================*/
@IsTest
public with sharing class ScheduledGetTTUsersTest
{
    /**
       * @author Paul Coleman
       * @date 2017-11-08
       * @description Simulate running a remote Becquerel External Object sync.
       */
    @IsTest
    private static void testBeckySyncForUsers() {

        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            becquerel_tt_user_for_tack__x tackUser = BecquerelUtility.createTestExternalUsers( 1, true )[0];
            Account testAccount = TestUtilities.CORE_ACCOUNT.clone();
            testAccount.usr_user_id__c = tackUser.usr_user_id__c;
            testAccount.user_pk_id__c = String.valueOf( tackUser.user_pk_id__c );
            testAccount.usr_email__c = tackUser.usr_email__c;
            testAccount.LastSyncedWithDataPlatform__c = Datetime.now(); //prevent normal becky trigger-based sync
            insert testAccount;

            Test.startTest();

                testAccount.usr_email__c = 'somethingtotallybogus@testingbeckysync.com';
                update testAccount;
                new ScheduledGetTTUsers().execute( (SchedulableContext)NULL );

            Test.stopTest();

            // No Assertion because impossible to meet Account.CreateDate threshold job < 24 hours but greater than 6 hourse old

        } //end RunAs
    }
}