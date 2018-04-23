/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-23   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    doInit : function(component, event, helper)
    {
        helper.loadUserSettings(component);

        var recordId = component.get('v.recordId');

        if(recordId != null && recordId.indexOf('500') == 0)
        {
            component.set('v.showCaseComponent', true);
        }
    },

    toggleView : function(component, event, helper)
    {
        if(component.get('v.splitViewStatus') == 'slds-is-open')
        {
            component.set('v.splitViewStatus', 'slds-is-closed');
        }
        else
        {
             component.set('v.splitViewStatus', 'slds-is-open');
        }

        helper.saveCategoryTreeSetting(component);
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.caseMessage', '');
        component.set('v.catMessage', '');
        component.set('v.prodUpdateMessage', '');
    },

    submitClick : function(component, event, helper)
    {
        var ce = $A.get("e.c:CategorizationEvent");

        component.set('v.allowSubmit', false);

        ce.setParam('actionName', 'Save Records');
        ce.setParam('recordId', component.get('v.recordId'));

        ce.fire();
    },
})