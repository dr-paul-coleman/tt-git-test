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
1.0      2017-08-16   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
         helper.loadStatuses(component);
         helper.loadApprovedBy(component);
         helper.loadTypes(component);
         helper.loadRequests(component);
    },

    submitClick: function(component, event, helper)
    {
        var typeCmp = component.find('type');
        var amountCmp = component.find('amount');
        var streetCmp = component.find('street');
        var fullNameCmp = component.find('fullName');
        var cityCmp = component.find('city');
        var approvedByCmp = component.find('approvedBy');

        var valid = true;

        if(!typeCmp.get('v.validity').valid)
        {
            typeCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!amountCmp.get('v.validity').valid)
        {
            amountCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!streetCmp.get('v.validity').valid)
        {
            streetCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!fullNameCmp.get('v.validity').valid)
        {
            fullNameCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!cityCmp.get('v.validity').valid)
        {
            cityCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!approvedByCmp.get('v.validity').valid)
        {
            approvedByCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            console.log('call save request');
            helper.saveRequest(component, helper);
        }
    },

    toggleMoreList: function(component)
    {
        component.set('v.showMoreList', !component.get('v.showMoreList'));
    },

})