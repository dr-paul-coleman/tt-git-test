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
Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-07-31   Mendel Guillaume       Created
========+============+=================+===============================================*/

public with sharing class FindUserController
{
	private final static String ACCOUNT_CUSTOMER_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
	private final static String ACCOUNT_PRO_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();

	@AuraEnabled
	public static List<FindUserResult> findUser(string searchText)
	{
		List<FindUserResult> results = new List<FindUserResult>();
		List<Contact> contacts = new List<Contact>();
		Boolean first = true;
		List<List<SObject>> records = null;
		Set<ID> accountIds = new Set<Id>();
		Set<Decimal> userIds = new Set<Decimal>();
		List<becquerel_tt_user_for_tack__x> usrs = null;
		Boolean isNumber = searchText.trim().isNumeric();
		String query;
		Decimal uId;
		List<String> searchSplit = searchText.split(' ');

		searchText = String.escapeSingleQuotes(searchText.trim());

		records = [FIND :searchText IN ALL FIELDS RETURNING Account(Id), Contact(Id, AccountId) LIMIT 100];

		//Get Account Ids
		if(!records[0].isEmpty())
		{
			accountIds.addAll(new Map<Id, Account>((List<Account>) records[0]).keySet());
		}

		if(!records[1].isEmpty())
		{
			List<Contact> temp = (List<Contact>) records[1];

			for (Contact c : temp)
			{
				accountIds.add(c.AccountId);
			}
		}

		if(!accountIds.isEmpty())
		{
			contacts = [SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
							Account.BillingState, FirstName, LastName, Phone FROM Contact WHERE AccountId IN :accountIds ORDER BY Account.Name, Name];
		}

		for(Contact c : contacts)
		{
			results.add(new FindUserResult(c, null));

			if(c.usr_user_id__c != null)
			{
				userIds.add(c.usr_user_id__c);
			}
		}

		//Exclude user ids returned from salesforce
		/*records = [FIND :searchText IN ALL FIELDS RETURNING becquerel_tt_user_for_tack__x(Id, sav_business_name__c,
						usr_last_name__c, usr_first_name__c, usr_email__c, usr_user_id__c, phn_phone_number__c, usa_state__c, sav_phn_phone_number__c
						WHERE usr_user_id__c NOT IN :userIds ORDER BY sav_business_name__c, usr_first_name__c, usr_last_name__c)
					LIMIT 50];*/

		if(!Test.isRunningTest())
		{
			query = 'SELECT Id, sav_business_name__c, usr_last_name__c, usr_first_name__c, usr_email__c, usr_user_id__c, phn_phone_number__c, usa_state__c, user_type__c ' +
					'FROM becquerel_tt_user_for_tack__x WHERE usr_user_id__c NOT IN :userIds AND (usr_last_name__c = :searchText OR usr_first_name__c = :searchText OR ' +
					'usr_email__c = :searchText OR phn_phone_number__c = :searchText OR sav_notif_phn_phone_number__c = :searchText OR ' +
					'sav_business_name__c = :searchText ';

			if (isNumber)
			{
				uId = Decimal.valueOf(searchText);
				query += 'OR usr_user_id__c = :uId ';
			}

			if (searchSplit.size() > 1)
			{
				query += 'OR (usr_first_name__c = \'' + searchSplit[0] + '\' AND usr_last_name__c = \'' + searchSplit[1] + '\') ';
			}

			query += ') ORDER BY sav_business_name__c, usr_first_name__c, usr_last_name__c, usr_user_id__c LIMIT 100';

			System.debug(query);

			usrs = database.query(query);
		}
		else
		{
			usrs = new List<becquerel_tt_user_for_tack__x>();
			usrs.add(new becquerel_tt_user_for_tack__x(sav_business_name__c = 'Biz 1', usr_last_name__c = 'Ext1',
					usr_first_name__c = 'Test', usr_email__c = 'ext1@gmail.com', usr_user_id__c = 12345,
					phn_phone_number__c = '555-555-5550', usa_state__c = 'NY', user_type__c = 'Pro'));
			usrs.add(new becquerel_tt_user_for_tack__x(sav_business_name__c = 'Biz 2', usr_last_name__c = 'Ext2',
					usr_first_name__c = 'Test', usr_email__c = 'ext1@gmail.com', usr_user_id__c = 12346,
					phn_phone_number__c = '555-555-5551', usa_state__c = 'NY', user_type__c = 'Pro'));
			usrs.add(new becquerel_tt_user_for_tack__x(sav_business_name__c = 'Biz 3', usr_last_name__c = 'Ext3',
					usr_first_name__c = 'Test', usr_email__c = 'ext1@gmail.com', usr_user_id__c = 12347,
					phn_phone_number__c = '555-555-5552', usa_state__c = 'NY', user_type__c = 'Customer'));
		}

		for (becquerel_tt_user_for_tack__x u : usrs)
		{
			results.add(new FindUserResult(null, u));
		}

		return results;
	}

	@AuraEnabled
	public static Contact findExistingContact(Decimal userId)
	{
		Contact c = null;

		List<Contact> contacts = [SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
				Account.BillingState, FirstName, LastName, Phone FROM Contact WHERE usr_user_id__c = :userId];

		if(!contacts.isEmpty())
		{
			c = contacts[0];
		}

		return c;
	}

	@AuraEnabled
	public static List<Option> getAccountRecordTypes()
	{
		List<Option> options = new List<Option>();
		List<Schema.RecordTypeInfo> rts = Account.SObjectType.getDescribe().getRecordTypeInfos();

		for(Schema.RecordTypeInfo r : rts)
		{
			if(!r.isMaster())
			{
				if(r.getName()  != 'Managed Account')
				{
					options.add(new Option(r.getName(), r.getRecordTypeId()));
				}
			}
		}

		return options;
	}

	@AuraEnabled
	public static Case getCase(String caseId)
	{
		Case c = null;
		List<Case> cases = [SELECT Id, Contact.Name FROM Case WHERE Id = :caseId];

		if(!cases.isEmpty())
		{
			c = cases[0];
		}

		return c;
	}

	@AuraEnabled
	public static ResponseUtility updateCase(String accountId, String contactId, String caseId)
	{
		ResponseUtility result = new ResponseUtility(true);
		Savepoint sp;

		try
		{
			sp = Database.setSavepoint();

			saveCase(accountId, contactId, caseId);

			result.record = new Account(Id = accountId);
		}
		catch (Exception ex)
		{
			if (sp != null)
			{
				Database.rollback(sp);
			}

			result.success = false;
			result.error = ex.getMessage();
		}

		return result;
	}

	@AuraEnabled
	public static ResponseUtility updateAccountContactFromUser(becquerel_tt_user_for_tack__x usr, String accountId, String contactId, String caseId)
	{
		Account acct = null;
		Contact cont = null;
		ResponseUtility result = new ResponseUtility(true);
		Savepoint sp;

		try
		{
			acct = new Account(Id = accountId, Name = String.format('{0} {1}', new List<String> {usr.usr_first_name__c, usr.usr_last_name__c}),
					usr_first_name__c = usr.usr_first_name__c, usr_last_name__c = usr.usr_last_name__c, usr_email__c = usr.usr_email__c);

			cont = new Contact(Id = contactId, FirstName = usr.usr_first_name__c, LastName = usr.usr_last_name__c,
					Email = usr.usr_email__c);

			sp = Database.setSavepoint();

			update acct;
			update cont;

			saveCase(accountId, contactId, caseId);
			result.record = acct;
		}
		catch (Exception ex)
		{
			if (sp != null)
			{
				Database.rollback(sp);
			}

			result.success = false;
			result.error = ex.getMessage();
		}

		return result;
	}

	@AuraEnabled
	public static ResponseUtility createAccountContactFromUser(becquerel_tt_user_for_tack__x usr, String acctRecType, String caseId)
	{
		Account acct = new Account(Name = String.format('{0} {1}', new List<String>{usr.usr_first_name__c, usr.usr_last_name__c}),
				usr_first_name__c = usr.usr_first_name__c, usr_last_name__c = usr.usr_last_name__c, usr_email__c = usr.usr_email__c,
				usr_user_id__c = usr.usr_user_id__c, RecordTypeId = (usr.user_type__c != null && usr.user_type__c.contains('Pro')) ? ACCOUNT_PRO_RECORD_TYPE_ID : ACCOUNT_CUSTOMER_RECORD_TYPE_ID);

		return createAccountContact(acct, caseId);
	}

	@AuraEnabled
	public static ResponseUtility createNewAccountContact(String email, String first, String last, String acctRecType, Decimal userId, String caseId)
	{
		Account acct = new Account(Name = String.format('{0} {1}', new List<String>{first, last}),
				usr_first_name__c = first, usr_last_name__c = last, usr_email__c = email, RecordTypeId = acctRecType);

		if(userId != null && userId > 0)
		{
			acct.usr_user_id__c = userId;
		}

		return createAccountContact(acct, caseId);
	}

	private static ResponseUtility createAccountContact(Account acct, String caseId)
	{
		ResponseUtility result = new ResponseUtility(true);
		Savepoint sp;
		List<Contact> contacts = null;
		List<User> owners = null;
		Contact cont = null;
		List<Case> cases = null;

		try
		{
			owners = [SELECT Id FROM User WHERE FirstName = 'tack' AND LastName = 'bot'];
			cases = [SELECT ANI__c FROM Case WHERE Id = :caseId];

			if(!cases.isEmpty() && cases[0].ANI__c != null)
			{
				acct.Phone = cases[0].ANI__c;
			}

			if(!owners.isEmpty())
			{
				acct.OwnerId = owners[0].Id;
			}

			sp = Database.setSavepoint();

			insert acct;

			//Check if contact is created. If not, create contact. Account Trigger code doesn't create contact if usr id is not specified
			contacts = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

			if(contacts.isEmpty())
			{
				cont = new Contact(AccountId = acct.Id, FirstName = acct.usr_first_name__c, LastName = acct.usr_last_name__c,
						Email = acct.usr_email__c, usr_user_id__c = acct.usr_user_id__c);

				if(!cases.isEmpty() && cases[0].ANI__c != null)
				{
					cont.Phone = cases[0].ANI__c;
				}

				if (acct.RecordTypeId == ACCOUNT_CUSTOMER_RECORD_TYPE_ID)
				{
					cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
				}
				else
				{
					cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
				}

				insert cont;
			}

			saveCase(acct.Id, cont != null ? cont.Id : contacts[0].Id, caseId);
			result.record = acct;
		}
		catch (Exception ex)
		{
			if(sp != null)
			{
				Database.rollback(sp);
			}

			result.success = false;
			result.error = ex.getMessage();
		}

		return result;
	}

	private static void saveCase(String accountId, String contactId, String caseId)
	{
		if(caseId != null)
		{
			Case c = new Case(Id = caseId, AccountId = accountId, ContactId = contactId);

			update c;
		}
	}

	public class FindUserResult
	{
		@AuraEnabled
		public Id recordId{get{ return contact == null ? user.Id : contact.Id;}}
		@AuraEnabled
		public String accountName{get{ return contact == null ? user.sav_business_name__c : contact.Account.Name;}}
		@AuraEnabled
		public String accountId{get{return contact == null ? null : contact.AccountId;}}
		@AuraEnabled
		public String name{get{ return contact == null ? String.format('{0} {1}', new List<String>{user.usr_first_name__c, user.usr_last_name__c}) : contact.Name;}}
		@AuraEnabled
		public String first{get{ return contact == null ? user.usr_first_name__c : contact.FirstName;}}
		@AuraEnabled
		public String last{get{ return contact == null ? user.usr_last_name__c : contact.LastName;}}
		@AuraEnabled
		public String userId
		{
			get
			{
				if (contact != null && contact.usr_user_id__c != null)
				{
					return String.valueOf(contact.usr_user_id__c);
				}
				else if (user != null && user.usr_user_id__c != null)
				{
					return String.valueOf(user.usr_user_id__c);
				}
				return '';
			}
		}
		@AuraEnabled
		public String recordType{get{ return contact == null ? user.user_type__c : contact.RecordType.Name;}}
		@AuraEnabled
		public String email{get{ return contact == null ? user.usr_email__c : contact.Email;}}
		@AuraEnabled
		public String billingCity{get{ return contact == null ? null : contact.Account.BillingCity;}}
		@AuraEnabled
		public String billingState{get{ return contact == null ? user.usa_state__c : contact.Account.BillingState;}}
		@AuraEnabled
		public String phone{get{ return contact == null ? user.phn_phone_number__c : contact.Phone;}}

		@AuraEnabled
		public Contact contact{get;set;}

		@AuraEnabled
		public becquerel_tt_user_for_tack__x user{get;set;}

		@AuraEnabled
		public Boolean isContact{get{return contact != null;}}

		@AuraEnabled
		public Boolean isExternalUser{get{return user != null;}}

		public FindUserResult(Contact c, becquerel_tt_user_for_tack__x u)
		{
			this.contact = c;
			this.user = u;
		}

		public FindUserResult()
		{}
	}

	public class Option
	{
		@AuraEnabled
		public String label{get;set;}

		@AuraEnabled
		public String value{get;set;}

		public Option(String l, String v)
		{
			this.label = l;
			this.value = v;
		}
	}
}