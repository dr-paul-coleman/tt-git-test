/**
 * Created by SentientGrey on 10/27/17.
 */
({
    doInit : function(component, event, helper)
    {
        helper.loadCaseStatuses(component);
    },

    onStatusChange : function(component, event, helper)
    {
        component.set('v.allowSubmit', true);
    },

    handleCategorizationEvent : function(component, event, helper)
    {
        var actionName = event.getParam('actionName');

        if(actionName == 'Save Records')
        {
            helper.saveCase(component);
        }
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },

})