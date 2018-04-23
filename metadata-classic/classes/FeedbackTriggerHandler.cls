/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     06-01-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/                                                                                       
public with sharing class FeedbackTriggerHandler 
{
	public static Id psfRecordTypeId = ProductFeedback__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Pro Services Feedback').getRecordTypeId();
	public static void isAfterInsert(List<ProductFeedback__c> feedbacks,Map<Id,ProductFeedback__c>feedbackMap) 
	{
		for(ProductFeedback__c feedback:feedbacks)
		{
			if(feedback.RecordTypeId == psfRecordTypeId && feedback.Case__c != null)
			{
				try
				{
					system.debug('feedback.Case__r.Id: '+feedback.Case__c);
					String response = ' PA Feedback submitted by '+feedback.FeedbackOwnerName__c + ', https://thumbtack.my.salesforce.com/console#%2F'+feedback.Id;
					system.debug('Response: '+response);
					ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedback.Case__c, ConnectApi.FeedElementType.FeedItem, response);
				}
				catch(Exception e){system.debug(e);}
			} 
		}
		
	}
	//public static void isBeforeUpdate(List<ProductFeedback__c> feedbacks,List<ProductFeedback__c> oldFeedbacks,Map<Id,ProductFeedback__c>feedbackMap,Map<Id,ProductFeedback__c>oldFeedbackMap) 
	//{
		
	//}
}