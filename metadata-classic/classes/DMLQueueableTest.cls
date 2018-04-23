/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       09/29/2017     Paul Coleman     Created
========+============+=================+===============================================*/
@IsTest
public with sharing class DMLQueueableTest {

    @IsTest
    private static void testQueuableDMLUtilityUpdateError() {

        //get tackbot as test user
        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Test.startTest();

                System.enqueueJob(new DMLQueueable(new SObject[]{new Account(Name='Test Record')}, DMLQueueable.Operation.UPDATES ));

            Test.stopTest();

            Account[] accounts = [SELECT Id FROM Account WHERE Name = 'Test Record' LIMIT 1];
            System.assert( accounts.isEmpty(), 'DMLQueueable updated an Account record without an Id' );
        }
    }

    @IsTest
    private static void testQueuableDMLUtilityInsert() {

        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            Test.startTest();

                System.enqueueJob(new DMLQueueable(new SObject[]{new Account(Name='Test Record')}, DMLQueueable.Operation.INSERTS ));

            Test.stopTest();

            Account[] accounts = [SELECT Id FROM Account WHERE Name = 'Test Record' LIMIT 1];
            System.assert( !accounts.isEmpty(), 'DMLQueueable did not insert the test Account' );
        }
    }

    @IsTest
    private static void testQueuableDMLUtilityDeletion() {

        Account account1 = new Account(Name='Test Record 1');
        Account account2 = new Account(Name='Test Record 2');
        insert new Account[]{account1,account2};

        System.runAs(TestUtilities.USER_TACK_BOT)
        {

            System.enqueueJob(new DMLQueueable(account2, DMLQueueable.Operation.UPDATES ));
            System.enqueueJob(new DMLQueueable(new SObject[]{account1,account1}, DMLQueueable.Operation.UPDATES ));

            Test.startTest();

                System.enqueueJob(new DMLQueueable( new Id[]{account1.Id}, DMLQueueable.Operation.DELETES ));

            Test.stopTest();

            Account[] accounts = [SELECT Id,IsDeleted FROM Account WHERE Id = :account1.Id LIMIT 1 ALL ROWS];
            System.assert( !accounts.isEmpty(), 'DMLQueueable did not insert the test Account' );
            System.assert( accounts[0].IsDeleted, 'DMLQueueable did not delete the test Account' );

        }

    }


}