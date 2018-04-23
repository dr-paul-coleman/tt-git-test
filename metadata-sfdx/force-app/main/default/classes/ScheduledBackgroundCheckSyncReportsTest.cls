@isTest
private class ScheduledBackgroundCheckSyncReportsTest {
	
	public static String CRON_EXP = '0 58 23 ? * 7L';
    static testMethod void test1()
    {
      SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'Complete',
                                                 '{"id":"58c95f513327c30040b768da","object":"county_criminal_search","uri":"/v1/county_criminal_searches/58c95f513327c30040b768da","status":"consider","county":"Hamilton","state":"OH","created_at":"2017-03-15T15:35:45Z","completed_at":"2017-03-15T17:19:21Z","turnaround_time":6216,"records":[{"id":"58c977996107d900215ca687","case_number":"17CRB4073","file_date":"2017-02-15","arresting_agency":"HAMILTON COUNTY","court_jurisdiction":"MUNICIPAL COURT","court_of_record":null,"dob":"1978-08-22","yob":null,"full_name":"JAYSON MELTON","county":"HAMILTON","state":"OH","charges":[{"charge":"POSSESSION OF DRUGS","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"GUILTY","probation_status":null,"offense_date":"2014-02-06","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2017-02-15","conviction_date":null,"release_date":null,"court":null,"plea":""}],"address":{"street":"3247 Lndale Mt","unit":"","city":"Holly Amelia","state":"OH","zipcode":"45102","county":null}},{"id":"58c977996107d900215ca68c","case_number":"C12CRB5620","file_date":"2012-02-27","arresting_agency":"HAMILTON COUNTY","court_jurisdiction":"MUNICIPAL COURT","court_of_record":null,"dob":"1978-08-22","yob":null,"full_name":"JAYSON M MELTON","county":"HAMILTON","state":"OH","charges":[{"charge":"POSSESSION OF DRUGS","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"GUILTY","probation_status":null,"offense_date":"2012-02-22","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2012-03-09","conviction_date":null,"release_date":null,"court":null,"plea":""},{"charge":"POSSESS ILLEGAL DRUG PARAPHERNALIA","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"DISMISSED","probation_status":null,"offense_date":"2012-02-22","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2012-03-09","conviction_date":null,"release_date":null,"court":null,"plea":""}],"address":{"street":"3247 Lindale Ct","unit":"","city":"Amelia","state":"OH","zipcode":"45102","county":null}}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        //Test.setMock(HttpCalloutMock.class, new CheckrGetSubReportsMock());
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        CheckerAPISettings__c cs = new CheckerAPISettings__c();
            cs.Name='default';
            cs.BaseURL__c = 'http://api.salesforce.com/foo/bar';
            cs.Password__c = '1';
            cs.UserName__c = 'user' ;
            //cs.Other fields values
            insert cs;
            Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
            Id accountRTId=Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account a = new Account(Name='Chester Tester',RecordTypeId=accountRTId,usr_email__c = 'test@test.com');
            insert a;
            Case cas = new Case(Subject = 'test',Status='New',RecordTypeId=caseRTId,Origin='Phone',AccountId=a.Id,IsTestData__c=false,Category__c='Other',SubCategory__c='Trigger Testing',SuppliedEmail='test@test.com');
            
            insert cas;
            cas.BGCReportId__c = '1234';
            update cas;
          
           BackgroundCheck__c b = new BackgroundCheck__c(BackgroundCheckComplete__c = false,ReportId__c='1234',Name = 'test test',SuppliedEmail__c = 'tester@tsster.com',CandidateName__c='test',CandidateId__c='1234',CountyCriminalSearchId__c= '1234',StateCriminalSearchId__c='12345');
            insert b;
        System.runAs(testUser) 
        {
            Test.startTest();
            String jobId = System.schedule('ScheduledBackgroundCheckSyncReports',
            CRON_EXP, 
              new ScheduledBackgroundCheckSyncReports());

              // Get the information from the CronTrigger API object
              CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
              NextFireTime FROM CronTrigger WHERE id = :jobId];

                // Verify the expressions are the same
              //System.assertEquals(TestScheduledApex.CRON_EXP, 
              // ct.CronExpression);

              // Verify the job has not run
              System.assertEquals(0, ct.TimesTriggered);
          Test.stopTest();
        }
    }
	
}