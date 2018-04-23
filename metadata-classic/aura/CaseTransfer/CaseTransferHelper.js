/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+===============================================
  1.0      2017-11-21   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */
({
    loadCase : function(component)
    {
        var action = component.get('c.getCase');

        action.setParam('caseId', component.get('v.caseId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.caseRecord', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    loadPersonRecords : function(component)
    {
        var action = component.get('c.getUsersForPersonTransfer');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.personRecords', response.getReturnValue());
            }
            else if (state === 'ERROR')
            { 
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    loadEscalationRecords : function(component)
    {
        var action = component.get('c.getUsersForEscalationTransfer');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.escalationRecords', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    loadQueueRecords : function(component)
    {
        var action = component.get('c.getGroupsForTransfer');

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.queueRecords', response.getReturnValue());
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }
        });

        $A.enqueueAction(action);
    },

    updateCase : function(component)
    {
        var assignmentType = component.get('v.assignmentType');
        var action;
        var escalationType = '';
        var ownerId;

        component.set('v.showSpinner', true);

        if(assignmentType == 'Self')
        {
            action = component.get('c.assignToMe');
        }
        else
        {
            action = component.get('c.assignCase');

            if(assignmentType == 'Queue')
            {
                ownerId = component.get('v.selectedTeamId');
            }
            else if(assignmentType == 'Person')
            {
                ownerId = component.get('v.selectedUserId');
            }
            else if(assignmentType == 'Escalation')
            {
                escalationType = component.get('v.selectedEscalationType');
                ownerId = component.get('v.selectedEscalationUserId');
            }

            action.setParam('ownerId', ownerId);
            action.setParam('comment', component.get('v.comment'));
            action.setParam('escalationType', escalationType);
        }

        action.setParam('caseId', component.get('v.caseId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                var result = response.getReturnValue();

                if(result == 'Success')
                {
                    this.loadCase(component);
                    this.clearFields(component);
                }
                else
                {
                    component.set('v.message', result);
                }
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCase')
            }

            component.set('v.showSpinner', false);
        });

        $A.enqueueAction(action);
    },

    clearFields : function(component)
    {
        component.set('v.selectedUserId', null);
        component.set('v.selectedEscalationUserId', null);
        component.set('v.selectedTeamId', null);
        component.set('v.comment', null);
        component.set('v.showFlowMi', false);
        component.set('v.showFlowPae', false);

        var rc = $A.get("e.c:CaseTransferEvent");

        rc.setParam('actionName', 'Refresh Case');
        rc.setParam('caseId', component.get('v.caseId'));
        rc.fire();
    },
})