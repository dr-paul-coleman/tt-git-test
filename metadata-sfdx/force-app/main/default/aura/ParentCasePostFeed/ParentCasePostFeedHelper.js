/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-12-06   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    submitPost : function(component, post)
    {
        var action = component.get('c.submit');
        var caseId = component.get('v.caseId');

        component.set('v.showSpinner', true);
        this.clearMessage(component);

        action.setParam('caseId', caseId);
        action.setParam('post', post);

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                if(response.getReturnValue() == 'Success')
                {
                    component.set('v.post', '');

                    var rc = $A.get("e.c:ParentCasePostFeedEvent");

                    rc.setParam('actionName', 'Refresh Case');

                    rc.fire();
                }
                else
                {
                   component.set('v.message', 'Error: ' + response.getReturnValue());
                }
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