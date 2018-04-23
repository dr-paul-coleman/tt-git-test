/**
 * Created by SentientGrey on 12/6/17.
 */
({
    submitClick : function(component, event, helper)
    {
        var post = component.get('v.post');
        var valid = post.length > 0;

        if(valid)
        {
            helper.submitPost(component, post);
        }
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },
})