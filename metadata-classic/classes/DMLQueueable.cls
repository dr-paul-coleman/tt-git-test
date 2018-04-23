/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       09/29/2017     Paul Coleman     Created Utility Queuable for generic asynchronous DML
========+============+=================+===============================================*/
public without sharing class DMLQueueable implements Queueable
{
    public enum Operation {INSERTS, UPDATES, DELETES}

    private SObject[] dmlRecords;
    private Set<Id> uniqueIds;
    private Id[] dmlIds;
    private Operation dmlOperation;

    //Type-casting constructors for rtti and ID type binding
    public DMLQueueable(SObject record, Operation dmlDo)
    {
        this( (new Object[]{record}), dmlDo );
    }

    public DMLQueueable(Id[] recordIds, Operation dmlDo)
    {
        this( (Object[])recordIds, dmlDo );
    }

    public DMLQueueable(SObject[] records, Operation dmlDo)
    {
        this( (Object[])records, dmlDo );
    }

    public DMLQueueable(Object[] alist, Operation dmlDo)
    {
        this.dmlOperation = ( null == dmlDo )? Operation.INSERTS: dmlDo;
        this.dmlRecords = new SObject[0];
        this.dmlIds = new Id[0];
        if( Operation.UPDATES == this.dmlOperation )
        {
            this.uniqueIds = new Set<Id>();
        }

        if( NULL != alist && !alist.isEmpty() )
        {
            String dmlOpString =  String.valueOf(dmlDo);
            System.debug(LoggingLevel.INFO, 'DMLQueuable DML Operation: ' + dmlOpString);
            for ( Object o : (null == alist) ? new Object[0] : alist )
            {
                if (null != o)
                {
                    if (Operation.DELETES == this.dmlOperation)
                    {
                        dmlIds.add((Id) o);
                    }
                    else
                    {
                        if (Operation.UPDATES == this.dmlOperation)
                        {
                            SObject record = (SObject)o;
                            if( !uniqueIds.contains( record.Id ) )
                            {
                                uniqueIds.add(record.Id);
                                dmlRecords.add((SObject) o);
                            }
                        }
                        else
                        {
                            dmlRecords.add((SObject) o);
                        }
                    }
                }
            }
            if ( dmlDo == Operation.DELETES && !dmlIds.isEmpty() )
            {
                System.debug( LoggingLevel.INFO, 'DMLQueuable first DELETION[0] Key Prefix: ' + new TId(dmlIds[0]).keyPrefix() );
            }
            else if ( !dmlRecords.isEmpty() )
            {
                String firstObjectType = dmlRecords[0].getSObjectType().getDescribe().getName();
                System.debug(LoggingLevel.INFO, 'DMLQueuable first SObject record type for ' + dmlOpString + ': ' + firstObjectType );
            }
        }
    }

    public void execute( System.QueueableContext ctx )
    {
        Integer successes = 0;
        Integer failures = 0;
        Integer created = 0;
        String lastError = '';
        SObject[] errorObjects = new SObject[0];
        String[] errorMsgs = new String[0];
        SObject[] rowLockRetries = new SObject[0];
        if( this.dmlOperation == Operation.INSERTS ||  this.dmlOperation == Operation.UPDATES )
        {
            if( !this.dmlRecords.isEmpty() )
            {
                this.dmlRecords.sort();
                // NOTE: The dmlRecords array thus far is a reference list to the objects array passed in the constructor
                //          usually passed by a trigger handler and may not permit updates to the same records.
                //       To ensure the DML on the records is independent from the reference list (aka, a trigger action)
                //       The following serialization/deserialization mocks a clone of the array, isolating the records from the
                //          reference list. JSON serialization is used because SObject does not support `Record.clone()`.
                this.dmlRecords = (SObject[])( JSON.deserialize( JSON.serialize(this.dmlRecords) , List<SObject>.class) );
                Integer recordIndex = 0;
                for ( Database.SaveResult result : (this.dmlOperation == Operation.INSERTS) ? Database.insert(this.dmlRecords, false) : Database.update(this.dmlRecords, false) )
                {
                    successes += ( result.isSuccess() ) ? 1 : 0;
                    failures += ( result.isSuccess() ) ? 0 : 1;
                    created += (this.dmlOperation == Operation.INSERTS && result.isSuccess() ) ? 1 : 0;
                    lastError = ( !result.isSuccess() && !result.getErrors().isEmpty() )? result.getErrors()[0].getMessage() : '';
                    if( !result.isSuccess() )
                    {
                        SObject errObject = this.dmlRecords[recordIndex];
                        errorObjects.add( errObject );
                        for( Database.Error err: result.getErrors() )
                        {
                            if( err.message.contains('unable to obtain exclusive access') ) { rowLockRetries.add( errObject ); }
                            else
                            {
                                errorMsgs.add('Error msg: ' + err.message + '<br/> Error Record: ' + JSON.serialize(errObject) );
                                String[] fieldnames = err.getFields();
                                if (!fieldnames.isEmpty()) { System.debug(LoggingLevel.ERROR, 'Error Fields: ' + String.join( fieldnames, ', ') ); }
                            }
                        }
                    }
                    recordIndex++;
                }
            }
        }
        else
        {
            if (!this.dmlIds.isEmpty())
            {
                for ( Database.DeleteResult result : Database.delete(this.dmlIds, false) )
                {
                    successes += ( result.isSuccess() ) ? 1 : 0;
                    failures += ( result.isSuccess() ) ? 0 : 1;
                    lastError = ( !result.isSuccess() && !result.getErrors().isEmpty() )? result.getErrors()[0].getMessage() : '';
                }
            }
        }

        if( !this.dmlIds.isEmpty() || !this.dmlRecords.isEmpty() )
        {
            System.debug(LoggingLevel.INFO, 'DML SUMMARY FOR ' + String.valueOf(this.dmlOperation) + ' SUCCESSES: ' + String.valueOf(successes));
            if (0 != failures)
            {
                if (rowLockRetries.isEmpty())
                {
                    System.debug(LoggingLevel.WARN, 'DML FAILURES: ' + String.valueOf(failures));

                    String errorString = 'DMLQueueable Database Errors for user ' + UserInfo.getUserName() + ' [' + UserInfo.getUserId() + ']<br/></br>';
                    errorString += String.join( errorMsgs, '<br/><br/>');
                    TackBotUtility.postTackLogErrorMessage(errorString, 'DMLQueueable.execute()');
                    System.debug(LoggingLevel.INFO, 'ERROR LOG: ' + errorString);

                }
                // Retry clause *ONLY* for 'unable to obtain exclusive access' DML exceptions
                // This may appear to be an infinite loop, but eventually, the row will come free and update --
                // i.e., the potential for infinite loop is very slim
                else if (!rowLockRetries.isEmpty()) { QueueableUtility.handleQueueable(new DMLQueueable(rowLockRetries, this.dmlOperation)); }
            }
        }

    }
}