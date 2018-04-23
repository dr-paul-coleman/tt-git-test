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
1.0     04-11-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
public with sharing class SupportProcessTriggerHandler {
	public static Id brRecordTypeId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Bug Report').getRecordTypeId();
	public static Id srRecordTypeId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Resource').getRecordTypeId();

	public static void onBeforeInsert(List<SupportProcess__c> spList, Map<Id,SupportProcess__c> spMap) 
	{
		List<SupportProcess__c> allSPList = [Select Id,Name,RecordTypeId From SupportProcess__c];
		Integer brCount = 0;
		Integer srCount = 0;
		for(SupportProcess__c sp:allSPList)
		{
            if(sp.Name!=null)
			{
                String[] value = sp.Name.Split('-');
				if(value.size()>1)
				{
                    system.debug(value[1]);
                    if(value[1] == null)value[1]='1';
                    if(sp.RecordTypeId == brRecordTypeId && Integer.valueOf(value[1]) > brCount)brCount = Integer.valueOf(value[1]);
                    if(sp.RecordTypeId == srRecordTypeId && Integer.valueOf(value[1])> srCount)srCount = Integer.valueOf(value[1]);
                    system.debug('srCount: '+srCount+',  BrCount: '+BrCount);
                }
            }
		}
            
		for(SupportProcess__c sp:spList)
		{

			String val = null;
			if(sp.RecordTypeId == brRecordTypeId)
			{
				brCount++;
				system.debug('BrCount: '+brCount);
				val = String.valueOf(brCount);
				if(brCount<1000 && brCount>100)val = '0'+String.valueOf(brCount);
				if(brCount<100 && brCount>10)val = '00'+String.valueOf(brCount);
				if(brCount<10 && brCount>0)val = '000'+String.valueOf(brCount);
				system.debug('val: '+val);
				sp.Name = 'BR-'+val;
			}
			if(sp.RecordTypeId == srRecordTypeId)
			{
				srCount++;
				system.debug('srCount: '+srCount);
				val = String.valueOf(srCount);
				if(srCount<1000 && srCount>100)val = '0'+String.valueOf(srCount);
				if(srCount<100 && srCount>10)val = '00'+String.valueOf(srCount);
				if(srCount<10 && srCount>0)val = '000'+String.valueOf(srCount);
				system.debug('val: '+val);
				
				sp.Name = 'SP-'+val;
			}
		}
		
	}
	/*public static void onBeforeUpdate(List<SupportProcess__c> spList, List<SupportProcess__c> oldspList, Map<Id,SupportProcess__c> spMap, Map<Id,SupportProcess__c> oldspMap) 
	{
		
	}*/
}