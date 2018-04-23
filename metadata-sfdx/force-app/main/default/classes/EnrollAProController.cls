/*
 Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.      

Version  Date     	 Author            	Description                          
=======+===========+==================+======================================
1.0      2017-03-27  Travis Oliver      Created 
1.1		 2017-08-21	 Meena Pisupati	    Updated ago8Hours limit to 48 hrs
1.2		 2017-09-21	 Meena Pisupati		Replaced ProAssist with Instant Match,
										Updated Header
1.3 	 2017-10-31	 Meena Pisupati		Added categoryIdFilter, funnelStepFilter
										to query on !timezone.empty() 
1.4      2018-01-16  Meena Pisupati		Updated Enroll a Pro logic to include 
										new outreach types and Assigned to
=======+===========+==================+======================================*/
public class EnrollAProController {

    @TestVisible
    private static List<Enrollment__c> testEnrollments;
    @TestVisible
    private static List<Enrollment__c> testCallbackEnrollments;

    @AuraEnabled
    public static Id enrollAPro() {

        Id result;
        Map<String, List<Map<String, String>>> userFilter = EAPFilterController.getUserFilter(null);
        List<String> outreachTypes = new List<String> ();
        List<String> outreachGroups = new List<String> ();
        List<String> categoryIds = new List<String> ();
        List<String> funnelSteps = new List<String> ();
        Set<String> noMarketOutreachTypes = new Set<String>{'managed_account', 'pro_onboarding', 'pro_engagement'};
        String outreachTypeFilter = '';
        String outreachGroupFilter = '';
        String categoryIdFilter = '';
        String funnelStepFilter = '';
        if (userFilter != null && !userFilter.isEmpty()) {

            outreachTypeFilter = getFilterString(userFilter, 'outreach_type__c', 'Market__r.RequestCategory__r.outreach_type__c', outreachTypes, 'outreachTypes');
            outreachGroupFilter = getFilterString(userFilter, 'outreach_group__c', 'outreach_group__c', outreachGroups, 'outreachGroups');
            categoryIdFilter = getFilterString(userFilter, 'RequestCategory__c', 'Market__r.RequestCategory__c', categoryIds, 'categoryIds');
            funnelStepFilter = getFilterString(userFilter, 'FunnelStep__c', 'FunnelStep__c', funnelSteps, 'funnelSteps');

        }
        Datetime ago15Minutes = Datetime.now().addMinutes(-15);
        Datetime ahead5Minutes = Datetime.now().addMinutes(5);
        Datetime ago8Hours = Datetime.now().addHours(-24); //Changed value from -8hrs to -24hrs - Added by MP
        Id userId = UserInfo.getUserId();
        List<String> timeZones = getTimeZonesAllowedToCall();
        if (!timeZones.isEmpty() || Test.isRunningTest()) {
                 String query = 'Select Id, Account__c From Enrollment__c '
                + 'Where Account__c != null '
                + 'And ((Market__c != null '
                + 'And Market__r.RequestCategory__c != null) '
                + 'Or outreach_type__c IN :noMarketOutreachTypes) '
                + 'And Account__r.EnrollmentCallbackDateTime__c != null '
                + 'And Account__r.EnrollmentCallbackDateTime__c < :ahead5Minutes '
                + 'And (Account__r.EnrollmentAssignedTo__c = null '
                + 'Or Account__r.EnrollmentAssignedTo__c = :userId '
                + 'Or Account__r.EnrollmentCallbackDateTime__c < :ago15Minutes) '
                + 'And TimezoneFromAdmin__c IN :timeZones '
                + outreachTypeFilter
                + outreachGroupFilter
                + categoryIdFilter
                + funnelStepFilter
                + 'order by PriorityFromAnalytics__c '
                + 'limit 1 ' ;
            System.debug(query);
           	List<Enrollment__c> enrollments = (List<Enrollment__c>) Database.query(query);
            
            enrollments = Test.isRunningTest() ? testCallbackEnrollments : enrollments;
            system.debug('Enrollment size from query 1: '+enrollments.size());
            if (enrollments.isEmpty()) {
			system.debug('In here : second query');
                 query = 'Select Id, Account__c From Enrollment__c '
                        + 'Where Account__c != null '
                        + 'And Account__r.EnrollmentCallbackDateTime__c = null '
                        + 'And (Account__r.EnrollmentAssignedTo__c = null '
                        + 'Or Account__r.EnrollmentAssignedTo__c = :userId) '
                        + 'And ((Market__c != null '
                        + 'And Market__r.RequestCategory__c != null '
                        + 'And Market__r.RequestCategory__r.outreach_type__c != null '
                        + 'And Market__r.EnrollAProEnabled__c = true '
                        + 'And Market__r.RequestCategory__r.EnrollAProEnabled__c = true) '
                        + 'Or (outreach_type__c IN :noMarketOutreachTypes)) '
                        + 'And UnsuccessfulReason__c = null '
                        + 'And CallbackOutreachType__c = null '
                        + 'And FunnelStep__c NOT IN (\'Enrolled\', \'Live on Instant Match\', \'Completed\') '
                        + 'And OutreachAttemptsRemaining__c > 0 '
                        + 'And ((Account__r.LastEnrollmentOutreachAttempt__c = null '
                        + 'And LastOutreachAttempt__c = null) '
                        + 'Or (Account__r.LastEnrollmentOutreachAttempt__c < :ago8Hours '
                        + 'And LastOutreachAttempt__c < :ago8Hours) '
                        + 'Or (Account__r.LastEnrollmentOutreachAttempt__c < :ago8Hours '
                        + 'And LastOutreachAttempt__c = null) '
                        + 'Or (Account__r.LastEnrollmentOutreachAttempt__c = null '
                        + 'And LastOutreachAttempt__c < :ago8Hours)) '
                        + 'And TimezoneFromAdmin__c IN :timeZones '
                        + outreachTypeFilter
                        + categoryIdFilter
                        + funnelStepFilter
                        + outreachGroupFilter
                        + 'order by PriorityFromAnalytics__c '
                        + 'limit 1 ';

                System.debug(query);                
                enrollments = (List<Enrollment__c>) Database.query(query);
                enrollments = Test.isRunningTest() ? testEnrollments : enrollments;
            }
            if (!enrollments.isEmpty()) {

                Enrollment__c enrollment = enrollments[0];
                result = enrollment.Id;                
                Account acc = [Select Id, EnrollmentAssignedTo__c, EnrollmentCallbackDateTime__c From Account Where Id = :enrollment.Account__c];
                acc.EnrollmentAssignedTo__c = UserInfo.getUserId();
                if (acc.EnrollmentCallbackDateTime__c != null) {

                    acc.EnrollmentCallbackDateTime__c = Datetime.now();

                }
                update acc;

            }

        }
        return result;

    }

