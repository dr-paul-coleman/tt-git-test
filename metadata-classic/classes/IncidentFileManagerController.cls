/**
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0                                     Created
   1.1      2018-02-02   Mendel Guillaume  Added support for Salesforce files
   ========+============+=================+===============================================
*/
public class IncidentFileManagerController
{
	@AuraEnabled
	public static String getSessionId()
	{
		return UserInfo.getSessionId();
	}

	@AuraEnabled
	public static List<IncidentFileManagerController.FileWrapper> getAllAttachments(Id incidentId)
	{
		List<IncidentFileManagerController.FileWrapper> allFiles = new List<IncidentFileManagerController.FileWrapper>();
		List<Attachment> result = new List<Attachment>();

		if (incidentId != null)
		{
			Set<Id> parentIds = new Set<Id> {incidentId};
			parentIds.addAll(MIUtility.getCaseIds(incidentId, null));
			
			if (!parentIds.isEmpty())
			{

				Map<Id, EmailMessage> emailMap = new Map<Id, EmailMessage>([Select Id From EmailMessage Where ParentId IN :parentIds And Incoming = true]);
				parentIds.addAll(emailMap.keySet());

				//Get Incident Actions
				Map<Id, MIIncidentAction__c> actionMap = new Map<Id, MIIncidentAction__c>([SELECT Id FROM MIIncidentAction__c WHERE MIIncident__c IN :parentIds]);
				parentIds.addAll(actionMap.keySet());

				//Docusign Attachments
				Map<Id, dsfs__DocuSign_Status__c> docs = new Map<Id, dsfs__DocuSign_Status__c>([SELECT Id FROM dsfs__DocuSign_Status__c WHERE MIIncident__c = :incidentId]);
				parentIds.addAll(docs.keySet());

				//Dispute Ids
				Map<Id, Dispute__c> disputes = new Map<Id, Dispute__c>([SELECT Id FROM Dispute__c WHERE MIIncident__c = :incidentId]);
				parentIds.addAll(disputes.keySet());

				//Dispute Message Ids
				Map<Id, DisputeMessage__c> disputeMessages = new Map<Id, DisputeMessage__c>([SELECT Id FROM DisputeMessage__c WHERE DisputeOffer__r.Dispute__r.MIIncident__c = :incidentId]);
				parentIds.addAll(disputeMessages.keySet());

				//Get SalesforceFiles
				List<ContentDocumentLink> cdls = [
						SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title,
								ContentDocument.LatestPublishedVersion.CreatedDate, ContentDocumentId
						FROM ContentDocumentLink
						WHERE LinkedEntityId IN :parentIds
				];

				//Get attachments
				result = [Select Id, Name, CreatedDate From Attachment Where ParentId IN :parentIds order by Name];

				for(ContentDocumentLink cdl : cdls)
				{
					allFiles.add(new FileWrapper(cdl));
				}

				for(Attachment a : result)
				{
					allFiles.add(new FileWrapper(a));
				}

				allFiles.sort();
			}

		}
		return allFiles;

	}

	@AuraEnabled
	public static void renameFile(Id attachmentId, String name)
	{
		AttachmentTriggerHandler.publishAttachmentEvent = false;

		if (attachmentId != null && String.isNotBlank(name))
		{
			update new Attachment(Id = attachmentId, Name = name);
		}
	}

	@AuraEnabled
	public static void deleteFile(Id attachmentId) {

		AttachmentTriggerHandler.publishAttachmentEvent = false;
		delete new Attachment (Id = attachmentId);

	}

	@AuraEnabled
	public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {

		AttachmentTriggerHandler.publishAttachmentEvent = false;
		base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
		
		Attachment a = new Attachment();
		a.parentId = parentId;
		a.Body = EncodingUtil.base64Decode(base64Data);
		a.Name = fileName;
		a.ContentType = contentType;
		
		insert a;
		
		return a.Id;
		
	}

	@AuraEnabled
	public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {

		if (String.isBlank(fileId)) {

			fileId = saveTheFile(parentId, fileName, base64Data, contentType);

		} else {

			appendToFile(fileId, base64Data);

		}
		return Id.valueOf(fileId);

	}
	
	private static void appendToFile(Id fileId, String base64Data) {

		AttachmentTriggerHandler.publishAttachmentEvent = false;
		base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
		
		Attachment a = [SELECT Id, Body FROM Attachment WHERE Id = :fileId];
		
		String existingBody = EncodingUtil.base64Encode(a.Body);
		a.Body = EncodingUtil.base64Decode(existingBody + base64Data); 
		update a;

	}

	public class FileWrapper implements LightningInnerClass, Comparable
	{
		@AuraEnabled
		public Id fileId{get;set;}
		@AuraEnabled
		public String name{get;set;}
		@AuraEnabled
		public Datetime createdDate{get;set;}
		@AuraEnabled
		public Id contentDocumentId{get;set;}

		public FileWrapper(Attachment attachment)
		{
			this.fileId = attachment.Id;
			this.name = attachment.Name;
			this.createdDate = attachment.CreatedDate;
		}

		/*public FileWrapper(ContentVersion cv)
		{
			this.fileId = cv.Id;
			this.name = cv.Title;
			this.createdDate = cv.CreatedDate;
			this.contentDocumentId = cv.ContentDocumentId;
		}*/

		public FileWrapper(ContentDocumentLink cdl)
		{
			this.fileId = cdl.ContentDocument.LatestPublishedVersionId;
			this.name = cdl.ContentDocument.LatestPublishedVersion.Title;
			this.createdDate = cdl.ContentDocument.LatestPublishedVersion.CreatedDate;
			this.contentDocumentId = cdl.ContentDocumentId;
		}

		public Integer compareTo(Object obj)
		{
			FileWrapper fw = (FileWrapper)obj;

			if(this.createdDate == fw.createdDate)
			{
				return 0;
			}
			else if(this.createdDate > fw.createdDate)
			{
				return 1;
			}
			else
			{
				return -1;
			}
		}
	}

}