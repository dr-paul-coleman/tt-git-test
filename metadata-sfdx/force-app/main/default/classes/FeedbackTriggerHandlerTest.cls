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
 =======+===========+=================+==============================================
 1.0     07-14-2017   Scott Purcell     Created 
 =======+===========+=================+=============================================*/
@isTest
private class FeedbackTriggerHandlerTest {
	public static Id psfRecordTypeId = ProductFeedback__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Pro Services Feedback').getRecordTypeId();
	@isTest static void testCreateFeedback() 
	{

        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            insert new Contact[]{new Contact(LastName='Tester',FirstName='Chester',Email='testerfound@bogus.testing.com',usr_user_id__c=12),new Contact(LastName='Tester2',FirstName='Chester',Email='tester2@bogus.testing.com',usr_user_id__c=13)};
            Test.startTest();

            Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester',SuppliedThumbtackID__c=120);
            insert c;
            ProductFeedback__c pf = new ProductFeedback__c();
            pf.RecordTypeId = psfRecordTypeId;
            pf.Case__c = c.Id;
            insert pf;
            Test.stopTest();

            Case testCase = [SELECT Id,SuppliedName,ContactId,AccountId,Account.Name,Contact.LastName,Status FROM Case WHERE Id=:c.Id LIMIT 1];
            List<FeedItem> chatFeed = [SELECT  Id, Body, CommentCount, CreatedDate, LikeCount, LinkUrl, ParentId, RelatedRecordId, Title, Type
			FROM FeedItem ];
			system.debug('chatFeed: '+chatFeed);
        }
    } 
	
}