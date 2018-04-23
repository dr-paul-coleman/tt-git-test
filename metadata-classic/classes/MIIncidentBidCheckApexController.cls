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
1.0       06-19-2017     Scott Purcell          Created
1.1       01-15-2018     Mendel Guillaume       Modified for error messaging and ReportedDate__c pre-population
========+============+=================+===============================================*/
public class MIIncidentBidCheckApexController
{
    public static Id miRecordTypeId = MIIncident__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('MI Incident').getRecordTypeId();
    public static Group marketplaceIntegrity = [Select Id from Group where Type = 'Queue' AND Name = 'Marketplace Integrity' LIMIT 1];
    public static Id cRTId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
    public static Id ttRTId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
    //public static becquerel_mi_incident_project_data__x mix { get; set; }
    public static MIIncident__c mi { get; set; }

    @AuraEnabled
    public static ResponseUtility getIncidentFromBecky(Decimal bidId, MIIncident__c incident)
    {
	    //query external then set mi record to external variables then return
	    ResponseUtility response = new ResponseUtility(true);
	    becquerel_mi_incident_project_data__x mix;

	    try
	    {
		    if (Test.isRunningTest())
		    {
			    mix = new becquerel_mi_incident_project_data__x(
					    bid_id__c = 1234, customer_id__c = 123, customer_email__c = 'test@tester.com', pro_email__c = 'pro@tester.com',
					    hired__c = false, pro_user_id__c = 12345, most_recent_phone_number__c = '1234445555', pro_first_name__c = 'pro first', pro_last_name__c = 'pro last',
					    request_create_time__c = Datetime.now(), request_id__c = 111, service_id__c = 222,
					    customer_first_name__c = 'Cust first', customer_last_name__c = 'cust last');
		    }
		    else
		    {
			    List<becquerel_mi_incident_project_data__x> externalIncidents = [
					    SELECT bid_id__c,customer_id__c,customer_email__c, pro_email__c,pro_user_id__c,most_recent_phone_number__c,
							    hired__c,request_create_time__c,request_id__c,service_id__c,customer_first_name__c,customer_last_name__c,
							    pro_first_name__c,pro_last_name__c,request_category__c,pro_signup_date__c
					    FROM becquerel_mi_incident_project_data__x
					    WHERE bid_id__c = :bidId
					    LIMIT 1
			    ];

			    if (!externalIncidents.isEmpty())
			    {
				    mix = externalIncidents[0];
			    }
		    }

		    if (mix != null)
		    {
			    Integer custInt = Integer.valueOf(mix.customer_id__c);
			    Integer proInt = Integer.valueOf(mix.pro_user_id__c);
			    Decimal cust = Decimal.valueOf(custInt);
			    Decimal pro = Decimal.valueOf(proInt);
			    List<Account> accs = [Select Id,usr_user_id__c From Account Where usr_user_id__c = :pro OR usr_user_id__c = :cust];

			    for (Account acc : accs)
			    {
				    if (pro != null && acc.usr_user_id__c == pro)incident.ProAccount__c = acc.Id;
				    if (cust != null && acc.usr_user_id__c == cust)incident.CustomerAccount__c = acc.Id;
			    }

			    incident.Name = 'Incident for ' + mix.customer_first_name__c + ' ' + mix.customer_last_name__c;
			    incident.CustomerName__c = (mix.customer_first_name__c + ' ' + mix.customer_last_name__c).left(50);
			    incident.service_id__c = String.valueOf(mix.service_id__c);
			    incident.request_id__c = String.valueOf(mix.request_id__c);
			    incident.request_category__c = mix.request_category__c;
			    incident.request_create_time__c = mix.request_create_time__c;
			    incident.quotes_hired__c = mix.hired__c;
			    incident.pro_user_id__c = String.valueOf(mix.pro_user_id__c);
			    incident.customer_id__c = String.valueOf(mix.customer_id__c);
			    incident.ProEmail__c = mix.pro_email__c;
			    incident.ProPhone__c = mix.most_recent_phone_number__c;
			    incident.CustomerEmail__c = mix.customer_email__c;
			    incident.ProfessionalName__c = (mix.pro_first_name__c + ' ' + mix.pro_last_name__c).left(50);

			    if (mix.pro_signup_date__c != null)incident.pro_signup_date__c = mix.pro_signup_date__c.date();

			    response.record = incident;
		    }
	    }
	    catch (Exception ex)
	    {
		    response.success = false;
		    response.error = ex.getMessage();
	    }

	    return response;
    }

