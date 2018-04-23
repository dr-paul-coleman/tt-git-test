/*
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-10-09   Mendel Guillaume       Created
  ========+============+=================+===============================================
*/

public with sharing class WorkItemHelper
{
	public static final Id BLACKLISTED_NUMBER_RECORD_TYPE_ID = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Blacklisted Number').getRecordTypeId();
	public static final Id CONCERNING_REVIEW_RECORD_TYPE_ID = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Concerning Review').getRecordTypeId();
	public static final Id STANDARD_WORK_ITEM_RECORD_TYPE_ID = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Work Item').getRecordTypeId();
}