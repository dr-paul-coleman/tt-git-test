({
	handleStepChange : function(component) {
		var initialStep = component.get('v.initialStep');
		var currentStep = component.get('v.currentStep');
		var endStep = component.get('v.endStep');
		var alreadyCompleted = component.get('v.alreadyCompleted');
		var isComplete = component.get('v.isComplete');
		if (!$A.util.isEmpty(currentStep)) {
			if ($A.util.isEmpty(initialStep)) {
				initialStep = currentStep;
				alreadyCompleted = initialStep == endStep;
			}
			isComplete = currentStep == endStep;
		}
		if (isComplete && !alreadyCompleted) {
			console.log('animation');
		}
		component.set('v.isComplete', isComplete);
		component.set('v.initialStep', initialStep);
		component.set('v.alreadyCompleted', alreadyCompleted);
	}
})