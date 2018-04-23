public class MIUtility {
	
	public static List<String> miIncidentFields {

		get {

			if (miIncidentFields == null) {

				miIncidentFields = new List<String> (new Set<String> {
					'Id',
                    'IncidentNumber__c',
					'Name',
					'MICategory__c',
					'MISubcategory__c',
					'AmountInDispute__c',
					'DescriptionOfDispute__c',
					'DispositionTowardsThumbtack__c',
					'DoNotSurveyCustomer__c',
					'DoNotSurveyPro__c',
					'EscalationType__c',
					'EscalationDate__c',
					'Priority__c',
					'OutcomeCustomer__c',
					'OutcomePro__c',
                    'Origin__c',
                    'Status__c',
                    'LastActionStatus__c',
					'LastModifiedBy.Name',
					'LastModifiedDate',
                    'bid_id__c',
					'ModriaCaseNumber__c',
					'ModriaStatus__c',
					'NextFollowupDate__c',
					'NextFollowupTask__c',
					'NewCallFlag__c',
					'NewCaseFlag__c',
					'NewEmailFlag__c',
					'NewPostFlag__c',
					'Owner.Name',
					'OwnerId',
					'PreviouslyBannedUserID__c',
					'RecommendedAction__c',
                    'request_category__c',
					'request_id__c',
					'service_id__c',
                    'quotes_hired__c',
                    'request_create_time__c',
					'TotalPaidToPro__c',
					'quotes_hired__c',
                    'AmountResolvedByPro__c',
					'AmountResolvedbyTT__c',
                    'ReportedDate__c',
                    'RecognizedDamageDate__c',
                    'CustomerAccount__c',
                    'CustomerAccount__r.Name',
                    'CustomerAccount__r.usr_first_name__c',
                    'CustomerAccount__r.usr_last_name__c',
                    'CustomerEmail__c',
                    'CustomerPhone__c',
                    'customer_id__c',
					'CustomerContact__c',
					'CustomerContact__r.Email',
                    'CustomerContact__r.Name',    
                    'CustomerPhone__c',
                    'AdminLinkViewUserCustomer__c',
                    'ProAccount__c',
                    'ProAccount__r.Name',
                    'ProAccount__r.usr_first_name__c',
                    'ProAccount__r.usr_last_name__c',
                    'ProContact__r.Name',
                    'ProEmail__c',
                    'ProPhone__c',
					'ProContact__c',
					'ProContact__r.Email',
                    'ProPhone__c',
                    'pro_signup_date__c',
                    'pro_user_id__c',
                    'ProAccount__r.ManagedAccount__c',
                    'ProAccount__r.ManagedAccountRevenue__c',
                    'AdminLinkViewUserPro__c',
                    'TotalSuccessfulChargeAmount__c',
                    'TotalNumberofSuccessfulCharges__c',
                    'AdminLinkVerificationDataPro__c',
					'ExternalQuoteData__r.hired_time__c',
                    'ExternalQuoteData__r.pro_num_reviews__c',
					'ExternalQuoteData__r.pro_quotes_last_30__c',
                    'ExternalQuoteData__r.pro_num_quotes__c',    
					'ExternalQuoteData__r.pro_last_quote_time__c',
					'ExternalQuoteData__r.pro_avg_rating__c',
					'ExternalQuoteData__r.proassist_on__c',
					'ExternalQuoteData__r.pro_del_reason__c',
                    'ExternalQuoteData__r.review_rating__c',
                    'ExternalQuoteData__r.customer_lifetime_avg_review_rating__c',
                    'ExternalQuoteData__r.customer_lifetime_number_requests__c',
                    'ExternalQuoteData__r.customer_lifetime_number_reviews__c',
                    'ExternalQuoteData__r.customer_signup_date__c',
					'ExternalQuoteData__r.request_city__c',
					'ExternalQuoteData__r.request_state__c',
					'ExternalQuoteData__r.request_zip__c',
                    'ExternalQuoteData__r.bid_pk_id__c',
                    'ExternalQuoteData__r.request_pk_id__c',    
                    'ExternalQuoteData__r.pro_user_pk_id__c',   
                    'ExternalQuoteData__r.pro_url_code__c',    
                    'ExternalQuoteData__r.service_pk_id__c',
                    'ExternalQuoteData__r.customer_pk_id__c',
                    'ExternalQuoteData__r.customer_url_code__c',    
					'(Select Id, CaseRef__c, MICasePrimaryCustomer__c, MICasePrimaryPro__c From Cases__r Where MICasePrimaryPro__c = true Or MICasePrimaryCustomer__c = true)'
				});

			}
			return miIncidentFields;

		} private set;

	}

	public static List<String> miIncidentActionFields {

		get {

			if (miIncidentActionFields == null) {

				miIncidentActionFields = new List<String> (new Set<String> {
					'Id',
					'Name',
					'MIIncident__c',
					'RecordTypeId',
					'RecordType.DeveloperName',
					'Type__c',
					'Status__c',
					'Notes__c',
					'DueDate__c',
					'CreatedBy.Name', 
					'CreatedDate', 
					'LastModifiedDate',
					//'Link__c',
                    'IsVisibleToCS__c'
				});

			}
			return miIncidentActionFields;

		} private set;

	}

	public static List<String> emailMessageFields {

		get {

			if (emailMessageFields == null) {

				emailMessageFields = new List<String> (new Set<String> {
					'Id', 
					'ParentId', 
					'ActivityId', 
					'CreatedDate', 
					'HtmlBody', 
					'TextBody',
					'Headers', 
					'Subject', 
					'FromName', 
					'FromAddress', 
					'ToAddress', 
					'CcAddress', 
					'BccAddress', 
					'Incoming', 
					'HasAttachment', 
					'Status', 
					'MessageDate',
					'Parent.AccountId',
					'Parent.ContactId'
				});

			}
			return emailMessageFields;

		} private set;

	}

	public static List<String> taskFields {

		get {

			if (taskFields == null) {

				taskFields = new List<String> (new Set<String> {
					'Id', 
					'WhatId', 
					'Who.Name',
					'Type',
					'Description',
					'CreatedDate',
					'CreatedBy.Name'
				});

			}
			return taskFields;

		} private set;

	}

	public static Set<Id> getCaseIds(Id incidentId, Id contactId)
	{
		return getCases(incidentId, contactId).keySet();
	}

	public static Map<Id, Case> getCases(Id incidentId, Id contactId)
	{
		Map<Id, Case> caseMap = new Map<Id, Case>();

		if (incidentId != null)
		{
			caseMap = new Map<Id, Case>(
					(List<Case>) Database.query(
							'Select Id, AccountId, ContactId From Case Where Incident__c = :incidentId '
									+ (contactId == null ? '' : 'And ContactId = :contactId ')
					)
			);
		}

		return caseMap;
	}
}