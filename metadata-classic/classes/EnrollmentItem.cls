public class EnrollmentItem {

	@AuraEnabled
	public String name {get; set;}
	@AuraEnabled
	public String link {get; set;}
    @AuraEnabled
	public String color {get; set;}
	@AuraEnabled
	public EnrollmentAction__c action {get; set;}
	@AuraEnabled
	public EnrollmentRule__c onlyRule {get; set;}
	@AuraEnabled
	public List<String> outcomes {get; set;}
	@AuraEnabled
	public Map<Id, EnrollmentRule__c> ruleMap {get; set;}
	@AuraEnabled
	public Map<String, List<EnrollmentRule__c>> rulesByOutcome {get; set;}
	@AuraEnabled
	public Map<String, List<String>> detailsByOutcome {get; set;}
	@AuraEnabled
	public Map<String, EnrollmentRule__c> rulesByDetail {get; set;}
	@AuraEnabled
	public EnrollmentRule__c completedRule {get; set;}
	@AuraEnabled
	public Boolean isAutonomous {get; set;}
	@AuraEnabled
	public Boolean isAutomated {get; set;}
	@AuraEnabled
	public String subSteps {get; set;}
	@AuraEnabled
	public Boolean isURLRequired {get; set;}
	@AuraEnabled
	public String prereqRuleName {get; set;}
	@AuraEnabled
	public String prereqRuleOutcome {get; set;}
	@AuraEnabled
	public Boolean showItem {get; set;}
	@AuraEnabled
	public Integer displayOrder {get; set;}
	@AuraEnabled
	public Datetime callbackDateTime {get; set;}
	@AuraEnabled
	public String callbackDateTimeString {get; set;}
	@AuraEnabled
	public String callbackOrigin {get; set;}
	@AuraEnabled
	public String callbackPhone {get; set;}
	@AuraEnabled
	public String callbackScheduledBy {get; set;}
	@AuraEnabled
	public Boolean isCallbackRule {get; set;}
	@AuraEnabled
	public Boolean isRequiredBasedOnPrereqs {get; set;}

	public EnrollmentItem() {
		
		outcomes = new List<String> ();
		rulesByOutcome = new Map<String, List<EnrollmentRule__c>> ();
		detailsByOutcome = new Map<String, List<String>> ();
		rulesByDetail = new Map<String, EnrollmentRule__c> ();
		ruleMap = new Map<Id, EnrollmentRule__c> ();
		isAutonomous = false;
		isAutomated = false;
		isURLRequired = false;
		showItem = true;
		isCallbackRule = false;

	}

	public EnrollmentItem(Enrollment__c enrollment) {

		this();
		if (enrollment.Account__r.EnrollmentCallbackDateTime__c != null) {

			callbackDateTime = enrollment.Account__r.EnrollmentCallbackDateTime__c;
			callbackDateTimeString = enrollment.Account__r.EnrollmentCallbackDateTime__c.format('MM/dd/yyyy hh:mm a');
			callbackOrigin = enrollment.Account__r.EnrollmentCallbackOrigin__c;
			callbackPhone = enrollment.Account__r.EnrollmentCallbackPhone__c;
			callbackScheduledBy = enrollment.Account__r.EnrollmentCallbackScheduledBy__r.Name;

		}

	}

	public void addRule(EnrollmentRule__c rule) {

		if (rule != null) {

			name = rule.Name;
			link = rule.EnrollmentLink__c;
            color = rule.EnrollmentActionColor__c;
			ruleMap.put(rule.Id, rule);
			isAutonomous = rule.IsAutonomous__c;
			isAutomated = rule.IsAutomatedAction__c;
			isURLRequired = rule.URLRequired__c;
			prereqRuleName = rule.PrerequisiteRuleName__c;
			prereqRuleOutcome = rule.PrerequisiteRuleOutcome__c;
			showItem = String.isBlank(prereqRuleName);
			displayOrder = Integer.valueOf(rule.EnrollmentActionOrder__c);
			isCallbackRule = rule.IsCallbackRule__c;
			isRequiredBasedOnPrereqs = rule.IsRequiredBasedOnPrerequisites__c;
			if (String.isNotBlank(rule.EnrollmentActionOutcome__c)) {

				List<EnrollmentRule__c> outcomeRules = rulesByOutcome.get(rule.EnrollmentActionOutcome__c);
				outcomeRules = outcomeRules == null ? new List<EnrollmentRule__c> () : outcomeRules;
				outcomeRules.add(rule);
				if (!rulesByOutcome.containsKey(rule.EnrollmentActionOutcome__c)) {

					outcomes.add(rule.EnrollmentActionOutcome__c);

				}
				rulesByOutcome.put(rule.EnrollmentActionOutcome__c, outcomeRules);
				if (String.isNotBlank(rule.Details__c)) {

					List<String> details = detailsByOutcome.get(rule.EnrollmentActionOutcome__c);
					details = details == null ? new List<String> () : details;
					details.add(rule.Details__c);
					detailsByOutcome.put(rule.EnrollmentActionOutcome__c, details);

					rulesByDetail.put(rule.Details__c, rule);

				}

			} else {

				this.onlyRule = rule;

			}
			if (String.isNotBlank(rule.SubSteps__c)) {

				this.subSteps = rule.SubSteps__c;

			}

		}

	}

	public void addAction(EnrollmentAction__c action) {

		if (action != null && String.isNotBlank(action.RuleId__c)) {

			EnrollmentRule__c rule = ruleMap.get(action.RuleId__c);
			if (!rule.IsCallbackRule__c || (rule.IsCallbackRule__c && action.CompletedOn__c >= callbackDateTime)) {

				this.action = action;
				this.completedRule = ruleMap.get(action.RuleId__c);

			}

		}

	}

}