/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved. 

Version      Date          Author            	Description
========+============+====================+==============================================
.....previous versions in GIT
2.0       2018-02-28	 Meena Pisupati		Insert or Update Routing Profile for Prospecting Enrollments upgraded to latest API version
2.1		  2018-02-15	 Jared Kennington	Refactored to new trigger structure
========+============+====================+==============================================*/

public class EnrollmentTriggerHandler extends ThumbtackTriggerHandlerBase
{
	//Recursion prevention flags
	private static Boolean isInBeforeProcessing = false;
	private static Boolean isInBeforeInsertProcessing = false;
	private static Boolean isInBeforeUpdateProcessing = false;
	private static Boolean isInAfterInsertProcessing = false;
	private static Boolean isInAfterUpdateProcessing = false;

	private static final Id quotingServiceRecordType = Schema.Sobjecttype.Enrollment__c.getRecordTypeInfosByName().get('Quoting Service').getRecordTypeId();


	public override void doBeforeProcessing(ThumbtackTriggerContext ctx)
	{
		if (!isInBeforeProcessing)
		{
			isInBeforeProcessing = true;

			try
			{
				doBefore((Enrollment__c[]) ctx.newRecords, (Map<Id, Enrollment__c>) ctx.oldRecordsMap);
				isInBeforeProcessing = false;
			}
			finally
			{
				isInBeforeProcessing = false;
			}
		}

	}

	public override void onBeforeInsert(ThumbtackTriggerContext ctx)
	{
		if (!isInBeforeInsertProcessing)
		{
			isInBeforeInsertProcessing = true;
			try
			{
				this.relateEnrollmentToMarket(ctx.newRecords, null);
				this.relateEnrollmentToAccount(ctx.newRecords);
			}
			finally
			{
				isInBeforeInsertProcessing = false;
			}
		}
	}

	public override void onBeforeUpdate(ThumbtackTriggerContext ctx)
	{
		if (!isInBeforeUpdateProcessing)
		{
			isInBeforeUpdateProcessing = true;

			try
			{
				this.relateEnrollmentToMarket((Enrollment__c[]) ctx.newRecords, (Map<Id, Enrollment__c>) ctx.oldRecordsMap);
				this.relateEnrollmentToService((Enrollment__c[]) ctx.newRecords, (Map<Id, Enrollment__c>) ctx.oldRecordsMap);
				this.relateEnrollmentToAccount((Enrollment__c[]) ctx.newRecords);
			}
			finally
			{
				isInBeforeUpdateProcessing = false;
			}
		}
	}

	public override void onAfterInsert(ThumbtackTriggerContext ctx)
	{
		if (!isInAfterInsertProcessing)
		{
			isInAfterInsertProcessing = true;

			try
			{
				this.insertRoutingProfile((Enrollment__c[]) ctx.newRecords);
				isInAfterInsertProcessing = false;
			}
			finally
			{
				isInAfterInsertProcessing = false;
			}
		}
	}

	public override void onAfterUpdate(ThumbtackTriggerContext ctx)
	{
		if (!isInAfterUpdateProcessing)
		{
			isInAfterUpdateProcessing = true;

			try
			{
				EnrollmentEventLogUtility.handleObjectChanges(ctx.newRecords, ctx.oldRecordsMap);
				//check if funnel step is prospecting or pre-onboaring and call updateRoutingProfile method
				this.checkFunnelSteps(ctx.newRecords, (Map<Id, Enrollment__c>)ctx.oldRecordsMap);
			}
			finally
			{
				isInAfterUpdateProcessing = false;
			}
		}
	}

	////////////////////////      BEGIN INNER METHODS     ////////////////////////

