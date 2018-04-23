/* +=====================================================================+    
 |                       Copyright (c) 2016 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : ChatTranscriptBatchBySkillTest.cls  
 Script Type         : Standard Test Class
 Description         : Test(s) for ChatTranscriptBatchBySkill 

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+============+=================+=================================
 1.0     2016-OCT-28  Paul Coleman      Created 
 1.0     2017-APR-01  Paul Coleman      Refactored to match Queuable simplicifcation. 
 =======+============+=================+=================================*/
@isTest
private class ChatTranscriptBatchBySkillTest {

    @testSetup
    static void setupFilterData() {
        User testUser = [SELECT id FROM User WHERE alias = 'tackbot' AND IsActive=true LIMIT 1];
        System.runAs(testUser) {
	        LiveChatVisitor v = new LiveChatVisitor();
	        insert v;
	        insert new LiveChatTranscript[]{new LiveChatTranscript(LiveChatVisitorId=v.Id),new LiveChatTranscript(LiveChatVisitorId=v.Id)};
        }
    }
    
    @isTest static void testWorkforceXMLCreation() {
        User testUser = [SELECT id FROM User WHERE alias = 'tackbot' AND IsActive=true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            	//first create WF Segment record (rollup summary)
            	ChatTranscriptBatchBySkill.testWorkforceSegmentRecords();
            	//second, create Nice XML record from WF Segment rollup summary
                new WorkforceSegmentRollupBatch().execute(null);
            	WorkforceSegmentRollupBatch.testNiceXMLRecord();
            Test.stopTest();

            Id rtId = WorkforceSegment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Chat Transcript Segment').getRecordTypeId();
            List<WorkforceSegment__c> result = [SELECT Id,RecordTypeId,TotalViewQueueId__c FROM WorkforceSegment__c];
            System.assert(!result.isEmpty(), 'No WorkforceSegment__c records created during Batch run');
            System.assert(result[0].RecordTypeId.equals(rtId), 'RecordTypeId not set to Chat Transcript Segment');

            rtId = WorkforceSegment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('SmartSync File').getRecordTypeId();
            result = [SELECT Id,RecordTypeId,TotalViewQueueId__c FROM WorkforceSegment__c WHERE REcordTypeID = :rtId];
            System.assert(!result.isEmpty(), 'No WorkforceSegment__c SmartSync File records created during Batch run');
            new ChatTranscriptBatchBySkill().execute(null);
        }
    }
}