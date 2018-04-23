/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/11/18      pcoleman           Created
========+============+=================+===============================================*/
global with sharing class SolutionCenterController
{

    public class SolutionCenterException extends Exception{}

    private static final String DOWNLOAD_URL = '/sfc/servlet.shepherd/version/download/';
    private static final String THUMBNAIL_URL = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=';
    private static final String PREVIEW_URL = THUMBNAIL_URL.replace('THUMB240BY180', 'THUMB720BY480');

    public class ContactUser
    {
        public User activeUser;
        public Id usersId;
        public Id usersContactId;
        public String usersContactHash;
        public String usersContactName;
        public String usersType;

        public ContactUser()
        {
            this.usersId = UserInfo.getUserId();
            this.usersType = UserInfo.getUserType();
            this.activeUser = [SELECT ContactId, Contact.Name, AccountId FROM User WHERE Id = :this.usersId LIMIT 1];
            this.usersContactId = activeUser.ContactId;
            this.usersContactHash = CryptoUtility.hashId(this.usersContactId);
            this.usersContactName = this.activeUser.Contact.Name;
        }

    }

    public enum DisputeUpdateType
    {
        DESCRIPTION, WITHDRAWAL
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-02
    * @description A class that consolidates the parent child replationships between Disputes, Offers, Messages and Files.
    */
    public class DisputeData
    {
        public Dispute__c[] disputes;
        public Id[] disputeOfferIds;
        public Map<Id, DisputeMessage__c[]> disputeMessageIdMap;
        public DisputeData(Dispute__c[] parents, Id[] offerIds, Map<Id, DisputeMessage__c[]> msgMap)
        {
            this.disputes = (null == parents) ? new Dispute__c[0] : parents;
            this.disputeOfferIds = (null == offerIds) ? new Id[0] : offerIds;
            this.disputeMessageIdMap = (null == msgMap) ? new Map<Id, DisputeMessage__c[]>() : msgMap;
        }
    }

    public SolutionCenterController() {} //custom controller constructor
    /**
    * @author Paul Coleman
    * @date 2018-02-02
    * @description Fetches relational Dispute data for SolutionCenter.
    * @param String A IdHash__c, Id, or NULL value for a Dispute__c record (NULL == records, if more than one).
    * @return DisputeData A class that can be distributed easily around functions, and navigated for JSON generation.
    */
    private static DisputeData queryDisputeData(String disputeHash)
    {
        DisputeData result = new DisputeData(new Dispute__c[0], new Id[0], new Map<Id, DisputeMessage__c[]>()); //default return
        ContactUser ttuser = new ContactUser();
        if (!ttuser.usersType.equalsIgnoreCase('guest'))
        {
            Map<Id, DisputeMessage__c[]> disputeMessageIdMap = new Map<Id, DisputeMessage__c[]>();
            Id[] disputeOfferIds = new Id[0];
            Dispute__c[] disputes;
            String soql = 'SELECT Id, IdHash__c, Name, InitiatorContact__c, ResponderContact__c, DisputeLastView__c, DisputeLastView__r.InitiatorLastViewedDate__c, DisputeLastView__r.ResponderLastViewedDate__c, IsMessagingEnabled__c, Description__c,DisputeExperience__c, DisputeExperience__r.Id, DisputeExperience__r.LabelsandInstructions__c, DisputeExperience__r.HCExperienceInitiator__c, DisputeExperience__r.HCExperienceResponder__c, InitiatorHash__c,InitiatorFirstName__c,InitiatorLastName__c,PrePopulatedDesiredResolution__c,PrePopulatedResolutionAmount__c,request_city__c,request_state__c,request_zip__c,request_category__c,ResponderHash__c,ResponderFirstName__c,ResponderLastName__c,SolutionCenterStatusLabel__c,Stage__c,Status__c,WithdrawalReason__c, OwnerId, InitiatorAccount__c, ResponderAccount__c, CreatedDate, (SELECT Id, IdHash__c, Dispute__c, OwnerId, SharedWithHash__c, ContactSharedWith__c, ContactCreatedBy__c, CreatedByHash__c,CreatedDate,DesiredRefundAmount__c,DesiredResolution__c,DisputeHash__c,DisputeOfferExpirationDate__c,Note__c,ResolutionCompleteByDate__c,Status__c FROM DisputeOffers__r ORDER BY CreatedDate ASC) FROM Dispute__c ';
            // fetch dispute records
            if ( !String.isEmpty(disputeHash) )
            {
                // if there is a dispute hash, add that filter to SOQL
                String disputeKeyPrefix = Schema.Dispute__c.sObjectType.getDescribe().getKeyPrefix();
                soql += ' WHERE ' + (disputeHash.startsWith(disputeKeyPrefix) ? ' Id = :disputeHash ' : ' IdHash__c = :disputeHash ');
            }
            //return nothing if an agent pulls the sc page without a dispute parm
            else if ( ttuser.usersType.equalsIgnoreCase('standard') )  { return result; }


            soql += ' ORDER BY CreatedDate ASC ' + ( String.isEmpty(disputeHash) ?  '' : ' LIMIT 1'  );

            disputes = (Dispute__c[])Database.query(soql);

            Map<Id, DisputeExperience__c> experiencesById = new Map<Id, DisputeExperience__c>();

            for (Dispute__c d : disputes)
            {
                if (null != d.DisputeExperience__c)
                {
                    experiencesById.put(d.DisputeExperience__c, null);
                }

                for (DisputeOffer__c offer : d.DisputeOffers__r)
                {
                    disputeOfferIds.add(offer.Id);
                }
            }

            for (DisputeExperience__c exp : [SELECT Id, MaxDaysForCalendarPicker__c, LabelsandInstructions__c, HCExperienceInitiator__c, HCExperienceResponder__c, RecordType.Name, (SELECT AcceptedFileFormats__c, Id, IsDefault__c, IsRequired__c, LinkURL__c, OptionLabel__c, OptionName__c, OptionType__c, SortOrder__c FROM DisputeExperienceOptionAssignments__r WHERE DisputeExperienceOption__r.Status__c = 'Published' ORDER BY SortOrder__c ASC) FROM DisputeExperience__c WHERE Id IN :experiencesById.keySet()])
            {
                experiencesById.put(exp.Id, exp);
            }

            for (Dispute__c d : disputes)
            {
                if (null != d.DisputeExperience__c)
                {
                    DisputeExperience__c exp = experiencesById.get(d.DisputeExperience__c);
                    if( null != exp ) {  d.putSObject('DisputeExperience__r', exp); }
                }
            }

            // gather all message records with related chatter file records
            for (DisputeMessage__c msg :
            [
                    SELECT Id, OwnerId, IdHash__c,
                    (
                            SELECT
                                    ContentDocument.LatestPublishedVersionId,
                                    ContentDocument.LatestPublishedVersion.Id,
                                    ContentDocument.LatestPublishedVersion.CreatedDate,
                                    ContentDocument.LatestPublishedVersion.Title,
                                    ContentDocument.LatestPublishedVersion.FileType,
                                    ContentDocument.LatestPublishedVersion.PathOnClient,
                                    ContentDocument.LatestPublishedVersion.Description,
                                    ContentDocument.LatestPublishedVersion.ContentSize,
                                    ContentDocument.LatestPublishedVersion.FileExtension,
                                    ContentDocument.LatestPublishedVersion.OwnerId
                                    FROM AttachedContentDocuments
                    ), CreatedDate, CreatedByHash__c, SharedWithHash__c, OfferHash__c, ParentMessageHash__c, DisputeOffer__c, DisputeMessage__c, Message__c, DocumentType__c, RecordType.DeveloperName, RecordType.Name
                            FROM DisputeMessage__c
                            WHERE DisputeOffer__c IN :disputeOfferIds
                    ORDER BY CreatedDate ASC
            ])
            {
                DisputeMessage__c[] messages = disputeMessageIdMap.containsKey(msg.DisputeOffer__c) ? disputeMessageIdMap.get(msg.DisputeOffer__c) : new DisputeMessage__c[0];
                messages.add(msg);
                disputeMessageIdMap.put(msg.DisputeOffer__c, messages);
            }

            // load all related records into a custom consolidation class, result may not be null if IdHash__c updates req'd
            result = new DisputeData(disputes, disputeOfferIds, disputeMessageIdMap) ;

        }

        return result;

    }

    /**
    * @author Paul Coleman
    * @date 2018-03-16
    * @description Fetches relational JSON tree of Dispute => DisputeOffer(s) => DisputeMessage(s) => Files for SolutionCenter UI handlers.
    * @usage SolutionCenterController.getDisputeData( (r,e)=>console.dir( JSON.parse(r) ), {escape:false});
    * @return String A JSON tree of related data, contructed to match the following schema example blow.
    *                 NOTE: Returns a JSON tree for all disputes visible to a portal user (CspLitePortal)
    *                 but throws an exception for Support Agent (Standard) users.
    *
    *   {
    *     "record": "{Object} Dispute__c custom fields",
    *     "experience": {
    *       "record": "{Object} DisputeExperience__c custom fields",
    *     },
    *     "offers": [
    *       {
    *         "record": "{Object} DisputeOffer__c custom fields",
    *         "messages": [
    *           {
    *             "record": "{Object} DisputeMessage__c custom fields",
    *             "files": [
    *               {
    *                 "contentSize": "{Number}",
    *                 "fileType": "{String}",
    *                 "id": "{String}",
    *                 "preview": "{String} 720x480 thumbnail",
    *                 "thumbnail": "{String} 240x180 thumbnail",
    *                 "title": "{String}",
    *                 "url": "{String} download URL"
    *               }
    *             ]
    *           }
    *         ]
    *       }
    *     ],
    *   }
    *
    */
    @RemoteAction
    global static String getDisputeData() //returns all disputes visible to a portal user (exception for Support Agent users)
    {
        ContactUser ttuser = new ContactUser();
        if ( ttuser.usersType.equalsIgnoreCase('standard') || ttuser.usersType.equalsIgnoreCase('guest') )
        {
            throw new SolutionCenterException('Only authenticated portal users may fetch all Disputes.');
        }
        return getDisputeDataByHash(null);
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-16
    * @description Fetches relational JSON tree of Dispute => DisputeOffer(s) => DisputeMessage(s) => Files for SolutionCenter UI handlers.
    * @usage SolutionCenterController.getDisputeDataByHash( "D8EFm8Zsq6", (r,e)=>console.dir( JSON.parse(r) ), {escape:false});
    * @param String A Dispute.IdHash__c string value for filtering the underlying SOQL query.
    * @return String A JSON tree of related data, contructed to match the following schema:
    */
    @RemoteAction
    global static String getDisputeDataByHash(String disputeHashId)
        {
        String result = '';
        ContactUser ttuser = new ContactUser();
        if (!ttuser.usersType.equalsIgnoreCase('guest'))
        {
            DisputeData data = queryDisputeData(!String.isEmpty(disputeHashId) ? disputeHashId : null);
            Dispute__c[] disputes = data.disputes;
            Map<Id, DisputeMessage__c[]> disputeMessageIdMap = data.disputeMessageIdMap;

            if (disputes.isEmpty() ) { throw new SolutionCenterException('No disputes found.'); }

            // do background update of "Last Viewed" stats
            try { updateDisputeLastViewedFields(disputes); } catch (Exception ex) { TackBotUtility.postTackLogException(ex, 'SolutionCenterController.getDisputeData'); }

            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartArray();

            for (Dispute__c dispute : disputes)
            {
                gen.writeStartObject(); // dispute

                //write Dispute field data
                gen.writeFieldName('record');

                gen.writeStartObject(); // record

                gen.writeStringField('IdHash__c', dispute.IdHash__c);
                gen.writeDateTimeField('CreatedDate', dispute.CreatedDate);
                if (!String.isEmpty(dispute.Name)) { gen.writeStringField('Name', dispute.Name); } else { gen.writeNullField('Name'); }
                if ( NULL != dispute.IsMessagingEnabled__c ) { gen.writeBooleanField('IsMessagingEnabled__c', dispute.IsMessagingEnabled__c); } else { gen.writeNullField('IsMessagingEnabled__c'); }
                if (!String.isEmpty(dispute.Description__c)) { gen.writeStringField('Description__c', dispute.Description__c); } else { gen.writeNullField('Description__c'); }
                if (!String.isEmpty(dispute.InitiatorHash__c)) { gen.writeStringField('InitiatorHash__c', dispute.InitiatorHash__c); } else {  gen.writeNullField('InitiatorHash__c'); }
                if (!String.isEmpty(dispute.InitiatorFirstName__c)) { gen.writeStringField('InitiatorFirstName__c', dispute.InitiatorFirstName__c); } else { gen.writeNullField('InitiatorFirstName__c'); }
                if (!String.isEmpty(dispute.InitiatorLastName__c)) { gen.writeStringField('InitiatorLastName__c', dispute.InitiatorLastName__c); } else { gen.writeNullField('InitiatorLastName__c'); }
                if (!String.isEmpty(dispute.PrePopulatedDesiredResolution__c)) { gen.writeStringField('PrePopulatedDesiredResolution__c', dispute.PrePopulatedDesiredResolution__c); } else { gen.writeNullField('PrePopulatedDesiredResolution__c'); }
                if (!String.isEmpty(dispute.request_city__c)) { gen.writeStringField('request_city__c', dispute.request_city__c); } else { gen.writeNullField('request_city__c'); }
                if (!String.isEmpty(dispute.request_state__c)) { gen.writeStringField('request_state__c', dispute.request_state__c); } else { gen.writeNullField('request_state__c'); }
                if (!String.isEmpty(dispute.request_zip__c)) { gen.writeStringField('request_zip__c', dispute.request_zip__c); } else { gen.writeNullField('request_zip__c'); }
                if (!String.isEmpty(dispute.request_category__c)) { gen.writeStringField('request_category__c', dispute.request_category__c); } else { gen.writeNullField('request_category__c'); }
                if (!String.isEmpty(dispute.ResponderHash__c)) { gen.writeStringField('ResponderHash__c', dispute.ResponderHash__c); } else { gen.writeNullField('ResponderHash__c'); }
                if (!String.isEmpty(dispute.ResponderFirstName__c)) { gen.writeStringField('ResponderFirstName__c', dispute.ResponderFirstName__c); } else { gen.writeNullField('ResponderFirstName__c'); }
                if (!String.isEmpty(dispute.ResponderLastName__c)) { gen.writeStringField('ResponderLastName__c', dispute.ResponderLastName__c); } else { gen.writeNullField('ResponderLastName__c'); }
                if (!String.isEmpty(dispute.SolutionCenterStatusLabel__c)) { gen.writeStringField('SolutionCenterStatusLabel__c', dispute.SolutionCenterStatusLabel__c); } else { gen.writeNullField('SolutionCenterStatusLabel__c'); }
                if (!String.isEmpty(dispute.Stage__c)) { gen.writeStringField('Stage__c', dispute.Stage__c); } else { gen.writeNullField('Stage__c'); }
                if (!String.isEmpty(dispute.Status__c)) { gen.writeStringField('Status__c', dispute.Status__c); } else { gen.writeNullField('Status__c'); }
                if (!String.isEmpty(dispute.WithdrawalReason__c)) { gen.writeStringField('WithdrawalReason__c', dispute.WithdrawalReason__c); } else { gen.writeNullField('WithdrawalReason__c'); }
                if (null != dispute.PrePopulatedResolutionAmount__c) { gen.writeNumberField('PrePopulatedResolutionAmount__c', dispute.PrePopulatedResolutionAmount__c); } else { gen.writeNullField('PrePopulatedResolutionAmount__c'); }

                gen.writeEndObject(); // record

                //write Experience data
                if (!String.isEmpty(dispute.DisputeExperience__c))
                {
                    gen.writeFieldName('experience');

                    gen.writeStartObject(); // record

                    gen.writeObjectField('record', (NULL == dispute.DisputeExperience__r? new DisputeExperience__c() : dispute.DisputeExperience__r ));

                    gen.writeEndObject(); // experience
                }
                else { gen.writeNullField('experience'); }


                gen.writeFieldName('offers');

                gen.writeStartArray(); // offers

                for (DisputeOffer__c offer : dispute.DisputeOffers__r)
                {
                    gen.writeStartObject(); // offer

                    gen.writeFieldName('record');

                    gen.writeStartObject(); // record

                    gen.writeStringField('IdHash__c', offer.IdHash__c);
                    gen.writeDateTimeField('CreatedDate', offer.CreatedDate);
                    if (!String.isEmpty(offer.CreatedByHash__c)) { gen.writeStringField('CreatedByHash__c', offer.CreatedByHash__c); } else { gen.writeNullField('CreatedByHash__c'); }
                    if (!String.isEmpty(offer.SharedWithHash__c)) { gen.writeStringField('SharedWithHash__c', offer.CreatedByHash__c); } else { gen.writeNullField('CreatedByHash__c'); }
                    if (null != offer.DesiredRefundAmount__c) { gen.writeNumberField('DesiredRefundAmount__c', offer.DesiredRefundAmount__c); } else { gen.writeNullField('DesiredRefundAmount__c'); }
                    if (!String.isEmpty(offer.DesiredResolution__c)) { gen.writeStringField('DesiredResolution__c', offer.DesiredResolution__c); } else { gen.writeNullField('DesiredResolution__c'); }
                    if (!String.isEmpty(offer.DisputeHash__c)) { gen.writeStringField('DisputeHash__c', offer.DisputeHash__c); } else { gen.writeNullField('DisputeHash__c'); }
                    if (null != offer.DisputeOfferExpirationDate__c) { gen.writeDateTimeField('DisputeOfferExpirationDate__c', offer.DisputeOfferExpirationDate__c); } else { gen.writeNullField('DisputeOfferExpirationDate__c'); }
                    if (!String.isEmpty(offer.Note__c)) { gen.writeStringField('Note__c', offer.Note__c); } else { gen.writeNullField('Note__c'); }
                    if (!String.isEmpty(offer.Status__c)) { gen.writeStringField('Status__c', offer.Status__c); } else { gen.writeNullField('Status__c'); }
                    if (null != offer.ResolutionCompleteByDate__c) { gen.writeDateTimeField('ResolutionCompleteByDate__c', offer.ResolutionCompleteByDate__c); } else { gen.writeNullField('ResolutionCompleteByDate__c'); }

                    gen.writeEndObject(); // record

                    gen.writeFieldName('messages');

                    gen.writeStartArray(); // messages

                    if (null != disputeMessageIdMap && !disputeMessageIdMap.isEmpty() && disputeMessageIdMap.containsKey(offer.id))
                    {
                        Map<Id, DisputeMessage__c> disputeMsgMap = new Map<Id, DisputeMessage__c>(disputeMessageIdMap.get(offer.Id));
                        String[] sortList = new String[0];

                        if (null != disputeMsgMap && !disputeMsgMap.isEmpty())  // null-pointer exception insurance
                        {
                            for (DisputeMessage__c msg : disputeMsgMap.values())
                            {
                                sortList.add(JSON.serialize(msg.CreatedDate) + '|' + msg.Id);
                            }

                            sortList.sort();

                            for (String createdStamp : sortList)
                            {
                                if (!String.isEmpty(createdStamp))
                                {
                                    String msgId = createdStamp.split('\\|')[1];
                                    DisputeMessage__c dMsg = disputeMsgMap.get(msgId);

                                    gen.writeStartObject(); // message

                                    gen.writeFieldName('record');

                                    gen.writeStartObject(); // record

                                    gen.writeDateTimeField('CreatedDate', dMsg.CreatedDate);
                                    gen.writeStringField('IdHash__c', dMsg.IdHash__c);
                                    if (!String.isEmpty(dMsg.CreatedByHash__c)) { gen.writeStringField('CreatedByHash__c', dMsg.CreatedByHash__c); } else { gen.writeNullField('CreatedByHash__c'); }
                                    if (!String.isEmpty(dMsg.SharedWithHash__c)) { gen.writeStringField('SharedWithHash__c', dMsg.SharedWithHash__c); } else { gen.writeNullField('SharedWithHash__c'); }
                                    if (!String.isEmpty(dMsg.Message__c)) { gen.writeStringField('Message__c', dMsg.Message__c); } else { gen.writeNullField('Message__c'); }
                                    if (!String.isEmpty(dMsg.DocumentType__c)) { gen.writeStringField('DocumentType__c', dMsg.DocumentType__c); }
                                    if (!String.isEmpty(dMsg.DisputeMessage__c)) { gen.writeStringField('ParentMessageHash__c', dMsg.ParentMessageHash__c); }
                                    gen.writeStringField('RecordTypeId', dMsg.RecordTypeId);

                                    gen.writeEndObject(); // record

                                    gen.writeFieldName('files');

                                    gen.writeStartArray(); // files

                                    AttachedContentDocument[] files = dMsg.AttachedContentDocuments;
                                    if (null != files)
                                    {
                                        for (AttachedContentDocument file : files)
                                        {
                                            ContentVersion version = file.ContentDocument.LatestPublishedVersion;
                                            gen.writeStartObject();

                                            gen.writeStringField('fileId', version.Id);
                                            gen.writeStringField('url', DOWNLOAD_URL + version.Id);
                                            gen.writeStringField('thumbnail', THUMBNAIL_URL + version.Id);
                                            gen.writeStringField('preview', PREVIEW_URL + version.Id);
                                            if (!String.isEmpty(version.Title)) { gen.writeStringField('title', version.Title); } else { gen.writeNullField('title'); }
                                            if (null != version.ContentSize) { gen.writeNumberField('contentSize', version.ContentSize); } else { gen.writeNullField('contentSize'); }
                                            if (!String.isEmpty(version.FileType)) { gen.writeStringField('fileType', version.FileType); } else { gen.writeNullField('fileType'); }

                                            gen.writeEndObject();
                                        }
                                    }

                                    gen.writeEndArray(); // files

                                    gen.writeEndObject(); // message
                                }
                            }
                        }
                    }

                    gen.writeEndArray(); // messages

                    gen.writeEndObject(); //offer
                }

                gen.writeEndArray(); // offers

                gen.writeEndObject(); //dispute

            }

            gen.writeEndArray();

            result = gen.getAsString();

        }

        return result;
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-15
    * @description Supports inserting a ContentVersion record (Chatter File) linked to a DisputeMessage__c parent.
    * @usage SolutionCenterController.uploadMsgFile({OfferHash__c:"O3A17_zKsv"}, "Test Text File", "VGhpcyBpcyBhIHNpbXBsZSB0ZXh0IGZpbGU=", (r,e)=>console.dir( r ), {escape:false});
    * @usage SolutionCenterController.uploadMsgFile({OfferHash__c:"O3A17_zKsv", "ParentMessageHash__c": "PARENT-MSG_HASH"}, "Test Text File w/Parent Msg", "VGhpcyBpcyBhIHNpbXBsZSB0ZXh0IGZpbGU=", (r,e)=>console.dir( r ), {escape:false});
    * @param Map<String, Object> The DisputeMessage__c record to be inserted -- identical to input param to createMessage().
    * @param String The filename (ContentVersion.PathOnClient).
    * @param String The file's base64-encoded content (ContentVersion.VersionData).
    * @return String The new ContentVersion record Id.
    */
    @RemoteAction
    global static String uploadMsgFile(Map<String, Object> fields, String fileName, String base64Data)
    {
        String versionId = '';
        ContactUser ttuser = new ContactUser();
        if ( ttuser.usersType.equalsIgnoreCase('CspLitePortal') )
        {
            String parentOfferHash = (String) fields.get('OfferHash__c');
            if (!String.isEmpty(parentOfferHash))
            {
                Id fileImageRTId = DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('File Image').getRecordTypeId();
                Map<String, Object> msgfields = fields.clone();
                msgfields.put('RecordTypeId', fileImageRTId );
                // SET DB save point in case of DML failure, requiring rollback
                Savepoint trx = Database.setSavepoint();
                try
                {
                    versionId = ChatterFileUtility.createThumbtackHelpCommunityFile(fileName, base64Data);
                    if( !String.isEmpty(versionId) )
                    {
                        String mHash = createMessage( msgfields );
                        if( !String.isEmpty(mHash) )
                        {
                            Id msgId = [SELECT Id FROM DisputeMessage__c WHERE IdHash__c = :mHash LIMIT 1].Id;
                            Id linkId = ChatterFileUtility.linkFile(versionId, msgId);
                            if( String.isEmpty(linkId) )
                            {
                                // insurance for File content and parent message removal
                                Database.rollback(trx); throw new SolutionCenterException( 'Dispute Message-to-file link failed to insert.' );
                            }
                        }
                        else
                        {
                            // insurance for File content removal
                            Database.rollback(trx); throw new SolutionCenterException( 'Dispute Message failed to insert.' );
                        }
                    }
                    else
                    {
                        throw new SolutionCenterException( 'Dispute Message file failed to insert.' ); // nothing to rollback yet
                    }
                }
                catch (Exception dmlex)
                {
                    Database.rollback(trx); throw new SolutionCenterException( 'File upload database exception. ' + dmlex.getMessage() );
                }
            }
            else
            {
                throw new SolutionCenterException('A valid OfferHash__c field value is required.');
            }
        }
        else
        {
            throw new SolutionCenterException('User Type is not permitted to upload files through Solution Center.');
        }
        return versionId;
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-02
    * @description a read-only reference to the current user's ContactId hash -- if the active user is a portal/community user.
    * @return String Hash value derived from the Contact.Id value.
    */
    public String getCurrentUserHash()
    {
        ContactUser ttuser = new ContactUser();
        return String.isEmpty(ttuser.usersContactHash) ? '' : ttuser.usersContactHash;
    }

    //BEN's PREFERRED API INTERFACE
    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Handles the update of a single Dispute record for a Description__c change.
    * @usage SolutionCenterController.updateDisputeDescription("D8EFm8Zsq6","I am changing my description of the problem", (r,e)=>console.dir( e ), {escape:false});
    * @param String The dispute record's IdHash__c value.
    * @param String The new description.
    */
    @RemoteAction
    global static void updateDisputeDescription(String disputeHash, String description)
    {
        Map<String, Object> fields = new Map<String, Object> {'IdHash__c' => disputeHash, 'Description__c' => description};
        SolutionCenterController.updateDispute(fields, DisputeUpdateType.DESCRIPTION);
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Handles the update of a single Dispute record for Status__c = 'Withdrawn'.
    * @usage SolutionCenterController.withdrawDispute("D8EFm8Zsq6","I got scared","Pro is really big and scary", (r,e)=>console.dir( e ), {escape:false});
    * @param String The dispute record's IdHash__c value.
    * @param String The withdrawal reason.
    * @param String Optional note text related to the withdrawal.
    */
    @RemoteAction
    global static void withdrawDispute(String disputeHash, String reason, String notes)
    {
        Map<String, Object> fields = new Map<String, Object> {'IdHash__c' => disputeHash, 'WithdrawalReason__c' => reason, 'WithdrawalNotes__c' => notes};
        SolutionCenterController.updateDispute(fields, DisputeUpdateType.WITHDRAWAL);
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-27
    * @description Handles the update of a single Dispute record for Last Viewed By (internal function).
    * @param String The dispute record's IdHash__c value.
    */
    private static void updateDisputeLastViewedFields(Dispute__c[] disputes)
    {
        ContactUser ttuser = new ContactUser();
        if (ttuser.usersType.equalsIgnoreCase('CspLitePortal'))
        {
            if ( null != disputes && !disputes.isEmpty() ) {  new DisputeViewUpdateQueueable(disputes, ttuser.usersContactId).execute(null); }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Handles the update of a single Dispute record based on update context (DisputeUpdateType enum).
    * @param Map<String, Object> The field values passed from SC Js.
    * @param DisputeUpdateType The type of Dispute__c update being completed.
    */
    private static void updateDispute(Map<String, Object> fields, DisputeUpdateType type)
    {
        ContactUser ttuser = new ContactUser();
        if (ttuser.usersType.equalsIgnoreCase('CspLitePortal'))
        {
            String hash = (String) fields.get('IdHash__c');
            String descripton = (String) fields.get('Description__c');
            String reason = (String) fields.get('WithdrawalReason__c');
            String notes = (String) fields.get('WithdrawalNotes__c');

            //validate required fields
            if (!String.isEmpty(hash) && (type == DisputeUpdateType.DESCRIPTION ? !String.isEmpty(descripton) : !String.isEmpty(reason)))
            {
                // get Dispute by hash value with all related Dispute Offers (for Withdraw processing)
                Dispute__c[] disputes = [SELECT Id, Stage__c, Description__c, InitiatorContact__c, (SELECT Id, Status__c FROM DisputeOffers__r) FROM Dispute__c WHERE IdHash__c = :hash LIMIT 1];
                if (!disputes.isEmpty())
                {
                    Dispute__c dispute = disputes[0];
                    if (type == DisputeUpdateType.DESCRIPTION && !descripton.equals(dispute.Description__c)) // no need to update if description is unchanged
                    {
                        Dispute__c updateDispute = new Dispute__c(Id = dispute.Id, Description__c = descripton);
                        Database.SaveResult dscrResult = SolutionCenterUtility.updateRecord(updateDispute, SolutionCenterUtility.DisputeDML.UPDATE_DISPUTE);
                        if( !dscrResult.success )
                        {
                            throw new SolutionCenterException('Database exception updating Dispute Description.');
                        }
                    }
                    else if (type == DisputeUpdateType.WITHDRAWAL && !'Withdrawn'.equals(dispute.Stage__c))
                    {
                        if (ttuser.usersContactId == dispute.InitiatorContact__c)
                        {
                            DisputeOffer__c[] offersForUpdate = new DisputeOffer__c[0];
                            // update Dispute
                            Dispute__c updateDispute = new Dispute__c(Id = dispute.Id, Status__c = 'Under review', Stage__c = 'Withdrawn', WithdrawalReason__c = reason, WithdrawalNotes__c = notes, WithdrawalDate__c = Datetime.now());
                            Database.SaveResult updateResult = SolutionCenterUtility.updateRecord(updateDispute, SolutionCenterUtility.DisputeDML.WITHDRAW_DISPUTE);
                            if( !updateResult.success )
                            {
                                throw new SolutionCenterException('Database exception updating Dispute with `Withdrawn` status.');
                            }
                            // update pending offers by Queueable, if any
                            for (DisputeOffer__c offer : dispute.DisputeOffers__r)
                            {
                                // Cascade Withdrawal to all Pending Offers
                                if ('Pending'.equalsIgnoreCase(offer.Status__c))
                                {
                                    offersForUpdate.add(new DisputeOffer__c(Id = offer.Id, Status__c = 'Withdrawn'));
                                }
                            }
                            for( Database.SaveResult offerWithdrawResult : SolutionCenterUtility.updateRecords(offersForUpdate, SolutionCenterUtility.DisputeDML.WITHDRAW_OFFER ) )
                            {
                                if( !offerWithdrawResult.success )
                                {
                                    throw new SolutionCenterException('Database exception updating a `Pending` Dispute Offer with `Withdrawn` status.');
                                }
                            }
                        }
                        else
                        {
                            throw new SolutionCenterException('Disputes can only with withdrawn by  Dispute\'s Initiator.');
                        }
                    }
                }
                else
                {
                    throw new SolutionCenterException('Dispute record not found from locator key: ' + hash + '.');
                }
            }
            else
            {
                throw new SolutionCenterException('Required field values missing.');
            }
        }
        else
        {
            throw new SolutionCenterException('User Type is not permitted to update Disputes through Solution Center.');
        }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-15
    * @description A utility function to convert inbound Js Date values to Apex Datetime, used in acceptOffer and createOffer.
    * @param Object A Js datetime value in the form of Date.toISOString() or Date.getTime() -- usually comes in as type Decimal.
    * @return Datetime A Datetime or null if the object parm can't be converted.
    */
    private static Datetime convertDate(Object dObj)
    {
        Datetime result = null;
        if( null != dObj )
        {
            result = (dObj instanceof Decimal) ? Datetime.newInstance(((Decimal) dObj).longValue()) : result;
            if (null == result && dObj instanceof String) { String ds = (String) dObj; result = ds.startsWith('"') ? (Datetime) JSON.deserialize(ds, Datetime.class) : (Datetime) JSON.deserialize('"' + ds + '"', Datetime.class); }
            result = (null == result && dObj instanceof Long) ? Datetime.newInstance((Long) dObj) : result;
        }
        return result;
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-02
    * @description Handles the insert of a single Dispute Offer record with ContactSharedWith__c.
    * @usage SolutionCenterController.createOffer({ 'DisputeHash__c':"D8EFm8Zsq6", 'ResolutionCompleteByDate__c': new Date().getTime(), 'DesiredResolution__c': 'I want a full refund.', 'DesiredRefundAmount__c': 10000, 'Note__c': 'My master bedroom is missing.' }, (r,e)=>console.dir( r ), {escape:false});
    * @param Map<String, Object> The field values passed from SC Js.
    * @return String The IdHash__c of the newly-created DisputeOffer__c record..
    */
    @RemoteAction
    global static String createOffer(Map<String, Object> fields)
    {
        String result = '';

        ContactUser ttuser = new ContactUser();
        if (ttuser.usersType.equalsIgnoreCase('CspLitePortal'))
        {
            Id defaultSolutionCenterOfferRtId = DisputeOffer__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Solution Center Offer').getRecordTypeId();

            String parentDisputeHash = (String) fields.get('DisputeHash__c');
            if (!String.isEmpty('DisputeHash__c'))
            {

                // get parent Offer (req'd field)
                Dispute__c[] disputes = [SELECT Id, IdHash__c, InitiatorTotalOfferCount__c, ResponderTotalOfferCount__c, MaxOfDaysForResponderFirstAction__c, InitiatorConfirmationDate__c, ResponderFirstActionDate__c, ResponderFirstActionDueDate__c, MaxofDaysforOffer__c, InitiatorContact__c, ResponderContact__c, (SELECT Id, IdHash__c, Status__c FROM DisputeOffers__r ORDER BY CreatedDate DESC) FROM Dispute__c WHERE IdHash__c = :parentDisputeHash LIMIT 1];
                if (!disputes.isEmpty())
                {
                    Dispute__c dispute = disputes[0];

                    // See if this new offer actually represents a counter offer vis a vis there existing a most recent pending offer
                    if (!dispute.DisputeOffers__r.isEmpty() && 'Pending'.equalsIgnoreCase(dispute.DisputeOffers__r[0].Status__c))
                    {
                        DisputeOffer__c counteredOffer = dispute.DisputeOffers__r[0];
                        SolutionCenterUtility.updateRecord(new DisputeOffer__c(Id = counteredOffer.Id, Status__c = 'Countered'), SolutionCenterUtility.DisputeDML.COUNTER_OFFER);
                    }

                    // gather field values for Offer insert
                    // Js Date usage: new Date() or new Date().toISOString()
                    Datetime resolutionByDate = SolutionCenterController.convertDate(fields.get('ResolutionCompleteByDate__c'));
                    DateTime now = DateTime.now();
                    String offerName = 'Offer from ' + ttuser.usersContactName;
                    String noteText = (String) fields.get('Note__c');
                    String desiredResolution = (String) fields.get('DesiredResolution__c');
                    Decimal maxDays = dispute.MaxofDaysforOffer__c;
                    Integer daysOut = (null == maxDays) ? 0 : maxDays.intValue();
                    DateTime expiration = now.addDays(daysOut);
                    Object desiredAmtObject = fields.get('DesiredRefundAmount__c');
                    Decimal desiredAmt = (null == desiredAmtObject) ? 0 : ((desiredAmtObject instanceof Decimal) ? (Decimal) desiredAmtObject : Decimal.valueOf((String) desiredAmtObject));

                    //Load Offer Record
                    DisputeOffer__c newOffer = new DisputeOffer__c(Name = offerName, DisputeOfferExpirationDate__c = expiration, ResolutionCompleteByDate__c = resolutionByDate, Status__c = 'Pending', DesiredResolution__c = desiredResolution, DesiredRefundAmount__c = desiredAmt, Note__c = noteText, ContactCreatedBy__c = ttuser.usersContactId, OwnerId = ttuser.usersId, Dispute__c = dispute.Id, DisputeHash__c = dispute.IdHash__c, RecordTypeId = defaultSolutionCenterOfferRtId);
                    newOffer.ContactSharedWith__c = (ttuser.usersContactId == dispute.InitiatorContact__c) ? dispute.ResponderContact__c : dispute.InitiatorContact__c ;

                    String errorString = '';
                    Database.SaveResult insertResult = SolutionCenterUtility.createRecord(newOffer, SolutionCenterUtility.DisputeDML.CREATE_OFFER);
                    if (!insertResult.isSuccess())
                    {
                        // unique IdHash__c insurance
                        if( StatusCode.DUPLICATE_VALUE == insertResult.errors[0].statusCode )
                        {
                            newOffer.IdHash__c = 'O'+ CryptoUtility.generateRandomString(15);
                            insertResult = SolutionCenterUtility.createRecord( newOffer, SolutionCenterUtility.DisputeDML.CREATE_OFFER );
                            if (!insertResult.isSuccess()) { errorString += insertResult.getErrors()[0].getMessage() + '\n'; } } else { errorString = insertResult.getErrors()[0].getMessage() + '\n'; }
                    }
                    else
                    {
                        Integer offerCount = dispute.DisputeOffers__r.size() + 1;
                        result = [SELECT IdHash__c FROM DisputeOffer__c WHERE Id = :newOffer.Id LIMIT 1].IdHash__c;
                        SolutionCenterUtility.doNewOfferRelatedDisputeUpdates( dispute, ttuser.usersContactId, offerCount );
                    }

                    if (!String.isEmpty(errorString))
                    {
                        throw new SolutionCenterException('Database IO Error: ' + errorString + '.');
                    }
                }
                else
                {
                    throw new SolutionCenterException('A dispute record was not found using locator key: ' + parentDisputeHash + '.');
                }
            }
            else
            {
                throw new SolutionCenterException('A valid Dispute record locator value is required.');
            }
        }
        else
        {
            throw new SolutionCenterException('User not permitted to create Dispute Offers through Solution Center.');
        }

        return result;
    }


    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Handles the update of a single Dispute Offer record, Setting Status__c to 'Accepted'.
    * @usage SolutionCenterController.acceptOffer('O3A17_zKsv', new Date().setDate(29), (r,e)=>console.dir( JSON.parse(r) ), {escape:false});
    * @param String The OfferHash__c value of the DisputeOffer to be accepted.
    * @param Object A Js Date object.
    */
    @RemoteAction
    global static void acceptOffer(String offerHashId, Object resolutionCompleteByDate)
    {
        ContactUser ttuser = new ContactUser();
        if (ttuser.usersType.equalsIgnoreCase('CspLitePortal'))
        {
            String acceptedStatus = 'Accepted';

            if (!String.isEmpty(offerHashId))
            {
                // find the target Offer by IdHash__c parm
                DisputeOffer__c[] disputeOffers = [SELECT Id, Status__c, ResolutionCompleteByDate__c, DesiredResolution__c, DesiredRefundAmount__c, Dispute__c, Dispute__r.ResponderContact__c, Dispute__r.InitiatorContact__c, Dispute__r.ResponderFirstActionDate__c, Dispute__r.ResponderFirstActionDueDate__c, ContactCreatedBy__c, ContactSharedWith__c FROM DisputeOffer__c WHERE IdHash__c = :offerHashId LIMIT 1];
                if (!disputeOffers.isEmpty())
                {
                    DisputeOffer__c offer = disputeOffers[0];
                    System.debug(LoggingLevel.WARN, 'CONTEXT USER: ' + JSON.serialize(ttuser.activeUser));
                    System.debug(LoggingLevel.WARN, 'OFFER: ' + JSON.serialize(offer));
                    if (ttuser.usersContactId == offer.ContactSharedWith__c)
                    {

                        if (!acceptedStatus.equals(disputeOffers[0].Status__c))
                        {
                            // Js Date usage: new Date() or new Date().toISOString()
                            DateTime now = Datetime.now();
                            Datetime resolutionByDate = SolutionCenterController.convertDate(resolutionCompleteByDate);
                            DisputeOffer__c updateOffer = new DisputeOffer__c(Id = offer.Id, Status__c = acceptedStatus);
                            updateOffer.ResolutionCompleteByDate__c = (null == resolutionByDate)? offer.ResolutionCompleteByDate__c: resolutionByDate;
                            SObject[] offerUpdates = new SObject[] {updateOffer};

                            //evaluate "fist responder satus
                            Dispute__c disputeUpdate = new Dispute__c(Id = offer.Dispute__c, Status__c = 'Under review', Stage__c = 'Agreement made', FinalResolution__c = offer.DesiredResolution__c, FinalResolutionAmount__c = offer.DesiredRefundAmount__c);
                            disputeUpdate.ResponderFirstActionDate__c = (null == offer.Dispute__r.ResponderFirstActionDate__c) ? now : offer.Dispute__r.ResponderFirstActionDate__c;
                            offerUpdates.add(disputeUpdate);

                            SolutionCenterUtility.updateRecords(offerUpdates, SolutionCenterUtility.DisputeDML.ACCEPT_OFFER);
                        }
                    } else { throw new SolutionCenterException('An offer cannot be accepted by the person who created it.'); } } else { throw new SolutionCenterException('An offer record was not found using locator key: ' + offerHashId + '.'); } } else { throw new SolutionCenterException('Required field values are missing.'); } } else { throw new SolutionCenterException('User Type is not permitted to accept Dispute Offers through Solution Center.'); }
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Retrieve DisputeMessage RecordType ids for use in SC Js.
    * @usage SolutionCenterController.getMessageRecordTypes( (r,ev)=> console.dir( r ), {escape:false} )
    * @return Map<String, String> A map of record type Ids to their Names.
    */
    @ReadOnly
    @RemoteAction
    global static Map<String, String> getMessageRecordTypes()
    {
        Map<String, String> rts = new Map<String, String>();

        for (RecordTypeInfo info : DisputeMessage__c.SObjectType.getDescribe().getRecordTypeInfosByName().values())
        {
            String name = info.getName();
            if (!'Master'.equalsIgnoreCase(name) && !'Confidential'.equalsIgnoreCase(name)) { rts.put(info.getRecordTypeId(), name); }
        }

        return rts;
    }

    /**
    * @author Paul Coleman
    * @date 2018-02-06
    * @description Handles the insert of a single Dispute Message record with ContactSharedWith__c.
    * @usage SolutionCenterController.createMessage({ 'OfferHash__c': "O3A17_zKsv", 'Message__c': 'A Test Message' }, (r,e)=>console.dir( r ), {escape:false});
    * @param Map<String, Object> The field values passed from SC Js.
    * @return String The IdHash__c of the newly-created DisputeMessage__c record.
    */
    @RemoteAction
    global static String createMessage(Map<String, Object> fields)
    {
        String result = '';
        // DisputeMessage__c.DisputeMessage__c is only set on DisputeMessage__c records when its RT is "File Image".
        // No other DisputeMessage__c records should have a parent DisputeMessage set.
        // The reason for the DisputeMessage.DisputeMessage__c field is to allow multiple file uploads to all be related to one Parent msg of RT "Message"
        // All DisputeMessages will have a DisputeOffer__c field value

        ContactUser ttuser = new ContactUser();
        if (ttuser.usersType.equalsIgnoreCase('CspLitePortal'))
        {
            Map<Id, String> rts = SolutionCenterUtility.getMessageRecordTypeIdMap();
            Map<String, Object> msgfields = fields.clone();
            String parentOfferHash = (String) msgfields.get('OfferHash__c');
            if (!String.isEmpty('OfferHash__c'))
            {
                // get parent Offer (req'd field)
                DisputeOffer__c[] offers = [SELECT Id, IdHash__c, ContactCreatedBy__c, ContactSharedWith__c, Dispute__c, Dispute__r.InitiatorTotalMessageCount__c, Dispute__r.ResponderTotalMessageCount__c, Dispute__r.ResponderFirstActionDate__c, Dispute__r.ResponderFirstActionDueDate__c, Dispute__r.InitiatorContact__c, Dispute__r.ResponderContact__c  FROM DisputeOffer__c WHERE IdHash__c = :parentOfferHash LIMIT 1];
                if (!offers.isEmpty())
                {
                    // gather field values for Message insert
                    DisputeOffer__c offer = offers[0];
                    String msgText = (String) msgfields.get('Message__c');
                    String recordTypeId = (String) msgfields.get('RecordTypeId');
                    if (String.isEmpty(recordTypeId) || !rts.containsKey(recordTypeId))
                    {
                        //default to Message RT
                        for (Id rtId : rts.keySet()) { if ('Message'.equalsIgnoreCase(rts.get(rtId))) { recordTypeId = rtId; break; } }
                    }

                    String msgName = 'Message from ' + ttuser.usersContactName;
                    // CREATE NEW DISPUTE MESSAGE RECORD SHELL
                    DisputeMessage__c newMsg = new DisputeMessage__c(Name = msgName, Message__c = msgText, ContactCreatedBy__c = ttuser.usersContactId, OwnerId = ttuser.usersId, OfferHash__c = offer.IdHash__c, DisputeOffer__c = offer.Id, Dispute__c = offer.Dispute__c, RecordTypeId = recordTypeId);
                    newMsg.ContactSharedWith__c = (ttuser.usersContactId == offer.Dispute__r.InitiatorContact__c) ? offer.Dispute__r.ResponderContact__c : offer.Dispute__r.InitiatorContact__c;

                    // HANDLE FILE IMAGE RECORD TYPE
                    String recordTypeName = rts.get(recordTypeId);
                    if ('File Image'.equalsIgnoreCase(recordTypeName))
                    {
                        //do file type parent lookup (req'd field)
                        String parentMsgHash = (String) msgfields.get('ParentMessageHash__c');
                        newMsg.DocumentType__c = (String) msgfields.get('DocumentType__c');
                        if (!String.isEmpty(parentMsgHash))
                        {
                            // lookup parent msg
                            for (DisputeMessage__c parentMessage : [SELECT Id, IdHash__c FROM DisputeMessage__c WHERE IdHash__c = :parentMsgHash LIMIT 1])
                            {
                                newMsg.DisputeMessage__c = parentMessage.Id;
                                newMsg.ParentMessageHash__c = parentMessage.IdHash__c;
                            }
                        }
                    }
                    String errorString = '';
                    Database.SaveResult insertResult = SolutionCenterUtility.createRecord(newMsg, SolutionCenterUtility.DisputeDML.CREATE_MSG);
                    if (!insertResult.isSuccess())
                    {
                        // unique IdHash__c insurance
                        if (StatusCode.DUPLICATE_VALUE == insertResult.errors[0].statusCode)
                        {
                            newMsg.IdHash__c = 'M' + CryptoUtility.generateRandomString(15);
                            insertResult = SolutionCenterUtility.createRecord(newMsg, SolutionCenterUtility.DisputeDML.CREATE_MSG);
                            if (!insertResult.isSuccess()) { errorString += insertResult.getErrors()[0].getMessage() + '\n'; }
                        }
                        else { errorString += insertResult.getErrors()[0].getMessage() + '\n'; }
                    }
                    else
                    {
                        result = [SELECT IdHash__c from DisputeMessage__c WHERE Id = :newMsg.Id].IdHash__c;

                        //eval "first responder" status
                        Dispute__c dispute = offer.Dispute__r;
                        Datetime now = Datetime.now();
                        Boolean isResponder = ttuser.usersContactId == dispute.ResponderContact__c;
                        Boolean isNotAlreadySet = null == dispute.ResponderFirstActionDate__c;
                        if ( isResponder && isNotAlreadySet && 1 == offers.size() )
                        {
                            SolutionCenterUtility.updateRecord( new Dispute__c( Id = dispute.Id, ResponderFirstActionDate__c = now, Status__c = 'In progress', Stage__c = 'Offer pending'), SolutionCenterUtility.DisputeDML.UPDATE_DISPUTE );
                        }

                        SolutionCenterUtility.catchupDisputeMessageCounts(newMsg);
                    }

                    if (!String.isEmpty(errorString)) { throw new SolutionCenterException('Database IO Error: ' + errorString + '.'); }
                } else { throw new SolutionCenterException('An offer record was not found using locator key: ' + parentOfferHash + '.'); } } else { throw new SolutionCenterException('A valid Offer record locator value is required.'); } } else { throw new SolutionCenterException('User Type is not permitted to create Dispute Messages through Solution Center.'); }

        return result;
    }

}