	private void checkFunnelSteps(List<Enrollment__c> triggerNew, Map<Id, Enrollment__c> triggerOldMap)
	{
		//changing this array
		List<Enrollment__c> newEnrollUpdate = new List<Enrollment__c>();
		Map<Id, Enrollment__c> oldEnrollMapUpdate = new Map<Id, Enrollment__c>();
		for(Enrollment__c en: triggerNew)
		{
			Enrollment__c oldEn = triggerOldMap.get(en.id);
			if((oldEn.SalesRep__c != en.SalesRep__c && en.FunnelStep__c == 'Prospecting') || (oldEn.FunnelStep__c == 'Prospecting' && en.FunnelStep__c == 'Pre-Onboarding'))
			{
				newEnrollUpdate.add(en);
				oldEnrollMapUpdate.put(oldEn.Id, oldEn);
			}
		}
		if(!newEnrollUpdate.isEmpty() && !oldEnrollMapUpdate.isEmpty())
		{
			this.updateRoutingProfile(newEnrollUpdate,oldEnrollMapUpdate);
		}
	}    
    
	private void doBefore(Enrollment__c[] triggerNew, Map<Id, Enrollment__c> triggerOldMap)
	{
        Schema.DescribeFieldResult outreachType = Enrollment__c.outreach_type__c.getDescribe();
		Map<String,String> outreachTypeMap = new Map<String,String>();

        for(Schema.PicklistEntry v : outreachType.getPicklistValues())
		{
            outreachTypeMap.put(v.getValue(), v.getLabel());
        }

		for(Enrollment__c e : triggerNew)
		{
			//Checks on field values that are used to label Enrollment Name - MP
			if(e.Name == null)
			{
				e.Name = '';

				if(e.AccountName__c != null)
				{
					e.Name = e.AccountName__c;
				}
				else if (e.FirstName__c != null || e.LastName__c != null)
				{
					if (e.FirstName__c == null)
					{
						e.Name = e.LastName__c;
					}
					else if (e.LastName__c == null)
					{
						e.Name = e.FirstName__c;
					}
					else
					{
						e.Name = e.FirstName__c + ' ' + e.LastName__c;
					}
				}
				else if (e.BusinessName__c != null)
				{
					e.Name = e.BusinessName__c;
				}

				if(e.outreach_type__c != 'product_enabled' && e.outreach_type__c != 'early_enrollment')
				{
                    system.debug(LoggingLevel.WARN,'Outreach Type Label: ' +outreachTypeMap.get(e.outreach_type__c));
					e.Name += ' - '+outreachTypeMap.get(e.outreach_type__c);
                    system.debug(Logginglevel.FINEST,'Enrollment Name: '+e.Name);
				}
				else
				{
					e.Name += ' ' + e.rca_request_category_id__c + '-' + e.zip_cbsa_code__c;
				}

				if (e.Name.length() > 80)
				{
					e.Name = e.Name.substring(0, 80);
				}
			}
		}

        //Checks on Enrollment Outreach type - MP
        if(Trigger.isUpdate)
        {
	        Enrollment__c oldEnrollment;
	        for (Enrollment__c newEnrollment : triggerNew)
	        {
		        if (triggerOldMap != null)
		        {
			        oldEnrollment = triggerOldMap.get(newEnrollment.Id);
			        if (oldEnrollment.outreach_type__c != null && newEnrollment.outreach_type__c != oldEnrollment.outreach_type__c)
			        {
				        newEnrollment.outreach_type__c = oldEnrollment.outreach_type__c;
			        }
		        }
	        }
        }
	}

