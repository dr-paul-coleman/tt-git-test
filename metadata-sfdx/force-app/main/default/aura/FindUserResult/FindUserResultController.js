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
    },

    setRecordId: function(component, event, helper)
    {
        var recordId = event.getSource().get('v.value'); //event.getSource().get('v.text');
        console.log(recordId);

        if(recordId.startsWith('003'))
        {
            helper.setContactId(component, recordId);
        }
        else
        {
            helper.setUserId(component, recordId);
        }

        component.set('v.showFind', false);
        helper.clearError(component);
    },

    createAccountClick: function(component, event, helper)
    {
        helper.createAccount(component);
    },

    updateAccountClick: function(component, event, helper)
    {
        helper.updateAccount(component); 
    },

    cancelCreateAccountClick: function(component, event, helper)
    {
        //component.set('v.pagedResults', component.get('v.pagedResults'));
        component.set('v.selectedUser', null);
        component.set('v.showCreateAccount', false);
        component.set('v.showData', true);
        component.set('v.showFind', true);
        component.set('v.existingContact', null);
        helper.clearError(component);
    },

    confirmClick: function(component, event, helper)
    {
        helper.updateCase(component);
    },

    cancelConfirmClick: function(component, event, helper)
    {
        //component.set('v.pagedResults', component.get('v.pagedResults'));
        component.set('v.selectedContact', null);
        component.set('v.showSelectedContact', false);
        component.set('v.showData', true);
        component.set('v.showFind', true);
        helper.clearError(component);
    },

    previousPageClick: function(component, event, helper)
    {
        var currentPage = component.get('v.currentPage');

        if(currentPage > 1)
        {
            currentPage -= 1;

            helper.setResultPage(component, currentPage);
            component.set('v.currentPage', currentPage);
        }
    },

    nextPageClick: function(component, event, helper)
    {
        var currentPage = component.get('v.currentPage');
        var numberOfPages = component.get('v.numberOfPages');

        if(currentPage < numberOfPages)
        {
            currentPage += 1;

            helper.setResultPage(component, currentPage);
            component.set('v.currentPage', currentPage);
        }
    },

    addNewClick: function(component, event, helper)
    {
        console.log('Add new Click');
        component.set('v.showData', false);
        component.set('v.showNewForm', true);
        component.set('v.showFind', false);
        helper.clearError(component);
    },
})