    @AuraEnabled
    public static ResponseUtility insertNewIncidentFromExternal(MIIncident__c mi, String casId, Boolean custcheckbox, Boolean procheckbox)
    {
	    ResponseUtility response = new ResponseUtility(true);
	    Contact custContact = null;
	    Contact proContact = null;

	    try
	    {
		    custContact = new Contact(usr_user_id__c = Decimal.valueOf(mi.customer_id__c), Email = mi.CustomerEmail__c, FirstName = mi.CustomerName__c.split(' ')[0],
				    LastName = mi.CustomerName__c.split(' ')[1]);
		    proContact = new Contact(usr_user_id__c = Decimal.valueOf(mi.pro_user_id__c), Email = mi.ProEmail__c, FirstName = mi.ProfessionalName__c.split(' ')[0],
				    LastName = mi.ProfessionalName__c.split(' ')[1]);

		    response = insertNewIncident(mi, casId, custcheckbox, procheckbox, custContact, proContact);
	    }
	    catch (Exception ex)
	    {
		    response.success = false;
		    response.error = ex.getMessage();
	    }

	    return response;
    }

    @AuraEnabled
    public static ResponseUtility insertNewIncident(MIIncident__c mi, String casId, Boolean custcheckbox, Boolean procheckbox, Contact custContact, Contact proContact)
    {
	    ResponseUtility response = new ResponseUtility(true);
	    Savepoint sp = null;

	    try
	    {
		    Case cs = getCaseValues(casId);
		    Set<String> emails = new Set<String>();

		    if(String.isNotBlank(custContact.Email))
		    {
			    emails.add(custContact.Email);
		    }

		    if(String.isNotBlank(proContact.Email))
		    {
			    emails.add(proContact.Email);
		    }

		    Map<String, FindUserController.FindUserResult> users = findThumbtackUsers(new Set<Decimal> {custContact.usr_user_id__c, proContact.usr_user_id__c}, emails);
		    FindUserController.FindUserResult custUser = users.get(String.valueOf(custContact.usr_user_id__c));
		    FindUserController.FindUserResult proUser = users.get(String.valueOf(proContact.usr_user_id__c));

		    if(custUser == null && String.isNotBlank(custContact.Email))
		    {
			    custUser = users.get(custContact.Email.toLowerCase());
		    }

		    if(proUser == null && String.isNotBlank(proContact.Email))
		    {
			    proUser = users.get(proContact.Email.toLowerCase());
		    }

		    sp = Database.setSavepoint();

		    if (custUser == null)
		    {
			    //Customer not found - create new account/contact
			    custContact = createNewAccountContact(custContact.Email, custContact.FirstName, custContact.LastName, cRTId, custContact.usr_user_id__c);
		    }
		    else
		    {
			    if (custUser.isExternalUser)
			    {
				    custContact = createNewAccountContact(custUser.email, custUser.first, custUser.last, cRTId, custUser.user.usr_user_id__c);
				    custContact.Phone = custUser.user.phn_phone_number__c;
			    }
			    else
			    {
				    custContact = custUser.contact;
			    }
		    }

		    if (proUser == null)
		    {
			    //Customer not found - create new account/contact
			    proContact = createNewAccountContact(proContact.Email, proContact.FirstName, proContact.LastName, cRTId, proContact.usr_user_id__c);
		    }
		    else
		    {
			    if (proUser.isExternalUser)
			    {
				    proContact = createNewAccountContact(proUser.email, proUser.first, proUser.last, ttRTId, proUser.user.usr_user_id__c);
				    proContact.Phone = proUser.user.phn_phone_number__c;
			    }
			    else
			    {
				    proContact = proUser.contact;
			    }
		    }

		    mi.bid_id__c = mi.bid_id__c != null ? String.valueOf(mi.bid_id__c) : null; //workaround for using number input field in interface
		    mi.RecordTypeId = miRecordTypeId;
		    mi.Name = 'Incident for ' + custContact.Name;

		    mi.CustomerAccount__c = custContact.AccountId;
		    mi.CustomerContact__c = custContact.Id;
		    mi.customer_id__c = custContact.usr_user_id__c == null ? null : String.valueOf(custContact.usr_user_id__c);

		    mi.pro_user_id__c = proContact.usr_user_id__c == null ? null : String.valueOf(proContact.usr_user_id__c);
		    mi.ProAccount__c = proContact.AccountId;
		    mi.ProContact__c = proContact.Id;
		    mi.FirstCaseCreatedDate__c = cs.CreatedDate;
		    mi.FirstCaseTransferredtoMIDate__c = cs.TransferredtoMI__c;

		    if (mi.OwnerId == null)
		    {
			    mi.OwnerId = UserInfo.getUserId();
		    }

		    mi.ExternalQuoteData__c = mi.bid_id__c;
		    insert mi;

		    Boolean primaryCustomerCase = (custcheckbox == null ? false : custcheckbox);
		    Boolean primaryProCase = (procheckbox == null ? false : procheckbox);

		    update new Case(Id = cs.Id,
				    MICasePrimaryCustomer__c = primaryCustomerCase,
				    MICasePrimaryPro__c = primaryProCase,
				    Description = 'Primary case of ' + custContact.Name + ' for ' + mi.Name,
				    Priority = mi.Priority__c,
				    Incident__c = mi.Id,
				    AccountId = (primaryCustomerCase ? custContact.AccountId : proContact.AccountId),
				    ContactId = (primaryCustomerCase ? custContact.Id : proContact.Id),
				    OwnerId = mi.OwnerId
		    );

		    // sync mi with external object
		    System.enqueueJob(new BeckyMTSIncidentSyncQueueable(new MIIncident__c[] {mi}));

		    //sync accounts with external object
		    System.enqueueJob(new BeckyTTUserSyncQueueable([SELECT Id, user_pk_id__c, usr_email__c, usr_user_id__c FROM Account WHERE Id IN (:mi.ProAccount__c, :mi.CustomerAccount__c)]));

		    response.record = mi;
	    }
	    catch (Exception ex)
	    {
		    if(sp != null)
		    {
			    Database.rollback(sp);
		    }

		    response.success = false;
		    response.error = ex.getMessage();
	    }

        return response;
    }

