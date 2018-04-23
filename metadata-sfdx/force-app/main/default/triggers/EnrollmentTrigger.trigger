/*
Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-02-15    Jared Kennington  refactored to new trigger structure
========+============+=================+================================================
*/
trigger EnrollmentTrigger on Enrollment__c (before insert,after insert,before update,after update)
{
    ThumbtackTriggerHandlerBase.doTrigger( 'EnrollmentTriggerHandler' );
}