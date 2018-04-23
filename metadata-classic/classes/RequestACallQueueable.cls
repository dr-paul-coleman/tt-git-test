/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       11/21/17      pcoleman          Created to handle Request-a-call submissions
                                             from Help Center
========+============+=================+===============================================*/
public without sharing class RequestACallQueueable implements Queueable
{
    private String requestACall;

    public RequestACallQueueable( String callRequest )
    {
        this.requestACall = callRequest;
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-21
    * @description Execute the Queueable's business rules for Account update and/or WorkItem insert based on request-a-call inputs.
    * @parm QueueableContext Not used.
    */
    public void execute( QueueableContext ctx )
    {
        if( String.isNotBlank( this.requestACall ) )
        {
            Map<String, String> record = getMapFromJSON( this.requestACall );
            // commpensate for JSON.stringify deserialization from Help Center, null values may become strings 'null'
            for( String key: record.keySet() ) { if( 'null'.equals(record.get(key)) ) { record.put( key, NULL); } }

            if( Test.isRunningTest() ) { System.debug( LoggingLevel.INFO, 'JSON Map: ' + record ); }
            String emailString = record.get('email');
            String phoneString = record.get('requestacallphone__c');
            String userIdString = '-1';  // default to avoid NULL query lookup skew
            Decimal userIdDecimal = Decimal.valueOf( userIdString );
            String userPkIdString = 'notfound'; // default to avoid NULL query lookup skew
            String callbackDOW = record.get('requestacalldayofweek__c');
            String callbackTimeFrame = record.get('requestacalltimeframe__c');
            String timeZone = record.get('timezonefromadmin__c');

            Set<String> searchStrings = new Set<String>();

            if( !Trigger.isExecuting )
            {
                try
                {
                    for ( becquerel_tt_user_for_tack__x ttuser : ( BecquerelUtility.IS_TEST_RUN ? BecquerelUtility.createTestExternalUsers( 1, true ) : [ SELECT Id, usr_last_name__c, usr_first_name__c, usr_timezone__c, usr_user_id__c, user_pk_id__c FROM becquerel_tt_user_for_tack__x WHERE usr_email__c = :emailString OR phn_phone_number__c = :phoneString OR sav_notif_phn_phone_number__c = :phoneString LIMIT 1 ] ) )
                    {
                        if ( NULL != ttuser.user_pk_id__c ) { searchStrings.add( String.valueOf( ttuser.user_pk_id__c ) ); }
                        if ( NULL != ttuser.usr_user_id__c ) { searchStrings.add( String.valueOf( ttuser.usr_user_id__c ) ); userIdDecimal = ttuser.usr_user_id__c; userIdString = String.valueOf(userIdDecimal); }
                        record.put( 'firstname', ttuser.usr_first_name__c );
                        record.put( 'lastname', ttuser.usr_last_name__c );
                        timeZone = ( String.isBlank(timeZone) ) ? ttuser.usr_timezone__c : timeZone;
                        record.put( 'timezonefromadmin__c', timeZone);
                    }

                }
                catch ( System.ExternalObjectException ex )
                {
                    System.debug(LoggingLevel.ERROR, ex); // skip HTTP 504 Errors when trying to do oData queries
                    if( !ex.getMessage().contains( 'Error received from the external system: 50')) { TackBotUtility.sendExceptionEmail( ex, 'RequestACallQueueable.execute()' ); }
                }
                catch ( System.UnexpectedException ex )
                {
                    System.debug(LoggingLevel.ERROR, ex);
                    if( !ex.getMessage().contains( 'Apex triggers can\'t reference external objects or call out to external data sources' ) ) { TackBotUtility.sendExceptionEmail( new ExternalObjectException(ex.getMessage()), 'RequestACallQueueable.execute()' ); }
                }
            }

            if( !searchStrings.isEmpty() )  // searchStrings loaded after a successful becky query result
            {
                String searchTerm = String.join( new List<String>(searchStrings),' OR ').removeEnd(' OR ');
                if( Test.isRunningTest() ) { System.debug( LoggingLevel.INFO, 'Account Search string' + searchTerm ); }
                Account[] locatedAccounts = (Account[])[FIND :searchTerm RETURNING Account(Id WHERE usr_user_id__c = :userIdDecimal OR user_pk_id__c = :userPkIdString ) ][0];
                if( locatedAccounts.isEmpty() ) {
                    this.insertWorkItem( record, userIdString, userPkIdString );
                }
                else
                {
                    if( Test.isRunningTest() ) { System.debug( LoggingLevel.INFO, 'ACCOUNT FIND RESULTS:' + JSON.serialize(locatedAccounts) ); }
                    Account a = locatedAccounts[0];
                    Datetime preferredDateTime = (String.isBlank(callbackDOW) || String.isBlank(callbackTimeFrame)) ? Datetime.now() : determineCallbackDateTime(timeZone, callbackTimeFrame, callbackDOW);
                    a.EnrollmentCallbackDateTime__c = preferredDateTime;
                    a.EnrollmentCallbackSource__c = record.get('requestacallsource__c');
                    a.EnrollmentCallbackCampaign__c = record.get('requestacallcampaign__c');
                    a.EnrollmentCallbackPhone__c = phoneString;
                    a.EnrollmentCallbackOrigin__c = 'Pro Requested';

                    Database.SaveResult accountSave = Database.update( a, false );
                    if (!accountSave.isSuccess() )
                    {
                        String errorString = accountSave.getErrors()[0].getMessage(); System.debug(LoggingLevel.ERROR, 'Account DML Error: ' + errorString); TackBotUtility.sendAdminMail('RequestACallQueueable Error', 'Account DML Failure.<br/>' + errorString);
                    }
                }
            }
            else
            {
                this.insertWorkItem( record, userIdString, userPkIdString );
            }
        }
    }

    /**
    * @author Adam Schults
    * @date 2017-08-01
    * @description Parse the callback date from the submitted request-a-call data
    * @parm String TimeZoneFromAdmin A Timezone string, e.g., America/Denver.
    * @parm String RequestACallTimeframe A range of times, e.g., 7:00 - 8:00 AM.
    * @parm String RequestACallDayOfWeek A day of the week, e.g., Monday.
    */
    private Datetime determineCallbackDateTime( String TimeZoneFromAdmin, String RequestACallTimeframe, String RequestACallDayOfWeek )
    {
        Map<String, Integer> weekDayNumberMap = new Map<String, Integer>{'Monday' => 1, 'Tuesday' => 2, 'Wednesday' => 3, 'Thursday' => 4, 'Friday' => 5 };
        Datetime result;
        Datetime now = Datetime.now();
        Datetime nowTimeZone = Datetime.newInstance(now.year(), now.month(), now.day(), now.hour(), 0, 0);


        try
        {
            if (String.isNotBlank(TimeZoneFromAdmin) && String.isNotBlank(RequestACallTimeframe) && String.isNotBlank(RequestACallDayOfWeek))
            {

                TimeZone tz = TimeZone.getTimeZone(TimeZoneFromAdmin);
                Integer timeZoneDifference = tz.getOffset(nowTimeZone) / 1000 / 60 / 60;
                Integer reqHour = Integer.valueOf(RequestACallTimeframe.substring(0, RequestACallTimeframe.indexOf(':')));
                Boolean add12 = RequestACallTimeframe.contains('AM') && reqHour != 12;
                nowTimeZone = nowTimeZone.addHours(timeZoneDifference);
                Date day = nowTimeZone.date();
                Date weekStart = day.toStartOfWeek();
                Integer daysBetween = weekStart.daysBetween(day);
                Time preferredTime = Time.newInstance(reqHour + (add12 ? 0 : 12), 0, 0, 0);
                Datetime proposedDT = Datetime.newInstance(day, preferredTime);
                proposedDT = proposedDT.addHours(-1 * timeZoneDifference);
                Integer weekDayNumber = weekDayNumberMap.get(RequestACallDayOfWeek);
                if (weekDayNumber == daysBetween)
                {
                    if (proposedDT > nowTimeZone || (proposedDT < nowTimeZone && (nowTimeZone.getTime() - proposedDT.getTime()) <= 1 * 60 * 60 * 1000))
                    {
                        result = proposedDT;
                    }
                }
                if (result == null)
                {
                    result = Datetime.newInstanceGmt(weekStart, proposedDT.time());
                    result = result.addDays((7 * (weekDayNumber > daysBetween ? 0 : 1)) + weekDayNumber);
                }
            }
        } catch( Exception ex ) {
            System.debug( LoggingLevel.ERROR, ex );
        }
        return ( NULL == result )? now : result;

    }

    /**
    * @author Paul Coleman
    * @date 2017-11-21
    * @description Obtain key-value pairs String Map from a parsed JSON string.
    *              This deserialization approach replaces object-specific deserialization and type casts (removing direct binding to Lead records)
    * @parm String The JSON string to parse.
    */
    private Map<String, String> getMapFromJSON( String jsonString )
    {
        Map<String, String> result = new Map<String, String>();
        try
        {
            JSONParser parser = JSON.createParser(jsonString);
            while (parser.nextToken() != null)
            {
                if (JSONToken.FIELD_NAME == parser.getCurrentToken())
                {
                    String fieldname = parser.getText();
                    if (String.isNotBlank(fieldname))
                    {
                        fieldname = fieldname.toLowerCase();
                        result.put(fieldname, NULL);
                        parser.nextToken();
                        if (JSONToken.FIELD_NAME != parser.getCurrentToken())
                        {
                            String fieldValue = parser.getText();
                            if (String.isNotBlank(fieldValue))
                            {
                                result.put(fieldname, fieldValue);
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            TackBotUtility.postTackLogException( ex, 'RequestACallQueueable.getMapFromJSON' );
        }
        return result;
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-29
    * @description Insert a WorkItem__c record because an Account match was not found given the Help Center input values (phone and email)
    * @parm Map<String,String> A map of name->value pairs combining Help Center Input data + data returned from the remote Becky query, if any.
    * @parm String A Thumbtack User Id value, if any.
    * @parm String A Thumbtack User PK Id value, if any.
    */
    private void insertWorkItem( Map<String,String> record, String userId, String pkId )
    {
        String userIdString = ( '-1'.equals(userId) ) ? NULL : userId;
        //String userPkIdString = ( 'notfound'.equals(pkId) ) ? NULL : pkId; // TODO FUTURE
        String phoneString = record.get('requestacallphone__c');
        Id workitem_record_type_id = WorkItem__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Work Item').getRecordTypeId();
        WorkItem__c workItem = new WorkItem__c (
                pro_first_name__c = record.get('firstname'),
                pro_last_name__c = record.get('lastname'),
                pro_email__c = record.get('email'),
                Phone__c = phoneString,
                Details__c = String.isBlank( userIdString ) ? 'Pro requested a callback. Thumbtack ID is not found ' : 'Pro requested a callback. Thumbtack ID: ' + userIdString,
                RecordTypeId = workitem_record_type_id,
                TimeZone__c = record.get('timezonefromadmin__c'),
                TimeWindow__c = record.get('requestacalltimeframe__c'),
                DayOfWeek__c = record.get('requestacalldayofweek__c'),
                EnrollmentCallbackSource__c = record.get('requestacallsource__c'),
                EnrollmentCallbackCampaign__c = record.get('requestacallcampaign__c'),
                Name = 'Pro requested a callback '+phoneString,
                Status__c ='New',
                Type__c = 'PA Request a call error',
                OwnerId = QueueUtility.getWorkItemQueueId('RequestACallError')
        );

        Database.SaveResult wiSave = Database.insert( workItem, false );
        if ( !wiSave.isSuccess() ) { String errorString = wiSave.getErrors()[0].getMessage(); System.debug( LoggingLevel.ERROR, 'WorkItem DML Error: ' + errorString); TackBotUtility.sendAdminMail('RequestACallQueueable Error', 'WorkItem__c DML Failure.<br/>' + errorString); }

    }
}