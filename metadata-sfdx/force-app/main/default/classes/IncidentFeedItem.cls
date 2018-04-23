public class IncidentFeedItem implements Comparable {

	@AuraEnabled
	public String itemType {get; set;}
	@AuraEnabled
	public Datetime sortDate {get; set;}
	@AuraEnabled
	public String personName {get; set;}
	@AuraEnabled
	public String summary {get; set;}
	@AuraEnabled
	public String details {get; set;}
	@AuraEnabled
	public String detailType {get; set;}
	@AuraEnabled
	public MIIncidentAction__c action {get; set;}
	@AuraEnabled
	public MIIncidentAction__History history {get; set;}
	@AuraEnabled
	public EmailMessage email {get; set;}
	@AuraEnabled
	public Task phoneCall {get; set;}
	@AuraEnabled
	public CaseFeed caseFeed {get; set;}
	@AuraEnabled
	public CaseComment caseComment {get; set;}
	@AuraEnabled
	public IncidentFactorAssignment__c factorAssignment {get; set;} 

	@AuraEnabled
	public String accountId{get;set;}
	@AuraEnabled
	public String contactId{get;set;}

	public IncidentFeedItem() {
		
	}

	public Integer compareTo(Object compareTo) {

		Integer result = 0;
		IncidentFeedItem item = (IncidentFeedItem) compareTo;
		if (this.sortDate > item.sortDate) result = -1;
		if (this.sortDate < item.sortDate) result = 1;
		return result;

	}

}