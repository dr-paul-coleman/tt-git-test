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
1.0      2017-08-15   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
         helper.loadStatuses(component);
         helper.loadRequests(component);
    },

    submitClick: function(component, event, helper)
    {
        //var last4Cmp = component.find('last4');
        var amountCmp = component.find('amount');
        var valid = true;

        /*if(!last4Cmp.get('v.validity').valid)
        {
            last4Cmp.showHelpMessageIfInvalid();
            valid = false;
        }*/

        if(!amountCmp.get('v.validity').valid)
        {
            amountCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            //console.log('call save request');
            helper.saveRequest(component, helper);
        }
    },

    toggleMoreList: function(component)
    {
        component.set('v.showMoreList', !component.get('v.showMoreList'));
    },
});