/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/23/17      pcoleman           Created
1.1       2017-12-14   Mendel Guillaume  Get tackbot user
========+============+=================+===============================================*/
@IsTest
public class TackBotUtilityTest
{

    @IsTest
    private static void testSendAdminEmailException() {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
                Messaging.SendEmailResult[] results;
                try
                {
                    Decimal i = 12 / 0;
                } catch ( System.MathException mex ) {
                    results = TackBotUtility.sendExceptionEmail( mex,  'TackBotUtilityTest.testSendAdminEmailException' );
                    TackBotUtility.postTackLogException(  mex,  'TackBotUtilityTest.testSendAdminEmailException' );
                }
            Test.stopTest();

            System.assert( NULL != results, 'Send Admin Email by Exception did not return an array of Messaging.SendEmailResult' );
            System.assertNotEquals( 0 , [SELECT count() FROM TackLog__c], 'Send Admin Email did not insert a TackLog record' );
        }
    }

    @IsTest
    static void testGetTackBotUser()
    {
        System.assertNotEquals(null, TackBotUtility.getTackBotUser());
    }
}