	private void relateEnrollmentToMarket(Enrollment__c[] triggerNew, Map<Id, Enrollment__c> triggerOldMap)
	{
		Enrollment__c[] enrollmentsToRelate = new Enrollment__c[0];
		String[] marketIds = new String[0];
		String[] categoryCbsa = new String[0];

		for (Enrollment__c newEnrollment : triggerNew)
		{
			Enrollment__c oldEnrollment;

			if (triggerOldMap != null)
			{
				oldEnrollment = triggerOldMap.get(newEnrollment.Id);
			}

			if ((oldEnrollment == null || (oldEnrollment != null && (newEnrollment.zip_cbsa_code__c != oldEnrollment.zip_cbsa_code__c || newEnrollment.rca_request_category_id__c != oldEnrollment.rca_request_category_id__c || newEnrollment.Market__c == null))) && newEnrollment.zip_cbsa_code__c != null && newEnrollment.rca_request_category_id__c != null)
			{
				enrollmentsToRelate.add(newEnrollment);
				marketIds.add(newEnrollment.rca_request_category_id__c + '-' + newEnrollment.zip_cbsa_code__c);
				categoryCbsa.add(newEnrollment.zip_cbsa_name__c);
			}
		}

		if (!marketIds.isEmpty())
		{
			Map<String, Id> marketMap = new Map<String, Id>();
			Map<String, Id> catGeoMap = new Map<String, Id>();
			Map<String, Market__c> newMarketMap = new Map<String, Market__c>();
			Enrollment__c[] enrollmentsStillNeedingMarket = new Enrollment__c[0];
			system.debug('marketIds: ' + marketIds);
			system.debug('categoryCbsa: ' + categoryCbsa);

			for (Market__c market : [Select Id, MarketID__c, CatGeo__c From Market__c Where MarketID__c IN :marketIds Or CatGeo__c IN :categoryCbsa])
			{
				if (String.isNotBlank(market.MarketID__c))
				{
					marketMap.put(market.MarketID__c, market.Id);
				}
				if (String.isNotBlank(market.CatGeo__c))
				{
					catGeoMap.put(market.CatGeo__c, market.Id);
				}
			}

			for (Enrollment__c newEnrollment : enrollmentsToRelate)
			{
				String marketId = newEnrollment.rca_request_category_id__c + '-' + newEnrollment.zip_cbsa_code__c;
				String marketName = newEnrollment.zip_cbsa_name__c + '-' + newEnrollment.zip_cbsa_name__c;

				if (marketMap.containsKey(marketId))
				{
					newEnrollment.Market__c = marketMap.get(marketId);
				}
				else if (catGeoMap.containsKey(marketName))
				{
					newEnrollment.Market__c = catGeoMap.get(newEnrollment.zip_cbsa_name__c);
				}
				else if(String.isNotBlank(newEnrollment.zip_cbsa_name__c) && String.isNotBlank(newEnrollment.zip_cbsa_code__c)
						&& String.isNotBlank(newEnrollment.outreach_type__c) && (newEnrollment.outreach_type__c != 'managed_account' && newEnrollment.outreach_type__c != 'pro_engagement' && newEnrollment.outreach_type__c != 'pro_onboarding') ) //using api name due to picklist restriction
				{
					if (!newMarketMap.containsKey(marketId))
					{
						newMarketMap.put(marketId, new Market__c(
								rca_name__c = newEnrollment.rca_name__c,
								zip_cbsa_name__c = newEnrollment.zip_cbsa_name__c,
								Deprioritized__c = false,
								TakeaLeadEnabled__c = true,
								rca_request_category_id__c = newEnrollment.rca_request_category_id__c,
								zip_cbsa_code__c = newEnrollment.zip_cbsa_code__c,
								outreach_type__c = newEnrollment.outreach_type__c
						));
					}

					enrollmentsStillNeedingMarket.add(newEnrollment);
				}
			}

			if (!newMarketMap.isEmpty())
			{
				insert newMarketMap.values();

				for (Enrollment__c newEnrollment : enrollmentsStillNeedingMarket)
				{
					String marketId = newEnrollment.rca_request_category_id__c + '-' + newEnrollment.zip_cbsa_code__c;
					newEnrollment.Market__c = newMarketMap.get(marketId).Id;
				}
			}
		}
	}

