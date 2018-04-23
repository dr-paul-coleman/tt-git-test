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
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     04-12-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
public class BackgroundCheckTriggerHandler 
{
    public static Group miQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Marketplace Integrity' LIMIT 1];
    public static void beforeInsert(List<BackgroundCheck__c> bChecks)
    {
        List<String>ids = new List<String>();
         system.debug('in bcheck handler insert');
        for(BackgroundCheck__c bc:bChecks)
        {
             system.debug('bc.ReportId__c: '+bc.ReportId__c );
            if(bc.ReportId__c != null)
            {
                system.debug('in bcheck handler insert');
                bc.OwnerId = miQueue.Id;
                bc.Status__c = 'Consider';
                ids.add(bc.ReportId__c);
            }
        }
        try{CheckrAPI.getCheckr(ids);}
        catch(Exception e){system.debug(e);}
        
    }
    public static void beforeUpdate(List<BackgroundCheck__c> bChecks,List<BackgroundCheck__c> oldBChecks)
    {
        List<String>emails= new List<String>();
        Map<String,BackgroundCheck__c> bCheckMap = new Map<String,BackgroundCheck__c>();
        Map<String,Id> accMap = new Map<String,Id>();
        List<Account> accList = [Select Id,usr_email__c From Account Where usr_email__c In:emails];
        for(Account a:accList)accMap.put(a.usr_email__c,a.Id);
        List<String> bChecksIds = new List<String>();
         system.debug('in bcheck handler update');
        for(BackgroundCheck__c bc:bChecks)
        {
            system.debug('bc.ReportId__c: '+bc.ReportId__c + ', Report Record Id: '+bc.Id + ', ContactID: '+bc.Contact__c);
            if(accMap.containsKey(bc.SuppliedEmail__c))
            {
                bc.Account__c = accMap.get(bc.SuppliedEmail__c);
            }
            if(bc.ReportId__c != null )
            {
                bc.OwnerId = miQueue.Id;
                bc.Status__c = 'Consider';
                bCheckMap.put(bc.ReportId__c,bc);
            }
        }
        List<Case> cases =[Select Id,BGCCharges__c,OwnerId,AccountId,ContactId,BackgroundCheck__c,BGCReportId__c,SuppliedName,SuppliedEmail From Case Where BGCReportId__c IN: bCheckMap.keySet()];
        try{CheckrAPI.syncCaseToBCheck(bCheckMap,cases);}
        catch(Exception e){system.debug(e);}
    }

}