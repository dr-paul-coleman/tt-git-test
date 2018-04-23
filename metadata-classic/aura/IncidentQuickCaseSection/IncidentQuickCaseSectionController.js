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
1.0      2017-08-31   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit : function(component, event, helper)
    {
        window.addEventListener("message", function(event) {
            /*if (event.origin !== 'Thumbtack') {
                // Not the expected origin: Reject the message!
                console.log('Wrong Origin');
                return;
            }*/
            if(event.data == 'Email Sent')
            {
                //console.log('Received email sent message!');
                helper.updateCase(component);
            }

        }, false);

        helper.loadButtons(component);
    },

    closeToastClick: function(component, event, helper)
    {
        //console.log('Close Click');
        helper.clearMessage(component);
    },

    hideEmail: function(component, event, helper)
    {
        component.set('v.showEmailComposer', false);
        //helper.resetCase(component);
        //helper.updateCase(component);
    },

    createCaseClick: function(component, event, helper)
    {
        var settingId = event.getSource().get('v.value');

        console.log(settingId);
        helper.createCase(component, settingId);
    },
})