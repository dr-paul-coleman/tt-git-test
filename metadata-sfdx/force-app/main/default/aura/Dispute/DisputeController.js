/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-11   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
({
    doInit: function(component, event, helper)
    {
        helper.loadIncident(component);
    },

    experienceSelected: function(component, event, helper)
    {
        //console.log('experienceSelected');
       // console.log('Selected Id: ' + component.get('v.disputeRecord.DisputeExperience__c'));
        helper.loadResolutions(component);
    },

    resolutionChange: function(component, event, helper)
    {
        var disputeRec = component.get('v.disputeRecord');
        var resolution = disputeRec.PrePopulatedDesiredResolution__c;

        //console.log('resolutionChange');

        if(resolution.indexOf('refund') > -1 || resolution.indexOf('Refund') > -1)
        {
            component.set('v.showRefund', true);
        }
        else
        {
            component.set('v.showRefund', false);
            disputeRec.PrePopulatedResolutionAmount__c = null;
            component.set('v.disputeRecord', disputeRec);
        }
    },

    nextClick: function(component, event, helper)
    {
        var currentStep = component.get('v.currentStep');

        if(currentStep < 3)
        {
            currentStep++;
        }

        component.set('v.currentStep', currentStep);
    },

    backClick: function(component, event, helper)
    {
        var currentStep = component.get('v.currentStep');

        if(currentStep > 1)
        {
            currentStep--;
        }

        component.set('v.currentStep', currentStep);
    },

    submitClick: function(component, event, helper)
    {
        helper.save(component);
    },

    viewClick: function(component, event, helper)
    {
        var incidentEvent = $A.get("e.c:IncidentOpenAction");

        incidentEvent.setParams({"actionId" : component.get("v.disputeRecord.Id"), "actionName" : component.get("v.disputeRecord.Name") });
        incidentEvent.fire();
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.message', '');
    },
})