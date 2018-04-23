/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
******************************************************************************** 

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       04/04/2017     Scott Purcell          Created
========+============+=================+===============================================*/

public with sharing class DeleteBlacklisted {
	
    public static void blacklisted()
    {
        List<WorkItem__c> nids = new List<WorkItem__c>();
        List<Decimal> userIds = new List<Decimal>();
        List<String> workItemIds = new List<String>();
        List<WorkItem__c> wiList = [Select Id,Type__c,rev_usr_user_id_reviewed__c,usr_user_id__c From WorkItem__c Where Type__c =:'Blacklisted Number'];
        for(WorkItem__c wi: wiList)
        {
            userIds.add(wi.rev_usr_user_id_reviewed__c);
        }
        List<Account> accSet = [Select Name,Id,WhiteListed__c,usr_user_id__c From Account Where WhiteListed__c =:true AND usr_user_id__c IN: userIds];
        system.debug('workItemIds: '+workItemIds);
        system.debug('accSet.size(): '+accSet.size());
        
        for(Account acc:accSet)
        {
            for(WorkItem__c wi: wiList)
            {
                if(wi.Type__c == 'Blacklisted Number' && wi.rev_usr_user_id_reviewed__c == acc.usr_user_id__c)
                    nids.add(wi);
            }
        }
        system.debug('deletelist: '+nids.size());
        if(nids.size()>0)
        {
            delete nids;
            system.debug('deletelist: successfully deleted');
        }
    }
}