/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-25   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
({
    doInit: function(component, event, helper)
    {
        helper.loadDisputeRecord(component);
        //console.log('User Id: ' + $A.get('$SObjectType.CurrentUser.Id'));
    },

    handleTipChange: function(component, event, helper)
    {
        var tipId = event.getParam('value');

        if(!$A.util.isEmpty(tipId))
        {
            var tips = component.get('v.successTips');

            for(var i = 0; i < tips.length; i++)
            {
                if(tips[i].record.Id == tipId)
                {
                    var dmr = component.get('v.disputeMessageRecord');
                    dmr.Message__c = tips[i].record.MessageTemplate__c;
                    component.set('v.disputeMessageRecord', dmr);
                    break;
                }
            }
        }
    },

    sendTipClick: function(component, event, helper)
    {
        console.log('initiatorSelected: ' + component.get('v.initiatorSelected'));
        console.log('responderSelected: ' + component.get('v.responderSelected'));
        helper.saveRecord(component);
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.message', '');
    },
})