	private void relateEnrollmentToAccount(Enrollment__c[] triggerNew)
	{
		Map<String,Id> accountMap = new Map<String,Id>();
		Set<Decimal> userIds = new Set<Decimal> ();
		Enrollment__c[] enrollments = new Enrollment__c[0];
		Enrollment__c[] enrollmentsNeedingAccounts = new Enrollment__c[0];
		Map<String, Account> newAccountMap = new Map<String, Account> ();
		Map<String, Id> emailAccounts = new Map<String, Id>();
		String[] userEmails = new String[0];
		Map<Id,Enrollment__c> accountEnrollment = new Map<Id,Enrollment__c>();
        Account[] accountUpdateList = new Account[0];
        Map<Id,Id> accountAndManagerIds = new Map<Id,Id>();

		for (Enrollment__c enrollment : triggerNew)
		{
			if (enrollment.user_id__c != null && enrollment.Account__c == null)
			{
				userIds.add(Decimal.valueOf(enrollment.user_id__c));
				enrollments.add(enrollment);
				if(String.isNotEmpty(enrollment.Email__c)){System.debug('Add email: ' + enrollment.Email__c); userEmails.add(enrollment.Email__c);}
			}
		}

		for (Account Acc: [SELECT Id, usr_user_id__c, usr_email__c  FROM Account WHERE usr_user_id__c IN :userIds OR usr_email__c IN :userEmails])
		{
			if (Acc.usr_user_id__c != null && !accountMap.containsKey(String.valueOf(Acc.usr_user_id__c.intValue())))
			{
				accountMap.put(String.valueOf(Acc.usr_user_id__c.intValue()), Acc.Id);
			}
			else if(String.isNotEmpty(Acc.usr_email__c) && !emailAccounts.containsKey(Acc.usr_email__c))
			{
				emailAccounts.put(Acc.usr_email__c, Acc.Id);
			}
		}

		for (Enrollment__c enrollment : enrollments)
		{
			if(accountMap.containsKey(enrollment.user_id__c))
			{
				enrollment.Account__c = accountMap.get(enrollment.user_id__c);
                accountEnrollment.put(accountMap.get(enrollment.user_id__c), enrollment);     
			}
			else if(emailAccounts.containsKey(enrollment.Email__c))
			{
				enrollment.Account__c = emailAccounts.get(enrollment.Email__c);
                accountEnrollment.put(emailAccounts.get(enrollment.Email__c), enrollment);     
			}
			else
			{
				enrollmentsNeedingAccounts.add(enrollment);
				if (!newAccountMap.containsKey(enrollment.user_id__c))
				{
					newAccountMap.put(enrollment.user_id__c, new Account (
						Name = (String.isNotBlank(enrollment.BusinessName__c) && enrollment.BusinessName__c.length() > 80) ? enrollment.BusinessName__c.substring(0, 80) : enrollment.BusinessName__c,
						usr_user_id__c = Decimal.valueOf(enrollment.user_id__c),
						usr_first_name__c = enrollment.FirstName__c,
						usr_last_name__c = enrollment.LastName__c,
						usr_email__c = enrollment.Email__c,
						Phone = enrollment.Phone__c,
                        AccountManager__c = enrollment.AccountManager__c
					));
				}
			}
		}

        for(Enrollment__c en: accountEnrollment.values())
        {           
            if(NULL != en.AccountManager__c)
            {
				accountAndManagerIds.put(en.Account__c, en.AccountManager__c);
            }
        }
		for(Account a: [SELECT Id, AccountManager__c FROM Account WHERE Id IN :accountAndManagerIds.keySet()])
		{
			a.AccountManager__c = accountAndManagerIds.get(a.Id);
			accountUpdateList.add(a);
		}

		if (!newAccountMap.isEmpty()) {
			insert newAccountMap.values();
			for (Enrollment__c enrollment : enrollmentsNeedingAccounts)
			{
				Account acc = newAccountMap.get(enrollment.user_id__c);
				if (acc != null) { enrollment.Account__c = acc.Id; }
			}
		}
        
        if(!accountUpdateList.isEmpty())
        {
            update accountUpdateList;
        }
	}

