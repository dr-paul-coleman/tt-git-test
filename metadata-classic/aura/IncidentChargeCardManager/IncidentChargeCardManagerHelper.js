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
1.0      2017-08-15   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    loadStatuses: function(component)
    {
        var action = component.get("c.getStatuses");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.statuses', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    saveRequest: function(component, helper)
    {
        var request = component.get('v.ccRequest');

        request.MIIncident__c = component.get('v.incidentId');
        request.Name = 'Charge Card Request For ' + component.get('v.proAccountName');
        request.Amount__c = parseFloat(request.Amount__c);

        var action = component.get("c.save");

        console.log(request);

        action.setParams({"request" : request});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    request.Amount__c = null;
                    request.TransactionID__c = null;
                    request.Last4ofCard__c = null;
                    request.Notes__c = null;
                    request.Status__c = 'Open';
                    component.set('v.ccRequest' , request);

                    helper.loadRequests(component);
                }
                else
                {
                    console.log(result);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadRequests: function(component)
    {
        var incidentId = component.get('v.incidentId');
        var action = component.get("c.getChargeCardRequests");

        action.setParams({"incidentId" : incidentId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var allRequests = response.getReturnValue();

                if(allRequests.length > 2)
                {
                   component.set('v.showMore', true);
                }

                component.set('v.allRequests', allRequests);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },
})