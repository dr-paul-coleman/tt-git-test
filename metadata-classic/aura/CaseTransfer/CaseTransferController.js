/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+===============================================
  1.0      2017-11-21   Mendel Guillaume       Created
  ========+============+=================+===============================================
 */

({
    doInit : function(component, event, helper)
    {
        helper.loadCase(component);
        helper.loadPersonRecords(component);
        helper.loadEscalationRecords(component);
        helper.loadQueueRecords(component);
    },

    transferChange : function(component, event, helper)
    {
        console.log(event.getSource().get('v.label'));
        component.set('v.assignmentType', event.getSource().get('v.label'));
    },

    closeToastClick: function(component, event, helper)
    {
        component.set('v.message', '');
    },

    updateClick : function(component, event, helper)
    {
        var miQueue = component.get('v.miQueueId');
        var paeQueue = component.get('v.paeQueueId');
        var selectedTeamId = component.get('v.selectedTeamId');

        component.set('v.message', '');

        console.log('selected team id: ' + selectedTeamId);
        console.log('miQueue: ' + miQueue);
        console.log('assignmentType: ' + component.get('v.assignmentType'));

        if(component.get('v.assignmentType') == 'Queue' && (selectedTeamId == miQueue || selectedTeamId == paeQueue))
        {
            var inputParams = [{name: 'CaseId', type: 'String', value: component.get('v.caseId')}];

            if(selectedTeamId == miQueue)
            {
                var flow = component.find("transferFlowMi");

                flow.startFlow('MTSTransferFlow', inputParams);
                component.set('v.showFlowMi', true);
            }
            else
            {
                var flow = component.find("transferFlowPae");

                flow.startFlow('ProAssistDecisionTreeCaseTransfer', inputParams);
                component.set('v.showFlowPae', true);
            }
        }
        else
        {
            helper.updateCase(component);
        }
    },

    handleStatusChange : function (component, event, helper)
    {
        console.log('Status: ' + event.getParam("status"));

        if(event.getParam("status") === "FINISHED")
        {
            console.log('Finished - Clear Fields');
            helper.clearFields(component);
        }
    },

    backClick : function(component, event, helper)
    {
        helper.clearFields(component);
    },
})