    @AuraEnabled
    public static Case getCaseValues(String casId)
    {
        return [SELECT Id, MIQuoteID__c, Origin, MITotalPaidtoPro__c, MICasePrimaryCustomer__c, MICasePrimaryPro__c,
		                Incident__c, Incident__r.bid_id__c, CreatedDate, TransferredtoMI__c
                    FROM Case
                    WHERE Id = :casId LIMIT 1];
    }

    @AuraEnabled
    public static MIIncident__c createInitialIncident(String casId)
    {
        Case cs = getCaseValues(casId);
        String bidid = String.valueOf(cs.MIQuoteID__c);
        List<MIIncident__c> mis = null;

	    if(bidid != null)
	    {
		    mis = [Select customer_id__c,IncidentExists__c,AmountInDispute__c,CustomerEmail__c, ProEmail__c,pro_user_id__c,ProPhone__c, bid_id__c,
				    quotes_hired__c,request_create_time__c,request_id__c,service_id__c,CustomerName__c,MISubcategory__c,MICategory__c,CustomerAccount__r.Name,
				    ProfessionalName__c,request_category__c,pro_signup_date__c,Origin__c,TotalPaidToPro__c,Priority__c,Status__c,OwnerId,RecordTypeId, ReportedDate__c
		    From MIIncident__c
		    Where bid_id__c = :bidid];
	    }

	    if (mis != null && !mis.isEmpty())
	    {
		    mi = mis[0];
		    mi.IncidentExists__c = true;
	    }
	    else
        {
            mi = new MIIncident__c();
            mi.IncidentExists__c = false;
            mi.FirstCaseCreatedDate__c = cs.CreatedDate;
            mi.FirstCaseTransferredtoMIDate__c = cs.TransferredtoMI__c;
        }

        mi.AmountInDispute__c = 0;
        mi.RecordTypeId = miRecordTypeId;
        mi.OwnerId = marketplaceIntegrity.Id;
        mi.Status__c = 'New';
	    mi.Origin__c = cs.Origin;
	    mi.TotalPaidToPro__c = cs.MITotalPaidtoPro__c;

        if (String.isBlank(mi.bid_id__c))
	    {
		    mi.bid_id__c = cs.MIQuoteID__c == null ? '' : String.valueOf(cs.MIQuoteID__c);
	    }

        if (mi.TotalPaidToPro__c == null)
        {
            mi.TotalPaidToPro__c = 0;
        }

	    if(mi.ReportedDate__c == null)
	    {
		    mi.ReportedDate__c = cs.CreatedDate.date();
	    }

        return mi;
    }

