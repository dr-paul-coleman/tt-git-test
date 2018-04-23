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
@isTest
private class SupportProcessTriggerHandlerTest 
{
	public static Id brRecordTypeId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Bug Report').getRecordTypeId();
	public static Id srRecordTypeId = SupportProcess__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Resource').getRecordTypeId();
	
	@isTest static void test_method_one() 
	{
		Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
		Case c = new Case(Status='New',RecordTypeId=caseRTId,Origin='Web',SuppliedEmail='tester@bogus.testing.com',SuppliedName='Chester CaseTester',SuppliedThumbtackID__c=120);
        insert c;
        List<SupportProcess__c> spList = new List<SupportProcess__c>();
        SupportProcess__c sp = new SupportProcess__c(Name = 'blah blah',Case__c = c.Id,RecordTypeId = brRecordTypeId);
		SupportProcess__c sp1 = new SupportProcess__c(Name = 'blah blah1',Case__c = c.Id,RecordTypeId = brRecordTypeId);
		SupportProcess__c sp2 = new SupportProcess__c(Name = 'blah2 blah2',Case__c = c.Id,RecordTypeId = srRecordTypeId);
        SupportProcess__c sp3 = new SupportProcess__c(Name = 'blah2 blah3',Case__c = c.Id,RecordTypeId = srRecordTypeId);
        SupportProcess__c sp4 = new SupportProcess__c(Name = 'blah2 blah4',Case__c = c.Id,RecordTypeId = srRecordTypeId);
        SupportProcess__c sp5 = new SupportProcess__c(Name = 'blah2 blah5',Case__c = c.Id,RecordTypeId = srRecordTypeId);
        SupportProcess__c sp6 = new SupportProcess__c(Name = 'blah2 blah6',Case__c = c.Id,RecordTypeId = srRecordTypeId);
        spList.add(sp1);
        spList.add(sp2);
        spList.add(sp3);
        spList.add(sp4);
        spList.add(sp5);
        spList.add(sp6);

		User testUser = [SELECT id FROM User WHERE Profile.Name LIKE '%Marketplace Integrity%' AND IsActive=true LIMIT 1];        
        System.runAs(testUser) 
        {
           Test.startTest();
                insert sp;
                insert spList;
            Test.stopTest();           
        }
        List<SupportProcess__c> sps = [Select Id,Name,RecordTypeId From SupportProcess__c];
        system.debug(sps);
        for(SupportProcess__c s:sps)
        {
        	//if(s.RecordTypeId == brRecordTypeId)
        	//{
        	//	system.assertEquals('BR-0001',s.Name);
        	//}
        	//if(s.RecordTypeId == srRecordTypeId)
        	//{
        	//	system.assertEquals('SP-0001',s.Name);
        	//}
        }
	}
	
	
	
}