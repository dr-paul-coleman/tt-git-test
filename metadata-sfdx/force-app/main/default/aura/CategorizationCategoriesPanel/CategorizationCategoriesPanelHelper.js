/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-20   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadCategoryTypes : function(component)
    {
        var action = component.get('c.getCategoryTypes');

        action.setParam('recordId', component.get('v.recordId'));
        
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.categoryTypes', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCategoryTypes')
            }
        });

        $A.enqueueAction(action);
    }
})