    @AuraEnabled
    public static List<String> getPicklistOptions(String sObjectName, String fieldName)
    {
        List<String> result = new List<String>();

	    if (String.isNotBlank(sObjectName) && String.isNotBlank(fieldName))
        {
            Schema.DescribeSObjectResult[] describeResults = Schema.describeSObjects(new String[] {sObjectName});
            Schema.DescribeFieldResult field = describeResults[0].fields.getMap().get(fieldName).getDescribe();
            for (Schema.PicklistEntry f : field.getPicklistValues())
            {
                result.add(f.getLabel());
            }
        }

	    return result;
    }

    @AuraEnabled
    public static List<IncidentChargeCardManagerController.Option> getCategories()
    {
        return IncidentSectionsController.getCategories();
    }

    @AuraEnabled
    public static Map<String, List<IncidentChargeCardManagerController.Option>> getCategoryMap()
    {
        return IncidentSectionsController.getCategoryMap();
    }

    @AuraEnabled
    public static FindUserController.FindUserResult findThumbtackUser(Decimal userId)
    {
        Map<String, FindUserController.FindUserResult> users = findThumbtackUsers(new Set<Decimal>{userId}, new Set<String>());

        if(!users.isEmpty())
        {
            return users.values()[0];
        }

        return null;
    }

    public static Map<String, FindUserController.FindUserResult> findThumbtackUsers(Set<Decimal> userIds, Set<String> emails)
    {
        Map<String, FindUserController.FindUserResult> users = new Map<String, FindUserController.FindUserResult>();

        List<Contact> contacts = [SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
                Account.BillingState, FirstName, LastName, Phone FROM Contact WHERE usr_user_id__c IN :userIds OR Email IN :emails];

        if(!contacts.isEmpty())
        {
            for(Contact c : contacts)
            {
	            if(c.usr_user_id__c != null)
	            {
		            users.put(String.valueOf(c.usr_user_id__c), new FindUserController.FindUserResult(c, null));
	            }

	            if(String.isNotBlank(c.Email))
	            {
		            users.put(c.Email.toLowerCase(), new FindUserController.FindUserResult(c, null));
	            }
            }
        }
        else
        {
            List<becquerel_tt_user_for_tack__x> extUsers = null;

            if(!Test.isRunningTest())
            {
                extUsers = [SELECT Id, sav_business_name__c, usr_last_name__c, usr_first_name__c,
                        usr_email__c, usr_user_id__c, phn_phone_number__c, usa_state__c, user_type__c
                        FROM becquerel_tt_user_for_tack__x
                        WHERE usr_user_id__c IN :userIds ];
            }
            else
            {
                if(userIds.contains(11112))
                {
                    extUsers = new List<becquerel_tt_user_for_tack__x> {
                            new becquerel_tt_user_for_tack__x(usr_last_name__c = 'Pro',
                                    usr_user_id__c = 11112, usr_first_name__c = 'Test')};
                }
                else
                {
                    extUsers = new List<becquerel_tt_user_for_tack__x>();
                }
            }

            if(!extUsers.isEmpty())
            {
                for(becquerel_tt_user_for_tack__x eu : extUsers)
                {
                    users.put(String.valueOf(eu.usr_user_id__c), new FindUserController.FindUserResult(null, eu));

	                if(String.isNotBlank(eu.usr_email__c))
	                {
		                users.put(eu.usr_email__c, new FindUserController.FindUserResult(null, eu));
	                }
                }
            }
        }

        return users;
    }

