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
1.0      2017-08-17   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        helper.loadFieldsAccess(component);
        helper.loadStatuses(component, helper);
    },

    saveClick: function(component, event, helper)
    {
        helper.saveGuarantee(component, helper);
    },

    viewClick: function(component, event, helper)
    {
        //console.log('View Click');
        var incidentEvent = $A.get("e.c:IncidentOpenAction");

        incidentEvent.setParams({"actionId" : component.get("v.guaranteeRequest.Id"), "actionName" : component.get("v.guaranteeRequest.Name") });
        incidentEvent.fire();
    },

    onGuaranteeTypeChange: function(component, event, helper)
    {
        console.log('on guarantee change');
        var guaranteeRequest = component.get('v.guaranteeRequest');
        guaranteeRequest.EligibilityFactors__c = null;
        component.set('v.guaranteeRequest', guaranteeRequest);

        helper.setEligibilityFactors(component);
    },
})