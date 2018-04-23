/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       01/11/18      pcoleman           Created to manage Chatter File (initially for Solution Centaur
========+============+=================+===============================================*/
global without sharing class ChatterFileUtility
{

    /**
    * @author Paul Coleman
    * @date 2017-01-17
    * @description Inserts a new ContentVersion record bound to a specific network.
    * @param String The file name of the new chatter file record.
    * @param String A string of file content, base64-encoded.
    * @return Id  The new record Id.
    */
    global static Id createThumbtackHelpCommunityFile( String fileName, String base64Data )
    {
        Id hcNetId = [SELECT Id FROM Network WHERE NAME = 'Thumbtack Help' LIMIT 1].Id;
        return createFile( fileName, base64Data, NULL, hcNetId);
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-15
    * @description Overloads the linkFile() function with a default sharing parm.
    * @param String A parent ContentDocument.Id value, the linked chatter file.
    * @param String A record Id that determines chatter file sharing and
    *           whose page layout can display the Files related list.
    * @return Id  The new ContentDocumentLink record Id.
    */
    global static Id linkFile( Id contentVersionId, Id linkId )
    {
        return linkFile( contentVersionId, linkId, NULL );
    }

    /**
    * @author Paul Coleman
    * @date 2018-03-15
    * @description Inserts a Chatter File Link (ContentDocumentLink) record.
    * @param String A parent ContentDocument.Id value, the linked chatter file.
    * @param String A record Id that determines chatter file sharing and
    *           whose page layout can display the Files related list.
    * @param String A share type setting (how the parent chatter file is shared [optiona].
    * @return Id  The new ContentDocumentLink record Id.
    */
    global static Id linkFile( Id contentVersionId, Id linkId, String shareType)
    {
        String result;
        if ( !String.isEmpty(contentVersionId) && !String.isEmpty(linkId) )
        {
            ContentVersion[] cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            if( !cv.isEmpty() )
            {
                Id documentId = cv[0].ContentDocumentId;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = documentId;
                cdl.LinkedEntityId = linkId;
                // default sharing: `based on linked record's sharing status`, aka `I`
                cdl.ShareType = String.isEmpty(shareType)? 'I' : shareType;

                insert cdl;
                result = cdl.Id;
            }
        }
        return result;
    }


    /**
    * @author Paul Coleman
    * @date 2018-03-15
    * @description Inserts a Chatter File (ContentVersion) record.
    * @param String The filename, aka Title and PathOnClient fields value.
    * @param String A File's content in Base64- & URL-encoded format (UTF-8)
    * @param String A parent ContentDocument.Id value for versioning [optional].
    * @param String A Network Id, aka Community designator.
    * @return Id  The new ContentVersion record Id.
    */
    global static Id createFile(String fileName, String base64Data, Id contentDocumentId, Id netId)
    {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.Title = fileName;
        cv.PathOnClient = filename;
        cv.NetworkId = netId;
        cv.Origin = 'H';

        // a non-null contentDocumentId will create a new version (and set the ContentDocument's LatestPublishedVersionId to the new version's record Id
        cv.ContentDocumentId = contentDocumentId;

        insert cv;
        return cv.Id;
    }
    
}