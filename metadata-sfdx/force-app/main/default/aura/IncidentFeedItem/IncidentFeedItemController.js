({
	toggleDetails : function(component, event, helper)
	{
	    var feedItem = component.get('v.feedItem');

		if(feedItem.itemType != 'call')
		{
		    var summary = component.find('feed-item-summary');
		    $A.util.toggleClass(summary, 'slds-hide');
		}

		var details = component.find('feed-item-details').getElement();
		$(details).slideToggle();
	},

	viewClick: function(component, event, helper)
    {
        var span = event.currentTarget.dataset;
        var viewEvent = $A.get("e.c:IncidentOpenAction");
        var id = span.value;
        var name = span.name;

        viewEvent.setParams({"actionId" : id, "actionName" : name });
        viewEvent.fire();
    },
})