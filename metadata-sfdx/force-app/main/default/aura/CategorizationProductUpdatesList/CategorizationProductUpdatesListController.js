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
        helper.loadProductUpdates(component);
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');

        if(actionName == 'Save Records')
        {
            helper.saveProductUpdates(component);
        } 
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },
})