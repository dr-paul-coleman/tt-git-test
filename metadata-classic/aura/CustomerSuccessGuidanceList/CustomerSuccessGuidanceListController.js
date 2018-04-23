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

    newCsgClick: function(component, event, helper)
    {
        var incidentEvent = $A.get("e.c:IncidentOpenAction");
        var id = component.get('v.accountId');
        var name = component.get('v.accountName');

        var url = 'a0e/e?Name=MTS+Flag&CF00N3100000GFfuh=' + name + '&CF00N3100000GFfuh_lkid=' + id + '&retURL=%2F' + id;
        console.log(url);

        incidentEvent.setParams({"actionId" : url, "actionName" : 'New Customer Success Guidance' });
        incidentEvent.fire();
    },
})