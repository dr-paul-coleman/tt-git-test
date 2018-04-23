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
1.0      2017-08-16   Mendel Guillaume       Created
1.1      2017-12-20   Kristin Hasna          Added new value to Type__c options
========+============+=================+===============================================*/

public with sharing class IncidentPayoutRequestManagerController
{
    @AuraEnabled
    public static String save(MIIncidentAction__c request)
    {
        String response = 'Success';

        try
        {
            request.RecordTypeId = MiIncidentActionTriggerHandler.PayoutRTId;
            upsert request;

        }
        catch(Exception ex)
        {
            response = ex.getMessage() + ' - ' + ex.getStackTraceString();
        }

        return response;
    }

    @AuraEnabled
    public static List<IncidentChargeCardManagerController.Option> getStatuses()
    {
        List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
        //TODO: use custom metadata type for list?

        options.add(new IncidentChargeCardManagerController.Option('Open', 'Open'));
        options.add(new IncidentChargeCardManagerController.Option('Approved', 'Approved'));
        options.add(new IncidentChargeCardManagerController.Option('Payment sent', 'Payment sent'));
        options.add(new IncidentChargeCardManagerController.Option('Pending', 'Pending'));
        options.add(new IncidentChargeCardManagerController.Option('Rejected', 'Rejected'));
        options.add(new IncidentChargeCardManagerController.Option('Sent for approval', 'Sent for approval'));

        return options;
    }

    @AuraEnabled
    public static List<IncidentChargeCardManagerController.Option> getTypes()
    {
        List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
        //TODO: use custom metadata type for list?

        options.add(new IncidentChargeCardManagerController.Option('Credit card charge payout', 'Credit card charge payout'));
        options.add(new IncidentChargeCardManagerController.Option('Customer satisfaction', 'Customer satisfaction'));
        options.add(new IncidentChargeCardManagerController.Option('Customer satisfaction - low dollar', 'Customer satisfaction - low dollar'));
        //options.add(new IncidentChargeCardManagerController.Option('Money back guarantee', 'Money back guarantee'));
        options.add(new IncidentChargeCardManagerController.Option('Property damage guarantee', 'Property damage guarantee'));
        options.add(new IncidentChargeCardManagerController.Option('Settlement', 'Settlement'));
        //options.add(new IncidentChargeCardManagerController.Option('Successful card charge', 'Successful card charge'));

        return options;
    }

    @AuraEnabled
    public static List<IncidentChargeCardManagerController.Option> getApprovedByOptions()
    {
        List<IncidentChargeCardManagerController.Option> options = new List<IncidentChargeCardManagerController.Option>();
        List<Schema.PicklistEntry> ples = MIIncident__c.ApprovedBy__c.getDescribe().getPicklistValues();

        for(Schema.PicklistEntry p : ples)
        {
            options.add(new IncidentChargeCardManagerController.Option(p.getLabel(), p.getValue()));
        }

        return options;
    }

    @AuraEnabled
    public static List<MIIncidentAction__c> getPayoutRequests(String incidentId)
    {
        return [SELECT Id, Name, Status__c, LastModifiedBy.Name, LastModifiedDate, Amount__c, Type__c FROM MIIncidentAction__c
                WHERE RecordTypeId =: MiIncidentActionTriggerHandler.PayoutRTId AND MIIncident__c =: incidentId
                ORDER BY LastModifiedDate DESC];
    }
}