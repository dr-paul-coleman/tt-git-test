/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-25   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    onSearchChange : function(component, event, helper)
    {
        var searchText = component.get('v.searchValue');

        if(searchText == '' || searchText == null)
        {
            helper.displaySearch(component, false);
        }
        else
        {
            helper.search(component, searchText);
        }
    },

    onSearchFocus : function(component, event, helper)
    {

    },

    onSearchBlur : function(component, event, helper)
    {
    },

    onItemClick : function(component, event, helper)
    {
        var span = event.currentTarget.dataset;
        var catDefKey = span.value;
        var parentCatDefKey = span.name;

        helper.displaySearch(component, false);
        component.set('v.showSearching', false);
        component.set('v.searchValue', '');

        var ce = $A.get("e.c:CategorizationEvent");

        ce.setParam('actionName', 'Add New Category - Search');
        ce.setParam('recordId', component.get('v.recordId'));
        ce.setParam('catDefKey', catDefKey);
        ce.setParam('parentCatDefKey', parentCatDefKey);

        ce.fire();
    },
})