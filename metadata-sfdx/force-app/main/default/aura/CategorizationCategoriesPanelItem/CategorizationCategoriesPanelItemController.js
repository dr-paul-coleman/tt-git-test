/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-23   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    toggleCategory : function(component, event, helper)
    {
        if(component.get('v.showCategory'))
        {
            component.set('v.showCategory', false);
        }
        else
        {
            var categoryType = component.get('v.ct');

            var ce = $A.get("e.c:CategorizationEvent");

            ce.setParam('actionName', 'Show Category Type');
            ce.setParam('recordId', component.get('v.recordId'));
            ce.setParam('categoryType', categoryType.name);

            ce.fire();
        }
    },

    categoryClick : function(component, event, helper)
    {
        console.log('categoryClick');
        var div = event.currentTarget.dataset;
        component.set('v.currentCategoryId', div.value);
    },

    subCategoryClick : function(component, event, helper)
    {
        var div = event.currentTarget.dataset;
        var subId = div.value;
        var catId = div.name;

        helper.handleSubCategorySelection(component, catId, subId);
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');
        var catDefKey = event.getParam('catDefKey');
        var parentCatDefKey = event.getParam('parentCatDefKey');

        if(actionName == 'Add New Category - Search' || actionName == 'Add New Category - Tree')
        {
            helper.toggleCategory(component, catDefKey, parentCatDefKey, true);
        }
        else if(actionName == 'Remove Category' || actionName == 'Remove Category - Tree')
        {
            helper.toggleCategory(component, catDefKey, parentCatDefKey, false);
        }
    },
})