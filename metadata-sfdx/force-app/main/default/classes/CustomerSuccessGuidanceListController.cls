/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
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

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-25   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class CustomerSuccessGuidanceListController
{
    @AuraEnabled
    public static List<CustomerSuccessGuidance__c> getRecords(String accountId)
    {
        return [SELECT Id, Name, Account__c, Flag__c, FlagType__c, FlagExplanation__c, CreatedDate, Owner.Name
        FROM CustomerSuccessGuidance__c WHERE Account__c =:accountId AND Account__c != null ORDER BY SortOrder__c DESC];
    }
}