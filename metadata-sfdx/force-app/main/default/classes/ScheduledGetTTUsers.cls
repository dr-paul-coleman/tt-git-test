/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       11/8/17      paulcoleman          Created
========+============+=================+===============================================*/
global with sharing class ScheduledGetTTUsers implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful
{
    private Id[] accountIds;
    global ScheduledGetTTUsers() {}

    global ScheduledGetTTUsers(Id[] accountIds) {
        this.execute( NULL, [SELECT Id, usr_email__c, usr_user_id__c, user_pk_id__c, CreatedDate, LastSyncedWithDataPlatform__c FROM Account WHERE RecordType.DeveloperName IN ('Customer', 'ThumbtackPro') AND CreatedDate = THIS_WEEK AND Id IN :accountIds] );
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Kick off Batchable.
    * @param SchedulableContext Note used.
    */
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch( new ScheduledGetTTUsers(), 100 );
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Kick off remote Becquerel External Object sync.
    * @param BatchableContext Note used.
    */
    global void execute( Database.BatchableContext bc, SObject[] accounts )
    {
        Account[] targetAccounts = new Account[0];
        for( SObject s: accounts )
        {
            Account a = (Account)s;
            if ( ( a.usr_user_id__c > 0 || NULL != a.usr_email__c || NULL != a.user_pk_id__c ) && NULL == a.LastSyncedWithDataPlatform__c )
            {
                targetAccounts.add(a);
            }
        }
        if( !targetAccounts.isEmpty() ) { new BeckyTTUserSyncQueueable( targetAccounts ).execute( NULL ); }
    }


    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, usr_email__c, usr_user_id__c, user_pk_id__c, CreatedDate, LastSyncedWithDataPlatform__c FROM Account WHERE RecordType.DeveloperName IN ('Customer', 'ThumbtackPro') AND CreatedDate = THIS_WEEK ]);
    }

    global void finish(Database.BatchableContext bc) {}

}