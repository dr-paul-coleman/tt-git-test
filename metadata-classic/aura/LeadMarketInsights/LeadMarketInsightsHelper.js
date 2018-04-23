/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-16   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadReport : function(component)
    {
        var action = component.get('c.getReport');

        action.setParam('reportId', component.get('v.reportId'));
        action.setParam('filters', component.get('v.filters'));
        component.set('v.showSpinner', true);

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.reportData', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadReport')
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },
})