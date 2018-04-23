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
    loadRequest: function(component)
    {
        var incidentId = component.get('v.incidentId');
        var action = component.get("c.getRequest");

        action.setParams({"incidentId" : incidentId});
        //console.log('loadRequest');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var guaranteeRequest = response.getReturnValue();
                component.set('v.guaranteeRequest' , guaranteeRequest);
                //console.log('Guarantee Type 1: ' + guaranteeRequest.GuaranteeType__c);
                this.setEligibilityFactors(component);
                //console.log('Guarantee Type 2: ' + guaranteeRequest.GuaranteeType__c);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadIncident: function(component)
    {
        var incidentId = component.get('v.incidentId');
        var action = component.get("c.getIncident");

        action.setParams({"incidentId" : incidentId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.incident' , response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadStatuses: function(component, helper)
    {
        var action = component.get("c.getStatuses");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.statuses', response.getReturnValue());

                helper.loadGuaranteeTypes(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadGuaranteeTypes: function(component, helper)
    {
        var action = component.get("c.getGuaranteeTypes");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.guaranteeTypes', response.getReturnValue());

                helper.loadGuaranteeMap(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadGuaranteeMap: function(component, helper)
    {
        var action = component.get("c.getGuaranteeMap");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.guaranteeEliFactsMap', response.getReturnValue());
                helper.loadAdjusterStatuses(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadAdjusterStatuses: function(component, helper)
    {
        var action = component.get("c.getAdjusterStatuses");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.adjusterStatuses', response.getReturnValue());

                helper.loadRequest(component);
                helper.loadIncident(component);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    saveGuarantee: function(component, helper)
    {
        var guarantee = component.get('v.guaranteeRequest');
        var incident = component.get('v.incident');

        component.set('v.message', null);

        if(guarantee.Id == null)
        {
            guarantee.MIIncident__c = component.get('v.incidentId');
            guarantee.Name = 'Guarantee Review';
        }

        guarantee.sobjectType = 'MIIncidentAction__c';
        incident.sobjectType = 'MIIncident__c';
        //console.log('save guarantee');
        //console.log(guarantee);
        //console.log(incident);


        var action = component.get("c.save");
        action.setParams({"request" : guarantee, "incident" : incident});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.message', 'Saved successfully.');
                    component.set('v.messageType', 'success');

                    helper.loadRequest(component);
                    helper.loadIncident(component);

                    var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

                    refreshIncident.setParams({'name' : 'Incident' });
                    refreshIncident.fire(); 
                }
                else
                {
                    console.log(result);
                    component.set('v.message', 'Error: ' + result);
                    component.set('v.messageType', 'error');
                }
            }
            else
            {
                console.log('Failed: ' + state);
                component.set('v.message', 'Error: ' + state);
                component.set('v.messageType', 'error');
            }
        });

        $A.enqueueAction(action);
    },

    loadFieldsAccess: function(component)
    {
        var action = component.get("c.getIncidentActionFieldsAccess");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.fieldsAccessMap' , response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    setEligibilityFactors : function(component)
    {
        var guaranteeMap = component.get('v.guaranteeEliFactsMap');
        var guaranteeRequest = component.get('v.guaranteeRequest');

        component.set('v.eligibilityFactors', guaranteeMap[guaranteeRequest.GuaranteeType__c]);
    },
})