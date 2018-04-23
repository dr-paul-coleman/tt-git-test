/*
  Copyright (c) 2015, 2016, 2017 Thumbtack  All rights reserved.
  
 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 ..Previous versions in GIT
 2.2     2018-02-19	 Meena Pisupati	   Update Routing Profile on Account Manager Update
 2.3     2018-04-01	 Meena Pisupati	   Logic Change for updateRoutingProfile method
 =======+===========+=================+=================================*/
public virtual class AccountTriggerHandler extends ThumbtackTriggerHandlerBase
{
    public static final DateTime SYNC_CUT_OFF_TIME = DateTime.now().addHours(-1);  //sync TT User remote objects no more frequently than this constant

    // Recursion Prevention Flags
    private static Boolean isInBeforeInsertProcessing = false;
    private static Boolean isInBeforeUpdateProcessing = false;
    private static Boolean isInAfterInsertProcessing = false;
    private static Boolean isInAfterUpdateProcessing = false;
    Set<String> outreachType = new Set<String>{'managed_account', 'lead_acquisition'};

    // TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
	public override void onBeforeInsert(ThumbtackTriggerContext ctx)
	{
		if(!isInBeforeInsertProcessing)
		{
			isInBeforeInsertProcessing = true;

			try
			{
				this.setAccountsOwnership((List<Account>) ctx.newRecords);
			}
			finally
			{
				isInBeforeInsertProcessing = false;
			}
		}
	}

    public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInBeforeUpdateProcessing)
        {
            isInBeforeUpdateProcessing = true;
            try
            {
                this.synchronizeSendOverbudgetEmail((Account[]) ctx.newRecords);
            }
            finally
            {
                isInBeforeUpdateProcessing = false;
            }
        }
          else
        {
            // Nothing to do here,
            // just illustrating how the trigger framework can divert to other processing for recursive execution flows
            this.doRecursiveProcessing(ctx);
        }

    }

    public override void onAfterInsert(ThumbtackTriggerContext ctx)
    {
        if(!isInAfterInsertProcessing)
        {
            isInAfterInsertProcessing = true;
            try { this.synchronizeTTContact((Account[]) ctx.newRecords); } finally { isInAfterInsertProcessing = false; }
        }
    }

    public override void onAfterUpdate(ThumbtackTriggerContext ctx)
    {
        if(!isInAfterUpdateProcessing)
        {
            isInAfterUpdateProcessing = true;
            try 
            { 
                this.synchronizeTTContact((Account[]) ctx.newRecords); 
                this.updateRoutingProfile((Account[]) ctx.newRecords,(Map<Id, Account>)ctx.oldRecordsMap);
            }        
            finally { isInAfterUpdateProcessing = false; }
        }
    }



    //PRIVATE MEMBER FUNCTIONS
	/**
    * @author Mendel Guillaume
    * @date 2017-12-14
    * @description Set account ownership to tackbot when account record type != 'Managed Account'
    * @param newRecords the trigger list.
    */
	private void setAccountsOwnership(List<Account> newRecords)
	{
		Id managedAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Managed Account').getRecordTypeId();
		User tackBot = TackBotUtility.getTackBotUser();

		for(Account a : newRecords)
		{
			if (a.RecordTypeId != managedAccountRecTypeId && a.OwnerId != tackBot.Id)
			{
				a.OwnerId = tackBot.Id;
			}
		}
	}

    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Ensure Phone number fields are stripped of formatting chars
    * @param Account[] the trigger array.
    */
    private void stripPhoneFormatting( Account[] triggerNew )
    {
        for ( Account acc : triggerNew )
        {
            acc.Phone = ( NULL == acc.Phone ) ? NULL : acc.Phone.replaceAll('[^0-9]','');
            acc.sav_notifications_phn_phone_number__c = ( NULL == acc.sav_notifications_phn_phone_number__c ) ? NULL : acc.sav_notifications_phn_phone_number__c.replaceAll('[^0-9]','');
        }
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Ensure SendOverbudgetEmail__c is set before update
    * @param Account[] the trigger array.
    */
    private void synchronizeSendOverbudgetEmail(Account[] triggerNew)
    {
        for (Account acc : triggerNew)
        {
            //modify send email flag if req'd
            acc.SendOverbudgetEmail__c = (acc.ContactBudgetPercentage__c >= 80 && !acc.OverBudgetEmailSent__c ) ? true : acc.SendOverbudgetEmail__c;

        }
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-05
    * @description Ensure a Contact exists for all thumbtack user Accounts, AFTER INSERT/UPDATE.
    * @param Account[] the trigger array.
    */
    private void synchronizeTTContact(Account[] triggerNew)
    {
        if( Test.isRunningTest() ) { System.debug(LoggingLevel.FINEST, 'ACCOUNTS TO SYNC WITH CONTACTS: ' + JSON.serialize(triggerNew)); }

        Id contactCustomerRtId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id contactProRtId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        List<Contact> contactsToUpsert = new List<Contact>();
        Account[] accountsToSync = new Account[0];

        for (Account acc : [SELECT Id, Name, LastSyncedWithDataPlatform__c, usr_email__c, usr_user_id__c, user_pk_id__c, RecordType.DeveloperName, usr_first_name__c, usr_last_name__c, Phone, OwnerId, (SELECT Id, usr_user_id__c, user_pk_id__c, Email FROM Contacts) FROM Account WHERE RecordType.DeveloperName IN ('Customer', 'ThumbtackPro') AND Id IN :triggerNew])
        {
            Id newContactRtId = ('Customer'.equals(acc.RecordType.DeveloperName)) ? contactCustomerRtId : contactProRtId;
            if (acc.Contacts.isEmpty())
            {
                contactsToUpsert.add(mapAccountFieldsToContact(acc, newContactRtId, null));
            }
            else
            {
                Boolean isContactMatchFound = false;
                for (Contact ttcontact : acc.Contacts)
                {
                    // find matching contact for field value sync
                    if (ttcontact.user_pk_id__c == acc.user_pk_id__c || ttcontact.usr_user_id__c == acc.usr_user_id__c || ttcontact.Email == acc.usr_email__c)
                    {
                        isContactMatchFound = true;
                        contactsToUpsert.add(mapAccountFieldsToContact(acc, newContactRtId, ttcontact.Id));
                        break;
                    }
                }

                // fail safe, if a contact(s) does exist, but is not a Thumbtack user match by pk, usr_id, or email,
                // insert a new matching contact
                if (!isContactMatchFound) { contactsToUpsert.add(mapAccountFieldsToContact(acc, newContactRtId, null)); }
            }

            // should this account be synchronoized with SF Connect Remote Objects (Becquerel)?
            DateTime lastSync = acc.LastSyncedWithDataPlatform__c;
            if (null == lastSync || lastSync < SYNC_CUT_OFF_TIME) { accountsToSync.add(acc); }

        } // end for

        // In-Line Synchronous Contact Upserts to maintain 1:1 Account=>Contact fidelity given Asynchronous remote object data syncs
        for (Database.UpsertResult result : Database.upsert(contactsToUpsert, false)) // UPSERT as many contacts as possible (ALL-OR-NOTHING SUCCESS NOT REQ'D)
        {
            // log UPSERT failures, if any
            if (!result.isSuccess()) { for (Database.Error err : result.getErrors()) { System.debug(LoggingLevel.ERROR, 'Contact UPSERT ERROR. [' + err.getStatusCode() + '] ' + err.getMessage() + ' Fields: ' + err.getFields()); } }
        }

        // Ask Becky to sync remote objects
        if (!accountsToSync.isEmpty())
        {
            BeckyTTUserSyncQueueable queue = new BeckyTTUserSyncQueueable((accountsToSync));
            if ( System.isQueueable() ) { queue.execute(null); } else { System.enqueueJob( queue ); }
        }

    }
	
    /**
    * @author Meenakshi Pisupati
    * @date 2018-02-19
    * @description Update Routing Profile if Account Manager on Account is updated if Pre-onboarding enrollment exists
    * @param Account[] the trigger array.
    */
    private void updateRoutingProfile(Account[] triggerNew, Map<Id, Account> triggerOldMap)
    {
        Id[] accountIds = new Id[0]; 
        Map<Id,RoutingProfile__c> rpEnrollments= new Map<Id,RoutingProfile__c>();
        RoutingProfile__c[] rpList = new RoutingProfile__c[0];     
        Id[] accountsToUpdateIds = new Id[0];
        
        //Check if Account Manager has been updated
        for(Account newAccount: triggerNew)
        {
            Account oldAccount = triggerOldMap.get(newAccount.id); 
            if(oldAccount.AccountManager__c != newAccount.AccountManager__c)
            {
                accountIds.add(newAccount.Id);                
            }
        }
        
        //Check if Pre-Onboarding enrollments exist
        for(Enrollment__c e: [SELECT Id, FunnelStep__c, Account__c FROM Enrollment__c WHERE Account__c IN :accountIds AND outreach_type__c IN ('managed_account','lead_acquisition')])
        {
            if('Pre-Onboarding'.equals(e.FunnelStep__c))
            {
                accountsToUpdateIds.add(e.Account__c);
            }
        }
        
        //If there are enrollments, update corresponding routing profiles with route to agent
        if(!accountsToUpdateIds.isEmpty())
        {     
            for(RoutingProfile__c rp: [SELECT Id, Account__c, Account__r.AccountManager__c, Account__r.AccountManager__r.Email, Enrollment__c FROM RoutingProfile__c WHERE Account__c IN :accountsToUpdateIds])
            {                             
                if(String.isNotEmpty(rp.Account__r.AccountManager__c))
                {
                    rp.RoutetoAgent__c = rp.Account__r.AccountManager__r.Email;   
                    rp.Sales__c = FALSE;                        
                }
                else
                {
                    rp.RoutetoAgent__c = NULL;         
                    rp.Enterprise__c = TRUE;
                    rp.Sales__c = FALSE;
                }
                rpList.add(rp);       
            }
        }
        
        if(!rpList.isEmpty())
        {
            try
            {
                QueueableUtility.handleQueueable(new DMLQueueable(rpList, DMLQueueable.Operation.UPDATES));
            } catch( Exception exc ){
                TackBotUtility.postTackLogException(exc, 'AccountTriggerHandler.updateRoutingProfile');
            }
        } 
    }
    
   /**
   * @author Paul Coleman
   * @date 2017-10-05
   * @description map Account->Contact fields for upsert of thumbtack user records
   * @param Account the account to sync the contact from.
   * @param Id the RecordTypeId to set on the Contact (matches Account, e.g. Pro or Customer).
   * @param Id the record Id of the Contact record, if this is an update vs new Contact.
   */
    private Contact mapAccountFieldsToContact(Account acc, Id recordTypeId, Id contactId)
    {
        String firstname = (null == acc.usr_first_name__c) ? '' : acc.usr_first_name__c.left(40);
        String lastname = (null == acc.usr_last_name__c) ? acc.Name : acc.usr_last_name__c.left(80);
        Contact ttcontact = new Contact(
                AccountId = acc.Id,
                RecordTypeId = recordTypeId,
                FirstName = firstname,
                LastName = lastname,
                Email = acc.usr_email__c,
                Phone = ( NULL == acc.Phone ) ? NULL : acc.Phone.replaceAll('[^0-9]',''),
                usr_user_id__c = acc.usr_user_id__c,
                user_pk_id__c = acc.user_pk_id__c,
                OwnerId = acc.OwnerId
            );
        if (null != contactId) { ttcontact.Id = contactId; }
        return ttcontact;
    }

}