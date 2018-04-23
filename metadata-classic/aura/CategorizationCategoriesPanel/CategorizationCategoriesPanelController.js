/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-20   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    doInit : function(component, event, helper)
    {
        helper.loadCategoryTypes(component);
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');


        if(actionName == 'Refresh Tree')
        {
            helper.loadCategoryTypes(component);
        }
        else if(actionName == 'Show Category Type')
        {
            var ctName = event.getParam('categoryType');
            var cTypes = component.get('v.categoryTypes');

            for(var i = 0; i < cTypes.length; i++)
            {
                console.log(cTypes[i].name);

                if(cTypes[i].name == ctName)
                {
                    cTypes[i].show = true;
                }
                else
                {
                    cTypes[i].show = false;
                }
            }

            component.set('v.categoryTypes', cTypes);
        }
    },
})