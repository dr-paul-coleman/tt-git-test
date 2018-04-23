({
	doInit : function(component, event, helper) {
		helper.getFactors(component);
	},

	handleIncidentIdChange: function(component, event, helper) {
		helper.getFactors(component);
	},

	handleRefresh : function(component, event, helper)
	{
        var eventName = event.getParam('name');

        if(eventName == 'IncidentFactors')
        {
            helper.getFactors(component);
        }
    }, 
})