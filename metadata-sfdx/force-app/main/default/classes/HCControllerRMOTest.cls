/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2017-04-26  Kristin Hasna     Created as part of the Help Center backend
									   rearchitecture, copied from HCControllerTest
1.1       11/21/17      pcoleman       Modified requestACall function to use Queueable instead of JSONObject trigger
 =======+===========+=================+=================================*/
@isTest
private class HCControllerRMOTest {

	@isTest(SeeAllData=true) //justification (KB Article Lookup and Config Records)
	private static void testConstructor() {

		PublicArticle__kav[] kb = [SELECT Id,KnowledgeArticleId From PublicArticle__kav WHERE IsVisibleInPkb = true AND PublishStatus ='Online' AND Language = 'en_US' LIMIT 1];
		System.runAs([SELECT Id FROM User WHERE IsActive=true AND Profile.Name='System Administrator' LIMIT 1][0])
		{
			Test.startTest();
			PageReference pageRef = Page.HCPageRMO;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('ar',kb.isEmpty()?'':kb[0].KnowledgeArticleId);
			HCControllerRMO cxt = new HCControllerRMO();
			cxt.initialize();
			//code coverages for query string parms in controller constructor
			ApexPages.currentPage().getParameters().put('vw','sg');
			cxt = new HCControllerRMO();
			ApexPages.currentPage().getParameters().put('vw','pg');
			cxt = new HCControllerRMO();
			ApexPages.currentPage().getParameters().put('vw','vd');
			cxt = new HCControllerRMO();
			try{HCControllerRMO.getProductFeedbackPickLists();} catch(Exception e) {}
			Test.stopTest();
		}
	}

	/**
	* @author Paul Coleman
	* @date 2017-11-27
	* @description Test that a work item is created when no account matches the input data from Help Center.
	*/
	@isTest
	private static void testCreateCallRequestWorkitem() {

		// create pseudo Lead record for Queueable processing
		Map<String,String> leadMap = new Map<String, String>{
				'Email' => 'test@tester.com',
				'RequestACallPhone__c' => '88888888887'
		};

		User testUser = [SELECT Id,Name FROM User WHERE Profile.Name = 'Thumbtack Help Profile' AND IsActive=true LIMIT 1];
		System.runAs(testUser)
		{

			Test.startTest();

			HCControllerRMO.createCallRequest( JSON.serialize( leadMap ) );

			Test.stopTest();
		}

		System.assertEquals( 1, [SELECT count() FROM WorkItem__c WHERE pro_email__c = :leadMap.get('Email')], 'No WorkItem inserted after Queueable action');
	}

	/**
	* @author Paul Coleman
	* @date 2017-11-27
	* @description Test that an account is updated with EnrollmentCallbackDateTime__c after request a call is submitted from the help center.
	*/
	@isTest
	private static void testCreateCallRequestAccountUpdateMinimal() {

		becquerel_tt_user_for_tack__x tackUser = BecquerelUtility.createTestExternalUsers( 1, true )[0];
		Account testAccount = TestUtilities.CORE_ACCOUNT.clone();

		//create test Account with remote object match
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			testAccount.usr_user_id__c = tackUser.usr_user_id__c;
			testAccount.user_pk_id__c = String.valueOf(tackUser.user_pk_id__c);
			testAccount.usr_email__c = tackUser.usr_email__c;
			testAccount.sav_phn_phone_number__c = tackUser.sav_phn_phone_number__c;
			testAccount.sav_notifications_phn_phone_number__c = tackUser.sav_notif_phn_phone_number__c;
			testAccount.Phone = tackUser.phn_phone_number__c;
			testAccount.EnrollmentCallbackDateTime__c = NULL;
			insert testAccount;
		}

		Test.startTest();

		// create pseudo Lead record for Queueable processing
		Map<String,String> leadMap = new Map<String, String>{
				'Email' => testAccount.usr_email__c,
				'RequestACallPhone__c' => testAccount.Phone
		};

		System.runAs(TestUtilities.USER_TACK_BOT)
		{   // Queueable uses SOSL to find a Matching Account, verify test context can see newly inserted account
			Test.setFixedSearchResults(new String[]{ testAccount.Id });
			String searchTerm = String.join( leadMap.values(), ' OR ' ).removeEnd(' OR ') ;
			System.debug( LoggingLevel.INFO, 'SEARCH TERM: ' + searchTerm );

			// can Tackbot find the target account?
			Account[] locatedAccounts = (Account[])[FIND :searchTerm IN ALL FIELDS RETURNING Account(Id, usr_user_id__c, usr_email__c, user_pk_id__c, sav_notifications_phn_phone_number__c, sav_phn_phone_number__c LIMIT 1) ][0];
			System.debug( LoggingLevel.INFO, locatedAccounts );
			System.assert( !locatedAccounts.isEmpty(), 'Test Account NOT found from SOSL FIND');
		}


