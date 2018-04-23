/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+=========================================
1.0       10/03/2017  Paul Coleman       Created to consolidate reuseable Test functions
1.1       12/19/2017  Paul Coleman       Linked USER_TACK_BOT SA test user to TackBotUtility
========+============+=================+========================================*/
@IsTest
public class TestUtilities
{
    private TestUtilities() {} //all static methods to support testing

    public static final Account CORE_ACCOUNT;
    public static final User USER_TACK_BOT = TackBotUtility.getTackBotUser();
    public static final Map<String,Id> RT_MAP = new Map<String, Id>();
    public static final Map<String,Id> Q_MAP = new Map<String, Id>();

    //thumbtack usr_user_id test constants
    public static final Decimal PRO_USR_USER_ID = BecquerelUtility.PRO_USER_ID;
    public static final Decimal CUSTOMER_USR_USER_ID = BecquerelUtility.CUSTOMER_USER_ID;
    public static final String PRO_USR_USER_ID_STR = String.valueOf(PRO_USR_USER_ID);
    public static final String CUSTOMER_USR_USER_ID_STR = String.valueOf(CUSTOMER_USR_USER_ID);

    //thumbtack user_pk_id test constants
    public static final Decimal PRO_USER_PK_ID_INT = BecquerelUtility.PRO_USER_PK_ID;
    public static final Decimal CUSTOMER_USER_PK_ID_INT = BecquerelUtility.CUSTOMER_USER_PK_ID;
    public static final String PRO_USER_PK_ID = String.valueOf(PRO_USER_PK_ID_INT);
    public static final String CUSTOMER_USER_PK_ID = String.valueOf(CUSTOMER_USER_PK_ID_INT);

    //core thumbtack user map, based on JIT User provisioning profile
    public static final Map<String,String> USER_ATTRIBUTE_MAP = new Map<String, String>
    {
            'email'=> BecquerelUtility.PRO_EMAIL,
            'first_name'=>BecquerelUtility.PRO_FIRST_NAME,
            'last_name'=>BecquerelUtility.PRO_LAST_NAME,
            'timezone'=>'America/Los_Angeles',
            'user_id'=>PRO_USR_USER_ID_STR,
            'user_pk_id'=>PRO_USER_PK_ID,
            'user_type'=>'Pro',
            'business_name'=>BecquerelUtility.PRO_FULL_NAME
    };

    // Reusable RecordType Id constants
    public static final Id MI_RECORD_TYPE_ID;
    public static final Id MI_CONFIDENTIAL_RECORD_TYPE_ID;

    public static final Id ACCOUNT_PRO_RECORD_TYPE_ID;
    public static final Id ACCOUNT_CUSTOMER_RECORD_TYPE_ID;

    public static final Id CONTACT_PRO_RECORD_TYPE_ID;
    public static final Id CONTACT_CUSTOMER_RECORD_TYPE_ID;

    public static final Id CASE_MI_RECORD_TYPE_ID;
    public static final Id CASE_CS_RECORD_TYPE_ID;

    public static final Id CSAT_CSAT_RECORD_TYPE_ID;

    // Reusable Queue Id constants
    public static final Id PROACTIVE_MI_QUEUE_ID;
    public static final Id MI_QUEUE_ID;

