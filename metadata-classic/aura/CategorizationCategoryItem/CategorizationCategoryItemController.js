/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-27   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    doInit : function(component, event, helper)
    {
        var cw = component.get('v.cw');

        if(cw != null && cw.category.Notes__c && cw.category.Notes__c.length > 0)
        {
            component.set('v.textCount', cw.category.Notes__c.length);
        }
    },

    sentimentClick : function(component, event, helper)
    {
        var span = event.currentTarget.dataset;
        var cat = component.get('v.cw');
        var newValue = Number.parseInt(span.value);
        var forCategories = component.get('v.forCategories');

        if(cat.category.Sentiment__c == newValue)
        {
            cat.category.Sentiment__c = 0;
        }
        else
        {
            cat.category.Sentiment__c = newValue;
        }

        if(!forCategories)
        {
            cat.selected = true;
        }

        component.set('v.allowSubmit', true);
        component.set('v.cw', cat);
    },

    onChange : function(component, event, helper)
    {
        component.set('v.allowSubmit', true);
    },

    onPrimaryChange : function(component, event, helper)
    {
        var cw = component.get('v.cw');
        component.set('v.allowSubmit', true);

        if(cw.category.Primary__c == true)
        {
            var ce = $A.get("e.c:CategorizationEvent");

            ce.setParam('actionName', 'Primary Change');
            ce.setParam('recordId', component.get('v.recordId'));
            ce.setParam('index', component.get('v.index'));
            ce.setParam('primaryCategory', cw.category.Category__c);
            ce.setParam('primarySubcategory', cw.category.Subcategory__c);

            ce.fire();
        }
    },

    onTextChange : function(component, event, helper)
    {
        var cw = component.get('v.cw');
        var forCategories = component.get('v.forCategories');

        if(forCategories)
        {
            if(cw.category.Notes__c == null || cw.category.Notes__c == '')
            {
                cw.category.Feedback__c = false;
            }
        }
        else
        {
            cw.selected = true;
        }

        component.set('v.allowSubmit', true);
        component.set('v.cw', cw);

        component.set('v.textCount', cw.category.Notes__c.length);
    },

    onTextFocus : function(component, event, helper)
    {
        component.set('v.showModal', true);
    },

    onEditClick : function(component, event, helper)
    {
        component.set('v.showModal', true);
    },

    doneClick : function(component, event, helper)
    {
        component.set('v.showModal', false);
    },

    removeCategoryClick : function(component, event, helper)
    {
        var ce = $A.get("e.c:CategorizationEvent");
        var span = event.currentTarget.dataset;
        var catDefKey = span.value;
        var parentCatDefKey = span.name;

        ce.setParam('actionName', 'Remove Category');
        ce.setParam('recordId', component.get('v.recordId'));
        ce.setParam('catDefKey', catDefKey);
        ce.setParam('parentCatDefKey', parentCatDefKey);

        ce.fire();
    },

    toggleHelp : function(component, event, helper)
    {
        component.set('v.showHelp', !component.get('v.showHelp'));
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');
        var index = event.getParam('index');

        if(actionName == 'Primary Change' && index != component.get('v.index') && component.get('v.forCategories'))
        {
            var cw = component.get('v.cw');

            cw.category.Primary__c = false;
            component.set('v.cw', cw);
        }
    },
})