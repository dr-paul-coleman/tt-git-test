trigger CommentTrigger on Comments__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

		if (Trigger.isBefore) {
	    	//call your handler.before method
	    
		} else if (Trigger.isAfter) {
	    	//call handler.after method
	    	if(Trigger.isinsert)
	    	{
	    		List<String>commentids = new List<String>();
	    		for(Comments__c comment:Trigger.new)
	    		{
	    			if(comment.CreatedInJIra__c == false && (comment.SupportProcess__c !=null || comment.Bug__c != null))commentids.add(comment.Id);
	    		}
	    		system.debug(commentids);
	    		if(commentIds.size()>0)JiraCallout.addComment(commentIds);
	    	}
	    
		}
}