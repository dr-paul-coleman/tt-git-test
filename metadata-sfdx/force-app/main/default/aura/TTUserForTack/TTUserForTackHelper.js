/**
 * Created by jkennington on 1/29/18.
 */
({
    getExternalId : function (component, recordId) {
        var action = component.get("c.getExternalObjectId");

        action.setParams({"accountId" : recordId});
        action.setCallback(this,function(result){
                var state = result.getState();
                if (component.isValid() && state == "SUCCESS"){
                    component.set("{!v.userId}",result.getReturnValue());
                }
                else
                {
                    component.set('{!v.showError}', true);
                    console.log('Failed: ' + state);
                }
                component.set('{!v.showSpinner}', false);
            }
        );
        $A.enqueueAction(action);
    }
})