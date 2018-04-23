/* +=====================================================================+    
 |                       Copyright (c) 2016 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : ChatTranscriptBatchBySkill.cls  
 Script Type         : Queueable Class 
 Description         : Class for producing WorkforceSegment__c record summary
                       records for XML aggregation and eventual upload to Nice
                       TotalView. This class is scheduled for execution within
 					   the ChatTranscriptBatch class.

 Change List:                                                               
 ------------                                                               

 Version    Date      Author            Description                          
 =======+============+=================+=================================
 1.0     2016-DEC-06  Paul Coleman      Created 
 2.0     2017-APR-06  Paul Coleman      Simplified for direct processing and 
 										potential asynchronous execution. 
 =======+============+=================+=================================*/
global without sharing class ChatTranscriptBatchBySkill implements Schedulable {

	global class DatabaseResults {
		List<WorkforceSegment__c> segments;
		List<Database.SaveResult> results;
		public DatabaseResults(List<WorkforceSegment__c> segList, List<Database.SaveResult> srList){
			this.segments = segList;
			this.results = srList;
		}
	}
    private class SkillSummary {
        public SkillSummary(String skill, String first, DateTime intervalStart){
            this.firstTranscript = first;
            this.skillText = skill;
            this.startTime = intervalStart;
        }
        Integer countOfChatTranscripts = 0;
        Integer countOfStatusCompleted = 0;
        Integer sumOfWaitTimes = 0;
        Integer sumOfChatDurations = 0;
        Integer sumOfCompleteChatDurations = 0;
        Integer countOfStatusMissed = 0;
        Integer countOfCompletedLess60 = 0;
        Integer countOfCompletedOver60 = 0;
        DateTime startTime = Datetime.now();
        DateTime endTime = Datetime.now();
        Integer totalTranscripts = 0;
        String firstTranscript = '';
        String lastTranscript = '';
        String skillText = '';
    }

    global ChatTranscriptBatchBySkill() {}    

    global void execute(SchedulableContext SC) {
    	ChatTranscriptBatchBySkill.createWorkforceSegmentRecords();
        //TO SCHEDULE EVERY 30 MINUTES, execute the following code as anaymous apex (excluding the initial '//'): 
        //System.schedule('Chat Stats by skill for Nice TotalView (Top of Hour)', '0 0 * ? * *', new ChatTranscriptBatchBySkill()); System.schedule('Chat Stats by skill for Nice TotalView (30th Minute)', '0 30 * ? * *', new ChatTranscriptBatchBySkill());
    }
    
    //declared as webservice for external testing and visualforce access
    webservice static Id testWorkforceSegmentRecords() {
    	List<Database.SaveResult> results = createWorkforceSegmentRecords().results;
    	return null==results||results.isEmpty()?null:results[0].getId();
    }
    
    global static ChatTranscriptBatchBySkill.DatabaseResults createWorkforceSegmentRecords() {
        Datetime lastJob = System.now().addMinutes(-30);     	
        Map<String,SkillSummary> sMap = new Map<String,SkillSummary>();
    	//gather summary data by skill
        for(List<LiveChatTranscript> transcripts : [SELECT Id,Name,Status,WaitTime,ChatDuration,CreatedDate,LastModifiedDate,Skill.MasterLabel FROM LiveChatTranscript WHERE CreatedDate>=:lastJob ORDER BY Name ASC LIMIT :Limits.getLimitQueryRows()]) {
	        for(LiveChatTranscript tr: transcripts) {
	            SkillSummary sk = (SkillSummary)sMap.get(tr.Skill.MasterLabel);
	            if(null==sk){sMap.put(tr.Skill.MasterLabel,new SkillSummary(tr.Skill.MasterLabel,tr.Name,System.now()));sk=sMap.get(tr.Skill.MasterLabel);}
	            sk.lastTranscript = tr.Name;
	            if(tr.LastModifiedDate>tr.CreatedDate){--sk.totalTranscripts;}else{
	                sk.totalTranscripts++;
	                sk.countOfChatTranscripts++;
	                String status = null==tr.Status?'':tr.Status.toLowerCase();
	                sk.countOfStatusCompleted += 'completed'.equals(status)? 1: 0;
	                sk.countOfStatusMissed += 'missed'.equals(status)? 1: 0;
	                sk.countOfCompletedLess60 += (null!=tr.WaitTime && 'completed'.equals(status) && tr.WaitTime<60)? 1: 0;
	                sk.countOfCompletedOver60 += (null!=tr.WaitTime && 'completed'.equals(status) && tr.WaitTime>=60)? 1: 0;
	                sk.sumOfWaitTimes += null==tr.WaitTime? 0: tr.WaitTime;
	                sk.sumOfChatDurations += null==tr.ChatDuration? 0: tr.ChatDuration;
	                sk.sumOfCompleteChatDurations += (null!=tr.ChatDuration && 'completed'.equals(status))? tr.ChatDuration: 0;
	            }
	        }
        }        
        return sMap.isEmpty()?new ChatTranscriptBatchBySkill.DatabaseResults(null, null):ChatTranscriptBatchBySkill.insertWorkforceRecords(sMap,lastJob);
    }
    
    private static ChatTranscriptBatchBySkill.DatabaseResults insertWorkforceRecords(Map<String,SkillSummary> skillsMap, Datetime lastMod) {
        Id transcriptRecordId = WorkforceSegment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Chat Transcript Segment').getRecordTypeId();
        List<WorkforceSegment__c> inserts = new List<WorkforceSegment__c>();
    	Id tackbot = [SELECT Id from User WHERE Alias = 'tackbot' LIMIT 1].Id;
	    String loginTimeAverage = '';
	    try{loginTimeAverage = String.valueOf(Integer.valueOf( (Decimal)[SELECT AVG(TimeInOnlineStatus) logintime FROM LiveAgentSession WHERE CreatedDate>=:lastMod][0].get('logintime') ));}catch(Exception ex){System.debug(LoggingLevel.ERROR,ex.getMessage());}
	    //create new WorkforceSegment__c records for insert
	    for(String skill: skillsMap.keySet()){
	        SkillSummary summary = skillsMap.get(skill);
	        System.debug(LoggingLevel.FINEST,JSON.serialize(summary));
	        Integer minit = summary.startTime.minute();
	        minit = 30>minit?0:30;
	        WorkforceSegment__c result = new WorkforceSegment__c(
	            RecordTypeId = transcriptRecordId,
	            OwnerId = tackbot,
	            Name = summary.startTime.format('yyyy-MM-dd HH:') + (0==minit?'00':'30'),
	            QueueNodeDateTime__c = summary.startTime.format('yyyyMMdd\'T\'HH')+ (0==minit?'00':'30'),
	            BeginningChatTranscriptNumber__c = summary.firstTranscript,
	            EndingChatTranscriptNumber__c = summary.lastTranscript,
	            QueueDataQueueValue__c = skill,
	            Date__c = summary.startTime.format('yyyyMMdd'),
	            Time__c = summary.startTime.format('HH') + (0==minit?'00':'30'),
	            QueueDataHandledTime__c = String.valueOf(Integer.valueOf(summary.sumOfCompleteChatDurations)),
	            QueueDataQueueDelayTime__c = String.valueOf(summary.sumOfWaitTimes),
	            QueueDataHandledShort__c = String.valueOf(summary.countOfCompletedLess60),
	            QueueDataHandledLong__c = String.valueOf(summary.countOfCompletedOver60),
	            QueueDataReceivedContacts__c = String.valueOf(summary.countOfChatTranscripts),
	            NumberOfContactsHandled__c = String.valueOf(summary.countOfStatusCompleted),
	            QueueDataAbandonedLong__c = String.valueOf(summary.countOfStatusMissed),
	            ASAx100__c = String.valueOf(0==summary.countOfChatTranscripts?0: Integer.valueOf(100*(Double.valueOf(summary.sumOfWaitTimes)/summary.countOfChatTranscripts))),
	            AHTx100__c = String.valueOf(0==summary.countOfChatTranscripts?0: Integer.valueOf(100*(Double.valueOf(summary.sumOfChatDurations)/summary.countOfChatTranscripts))),
	            ServiceLevelx100__c = String.valueOf(0==summary.countOfChatTranscripts?0: Integer.valueOf(100*(Double.valueOf(summary.countOfCompletedLess60)/summary.countOfChatTranscripts))),
	            InTime__c = String.valueOf(Integer.valueOf(summary.sumOfChatDurations)),
	            LoginTime__c = loginTimeAverage
	        );
	        System.debug(LoggingLevel.FINEST,'NEW WORKFORCE SEGMENT SUMMARY'+JSON.serialize(result));
	        inserts.add(result); //add stats record
	    }
	    return new ChatTranscriptBatchBySkill.DatabaseResults(inserts, Database.insert(inserts,false));
    }
    
}