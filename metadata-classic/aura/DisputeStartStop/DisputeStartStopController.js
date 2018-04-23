/**
 * Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+===============================================
   1.0      2018-01-29   Mendel Guillaume       Created
   ========+============+=================+===============================================
 */
({
    doInit: function(component, event, helper)
    {
        helper.loadStatusMap(component);
    },

    restartClick: function(component, event, helper)
    {
        helper.save(component, 'Restart');
    },

    stopClick: function(component, event, helper)
    {
        helper.save(component, 'Stop');
    },

    closeClick: function(component, event, helper)
    {
        helper.save(component, 'Close');
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.message', '');
    },

    closeModalClick: function(component, event, helper)
    {
        component.set('v.showModal', false);
    },

    openModalClick: function(component, event, helper)
    {
        component.set('v.showModal', true);
    },

    closeCloseModalClick: function(component, event, helper)
    {
        component.set('v.showCloseModal', false);
    },

    openCloseModalClick: function(component, event, helper)
    {
        component.set('v.showCloseModal', true);
    },

    onStatusChange: function(component, event, helper)
    {
        //console.log('onStatusChange');
        helper.setStages(component);
    },

})