/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+===============================================
  1.0      2017-11-22   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */
({
    loadOrigins : function(component)
    {
        var action = component.get('c.getCaseOrigins');

        action.setCallback(this, function(response)
        {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var result = response.getReturnValue();

                component.set('v.origins', result);

                this.loadDefaultCase(component);
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    loadDefaultCase : function(component)
    {
        var action = component.get('c.getDefaultCase');

        action.setCallback(this, function(response)
        {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var result = response.getReturnValue();

                result.sobjectType = 'Case';
                component.set('v.description', result.Description);
                result.Description = '';

                component.set('v.caseRecord', result);
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    submit : function(component)
    {
        var action = component.get('c.submitCase');

        component.set('v.showSpinner', true);

        action.setParam('c', component.get('v.caseRecord'));

        action.setCallback(this, function(response)
        {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var result = response.getReturnValue();

                if(result.result == 'Success')
                {
                    var redirectToCase = $A.get("e.c:QuickCaseEvent");
                    redirectToCase.setParams({'actionName' : 'CaseRedirect', 'caseId' : result.caseRecord.Id, 'caseNumber' : result.caseRecord.CaseNumber});
                    redirectToCase.fire();
                }
                else
                {
                    component.set('v.message', result.result);
                }
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },
})