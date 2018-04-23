({
	getAccount : function(component) {
		var enrollmentId = component.get('v.enrollmentId');
		var action = component.get('c.getAccount');
		action.setParams({
			enrollmentId: enrollmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var account = response.getReturnValue();
				component.set('v.account', account);
				component.set("v.proURL","https://www.thumbtack.com/admin/login?usr_user_id="+component.get("v.account.ThumbtackUserID__c")+"&return_url=/profile/account");
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},

	loadEnrollment : function(component)
	{
        var enrollmentId = component.get('v.enrollmentId');
        var action = component.get('c.getEnrollment');

        action.setParams({
            enrollmentId: enrollmentId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.enrollment', response.getReturnValue());
            } else if (state === 'ERROR') {
                // error handling goes here
            }
        });

        $A.enqueueAction(action);
    }
})