    @AuraEnabled
    public static ResponseUtility createGoodSamaritanIncidentExistingUser(MIIncident__c incident, String caseId, becquerel_tt_user_for_tack__x user, Boolean isPro)
    {
	    ResponseUtility response = new ResponseUtility(true);
		Contact c = null;

	    try
	    {
		    c = createNewAccountContact(user.usr_email__c, user.usr_first_name__c, user.usr_last_name__c,
				    isPro ? ttRTId : cRTId, user.usr_user_id__c);

		    response.record = createGoodSamaritanIncident(incident, caseId, isPro, c);
	    }
	    catch (Exception ex)
	    {
		    response.success = false;
		    response.error = ex.getMessage();
	    }

	    return  response;
    }

    @AuraEnabled
    public static ResponseUtility createGoodSamaritanIncidentExistingContact(MIIncident__c incident, String caseId, Contact c, Boolean isPro)
    {
	    ResponseUtility response = new ResponseUtility(true);

	    try
	    {
            response.record = createGoodSamaritanIncident(incident, caseId, isPro, c);
	    }
	    catch (Exception ex)
	    {
		    response.success = false;
		    response.error = ex.getMessage();
	    }

	    return  response;
    }

    @AuraEnabled
    public static ResponseUtility createGoodSamaritanIncidentNewUser(MIIncident__c incident, String caseId, String email, String firstName, String lastName, Boolean isPro)
    {
        List<Contact> contacts = null;
        Contact c = null;
	    ResponseUtility response = new ResponseUtility(true);
	    Savepoint sp = Database.setSavepoint();

	    try
	    {
		    if (String.isNotBlank(email))
		    {
			    contacts = [
					    SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
							    Account.BillingState, FirstName, LastName, Phone
					    FROM Contact
					    WHERE Email = :email
			    ];

			    //Check external data for user record if not in Salesforce
			    if (contacts.isEmpty())
			    {
				    List<becquerel_tt_user_for_tack__x> users = null;

				    if (!Test.isRunningTest())
				    {
					    users = [
							    SELECT Id, sav_business_name__c, usr_last_name__c, usr_first_name__c,
									    usr_email__c, usr_user_id__c, phn_phone_number__c, usa_state__c, user_type__c
							    FROM becquerel_tt_user_for_tack__x
							    WHERE usr_email__c = :email
					    ];
				    }
				    else
				    {
					    users = new List<becquerel_tt_user_for_tack__x>
					    {
							    new becquerel_tt_user_for_tack__x(usr_last_name__c = 'Pro',
									    usr_user_id__c = 11112, usr_first_name__c = 'Test')
					    };
				    }

				    if (!users.isEmpty())
				    {
					    //Check if user is in Salesforce with a different email address
					    if (users[0].usr_user_id__c != null && users[0].usr_user_id__c > 0)
					    {
						    contacts = [
								    SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
										    Account.BillingState, FirstName, LastName, Phone
								    FROM Contact
								    WHERE usr_user_id__c = :users[0].usr_user_id__c
						    ];

						    if (!contacts.isEmpty())
						    {
							    c = contacts[0];
						    }
					    }

					    if (c == null)
					    {
						    c = createNewAccountContact(users[0].usr_email__c, users[0].usr_first_name__c, users[0].usr_last_name__c,
								    isPro ? ttRTId : cRTId, users[0].usr_user_id__c);
						    c.Phone = users[0].phn_phone_number__c;
					    }
				    }
			    }
			    else
			    {
				    c = contacts[0];
			    }
		    }

		    //No contacts found by email, create new contact
		    if (c == null)
		    {
			    c = createNewAccountContact(email, firstName, lastName, isPro ? ttRTId : cRTId, null);
		    }

		    response.record = createGoodSamaritanIncident(incident, caseId, isPro, c);
	    }
	    catch (Exception ex)
	    {
		    if(sp != null)
		    {
			    Database.rollback(sp);
		    }

		    response.success = false;
		    response.error = ex.getMessage();
	    }

	    return response;
    }

