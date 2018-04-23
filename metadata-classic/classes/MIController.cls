/* +=====================================================================+    
 |                       Copyright (c) 2015 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : MIController.cls  
 Script Type         : Standard Apex Controller Class 
 Description         : Static MIIncident__c Utility methods for Service Console
                       Visualforce Components

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-08-03  Paul Coleman      Created 
 1.1     2017-09-05  Scott Purcell     Removed reference to OriginalCase__c
 =======+===========+=================+=================================*/
 global with sharing class MIController {
    public MIController(ApexPages.StandardController stdController) {}

    /* Get Attachments by MIIncident__c.Id
    */
    @RemoteAction
    global static String getAttachmentsByMIId(Id MIIncidentId) {
        List<Attachment> all = new List<Attachment>();
        List<MIFile__c> actualMiFiles = new List<MIFile__c>();
        Set<Id> miFilesForDeletion = new Set<Id>();
        List<Case> cases = new List<Case>();
        List<EmailMessage> emails = new List<EmailMessage>();
        List<MIIncident__c> miRecs = [SELECT Id,(SELECT Id from Cases__r),(Select Id from Attachments) FROM MIIncident__c WHERE Id = :MIIncidentId LIMIT 1];
        Set<Id> replicatedAttachmentIds = new Set<Id>();
        if( !miRecs.isEmpty() ) {
            MIIncident__c mi = miRecs[0];
            List<MIFile__c> currentFiles = [SELECT Id,Name,OwnerId,NewAttachmentId__c,AttachmentParentId__c,AttachmentId__c,MIIncident__c FROM MIFile__c WHERE MIIncident__c = :mi.Id];
            Set<Id> miAttachmentIds = new Set<Id>();
            for(Attachment mia: mi.Attachments) {
                miAttachmentIds.add(mia.Id);
            }
            //collect attachment ids already replicated up to MI Incident, making sure the new attachment id still exists
            for( MIFile__c mf: currentFiles ){
                if( miAttachmentIds.contains(mf.NewAttachmentId__c) ) {
                    replicatedAttachmentIds.add(mf.AttachmentId__c);
                    actualMiFiles.add(mf);
                } else {
                    miFilesForDeletion.add(mf.Id);
                }
            }
            //get related case attachments, if any
            for(Attachment ac: [SELECT Id,Name,ParentId,Description,CreatedDate,CreatedById,CreatedBy.Name,ContentType,BodyLength FROM Attachment WHERE ParentId IN :mi.Cases__r]) {
                if(!replicatedAttachmentIds.contains(ac.Id)) {
                    all.add(ac);
                }
            }
            //get related case emailmessage attachments, if any
            for(Attachment ae: [SELECT Id,Name,ParentId,Description,CreatedDate,CreatedById,CreatedBy.Name,ContentType,BodyLength FROM Attachment WHERE ParentId IN (SELECT Id FROM EmailMessage WHERE ParentId IN :mi.Cases__r)]) {
                if(!replicatedAttachmentIds.contains(ae.Id)) {
                    all.add(ae);
                }
            }
            // OriginalCase__c attachments not included in this version, per Travis Oliver Aug 25th, 2015
            //if( mi.OriginalCase__c != null ) {
            //  //get original case attachments, if any
            //  for(Attachment ao: [SELECT Id,Name,ParentId,Description,CreatedDate,CreatedById,CreatedBy.Name,ContentType,BodyLength FROM Attachment WHERE ParentId = :mi.OriginalCase__c]) {
            //      if(!replicatedAttachmentIds.contains(ao.Id)) {
            //          all.add(ao);
            //      }
            //  }
            //  //get original case email attachments, if any
            //  for(Attachment aoe: [SELECT Id,Name,ParentId,Description,CreatedDate,CreatedById,CreatedBy.Name,ContentType,BodyLength FROM Attachment WHERE ParentId IN (SELECT Id FROM EmailMessage WHERE ParentId = :mi.OriginalCase__c)]) {
            //      if(!replicatedAttachmentIds.contains(aoe.Id)) {
            //          all.add(aoe);
            //      }
            //  }
            //}
        
            delete [SELECT Id from MIFile__c WHERE Id IN :miFilesForDeletion];

            //get CaseNumbers and Email From info of related parent records for display
            String emailPrefix=EmailMessage.SObjectType.getDescribe().getKeyPrefix();
            String casePrefix=Case.SObjectType.getDescribe().getKeyPrefix();
            Set<Id> caseids = new Set<Id>();
            Set<Id> emailids = new Set<Id>();
            for(Attachment a: all) {
                String parentId = a.ParentId;
                if( parentId.startsWith(casePrefix) ) { //case record
                    caseids.add(parentId);
                } else if ( parentId.startsWith(emailPrefix) ) {
                    emailids.add(parentId);
                }
            }
            cases = [Select Id,CaseNumber,Subject,RecordTypeId,RecordType.Id,RecordType.Name FROM Case WHERE Id IN :caseids];
            emails = [Select Id,Subject,Parent.CaseNumber,Parent.Subject,Parent.RecordTypeId,Parent.RecordType.Id,Parent.RecordType.Name,FromAddress,FromName FROM EmailMessage WHERE Id IN :emailids];
        }
        //serialize all results
        return '{"Attachments":'+ JSON.serialize(all) + ',"MIFiles":'+ JSON.serialize(actualMiFiles) + ',"Cases":'+ JSON.serialize(cases) + ',"Emails":'+ JSON.serialize(emails) + '}';
    }



    @RemoteAction
    global static MIFile__c replicateAttachment(Id attachmentId, Id miIncidentId) {
        MIFile__c mif;
        List<Attachment> oldAs = [Select Id,Name,ContentType,Body,ParentId from Attachment where Id = :attachmentId LIMIT 1];
        if( !oldAs.isEmpty() ) {
            Attachment oldA = oldAs[0];
            Attachment newA = new Attachment(ParentId=miIncidentId,Name=oldA.Name,ContentType=oldA.ContentType,Body=oldA.Body);
            insert newA;
            mif = new MIFile__c(MIIncident__c=miIncidentId,Name=oldA.Name,NewAttachmentId__c=newA.Id,AttachmentParentId__c=oldA.ParentId,AttachmentId__c=oldA.Id);
            insert mif;
        }
        return mif;
    }    

}