	private void relateEnrollmentToService(Enrollment__c[] triggerNew, Map<Id, Enrollment__c> triggerOldMap)
	{
		Id serviceRT = Schema.Sobjecttype.Service__c.getRecordTypeInfosByName().get('Pro Assistance Service').getRecordTypeId();
		service__c[] servicesToAdd = new service__c[0];
		Map<Decimal,service__c> serviceMap = new Map<Decimal,service__c>();
		Map<String,Id> accountMap = new Map<String,Id>();
		Set<Decimal> userIds = new Set<Decimal> ();
		Enrollment__c[] enrollments = new Enrollment__c[0];

		for (Enrollment__c enrollment : triggerNew)
		{
			//check to see if these enrollments are 'Quoting service' and let them through
			if(enrollment.RecordTypeId == quotingServiceRecordType){ enrollments.add(enrollment); }
		}

		for (Enrollment__c enrollment : enrollments)
		{
			if (enrollment.user_id__c != null)
			{
				accountMap.put(enrollment.user_id__c, null);
				userIds.add(Decimal.valueOf(enrollment.user_id__c));
			}
			serviceMap.put(enrollment.sav_available_service_id__c,null);
		}

		for (Account Acc: [SELECT Id, usr_user_id__c FROM Account WHERE usr_user_id__c IN :userIds])
		{
			if (Acc.usr_user_id__c != null)
			{
				accountMap.put(String.valueOf(Acc.usr_user_id__c.intValue()), Acc.Id);
			}
		}

		for (service__c s : [SELECT id,sav_available_service_id__c FROM Service__c WHERE sav_available_service_id__c IN :serviceMap.keySet()])
		{
			serviceMap.put(s.sav_available_service_id__c,s);
		}

		for (Enrollment__c enrollment : enrollments)
		{
			if (enrollment.service__c == null)
			{
				if(serviceMap.keySet().contains(enrollment.sav_available_service_id__c) && serviceMap.get(enrollment.sav_available_service_id__c) != null)
				{
					enrollment.Service__c = enrollment.Service__c == null ? serviceMap.get(enrollment.sav_available_service_id__c).Id : enrollment.Service__c;
				}
				else
				{
					servicesToAdd.add(new service__c(
						RecordTypeId = serviceRT,
						ProAssistantSubscriptionType__c = enrollment.outreach_type__c,
						Name = enrollment.FirstName__c + ' ' + enrollment.LastName__c + ' ' + enrollment.user_id__c,
						PricingCalculator__c = enrollment.PricingURL__c,
						ProAssistantEmail__c = enrollment.Email__c,
						sav_usr_user_id__c = Decimal.valueOf(enrollment.user_id__c),
						sav_available_service_id__c = enrollment.sav_available_service_id__c,
						ProAccount__c = (Id)accountMap.get(enrollment.user_id__c),
						usr_phn_phone_number__c = enrollment.Phone__c,
						usr_email__c = enrollment.Email__c,
						usr_first_name__c = enrollment.FirstName__c,
						usr_last_name__c = enrollment.LastName__c
					));
				}
			}
		}

		insert servicesToAdd;

		system.debug('servicesToAdd: '+servicesToAdd);
		Map<String,Id> serviceToEnrollmentMap = new Map<String,Id>();
		for(service__c s : servicesToAdd)
		{
			serviceToEnrollmentMap.put(String.valueOf(s.sav_usr_user_id__c), s.Id);
		}
		for (Enrollment__c enrollment : triggerNew)
		{
			enrollment.Service__c = enrollment.Service__c == null ? serviceToEnrollmentMap.get(enrollment.user_id__c) : enrollment.Service__c;
			system.debug('enrollment: '+enrollment.service__c);
		}
	}

