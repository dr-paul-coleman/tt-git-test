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
1.0      2017-08-29   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        helper.loadEscalationTypes(component);
    },

    submitClick: function(component, event, helper)
    {
        var escTypes = component.find('escTypes');
        var valid = true;

        if(!escTypes.get('v.validity').valid)
        {
            escTypes.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            helper.save(component);
        }
    },
})