/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-11   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */

({
    loadIncident: function(component)
    {
        var action = component.get('c.getIncident');

        action.setParams({'incidentId' : component.get('v.incidentId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var incident =  response.getReturnValue();
                var warning = '';

                component.set('v.incidentRecord', incident);

                if(incident.ProContact__c == null || incident.ProContact__c == undefined || incident.CustomerContact__c == null || incident.CustomerContact__c == undefined)
                {
                    warning = 'This looks like a Good Samaritan incident. In order to create a dispute you must have both a pro and customer associated with this incident.<br/><br/>';
                }
                else
                {
                    if(incident.ProContact__r.user_pk_id__c == undefined || incident.ProContact__r.user_pk_id__c == null)
                    {
                        warning = 'The pro user does not have a PKID; please update the tack record accordingly.<br/><br/>';
                    }

                    if(incident.CustomerContact__r.user_pk_id__c == undefined || incident.CustomerContact__r.user_pk_id__c == null)
                    {
                        warning += 'The customer user does not have a PKID; please update the tack record accordingly.<br/><br/>';
                    }
                }

                component.set('v.warningMessage', warning);
            }
            else
            {
                console.log('Failed - loadIncident: ' + state);
            }

            this.loadNewDispute(component);
        });

        $A.enqueueAction(action);
    },


    loadNewDispute: function(component)
    {
        var action = component.get('c.getNewDispute');

        action.setParams({'incidentId' : component.get('v.incidentId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var result = response.getReturnValue();
                component.set('v.disputeRecord', result);

                if(result.Id == null)
                {
                    component.set('v.currentStep', 1);
                }
                else
                {
                    component.set('v.currentStep', 4);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            this.loadResolutions(component);
        });

        $A.enqueueAction(action);
    },

    loadResolutions: function(component)
    {
        var action = component.get('c.getResolutions');

        console.log('loadResolutions - Selected Id: ' + component.get('v.disputeRecord.DisputeExperience__c'));
        action.setParams({'disputeExperienceId' : component.get('v.disputeRecord.DisputeExperience__c')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.resolutions', response.getReturnValue());
                console.log(response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    save: function(component)
    {
        var action = component.get('c.saveDispute');
        var dispute = component.get('v.disputeRecord');
        var incident = component.get('v.incidentRecord');

        component.set('v.showSpinner', true);

        if(dispute.InitiatorContact__c == incident.CustomerContact__c)
        {
            dispute.InitiatorAccount__c = incident.CustomerAccount__c;
            dispute.ResponderAccount__c = incident.ProAccount__c;
            dispute.ResponderContact__c = incident.ProContact__c;
            dispute.Name = 'Dispute between ' + incident.CustomerContact__r.Name + ' and ' + incident.ProContact__r.Name;
        }
        else
        {
            dispute.InitiatorAccount__c = incident.ProAccount__c;
            dispute.ResponderAccount__c = incident.CustomerAccount__c;
            dispute.ResponderContact__c = incident.CustomerContact__c;
            dispute.Name = 'Dispute between ' + incident.ProContact__r.Name + ' and ' + incident.CustomerContact__r.Name;
        }

        dispute.sobjectType = 'Dispute__c';
        action.setParams({'dispute' : dispute});
        component.set('v.message', '');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.messageType', 'success');
                    this.loadNewDispute(component);
                    component.set('v.message', 'Dispute record created successfully.');
                    //component.set('v.currentStep', 1);
                }
                else
                {
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

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },
})