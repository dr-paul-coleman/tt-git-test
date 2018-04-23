/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-03   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/
({
    loadRecords: function(component)
    {
        var action = component.get('c.getWorkItemsByType');

        component.set('v.showSpinner', true);

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

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    loadRecordsRT: function(component)
    {
        var action = component.get('c.getWorkItemsByRecordType');

        component.set('v.showSpinner', true);

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.recordsRT', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    transferItem: function(component, type)
    {
        var action = component.get('c.takeWorkItem');

        component.set('v.showSpinner', true);

        action.setParams({'type' : type});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var workItem = response.getReturnValue();

                if(workItem != null)
                {
                    this.loadRecords(component);
                    this.fireOpenNewTabEvent(component, '/' + workItem.Id, workItem.Name);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    transferItemRT: function(component, type)
    {
        var action = component.get('c.takeWorkItemRT');

        component.set('v.showSpinner', true);

        action.setParams({'recordTypeName' : type});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var workItem = response.getReturnValue();

                if(workItem != null)
                {
                    this.loadRecordsRT(component);
                    this.fireOpenNewTabEvent(component, '/' + workItem.Id, workItem.Name);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    fireOpenNewTabEvent: function(compoent, url, name)
    {
        var incidentEvent = $A.get("e.c:WorkItemOpenPrimaryTab");

        incidentEvent.setParams({"url" : url, "name" : name });
        incidentEvent.fire();
    },
})