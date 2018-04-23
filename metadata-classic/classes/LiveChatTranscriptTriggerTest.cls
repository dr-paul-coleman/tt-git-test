/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-09-29   Mendel Guillaume       Created
  1.1      2018-01-03   Mendel Guillaume  Updated to follow template/guidelines
  ========+============+=================+===============================================
*/

@IsTest
private class LiveChatTranscriptTriggerTest
{
	@TestSetup
	static void creatData()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Id MIRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
			Account a = new Account(Name = 'Chester Tester');
			insert a;
			Contact ct = new Contact(LastName = 'Tester', FirstName = 'Chester', AccountId = a.Id);
			insert ct;
			Case c = new Case(AccountId = a.Id, Status = 'New', ContactId = ct.Id, RecordTypeId = MIRTId);
			insert c;

			LiveChatVisitor lcv = new LiveChatVisitor();
			insert lcv;
		}
	}

	@IsTest
	static void testSetFirstThumbtackResponse()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
			LiveChatVisitor lcv = [SELECT Id FROM LiveChatVisitor];

			Test.startTest();

			LiveChatTranscript lct = new LiveChatTranscript(CaseId = c.Id, StartTime = Datetime.now().addMinutes(-10),
					EndTime = Datetime.now(), LiveChatVisitorId = lcv.Id);

			System.assertEquals(null, c.FirstThumbtackResponse__c, 'First response not null');

			insert lct;

			Test.stopTest();

			c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
			System.assertNotEquals(null, c.FirstThumbtackResponse__c, 'First response is null');
		}
	}

	@IsTest
	static void testFeedItemCreatedOnInsert()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
			LiveChatVisitor lcv = [SELECT Id FROM LiveChatVisitor];

			Test.startTest();

			LiveChatTranscript lct = new LiveChatTranscript(CaseId = c.Id, StartTime = Datetime.now().addMinutes(-10),
					EndTime = Datetime.now(), LiveChatVisitorId = lcv.Id, Body = 'Test', Status = 'Completed');
			insert lct;

			Test.stopTest();

			FeedItem fi = [SELECT Id, Body FROM FeedItem WHERE ParentId = :c.Id];
			System.assert(fi.Body.contains(lct.Body));
		}
	}

	@IsTest
	static void testFeedItemCreatedOnUpdate()
	{
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Case c = [SELECT Id, FirstThumbtackResponse__c FROM Case];
			LiveChatVisitor lcv = [SELECT Id FROM LiveChatVisitor];

			Test.startTest();

			LiveChatTranscript lct = new LiveChatTranscript(CaseId = c.Id, StartTime = Datetime.now().addMinutes(-10),
					EndTime = Datetime.now(), LiveChatVisitorId = lcv.Id, Body = 'Test');
			insert lct;

			System.assertEquals(0, [SELECT Id, Body FROM FeedItem WHERE ParentId = :c.Id].size());

			lct.Status = 'Completed';
			update lct;
			Test.stopTest();

			FeedItem fi = [SELECT Id, Body FROM FeedItem WHERE ParentId = :c.Id];
			System.assert(fi.Body.contains(lct.Body));
		}
	}
}