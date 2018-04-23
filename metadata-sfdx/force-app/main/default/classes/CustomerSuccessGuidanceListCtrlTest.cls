/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
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

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-09-04   Mendel Guillaume       Created
========+============+=================+===============================================*/

@IsTest
private class CustomerSuccessGuidanceListCtrlTest
{
	@TestSetup
	static void createData()
	{
		Account customer = new Account(Name = 'Customer Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
		insert customer;

		CustomerSuccessGuidance__c csg = new CustomerSuccessGuidance__c(Account__c = customer.Id, Name = 'Test Guidance');
		insert csg;
	}

	static testMethod void testGetRecords()
	{
		Account a = [SELECT Id FROM Account];
		System.assertEquals(1, CustomerSuccessGuidanceListController.getRecords(a.Id).size());
	}
}