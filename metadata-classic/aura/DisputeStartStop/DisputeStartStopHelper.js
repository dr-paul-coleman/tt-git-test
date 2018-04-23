/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-29   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
({
    loadStatusMap: function(component)
    {
        var action = component.get("c.getStatusMap");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.statusMap', response.getReturnValue());

                this.loadStatuses(component);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadStatuses: function(component)
    {
        var action = component.get("c.getStatuses");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.statuses', response.getReturnValue());
                this.loadDisputeRecord(component);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadDisputeRecord: function(component)
    {
        var action = component.get('c.getDispute');

        action.setParams({'disputeId' : component.get('v.recordId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var dispute =  response.getReturnValue();

                component.set('v.disputeRecord', dispute);
            }
            else
            {
                console.log('Failed - loadDisputeRecord: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    setStages : function(component)
    {
        var statusMap = component.get('v.statusMap');
        var status = component.get('v.newStatus');

       // console.log('Status Map: ' + JSON.stringify(statusMap));
       // console.log('status: ' + status);

        component.set('v.stages', statusMap[status]);
    },

    save: function(component, saveType)
    {
        var action = component.get('c.saveDispute');
        var dispute = component.get('v.disputeRecord');

        if(saveType == 'Stop')
        {
            dispute.Status__c = 'Under Review';
            dispute.Stage__c = 'Stopped'
        }
        else if(saveType == 'Restart')
        {
            dispute.Status__c = component.get('v.newStatus');
            dispute.Stage__c = component.get('v.newStage');
        }
        else if(saveType == 'Close')
        {
            dispute.Status__c = 'Closed';
        }

        component.set('v.message', '');
        component.set('v.showSpinner', true);
        action.setParams({'dispute' : dispute});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var result =  response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.messageType', 'success');

                    if(saveType == 'Stop')
                    {
                        component.set('v.message', 'Dispute record stopped successfully.');
                    }
                    else if(saveType == 'Restart')
                    {
                        component.set('v.message', 'Dispute record restarted successfully.');
                        component.set('v.showModal', false);
                        component.set('v.newStage', '');
                        component.set('v.newStatus', '');
                        component.set('v.stages', null);
                    }
                    else if(saveType == 'Close')
                    {
                        component.set('v.message', 'Dispute record closed successfully.');
                        component.set('v.showCloseModal', false);
                    }

                    this.loadDisputeRecord(component);

                    var rc = $A.get("e.c:QuickTipEvent");

                    rc.setParam('actionName', 'Refresh');
                    rc.setParam('recordId', component.get('v.recordId'));

                    rc.fire(); 
                }
                else
                {
                    component.set('v.message', 'Error<br/><br/>' + result);
                    component.set('v.messageType', 'error');
                }
            }
            else
            {
                console.log('Failed - loadIncident: ' + state);
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },
})