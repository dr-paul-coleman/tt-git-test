/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-23   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    doInit : function(component, event, helper)
    {
        var cw = component.get('v.cw');

        if(cw != null)
        {

            for(var i = 0; i < cw.childCategories.length; i++)
            {
                if(cw.childCategories[i].category.Id != null && !cw.childCategories[i].category.Deleted__c)
                {
                    component.set('v.showChildren', true);
                    break;
                }
            }
        }
    },

    toggleRows : function(component, event, helper)
    {
        component.set('v.showChildren', !component.get('v.showChildren'));
    },
})