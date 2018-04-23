public class RelatedListController {

	@AuraEnabled
	public static List<RelatedListSetting> getRelatedListsForPageName(String sectionName) {

		List<RelatedListSetting> result = new List<RelatedListSetting> ();
		if (String.isNotBlank(sectionName)) {

			for (RelatedListSetting__mdt setting : [Select ObjectAPIName__c, OrderFieldAPIName__c, TableName__c, ParentObjectAPIName__c, ParentRefrenceFieldAPIName__c,
													QueryFieldSetName__c, RecordsPerPage__c, RelationshipFieldAPIName__c, SortDirection__c
													From RelatedListSetting__mdt
													Where RelatedListSectionName__c = :sectionName
													order by TableDisplayOrder__c]) {

				result.add(new RelatedListSetting (setting));

			}

		}
		return result;

	}

	@AuraEnabled
	public static RelatedListSetting getRelatedListInfo(String parentObjectName, String parentReferenceFieldName, Id recordId, String objectName, String fieldSetName) {

		RelatedListSetting result = new RelatedListSetting ();
		result.referenceId = getParentReferenceId(parentObjectName, parentReferenceFieldName, recordId);
		result.fields = getFieldsFromFieldSet(objectName, fieldSetName);
		return result;

	}

	private static String getParentReferenceId(String parentObjectName, String parentReferenceFieldName, Id recordId) {

		String result;
		if (String.isNotBlank(parentObjectName) && String.isNotBlank(parentReferenceFieldName)) {

			SObject record = Database.query(
				'Select ' + parentReferenceFieldName + ' From ' + parentObjectName + ' Where Id = :recordId '
			);
			result = (String) record.get(parentReferenceFieldName);

		}
		return result;

	}
	
	private static List<Map<String, String>> getFieldsFromFieldSet(String objectName, String fieldSetName) {

		List<Map<String, String>> result = new List<Map<String, String>> ();
		if (String.isNotBlank(objectName) && String.isNotBlank(fieldSetName)) {

			Schema.DescribeSObjectResult[] describeResults = Schema.describeSObjects(new String[] {objectName});
            List<Schema.FieldSetMember> members = describeResults[0].fieldSets.getMap().get(fieldSetName).getFields();
            Map<String, Schema.SObjectField> fieldMap = describeResults[0].fields.getMap();
            for (Schema.FieldSetMember member : members) {

            	String fieldName = member.getFieldPath();
            	Schema.DisplayType displayType = fieldMap.get(fieldName).getDescribe().getType();
            	String dataType = 'non-date';
            	if (displayType == Schema.DisplayType.Date) {

            		dataType = 'date';

            	} else if (displayType == Schema.DisplayType.DateTime) {

            		dataType = 'datetime';

            	}
            	result.add(new Map<String, String> {
            		'name' => fieldName,
            		'label' => member.getLabel(),
            		'dataType' => dataType
            	});

            }

		}
		return result;

	}

	@AuraEnabled
	public static List<sObject> getRecords(String objectName, String relationshipFieldName, String referenceId, List<String> queryFields, String orderField, String sortDirection, Integer recordsPerPage, Integer pageNumber) {

		List<sObject> result = new List<sObject> ();
		if (String.isNotBlank(objectName) && String.isNotBlank(relationshipFieldName) && String.isNotBlank(referenceId) && queryFields != null && !queryFields.isEmpty()) {

			String query = 'Select ' + String.join(queryFields, ', ') + ' From ' + objectName + ' ';
			query += 'Where ' + relationshipFieldName + ' = :referenceId ';
			if (String.isNotBlank(orderField)) {

				query += 'order by ' + orderField + ' ';
				if (String.isNotBlank(sortDirection)) {

					query += sortDirection + ' ';

				}

			}
			Integer i_recordsPerPage = Integer.valueOf(recordsPerPage);
			if (i_recordsPerPage != null && i_recordsPerPage > 0) {

				query += 'limit ' + i_recordsPerPage + ' ';
				Integer i_pageNumber = Integer.valueOf(pageNumber);
				Integer offset = i_recordsPerPage * i_pageNumber;
				if (i_pageNumber != null && i_pageNumber > 0) {

					query += 'offset ' + offset + ' ';

				}

			}
			result = Database.query(query);

		}
		return result;

	}

}