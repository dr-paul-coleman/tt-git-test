/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2018-02-05   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

@IsTest
private class ContentVersionTriggerHandlerTest
{
	@IsTest
	static void testAttachmentEventRaised()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			ContentVersion cv = new ContentVersion(Title = 'Test Content', PathOnClient = 'test.txt', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);

			Test.startTest();

			insert cv;
			System.assert(ContentVersionTriggerHandler.attachmentEventSaveResults != null);

			ContentVersionTriggerHandler.attachmentEventSaveResults = null;
			cv.Title = 'Test Content Test';
			update cv;

			Test.stopTest();

			System.assert(ContentVersionTriggerHandler.attachmentEventSaveResults != null);
		}
	}
}