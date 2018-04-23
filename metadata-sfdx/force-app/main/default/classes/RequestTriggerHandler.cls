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
=======+===========+=================+==============================================
1.0     2016-12-06   Scott Purcell      Created
1.1.    04/10/2017   Scott Purcell      Added Bequerel code that will need to be uncommmented
1.2.    07/14/2017   Paul Coleman       refactored getEncodedServiceId logic to use common untility
                                        function ProRequestsEmailService.getServiceDetails()
=======+===========+=================+=============================================*/
public with sharing class RequestTriggerHandler
{

    private static final Id PRO_ASSIST_RECORD_TYPE_ID = Request__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Pro Assistance Request').getRecordTypeId();
    private static final Id DID_NOT_QUOTE_Q_ID = [Select Id, QueueId From QueueSobject Where SobjectType = 'Request__c' And Queue.Name = 'Did Not Quote' LIMIT 1].QueueId;

    public static void OnBeforeInsert(List<Request__c> newRequests)
    {
        Map<String, List<Request__c>> reqsByServiceIdMap = new Map<String, List<Request__c>>();
        for (Request__c request : newRequests)
        {
            if (request.QuotingServiceStatus__c == 'Off')
            {
                request.Status__c = 'Pro Paused';
            }
            if (request.PurchasedBalance__c < 0 && request.BalanceState__c == 2)
            {
                request.Status__c = 'No Balance - Cant Quote';
                request.OwnerId = DID_NOT_QUOTE_Q_ID;
            }
            if (request.RecordTypeId == PRO_ASSIST_RECORD_TYPE_ID)
            {
                //PBC 2014-07-14: only do Encoded id parse and service lookup if they are non-null
                if ( String.isEmpty( request.EncodedServiceID__c )  ||  String.isEmpty( request.EncodedRequestID__c ) || String.isEmpty(request.EmailSendQuoteLink__c) )
                {
                    doRequestInfoParse(request, reqsByServiceIdMap);
                }
            }
        }
        List<Id> ids = new List<Id>();
        List<String> accIds = new List<String>();
        List<Decimal> userIDs = new List<Decimal>();
        for (Request__c r : newRequests)
        {
            ids.add(r.Service__c);
            r.LastSyncedWithDataPlatform__c = DateTime.now();


        }
        //system.debug('ids: '+ids);
        List<Service__c> servs = [Select Id,ProAccount__r.ContactBudget__c,ProAccount__r.usr_user_id__c FROM Service__c Where Id in:ids];
        system.debug('servs: ' + servs);
        //***************************************************************
        for (Service__c serv : servs)
        {
            accIds.add(serv.ProAccount__c);
            userIDs.add(serv.ProAccount__r.usr_user_id__c);
        }
        associateRequestToServiceByEncodedId(reqsByServiceIdMap);
    }

    public static void OnBeforeUpdate(Map<Id, Request__c> oldRequests, List<Request__c> updatedRequests)
    {
        List<String> accIds = new List<String>();
        system.debug('old: ' + oldRequests + ' // new: ' + updatedRequests);
        List<Decimal> userIds = new List<Decimal>();
        Map<String, List<Request__c>> reqsByServiceIdMap = new Map<String, List<Request__c>>();
        //*************** Added 4-6-2017-Scott Purcell-to include becky services
        List<Id> ids = new List<Id>();
        for (Request__c r : updatedRequests)
        {
            ids.add(r.Service__c);
            r.LastSyncedWithDataPlatform__c = DateTime.now();

        }

        List<Service__c> servs = [Select Id,ProAccount__r.ContactBudget__c,ProAccount__r.usr_user_id__c FROM Service__c Where Id in:ids];
        //***************************************************************
        for (Service__c serv : servs)
        {
            userIds.add(serv.ProAccount__r.usr_user_id__c);
        }
        //***************************************************************
        for (Request__c request : updatedRequests)
        {
            for (Service__c serv : servs)
            {
                if (serv.Id == request.Service__c)
                {
                    Request__c oldRequest = oldRequests.get(request.Id);
                    if (request.QuotingServiceStatus__c == 'Off')
                    {
                        request.Status__c = 'Pro Paused';
                    }
                    if (request.RecordTypeId == PRO_ASSIST_RECORD_TYPE_ID && request.EncodedServiceID__c != oldRequest.EncodedServiceID__c)
                    {
                        //PBC 2017-07-14, only do Encoded id parse and service lookup if they are non-null
                        if ( String.isEmpty( request.EncodedServiceID__c )  ||  String.isEmpty( request.EncodedRequestID__c ) || String.isEmpty(request.EmailSendQuoteLink__c) )
                        {
                            doRequestInfoParse(request, reqsByServiceIdMap);
                        }
                    }
                }
            }
        }
        for (Service__c serv : servs)
        {
            accIds.add(serv.ProAccount__c);
            userIDs.add(serv.ProAccount__r.usr_user_id__c);
        }
        associateRequestToServiceByEncodedId(reqsByServiceIdMap);
    }

    //PBC 2017-07-17, added to bind ProRequestsEmailService dependency (not re-invent the wheel)
    public static ProRequestsEmailService.TTServiceInfo doRequestInfoParse(Request__c request, Map<String, List<Request__c>> requestMap)
    {

        ProRequestsEmailService.TTServiceInfo serviceInfo;
        if (null != request && null != request.EmailHTMLBodyLong__c)
        {
            serviceInfo = ProRequestsEmailService.getServiceDetails(request.EmailHTMLBodyLong__c);
            if (null != serviceInfo)
            {
                request.EncodedServiceID__c = serviceInfo.encodedServiceId;
                request.EmailSendQuoteLinkPart1__c = serviceInfo.serviceUrl;
                request.EncodedRequestID__c = serviceInfo.requestId;
                request.EmailSendQuoteLink__c = serviceInfo.serviceUrl;
                request.UrlParms__c = serviceInfo.parmJSON;

                if (null == request.Service__c && String.isNotBlank(request.EncodedServiceID__c) && null != requestMap)
                {
                    List<Request__c> reqs = requestMap.get(request.EncodedServiceID__c);
                    reqs = (reqs == null) ? new List<Request__c>() : reqs;
                    reqs.add(request);
                    requestMap.put(request.EncodedServiceID__c, reqs);
                }
            }
        }
        return null == serviceInfo ? new ProRequestsEmailService.TTServiceInfo(NULL, NULL, NULL, NULL) : serviceInfo;
    }

    private static void associateRequestToServiceByEncodedId(Map<String, List<Request__c>> reqsByServiceIdMap)
    {
        //PBC 2017-07-16: created more null pointer exception resistance
        if (!reqsByServiceIdMap.isEmpty())
        {
            //loop services and requests accessible from reqByServiceIdMap, if any
            for (Service__c serv : [Select Id, EncodedServiceID__c From Service__c Where EncodedServiceID__c IN :reqsByServiceIdMap.keySet()])
            {
                //get child request from encoded Id map, if any
                List<Request__c> reqs = reqsByServiceIdMap.get(serv.EncodedServiceID__c);
                if (null != reqs)
                {
                    for (Request__c req : reqs)
                    {
                        // if each request matches the service's encoded service id and is not already set, 
                        // assign service parent id to request
                        if (null != req && null != req.Service__c)
                        {
                            req.Service__c = serv.Id;
                        }
                    }
                }
            }
        }
    }

}