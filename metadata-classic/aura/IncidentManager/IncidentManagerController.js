({
	doInit : function(component, event, helper) {
		helper.getIncident(component);
	},

	handleRefresh : function(component, event, helper) {
	    var eventName = event.getParam('name');

	    if(eventName == 'Incident')
	    {
    		helper.getIncident(component);
        }
    },

	toggleShowNotes: function(component, event, helper) {
		component.set('v.view', 'Notes');
		helper.clearButtonSelection(component);
		helper.highlightSelectedButton(component, 'btnNotes', 'brand');
	},
	
	toggleShowActions: function(component, event, helper) {
		component.set('v.view', 'Actions');
		helper.clearButtonSelection(component);
        helper.highlightSelectedButton(component, 'btnTasks', 'brand');
	},

	showChargeCardRequests: function(component, event, helper)
	{
        component.set('v.view', 'ChargeCardRequests');
    },

    showPayoutRequests: function(component, event, helper)
    {
        component.set('v.view', 'PayoutRequests');
    },

	openClassicMIView : function (component, event, helper) {
	    window.location.href = "/"+component.get('v.recordId')+'?nooverride=1';

	  //  var openEvent = $A.get("e.c:OpenInPrimaryTab");
      //  var url = '/' + component.get('v.incident').Id + '?nooverride=1';
      //  openEvent.setParams({"url" : url, "name" : component.get('v.incident').Name});
      //  openEvent.fire();
	},

	handleActionSelect: function(component, event, helper)
	{
	    var selectedValue = event.getParam('value');

	    component.set('v.view', selectedValue);

	    helper.clearButtonSelection(component);

        if(selectedValue == 'ChargeCardRequests')
        {
            $A.util.addClass(component.find('miCharge'), 'menu-highlight');
        }
        else if(selectedValue == 'PayoutRequests')
        {
            $A.util.addClass(component.find('miPayout'), 'menu-highlight');
        }
        else if(selectedValue == 'Escalation')
        {
            $A.util.addClass(component.find('miEscalate'), 'menu-highlight');
        }
    },
});