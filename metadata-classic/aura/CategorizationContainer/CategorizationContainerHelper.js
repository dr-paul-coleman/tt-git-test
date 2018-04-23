/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-14   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadUserSettings : function(component)
    {
        var action = component.get('c.getUserSettings');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var settings = response.getReturnValue();

                if(settings.ShowCategoryTree__c)
                {
                    component.set('v.splitViewStatus', 'slds-is-open')
                }
                else
                {
                    component.set('v.splitViewStatus', 'slds-is-closed')
                }
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadUserSettings')
            }
        });

        $A.enqueueAction(action);
    },

    saveCategoryTreeSetting : function(component)
    {
        var action = component.get('c.toggleTreeSetting');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error saveCategorySetting')
            }
        });

        $A.enqueueAction(action);
    },
})