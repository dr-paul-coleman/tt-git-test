/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       01/05/20118  pcoleman           Created for testing QueueableUtility class functions
========+============+=================+===============================================*/
@isTest
private class QueueableUtilityTest {
    private class QueueableTestException extends Exception {}

    /**
    * @author Paul Coleman
    * @date 2018-01-05
    * @description Test Queuable class for passing to QueueableUtility.handleQueueable().
    */
    private without sharing class TestQueueableSynchronous implements Queueable
    {
        public void execute( System.QueueableContext ctx )
        {
            QueueableUtility.handleQueueable( new TestQueueable() );
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-05
    * @description Test Queuable class for passing to QueueableUtility.handleQueueable().
    */
    private without sharing class TestQueueable implements Queueable
    {
        public void execute( System.QueueableContext ctx ) {
            if( NULL == ctx )
            {
                throw new QueueableTestException('Test Exception');
            }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-05
    * @description Explicit code coverage for QueueableUtility.handleQueueable().
    */
    @IsTest
    private static void testHandleQueueable() {

        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Test.startTest();

                //Test normal asynchronous execution
                QueueableUtility.handleQueueable( new TestQueueable()  );

                //Test syncrhonous fallback to execute(null)
                while ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                    System.enqueueJob( new TestQueueableSynchronous() );
                }
                QueueableUtility.handleQueueable(new TestQueueableSynchronous());


            Test.stopTest();

            // nothing to assert, handleQueueable is fire-and-forget

        }

    }

}