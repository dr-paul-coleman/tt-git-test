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
1.0      2017-08-18   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        helper.loadStatuses(component, helper);
    },

    saveClick: function(component, event, helper)
    {
        var disputeCodeCmp = component.find('disputeCode');
        var statusCmp = component.find('status');
        var disputeChannelsCmp = component.find('disputeChannels');

        var valid = true;
        var arbitration = component.get('v.arbitration');

        if(arbitration.dispute_amount__c == null)
        {
            component.set('v.showDisputeAmountMissing', true);
            valid = false;
        }
        else
        {
            component.set('v.showDisputeAmountMissing', false);
        }

        console.log(arbitration.DateSubmitted__c);

        if(arbitration.DateSubmitted__c == null)
        {
            component.set('v.showDateSubmittedMissing', true);
            valid = false;
        }
        else
        {
            component.set('v.showDateSubmittedMissing', false);
        }

        if(!disputeCodeCmp.get('v.validity').valid)
        {
            disputeCodeCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!statusCmp.get('v.validity').valid)
        {
            statusCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!disputeChannelsCmp.get('v.validity').valid)
        {
            disputeChannelsCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            helper.saveArbitration(component, helper);
        }
    },

    viewClick: function(component, event, helper)
    {
        //console.log('View Click');
        var incidentEvent = $A.get("e.c:IncidentOpenAction");

        incidentEvent.setParams({"actionId" : component.get("v.arbitration.Id"), "actionName" : component.get("v.arbitration.Name") });
        incidentEvent.fire();
    },

    onDisputeAmountBlur: function(component, event, helper)
    {
        var arbitration = component.get('v.arbitration');

        if(arbitration.dispute_amount__c == null)
        {
            component.set('v.showDisputeAmountMissing', true);
        }
        else
        {
            component.set('v.showDisputeAmountMissing', false);
        }
    },

    onDateSubmittedBlur: function(component, event, helper)
    {
        var arbitration = component.get('v.arbitration');

        if(arbitration.DateSubmitted__c == null)
        {
            component.set('v.showDateSubmittedMissing', true);
        }
        else
        {
            component.set('v.showDateSubmittedMissing', false);
        }
    },
})