    /**
    * @author Meenakshi Pisupati
    * @date 2018-02-28
    * @description Get Existing Routing Profile based on Phone Number on Enrollment
    * @param Enrollment[] the trigger array.
    */
    private Map<Id, RoutingProfile__c> getExistingRoutingProfiles(Enrollment__c[] triggerNew)
    {
        Map<Id, RoutingProfile__c> existingRoutingProfiles = new Map<Id, RoutingProfile__c>();
        String phoneSOSLString = '';
        String phoneFieldForQuery = '';
        List<String> phoneFields = new List<String>{'Phone__c','Phone2__c','Phone3__c','Phone4__c','Phone5__c','Phone6__c','Phone7__c','Phone8__c','Phone9__c','Phone10__c'};
        for(Enrollment__c e: triggerNew)
        {
            if(NULL != e.Phone__c && '' != e.Phone__c)
            {
                phoneSOSLString += ''.equals(phoneSOSLString) ? e.Phone__c : phoneSOSLString.length() <  19985 ? (' OR ' + e.Phone__c) : '' ; //20k max SOSL limit
            }
        }
        for(String phAPI: phoneFields)
        {
            phoneFieldForQuery+=phAPI+',';
        }

        if(NULL != phoneSOSLString && '' != phoneSOSLString)
        {
            String searchQuery = 'FIND \'' + phoneSOSLString + '\' IN PHONE FIELDS RETURNING RoutingProfile__c('+phoneFieldForQuery+'Id)';

            //checking for existing Routing profiles
            List<RoutingProfile__c[]> soslResults = search.query(searchQuery);

            for(RoutingProfile__c rp: soslResults[0])
            {
                for(String ph: phoneFields)
                {
                    String valueOfPhoneField = String.valueOf(rp.get(ph));
                    if(NULL != valueOfPhoneField)
                    {
                        for(Enrollment__c e: triggerNew)
                        {
                            String enrollPhone = e.Phone__c.replaceAll('[^0-9]','');
                            valueofPhoneField = valueofPhoneField.replaceAll('[^0-9]','');
                            if(NULL != enrollPhone && valueofPhoneField == enrollPhone)
                            {
                                existingRoutingProfiles.put(e.Id,rp);
                                break;
                            }
                        }
                    }
                }
            }
        }
        return existingRoutingProfiles;
    }

    /**
    * @author Meenakshi Pisupati
    * @date 2018-02-28
    * @description Update Routing Profile based on Enrollment's Funnel Step
    * @param Enrollment[] the trigger array (New array and Old Map).
    */
	private void updateRoutingProfile(Enrollment__c[] triggerNew,Map<Id, Enrollment__c> triggerOldMap )
    {
        RoutingProfile__c[] rProfilesToUpdate = new RoutingProfile__c[0];
        Map<Id, RoutingProfile__c> existingRPs = this.getExistingRoutingProfiles(triggerNew);

        if(!existingRPs.isEmpty())
        {
            for(Enrollment__c en: [SELECT Id,Account__r.AccountManager__c, Account__r.AccountManager__r.Email, FunnelStep__c,SalesRep__c, SalesRep__r.Email FROM Enrollment__c WHERE Id IN :existingRPs.keySet()])
            {
                Enrollment__c oldEn = triggerOldMap.get(en.id);
                if(existingRPs.containsKey(en.Id))
                {
	                if('Prospecting'.equals(oldEn.FunnelStep__c) && 'Pre-Onboarding'.equals(en.FunnelStep__c))
	                {
	                    RoutingProfile__c rp = existingRPs.get(en.Id);
	                	rp.Enrollment__c = en.Id;
	                    if(NULL != en.Account__r.AccountManager__c)
	                    {
	                        rp.RoutetoAgent__c = en.Account__r.AccountManager__r.Email;
                            rp.Sales__c = FALSE;
	                    }else
	                    {
	                        rp.RoutetoAgent__c = NULL;
	                        rp.Enterprise__c = TRUE;
                            rp.Sales__c = FALSE;
	                    }
	                    rProfilesToUpdate.add(rp);
	                }else if('Prospecting'.equals(en.FunnelStep__c))
	                {
	                    RoutingProfile__c rp = existingRPs.get(en.Id);
	                	rp.Enrollment__c = en.Id;
	                    if(NULL != en.SalesRep__c)
	                    {
	                        rp.RoutetoAgent__c = en.SalesRep__r.Email;
	                    }else
	                    {
	                        rp.RoutetoAgent__c = NULL;
	                        rp.Sales__c = TRUE;
	                    }
	                    rProfilesToUpdate.add(rp);
	                }
           		}
            }
        }
        if(!rProfilesToUpdate.isEmpty())
        {
	    	 try
	        {
	            QueueableUtility.handleQueueable(new DMLQueueable(rProfilesToUpdate, DMLQueueable.Operation.UPDATES));
	        } catch( Exception exc ){
	            TackBotUtility.postTackLogException(exc, 'EnrollmentTriggerHandler.updateRoutingProfileRecord');
	        }
        }
    }

