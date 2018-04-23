/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version    Date     Author            Description
=======+===========+=================+==========================================
1.0     2016-12-14  Scott Purcell     Created
1.1     2016-12-14  Scott Purcell     AddedQuotingService tests
1.2     2017-06-09  Scott Purcell     Create csg record for Enterprise services
1.3     2017-10-02  Meena Pisupati	  Updated Header
=======+===========+=================+==========================================*/
public without sharing class ServiceTriggerHandler 
{

	public static Id customerSuccessFlagRecTypeId = CustomerSuccessGuidance__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Success Flag').getRecordTypeId();
	public static Id serviceRecTypeId = Service__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Pro Assistance Service').getRecordTypeId();

	public static User usr {

		get {

			if (usr == null) {

				String username = 'tack bot';
	 			usr =[Select Name,Id From User Where Name LIKE:('%' + username + '%') limit 1];

			}
			return usr;

		} set;

	}

	 public static void OnBeforeInsert(List<Service__c> newObjects)
	 {	 

	 	List<Id>ids = new List<Id>();
	 	for(Service__c serv: newObjects)
	 	{
	 		
	 		ids.add(serv.ProAccount__c);

	 	}
	 	Map<Id, Account> accMap = new Map<Id, Account> ([Select Name,Id,UserEmail__c From Account Where Id IN:ids]);
	 	for(Service__c serv: newObjects) {

	 		Account acc = accMap.get(serv.ProAccount__c);
	 		if (acc != null) {

	 			acc.UserEmail__c = serv.usr_email__c;

	 		}

	 	}
		update accMap.values();
		manageCustomerSuccessGuidanceFlags(newObjects);

    }

    /*public static void OnAfterInsert(List<Service__c> newObjects){
        // EXECUTE AFTER INSERT LOGIC
    }*/

    public static void OnBeforeUpdate(List<Service__c> updatedObjects, List<Service__c> oldObjects, Map<Id,Service__c> newMap, Map<Id,Service__c> oldMap)
	{
		List<CustomerSuccessGuidance__c> csgs = new List<CustomerSuccessGuidance__c>();
		List<CustomerSuccessGuidance__c> csgToDelete = new List<CustomerSuccessGuidance__c>();
	 	List<Id>ids = new List<Id>();
	 	List<String> nonEnterpriseIds = new List<String>();
	 	List<String> enterpriseIds = new List<String>();
	 	Map<Id,CustomerSuccessGuidance__c> csgMap = new Map<Id,CustomerSuccessGuidance__c>();
	 	Map<Id,CustomerSuccessGuidance__c> csgNonMap = new Map<Id,CustomerSuccessGuidance__c>();
	 	for(Service__c serv: updatedObjects)
	 	{
	 		ids.add(serv.ProAccount__c);
	 		if(serv.ProAssistantManagedBy__c == 'Sales & Account Management')enterpriseIds.add(serv.ProAccount__c);
	 		if(serv.ProAssistantManagedBy__c != 'Sales & Account Management')nonEnterpriseIds.add(serv.ProAccount__c);


	 	}
	 	List<CustomerSuccessGuidance__c> csgList = [Select Id,Account__c FROM CustomerSuccessGuidance__c WHERE Account__c IN:enterpriseIds ];
	 	List<CustomerSuccessGuidance__c> csgNonList = [Select Id,Account__c FROM CustomerSuccessGuidance__c WHERE Account__c IN:nonEnterpriseIds ];
	 	for(CustomerSuccessGuidance__c c:csgList)csgMap.put(c.Account__c,c);
	 	for(CustomerSuccessGuidance__c c:csgNonList)csgNonMap.put(c.Account__c,c);
	 	Map<Id, Account> accMap = new Map<Id, Account> ([Select Name,Id,UserEmail__c From Account Where Id IN:ids]);
	 	for(Service__c serv: updatedObjects) {

	 		Account acc = accMap.get(serv.ProAccount__c);
	 		if (acc != null) {

	 			acc.UserEmail__c = serv.usr_email__c;

	 		}
 			if(serv.ProAssistantManagedBy__c != oldMap.get(serv.Id).ProAssistantManagedBy__c  && serv.ProAssistantManagedBy__c == 'Sales & Account Management') 
	 		{               
	 			if(!csgMap.containsKey(serv.ProAccount__c))
	 			{                 
	 				CustomerSuccessGuidance__c g = new CustomerSuccessGuidance__c(
								RecordTypeID = customerSuccessFlagRecTypeId,
								OwnerId = serv.OwnerId,
								Account__c = serv.ProAccount__c,
								Name = serv.Name,
								CSFlagType__c = 'Sales & Account Management'
                    );
 					csgs.add(g);
	 			}
	 		}
	 		if(serv.ProAssistantManagedBy__c != oldMap.get(serv.Id).ProAssistantManagedBy__c  && serv.ProAssistantManagedBy__c != 'Sales & Account Management') 
	 		{               
	 			if(csgNonMap.containsKey(serv.ProAccount__c))
	 			{                 
	 				//csgNonMap.get(serv.ProAccount__c).EndDate__c = Datetime.now();
	 				system.debug('changing the csg to have an end date');
	 				csgToDelete.add(csgNonMap.get(serv.ProAccount__c));
	 			}
	 		}
	 		
	 	}
	 	delete csgToDelete;
		update accMap.values();
		//update csgNonMap.values();
		if(csgs.size()>0)insert csgs;
		manageCustomerSuccessGuidanceFlags(updatedObjects);

    }

    private static void manageCustomerSuccessGuidanceFlags(List<Service__c> newObjects) {

	 	List<Id>ids = new List<Id>();
	 	Map<Id, Set<String>> serviceTypesByAccount = new Map<Id, Set<String>> ();
	 	Map<Id, Map<String, CustomerSuccessGuidance__c>> csgMapByAccount = new Map<Id, Map<String, CustomerSuccessGuidance__c>> ();
	 	for(Service__c serv: newObjects)
	 	{
	 		ids.add(serv.ProAccount__c);
	 		Set<String> serviceTypes = serviceTypesByAccount.get(serv.ProAccount__c);
	 		serviceTypes = serviceTypes == null ? new Set<String> () : serviceTypes;
	 		if (serv.RecordTypeId == serviceRecTypeId && serv.QuotingServiceStatus__c == 'ON') {

		 		serviceTypes.add(serv.ProAssistantSubscriptionType__c);

	 		}
	 		serviceTypesByAccount.put(serv.ProAccount__c, serviceTypes);
	 		csgMapByAccount.put(serv.ProAccount__c, new Map<String, CustomerSuccessGuidance__c> ());

	 	}
	 	List<String> subscriptionTypes = new List<String> ();
	 	List<String> flagTypes = new List<String> ();
	 	Map<String, List<CustomerSuccessGuidanceSetting__mdt>> csgSettingByFlagType = new Map<String, List<CustomerSuccessGuidanceSetting__mdt>> ();
	 	for (CustomerSuccessGuidanceSetting__mdt csgSetting : [Select ServiceSubscriptionType__c, CSGName__c, CSGFlagExplanation__c, CSGCSFlagType__c
	 															From CustomerSuccessGuidanceSetting__mdt]) {

	 		subscriptionTypes.add(csgSetting.ServiceSubscriptionType__c);
	 		flagTypes.add(csgSetting.CSGCSFlagType__c);
	 		List<CustomerSuccessGuidanceSetting__mdt> csgSettings = csgSettingByFlagType.get(csgSetting.CSGCSFlagType__c);
	 		csgSettings = csgSettings == null ? new List<CustomerSuccessGuidanceSetting__mdt> () : csgSettings;
	 		csgSettings.add(csgSetting);
	 		csgSettingByFlagType.put(csgSetting.CSGCSFlagType__c, csgSettings);

	 	}
	 	for (Service__c serv : [Select Id, ProAccount__c, ProAssistantSubscriptionType__c 
	 							From Service__c 
	 							Where ProAccount__c IN :ids
	 							And ProAssistantSubscriptionType__c IN :subscriptionTypes
	 							And QuotingServiceStatus__c = 'ON'
	 							And RecordTypeId = :serviceRecTypeId]) {

	 		Set<String> serviceTypes = serviceTypesByAccount.get(serv.ProAccount__c);
	 		serviceTypes = serviceTypes == null ? new Set<String> () : serviceTypes;
	 		serviceTypes.add(serv.ProAssistantSubscriptionType__c);
	 		serviceTypesByAccount.put(serv.ProAccount__c, serviceTypes);

	 	}
	 	List<CustomerSuccessGuidance__c> csgDeleteList = new List<CustomerSuccessGuidance__c>();
	 	List<CustomerSuccessGuidance__c> csgNewList = new List<CustomerSuccessGuidance__c>();

	 	for (CustomerSuccessGuidance__c csg : [Select Id,Account__c,CSFlagType__c From CustomerSuccessGuidance__c WHERE CSFlagType__c IN :flagTypes AND Account__c IN:ids]) {

	 		Map<String, CustomerSuccessGuidance__c> csgMap = csgMapByAccount.get(csg.Account__c);
	 		csgMap.put(csg.CSFlagType__c, csg);
	 		csgMapByAccount.put(csg.Account__c, csgMap);

	 	}
	 	for (Id accId : serviceTypesByAccount.keySet()) {

	 		Set<String> serviceTypes = serviceTypesByAccount.get(accId);
	 		Map<String, CustomerSuccessGuidance__c> csgMap = csgMapByAccount.get(accId);
	 		for (String flagType : csgSettingByFlagType.keySet()) {

	 			Boolean shouldHaveFlag = false;
	 			for (CustomerSuccessGuidanceSetting__mdt csgSetting : csgSettingByFlagType.get(flagType)) {

	 				if (serviceTypes.contains(csgSetting.ServiceSubscriptionType__c)) {

			 			shouldHaveFlag = true;
			 			if (!csgMap.containsKey(csgSetting.CSGCSFlagType__c)) {

			 				CustomerSuccessGuidance__c g = new CustomerSuccessGuidance__c(
								RecordTypeID = customerSuccessFlagRecTypeId,
								OwnerId = usr.Id,
								Account__c = accId,
								Name = csgSetting.CSGName__c,
								CSFlagType__c = csgSetting.CSGCSFlagType__c,
								FlagExplanation__c = csgSetting.CSGFlagExplanation__c
							);
							csgNewList.add(g);
							csgMap.put(csgSetting.CSGCSFlagType__c, g);

			 			}
			 			break;

			 		}

	 			}
	 			if (!shouldHaveFlag && csgMap.containsKey(flagType)) {

	 				csgDeleteList.add(csgMap.get(flagType));
	 				csgMap.remove(flagType);

	 			}

	 		}

	 	}
		insert csgNewList;
		delete csgDeleteList;

    }

    /*public static void OnAfterUpdate(List<Service__c> updatedObjects, List<Service__c> oldObjects, Map<Id,Service__c> newMap,Map<Id,Service__c> oldMap)
	{
        // AFTER UPDATE LOGIC
    }*/

    /*public static void OnBeforeDelete(List<Service__c> ObjectsToDelete, Map<Id,Service__c> newMap){
        // BEFORE DELETE LOGIC
    }*/

    /*public static void OnAfterDelete(List<Service__c> deletedObjects, Map<Id,Service__c> newMap){
        // AFTER DELETE LOGIC
    }*/

    /*public void OnUndelete(Service__c[] restoredObjects){
        // AFTER UNDELETE LOGIC
    }*/
}