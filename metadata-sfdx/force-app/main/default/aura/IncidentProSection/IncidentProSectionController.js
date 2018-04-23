/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-21   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    editClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        component.set('v.showModal', true);
    },

    cancelClick: function(component, event, helper)
    {
        //console.log('Cancel Click');
        helper.reloadIncident(component);
        helper.closeModal(component);
        helper.clearMessage(component);
    },

    saveClick: function(component, event, helper)
    {
        var userId = component.find('userId');
        var valid = true;

        if(!userId.get('v.validity').valid)
        {
            userId.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            helper.save(component);
        }
    },

    closeToastClick: function(component, event, helper)
    {
        //console.log('Close Click');
        helper.clearMessage(component);
    },

    hideEmail: function(component, event, helper)
    {
        component.set('v.showEmailComposer', false);
    },

    accountClick: function(component, event, helper)
    {
        var incident = component.get('v.incident');
        var accountId = incident.ProAccount__c;
        var accountName = incident.ProAccount__r.Name;

        helper.openLink(component, accountId, accountName);
    },

    contactClick: function(component, event, helper)
    {
        var incident = component.get('v.incident');
        var contactId = incident.ProContact__c;
        var contactName = incident.ProContact__r.Name;

        helper.openLink(component, contactId, contactName);
    },
})