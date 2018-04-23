/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       09/30/17      mguillame          Created
1.1       02/15/18      mguillame          Added Confidential RT variable
1.2       03/19/18      khasna             Added 'Solution Center' case origin for feed item
========+============+=================+===============================================*/

public with sharing class CaseHelper
{
  public static final Id MARKETPLACE_INTEGRITY_RESTRICTED_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity Restricted').getRecordTypeId();
  public static final Id MARKETPLACE_INTEGRITY_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
  public static final Id CUSTOMER_SUPPORT_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
  public static final Id LIVE_CHAT_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Live Chat').getRecordTypeId();
  public static final Id CONFIDENTIAL_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Confidential').getRecordTypeId();

  public class CaseCommentQueue implements Queueable
  {
    private List<Case> cases;
    public CaseCommentQueue(List<Case> newCases)
    {
      this.cases = newCases;
    }

    public void execute(QueueableContext context)
    {
      try
      {

        List<SObject> comments = new List<SObject>();
        //Id cRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();
        for(Case cse: this.cases)
        {
          String orgn = (null==cse.Origin)?'':cse.Origin.toLowerCase();
          if(('web'==orgn||'live chat'==orgn||'solution center'==orgn))
          {
            String ccbody='Case submitted from the Help Center by '+cse.SuppliedName+' who can be contacted at '+cse.SuppliedEmail+'\r\nSupplied User Id: '+cse.SuppliedThumbtackID__c+'\r\n\r\nSubject:  '+cse.Subject+'\r\n\r\nDetails:\r\n'+cse.Description+'\r\n\r\nHelp Center Visit Info:\r\n'+cse.HelpCenterVisitTopic__c+' > ' +cse.HelpCenterVisitSubTopic__c+ ' > '+(null==cse.HelpCenterVisitLastArticle__c||''.equals(cse.HelpCenterVisitLastArticle__c.trim())?'--No Article--':cse.HelpCenterVisitLastArticle__c);
            comments.add(new CaseComment(ParentId=cse.Id,CommentBody=ccbody));
          }
        }
        if(!comments.isEmpty())
        {
          comments.sort();
          Database.insert(comments,false);
        }
      }
      catch(DmlException e)
      {
        system.debug(e);
      }
    }
  }
  // END CaseCommentQueue inner class

  public class CaseQueue implements Queueable
  {
    private Map<Id,Case> cases;
    public CaseQueue(List<Id> casesMissingContacts)
    {
      this.cases = new Map<Id,Case>([SELECT Id,SuppliedEmail,SuppliedName,SuppliedThumbtackID__c,ContactId,AccountId,Status FROM Case WHERE Id IN :casesMissingContacts AND RecordType.Name IN ('Customer Support','Marketplace Integrity','Live Chat') AND Origin IN ('Suggestion Box','Email','Web','Dispute form','Directly Question','Live Chat','Social Media','App Integration')]);
    }

    public void execute(QueueableContext context)
    {
      try
      {
        System.debug(LoggingLevel.FINEST, JSON.serialize(this.cases) );

        if(null!=this.cases && !this.cases.isEmpty())
        {
          //Lookup Account from Custom Setting, if not found, do Account SOQL
          Id cRTId=Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
          Id aRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();

          // **************************************************************
          // STEP [1], match on Case.SuppliedEmail -> Contact.Email
          // **************************************************************

          //1A] gather up emails for contact lookup
          Map<String,Contact> emailsToContact = new Map<String,Contact>();
          for(Case c: cases.values())
          {
            if( null==c.ContactId && null!=c.SuppliedEmail && !''.equals(c.SuppliedEmail.trim()) )
            {
              emailsToContact.put(c.SuppliedEmail,null);
            }
          }

          //2A] see if any of the supplied emails match existing contacts
          if( !emailsToContact.isEmpty() )
          {
            for(Contact existingContact: [SELECT Id,Email,AccountId from Contact WHERE Email IN :emailsToContact.keyset()])
            {
              if( null==emailsToContact.get(existingContact.Email) )
              { //ignore dupes, take first matching contact
                emailsToContact.put(existingContact.Email,existingContact);
              }
            }
          }

          //3A] see if matching contacts to email can satisfy any of the Case to Contact links
          if( !emailsToContact.isEmpty() )
          {
            for(Case c: cases.values())
            {
              if( null==c.ContactId && null!=c.SuppliedEmail && !''.equals(c.SuppliedEmail.trim()) )
              {
                Contact ct = emailsToContact.get(c.SuppliedEmail);
                c.ContactId = (ct==null? null: ct.Id);
                c.AccountId = (ct==null? null: ct.AccountId);
              }
            }
          }

          // **************************************************************
          // END STEP [1]
          // **************************************************************
          // **************************************************************
          // STEP [2], match on Case.SuppliedThumbtackID__c -> Account/Contact.usr_user_id__c
          // **************************************************************

          //1B] gather up SuppliedThumbtackID__c for contact lookup
          Map<Decimal,Contact> userIdsToContact = new Map<Decimal,Contact>();
          for(Case c: cases.values())
          {
            if( null==c.ContactId && null!=c.SuppliedThumbtackID__c && c.SuppliedThumbtackID__c>0 )
            {
              userIdsToContact.put(c.SuppliedThumbtackID__c,null);
            }
          }
          //2B] see if any of the supplied emails match existing contacts
          if( !userIdsToContact.isEmpty() )
          {
            for(Contact existingContact: [SELECT Id,Email,AccountId,Account.usr_user_id__c,usr_user_id__c from Contact WHERE Account.usr_user_id__c IN :userIdsToContact.keyset() OR usr_user_id__c IN :userIdsToContact.keyset()]) {
              if( null==userIdsToContact.get(existingContact.Account.usr_user_id__c) && null==userIdsToContact.get(existingContact.usr_user_id__c) )
              { //ignore dupes, take first matching contact
                userIdsToContact.put( (null==existingContact.usr_user_id__c? existingContact.Account.usr_user_id__c:existingContact.usr_user_id__c),existingContact);
              }
            }
          }
          //3C] see if matching contacts to email can satisfy any of the Case to Contact links
          if( !userIdsToContact.isEmpty() )
          {
            for(Case c: cases.values())
            {
              if( null==c.ContactId && null!=c.SuppliedThumbtackID__c && c.SuppliedThumbtackID__c>0 )
              {
                Contact ct = userIdsToContact.get(c.SuppliedThumbtackID__c);
                c.ContactId = (ct==null? null: ct.Id);
                c.AccountId = (ct==null? null: ct.AccountId);
              }
            }
          }

          // **************************************************************
          // END STEP [2]
          // **************************************************************
          //4] for any remaining unlinked Cases, create a Customer Contact linked to a Case.Id Map
          //Map<Id,Contact> contacts = new Map<Id,Contact>();
          Map<Id,Account> caseIdToAccountMap = new Map<Id,Account>();
          for(Case c: cases.values())
          {
            if( null==c.ContactId && null!=c.SuppliedEmail && !''.equals(c.SuppliedEmail.trim()) )
            {
              //if Case.SuppliedName is empty, use the Case.SuppliedEmail mailbox name to set Contact.LastName
              String[] emailParts = c.SuppliedEmail.trim().split('@',2);
              Boolean LastNameIsEmailAddress = (null==c.SuppliedName || ''.equals(c.SuppliedName.trim()));
              String[] nameParts = LastNameIsEmailAddress? new List<String>{emailParts[0]}: c.SuppliedName.replaceAll('  ',' ').trim().split(' ',2);
              //contacts.put(c.Id, new Contact( FirstName=((2 == nameParts.size())? nameParts[0]:null), LastName=((2 == nameParts.size())? nameParts[1]:nameParts[0]), ContactOrigin__c='Email-to-Case', LastNameIsEmailAddress__c=LastNameIsEmailAddress, Email=c.SuppliedEmail, RecordTypeId=cRTId, AccountId=null) );
              caseIdToAccountMap.put(c.Id, new Account( Name=String.join(nameParts,' '), RecordTypeId=aRTId, usr_email__c=c.SuppliedEmail, usr_first_name__c=((2 == nameParts.size())? nameParts[0]:null), usr_last_name__c=((2 == nameParts.size())? nameParts[1]:nameParts[0])) );
            }
          }
          //5 insert new Account records, if any, then place new AccountIds on Contacts to be inserted
          if( !caseIdToAccountMap.isEmpty() )
          {
            Database.SaveResult[] acctResults = Database.insert(caseIdToAccountMap.values(),false);
            System.debug(LoggingLevel.FINEST, JSON.serialize(acctResults));
            Set<Id> newAccountIds = new Set<Id>();
            Map<Id, Account> accountWithContactMap = null;

            for(Database.SaveResult sr : acctResults)
            {
              if(sr.isSuccess())
              {
                newAccountIds.add(sr.getId());
              }
            }

            accountWithContactMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id IN: newAccountIds]);

            for(Case c : cases.values())
            {
              Account caseAccount = caseIdToAccountMap.get(c.Id);

              if(caseAccount != null && caseAccount.Id != null)
              {
                Account accountWithContact = accountWithContactMap.get(caseAccount.Id);

                if(accountWithContact != null)
                {
                  c.AccountId = accountWithContact.Id;

                  if(!accountWithContact.Contacts.isEmpty())
                  {
                    c.ContactId = accountWithContact.Contacts[0].Id;
                  }
                }
              }
            }

            /*Integer acctIndex = -1;
            for ( Id caseId: accounts.keySet() )
            {
              ++acctIndex;
              Database.SaveResult sr = acctResults[acctIndex];
              if(sr.isSuccess() && null!=sr.getId() && sr.getId().equals(accounts.get(caseId).Id) )
              {
                if( null != contacts.get(caseId) )
                {
                  contacts.get(caseId).AccountId = sr.getId();
                }
              }
            }*/
          }
          /*//6 insert new Contact records, if any, and do not use all-or-nothing commits
          if( !contacts.isEmpty() )
          {
            Database.SaveResult[] saveResults = Database.insert(contacts.values(),false);
            System.debug(LoggingLevel.FINEST, JSON.serialize(saveResults));
            Integer ctIndex = -1;
            for ( Id caseId: contacts.keySet() )
            {
              ++ctIndex;
              Database.SaveResult sr = saveResults[ctIndex];
              if(sr.isSuccess() && null!=sr.getId() && sr.getId().equals(contacts.get(caseId).Id) )
              {
                if( null != this.cases.get(caseId) )
                {
                  Case triggeredCase = this.cases.get(caseId);
                  triggeredCase.ContactId = sr.getId();
                  triggeredCase.AccountId = (null != contacts.get(caseId))? contacts.get(caseId).AccountId: null;
                }
              }
            }
          }*/

          //7 update the triggered Cases with newly set ContactId values, and do not use all-or-nothing commits
          System.debug(LoggingLevel.FINEST, JSON.serialize( Database.update(cases.values(),false) ) );
        }
      }
      catch(DmlException e)
      {
        system.debug(e);
      }
    }
  }
  //END CaseQueue inner class

}