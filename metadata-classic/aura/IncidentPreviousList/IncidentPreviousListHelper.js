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
1.0      2017-08-28   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    loadRecords: function(component)
    {
        var action = component.get('v.isPro') ? component.get('c.getProIncidents') : component.get('c.getCustomerIncidents');

        action.setParams({'accountId' : component.get('v.accountId'), 'incidentId' : component.get('v.incidentId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == 'SUCCESS')
            {
                component.set('v.records', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },
})