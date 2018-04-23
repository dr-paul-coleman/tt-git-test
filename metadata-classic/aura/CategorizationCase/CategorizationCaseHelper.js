/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-27   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadCase : function(component)
    {
        var action = component.get('c.getCase');

        action.setParam('caseId', component.get('v.recordId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.caseRecord', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    loadCaseStatuses : function(component)
    {
        var action = component.get('c.getCaseStatuses');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.statuses', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCategories')
            }

            this.loadCase(component);
        });

        $A.enqueueAction(action);
    },

    saveCase : function(component)
    {
        var action = component.get('c.updateCase');
        var caseRecord = component.get('v.caseRecord');

        caseRecord.Category__c = component.get('v.primaryCategory');
        caseRecord.SubCategory__c = component.get('v.primarySubcategory');

        component.set('v.showSpinner', true);
        this.clearMessage(component);
        action.setParam('caseRecord', caseRecord);

        action.setCallback(this, function(response) {
            var state = response.getState();

            console.log('saveCase 4');
            if (state === 'SUCCESS')
            {
                var message = component.get('v.message');

                if(response.getReturnValue() == 'Success')
                {
                   var rc = $A.get("e.c:CategorizationEvent");

                    rc.setParam('actionName', 'Refresh Case');
                    rc.setParam('recordId', component.get('v.recordId'));

                    rc.fire();
                }
                else
                {
                    message += 'Error updating case: ' + response.getReturnValue();
                    component.set('v.allowSubmit', true);
                }

                component.set('v.message', message);
                console.log('saveCase 5: ' + message);
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error saveCase')
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    clearMessage: function(component)
    {
        component.set('v.message', '');
    },

})