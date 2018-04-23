({
	doInit : function(component, event, helper) {
		helper.computeCurrentStepIndex(component);
		var paramVal = helper.getParameterByName('showAnimation');
		component.set('v.showAnimation', !$A.util.isEmpty(paramVal));
	},
	handleCurrentStepChange: function(component, event, helper) {
		helper.computeCurrentStepIndex(component);
	},
	viewFunnelStep: function(component, event, helper) {
		var link = event.currentTarget;
		var funnelStep = link.dataset.funnelStep;
		var funnelStepIndex = link.dataset.funnelStepIndex;
		var currentStepIndex = component.get('v.currentStepIndex');
		if (funnelStepIndex <= currentStepIndex) {
			var appEvent = $A.get('e.c:FunnelStepClicked');
			appEvent.setParams({
				funnelStep: funnelStep
			});
			appEvent.fire();
		}
	}
})