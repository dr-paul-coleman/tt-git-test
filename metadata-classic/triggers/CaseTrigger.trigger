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
 Script File Name    : CaseTrigger.cls  
 Script Type         : Standard Apex Trigger Class 
 Description         : Trigger actions on Case records

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-07-03  Paul Coleman      Created 
 1.1     2015-08-12  Travis Oliver     Updated to include 'after update' events
 1.2     2015-09-07  Travis Oliver     Updated 'after insert' to add chat recordtype  
 1.3     2015-12-19  Paul Coleman      added CaseCommentQueue to 'after insert' event 
 1.4     2016-02-05  Kristin Hasna     Updated to include Social Media case origin
 1.5     2016-05-02  Kristin Hasna     Updated to include Suggestion Box and App Integration case origin
 1.6     2016-09-29  Paul Coleman      added 'before insert' event logic and flagEmailToCaseDupesAsNoise call 
 1.7     04-30-2017  Scott Purcell     Added miIncidentHandler to beforeInsert and beforeUpdate
1.8     04-30-2017  Scott Purcell      Added a check for a variable that stops the case trigger from recursively firing
 1.9     09-19-207   Kristin Hasna     Added in 'Dispute form' and 'Directly Question' case origins
 2.0     2017-09-30  Mendel Guillaume  Code refactoring
 =======+===========+=================+=================================*/
trigger CaseTrigger on Case (after insert, before insert, after update,before update)
{
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            CaseTriggerHandler.onBeforeInsert(Trigger.new);
        }
        else if(Trigger.isUpdate)
        {
            CaseTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
    else if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            CaseTriggerHandler.onAfterInsert(Trigger.newMap);
        }
        else if(Trigger.isUpdate)
        {
            CaseTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        } 
    }

    //Before Insert, if Case is from Email-to-Case, prevent dupes by flagging Case with Noise RT, dupe processing handled in CaseEmailTrigger
    /*if( Trigger.isBefore &&  Trigger.isInsert ) {
        //find any Triggered Customer Support Cases that are from Email-To-Case, ignore all others
        List<Case>miCases = new List<Case>();
        Id csRTId= Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        boolean targetsFound = false;
        for(Case c: Trigger.New)
        {
            if (c.RecordTypeId==csRTId && 'Email'.equals(c.Origin))
            {
                targetsFound = true;
            }
            if(c.MIDoNotRelateIncident__c == false)miCases.add(c);//do not relate incidents if this is checked.
        }
        if(targetsFound && CaseTriggerHandler.firstRun){
            //using the Case.SuppliedEmail field value, see if that contact already has an open case(s) & if so, set RT to Noise
             CaseTriggerHandler.flagEmailToCaseDupesAsNoise(Trigger.New);
        }
        CaseTriggerHandler.miIncidentHandler(miCases,Trigger.newMap,Trigger.newMap,Trigger.isUpdate);

    }*/

    //After Insert, if Contact isNull, try creating missing Contact(s) if any, 
    //also post the case description as a CaseComment for case feed visibility in service console publisher 
   /* if( Trigger.isAfter &&  Trigger.isInsert ) {
        List<String>caseIds = new List<String>();
        if( ![Select Id from Case WHERE Id IN :Trigger.New AND RecordType.Name IN ('Customer Support','Marketplace Integrity Restricted','Marketplace Integrity','Live Chat') AND Origin IN ('Email','Web','Live Chat','Social Media','Suggestion Box','Dispute form','Directly Question','App Integration')].isEmpty() ) {

            if( Limits.getQueueableJobs() == 0) { ID jobID = System.enqueueJob(new CaseTriggerHandler.CaseCommentQueue(Trigger.New)); }
            CaseTriggerHandler.createMissingContacts(Trigger.New);
        }
        
    }*/
    
    /*if(Trigger.isBefore && Trigger.isUpdate)
    {
        system.debug('casetriggerhandler.isbeforeupdate');
        List<Case>miCases = new List<Case>();
        
        List<Case> cases = new List<Case>();
        for(Case c:Trigger.new)
        {
            if(c.MIDoNotRelateIncident__c == false)miCases.add(c);
            if(c.BGCReportId__c != null && c.BackgroundCheck__c == null)cases.add(c);
        }
        if(cases.size()>0)CaseTriggerHandler.backgroundCheck(cases,Trigger.Old);
        if(CaseTriggerHandler.firstRun)
        {
            CaseTriggerHandler.miIncidentHandler(miCases,Trigger.newMap,Trigger.oldMap,Trigger.isUpdate);
            CaseTriggerHandler.isBeforeUpdate(Trigger.new,Trigger.old);
        }
        CaseTriggerHandler.firstRun = false;
        
    }*/
    
    //After Update, find closed triggered Cases that are eligible for CSAT Insert
    /*if( Trigger.isAfter &&  Trigger.isUpdate ) {

        List<Case> cases = [Select Id,CaseNumber,AccountId,ContactId,Category__c,SubCategory__c,Ownerid,(SELECT ID FROM SurveyResponses__r) FROM Case WHERE Id IN :Trigger.New and RecordType.Name IN ('Customer Support','Marketplace Integrity','Live Chat') AND CSATEligible__c='Eligible' AND isClosed=true];
        if( !cases.isEmpty() ) {
            CaseTriggerHandler.createCsat( cases );
        }
        
        
    }*/

    

}
//trigger CaseTrigger on Case (after insert, before insert, after update,before update) {

