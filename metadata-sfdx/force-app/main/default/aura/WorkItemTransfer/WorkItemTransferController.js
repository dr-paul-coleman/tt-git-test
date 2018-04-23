/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-03   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/
({
    doInit: function(component, event, helper)
    {
        helper.loadRecordsRT(component);
        helper.loadRecords(component);
    },

    transfer: function(component, event, helper)
    {
        var type = event.getSource().get('v.value');

        helper.transferItem(component, type);
    },

    transferRT: function(component, event, helper)
    {
        var type = event.getSource().get('v.value');

        helper.transferItemRT(component, type);
    },
})