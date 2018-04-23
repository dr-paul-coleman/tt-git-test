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
1.0      2017-08-28   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    loadRecords: function(component)
    {
        var action = component.get('c.getRecords');

        action.setParams({'incidentId' : component.get('v.incidentId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.records', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadQueues: function(component)
    {
        var action = component.get("c.getQueues");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.queues', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    detach: function(component, caseId)
    {
        var action = component.get('c.detachCase');

        action.setParams({'caseId' : caseId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                if(response.getReturnValue() == 'success')
                {
                    if(response.getReturnValue() == 'success')
                    {
                        this.loadRecords(component);
                        component.set('v.showDetachModal', false);
                    }
                    else
                    {
                        component.set('v.message', 'Error: ' + response.getReturnValue());
                        component.set('v.messageType', 'error');
                    }
                }
                else
                {
                    component.set('v.message', 'Error: ' + response.getReturnValue());
                    component.set('v.messageType', 'error');
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    saveCase: function(component)
    {
        var editCase = component.get('v.editCase');
        var action = component.get('c.saveCase');
        var agentOrQueue = component.get('v.agentOrQueue');

        editCase.sobjectType = 'Case';

        if(agentOrQueue == 'Queue')
        {
            editCase.OwnerId = component.get('v.selectedQueueId');
        }
        else
        {
            editCase.OwnerId = component.get('v.selectedUserId');
        }

        action.setParams({'editCase' : editCase});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                if(response.getReturnValue() == 'success')
                {
                    this.loadRecords(component);
                    component.set('v.showModal', false);
                }
                else
                {
                    component.set('v.message', 'Error: ' + response.getReturnValue());
                    component.set('v.messageType', 'error');
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    clearMessage: function(component)
    {
        component.set('v.message', null);
    },
})