public class RelatedListSetting {

	@AuraEnabled
	public String tableName {get; set;}
	@AuraEnabled
	public String objectName {get; set;}
	@AuraEnabled
	public String queryFieldSetName {get; set;}
	@AuraEnabled
	public String relationshipFieldName {get; set;}
	@AuraEnabled
	public String orderFieldName {get; set;}
	@AuraEnabled
	public String sortDirection {get; set;}
	@AuraEnabled
	public Integer recordsPerPage {get; set;}
	@AuraEnabled
	public String parentObjectName {get; set;}
	@AuraEnabled
	public String parentReferenceFieldName {get; set;}
	@AuraEnabled
	public String referenceId {get; set;}
	@AuraEnabled
	public List<Map<String, String>> fields {get; set;}

	public RelatedListSetting() {}

	public RelatedListSetting(RelatedListSetting__mdt setting) {
		
		tableName = setting.TableName__c;
		objectName = setting.ObjectAPIName__c;
		orderFieldName = setting.OrderFieldAPIName__c;
		queryFieldSetName = setting.QueryFieldSetName__c;
		recordsPerPage = Integer.valueOf(setting.RecordsPerPage__c);
		relationshipFieldName = setting.RelationshipFieldAPIName__c;
		sortDirection = setting.SortDirection__c;
		parentObjectName = setting.ParentObjectAPIName__c;
		parentReferenceFieldName = setting.ParentRefrenceFieldAPIName__c;

	}

}