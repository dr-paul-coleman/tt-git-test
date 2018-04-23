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
1.0      2017-08-31   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    clearMessage: function(component)
    {
        component.set('v.message', null);
    },

    resetCase: function(component)
    {
        var quickCase = {'sobjectType':'Case'};

        component.set('v.quickCase', quickCase);
    },

    loadButtons: function(component)
    {
        var action = component.get("c.getQuickCaseButtons");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                component.set('v.buttonOptions', result);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    createCase: function(component, settingId)
    {
        var incident = component.get('v.incident');

        this.clearMessage(component);

        var action = component.get('c.createQuickCase');
        action.setParams({'incident' : incident, 'settingId' : settingId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.quickCase', result.record);
                    component.set('v.showEmailComposer', true);

                    this.refreshCasesList(component);
                }
                else
                {
                    component.set('v.message', 'Error: ' + result.error);
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

    updateCase: function(component)
    {
        var quickCase = component.get('v.quickCase');

        this.clearMessage(component);

        var action = component.get("c.updateQuickCase");
        action.setParams({"caseId" : quickCase.Id});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.quickCase', result.record);
                    //component.set('v.showEmailComposer', false);

                    this.refreshCasesList(component);
                }
                else
                {
                    component.set('v.message', 'Error: ' + result.error);
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

    refreshCasesList: function(component)
    {
        var refreshEvent = $A.get("e.c:IncidentRefreshCasesEvent");

        refreshEvent.fire();
    },
})