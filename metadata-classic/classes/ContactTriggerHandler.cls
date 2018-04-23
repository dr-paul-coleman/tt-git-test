/**
  Copyright (c) 2017 Thumbtack  All rights reserved.

  Change List:
  ------------

  Version    Date     Author            Description
  =======+===========+=================+=================================
  1.0     2017-12-14  Mendel Guillaume  Created
  =======+===========+=================+=================================
 */

public virtual class ContactTriggerHandler extends ThumbtackTriggerHandlerBase
{
	// Recursion Prevention Flags
	private static Boolean isInBeforeInsertProcessing = false;
	private static Boolean isInBeforeUpdateProcessing = false;
	private static Boolean isInAfterInsertProcessing = false;
	private static Boolean isInAfterUpdateProcessing = false;

	// TRIGGER FRAMEWORK OVERRIDDEN EVENT HANDLERS
	public override void onBeforeInsert(ThumbtackTriggerContext ctx)
	{
		if(!isInBeforeInsertProcessing)
		{
			isInBeforeInsertProcessing = true;

			try
			{
				this.setContactsOwnership((List<Contact>) ctx.newRecords);
			}
			finally
			{
				isInBeforeInsertProcessing = false;
			}
		}
	}

	/**
    * @author Mendel Guillaume
    * @date 2017-12-14
    * @description Set contact ownership to tackbot when account record type != 'Managed Account'
    * @param newRecords the trigger list.
    */
	private void setContactsOwnership(List<Contact> newRecords)
	{
		Id managedAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Managed Account').getRecordTypeId();
		User tackBot = TackBotUtility.getTackBotUser();

		for(Contact c : newRecords)
		{
			if (c.AccountRecordTypeId__c != managedAccountRecTypeId && c.OwnerId != tackBot.Id)
			{
				c.OwnerId = tackBot.Id;
			}
		}
	}
}