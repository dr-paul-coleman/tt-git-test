/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/5/17      paulcoleman          Created
========+============+=================+===============================================*/

public with sharing class ThumbtackTriggerContext
{
    public class ThumbtackTriggerHandlerException extends Exception {}
    public Enum TEvent { beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete }
    public TEvent dmlEvent;

    public SObject[] newRecords { get; private set; }
    public SObject[] oldRecords { get; private set; }
    public Map<Id, SObject> newRecordsMap { get; private set; }
    public Map<Id, SObject> oldRecordsMap { get; private set; }
    public String sobjectName { get; private set; }
    public Boolean isExecuting { get; private set; }
    public Integer recordCount { get; private set; }

    /**
	* @author Paul Coleman
	* @date 10/05/2017
    * @description Constructs the ThumbtackTriggerContext object.
    * @param SObject[] A list of records with the state of 'before' event
    * @param SObject[] A list of records with the state of 'after' event
    * @param Map<Id, SObject> A map of records with the state of 'before' event
    * @param Map<Id, SObject> A map of records with the state of 'after' event
    * @param Boolean An 'isBefore' event flag
    * @param Boolean An 'isAfter' event flag
    * @param Boolean An 'isDelete' event flag
    * @param Boolean An 'isInsert' event flag
    * @param Boolean An 'isUpdate' event flag
    * @param Boolean An 'isUnDelete' event flag
    * @param Boolean An 'isExecuting' event flag.
    */
    public ThumbtackTriggerContext(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap,
            Boolean isBefore, Boolean isAfter, Boolean isDelete, Boolean isInsert, Boolean isUpdate, Boolean isUnDelete, Boolean isExecuting, Integer size) {

        this.newRecords = newList;
        this.oldRecords = oldList;
        this.oldRecordsMap = oldMap;
        this.newRecordsMap = newMap;
        this.recordCount = size;

        SObject so = ( null != this.oldRecords && !this.oldRecords.isEmpty() )? this.oldRecords[0] : this.newRecords[0];
        this.sobjectName = so.getSObjectType().getDescribe().getName();

        if (isBefore & isInsert) { this.dmlEvent = TEvent.beforeInsert; }
        else if (isBefore && isUpdate) { this.dmlEvent = TEvent.beforeUpdate; }
        else if (isBefore && isDelete) { this.dmlEvent = TEvent.beforeDelete; }
        else if (isAfter && isInsert) { this.dmlEvent = TEvent.afterInsert; }
        else if (isAfter && isUpdate) { this.dmlEvent = TEvent.afterUpdate; }
        else if (isAfter && isDelete) { this.dmlEvent = TEvent.afterDelete; }
        else if (isAfter && isUndelete) { this.dmlEvent = TEvent.afterUndelete; }
        this.isExecuting = isExecuting;
    }
}