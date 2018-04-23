/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+===============================================
  1.0      2017-11-22   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */
({
    doInit: function(component, event, helper)
    {
        helper.loadOrigins(component);
    },

    submitClick : function(component, event, helper)
    {
        var fullName = component.find('fullName');
        var email = component.find('email');
        var subject = component.find('subject');
        var origin = component.find('origin');
        var valid = true;

        if(!fullName.get('v.validity').valid)
        {
            fullName.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!email.get('v.validity').valid)
        {
            email.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!subject.get('v.validity').valid)
        {
            subject.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!origin.get('v.validity').valid)
        {
            origin.showHelpMessageIfInvalid();
            valid = false;
        }

        if(valid)
        {
            helper.submit(component);
        }
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.message', '');
    },
})