    static
    {
        // Load up RecordTypes into a Map
        for(RecordType rt: [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE IsActive=true])
        {
            RT_MAP.put(rt.SobjectType.toLowerCase() + '_' + rt.DeveloperName.toLowerCase(), rt.Id);
        }
        System.debug(LoggingLevel.FINEST, JSON.serialize(RT_MAP));

        // Load up Queue Ids into a Map
        for(Group q: [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue'])
        {
            Q_MAP.put(q.DeveloperName.toLowerCase(), q.Id);
        }
        System.debug(LoggingLevel.FINEST, JSON.serialize(Q_MAP));

        // Reusable RecordType Id Assignments
        // MIT / MTS
        MI_RECORD_TYPE_ID = RT_MAP.get('miincident__c_miincident');
        MI_CONFIDENTIAL_RECORD_TYPE_ID = RT_MAP.get('miincident__c_confidential');

        // ACCOUNT
        ACCOUNT_PRO_RECORD_TYPE_ID = RT_MAP.get('account_thumbtackpro');
        ACCOUNT_CUSTOMER_RECORD_TYPE_ID = RT_MAP.get('account_customer');

        // CONTACT
        CONTACT_PRO_RECORD_TYPE_ID = RT_MAP.get('contact_thumbtackpro');
        CONTACT_CUSTOMER_RECORD_TYPE_ID = RT_MAP.get('contact_customer');

        // CASE
        CASE_MI_RECORD_TYPE_ID = RT_MAP.get('case_marketplaceintegrity');
        CASE_CS_RECORD_TYPE_ID = RT_MAP.get('case_customersupport');

        // CSAT
        CSAT_CSAT_RECORD_TYPE_ID = RT_MAP.get('csat__c_customersatisfaction');

        // Reusable Queue Id Assignments
        PROACTIVE_MI_QUEUE_ID = Q_MAP.get('proactivemiqueue');
        MI_QUEUE_ID = Q_MAP.get('marketplaceintegrity');

        CORE_ACCOUNT = new Account(Name = USER_ATTRIBUTE_MAP.get('business_name'),
                usr_email__c = USER_ATTRIBUTE_MAP.get('email'),
                usr_first_name__c = USER_ATTRIBUTE_MAP.get('first_name'),
                usr_last_name__c = USER_ATTRIBUTE_MAP.get('last_name'),
                usr_timezone__c = USER_ATTRIBUTE_MAP.get('timezone'),
                user_pk_id__c = USER_ATTRIBUTE_MAP.get('user_pk_id'),
                usr_user_id__c = Decimal.valueOf(USER_ATTRIBUTE_MAP.get('user_id')),
                RecordTypeId = ACCOUNT_PRO_RECORD_TYPE_ID);

    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches all test Account records (with child Contact).
    * @param String A profile name.
    * @return User An active Salesforce User matching the profileName parm.
    */
    public static User getTestUserByProfile(String profileName)
    {
        return [SELECT Id FROM User WHERE Profile.Name = :profileName AND IsActive = true LIMIT 1];
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches all test Account records (with child Contact).
    * @return Map<Decimal,Account> A Thumbtack user id => Account map of the queried records.
    */
    public static Map<Decimal,Account> getAllTestAccounts()
    {
        return getTestAccounts( (Set<Id>)NULL );
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches a test Account record (with child Contact).
    * @return Account A single test account.
    */
    public static Account getTestAccountWithContact()
    {
        Map<Decimal,Account> accountMap = getTestAccounts( (Set<Id>)NULL );
        return ( accountMap.isEmpty() )? NULL: accountMap.values()[0];
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches a test Account record (with child Contact).
    * @parm Id An Account Id for the SOQL filter. NOTE: Passing a null Id set fetches a single Account.
    * @return Account A single test account by record Id.
    */
    public static Account getTestAccountWithContact( Id accountId )
    {
        Set<Id> uniqueIds = ( NULL == accountId )? new Set<Id>():  new Set<Id>( new Id[]{accountId} );
        Map<Decimal,Account> accountMap = getTestAccounts( ( uniqueIds.isEmpty() )? (Set<Id>)NULL : uniqueIds  );
        return ( accountMap.isEmpty() )? NULL: accountMap.values()[0];
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches a test Account record (with child Contact).
    * @parm Id An Account whose Id will be used for the SOQL filter. NOTE: Passing a null Account fetches a single test Account.
    * @return Account A single test account by Account record Id.
    */
    public static Account getTestAccountWithContact( Account a )
    {
        Set<Id> uniqueIds = ( NULL == a )? new Set<Id>():  new Set<Id>( new Id[]{a.Id} );
        Map<Decimal,Account> accountMap = getTestAccounts( ( uniqueIds.isEmpty() )? (Set<Id>)NULL : uniqueIds  );
        return ( accountMap.isEmpty() )? NULL: accountMap.values()[0];
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches test Account records (with child Contact). Passing a null Id set fetches all test Accounts.
    * @parm Id[] A list of Account Ids for the SOQL filter
    * @return Map<Decimal,Account> A Thumbtack user id => Account map of the queried records.
    */
    public static Map<Decimal,Account> getTestAccounts( Id[] accountIds )
    {
        Set<Id> uniqueIds = new Set<Id>();
        for( Id i: (NULL == accountIds)? new Id[0]: accountIds) {
            uniqueIds.add(i);
        }
        return getTestAccounts( ( uniqueIds.isEmpty() )? (Set<Id>)NULL : uniqueIds );
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches test Account records (with child Contact). NOTE: Passing a null Account List fetches all test Accounts.
    * @parm Id[] A list of Account Ids for the SOQL filter
    * @return Map<Decimal,Account> A Thumbtack user id => Account map of the queried records.
    */
    public static Map<Decimal,Account> getTestAccounts( Account[] accounts )
    {
        Set<Id> uniqueIds = new Set<Id>();
        for( Account a: (NULL == accounts)? new Account[0]: accounts) {
            uniqueIds.add(a.Id);
        }
        return getTestAccounts( ( uniqueIds.isEmpty() )? (Set<Id>)NULL : uniqueIds );
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Fetches test Account records (with child Contact). Passing a null Id set fetches all test Accounts.
    * @return Map<Decimal,Account> A Thumbtack user id => Account map of the queried records.
    */
    public static Map<Decimal,Account> getTestAccounts( Set<Id> accountIds )
    {
        Map<Decimal,Account> result = new Map<Decimal, Account>();
        Set<Id> recordIds = ( NULL == accountIds || accountIds.isEmpty() )? new Set<Id>(): accountIds;
        if ( recordIds.isEmpty()  )
        {
            // get all test Account Ids
            for( Account a: [SELECT Id FROM Account] )
            {
                recordIds.add(a.Id);
            }
        }

        // NOTE: add fields to the SELECT below for specific test scenarios not addressed by the current field list
        for(Account a : [ SELECT Id,
                Name,
                MIOpenIncident__c,
                SendOverbudgetEmail__c,
                LastSyncedWithDataPlatform__c,
                RecordTypeId,
                RecordType.DeveloperName,
                RecordType.Name,
                usr_email__c,
                usr_user_id__c,
                user_pk_id__c,
                usr_first_name__c,
                usr_last_name__c,
                Phone,
                OwnerId,
                ( SELECT Id, Name, usr_user_id__c, user_pk_id__c, RecordTypeId, RecordType.Name, RecordType.DeveloperName, OwnerId, AccountId FROM Contacts )
                FROM Account
                WHERE RecordType.DeveloperName IN ('Customer', 'ThumbtackPro') AND Id IN :recordIds
        LIMIT :recordIds.size() ] )
        {
            result.put(a.usr_user_id__c, a);
        }

        return result;
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Insert four test Account records: two Pro and two Customer.
    * @return Account[] The inserted accounts.
    */
    public static Account[] insertFourCoreThumbtackUsers()
    {
        Account[] newAccounts = new Account[0];
        System.runAs( USER_TACK_BOT )
        {
            Account aPro = CORE_ACCOUNT.clone();
            Account aPro2 = CORE_ACCOUNT.clone();
            Account aCustomer = CORE_ACCOUNT.clone();
            Account aCustomer2 = CORE_ACCOUNT.clone();
            // Override field values as necessary
            aPro2.usr_first_name__c = '_2' + aPro.usr_first_name__c; aPro2.usr_last_name__c = '_2' + aPro.usr_last_name__c;  aPro.Name = aPro2.usr_first_name__c + ' ' + aPro2.usr_last_name__c; aPro2.usr_user_id__c = aPro.usr_user_id__c + 1; aPro2.user_pk_id__c = aPro.user_pk_id__c + '2'; aPro2.usr_email__c = '_2' + aPro.usr_email__c;
            aCustomer.RecordTypeId = ACCOUNT_CUSTOMER_RECORD_TYPE_ID; aCustomer.usr_first_name__c = BecquerelUtility.CUSTOMER_FIRST_NAME; aCustomer.usr_last_name__c = BecquerelUtility.CUSTOMER_LAST_NAME; aCustomer.Name = BecquerelUtility.CUSTOMER_FULL_NAME; aCustomer.usr_user_id__c = TestUtilities.CUSTOMER_USR_USER_ID; aCustomer.user_pk_id__c = TestUtilities.CUSTOMER_USER_PK_ID; aCustomer.usr_email__c = BecquerelUtility.CUSTOMER_EMAIL;
            aCustomer2.RecordTypeId = ACCOUNT_CUSTOMER_RECORD_TYPE_ID; aCustomer2.usr_first_name__c = '2_' + aCustomer.usr_last_name__c; aCustomer2.usr_last_name__c = '2_' + aCustomer2.usr_last_name__c; aCustomer2.Name = aCustomer2.usr_first_name__c + ' ' + aCustomer2.usr_last_name__c; aCustomer2.usr_user_id__c = aCustomer.usr_user_id__c + 1; aCustomer2.user_pk_id__c = aCustomer.user_pk_id__c + '2'; aCustomer2.usr_email__c = '_2' + aCustomer.usr_email__c;
            newAccounts =  new Account[]{ aPro, aPro2, aCustomer, aCustomer2 };
            insert newAccounts;
            Test.setFixedSearchResults(new String[]{ aPro.Id, aPro2.Id, aCustomer.Id, aCustomer2.Id });
        }
        return newAccounts;
    }


    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Insert four test Account records: two Pro and two Customer.
    * @return Account[] The inserted accounts.
    */
    public static Map<Decimal,Account> doCoreAccountSetup()
    {
        insertFourCoreThumbtackUsers();
        return getAllTestAccounts();
    }
}