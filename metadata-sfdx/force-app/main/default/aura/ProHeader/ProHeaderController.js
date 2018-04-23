({
	doInit : function(component, event, helper) {

		helper.getAccount(component);
		helper.loadEnrollment(component);
	},
	handleAccountUpdatedEvent: function(component, event, helper) {
		helper.getAccount(component);
		
	},
	callPro: function(component, event, helper) {
		var appEvent = $A.get('e.c:AccountPhoneClicked');
		appEvent.fire();
	},
	handleScriptsLoaded: function(component, event, helper) {
		var copyButton = component.find('copy-button').getElement();
		new Clipboard(copyButton, {
			text: $A.getCallback(function(trigger) {
				return component.get('v.account.usr_email__c');
			})
		});
	},

	openAccountInTabClick : function(component, event, helper)
	{
	    var account = component.get('v.account');
	    var appEvent = $A.get('e.c:ProEnrollmentEvent');

        appEvent.setParams({
            'url' : '/' + account.Id,
            'title' : account.name,
            'actionName' : 'openSubTab'
        });

        appEvent.fire();
    },
})