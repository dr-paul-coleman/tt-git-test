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
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     02-21-2017  Scott Purcell      Created-To replace Bug Report Update History process builder
1.1		3-23-2017   Scott Purcell      Created delete component for profiles that are all marked false
=======+===========+=================+================================================
*/
public with sharing class RoutingProfileTriggerHandler 
{
	public static void BeforeUpdate(List<RoutingProfile__c> profiles,List<RoutingProfile__c> oldProfiles,map<id,RoutingProfile__c> profilesMap)
	{
		List<Lead> leads = new List<Lead>();
		List<String> ids = new List<String>();
		for(RoutingProfile__c rp: profiles)
		{
            system.debug('rp.Lead__c: '+rp.Lead__c);
			if(rp.Lead__c != null)ids.add(rp.Lead__c);
		}
		system.debug('ids: '+ids);
		if(ids.size()>0)leads = [Select Id,ThumbtackID__c From Lead Where Id in :ids];
		system.debug('leads: '+leads);
		for(RoutingProfile__c profile : profiles)
		{
			for(Lead l:leads)
			{
				if(profile.Lead__c == l.Id && l.ThumbtackID__c != null)
				{
					profile.ThumbtackID__c = l.ThumbtackID__c;
					profile.updated__c = true;
				}
			}
			system.debug('profile: '+profile);
		}
	}
	public static void AfterUpdate(List<RoutingProfile__c> profiles) 
	{
		List<String>profilesToDelete = new List<String>();//Added 3/23/2107 -Scott Purcell
		for(RoutingProfile__c p : profiles)
		{
			if(p.CreditFisher__c == false && p.CustomerContact__c == false && p.Enterprise__c == false && p.Experiment__c == false && p.FrequentCaller__c == false && p.ProAssistant__c == false && p.ProAssistOnboarding__c == false && p.QuotingService__c == false && p.TopPro__c == false)
			{
				profilesToDelete.add(p.Id);
			}
		}
		delete [Select Id From RoutingProfile__c Where id IN :profilesToDelete];
	}
	
}