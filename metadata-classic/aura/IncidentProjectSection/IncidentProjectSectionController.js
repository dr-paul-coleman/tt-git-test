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
1.0      2017-08-22   Mendel Guillaume       Created
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
        helper.save(component);
    },

    closeToastClick: function(component, event, helper)
    {
        //console.log('Close Click');
        helper.clearMessage(component);
    },
})