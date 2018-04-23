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
1.0      2017-08-25   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        helper.loadModiaStatuses(component);
    },

    saveClick: function(component, event, helper)
    {
        helper.save(component);
    },
})