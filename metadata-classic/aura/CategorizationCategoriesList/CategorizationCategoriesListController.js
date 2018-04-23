/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-24   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    doInit : function(component, event, helper)
    {
        helper.loadOrigins(component); 
        helper.loadCategories(component);
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');
        var catDefKey = event.getParam('catDefKey');
        var parentCatDefKey = event.getParam('parentCatDefKey');

        console.log(actionName);

        if(actionName == 'Add New Category - Search' || actionName == 'Add New Category - Tree')
        {
            helper.addNewCategory(component, catDefKey, parentCatDefKey);
        }
        else if(actionName == 'Remove Category - Tree' || actionName == 'Remove Category')
        {
            helper.removeCategory(component, catDefKey, parentCatDefKey);
        }
        else if(actionName == 'Save Records')
        {
            helper.saveCategories(component); 
        }
        else if(actionName == 'Primary Change')
        {
            var pCat = event.getParam('primaryCategory');
            var pSubCat = event.getParam('primarySubcategory');

            component.set('v.primaryCategory', pCat);
            component.set('v.primarySubcategory', pSubCat);

            console.log('xPrimary Cat: ' + component.get('v.primaryCategory'));
            console.log('xPrimary Sub Cat: ' + component.get('v.primarySubcategory'));
        }
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },
})