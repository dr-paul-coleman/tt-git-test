/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       1/26/18      jkennington          Created
========+============+=================+===============================================*/
@isTest
private class TTUserForTackControllerTest
{
    @TestSetup
    private static void createTestAccount()
    {
        insert TestUtilities.CORE_ACCOUNT.clone();
    }

    @IsTest
    private static void getExternalObjectId()
    {
        System.runAs(TestUtilities.USER_TACK_BOT)
        {
            Test.startTest();
            Account acc = TestUtilities.getTestAccountWithContact();
            String result = TTUserForTackController.getExternalObjectId(acc.Id);
            Test.stopTest();

            System.assert(result == acc.usr_user_id__c.toPlainString(), 'Correct userId not returned');
        }

    }
}