    private static List<String> getTimeZonesAllowedToCall() {

        Map<Boolean, List<String>> result = new Map<Boolean, List<String>> {
            true => new List<String> (),
            false => new List<String> ()
        };
        Integer hour = Datetime.now().hour();
        result.get(hour >= 6 && hour < 19).add('America/St_Kitts');
        result.get(hour >= 6 && hour < 19).add('America/New_York');
        result.get(hour >= 7 && hour < 20).add('America/Chicago');
        result.get(hour >= 8 && hour < 21).add('America/Denver');
        result.get(hour >= 9 && hour < 22).add('America/Los_Angeles');
        result.get(hour >= 9 && hour < 22).add('America/Phoenix');
        result.get(hour >= 10 && hour < 23).add('America/Juneau');
        result.get(hour >= 12 && hour < 24).add('Pacific/Honolulu');
        return result.get(true);

    }

    private static String getFilterString(Map<String, List<Map<String, String>>> userFilter, String key, String fieldName, List<String> values, String valuesListName) {
        String stringFilter = '';
        Boolean hasNoMarketOutreachType = false;

        if (userFilter.containsKey(key)) {
			system.debug('In here'+key);
            system.debug('Value of the key'+userFilter.get(key));
            List<Map<String, String>> options = userFilter.get(key);
            if (options != null && !options.isEmpty()) 
            {
                for (Map<String, String> option : options) 
                {
					String optionValue = option.get('value');
                    values.add(optionValue);

                    if('managed_account'.equals(optionValue) || 'pro_engagement'.equals(optionValue) || 'pro_onboarding'.equals(optionValue))
                    {
                        hasNoMarketOutreachType = true;
                    }
                }

                if('outreach_type__c'.equals(key) && hasNoMarketOutreachType)
                {
                    List<Map<String, String>> optionsList = userFilter.get(key);
                    for(Map<String, String> opt : optionsList)
                    {
                    String optionValue = opt.get('value');
                    values.add(optionValue);
                    }
                    stringFilter = 'And (' + fieldName + ' IN :' + valuesListName + ' OR outreach_type__c  IN (\''+String.join(values,'\',\'')+'\')) ';
                }
                else
                {
                    stringFilter = 'And ' + fieldName + ' IN :' + valuesListName + ' ';
                }

            }

        }
        return stringFilter;

    }

}