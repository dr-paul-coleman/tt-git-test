/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-11-14   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/

public with sharing class CategorizationContainerController
{
	@AuraEnabled
	public static CategorizationSettings__c getUserSettings()
	{
		return CategorizationSettings__c.getInstance();
	}

	@AuraEnabled
	public static void toggleTreeSetting()
	{
		CategorizationSettings__c cs = CategorizationSettings__c.getInstance();

		cs.ShowCategoryTree__c = !cs.ShowCategoryTree__c;

		upsert cs;
	}
}