		// Help Center Site's Guest User
		User testUser = [SELECT Id,Name FROM User WHERE Profile.Name = 'Thumbtack Help Profile' AND IsActive=true LIMIT 1];
		System.runAs(testUser)
		{
			HCControllerRMO.createCallRequest(JSON.serialize(leadMap));
		}

		Test.stopTest();

		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			// did the guest user (site profile) update the Account via Queueable?
			Account afterUpdateAccount = [SELECT EnrollmentCallbackDateTime__c FROM Account WHERE Id = :testAccount.Id];
			System.assertNotEquals( NULL, afterUpdateAccount.EnrollmentCallbackDateTime__c, 'Account EnrollmentCallbackDateTime__c is NULL after Queueable action');

		} //end RunAs
	}


	/**
	* @author Paul Coleman
	* @date 2017-11-27
	* @description Test that an account is updated with EnrollmentCallbackDateTime__c after request a call is submitted from the help center.
	*/
	@isTest
	private static void testCreateCallRequestAccountUpdateAllParms() {

		becquerel_tt_user_for_tack__x tackUser = BecquerelUtility.createTestExternalUsers( 1, true )[0];
		Account testAccount = TestUtilities.CORE_ACCOUNT.clone();

		//create test Account with remote object match
		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			testAccount.usr_user_id__c = tackUser.usr_user_id__c;
			testAccount.user_pk_id__c = String.valueOf(tackUser.user_pk_id__c);
			testAccount.usr_email__c = tackUser.usr_email__c;
			testAccount.sav_phn_phone_number__c = tackUser.sav_phn_phone_number__c;
			testAccount.sav_notifications_phn_phone_number__c = tackUser.sav_notif_phn_phone_number__c;
			testAccount.Phone = tackUser.phn_phone_number__c;
			testAccount.EnrollmentCallbackDateTime__c = NULL;
			insert testAccount;
		}

		Test.startTest();

		// create pseudo Lead record for Queueable processing
		Map<String,String> leadMap = new Map<String, String>{
				'Email' => testAccount.usr_email__c,
				'RequestACallPhone__c' => testAccount.Phone,
				'RequestACallDayOfWeek__c' => 'Tuesday',
				'RequestACallTimeframe__c' => '9:00 AM – 10:00 AM',
				'TimeZoneFromAdmin__c' => 'America/Denver'
		};

		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			Test.setFixedSearchResults(new String[]{ testAccount.Id });
		}


		// Help Center Site's Guest User
		User testUser = [SELECT Id,Name FROM User WHERE Profile.Name = 'Thumbtack Help Profile' AND IsActive=true LIMIT 1];
		System.runAs(testUser)
		{
			HCControllerRMO.createCallRequest(JSON.serialize(leadMap));
		}

		Test.stopTest();

		System.runAs(TestUtilities.USER_TACK_BOT)
		{
			// did the guest user (site profile) update the Account via Queueable?
			Account afterUpdateAccount = [SELECT EnrollmentCallbackDateTime__c FROM Account WHERE Id = :testAccount.Id];
			System.assertNotEquals( NULL, afterUpdateAccount.EnrollmentCallbackDateTime__c, 'Account EnrollmentCallbackDateTime__c is NULL after Queueable action');

		} //end RunAs
	}


	@isTest(SeeAllData=true) //justification, readonly KB searches
	private static void testArticleRemoteActionMethods()
	{
		PublicArticle__kav[] kb = [SELECT Id,KnowledgeArticleId,Title From PublicArticle__kav WHERE IsVisibleInPkb = true AND PublishStatus ='Online' AND Language = 'en_US' AND Title = 'Add a pro badge to my website' LIMIT 1];
		System.runAs([SELECT Id FROM User WHERE IsActive=true AND Profile.Name='System Administrator' LIMIT 1][0]) {
			System.assert(HCControllerRMO.searchArticles(kb.isEmpty()?'bogus':kb[0].Title,null,null,5) != null, 'Article json string is null.');
		}
	}



}