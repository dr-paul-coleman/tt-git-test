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
1.0      2017-08-02   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    createAccount: function(component)
    {
        var rt = component.get('v.selectedAcctRecType');
        var user = component.get('v.selectedUser');
        var caseId = component.get('v.caseId');

        component.set('v.showSpinnerCreateAccount', true);
        component.set('v.error', '');
        console.log(rt);
        console.log(user);

        var action = component.get("c.createAccountContactFromUser");

        action.setParams({"usr" : user, "acctRecType" : rt, "caseId" : caseId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.selectedUser', null);
                    component.set('v.showCreateAccount', false);
                    component.set('v.showData', false);
                    component.set('v.showFind', true);

                    this.fireEvent(component, result, caseId);
                }
                else
                {
                    component.set('v.error', result.error);
                }

                console.log(result);
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinnerCreateAccount', false);
        });

        $A.enqueueAction(action);
    },

    updateAccount: function(component)
    {
        var rt = component.get('v.selectedAcctRecType');
        var user = component.get('v.selectedUser');
        var caseId = component.get('v.caseId');
        var existingContact = component.get('v.existingContact');

        component.set('v.showSpinnerCreateAccount', true);
        component.set('v.error', '');
        console.log(rt);
        console.log(user);

        var action = component.get("c.updateAccountContactFromUser");

        action.setParams({"usr" : user, "accountId" : existingContact.AccountId, "contactId" : existingContact.Id, "caseId" : caseId});
 
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.selectedUser', null);
                    component.set('v.showCreateAccount', false);
                    component.set('v.showData', false);
                    component.set('v.showFind', true);
                    component.set('v.existingContact', null);

                    this.fireEvent(component, result, caseId);
                }
                else
                {
                    component.set('v.error', result);
                }

                console.log(result);
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinnerCreateAccount', false);
        });

        $A.enqueueAction(action);
    },

    updateCase : function(component)
    {
        var contact = component.get('v.selectedContact');
        var caseId = component.get('v.caseId');

        component.set('v.showSpinnerConfirm', true);
        component.set('v.error', '');
        console.log(contact);

        var action = component.get("c.updateCase");

        action.setParams({"accountId" : contact.AccountId, "contactId" : contact.Id, "caseId" : caseId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.selectedContact', null);
                    component.set('v.showSelectedContact', false);
                    component.set('v.showData', false);
                    component.set('v.showFind', true);

                    this.fireEvent(component, result, caseId);
                }
                else
                {
                    component.set('v.error', result);
                }

                console.log(result);
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinnerConfirm', false);
        });

        $A.enqueueAction(action);
    },

    setContactId: function(component, contactId)
    {
        var results = component.get('v.pagedResults');
        var contact;

        component.set('v.selectedContactId', contactId);

        for(var j = 0; j < results.length; j++)
        {
            if(results[j].recordId == contactId)
            {
                contact = results[j].contact;
                break;
            }
        }

        console.log(contact);
        component.set('v.selectedContact', contact);
        component.set('v.showSelectedContact', true);
        component.set('v.showData', false);
    },

    setUserId: function(component, userId)
    {
        var results = component.get('v.pagedResults');
        var usr = null;

        console.log(userId);
        component.set('v.selectedUserId', userId);

        for(var i = 0; i < results.length; i++)
        {
            if(results[i].recordId == userId)
            {
                usr = results[i].user;
                break;
            }
        }

        console.log(usr);

        //Check if there is an existing contact in Salesforce with the user Id
        var action = component.get("c.findExistingContact");

        action.setParams({"userId" : usr.usr_user_id__c});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var existingContact = response.getReturnValue();

                component.set('v.existingContact', existingContact);
                component.set('v.selectedUser', usr);
                component.set('v.showCreateAccount', true);
                component.set('v.showData', false);
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action);
    },

    setResultPage: function(component, currentPage)
    {
        var pageSize = component.get('v.pageSize');
        var startIndex = (currentPage - 1) * 10;
        var endIndex = currentPage * 10;
        var results = component.get('v.results');
        var pagedResults;

        if(endIndex > results.length)
        {
            pagedResults = results.slice(startIndex);
        }
        else
        {
            pagedResults = results.slice(startIndex, endIndex);
        }

        component.set('v.pagedResults', pagedResults);
    },

    clearError: function(component)
    {
        component.set('v.error', '');
    },

    fireEvent: function(component, result, caseId)
    {
        if(caseId != null && caseId != '')
        {
            var refCaseEvent = $A.get('e.c:FindUserRefreshCaseEvent');
            refCaseEvent.fire();
        }
        else
        {
            var redirectToAccount = $A.get('e.c:FindUserEvent');
            redirectToAccount.setParams({'actionName' : 'accountRedirect', 'accountId' : result.record.Id});
            redirectToAccount.fire();
        }
    },
})