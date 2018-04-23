/*
Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================

*/
({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log(recordId);
        if(recordId)
        {
            helper.getExternalId(component, recordId);
        }
    }
})