//    //Before Insert, if Case is from Email-to-Case, prevent dupes by flagging Case with Noise RT, dupe processing handled in CaseEmailTrigger
//    if( Trigger.isBefore &&  Trigger.isInsert ) {
//        //find any Triggered Customer Support Cases that are from Email-To-Case, ignore all others
//        Id csRTId= Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
//        boolean targetsFound = false;
//        for(Case c: Trigger.New)
//        {
            
//            if (c.RecordTypeId==csRTId && 'Email'.equals(c.Origin))
//            {
//                targetsFound = true;
//            }
            
//        }
//        if(targetsFound)
//        {
//            //using the Case.SuppliedEmail field value, see if that contact already has an open case(s) & if so, set RT to Noise
//            CaseTriggerHandler.flagEmailToCaseDupesAsNoise(Trigger.New);
//        }
//    }

//    //After Insert, if Contact isNull, try creating missing Contact(s) if any, 
//    //also post the case description as a CaseComment for case feed visibility in service console publisher 
//    if( Trigger.isAfter &&  Trigger.isInsert ) {
//        List<String>caseIds = new List<String>();
//        if( ![Select Id from Case WHERE Id IN :Trigger.New AND RecordType.Name IN ('Customer Support','Marketplace Integrity Restricted','Marketplace Integrity','Live Chat') AND Origin IN ('Email','Web','Dispute form', 'Directly Question','Live Chat','Social Media','Suggestion Box', 'App Integration')].isEmpty() ) {
//            System.enqueueJob( new CaseTriggerHandler.CaseCommentQueue(Trigger.New) );       
//            CaseTriggerHandler.createMissingContacts(Trigger.New);
//        }
        
//    }
//    if(Trigger.isBefore && Trigger.isUpdate)
//    {
       
//        List<Case> cases = new List<Case>();
//        for(Case c:Trigger.new)
//        {
//            if(c.BGCReportId__c != null && c.BackgroundCheck__c == null)cases.add(c);
//        }
//        if(cases.size()>0)CaseTriggerHandler.backgroundCheck(cases,Trigger.Old);
//    }
    
//    //After Update, find closed triggered Cases that are eligible for CSAT Insert
//    if( Trigger.isAfter &&  Trigger.isUpdate ) {

//        List<Case> cases = [Select Id,CaseNumber,AccountId,ContactId,Category__c,SubCategory__c,Ownerid,(SELECT ID FROM SurveyResponses__r) FROM Case WHERE Id IN :Trigger.New and RecordType.Name IN ('Customer Support','Marketplace Integrity','Live Chat') AND CSATEligible__c='Eligible' AND isClosed=true];
//        if( !cases.isEmpty() ) {
//            CaseTriggerHandler.createCsat( cases );
//        }
        
        
//    }
    

//}