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
    doInit: function(component, event, helper)
    {
        helper.loadRecords(component);
    },

    viewClick: function(component, event, helper)
    {
        //console.log('View Click');
        var span = event.currentTarget.dataset;
        var incidentEvent = $A.get("e.c:IncidentOpenAction");
        var id = span.value;
        var name = span.name;

        incidentEvent.setParams({"actionId" : id, "actionName" : name });
        incidentEvent.fire();
    },
})