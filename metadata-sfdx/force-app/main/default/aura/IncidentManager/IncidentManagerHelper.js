({
	getIncident : function(component) {
		var action = component.get('c.getIncident');
		action.setParams({
			incidentId: component.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var incident = response.getReturnValue();
				component.set('v.incident', incident);
				this.getCasesFromIncident(component);
				this.getIncidentProjectData(component, incident.bid_id__c);
				this.loadSubCategories(component, incident.MICategory__c);
			}
			else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	getIncidentProjectData : function(component, bidId) {
        var action = component.get('c.getIncidentProjectData');
        action.setParams({'bidId': bidId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var incidentProjData = response.getReturnValue();
                component.set('v.incidentProjData', incidentProjData);
            }
            else if (state === 'ERROR') {
                // error handling goes here
            }
        });
        $A.enqueueAction(action);
    },

	getCasesFromIncident: function(component) {
		var incident = component.get('v.incident');
		if (!$A.util.isEmpty(incident) && !$A.util.isEmpty(incident.Cases__r)) {
			var proCase, customerCase;
			incident.Cases__r.forEach(function(incidentCase) {
				if (incidentCase.MICasePrimaryPro__c) {
					proCase = incidentCase;
				} else if (incidentCase.MICasePrimaryCustomer__c) {
					customerCase = incidentCase;
				}
			});
			component.set('v.proCase', proCase);
			component.set('v.customerCase', customerCase);
		}
	},

	clearButtonSelection: function(component)
	{
	    component.find('btnTasks').set('v.variant', 'neutral');
	    component.find('btnNotes').set('v.variant', 'neutral');
	    //component.find('btnMenu').set('v.variant', 'border');
	    $A.util.removeClass(component.find('miCharge'), 'menu-highlight');
	    $A.util.removeClass(component.find('miPayout'), 'menu-highlight');
	    $A.util.removeClass(component.find('miEscalate'), 'menu-highlight');
    },

    highlightSelectedButton: function(component, buttonId, variant)
    {
        component.find(buttonId).set('v.variant', variant);
    },

    loadSubCategories: function(component, category)
    {
        var action = component.get("c.getCategorySubs");

        action.setParams({'category': category});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.subCategories', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },
});