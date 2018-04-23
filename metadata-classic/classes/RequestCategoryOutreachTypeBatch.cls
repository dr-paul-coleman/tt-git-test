/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       unknown      Adam Schultz
2.0       11/11/17     paulcoleman       Patched for all-or-nothing DML retry of RequestCategory__c
                                              within finish()
========+============+=================+===============================================*/
global class RequestCategoryOutreachTypeBatch implements Database.Batchable<sObject> {
	
	global RequestCategoryOutreachTypeBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {

		String query = 'Select Id, outreach_type__c, Market__r.RequestCategory__c, Market__r.RequestCategory__r.outreach_type__c, FunnelStep__c, CallbackOutreachType__c, Account__c From Enrollment__c Where Market__r.RequestCategory__r.OutreachTypeChanged__c = true';
		return Database.getQueryLocator(query);

	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		Set<String> funnelStepsAllowingChange = new Set<String> ();
		for (FunnelStepSetting__mdt setting : [Select Id, MasterLabel, DeveloperName, Order__c, EnrollmentOutreachTypeCanChange__c
												From FunnelStepSetting__mdt
												Where EnrollmentOutreachTypeCanChange__c = true
												order by Order__c]) {

			funnelStepsAllowingChange.add(setting.MasterLabel);

		}
		Set<Id> enrollmentIdsForFunnelStepUpdate = new Set<Id> ();
		Map<Id, Enrollment__c> enrollmentsForUpdate = new Map<Id, Enrollment__c> ();
		Map<String, List<Enrollment__c>> enrollmentsByOutreachType = new Map<String, List<Enrollment__c>> ();
		List<Id> accountIds = new List<Id> ();
		for (Enrollment__c enrollment : (List<Enrollment__c>) scope) {

			if (funnelStepsAllowingChange.contains(enrollment.FunnelStep__c)) {

				enrollment.outreach_type__c = enrollment.Market__r.RequestCategory__r.outreach_type__c;
				enrollmentsForUpdate.put(enrollment.Id, enrollment);
				enrollmentIdsForFunnelStepUpdate.add(enrollment.Id);

			} else {

				List<Enrollment__c> enrollments = enrollmentsByOutreachType.get(enrollment.outreach_type__c);
				enrollments = enrollments == null ? new List<Enrollment__c> () : enrollments;
				enrollments.add(enrollment);
				enrollmentsByOutreachType.put(enrollment.outreach_type__c, enrollments);

			}
			if (enrollment.CallbackOutreachType__c == enrollment.Market__r.RequestCategory__r.outreach_type__c) {

				enrollment.CallbackOutreachType__c = null;
				enrollmentsForUpdate.put(enrollment.Id, enrollment);
				accountIds.add(enrollment.Account__c);

			}

		}
        // PBC: emergency patch for UNABLE TO LOCK ROW all-or-nothing email distros to systems@
        // avoid all-or-nothing DML failures
        Enrollment__c[] resubmitUpdates = new Enrollment__c[0];
        Integer enrollIndex = 0;
        for( Database.SaveResult result: Database.update(enrollmentsForUpdate.values(), false) )
        {
            if( !result.isSuccess() )
            {
                resubmitUpdates.add(enrollmentsForUpdate.values()[enrollIndex]);

            }
            enrollIndex++;
        }

        // for failed DML records, attempt to complete the dml asynchronously
        if( !resubmitUpdates.isEmpty() )
        {
            try { System.enqueueJob( new DMLQueueable( resubmitUpdates, DMLQueueable.Operation.UPDATES ) ); } catch (Exception e) { TackBotUtility.postTackLogException(e, 'RequestCategoryOutreachTypeBatch.execute'); }
        }
        // END emergency patch

		if (!accountIds.isEmpty()) {

			Datetime now = Datetime.now();
			List<Account> accountsForUpdate = [Select Id, EnrollmentCallbackDateTime__c, EnrollmentCallbackOrigin__c From Account Where Id IN :accountIds];
			for (Account acc : accountsForUpdate) {

				acc.EnrollmentCallbackDateTime__c = now;
				acc.EnrollmentCallbackOrigin__c = 'System';

			}
			update accountsForUpdate;

		}
		if (!enrollmentsByOutreachType.isEmpty()) {

			List<EnrollmentAction__c> actionsForInsert = new List<EnrollmentAction__c> ();
			List<String> ruleIds = new List<String> ();
			Map<Id, Set<String>> ruleIdsByEnrollmentId = new Map<Id, Set<String>> ();
			List<String> enrollmentOutreachTypes = new List<String> (enrollmentsByOutreachType.keySet());
			String outreachTypeString = '\'';
			outreachTypeString += String.join(enrollmentOutreachTypes, '\',\'');
			outreachTypeString += '\'';
			for (EnrollmentRule__c rule : (List<EnrollmentRule__c>) Database.query(
											'Select Id, Name, EnrollmentOutreachType__c, CategoryOutreachTypeAutomatedTarget__c '
											+ 'From EnrollmentRule__c '
											+ 'Where IsAutomatedAction__c = true '
											+ 'And IsActive__c = true '
											+ 'And EnrollmentOutreachType__c includes (' + outreachTypeString + ') ')) {

				for (String eOutreachType : rule.EnrollmentOutreachType__c.split(';')) {

					if (enrollmentsByOutreachType.containsKey(eOutreachType)) {

						for (Enrollment__c enrollment : enrollmentsByOutreachType.get(eOutreachType)) {

							Boolean outreachTypeMatches = false;
							for (String ruleOutreachType : rule.CategoryOutreachTypeAutomatedTarget__c.split(';')) {

								if (ruleOutreachType == enrollment.Market__r.RequestCategory__r.outreach_type__c) {

									actionsForInsert.add(new EnrollmentAction__c (
										Name = rule.Name,
										Enrollment__c = enrollment.Id,
										Type__c = 'Onboarding Step',
										RuleId__c = String.valueOf(rule.Id)
									));
									enrollmentIdsForFunnelStepUpdate.add(enrollment.Id);
									outreachTypeMatches = true;
									break;

								}

							}
							if (!outreachTypeMatches) {

								String ruleId = String.valueOf(rule.Id);
								ruleIds.add(ruleId);
								Set<String> ruleIdSet = ruleIdsByEnrollmentId.get(enrollment.Id);
								ruleIdSet = ruleIdSet == null ? new Set<String> () : ruleIdSet;
								ruleIdSet.add(ruleId);
								ruleIdsByEnrollmentId.put(enrollment.Id, ruleIdSet);

							}

						}

					}

				}

			}
			ProEnrollmentUtility.createEnrollmentActions(actionsForInsert);
			if (!ruleIds.isEmpty()) {

				List<EnrollmentAction__c> actionsForDelete = new List<EnrollmentAction__c> ();
				for (EnrollmentAction__c action : [Select Id, RuleId__c, Enrollment__c 
													From EnrollmentAction__c 
													Where Enrollment__c IN :ruleIdsByEnrollmentId.keySet() 
													And RuleId__c IN :ruleIds]) {

					if (ruleIdsByEnrollmentId.containsKey(action.Enrollment__c) && ruleIdsByEnrollmentId.get(action.Enrollment__c).contains(action.RuleId__c)) {

						actionsForDelete.add(action);
						enrollmentIdsForFunnelStepUpdate.add(action.Enrollment__c);

					}

				}
				delete actionsForDelete;

			}

		}
		if (!enrollmentIdsForFunnelStepUpdate.isEmpty()) {

			ProEnrollmentUtility.handleEnrollmentUpdate(new List<Id> (enrollmentIdsForFunnelStepUpdate));

		}
	
	}

	/**
	* @author Paul Coleman
	* @date 2017-10-17
	* @description (refactored) modifed update DML to not use all-or-nothing commit.
	* @param Database.BatchableContext unused
	*/
	global void finish(Database.BatchableContext BC) {

        RequestCategory__c[] cats = [Select OutreachTypeChanged__c From RequestCategory__c Where OutreachTypeChanged__c = true];
		for (RequestCategory__c cat : cats) {
			cat.OutreachTypeChanged__c = false;
		}

        RequestCategory__c[] errorRecords = new RequestCategory__c[0];
        Integer cIndex = 0;
        String messageBody = '';
        for( Database.SaveResult result: Database.update( cats, false) )
        {
            if( !result.isSuccess() )
            {
                errorRecords.add( cats[cIndex] );
                String error = 'RequestCategory__c UPDATE FAILED. ' + ( result.getErrors().isEmpty()? '' : result.getErrors()[0].getMessage() ) + '\n<br/> REQUESTCATEGORY RECORD: ' + JSON.serialize( cats[cIndex] );
                System.debug( LoggingLevel.ERROR, error );
                messageBody += error + '<br/><br/>';
            }
            cIndex++;

        }

        if( !errorRecords.isEmpty() )
        {
            messageBody += '<br/><br/> Retrying DML via Queuable.';
            TackBotUtility.sendDevMail( 'RequestCategory__c Update Errors for user ' + UserInfo.getUserName() + ' [' + UserInfo.getUserId() + ']', messageBody );
            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            {
                try
                {
                    System.enqueueJob( new DMLQueueable( errorRecords, DMLQueueable.Operation.UPDATES ) );
                }
                catch (Exception ex)
                {
                    TackBotUtility.postTackLogException( ex, 'RequestCategoryOutreachTypeBatch.finish' );
                }
            }
        }
		
	}
	
}