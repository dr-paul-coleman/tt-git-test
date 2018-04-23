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
    doInit: function(component, event, helper)
    {
        helper.loadRecords(component);
        helper.loadQueues(component);
    },

    viewClick: function(component, event, helper)
    {
        //console.log('View Click');
        //console.log(event.currentTarget.dataset.value);
        var span = event.currentTarget.dataset;
        var incidentEvent = $A.get("e.c:IncidentOpenAction");
        var id = span.value;
        var name = span.name;

        incidentEvent.setParams({"actionId" : id, "actionName" : name });
        incidentEvent.fire();
    },

    detachClick: function(component, event, helper)
    {
        var span = event.currentTarget.dataset;
        var id = span.value;
        var cases = component.get('v.records');

        helper.clearMessage(component);

        for(var i = 0; i < cases.length; i++)
        {
           if(cases[i].Id == id)
           {
               var editCase = cases[i];

               component.set('v.editCase', editCase);
               component.set('v.showDetachModal', true);
               break;
           }
        }
    },

    editClick: function(component, event, helper)
    {
        var span = event.currentTarget.dataset;
        var id = span.value;
        var cases = component.get('v.records');

        helper.clearMessage(component);

        for(var i = 0; i < cases.length; i++)
        {
            if(cases[i].Id == id)
            {
                var editCase = cases[i];

                if(editCase.OwnerIsQueue__c)
                {
                    component.set('v.selectedQueueId', editCase.OwnerId);
                    component.set('v.agentOrQueue', 'Queue');
                }
                else
                {
                    component.set('v.selectedUserId', editCase.OwnerId);
                    component.set('v.agentOrQueue', 'Agent');
                }

                component.set('v.editCase', editCase);
                component.set('v.showModal', true);
                break;
            }
        }
    },

    cancelClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        component.set('v.showModal', false);
    },

    cancelDetachClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        component.set('v.showDetachModal', false);
    },

    saveClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        helper.saveCase(component);
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },

    confirmClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        helper.detach(component, component.get('v.editCase').Id);
    },
})