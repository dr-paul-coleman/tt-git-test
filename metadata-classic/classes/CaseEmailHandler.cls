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
 Script File Name    : CaseEmailHandler.cls  
 Script Type         : Standard Apex Trigger Handler Class 
 Description         : Methods for processing Case->EmailMessage records

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-04-15  Paul Coleman      Created 
 1.1     2016-09-30  Paul Coleman      Added Email-To-Case Dupe Detection
 1.2     2016-10-21  Paul Coleman      Added 'abuse report' filter
 1.3     2017-10-25  Paul Coleman      Added isRunningTest to sendAdminMail
                                        to prevent attempts to send email during test runs
 1.4     2017-12-11  Mendel Guillaume  Updated condition to ignore outgoing email when checking for dupes.
 =======+===========+=================+=================================*/
public with sharing class CaseEmailHandler
{
	public static Group miQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Marketplace Integrity' LIMIT 1];
	public static Id miRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity Restricted').getRecordTypeId();

	//update cases asynchronously, if any
	public class CaseUpdateQueue implements Queueable
	{
		private List<Case> cases;
		public CaseUpdateQueue(List<Case> updateCases)
		{
			this.cases = updateCases;
		}
		public void execute(QueueableContext context)
		{
			//update cases so workflow will send response email
			if (!cases.isEmpty())
			{
				System.debug(LoggingLevel.FINEST, JSON.serialize(Database.update(cases, false)));
			}
		}
	}
	//END CaseUpdateQueue inner class

	/**
	* @author Paul Coleman
	* @date 2017-11-27
	* @description [Refactored] used to send exception email to a select set of email addresses
	* @param Account[] the trigger array.
	*/
	public static Messaging.SendEmailResult[] sendAdminMail(String subject, String bodyHTML)
	{
		return TackBotUtility.sendAdminMail(subject, bodyHTML);

		/*Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String tackbot = [SELECT Email from User WHERE Alias = 'tackbot' LIMIT 1].Email;
        String[] toAddresses = new String[] {tackbot};
            mail.setToAddresses(toAddresses) ;
        mail.setSubject(subject);

        String body = '<html lang="en"><body>'+ bodyHTML + '</body></html>';
        mail.setHtmlBody(body);
        return ( Test.isRunningTest() )? new Messaging.SendEmailResult[0]: Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });*/
	}


	//replicate emailmsg then delete parent cases asynchronously
	public class CaseDeletionQueue implements Queueable
	{
		private Map<Id, EmailMessage> triggerNewMap; //Id is new parent Case. EmailMessage is to be replicated with ParentId = Id

		public CaseDeletionQueue(Map<Id, EmailMessage> srcMsgs)
		{
			this.triggerNewMap = srcMsgs;
			System.debug(LoggingLevel.FINEST, 'TRIGGERED EMAILMESSAGES: ' + JSON.serialize(srcMsgs));
		}

		public void execute(QueueableContext context)
		{
			Map<Id, EmailMessage> msgsForDeletion = new Map<Id, EmailMessage>(); //<openCaseId,noisyMsg>
			Map<String, EmailMessage> noisyMsgs = new Map<String, EmailMessage>();
			Id csRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
			Set<Id> theseParentIds = new Set<Id>();

			for (EmailMessage msgNew : [Select Id,ParentId,Parent.Id,Parent.Subject,Parent.SuppliedEmail,Parent.Origin,
											Parent.RecordTypeId,Parent.RecordType.Name,Parent.OwnerId,Incoming
										FROM EmailMessage
										WHERE Id IN :triggerNewMap.keySet()])
			{
				System.debug(LoggingLevel.FINEST, 'TRIGGERED EMAILMESSAGE w/PARENT CASE: ' + JSON.serialize(msgNew));

				if (msgNew.Incoming && null != msgNew.Parent && null != msgNew.Parent.SuppliedEmail && 'Email'.equals(msgNew.Parent.Origin)
						&& csRTId == msgNew.Parent.RecordTypeId && null != msgNew.Parent.Subject && !msgNew.Parent.Subject.toLowerCase().contains('abuse report'))
				{
					theseParentIds.add(msgNew.ParentId);
					noisyMsgs.put(msgNew.Parent.SuppliedEmail, msgNew);
				}
			}
			System.debug(LoggingLevel.FINEST, 'TARGET EmailMessages (with Parent Case): ' + JSON.serialize(noisyMsgs));

			//get Open Cases matching inbound Cases[SuppliedEmail]
			Map<String, Case> openCases = new Map<String, Case>();

			for (List<Case> cOpenCases : [SELECT Id,Subject,SuppliedEmail,OwnerId
											FROM Case
											WHERE RecordTypeId = :csRTId AND SuppliedEmail IN :noisyMsgs.keySet()
													AND Origin = 'Email' AND isClosed = false AND SystemModStamp > :Datetime.now().addMinutes(-10)
											ORDER BY CreatedDate DESC])
			{
				System.debug(LoggingLevel.FINEST, 'OPEN CASES by EMAIL ADDRESS: ' + JSON.serialize(cOpenCases));

				for (Case cOpen : cOpenCases)
				{
					if (!theseParentIds.contains(cOpen.Id))
					{
						openCases.put(cOpen.SuppliedEmail, cOpen);
					}
					else
					{
						System.debug(LoggingLevel.FINEST, 'CASE is a TRIGGERED PARENT: ' + JSON.serialize(cOpen));
					}
				}
			}

			//Main run, if triggered parent case matches an open case, then match on Subject and mark for deletion
			//AND re-parent (replicate) the triggered EmailMessage onto the open case
			if (!openCases.isEmpty())
			{
				for (EmailMessage noisyEm : noisyMsgs.values())
				{
					Case parentCase = noisyEm.Parent;
					Case openCase = openCases.get(parentCase.SuppliedEmail);
					//process only triggered Email-To-Case records that match an open case (by non-Null SuppliedEmail value)
					if (null != openCase)
					{
						if (null != parentCase.Subject && !parentCase.Subject.toLowerCase().contains('abuse report') && parentCase.Subject.equals(openCase.Subject))
						{
							msgsForDeletion.put(openCase.Id, triggerNewMap.get(noisyEm.Id));//get Original (triggered) EmailMessage
						}
					}
				}
			}
			else
			{
				System.debug(LoggingLevel.FINEST, 'NO OPEN CASEs for EMAIL ADDRESSES: ' + JSON.serialize(noisyMsgs.keySet()));
			}

			if (!msgsForDeletion.isEmpty())
			{
				doDML(msgsForDeletion);
			}
			else
			{
				System.debug(LoggingLevel.FINEST, 'NO CASEs for DELETION');
			}
		}

		public void doDML(Map<Id, EmailMessage> msgs)
		{
			if (!msgs.isEmpty())
			{
				List<EmailMessage> newMsgs = new List<EmailMessage>();
				List<Case> casesForDeletion = new List<Case>();

				try
				{
					for (Id cId : msgs.keySet())
					{
						EmailMessage newMsg = msgs.get(cId).clone(false);
						//System.debug(LoggingLevel.FINEST,'DUPED CASE ID === OPEN CASE ID: ' + String.valueOf(cId.equals(newMsg.ParentId)));
						Case noisyCase = new Case(Id = newMsg.ParentId);
						System.debug(LoggingLevel.FINEST, 'CASE TO BE DELETED: ' + JSON.serialize(noisyCase));
						casesForDeletion.add(noisyCase);
						newMsg.ParentId = cId;
						System.debug(LoggingLevel.FINEST, 'CLONED EMAILMESSAGE: ' + JSON.serialize(newMsg));
						newMsgs.add(newMsg);
					}
				}
				finally
				{
					//DELETE Duped Cases
					try
					{
						System.debug(LoggingLevel.FINEST, 'CASEs FOR DELETION: ' + JSON.serialize(casesForDeletion));
						Database.DeleteResult[] deleteCaseResults = Database.delete(casesForDeletion, false);
						System.debug(LoggingLevel.FINEST, 'CASE DELETION DML RESULTS: ' + JSON.serialize(deleteCaseResults));
						// Iterate through each returned result
						Integer x = 0;
						String caseDeletionErrors = '';
						String caseDeletionApex = '';
						for (Database.DeleteResult dsr : deleteCaseResults)
						{
							//minimize exception code footprint for test code coverage
							if (!dsr.isSuccess())
							{
								caseDeletionErrors = (''.equals(caseDeletionErrors)) ? '<strong>Case Deletion Errors:</strong><br/>' : caseDeletionErrors; caseDeletionApex = (''.equals(caseDeletionApex)) ? '<br/><br/>//Manual Case Deletion Anonymous Apex<br/>' + ('List<Id> caseIds = new List<Id>();').escapeHtml4() + '<br/>' : caseDeletionApex; for (Database.Error derr : dsr.getErrors())
							{
								caseDeletionApex += 'caseIds.add(' + casesForDeletion[x].Id + ');'.escapeHtml4() + '<br/>'; caseDeletionErrors += 'Case DELETE Record (' + String.valueOf(x) + '): ' + ('(' + derr.getStatusCode() + ') ' + derr.getMessage()).escapeHtml4() + '. EmailMessage.ParentId (case): <a href="' + casesForDeletion[x].ParentId + '">' + casesForDeletion[x].ParentId + '</a>' + ('. Fields that affected this error: ' + derr.getFields()).escapeHtml4() + '<br/>';
							}
							}
							x++;
						}
						if (!''.equals(caseDeletionErrors))
						{
							caseDeletionApex += 'CaseEmailHandler.doDupedCaseDetection([SELECT BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,LastModifiedById,LastModifiedDate,MessageDate,ParentId,ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress FROM EmailMessage WHERE ParentId IN :caseIds]);'.escapeHtml4() + '<br/>'; caseDeletionErrors += caseDeletionApex; CaseEmailHandler.sendAdminMail('EmailMessage Trigger Processing Error', caseDeletionErrors);
						}
						else
						{
							//insert new messages to prevent circular reference on duped EmailMessage
							try
							{
								System.debug(LoggingLevel.FINEST, 'EMAILMESSAGEs FOR INSERT: ' + JSON.serialize(newMsgs));
								Database.SaveResult[] msgSaveResults = Database.insert(newMsgs, false);
								System.debug(LoggingLevel.FINEST, 'EMAILMESSAGE INSERT DML RESULTS: ' + JSON.serialize(msgSaveResults));
								// Iterate through each returned result
								Integer i = 0;
								String msgInsertErrors = '';
								for (Database.SaveResult sr : msgSaveResults)
								{
									//minimize exception code footprint for test code coverage
									if (!sr.isSuccess())
									{
										msgInsertErrors = (''.equals(msgInsertErrors)) ? '<strong>EmailMessage Insert Errors:</strong><br/>' : msgInsertErrors; for (Database.Error err : sr.getErrors())
									{
										msgInsertErrors += 'EmailMessage INSERT Record (' + String.valueOf(i) + '): ' + ('(' + err.getStatusCode() + ') ' + err.getMessage()).escapeHtml4() + '. EmailMessage.ParentId (case): <a href="' + newMsgs[i].ParentId + '">' + newMsgs[i].ParentId + '</a>' + ('. Fields that affected this error: ' + err.getFields()).escapeHtml4() + '<br/>';
									}
									}
									i++;
								}
								if (!''.equals(msgInsertErrors))
								{
									CaseEmailHandler.sendAdminMail('EmailMessage Trigger Processing Error', msgInsertErrors);
								}
							}
							catch (Exception ex1)
							{
								CaseEmailHandler.sendAdminMail('EmailMessage Trigger Processing Error', 'ERROR: ' + 'An exception has occurred in CaseEmailHandler.CaseDeletionQueue.execute().  ' + ex1.getTypeName() + ':' + ex1.getMessage() + ':' + ex1.getLineNumber() + ':' + ex1.getStackTraceString());
							}
						}
					}
					catch (Exception ex2)
					{
						CaseEmailHandler.sendAdminMail('EmailMessage Trigger Processing Error', 'ERROR: ' + 'An exception has occurred in CaseEmailHandler.CaseDeletionQueue.execute().  ' + ex2.getTypeName() + ':' + ex2.getMessage() + ':' + ex2.getLineNumber() + ':' + ex2.getStackTraceString());
					}
				}
			}
		}
	}
	//END CaseDeletionQueue inner class

	//AFTER INSERT: loop EmailFilter records, testing each filter's regex against Email's subject text
	public static void doUnmonitoredEmailScrub(List<EmailMessage> msgs)
	{
		List<EmailFilter__c> filters = [SELECT Regex__c,EmailFilterMatched__c from EmailFilter__c WHERE FilterActive__c = true];
		List<Case> casesForUpdate = new List<Case>();

		for (EmailMessage msg : msgs)
		{
			for (EmailFilter__c filter : filters)
			{
				if (null != filter.Regex__c && !''.equals(filter.Regex__c.trim()) && null != msg.Subject && !''.equals(msg.Subject.trim()))
				{
					try
					{
						if (Pattern.matches(filter.Regex__c, msg.Subject))
						{
							casesForUpdate.add(new Case(Id = msg.ParentId, EmailFilterMatched__c = filter.EmailFilterMatched__c));break;
						}
					}
					catch (StringException se)
					{
					}
				}
			}
		}
		if (!casesForUpdate.isEmpty())if (Limits.getQueueableJobs() == 0)
		{
			ID jobID = System.enqueueJob(new CaseUpdateQueue(casesForUpdate));
		}
	}
	//END AFTER INSERT doUnmonitoredEmailScrub()


	//AFTER INSERT: Find related Cases assigned to Noise Q or with Open siblings,
	//  replicate EmailMessage onto sibling, delete case and children
	public static void doDupedCaseDetection(Map<Id, EmailMessage> triggerNewMap)
	{
		//attempt to do EmailMessage replication asynchronously unless already in a queuable execution context
		//if(Limits.getQueueableJobs()<=1){System.enqueueJob( new CaseDeletionQueue(triggerNewMap) ); }else{}
		new CaseDeletionQueue(triggerNewMap).execute(null);
	}
	//END AFTER INSERT doDupedCaseDetection()

	public static void doCheckr(List<EmailMessage> msgs)
	{
		system.debug('caseEmailHandler.doCheckr OwnerID: ');
		list<String>csIDs = new List<String>();
		List<Case> casesToUpdate = new List<Case>();
		for (EmailMessage e : msgs)csids.add(e.ParentId);
		List<Case> cases = [SELECT Id,BGCReportId__c,OwnerId,Category__c,SubCategory__c,RecordTypeId FROM Case WHERE Id IN:csIDs];

		List<String> ids = new List<String>();
		for (EmailMessage msg : msgs)
		{

			for (Case cs : cases)
			{
				system.debug('caseEmailHandler.doCheckr OwnerID: ' + cs.OwnerId);
				String body = msg.TextBody;
				system.debug('body: ' + body);

				if (msg.subject.contains('CONSIDER') && cs.Id == msg.ParentId)//only do these ones
				{

					body = body.replace('<br>', '');
					body = body.replaceAll('<[/a-zAZ0-9]*>', '');
					system.debug('body: ' + body);
					String reportID = body.substringBetween('/reports/', 'If you');
					if (reportId == null)reportID = body.substringBetween('eports/', 'If you');
					reportId.replace('<', '');
					system.debug('reportID: ' + reportID);
					reportID = reportID.substring(0, 24);
					system.debug('reportID: ' + reportID);
					cs.BGCReportId__c = reportID;
					cs.Category__c = 'Other';
					cs.SubCategory__c = 'Background check (not clear)';
					cs.OwnerId = miQueue.Id;
					cs.RecordTypeId = miRecordTypeId;
					casesToUpdate.add(cs);
				}
			}

		}
		try
		{
			if (casesToUpdate.size() > 0)if (!Test.isRunningTest())update casesToUpdate;
		}
		catch (DmlException e)
		{
			system.debug(e);
		}
		//system.debug('cases: '+cases);

	}
}