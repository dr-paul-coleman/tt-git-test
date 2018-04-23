/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/25/17      pcoleman           Created
1.1       04/02/17      pcoleman           removed user id mapping in Account update
========+============+=================+===============================================*/
public with sharing class AccountOpenMTSIncidentSync implements Queueable
{
    MIIncident__c[] incidents;
    Map<Id,MIIncident__c> oldIncidentMap;

    public AccountOpenMTSIncidentSync(MIIncident__c[] triggerNew, Map<Id,MIIncident__c> triggerOldMap)
    {
        this.incidents = triggerNew;
        this.oldIncidentMap = triggerOldMap;
    }

    public void execute(QueueableContext ctx)
    {
        Set<Decimal> userIds = new Set<Decimal>();
        Account[] accountsForUpdate = new Account[0];
        Set<Id> accountIds = new Set<Id>();

        // 1] Gather all user ids and account ids for lookup query
        for (MIIncident__c incident : incidents)
        {
            if ( !String.isEmpty(incident.pro_user_id__c) ) { userIds.add(Decimal.valueOf(incident.pro_user_id__c)); }
            if ( !String.isEmpty(incident.customer_id__c) ) { userIds.add(Decimal.valueOf(incident.customer_id__c)); }
            if ( !String.isEmpty(incident.ProAccount__c) ) { accountIds.add(incident.ProAccount__c); }
            if ( !String.isEmpty(incident.CustomerAccount__c) ) { accountIds.add(incident.CustomerAccount__c); }
            if (NULL != oldIncidentMap)
            {
                MIIncident__c oldIncident = oldIncidentMap.get(incident.Id);
                if (NULL != oldIncident)
                {
                    if ( !String.isEmpty(oldIncident.pro_user_id__c) ) { userIds.add(Decimal.valueOf(oldIncident.pro_user_id__c)); }
                    if ( !String.isEmpty(oldIncident.customer_id__c) ) { userIds.add(Decimal.valueOf(oldIncident.customer_id__c)); }
                    if ( !String.isEmpty(oldIncident.ProAccount__c) ) { accountIds.add(oldIncident.ProAccount__c); }
                    if ( !String.isEmpty(oldIncident.CustomerAccount__c) ) { accountIds.add(oldIncident.CustomerAccount__c); }
                }
            }
        }

        MIIncident__c[] accountsMiIncidents = new MIIncident__c[0];
        // 2] determine which Accounts are out of sync with open MI incidents Status
        for (Account[] accounts : [SELECT Id, usr_user_id__c, MIOpenIncident__c, (SELECT Status__c FROM MIIncidentsCustomer__r WHERE IsDeleted = false), (SELECT Status__c FROM MIIncidentsPro__r WHERE IsDeleted = false) FROM Account WHERE Id IN :accountIds OR usr_user_id__c IN :userIds ALL ROWS])
        {
            for (Account accnt : accounts) //large data set for-each pattern
            {
                accountsMiIncidents.clear();  //clearing is more efficient than newing an array in a loop
                accountsMiIncidents.addAll( accnt.MIIncidentsCustomer__r );
                accountsMiIncidents.addAll( accnt.MIIncidentsPro__r );
                Boolean open = false;

                // look for any (at least one) open MI incident, if found, set the account's MIOpenIncident flag to true, otherwise set it to false
                for (MIIncident__c miOfAccount : accountsMiIncidents)
                {
                    if ( !'Closed'.equalsIgnoreCase(miOfAccount.Status__c) ) { open = true; break; }
                }

                if ( open != accnt.MIOpenIncident__c ) { accountsForUpdate.add( new Account( Id = accnt.Id, LastSyncedWithDataPlatform__c = null, MIOpenIncident__c = open ) ); }
            }
        }

        // UPDATE all Accounts needing a OPEN MI flag change (and force Becky TT User Sync via LastSyncedWithDataPlatform__c = null )
        if (!accountsForUpdate.isEmpty()) { QueueableUtility.handleQueueable( new DMLQueueable(accountsForUpdate, DMLQueueable.Operation.UPDATES) ); }
    }
}