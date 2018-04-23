/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-25   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
({
    loadDisputeRecord: function(component)
    {
        var action = component.get('c.getDispute');

        action.setParams({'disputeId' : component.get('v.recordId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var dispute =  response.getReturnValue();
                var warning = '';

                component.set('v.disputeRecord', dispute);

                if(dispute.InitiatorContact__c == undefined || dispute.InitiatorContact__c == null)
                {
                    warning = 'No initiator contact found.<br/><br/>';
                }

                if(dispute.ResponderContact__c == undefined || dispute.ResponderContact__c == null)
                {
                    warning = 'No responder contact found.<br/><br/>';
                }

                if(dispute.DisputeOffers__r == undefined || dispute.DisputeOffers__r == null || dispute.DisputeOffers__r.length == 0)
                {
                    warning = 'No dispute offer found.<br/><br/>';
                }

                component.set('v.warningMessage', warning);
            }
            else
            {
                console.log('Failed - loadIncident: ' + state);
            }

            this.loadSuccessTips(component);
            this.getInitiatorUserId(component);
        });

        $A.enqueueAction(action);
    },

    getInitiatorUserId: function(component)
    {
        var action = component.get('c.getUserId');
        var dispute = component.get('v.disputeRecord');

        action.setParams({'contactId' : dispute.InitiatorContact__c});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.initiatorUserId', response.getReturnValue());
            }
            else
            {
                console.log('Failed - getInitiatorUserId: ' + state);
            }

            this.loadSuccessTips(component);
        });

        $A.enqueueAction(action);
    },

    loadSuccessTips: function(component)
    {
        var action = component.get('c.getSuccessTips');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.successTips', response.getReturnValue());
            }
            else
            {
                console.log('Failed - loadSuccessTips: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    saveRecord: function(component)
    {
        var action = component.get('c.saveMessage');
        var disputeMessage = component.get('v.disputeMessageRecord');
        var disputeRecord = component.get('v.disputeRecord');
        var initSelected = component.get('v.initiatorSelected');
        var respSelected = component.get('v.responderSelected');
        var cloneId = null;

        component.set('v.showSpinner', true);
        component.set('v.message', '');
        disputeMessage.sobjectType = 'DisputeMessage__c';
        disputeMessage.DisputeOffer__c = disputeRecord.DisputeOffers__r[0].Id;
        disputeMessage.Name = 'Agent added Tip';
        disputeMessage.Dispute__c = disputeRecord.Id;

        if(initSelected && respSelected)
        {
            //disputeMessage.OwnerId = component.get('v.initiatorUserId');
            disputeMessage.ContactSharedWith__c = disputeRecord.ResponderContact__c;
            cloneId = disputeRecord.InitiatorContact__c;
        }
        else if(initSelected)
        {
            //disputeMessage.OwnerId = $A.get('$SObjectType.CurrentUser.Id');
            disputeMessage.ContactSharedWith__c = disputeRecord.InitiatorContact__c;
        }
        else if(respSelected)
        {
            //disputeMessage.OwnerId = $A.get('$SObjectType.CurrentUser.Id');
            disputeMessage.ContactSharedWith__c = disputeRecord.ResponderContact__c;
        }

        action.setParam('message', disputeMessage);
        action.setParam('cloneId', cloneId);

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    console.log('Result: Success');
                    component.set('v.initiatorSelected', false);
                    component.set('v.responderSelected', false);
                    component.set('v.selectedTipId', null);
                    component.set('v.disputeMessageRecord.Message__c', '');

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
                console.log('Failed - saveRecord: ' + state);
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },
})