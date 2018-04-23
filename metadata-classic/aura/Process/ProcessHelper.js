({
	computeCurrentStepIndex : function(component) {
		var currentStepIndex = 0;
		var currentStep = component.get('v.currentStep');
		var steps = component.get('v.steps');
		if (steps) {
			steps.forEach(function(step, stepIndex) {
				if (currentStep == step) {
					currentStepIndex = stepIndex;
				}
			});
		}
		component.set('v.currentStepIndex', currentStepIndex);
	},
	getParameterByName: function(name, url) {
		if (!url) url = window.location.href;
		name = name.replace(/[\[\]]/g, "\\$&");
		var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
			results = regex.exec(url);
		if (!results) return null;
		if (!results[2]) return '';
		return decodeURIComponent(results[2].replace(/\+/g, " "));
	}
})