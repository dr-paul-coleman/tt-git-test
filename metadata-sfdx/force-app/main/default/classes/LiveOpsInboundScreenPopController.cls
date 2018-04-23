/*
  Copyright (c) 2015, 2016, 2017 Thumbtack  All rights reserved.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2015-12-18  Paul Coleman      Created 
 1.1     2016-05-10  Paul Coleman      Removed IsBanned__c per JIRA CS-982
 1.2     2017-07-05  Kristin Hasna     Added Marketplace Integrity RT for
                                            popping but not changing owner
 1.3     2018-04-09  Paul Coleman      Fixed but related to duplicate Case
                                            creation for `Contact not found`.
                                            Changed doCaseQuery filter criteria
                                            based on changing Picklist values.
 =======+===========+=================+=================================*/
global with sharing class LiveOpsInboundScreenPopController
{
    global LiveOpsInboundScreenPopController(){}
    global LiveOpsInboundScreenPopController(ApexPages.StandardController stdController){}

    private static final Id CSUPPORT_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
    private static final Id LIVE_CHAT_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Live Chat').getRecordTypeId();
    private static final Id MI_RECORD_TYPE_ID = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity').getRecordTypeId();

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description A function defined in the LiveOpsInboundScreenPop page <apex ... action='initialize'..> tag.
    * @return A PageReference to LiveOpsInboundScreenPop with a Case Id if possible.
    */
    public PageReference initialize()
    {
        String caseId = ApexPages.currentPage().getParameters().get('id');
        if (caseId == null)
        {
            try
            {
                Map<String, String> parms = ApexPages.currentPage().getParameters();
                if ( Test.isRunningTest() )
                {
                    System.debug(LoggingLevel.INFO, 'Page Url: ' + JSON.serialize(ApexPages.currentPage().getUrl()));
                    System.debug(LoggingLevel.INFO, 'Page Parameters: ' + JSON.serialize(parms));
                }
                String ani = (null == parms.get('ANI') || ''.equals(parms.get('ANI').trim())) ? 'UNKNOWN' : parms.get('ANI');
                String dnis = (null == parms.get('DNIS') || ''.equals(parms.get('DNIS').trim())) ? parms.get('ProductPhone') : parms.get('DNIS');
                String phoneSearchTerm = ani.replaceAll('[^0-9]', '');
                Contact[] contacts = [FIND :phoneSearchTerm IN PHONE FIELDS RETURNING Contact(Id, Name, AccountId) LIMIT 2][0];

                //if SOSL results >= 2, cannot decide here which contact to use, defer to Page Js for rules
                Case result;
                if ( contacts.size() < 2 )
                {
                    result = this.doCaseQuery( ( contacts.isEmpty()? NULL: contacts[0] ), phoneSearchTerm, dnis );
                    if( NULL == result.Id ) { insert result; }
                    this.doOwnerIdChange( result, dnis );
                    return getPageRef( parms, result.Id, phoneSearchTerm, dnis );
                }
                else { return null; }
            }
            catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); return null; }
        }
        else { return null; }
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Query Case records by Contact Id OR ANI.
    * @return Case The case located or created.
    */
    public Case doCaseQuery( Contact contct, String ani, String dnis ) {

        Id[] contactIds = ( NULL == contct ) ? new Id[0]: new Id[]{contct.Id};
        Id[] recordTypeIds = new Id[] { CSUPPORT_RECORD_TYPE_ID, LIVE_CHAT_RECORD_TYPE_ID, MI_RECORD_TYPE_ID };
        String[] origins = new String[] {'LiveOps Inbound Support Call', 'Inbound Phone', 'Email', 'Live Chat', 'LiveOps Inbound', 'Social Media', 'Text Message', 'Voicemail', 'Web', 'Inbound Support Call'};
        Case[] targetCases = Database.query( 'SELECT Id, RecordTypeId, RecordType.Name, OwnerId, DNIS__c  FROM Case WHERE IsClosed = false AND  Origin IN :origins AND  RecordTypeId IN :recordTypeIds AND  ( ANI__c = :ani OR ContactId IN :contactIds ) ORDER BY CreatedDate DESC LIMIT 1' );
        return targetCases.isEmpty()? new Case( ContactId = (NULL == contct? NULL : contct.Id), AccountId = (NULL == contct? NULL : contct.AccountId), RecordTypeId = CSUPPORT_RECORD_TYPE_ID, ANI__c = ani, DNIS__c = dnis, Subject = 'Inbound Support Call from ' + ani, Origin = 'Inbound Phone', Priority = 'Low') : targetCases[0];

    }
    
    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Changes OwnerId to the current user if the Case is not an MI Case.
    */
    private void doOwnerIdChange( Case existingCase, String dnis )
    {
        if ( MI_RECORD_TYPE_ID != existingCase.RecordTypeId )
        {
            Id currentUserId = UserInfo.getUserId();
            //switch case owner if not an mi case
            if( existingCase.OwnerId != currentUserId )
            {
                existingCase.OwnerId = UserInfo.getUserId();
                existingCase.DNIS__c = dnis;
                update existingCase;
            }
        }
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description Load up the Visualforce page with the same query parameters that were sent by the CTI adapter (the screen pop source).
    * @param Map<String, String> All of the query string parms passed on the original url for the screen pop.
    * @param Id The case record Id located or inserted by the intialize() function.
    * @param String The ANI phone number passed on the original url for the screen pop.
    * @param String The DNIS phone number passed on the original url for the screen pop.
    * @return PageReference the current page redirected with query string parms -- including case Id.
    */
    public PageReference getPageRef(Map<String, String> inputParms, Id caseId, String ani, String dnis)
    {
        PageReference liveops = Page.LiveOpsInboundScreenPop;
        Map<String,String> parms = liveops.getParameters();
        parms.putAll(inputParms);
        parms.put('id', caseId);
        parms.put('DNIS', dnis);
        parms.put('ANI', ani); //override with stripped phone formatting
        liveops.setRedirect(true);
        System.debug(LoggingLevel.FINEST, 'Redirecting to CASE: ' + caseId);
        return liveops;
    }

    /**
    * @author Paul Coleman
    * @date 2017-10-17
    * @description A utility function for allowing the LiveOpsInboundScreenPop page to execute SOSL via Ajax call.
    * @param String The SOSL query string.
    * @return String A serialised version of the SOSL result set.
    */
    @remoteAction
    global static String doSOSL(String sosl)
    {
        return JSON.serialize(search.query(sosl));
    }
}