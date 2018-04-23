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
    loadPriorities: function(component, helper)
    {
        var action = component.get("c.getPriorities");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.priorities', response.getReturnValue());

                helper.loadOrigins(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadOrigins: function(component, helper)
    {
        var action = component.get("c.getOrigins");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.origins', response.getReturnValue());

                helper.loadCategories(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadCategories: function(component, helper)
    {
        var action = component.get("c.getCategories");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.categories', response.getReturnValue());

                //helper.loadSubCategories(component, helper);
                helper.loadCategoryMap(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadSubCategories: function(component, helper)
    {
        var action = component.get("c.getSubcategories");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.subCategories', response.getReturnValue());

                helper.loadStatuses(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadCategoryMap: function(component, helper)
    {
        var action = component.get("c.getCategoryMap");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.categoryMap', response.getReturnValue());
                //console.log(component.get('v.categoryMap'));

                helper.loadStatuses(component, helper);
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

                helper.loadProOutcomes(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadProOutcomes: function(component, helper)
    {
        var action = component.get("c.getProOutcomes");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.proOutcomes', response.getReturnValue());

                helper.loadCustOutcomes(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadCustOutcomes: function(component, helper)
    {
        var action = component.get("c.getCustOutcomes");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.custOutcomes', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    save: function(component, closing)
    {
        var incident = component.get('v.incident');
        var action;

        this.clearMessage(component);
        incident.sobjectType = 'MIIncident__c';

        if(closing)
        {
            action = component.get("c.closeIncident");
            action.setParams({"incident" : incident, "note" : component.get('v.note'), "visibleToCs" : component.get('v.visibleToCs')});
        }
        else
        {
            action = component.get("c.saveIncident");
            action.setParams({"incident" : incident});
        }

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.messageType', 'success');

                    if(closing)
                    {
                        component.set('v.message', 'Closed successfully.');
                        this.closeCloseModal(component);
                    }
                    else
                    {
                        component.set('v.message', 'Saved successfully.');
                        this.closeModal(component);
                    }

                    this.reloadIncident(component);
                }
                else
                {
                    console.log(result);
                    component.set('v.message', 'Error<br/><br/>' + result);
                    component.set('v.messageType', 'error');
                }
            }
            else
            {
                console.log('Failed: ' + state);
                component.set('v.message', 'Error<br/><br/>' + state);
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

    closeCloseModal: function(component)
    {
        component.set('v.showCloseModal', false);
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

                this.setSubCategories(component, incident.MICategory__c);

                component.set('v.incident', incident);
            } else if (state === 'ERROR') {
                // error handling goes here
            }

            //this.closeModal(component);
        });
        $A.enqueueAction(action);
    },

    setSubCategories : function(component, category)
    {
        var categoryMap = component.get('v.categoryMap');

        if(category == null)
        {
            var incident = component.get('v.incident');

            component.set('v.subCategories', categoryMap[incident.MICategory__c]);
        }
        else
        {
            component.set('v.subCategories', categoryMap[category]);
        }

    },
})