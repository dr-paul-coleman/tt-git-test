({
	getInitialIncident : function(component) 
    {
        var action = component.get("c.createInitialIncident");
        action.setParams({ casId : component.get("v.casId") });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                if(response.getReturnValue() != null)
                {
                    var incident = response.getReturnValue()
                	component.set("v.incident", incident);

                	if(incident.IncidentExists__c)
                	{
                	     component.set('v.currentStep', 'incidentExists');
                    }
                    else
                    {
                        component.set("v.custCase", component.get("v.incident.MICasePrimaryCustomer__c"));
                        component.set("v.proCase", component.get("v.incident.MICasePrimaryPro__c"));

                        if(component.get("v.incident.Origin__c") != null)
                        {
                           component.set("v.originExists",true);
                        }
                    }
                }
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR") 
            {
                component.set("v.error", true);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {console.log("Unknown error");}
            }
        });
        $A.enqueueAction(action);
    },

    getCase: function(component) 
    {
        var action = component.get("c.getCaseValues");
        action.setParams({ casId : component.get("v.casId") });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                if(response.getReturnValue() != null)
                {
                    var c = response.getReturnValue();
                    component.set("v.case", c);

                    if(c.Incident__c == null)
                    {
                        component.set('v.currentStep', 'createIncident');
                    }

                     component.set("v.custCase", component.get("v.case.MICasePrimaryCustomer__c"));
                     component.set("v.proCase", component.get("v.case.MICasePrimaryPro__c"));
                     console.log("case Id: " + component.get("v.casId"));
                     console.log("selectedProCase: " + component.get("v.case.MICasePrimaryPro__c"));
                     console.log("selectedCustCase: " + component.get("v.case.MICasePrimaryCustomer__c"));
                }
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR") 
            {
                component.set("v.error", true);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {console.log("Unknown error");}
            }

            this.getInitialIncident(component);
        });
        $A.enqueueAction(action);
    },

    getIncidentFromExternal : function(component)
    {
        var action = component.get("c.getIncidentFromBecky");
        console.log("incident: " + component.get("v.incident"));
        var incident = component.get("v.incident");
        this.clearMessage(component);

        incident.sobjectType = "MIIncident__c";
        action.setParams({ 'bidId' : component.get("v.incident.bid_id__c"), 'incident' : incident });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    if(result.record != null)
                    {
                	    component.set('v.incident', result.record);
                        component.set('v.currentStep', 'incidentFound');
                	    //console.log("response.getReturnValue(): " + response.getReturnValue());
                	}
                	else
                	{
                        component.set('v.currentStep', 'createIncidentFromScratch');
                    }
                }
                else
                {
                    console.log('Result: ' + result.error);
                    component.set("v.error", true);
                    component.set('v.message', result.error);
                }
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR") 
            {
				var errors = response.getError();
                if (errors) 
                {
                    component.set("v.error", true);
                    component.set("{!v.proCase}", false);
                    component.set("{!v.custCase}", false);

                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {console.log("Unknown error");}
                
            }

            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    },

    insertIncident : function(component, fromExt)
    {
        var action;
        var incident = component.get("v.incident");
        var custContact = component.get('v.custContact');
        var proContact = component.get('v.proContact');

        this.clearMessage(component);
        component.set("v.error", false);
        component.set("v.showSpinner",true);
        incident.sobjectType = "MIIncident__c";
        custContact.sobjectType = 'Contact';
        proContact.sobjectType = 'Contact';

        //action.setParams({ mi : incident,custcheckbox:component.get("v.custCase"),procheckbox:component.get("v.proCase"),casId:component.get("v.casId"),cat:component.get("v.incident.MICategory__c"),sub:component.get("v.incident.MISubcategory__c"),pri:component.get("v.incident.Priority__c"),orig:component.get("v.incident.Origin__c")});

        if(fromExt)
        {
            action = component.get("c.insertNewIncidentFromExternal");

            action.setParams({
                'mi' : incident,
                'custcheckbox' : component.get("v.custCase"),
                'procheckbox' : component.get("v.proCase"),
                'casId' : component.get("v.casId")
            });
        }
        else
        {
            action = component.get("c.insertNewIncident");

            action.setParams({
                'mi' : incident,
                'custcheckbox' : component.get("v.custCase"),
                'procheckbox' : component.get("v.proCase"),
                'casId' : component.get("v.casId"),
                'custContact' : custContact,
                'proContact' : proContact
            });
        }

        action.setCallback(this, function(response)
        {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set("v.incident", result.record);
                    component.set('v.currentStep', 'incidentFactors');
                }
                else
                {
                    component.set("v.error", true);
                    component.set('v.message', result.error);
                }
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR")
            {
                component.set("v.error", true);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message)
                    {
                        alert("Error message: " + errors[0].message);
                    }
                }
                else {console.log("Unknown error");}
            }

            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    },

    getOriginPicklist : function(component)
    {
        var action = component.get("c.getPicklistOptions");
        action.setParams({ sObjectName : "MIIncident__c",fieldName : "Origin__c" });
        action.setCallback(this, function(response)
        {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                console.log("response.getReturnValue(): " + response.getReturnValue());
                component.set("v.origin", response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR")
            {
                component.set("v.error", true);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {console.log("Unknown error");}
            }
        });
        $A.enqueueAction(action);
    },

    getPriorityPicklist : function(component)
    {
        var action = component.get("c.getPicklistOptions");
        action.setParams({ sObjectName : "MIIncident__c",fieldName : "Priority__c" });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                console.log("response.getReturnValue(): " + response.getReturnValue());
                component.set("v.priority", response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {}
            else if (state === "ERROR") 
            {
                component.set("v.error", true);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {console.log("Unknown error");}
            }
        });
        $A.enqueueAction(action);
    },

    loadCategories: function(component)
    {
        var action = component.get("c.getCategories");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.categories', response.getReturnValue());

                this.loadCategoryMap(component);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    loadCategoryMap: function(component)
    {
        var action = component.get("c.getCategoryMap");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.categoryMap', response.getReturnValue());
                this.setSubCategories(component);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    setSubCategories : function(component)
    {
        var categoryMap = component.get('v.categoryMap');
        var incident = component.get('v.incident');

        if(incident != null)
        {
            component.set('v.subCategories', categoryMap[incident.MICategory__c]);
        }
    }, 

    findUser: function(component, userId)
    {
        var action = component.get("c.findThumbtackUser");

        action.setParams({ 'userId' : userId });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var user = response.getReturnValue();

                component.set('v.thumbtackUser', user);

                if(user != null)
                {
                    component.set('v.currentStep', 'confirmUser');
                }
                else
                {
                    component.set('v.currentStep', 'confirmNewUser');
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set("v.showSpinner",false);
        });

        $A.enqueueAction(action);
    },

    createGoodSamaritanIncident: function(component, userFound)
    {
        var action;
        var caseId = component.get('v.casId');
        var incident = component.get('v.incident');
        var isPro = component.get('v.userType') == 'Pro';

        component.set("v.showSpinner", true);
        this.clearMessage(component);
        component.set("v.error", false);

        incident.sobjectType = 'MIIncident__c';

        if(userFound)
        {
            var user = component.get('v.thumbtackUser');
            user.sobjectType = 'FindUserController.FindUserResult';

            if(user.isExternalUser)
            {
                var u = user.user;
                u.sobjectType = 'becquerel_tt_user_for_tack__x';
                action = component.get('c.createGoodSamaritanIncidentExistingUser');
                action.setParams({ 'incident' : incident, 'caseId' : caseId, 'user' : u, 'isPro' : isPro });
            }
            else
            {
                var c = user.contact;
                c.sobjectType = 'Contact';
                action = component.get('c.createGoodSamaritanIncidentExistingContact');
                action.setParams({ 'incident' : incident, 'caseId' : caseId, 'c' : c, 'isPro' : isPro });
            }
        }
        else
        {
            action = component.get('c.createGoodSamaritanIncidentNewUser');
            action.setParams({ 'incident' : incident, 'caseId' : caseId, 'email' : component.get('v.newEmail'),
                'firstName' : component.get('v.newFirstName'), 'lastName' : component.get('v.newLastName'), 'isPro' : isPro });
        }

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.incident', result.record);

                    component.set('v.currentStep', 'incidentFactors');
                }
                else
                {
                    component.set("v.error", true);
                    component.set('v.message', result.error);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set("v.showSpinner",false);
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

    clearMessage: function(component)
    {
        component.set('v.message', null);
    },
})