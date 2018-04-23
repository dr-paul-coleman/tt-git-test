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
1.0      2017-08-22   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    save: function(component)
    {
        var incident = component.get('v.incident');

        this.clearMessage(component);
        incident.sobjectType = 'MIIncident__c';

        var action = component.get("c.saveIncident");
        action.setParams({"incident" : incident});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.message', 'Saved successfully.');
                    component.set('v.messageType', 'success');

                    this.closeModal(component);
                    this.reloadIncident(component);
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

    clearMessage: function(component)
    {
        component.set('v.message', null);
    },

    closeModal: function(component)
    {
        component.set('v.showModal', false);
    },

    reloadIncident : function(component) {
        var action = component.get('c.getIncident');
        action.setParams({
            incidentId: component.get('v.incident.Id')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var incident = response.getReturnValue();
                component.set('v.incident', incident);
            } else if (state === 'ERROR') {
                // error handling goes here
            }

            //this.closeModal(component);
        });
        $A.enqueueAction(action);
    },
})