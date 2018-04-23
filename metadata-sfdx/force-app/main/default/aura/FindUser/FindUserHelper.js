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
    find: function(component)
    {
        var pageSize = 10;
        var action = component.get("c.findUser");
        component.set('v.showError', false);
        component.set('v.showSpinnerFind', true);
        component.set('v.showSearchWarning', false);

        action.setParams({"searchText" : component.find('searchText').get("v.value")});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var results = response.getReturnValue();
                var pagedResults;

                component.set('v.results', results);
                //console.log(results);

                if(results.length > 0)
                {
                    console.log('1');
                    component.set('v.recordsFound', true);
                    component.set('v.showData', true);

                    if(results.length > 100)
                    {
                        component.set('v.showSearchWarning', true);
                    }

                    if(pageSize > results.length)
                    {
                        pagedResults = results.slice(0);
                    }
                    else
                    {
                        pagedResults = results.slice(0, 10);
                    }

                    component.set('v.pagedResults', pagedResults);
                    component.set('v.numberOfPages', Math.ceil(results.length / 10));
                }
                else
                {
                    console.log('2');
                    component.set('v.recordsFound', false);
                    component.set('v.showData', false);
                    component.set('v.showError', true);
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }

            component.set('v.showSpinnerFind', false);
        });

        $A.enqueueAction(action);
    },

    reset: function(component)
    {
       component.set('v.showError', false);
       component.set('v.showNewForm', false);
       component.set('v.currentPage', 1);
    },

    createAccount: function(component)
    {
        var action = component.get("c.createNewAccountContact");
        var caseId = component.get('v.caseId');
        var userId = component.find('userId').get('v.value');

        if(userId == '' || userId == null)
        {
            userId = -1;
        }

        component.set('v.showSpinnerCreateAccount', true);
        component.set('v.error', '');

        action.setParams({"email" : component.find('email').get("v.value"), "first" : component.find('first').get("v.value"),
                "last" : component.find('last').get("v.value"), "acctRecType" : component.get('v.selectedAcctRecType'),
                "userId" : userId ,"caseId" : caseId});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var result = response.getReturnValue();

                if(result.success)
                {
                    component.set('v.showNewForm', false);
                    component.set('v.showFind', true);

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

    getCase: function(component)
    {
        var action = component.get("c.getCase");

        action.setParams({"caseId" : component.get('v.caseId')});

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                var caseRecord = response.getReturnValue();
                console.log(caseRecord);
               // console.log(caseRecord.Contact.Name);

                if(caseRecord != null && caseRecord.Contact != null && caseRecord.Contact.Name != null)
                {
                    var searchTextCmp = component.find('searchText');
                    searchTextCmp.set('v.value', caseRecord.Contact.Name);
                }
                else
                {
                    console.log('No Case Data!')
                }
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });
        $A.enqueueAction(action);
    },

    clearError: function(component)
    {
        component.set('v.error', '');
    },
})