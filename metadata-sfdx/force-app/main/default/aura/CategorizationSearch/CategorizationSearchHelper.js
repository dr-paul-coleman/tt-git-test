/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-25   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    displaySearch : function(component, display)
    {
        component.set('v.showResults', display);
    },

    search : function(component, searchText)
    {
        var action = component.get('c.getCategorizationDefinitions');

        component.set('v.showSearching', true);
        this.clearResults(component);
        this.displaySearch(component, true);

        action.setParam('searchText', searchText);
        action.setParam('recordId', component.get('v.recordId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var cats = response.getReturnValue();

                component.set('v.showSearching', false);
                component.set('v.categories', cats);

                if(cats.length == 0)
                {
                    component.set('v.showNoResults', true);
                }
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error search')
            }
        });

        $A.enqueueAction(action);
    },

    clearResults : function(component)
    {
        component.set('v.categories', []);
        component.set('v.showNoResults', false);
    },
})