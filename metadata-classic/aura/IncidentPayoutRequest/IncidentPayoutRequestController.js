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
    requestClick : function(component, event, helper)
    {
        var incidentEvent = $A.get("e.c:IncidentOpenAction");

        incidentEvent.setParams({"actionId" : component.get("v.payoutRequest.Id"), "actionName" : component.get("v.payoutRequest.Name") });
        incidentEvent.fire();
    },
})