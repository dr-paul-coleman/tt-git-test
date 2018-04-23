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
1.0      2017-07-31   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        var action = component.get("c.getAccountRecordTypes");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.acctRecordTypes', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });
        $A.enqueueAction(action);

        helper.getCase(component);
    },

    findEnter: function(component, event, helper)
    {
        console.log('here');
        if(event.keyCode == 13)
        {
            var searchCmp = component.find('searchText');
            helper.clearError(component);

            if(!searchCmp.get('v.validity').valid)
            {
                searchCmp.showHelpMessageIfInvalid();
                console.log('Not valid');
            }
            else
            {
                console.log('Valid');
                helper.reset(component);
                helper.find(component);
            }
        }
    },

    findClick: function(component, event, helper)
    {
        var searchCmp = component.find('searchText');
        helper.clearError(component);

        if(!searchCmp.get('v.validity').valid)
        {
            searchCmp.showHelpMessageIfInvalid();
            console.log('Not valid');
        }
        else
        {
            console.log('Valid');
            helper.reset(component);
            helper.find(component);
        }
    },

    newAccountClick: function(component, event, helper)
    {
        component.set('v.showError', false);
        component.set('v.showNewForm', true);
        component.set('v.showFind', false);
    },

    createAccountClick: function(component, event, helper)
    {
        var emailCmp = component.find('email');
        var firstCmp = component.find('first');
        var lastCmp = component.find('last');
        var userId = component.find('userId');
        var valid = true;

        if(!emailCmp.get('v.validity').valid)
        {
            emailCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!firstCmp.get('v.validity').valid)
        {
            firstCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!lastCmp.get('v.validity').valid)
        {
            lastCmp.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!userId.get('v.validity').valid)
        {
            userId.showHelpMessageIfInvalid();
            valid = false;
        }

        console.log('Is Valid: ' + valid);

        if(valid)
        {
            helper.createAccount(component);
        }
    },

    cancelCreateAccountClick: function(component, event, helper)
    {
        component.set('v.showNewForm', false);
        component.set('v.showFind', true);
        helper.clearError(component);
    },
})