    public static Contact createNewAccountContact(String email, String first, String last, Id acctRecType, Decimal userId)
    {
        Account acct = new Account(Name = String.format('{0} {1}', new List<String> {first, last}),
                usr_first_name__c = first, usr_last_name__c = last, usr_email__c = email, RecordTypeId = acctRecType);
        List<Contact> contacts = null;
        List<User> owners = [SELECT Id FROM User WHERE FirstName = 'tack' AND LastName = 'bot'];

        if (userId != null && userId > 0)
        {
            acct.usr_user_id__c = userId;
        }

        if(!owners.isEmpty())
        {
            acct.OwnerId = owners[0].Id;
        }

        insert acct;

        contacts = [SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
                Account.BillingState, FirstName, LastName, Phone FROM Contact WHERE AccountId =: acct.Id];

        /*
        //Check if contact is created. If not, create contact. Account Trigger code doesn't create contact if usr id is not specified
        if(contacts.isEmpty())
        {
            Contact cont = new Contact(AccountId = acct.Id, FirstName = acct.usr_first_name__c, LastName = acct.usr_last_name__c,
                    Email = acct.usr_email__c, usr_user_id__c = acct.usr_user_id__c);

            if (acct.RecordTypeId == cRTId)
            {
                cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            }
            else
            {
                cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
            }

            insert cont;

            contacts = [SELECT Id, Name, Email, usr_user_id__c, Account.Name, AccountId, Account.BillingCity, RecordType.Name,
                    Account.BillingState, FirstName, LastName, Phone FROM Contact WHERE AccountId =: acct.Id];
        }*/

        return contacts[0];
    }

    private static MIIncident__c createGoodSamaritanIncident(MIIncident__c incident, String caseId, Boolean isPro, Contact c)
    {
	    Case cs = getCaseValues(caseId);

	    incident.RecordTypeId = miRecordTypeId;
	    incident.Name = 'Good samaritan report for ' + c.Name;
	    incident.Status__c = 'New';
	    incident.FirstCaseCreatedDate__c = cs.CreatedDate;
	    incident.FirstCaseTransferredtoMIDate__c = cs.TransferredtoMI__c;

	    if (isPro)
	    {
		    incident.ProAccount__c = c.AccountId;
		    incident.ProContact__c = c.Id;
		    incident.pro_user_id__c = c.usr_user_id__c != null ? String.valueOf(c.usr_user_id__c) : null;
		    incident.ProEmail__c = c.Email;
		    incident.ProPhone__c = c.Phone;
		    //cs.MICasePrimaryPro__c = true;
	    }
	    else
	    {
		    incident.CustomerAccount__c = c.AccountId;
		    incident.CustomerContact__c = c.Id;
		    incident.customer_id__c = c.usr_user_id__c != null ? String.valueOf(c.usr_user_id__c) : null;
		    incident.CustomerEmail__c = c.Email;
		    incident.CustomerPhone__c = c.Phone;
		    //cs.MICasePrimaryCustomer__c = true;
	    }

	    if (incident.OwnerId == null)
	    {
		    incident.OwnerId = marketplaceIntegrity.Id;
	    }

	    insert incident;

	    cs.Description = 'Primary case of ' + c.Name + ' for ' + incident.Name;
	    cs.Incident__c = incident.Id;
	    cs.OwnerId = incident.OwnerId;
	    update cs;

	    return incident;
    }

    @AuraEnabled
    public static List<Group> getQueues()
    {
        return Database.query('SELECT Id, Name FROM Group WHERE Type = \'Queue\' AND Name IN (' + Label.MIIncidentBidCheckQueues + ')');
    }
}