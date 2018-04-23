/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     03-21-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@isTest
private class CheckrAPITest {
    private static Id cRTId=Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
    @isTest static void testGetCheckrById() 
    {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"6aeb5a753e16a8fb20c320f0","object":"report","uri":"/v1/reports/6aeb5a753e18fb20c320f0","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","upgraded_at":null,"turnaround_time":561,"due_time":"2017-06-05T04:27:05Z","package":"tasker_basic","tags":[],"adjudication":null,"candidate":{"id":"e0b44ae8beb853b8f1b5f9","object":"candidate","uri":"/v1/candidates/e0b44ae8beb3a3b8f1b5f9","created_at":"2017-05-28T04:27:05Z","first_name":"Vi","last_name":"Vic","middle_name":"Ly","mother_maiden_name":null,"dob":"1970-02-15","ssn":"XXX-XX-2345","email":"vic@verizon.net","zipcode":"19734","phone":"3023587772","driver_license_state":null,"driver_license_number":null,"copy_requested":true,"previous_driver_license_state":null,"previous_driver_license_number":null,"adjudication":null,"custom_id":"3gqb73is","no_middle_name":false,"report_ids":["6aeb5a753e16ab20c320f0"],"geo_ids":[]},"county_criminal_searches":[{"id":"592a519f9b64002ccc85ac","object":"county_criminal_search","uri":"/v1/county_criminal_searches/592a519f9bd4002ccc85ac","status":"consider","county":"Delaware","state":"PA","created_at":"2017-05-28T04:27:11Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":555,"records":[{"id":"592a53ca0a4733003a214ded","case_number":"MJ-32136-CR-0000259-2011","file_date":"2011-05-24","arresting_agency":null,"court_jurisdiction":"AOC - PENNSYLVANIA - DELAWARE COUNTY","court_of_record":null,"dob":"1973-02-15","yob":1973,"full_name":"VICTORIA LYNNE VICKERS","county":"DELAWARE","state":"PA","charges":[{"charge":"SIMPLE ASSAULT (STATUTE: 18-2701-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"HARASSMENT - SUBJECT OTHER TO PHYSICAL CONTACT (STATUTE: 18-2709-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"DISORDERLY CONDUCT ENGAGE IN FIGHTING (STATUTE: 18-5503-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null}],"address":{"street":"Marcu","unit":"","city":"Hook","state":"PA","zipcode":"19062","county":null}}]}],"document_ids":["0679dc9d77308c6a9ed6"],"federal_criminal_search_id":null,"global_watchlist_search":{"id":"592a519901ee009bb1f107","object":"global_watchlist_search","uri":"/v1/global_watchlist_searches/592a519901a2009bb1f107","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:33:22Z","turnaround_time":377,"records":[]},"motor_vehicle_report_id":null,"national_criminal_search":{"id":"592a5191a2ee009bb1f105","object":"national_criminal_search","uri":"/v1/national_criminal_searches/59219901a2ee009bb1f105","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":561,"records":[]},"personal_reference_verification_ids":[],"professional_reference_verification_ids":[],"sex_offender_search":{"id":"592a519902ee009bb1f106","object":"sex_offender_search","uri":"/v1/sex_offender_searches/92a51990a2ee009bb1f106","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:30:11Z","turnaround_time":186,"records":[]},"ssn_trace_id":"592a519901a2ee009b1f104","state_criminal_search_ids":[],"terrorist_watchlist_search_id":"592a519901a2e009bb1f107","facis_search_id":null}',
                                                   null);
        
        Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;
            Id accountRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account a = new Account(Name='Chester Tester',RecordTypeId=accountRTId,usr_email__c = 'test@test.com');
            insert a;
            Case cas = new Case(BGCReportId__c = '1234',Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Other',SubCategory__c='Trigger Testing',SuppliedEmail='test@test.com',Subject ='CONSIDER',Description ='The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team');
            insert cas;
            cas.BGCReportId__c = '1234';
            update cas;
            Case cas2 = new Case(BGCReportId__c = '12345',Subject = 'test2',Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Other',SubCategory__c='Trigger Testing',SuppliedEmail='test2@test.com');
            insert cas2;
            cas2.BGCReportId__c = '12345';
            update cas2;
           
            BackgroundCheck__c bCheck = new BackgroundCheck__c(ReportId__c='1234',Name = 'testtest',CandidateName__c='test',CandidateId__c='1234',CountyCriminalSearchId__c= '1234',StateCriminalSearchId__c='12345');
            insert bCheck;
            List<String> bIDs = new List<String>();
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        
                bIDs.add(bCheck.id);
       
        System.runAs(testUser) 
        {
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            Test.startTest();
                CheckrAPI.getCheckr(bIDs);
            Test.stopTest();
            List<Case> cases = [SELECT Id FROM Case ];
            system.debug('cases: '+cases);
        }
    }
    @isTest static void testGetReports() 
    {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"6aeb5a753e16a8fb20c320f0","object":"report","uri":"/v1/reports/6aeb5a753e18fb20c320f0","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","upgraded_at":null,"turnaround_time":561,"due_time":"2017-06-05T04:27:05Z","package":"tasker_basic","tags":[],"adjudication":null,"candidate":{"id":"e0b44ae8beb853b8f1b5f9","object":"candidate","uri":"/v1/candidates/e0b44ae8beb3a3b8f1b5f9","created_at":"2017-05-28T04:27:05Z","first_name":"Vi","last_name":"Vic","middle_name":"Ly","mother_maiden_name":null,"dob":"1970-02-15","ssn":"XXX-XX-2345","email":"vic@verizon.net","zipcode":"19734","phone":"3023587772","driver_license_state":null,"driver_license_number":null,"copy_requested":true,"previous_driver_license_state":null,"previous_driver_license_number":null,"adjudication":null,"custom_id":"3gqb73is","no_middle_name":false,"report_ids":["6aeb5a753e16ab20c320f0"],"geo_ids":[]},"county_criminal_searches":[{"id":"592a519f9b64002ccc85ac","object":"county_criminal_search","uri":"/v1/county_criminal_searches/592a519f9bd4002ccc85ac","status":"consider","county":"Delaware","state":"PA","created_at":"2017-05-28T04:27:11Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":555,"records":[{"id":"592a53ca0a4733003a214ded","case_number":"MJ-32136-CR-0000259-2011","file_date":"2011-05-24","arresting_agency":null,"court_jurisdiction":"AOC - PENNSYLVANIA - DELAWARE COUNTY","court_of_record":null,"dob":"1973-02-15","yob":1973,"full_name":"VICTORIA LYNNE VICKERS","county":"DELAWARE","state":"PA","charges":[{"charge":"SIMPLE ASSAULT (STATUTE: 18-2701-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"HARASSMENT - SUBJECT OTHER TO PHYSICAL CONTACT (STATUTE: 18-2709-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"DISORDERLY CONDUCT ENGAGE IN FIGHTING (STATUTE: 18-5503-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null}],"address":{"street":"Marcu","unit":"","city":"Hook","state":"PA","zipcode":"19062","county":null}}]}],"document_ids":["0679dc9d77308c6a9ed6"],"federal_criminal_search_id":null,"global_watchlist_search":{"id":"592a519901ee009bb1f107","object":"global_watchlist_search","uri":"/v1/global_watchlist_searches/592a519901a2009bb1f107","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:33:22Z","turnaround_time":377,"records":[]},"motor_vehicle_report_id":null,"national_criminal_search":{"id":"592a5191a2ee009bb1f105","object":"national_criminal_search","uri":"/v1/national_criminal_searches/59219901a2ee009bb1f105","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":561,"records":[]},"personal_reference_verification_ids":[],"professional_reference_verification_ids":[],"sex_offender_search":{"id":"592a519902ee009bb1f106","object":"sex_offender_search","uri":"/v1/sex_offender_searches/92a51990a2ee009bb1f106","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:30:11Z","turnaround_time":186,"records":[]},"ssn_trace_id":"592a519901a2ee009b1f104","state_criminal_search_ids":[],"terrorist_watchlist_search_id":"592a519901a2e009bb1f107","facis_search_id":null}',
                                                   null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        //Test.setMock(HttpCalloutMock.class, new CheckrGetSubReportsMock());
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
            CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            Id accountRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account a = new Account(Name='Chester Tester',RecordTypeId=accountRTId,usr_email__c = 'test@test.com',usr_user_id__c = 12345);
            insert a;
            
            Case cas = new Case(BGCReportId__c = '1234',Subject ='CONSIDER',Description ='The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team',Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Other',SubCategory__c='Trigger Testing',SuppliedEmail='test@test.com');
            
            insert cas;
            cas.BGCReportId__c = '1234';
            update cas;
          
           BackgroundCheck__c b = new BackgroundCheck__c(ReportId__c='1234',Name = 'testtest',CandidateName__c='test',CandidateId__c='1234',CountyCriminalSearchId__c= '1234',StateCriminalSearchId__c='12345');
            insert b;
        
            Test.startTest();
            
            CheckrAPI.getReports(b.Id);

            //String result = '{"id":"b197030eda2c81c26e05f6b7","object":"report","uri":"/v1/reports/b197030eda2c81c26e05f6b7","status":"consider","created_at":"2017-03-03T21:38:32Z","completed_at":"2017-03-07T13:20:51Z","upgraded_at":null,"turnaround_time":315739,"due_time":"2017-03-11T21:38:32Z","package":"tasker_basic","tags":[],"adjudication":null,"candidate_id":"78d74adef04f3ac9bf2f3db7","county_criminal_search_ids":["58ba2644e9cfef003c59cff7","58ba2644e9cfef003c59cff7"],"document_ids":["526cb27219041cf8ec475307"],"federal_criminal_search_id":"1234","global_watchlist_search_id":"58b9e258003cd100834c345e","motor_vehicle_report_id":null,"national_criminal_search_id":"58b9e258003cd100834c345c","personal_reference_verification_ids":[],"professional_reference_verification_ids":[],"sex_offender_search_id":"58b9e258003cd100834c345d","ssn_trace_id":"58b9e258003cd100834c345b","state_criminal_search_ids":[],"terrorist_watchlist_search_id":"58b9e258003cd100834c345e","facis_search_id":null}';
            //b = CheckrAPI.doLogic(b,result);
            Test.stopTest();
        }
    } 
    @isTest static void testGetReportsBulk() 
    {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"id":"6aeb5a753e16a8fb20c320f0","object":"report","uri":"/v1/reports/6aeb5a753e18fb20c320f0","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","upgraded_at":null,"turnaround_time":561,"due_time":"2017-06-05T04:27:05Z","package":"tasker_basic","tags":[],"adjudication":null,"candidate":{"id":"e0b44ae8beb853b8f1b5f9","object":"candidate","uri":"/v1/candidates/e0b44ae8beb3a3b8f1b5f9","created_at":"2017-05-28T04:27:05Z","first_name":"Vi","last_name":"Vic","middle_name":"Ly","mother_maiden_name":null,"dob":"1970-02-15","ssn":"XXX-XX-2345","email":"vic@verizon.net","zipcode":"19734","phone":"3023587772","driver_license_state":null,"driver_license_number":null,"copy_requested":true,"previous_driver_license_state":null,"previous_driver_license_number":null,"adjudication":null,"custom_id":"3gqb73is","no_middle_name":false,"report_ids":["6aeb5a753e16ab20c320f0"],"geo_ids":[]},"county_criminal_searches":[{"id":"592a519f9b64002ccc85ac","object":"county_criminal_search","uri":"/v1/county_criminal_searches/592a519f9bd4002ccc85ac","status":"consider","county":"Delaware","state":"PA","created_at":"2017-05-28T04:27:11Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":555,"records":[{"id":"592a53ca0a4733003a214ded","case_number":"MJ-32136-CR-0000259-2011","file_date":"2011-05-24","arresting_agency":null,"court_jurisdiction":"AOC - PENNSYLVANIA - DELAWARE COUNTY","court_of_record":null,"dob":"1973-02-15","yob":1973,"full_name":"VICTORIA LYNNE VICKERS","county":"DELAWARE","state":"PA","charges":[{"charge":"SIMPLE ASSAULT (STATUTE: 18-2701-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"HARASSMENT - SUBJECT OTHER TO PHYSICAL CONTACT (STATUTE: 18-2709-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null},{"charge":"DISORDERLY CONDUCT ENGAGE IN FIGHTING (STATUTE: 18-5503-A1)","charge_type":"unknown","charge_id":null,"classification":"unknown","deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"WITHDRAWN","probation_status":null,"offense_date":"2011-05-23","deposition_date":null,"arrest_date":null,"charge_date":"2011-05-24","sentence_date":null,"disposition_date":"2011-07-27","conviction_date":null,"release_date":null,"court":null,"plea":null}],"address":{"street":"Marcu","unit":"","city":"Hook","state":"PA","zipcode":"19062","county":null}}]}],"document_ids":["0679dc9d77308c6a9ed6"],"federal_criminal_search_id":null,"global_watchlist_search":{"id":"592a519901ee009bb1f107","object":"global_watchlist_search","uri":"/v1/global_watchlist_searches/592a519901a2009bb1f107","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:33:22Z","turnaround_time":377,"records":[]},"motor_vehicle_report_id":null,"national_criminal_search":{"id":"592a5191a2ee009bb1f105","object":"national_criminal_search","uri":"/v1/national_criminal_searches/59219901a2ee009bb1f105","status":"consider","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:36:26Z","turnaround_time":561,"records":[]},"personal_reference_verification_ids":[],"professional_reference_verification_ids":[],"sex_offender_search":{"id":"592a519902ee009bb1f106","object":"sex_offender_search","uri":"/v1/sex_offender_searches/92a51990a2ee009bb1f106","status":"clear","created_at":"2017-05-28T04:27:05Z","completed_at":"2017-05-28T04:30:11Z","turnaround_time":186,"records":[]},"ssn_trace_id":"592a519901a2ee009b1f104","state_criminal_search_ids":[],"terrorist_watchlist_search_id":"592a519901a2e009bb1f107","facis_search_id":null}',
                                                   null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        //Test.setMock(HttpCalloutMock.class, new CheckrGetSubReportsMock());
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(testUser) 
        {
            CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;
            
            List<BackgroundCheck__c> bchecks = new List<BackgroundCheck__c>();
          for(Integer i = 0;i<200;i++)
          {
            BackgroundCheck__c b = new BackgroundCheck__c(Name = 'testtest'+i,CandidateName__c='test',CandidateId__c='1234'+i,CountyCriminalSearchId__c= '1234',StateCriminalSearchId__c='12345');
            bchecks.add(b);
          }
           
            insert bchecks;
            integer i = 0;
        for(BackgroundCheck__c b:bchecks)
        {
            b.ReportId__c='1234'+i;
            i++;
        }
        update bchecks;
            Test.startTest();
                CheckrAPI.getReportsBulk();
            Test.stopTest();
        }
    } 
    @isTest static void testGetAdverseItems() 
    {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                  'Complete',
                                                  '{"data":[{"id":"58d2b83c9e4f49007356dacd","object":"adverse_item","text":"CHARGE: STRANGULATION (DISPOSITION: GUILTY)"},{"id":"58d2b83c9e49007356dact","object":"adverse_item","text":"CHARGE: DOMESTIC BATTERY WITH PRIOR UNRELATED CONVICTION (DISPOSITION: GUILTY)"},{"id":"58d2b83c9449007356dacf","object":"adverse_item","text":"CHARGE: DOMESTIC BATTERY (DISPOSITION: DISMISSED)"},{"id":"58d2b83c9e4f490066dad0","object":"adverse_item","text":"CHARGE: DOMESTIC BATTERY COMMITTED IN PRESENCE OF CHILD LESS THAN 16 YEARS OF AGE (DISPOSITION: DISMISSED)"},{"id":"58d2b83c9e4f43337356dad1","object":"adverse_item","text":"CHARGE: OPERATING A MOTOR VEHICLE WHILE SUSPENDED (DISPOSITION: GUILTY)"},{"id":"5666b83c9e4f49007356dad2","object":"adverse_item","text":"CHARGE: INVASION OF PRIVACY (DISPOSITION: GUILTY)"},{"id":"58d2b83c9e4f49007356dad3","object":"adverse_item","text":"CHARGE: THEFT (DISPOSITION: GUILTY)"},{"id":"58d2b83c9e4f49555356dad4","object":"adverse_item","text":"CHARGE: DOMESTIC BATTERY (DISPOSITION: GUILTY)"}],"object":"list","count":8}',
                                                   null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;
            Id accountRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account a = new Account(Name='Chester Tester',RecordTypeId=accountRTId,usr_email__c = 'test@test.com');
            insert a;
            Case cas = new Case(Subject ='CONSIDER',Description ='The background check for Andrea Deemaine Jewell completed with a status CONSIDER.You can review the detailed report at: https://dashboard.checkr.com/reports/19f490e9f89cd5297979d6bd If you have any questions about the results, please reply to this email.You can update your email notification settings here:https://dashboard.checkr.com/user/settings-- The Checkr team',Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Other',SubCategory__c='Trigger Testing',SuppliedEmail='test@test.com');
            insert cas;
            cas.BGCReportId__c = '1234';
            update cas;
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        String Username = 'System Integration';
        BackgroundCheck__c b = new BackgroundCheck__c(ReportId__c='1234',Name = 'testtest',CandidateName__c='test',CandidateId__c='1234',CountyCriminalSearchId__c= '1234',StateCriminalSearchId__c='12345');
            insert b;
        System.runAs(testUser) 
        {
            Test.startTest();
            CheckrAPI.getAdverseItems(b,'12345');

            Test.stopTest();
            List<Case> cases = [SELECT Id FROM Case ];
            system.debug('cases: '+cases);
        }
    }
}