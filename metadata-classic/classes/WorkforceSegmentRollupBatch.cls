/* +=====================================================================+    
 |                       Copyright (c) 2016 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : WorkforceSegmentRollupBatch.cls  
 Script Type         : Batch Apex with Scheduler Class 
 Description         : Class for producing WorkforceSegment__c record summary
                       records, e.g., XML/CSV attachments, for upload to Nice
                       TotalView

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-12-06  Paul Coleman      Created 
 =======+===========+=================+=================================*/
global without sharing class WorkforceSegmentRollupBatch implements Schedulable {
	global class DatabaseResults {
		Id xmlid;
		Id attachmentid;
		public DatabaseResults(Id xId, Id aId){
			xmlid = xId;
			attachmentid = aId;
		}
	}
	
    private class SkillTime {
        public SkillTime(String skill, String timeStr){
            skillText = skill;
            timeString = timeStr;
        }
        String skillText;
        String timeString;
    }

    global WorkforceSegmentRollupBatch() {}
    
 	global void execute(SchedulableContext SC) {
	    	WorkforceSegmentRollupBatch.createNiceXMLRecord();
	        //TO SCHEDULE EVERY 24 hours at 11pm: 
	        //System.schedule('Workforce Segment Rollup for Nice TotalView (Daily)', '0 0 23 ? * *', new WorkforceSegmentRollupBatch());
	    }
    
    //declared as webservice for external testing and visualforce access
    webservice static Id testNiceXMLRecord() {
       return createNiceXMLRecord().xmlid;
    }
    global static WorkforceSegmentRollupBatch.DatabaseResults createNiceXMLRecord() {
    	Attachment attachmnt;
    	WorkforceSegment__c wfParent;
        Id trRTId = WorkforceSegment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Chat Transcript Segment').getRecordTypeId();
        Id smRTId = WorkforceSegment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('SmartSync File').getRecordTypeId();
        
        //get last inserted Smart Sync XML record
        Datetime lastMod = [SELECT Id FROM WorkforceSegment__c WHERE RecordTypeId=:smRTId LIMIT 1].isEmpty()? System.now().addDAYS(-24) : (Datetime)[SELECT max(CreatedDate) lastMod FROM WorkforceSegment__c WHERE RecordTypeId=:smRTId][0].get('lastMod');    
        Integer totalRecs = [SELECT count() FROM WorkforceSegment__c WHERE RecordTypeId=:trRTId AND CreatedDate>:lastMod];
        
        if(0!=totalRecs){ 
	        //Load WFSegments into a List (vs For each loop), because the records must be looped twice below. 
	        //See PHASE 1 and PHASE 2 comments
	        List<WorkforceSegment__c> segments = (0==totalRecs)?new WorkforceSegment__c[0]:[SELECT Id,Name,BacklogNotYetExpired__c,QueueDataQueueDelayTime__c,QueueDataHandledTime__c,NumberofContactsReceived__c,QueueNodeDateTime__c,BeginningChatTranscriptNumber__c,EndingChatTranscriptNumber__c,QueueDataQueueValue__c,Date__c,Time__c,QueueDataHandledShort__c,QueueDataHandledLong__c,QueueDataReceivedContacts__c,NumberOfContactsHandled__c,QueueDataAbandonedLong__c,ASAx100__c,AHTx100__c,ServiceLevelx100__c,InTime__c,LoginTime__c FROM WorkforceSegment__c WHERE RecordTypeId=:trRTId AND CreatedDate>:lastMod ORDER BY Name ASC];

	        //gather skills by timestamp from WF records, PHASE 1 WFSegment loop
	        Map<SkillTime,List<WorkforceSegment__c>> skillTimes = new Map<SkillTime,List<WorkforceSegment__c>>();
	        for(WorkforceSegment__c s: segments) {
	            SkillTime st = new SkillTime(s.QueueDataQueueValue__c,s.QueueNodeDateTime__c);
	            List<WorkforceSegment__c> wflist = null==skillTimes.get(st)?new List<WorkforceSegment__c>():skillTimes.get(st);
	            wflist.add(s);
	            skillTimes.put(st,wflist);
	        }
	        
	        //aggregate stats for each batch of transcripts
	        XmlStreamWriter niceXML = new XmlStreamWriter();
	        niceXML.writeStartDocument('UTF-8', '1.0');
	        try {
	            /* EXAMPLE XML
	            <HistPlugin>
	            <DataSourceNode>
	            <Vendor></Vendor>
	            <QueueNode>
	                <TimePeriod><DateTime>20140102T0900</DateTime></TimePeriod>
	                <QueueData>
	                    <QueueValue>45</QueueValue> <!-- Workload CT -->
	                    <ContactsReceived><count>99</count></ContactsReceived>
	                    <AbandonedShort><count>5</count></AbandonedShort>
	                    <AbandonedLong><count>2</count></AbandonedLong>
	                    <HandledShort><count>6</count></HandledShort>
	                    <HandledLong><count>3</count></HandledLong>
	                    <HandleTime><duration><totalseconds>200</totalseconds></duration></HandleTime>
	                    <HoldTime><duration><totalseconds>50</totalseconds></duration></HoldTime>
	                    <WorkTime><duration><totalseconds>100</totalseconds></duration></WorkTime>
	                    <QueueDelayTime><duration><totalseconds>125</totalseconds></duration></QueueDelayTime>
	                    <SvcLvlPct><percentage>99.99</percentage></SvcLvlPct>
	                    <BackLogExpired><count>2</count></BackLogExpired>
	                    <BackLogNotExpired><count>3</count></BackLogNotExpired>
	                </QueueData>
	            </QueueNode>
	            </DataSourceNode>
	            <DataSourceNode>
	                <Vendor></Vendor>
	                <AgentQueueNode>
	                    <TimePeriod><DateTime>20140102T0900</DateTime></TimePeriod>
	                </AgentQueueNode>
	            </DataSourceNode>
	            <DataSourceNode>
	                <Vendor></Vendor>
	                <AgentSystemNode>
	                     <TimePeriod><DateTime>20140102T0900</DateTime></TimePeriod>
	                </AgentSystemNode>
	            </DataSourceNode>
	            </HistPlugin>
	            */
	
	            niceXML.writeStartElement(null, 'HistPlugin', null);
	                //Loop Skills by timeStamp -> lists of segment records
	                for(SkillTime stime: skillTimes.keyset()) {
	                    niceXML.writeStartElement(null, 'DataSourceNode', null);
	                    niceXML.writeStartElement(null, 'Vendor', null);
	                        niceXML.writeCharacters('Salesforce');
	                    niceXML.writeEndElement(); //end Vendor
	                    
	                        niceXML.writeStartElement(null, 'QueueNode', null);
	                        niceXML.writeStartElement(null, 'TimePeriod', null);
	                        niceXML.writeStartElement(null, 'DateTime', null);
	                            niceXML.writeCharacters(stime.timeString);
	                        niceXML.writeEndElement(); //end DateTime
	                        niceXML.writeEndElement(); //end TimePeriod
	                        
	                        //loop wf segments AGAIN for XML segment details, PHASE 2 WFSegment oop
	                        List<WorkforceSegment__c> skillSegments = null==skillTimes.get(stime)?new List<SObject>():skillTimes.get(stime);
	                        for(WorkforceSegment__c sg: skillSegments) {
	                            
	                            niceXML.writeStartElement(null, 'QueueData', null);
	                                
	                                //<QueueValue>45</QueueValue>
	                                niceXML.writeStartElement(null, 'QueueValue', null);
	                                    niceXML.writeCharacters(null==sg.QueueDataQueueValue__c?'':sg.QueueDataQueueValue__c);
	                                niceXML.writeEndElement(); //end QueueValue
	                            
	                                //<ContactsReceived><count>99</count></ContactsReceived>
	                                niceXML.writeStartElement(null, 'ContactsReceived', null);
	                                    niceXML.writeStartElement(null, 'count', null);
	                                        niceXML.writeCharacters(null==sg.NumberofContactsReceived__c?'':sg.NumberofContactsReceived__c);
	                                    niceXML.writeEndElement(); //end count
	                                niceXML.writeEndElement(); //end ContactsReceived
	                                
	                                //unused Element as of 13-DEC-2016
	                                // <AbandonedShort><count>5</count></AbandonedShort>
	                                // niceXML.writeStartElement(null, 'AbandonedShort', null);
	                                //     niceXML.writeStartElement(null, 'count', null);
	                                //         // niceXML.writeCharacters(sg.);
	                                //     niceXML.writeEndElement(); //end count
	                                // niceXML.writeEndElement(); //end AbandonedShort
	            
	                                //<AbandonedLong><count>2</count></AbandonedLong>
	                                niceXML.writeStartElement(null, 'AbandonedLong', null);
	                                    niceXML.writeStartElement(null, 'count', null);
	                                        niceXML.writeCharacters(null==sg.QueueDataAbandonedLong__c?'':sg.QueueDataAbandonedLong__c);
	                                    niceXML.writeEndElement(); //end count
	                                niceXML.writeEndElement(); //end AbandonedLong
	            
	                                //<HandledShort><count>6</count></HandledShort>
	                                niceXML.writeStartElement(null, 'HandledShort', null);
	                                    niceXML.writeStartElement(null, 'count', null);
	                                        niceXML.writeCharacters(null==sg.QueueDataHandledShort__c?'':sg.QueueDataHandledShort__c);
	                                    niceXML.writeEndElement(); //end count
	                                niceXML.writeEndElement(); //end HandledShort
	            
	                                //<HandledLong><count>3</count></HandledLong>
	                                niceXML.writeStartElement(null, 'HandledLong', null);
	                                    niceXML.writeStartElement(null, 'count', null);
	                                        niceXML.writeCharacters(null==sg.QueueDataHandledLong__c?'':sg.QueueDataHandledLong__c);
	                                    niceXML.writeEndElement(); //end count
	                                niceXML.writeEndElement(); //end HandledLong
	            
	                                //<HandleTime><duration><totalseconds>200</totalseconds></duration></HandleTime>
	                                niceXML.writeStartElement(null, 'HandleTime', null);
	                                    niceXML.writeStartElement(null, 'duration', null);
	                                        niceXML.writeStartElement(null, 'totalseconds', null);
	                                            niceXML.writeCharacters(null==sg.QueueDataHandledTime__c?'':sg.QueueDataHandledTime__c);
	                                        niceXML.writeEndElement(); //end totalseconds
	                                    niceXML.writeEndElement(); //end duration
	                                niceXML.writeEndElement(); //end HandleTime
	            
	                                //<HoldTime><duration><totalseconds>50</totalseconds></duration></HoldTime>
	                                niceXML.writeStartElement(null, 'HoldTime', null);
	                                    niceXML.writeStartElement(null, 'duration', null);
	                                        niceXML.writeStartElement(null, 'totalseconds', null);
	                                            // niceXML.writeCharacters(sg.);
	                                        niceXML.writeEndElement(); //end totalseconds
	                                    niceXML.writeEndElement(); //end duration
	                                niceXML.writeEndElement(); //end HoldTime
	            
	                                //<WorkTime><duration><totalseconds>100</totalseconds></duration></WorkTime>
	                                // niceXML.writeStartElement(null, 'WorkTime', null);
	                                //     niceXML.writeStartElement(null, 'duration', null);
	                                //         niceXML.writeStartElement(null, 'totalseconds', null);
	                                //             niceXML.writeCharacters(null==sg.WorkTime__c?'':sg.WorkTime__c);
	                                //         niceXML.writeEndElement(); //end totalseconds
	                                //     niceXML.writeEndElement(); //end duration
	                                // niceXML.writeEndElement(); //end WorkTime
	            
	                                //<QueueDelayTime><duration><totalseconds>125</totalseconds></duration></QueueDelayTime>
	                                niceXML.writeStartElement(null, 'QueueDelayTime', null);
	                                    niceXML.writeStartElement(null, 'duration', null);
	                                        niceXML.writeStartElement(null, 'totalseconds', null);
	                                            niceXML.writeCharacters(null==sg.QueueDataQueueDelayTime__c?'':sg.QueueDataQueueDelayTime__c);
	                                        niceXML.writeEndElement(); //end totalseconds
	                                    niceXML.writeEndElement(); //end duration
	                                niceXML.writeEndElement(); //end QueueDelayTime
	            
	                                //<SvcLvlPct><percentage>99.99</percentage></SvcLvlPct>
	                                niceXML.writeStartElement(null, 'SvcLvlPct', null);
	                                    niceXML.writeStartElement(null, 'percentage', null);
	                                        // niceXML.writeCharacters(sg.);
	                                    niceXML.writeEndElement(); //end percentage
	                                niceXML.writeEndElement(); //end SvcLvlPct
	            
	                                //<BackLogExpired><count>2</count></BackLogExpired>
	                                // niceXML.writeStartElement(null, 'BackLogExpired', null);
	                                //     niceXML.writeStartElement(null, 'count', null);
	                                //         niceXML.writeCharacters(null==sg.BacklogExpired__c?'':sg.BacklogExpired__c);
	                                //     niceXML.writeEndElement(); //end count
	                                // niceXML.writeEndElement(); //end BackLogExpired
	            
	                                //<BackLogNotExpired><count>3</count></BackLogNotExpired>
	                                niceXML.writeStartElement(null, 'BackLogNotExpired', null);
	                                    niceXML.writeStartElement(null, 'count', null);
	                                        niceXML.writeCharacters(null==sg.BacklogNotYetExpired__c?'':sg.BacklogNotYetExpired__c);
	                                    niceXML.writeEndElement(); //end count
	                                niceXML.writeEndElement(); //end BackLogNotExpired
	                            
	                            niceXML.writeEndElement(); //end QueueData
	                        }
	                        niceXML.writeEndElement(); //end QueueNode
	                    
	                    niceXML.writeEndElement(); //end DataSourceNode
	        
	                    niceXML.writeStartElement(null, 'DataSourceNode', null);
	                    niceXML.writeStartElement(null, 'Vendor', null);
	                        niceXML.writeCharacters('Salesforce');
	                    niceXML.writeEndElement(); //end Vendor
	                    niceXML.writeStartElement(null, 'AgentQueueNode', null);
	                    niceXML.writeStartElement(null, 'TimePeriod', null);
	                    niceXML.writeStartElement(null, 'DateTime', null);
	                        niceXML.writeCharacters(stime.timeString);
	                    niceXML.writeEndElement(); //end DateTime
	                    niceXML.writeEndElement(); //end TimePeriod
	                    niceXML.writeEndElement(); //end AgentQueueNode
	                    niceXML.writeEndElement(); //end DataSourceNode
	        
	                    niceXML.writeStartElement(null, 'DataSourceNode', null);
	                    niceXML.writeStartElement(null, 'Vendor', null);
	                        niceXML.writeCharacters('Salesforce');
	                    niceXML.writeEndElement(); //end Vendor
	                    niceXML.writeStartElement(null, 'AgentSystemNode', null);
	                    niceXML.writeStartElement(null, 'TimePeriod', null);
	                    niceXML.writeStartElement(null, 'DateTime', null);
	                        niceXML.writeCharacters(stime.timeString);
	                    niceXML.writeEndElement(); //end DateTime
	                    niceXML.writeEndElement(); //end TimePeriod
	                    niceXML.writeEndElement(); //end AgentSystemNode
	                    niceXML.writeEndElement(); //end DataSourceNode
	            
	                } //end skillTime map loop for Skills-based QueueNode elements
	              niceXML.writeEndElement(); //end HistPlugin
	            
	            niceXML.writeEndDocument();
	            
	            Id tackbot = [SELECT Id from User WHERE Alias = 'tackbot' LIMIT 1].Id;
	            DateTime now = System.now();
	            Integer minit = now.minute();
	            minit = 30>minit?0:30;
	            wfParent = new WorkforceSegment__c(
	                RecordTypeId = smRTId,
	                OwnerId = tackbot,
	                Name = 'SmartSync_' + now.format('yyyy MM dd HH').replace(' ','_') +'_'+(0==minit?'00':'30') + '.xml'
	            );
	            insert wfParent;
	            //write attachment with XML
	            attachmnt = new Attachment(ParentId=wfParent.Id,Name= (now.format('MMddyy HH').replace(' ','.')+(0==minit?'00':'30') + '.xml') ,Body=Blob.valueOf(niceXML.getXmlString()),ContentType='text/xml');
	            insert attachmnt;
	            
	        } finally {
	            niceXML.close();
	        }
        }
        return null==wfParent?new DatabaseResults(null,null):new DatabaseResults(wfParent.Id,attachmnt.Id);
    }
}