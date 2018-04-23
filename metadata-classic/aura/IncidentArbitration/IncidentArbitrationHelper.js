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
1.0      2017-08-18  Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    loadArbitration: function(component, incident)
    {
        var incidentId = component.get('v.incidentId');
        var action = component.get("c.getArbitration");
        var disputeUrl = null;

        action.setParams({"incidentId" : incidentId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var arbitration = response.getReturnValue();

                if(arbitration.Id == null)
                {
                    arbitration.Incident__c = incidentId;
                    arbitration.Name = 'FairClaims Dispute for ' + (incident.CustomerContact__c == null ? '' : incident.CustomerContact__r.Name);
                    arbitration.dispute_code__c = 'TT' + incident.IncidentRef__c;
                    arbitration.dispute_amount__c = incident.AmountInDispute__c;
                    arbitration.support_team_member_name__c = incident.Owner.Name;
                    arbitration.support_team_member_email__c = incident.Owner.Email;
                    arbitration.Status__c = 'New';

                    if(incident.CustomerAccount__c != null)
                    {
                        arbitration.claimant_first_name__c = incident.CustomerAccount__r.usr_first_name__c;
                        arbitration.claimant_last_name__c = incident.CustomerAccount__r.usr_last_name__c;
                    }

                    arbitration.claimant_phone__c = incident.CustomerPhone__c;
                    arbitration.claimant_email__c = incident.CustomerEmail__c;

                    if(incident.ProAccount__c != null)
                    {
                        arbitration.respondent_first_name__c = incident.ProAccount__r.usr_first_name__c;
                        arbitration.respondent_last_name__c = incident.ProAccount__r.usr_last_name__c;
                    }

                    arbitration.respondent_phone__c = incident.ProPhone__c;
                    arbitration.respondent_email__c = incident.ProEmail__c;
                    arbitration.brief_description_of_dispute__c = incident.DescriptionOfDispute__c; 

                    disputeUrl = 'https://www.fairclaims.com/disputes/new?claimant_first_name=' +  encodeURIComponent(arbitration.claimant_first_name__c) +
                                     '&claimant_last_name=' + encodeURIComponent(arbitration.claimant_last_name__c) +
                                     '&claimant_email=' + encodeURIComponent(arbitration.claimant_email__c) +
                                     '&claimant_phone=' + encodeURIComponent(arbitration.claimant_phone__c) +
                                     '&respondent_first_name=' + encodeURIComponent(arbitration.respondent_first_name__c) +
                                     '&respondent_last_name=' + encodeURIComponent(arbitration.respondent_last_name__c) +
                                     '&respondent_email=' + encodeURIComponent(arbitration.respondent_email__c) +
                                     '&respondent_phone=' + encodeURIComponent(arbitration.respondent_phone__c) +
                                     '&dispute_code=' + encodeURIComponent(arbitration.dispute_code__c != null ? arbitration.dispute_code__c : '');
                                     
                                     
                    component.set('v.disputeUrl', disputeUrl);
                }
                else
                {
                    disputeUrl = 'https://www.fairclaims.com/disputes/' + encodeURIComponent(arbitration.dispute_code__c);
                }

                component.set('v.disputeUrl', disputeUrl);

                component.set('v.arbitration' , arbitration);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadIncident: function(component, helper)
    {
        var incidentId = component.get('v.incidentId');
        var action = component.get("c.getIncident");

        action.setParams({"incidentId" : incidentId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var incident = response.getReturnValue();
                component.set('v.incident', incident);
                helper.loadArbitration(component, incident);
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

                helper.loadDisputeChannels(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadDisputeChannels: function(component, helper)
    {
        var action = component.get("c.getDisputeChannels");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.disputeChannels', response.getReturnValue());

                helper.loadIncident(component, helper);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    saveArbitration: function(component, helper)
    {
        var arbitration = component.get('v.arbitration');
        var incident = component.get('v.incident');

        component.set('v.message', null);


        arbitration.sobjectType = 'Arbitration__c';
        //incident.sobjectType = 'MIIncident__c';
        //console.log('save guarantee');
        //console.log(guarantee);
        //console.log(incident);


        var action = component.get("c.save");
        action.setParams({"arbitration" : arbitration});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    component.set('v.message', 'Saved successfully.');
                    component.set('v.messageType', 'success');

                    helper.loadArbitration(component, incident);

                    var refreshIncident = $A.get("e.c:IncidentRefreshEvent");

                    refreshIncident.setParams({'name' : 'Incident' });
                    refreshIncident.fire();

                    if(arbitration.Id == null)
                    {
                        var disputeUrl = 'https://www.fairclaims.com/disputes/new?claimant_first_name=' +  encodeURIComponent(arbitration.claimant_first_name__c) +
                                          '&claimant_last_name=' + encodeURIComponent(arbitration.claimant_last_name__c) +
                                          '&claimant_email=' + encodeURIComponent(arbitration.claimant_email__c) +
                                          '&claimant_phone=' + encodeURIComponent(arbitration.claimant_phone__c) +
                                          '&respondent_first_name=' + encodeURIComponent(arbitration.respondent_first_name__c) +
                                          '&respondent_last_name=' + encodeURIComponent(arbitration.respondent_last_name__c) +
                                          '&respondent_email=' + encodeURIComponent(arbitration.respondent_email__c) +
                                          '&respondent_phone=' + encodeURIComponent(arbitration.respondent_phone__c) +
                                          '&dispute_code=' + encodeURIComponent(arbitration.dispute_code__c != null ? arbitration.dispute_code__c : '');
                                          
                                          

                        var openMainTab = $A.get("e.c:OpenInPrimaryTab");
                        openMainTab.setParams({'url' : disputeUrl, 'name' : 'Submit New Dispute'});
                        openMainTab.fire();
                    }
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
})