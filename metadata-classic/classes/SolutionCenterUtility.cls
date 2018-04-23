/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2/7/18      pcoleman           Created to support Solution Center Business rules
                                            and resusability between Trigger Handler classes
                                            and SolutionCenterController
========+============+=================+===============================================*/
public without sharing class SolutionCenterUtility
{
    // SolutionCenterException is re-declared FROM SolutionCenterController to avoid
    // circular class references (SolutionCenterController makes heavy use of this class)
    public class SolutionCenterException extends Exception{}

    public enum DisputeDML {  ACCEPT_OFFER, WITHDRAW_OFFER, UPDATE_DISPUTE, WITHDRAW_DISPUTE, CREATE_OFFER, CREATE_MSG, GET_ID_HASH, COUNTER_OFFER }

    /**
    * @author Paul Coleman
    * @date 2018-03-06
    * @description A function to insert a Case related to a Dispute
    * @param Map<String, Object> A field map of case field values.
    */
    public static void insertDisputeCase( Map<String, Object> caseFields )
    {
        String disputeHash = (String) caseFields.get('DisputeIdHash__c');

        Dispute__c[] disputes = [SELECT Id, MIIncident__c FROM Dispute__c WHERE IdHash__c = :disputeHash LIMIT 1];
        if (!disputes.isEmpty())
        {
            Dispute__c dispute = disputes[0];
            Case newCase = new Case(Dispute__c = dispute.Id, Incident__c = dispute.MIIncident__c);
            for (String field : caseFields.keySet())
            {
                newCase.put(field, caseFields.get(field));
            }

            QueueableUtility.handleQueueable( new DMLQueueable( newCase, DMLQueueable.Operation.INSERTS) );
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-25
    * @description Shares the offer with the other party in the dispute.
    * @param Dispute__c The Offer's Dispute parent.
    * @param Id The Contact.Id that created the message.
    * @param Integer The current count of Offers related to the Dispute input parm.
    */
    public static void doNewOfferRelatedDisputeUpdates( Dispute__c dispute, Id thisContactsId, Integer offerCount)
    {

        Datetime now = Datetime.now();
        // Is this offer insert the Initiator's confirmation action on the dispute (first offer)?
        Dispute__c updateDispute = new Dispute__c(Id = dispute.Id);
        // Set default Dispute status and stage for a new offer insert, may be overridden in conditional logic below
        updateDispute.Status__c = 'In progress';
        updateDispute.Stage__c = 'Offer pending';
        if ((thisContactsId == dispute.InitiatorContact__c))
        {
            updateDispute.InitiatorTotalOfferCount__c = ++dispute.InitiatorTotalOfferCount__c;

            if (null == dispute.ResponderFirstActionDueDate__c && 1 == offerCount) //indicator of confirmation offer not ready
            {
                // Initiator has confirmed the dispute details by creating the first DisputeOffer__c
                Decimal decimalDays = dispute.MaxOfDaysForResponderFirstAction__c;
                Integer days = (null == decimalDays) ? 0 : Integer.valueOf(decimalDays);
                updateDispute.ResponderFirstActionDueDate__c = now.addDays(days);
                updateDispute.InitiatorConfirmationDate__c = now;
                updateDispute.Status__c = 'Awaiting';
                updateDispute.Stage__c = 'Responder first action needed';
            }
        }
        else if (thisContactsId == dispute.ResponderContact__c)  // data integrity/security insurance vs a stand-alone `else`
        {
            updateDispute.ResponderTotalOfferCount__c = ++dispute.ResponderTotalOfferCount__c;
            Boolean isResponder = thisContactsId == dispute.ResponderContact__c;
            Boolean isNotAlreadySet = null == dispute.ResponderFirstActionDate__c;
            if (isResponder && isNotAlreadySet)
            {
                updateDispute.ResponderFirstActionDate__c = now;
            }
        }

        SolutionCenterUtility.updateRecord( updateDispute, DisputeDML.UPDATE_DISPUTE );

    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Provides an avenue for updating Offer and Dispute records synchronously without sharing.
    * @param SObject A record for update, usually an Offer and/or Dispute.
    * @param DisputeDML An enum for conditional processing.
    * @return Database.SaveResult A DML result.
    */
    public static Database.SaveResult updateRecord(SObject record, DisputeDML dmlType)
    {
        return updateRecords( new SObject[]{record}, dmlType )[0];
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Provides an avenue for insert Offer and Message records synchronously without sharing.
    * @param SObject An offer or message record.
    * @param DisputeDML An enum for conditional processing.
    * @return Database.SaveResult A DML result.
    */
    public static Database.SaveResult createRecord(SObject record, DisputeDML dmlType)
    {
        Database.SaveResult insertResult = Database.insert(record, false);
        if( !insertResult.success )
        {
            System.debug(LoggingLevel.ERROR, record.getSObjectType() + ': ' + JSON.serialize(record));
            Database.Error err = insertResult.errors[0];
            String errorMsg = 'Message [' + record.getSObjectType() + '] : ' + err.message + '. Error Fields: ' + JSON.serialize(err.fields);
            // using ternaries to get 100% code coverage for DML errors that rarely occur
            errorMsg = (dmlType == DisputeDML.CREATE_OFFER)? 'An error occurred when attempting to create an Offer. ' + errorMsg : errorMsg;
            errorMsg = (dmlType == DisputeDML.CREATE_MSG)? 'An error occurred when attempting to create a Message. ' + errorMsg : errorMsg;
            throw new SolutionCenterException( errorMsg );
        }
        return insertResult;
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-05
    * @description Provides an avenue for updating Offer and Dispute records synchronously without sharing.
    * @param SObject[] A list of records, usually an Offer and/or Dispute.
    * @param DisputeDML An enum for conditional processing.
    * @return Database.SaveResult[] An array of DML results.
    */
    public static Database.SaveResult[] updateRecords(SObject[] records, DisputeDML dmlType)
    {
        Integer objIndex = 0;
        Database.SaveResult[] updateResults = Database.update(records, false);
        for ( Database.SaveResult updateResult : updateResults )
        {
            if (!updateResult.success)
            {
                SObject obj = records[objIndex];
                System.debug(LoggingLevel.ERROR, obj.getSObjectType() + ': ' + JSON.serialize(obj));
                Database.Error err = updateResult.errors[0];
                String errorMsg = 'Message [' + obj.getSObjectType() + '] : ' + err.message + '. Error Fields: ' + JSON.serialize(err.fields);
                errorMsg = (dmlType == DisputeDML.ACCEPT_OFFER)?  'An error occurred when attempting to accept an Offer. ' + errorMsg : errorMsg;
                errorMsg = (dmlType == DisputeDML.COUNTER_OFFER)?  'An error occurred when attempting to counter an Offer. ' + errorMsg : errorMsg;
                errorMsg = (dmlType == DisputeDML.UPDATE_DISPUTE) ? 'An error occurred when attempting to update a Dispute. ' : errorMsg ;
                errorMsg = (dmlType == DisputeDML.WITHDRAW_DISPUTE) ? 'An error occurred when attempting to withdraw a Dispute. ' : errorMsg ;
                errorMsg = (dmlType == DisputeDML.WITHDRAW_OFFER) ? 'An error occurred when attempting to withdraw an Offer. ' : errorMsg ;
                errorMsg = (dmlType == DisputeDML.CREATE_OFFER) ? 'An error occurred when attempting to withdraw a Dispute. ' : errorMsg ;
                errorMsg = (dmlType == DisputeDML.GET_ID_HASH) ? 'An error occurred when attempting to update Record. ' : errorMsg ;
                throw new SolutionCenterException( errorMsg );
            }
            objIndex++;
        }
        return updateResults;
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-25
    * @description Catch up the Message counts on Dispute and Dispute offer.
    * @param DisputeMessage__c A newly inserted message.
    */
    public static void catchupDisputeMessageCounts(DisputeMessage__c newMsg)
    {
        if (!'Standard'.equals(UserInfo.getUserType())) { new DisputeMessageCountQueueable(newMsg).execute(null); }
    }


    /**
   * @author Paul Coleman
   * @date 2018-03-06
   * @description Retrieve DisputeMessage RecordType ids for use in insertDiputeMessage().
   * @return Map<Id, String> A DML result object .
   */
    public static Map<Id, String> getMessageRecordTypeIdMap()
    {
        Map<Id,String> rts = new Map<Id, String>(); //Solution Center Offer
        for( RecordTypeInfo info : DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().values() )
        {
            rts.put( info.getRecordTypeId(), info.getName() );
        }
        return rts;
    }

    /**
   * @author Paul Coleman
   * @date 2018-03-06
   * @description Published Platform Events for Solution Center DML notifications.
   * @parm SObject[] An array of records that need related Platform Events fired.
   */
    public static void publishSolutionCenterEvents( SObject[] records )
    {
        Set<String> targets = new Set<String>( 'Dispute__c,DisputeOffer__c,DisputeMessage__c'.toLowerCase().split(',') );
        SolutionCenterRefreshEvent__e[] events = new SolutionCenterRefreshEvent__e[0];
        Map<Id,String> userContactHashMap = new Map<Id, String>();
        for( SObject so : records )
        {
            userContactHashMap.put( (Id)so.get('LastModifiedById'), null);
        }
        //get last modified users contact ids
        for( User usr: [SELECT Id, ContactId FROM User WHERE Id IN :userContactHashMap.keySet() LIMIT :userContactHashMap.size()])
        {
            userContactHashMap.put( usr.Id,  ( !String.isEmpty(usr.ContactId)? CryptoUtility.hashId(usr.ContactId) : '' ) );
        }

        for( SObject so : records )
        {
            String type = so.getSObjectType().getDescribe().name.toLowerCase();
            if( targets.contains(type) )
            {
                Id lastModifiedByUser = (Id)so.get('LastModifiedById');
                SolutionCenterRefreshEvent__e event = new SolutionCenterRefreshEvent__e();
                event.EventCreatedByHash__c = userContactHashMap.get(lastModifiedByUser);
                if ('Dispute__c'.equalsIgnoreCase(type))
                {
                    Dispute__c dispute = (Dispute__c) so;
                    event.DisputeIdHash__c = String.isEmpty( dispute.IdHash__c ) ? CryptoUtility.hashId(dispute.Id) : dispute.IdHash__c;
                    event.SObjectType__c = 'Dispute__c';
                }
                else if ('DisputeOffer__c'.equalsIgnoreCase(type))
                {
                    DisputeOffer__c offer = (DisputeOffer__c) so;
                    event.DisputeIdHash__c =  offer.DisputeHash__c ;
                    event.SObjectType__c = 'DisputeOffer__c';
                }
                else if ('DisputeMessage__c'.equalsIgnoreCase(type))
                {
                    DisputeMessage__c msg = (DisputeMessage__c) so;
                    Dispute__c[] msgDispute = [SELECT IdHash__c FROM Dispute__c WHERE Id = :msg.Dispute__c LIMIT 1];
                    if( !msgDispute.isEmpty() )
                    {
                        event.DisputeIdHash__c = msgDispute[0].IdHash__c;
                        event.SObjectType__c = 'DisputeMessage__c';
                    }
                }

                if( !String.isEmpty(event.DisputeIdHash__c) ) { events.add( event ); }
            }
        }

        if( !events.isEmpty() )
        {
            String errStr = '';
            try { for (Database.SaveResult publishResult : EventBus.publish(events)) { if (!publishResult.isSuccess()) { errStr += publishResult.errors[0].message + '\n'; } }
            } catch ( DmlException dex ) { TackBotUtility.postTackLogException(dex, 'SolutionCenterUtility.publishSolutionCenterEvents()' );  }
            if( !String.isEmpty(errStr) ) { TackBotUtility.postTackLogErrorMessage(errStr,'SolutionCenterUtility.publishSolutionCenterEvents()'); }
        }
    }
}