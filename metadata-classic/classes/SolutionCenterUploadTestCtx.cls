/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       3/13/18      pcoleman           Created
========+============+=================+===============================================*/
public with sharing class SolutionCenterUploadTestCtx
{
    public blob chatterFile { get; set; }
    public String fileName { get; set; }
    public String hashId { get; set; }
    public String versionId { get; set; }

    public PageReference uploadFile() {

        if( !String.isEmpty(this.hashId) && null != this.chatterFile )
        {
            Id documentId;
            Id msgRecordId;
            Id netId = [SELECT Id FROM Network WHERE NAME = 'Thumbtack Help' LIMIT 1].Id;

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = this.chatterFile;
            cv.Title = fileName;
            cv.PathOnClient = filename;
            cv.NetworkId = netId;
            cv.Origin = 'H';

            insert cv;

            documentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            if (NULL != msgRecordId)
            {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = documentId;
                cdl.LinkedEntityId = msgRecordId;
                cdl.ShareType = 'I';

                insert cdl;
            }

            this.versionId = cv.Id;
        }

        return ApexPages.currentPage();
    }

    @RemoteAction public static String doLongString(String longString) {
        return longString;
    }
}