    /**
    * @author Meenakshi Pisupati
    * @date 2018-02-28
    * @description Insert or Update Routing Profile and relate to Enrollment
    * @param Enrollment[] the trigger array.
    */

	private void insertRoutingProfile(Enrollment__c[] triggerNew)
	{
        //Added - MP - capture existing RPs in a map
        RoutingProfile__c[] rProfilesToInsert = new RoutingProfile__c[0];
        RoutingProfile__c[] rProfilesToUpdate = new RoutingProfile__c[0];
        Map<Id, RoutingProfile__c> existingRPs = this.getExistingRoutingProfiles(triggerNew);
        String errorMessage = '';

        //If there are no existing RPs, create new, else update
        for(Enrollment__c en: triggerNew)
        {
            RoutingProfile__c rp = existingRPs.get(en.Id);

        	if(NULL == rp)
			{
                //Added - MP - if enrollment is in Prospecting funnel step, create routing profile if there are no existing RPs
                if('Prospecting'.equals(en.FunnelStep__c) &&  'managed_account'.equals(en.outreach_type__c))
                {
                    rp = new RoutingProfile__c(
                        Name = 'Routing Profile for '+en.Email__c,
                        Email__c = en.Email__c,
                        Phone__c = en.Phone__c,
                        Account__c = en.Account__c,
                        ThumbtackID__c  = Decimal.valueOf(en.user_id__c) ,
                        Enrollment__c = en.Id,
                        Enterprise__c = FALSE
                    );
                    if(NULL != en.SalesRep__c)
                    {
                        rp.RoutetoAgent__c = en.SalesRep__r.Email;
                        rp.Sales__c = FALSE;
                    }else
                    {
                        rp.RoutetoAgent__c = NULL;
                        rp.Sales__c = TRUE;
                    }
                    rProfilesToInsert.add(rp);
                }
            }
			else
			{
				rp.Enrollment__c = en.Id;
				if('Prospecting'.equals(en.FunnelStep__c) && 'managed_account'.equals(en.outreach_type__c))
				{
                    rp.Enterprise__c = FALSE;
					if(NULL != en.SalesRep__c)
					{
						rp.RoutetoAgent__c = en.SalesRep__r.Email;
						rp.Sales__c = FALSE;
					}else
					{
						rp.RoutetoAgent__c = NULL;
						rp.Sales__c = TRUE;
					}
				}
                else if('Pre-Onboarding'.equals(en.FunnelStep__c))
                {
                    rp.Sales__c = FALSE;
                    if(NULL != en.Account__r.AccountManager__c)
                    {
                        rp.RoutetoAgent__c = en.Account__r.AccountManager__r.Email;
                    }
                    else
                    {
                        rp.Enterprise__c = TRUE; 
                    }
                }
				rProfilesToUpdate.add(rp);
			}
		}

        if(!rProfilesToInsert.isEmpty())
        {
            for (Database.saveResult result : Database.insert(rProfilesToInsert, false))
            {
                if (!result.isSuccess())
                {
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'EnrollmentTriggerHandler.updateRoutingProfileRecord');
                errorMessage = '';
            }
        }
        if(!rProfilesToUpdate.isEmpty())
        {
            try
            {
                QueueableUtility.handleQueueable(new DMLQueueable(rProfilesToUpdate, DMLQueueable.Operation.UPDATES));
            } catch( Exception exc ){
                TackBotUtility.postTackLogException(exc, 'EnrollmentTriggerHandler.updateRoutingProfileRecord');
            }
        }
	}

}