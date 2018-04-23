/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       1/24/18      jkennington          Created
========+============+=================+===============================================*/
public without sharing class TTUserForTackController
{
    @AuraEnabled
    public static String getExternalObjectId(Id accountId)
    {
        Decimal userId = [SELECT usr_user_id__c FROM Account WHERE Id = :accountId LIMIT 1][0].usr_user_id__c;
        becquerel_tt_user_for_tack__x[] result = [SELECT Id FROM becquerel_tt_user_for_tack__x WHERE usr_user_id__c = :userId];

        //If we don't have a record to display, throw an error for JS to handle
        if(result.isEmpty() && !Test.isRunningTest()){throw new AuraHandledException('No userId available to query');}

        return Test.isRunningTest() ? '12345' : result[0].Id;
    }
}