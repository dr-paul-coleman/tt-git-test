({
    doInit : function(component, event, helper)
    {
        helper.getCase(component);
        helper.getOriginPicklist(component);
        helper.getPriorityPicklist(component);
        helper.loadCategories(component);
        helper.loadQueues(component);
    },

    cancelClick : function(component, event, helper) {
        var retValue = component.get('v.caseId');
        if(window.opener == null){
           href = "https://ap1.salesforce.com/500/o"
        }else{
            window.close();
        }
    },

    continue1Click : function(component, event, helper) {
        var incidentType = component.get('v.incidentType');
        var userId = component.get('v.userId')
        var assignedTo = component.get('v.agentOrQueue');
        var incident = component.get('v.incident');

        if(assignedTo == 'Agent')
        {
            incident.OwnerId = component.get('v.selectedUserId');
        }
        else 
        {
            incident.OwnerId = component.get('v.selectedQueueId');
        }

        component.set('v.incident', incident);

        console.log('Owner Id: ' + component.get('v.incident.OwnerId'));

    	component.set('v.showSpinner',true);

        if(incidentType == 'Incident')
        {
            helper.getIncidentFromExternal(component);
        }
        else
        {
            if(userId != null && userId != '')
            {
                helper.findUser(component, userId);
            }
            else
            {
                component.set('v.currentStep', 'confirmNewUser');
                component.set('v.showSpinner', false);
            }
        }
    },

    backClick : function(component, event, helper) {
         component.set("v.continue", false);
         component.set("v.incident.IncidentExists__c",false);
         //component.set("{!v.incident.bid_id__c}", "");
         component.set("v.error",false);
         component.set('v.currentStep', 'createIncident');
    },

    clearForm: function(component, event, helper) {
         component.set("v.continue", false);
         component.set("v.incidentFound", false);
         /*component.set("v.incident.IncidentExists__c",false);
         component.set("{!v.incident.bid_id__c}", '');
         component.set("{!v.incident.TotalPaidToPro__c}", 0);
         component.set("{!v.incident.AmountInDispute__c}", 0);
         component.set("{!v.incident.Origin__c}", "");
         component.set("{!v.incident.Priority__c}", "");
         */
         component.set("{!v.originExists}", false);
         component.set("{!v.proCase}", false);
         component.set("{!v.custCase}", false);
         component.set("v.error",false);
         component.set('v.userId', '');
         component.set('v.currentStep', 'createIncident');

         helper.getInitialIncident(component);
    },

    continue2Click : function(component, event, helper) {
        component.set("v.continue", true);
    },

    verifyClick : function(component, event, helper) {
        helper.insertIncident(component, true);
    },

    finish : function(component, event, helper) {
        component.set("v.finished", true);
        component.set('v.currentStep', 'finished');
    },

    createNewClick : function(component, event, helper) {
        helper.insertIncident(component, false);
        component.set("v.continue", false);
        component.set("v.incidentFound", false);
        component.set("v.error",false);
    },

    caseSelectChange : function(component, event, helper) {
        var pro = component.get('v.proCase');// component.find("procheckbox").get("v.checked");
        var cust = component.get('v.custCase');//component.find("custcheckbox").get("v.checked");

        console.log('Pro: ' + pro);
        console.log('Cust: ' + cust);

        if(cust)
        {
            component.set("v.proCase", false);
        }
        if(pro)
        {
            component.set("v.custCase", false);
        }
    },

    incidentLinkClicked : function(component, event, helper) {
        var incidentEvent = $A.get("e.c:IncidentLinkClicked");
        incidentEvent.setParams({
            incidentId: component.get("v.incident.Id")
        });
        incidentEvent.fire();
    },

    caseIncidentLinkClicked : function(component, event, helper) {
        var incidentEvent = $A.get("e.c:IncidentLinkClicked");
        incidentEvent.setParams({
            incidentId: component.get("v.case").Incident__c
        });
        incidentEvent.fire();
    },

    incidentTypeOnChange : function(component, event, helper)
    {
        var incidentType = event.getSource().get('v.label');
        component.set('v.incidentType', incidentType);

        var incident = component.get('v.incident');

        if(incidentType == 'Incident')
        {
            incident.MICategory__c = null;
            component.find('category').set('v.value', null);
        }
        else
        {
           incident.MICategory__c = 'Concern about user';
        }

        incident.MISubcategory__c = null;
        component.set('v.incident', incident);
        helper.setSubCategories(component);
    },

    onCategoryChange: function(component, event, helper)
    {
        var incident = component.get('v.incident');

        incident.MISubcategory__c = null;

        helper.setSubCategories(component);
    },

    confirmUserBackClick : function(component, event, helper)
    {
        component.set('v.currentStep', 'createIncident');
    },

    confirmUserClick: function(component, event, helper)
    {
        helper.createGoodSamaritanIncident(component, true);
    },

    confirmNewUserClick: function(component, event, helper)
    {
        var emailCmp = component.find('txtNewEmail');
        var firstCmp = component.find('txtNewFirstName');
        var lastCmp = component.find('txtNewLastName');

        var valid = true;

        if(!emailCmp.get('v.validity').valid)
        {
            emailCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!firstCmp.get('v.validity').valid)
        {
            firstCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!lastCmp.get('v.validity').valid)
        {
            lastCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            helper.createGoodSamaritanIncident(component, false);
        }
    },
})