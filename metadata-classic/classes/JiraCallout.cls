/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2016 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:
------------
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     01-13-2017  Scott Purcell      Created
1.1     03-06-2017  Scott Purcell      Added Error handling Object
=======+===========+=================+================================================
*/
global with sharing class JiraCallout 
{
    public static HttpResponse res {get;set;}
    public class customException extends Exception{}
    public static void handler(List<String> bugIds,Boolean isCreate)
    { 
        if(isCreate == true)createIssue(bugIds,isCreate);
    }
    public static void AttachmentHandler(List<String> bugIds,List<Attachment> attachments)
    { 
        List<String> attachIds = new List<String>();
        for(Attachment att: Attachments)
        {
            attachIds.add(att.Id);
        }
        createAttachments(bugIds,true,attachIds);
    }

    @future (callout=true)
    private static void createIssue(List<String> bugIds, boolean isCreate)
    {
        Boolean attachmentsExist = false;
    	List<Bug__c> bugList = [Select Id,UserCode__c,ProjectId__c,JiraStatus__c,Labels__c,Name,JiraId__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,IssueType__c,Priority__c,Project__c From Bug__c Where Id IN:bugIds]; 
    	if(bugList.size()==0) return;
	    String baseUrl; 
	    String username;
	    String password;
    	for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
        	username = jira.Username__c;       // JIRA username
        	password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;
        for(Bug__c bug:bugList)
        {
        	req.setMethod( 'POST');
	        req.setEndpoint(baseUrl + '/');
	        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
	        req.setHeader('Content-Type', 'application/json');
	        req.setBody(getbody(bug,isCreate));
	        string errMsg = (isCreate?'Issue Not Created In Jira On: '+String.valueOf(DateTime.now()):'Issue Not Created In Jira On: '+String.valueOf(DateTime.now()));
	        system.debug('request: '+req);
	        try
            {
	           res = (new Http()).send(req);
               system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());  
	        } Catch(Exception ex){
	             system.debug(ex); 
	        }
	        if(res != null){
	        	
                if(res.getStatusCode() == 201 || res.getStatusCode() == 200)
	            {
	                myReturn = (JiraCallout.createIssueReturn)JSON.deserialize(res.getBody(), JiraCallout.createIssueReturn.class);
                    system.debug('Key: '+myReturn.key);
	                bug.IssueSentToJiraStatus__c = 'Issue Created In Jira On: '+String.valueOf(DateTime.now());
	                bug.JiraId__c = myReturn.key;
	                bug.JIRALink__c = 'https://thumbtack.atlassian.net/browse/'+myReturn.key;
                    
	            } else {
                    bug.IssueSentToJiraStatus__c = errMsg;
                    bug.IssueCreated__c = false;
	            }
	        }
        }
        update bugList;
    }


    webservice static void createSupportProcessIssue(Id supportProcessId)
    {
        Boolean attachmentsExist = false;
        SupportProcess__c sp = [Select Id,UserCode__c,JIRASummary__c,Name,JIRAEscalationNotes__c,IssueCreated__c,JIRALink__c,JiraId__c,IssueSentToJiraStatus__c From SupportProcess__c Where Id =:supportProcessId LIMIT 1]; 
        if(sp == null ) return;
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;
        
        req.setMethod( 'POST');
        req.setEndpoint(baseUrl + '/');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        req.setHeader('Content-Type', 'application/json');
        req.setBody(getSupportbody(sp));
        string errMsg = 'Issue Not Created In Jira On: '+String.valueOf(DateTime.now());
        system.debug('request: '+req);
        try
        {
           res = (new Http()).send(req);
           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());  
        } Catch(Exception ex){
            system.debug(ex);
        }
        if(res != null){
            
            if(res.getStatusCode() == 201 || res.getStatusCode() == 200)
            {
                myReturn = (JiraCallout.createIssueReturn)JSON.deserialize(res.getBody(), JiraCallout.createIssueReturn.class);
                system.debug('Key: '+myReturn.key);
                sp.IssueSentToJiraStatus__c = 'Issue Created In Jira On: '+String.valueOf(DateTime.now());
                sp.JiraId__c = myReturn.id;
                sp.JIRALink__c = 'https://thumbtack.atlassian.net/browse/'+myReturn.key;
                
            } else {
                sp.IssueSentToJiraStatus__c = errMsg;
                sp.IssueCreated__c = false;
            }
        }
        
        update sp;
    }
    webservice static void updateSupportProcessIssue(Id supportProcessId)
    {
        Boolean attachmentsExist = false;
        SupportProcess__c sp = [Select Id,UserCode__c,JIRASummary__c,Name,JIRAEscalationNotes__c,IssueCreated__c,JIRALink__c,JiraId__c,IssueSentToJiraStatus__c From SupportProcess__c Where Id =:supportProcessId LIMIT 1]; 
        if(sp == null ) return;
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.GETBaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;
        
        req.setMethod( 'GET');
        req.setEndpoint(baseUrl + '/'+ sp.JiraId__c);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        req.setHeader('Content-Type', 'application/json');
        string errMsg = ('Update Not Synced To Jira On: '+String.valueOf(DateTime.now()));
        system.debug('request: '+req);
        try
        {
           res = (new Http()).send(req);
           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());  
        } Catch(Exception ex){
             system.debug(ex); 
        }
        if(res != null){
            
            if(res.getStatusCode() == 201 || res.getStatusCode() == 200)
            {
                myReturn = (JiraCallout.createIssueReturn)JSON.deserialize(res.getBody(), JiraCallout.createIssueReturn.class);
                system.debug('myReturn: '+myReturn);
                sp.IssueSentToJiraStatus__c = 'Issue Created In Jira On: '+String.valueOf(DateTime.now());
                sp.JiraId__c = myReturn.id;
                sp.JIRALink__c = 'https://thumbtack.atlassian.net/browse/'+myReturn.key;
                if(myReturn.Fields != null)sp.JIRASummary__c = myReturn.Fields.summary;
                if(myReturn.Fields != null)sp.JIRAEscalationNotes__c = 'FROM JIRA: '+myReturn.Fields.description;
                system.debug('myReturn.description: '+sp.JIRAEscalationNotes__c );
                 system.debug('myReturn.summary: '+sp.JIRASummary__c);
                
            } else {
                sp.IssueSentToJiraStatus__c = errMsg;
                sp.IssueCreated__c = false;
            }
        }
         update sp;
    }
    webservice static void updateIssue(String bugId)
    {
        Boolean isCreate = false;
        Boolean attachmentsExist = false;
        Bug__c bug = [Select Id,ProjectId__c,UserCode__c,JiraStatus__c,Labels__c,Name,JiraId__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,IssueType__c,Priority__c,Project__c From Bug__c Where Id =:bugId LIMIT 1]; 
        if(bug==null) return;
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.GETBaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;
        req.setMethod( 'PUT');
        req.setEndpoint(baseUrl + '/'+ bug.JiraId__c);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        req.setHeader('Content-Type', 'application/json');
        req.setBody(getUpdateBody(bug,isCreate));
        string errMsg = (isCreate?'Update Not Synced To Jira On: '+String.valueOf(DateTime.now()):'Update Not Synced To Jira On: '+String.valueOf(DateTime.now()));
        system.debug('request: '+req);
        try
        {
           res = (new Http()).send(req);
           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
           bug.IssueSentToJiraStatus__c = 'Update Synced To Jira On: '+String.valueOf(DateTime.now());
           system.debug('Successfully updated JIRA');
        } Catch(Exception ex){
            bug.IssueSentToJiraStatus__c = errMsg;
        }
        update bug;
    }
    webservice static void getComments(Id id,String jiraId,Boolean isBug)
    {
        Boolean isCreate = false;
        Boolean attachmentsExist = false;
        List<Comments__c> existingComList = [Select Id,Bug__c,SupportProcess__c,Body__c From Comments__c Where (SupportProcess__c =: id OR Bug__c =: id)];
        List<Comments__c> comList = new List<Comments__c>();
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        getCommentsReturn comReturn;
        req.setMethod( 'GET');
        req.setEndpoint(baseUrl + '/' + jiraId + '/comment');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        req.setHeader('Content-Type', 'application/json');
        
        string errMsg = (isCreate?'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()):'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()));
        system.debug('request: '+req);
        try
        {
           res = (new Http()).send(req);
           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
           system.debug('Successfully updated SFDC from JIRA');
        } Catch(Exception ex){
            CustomException__c exeption = new CustomException__c();
            exeption.Name = 'JiraCalloutExeption-getComment';
            exeption.ErrorMessage__c = ex.getMessage();
            exeption.RecordId__c = id;
            exeption.BugRecordType__c = 'Jira Integration';
            insert exeption;
        }
        if(res != null)
        {
            
            if(res.getStatusCode() == 201 || res.getStatusCode() == 200)
            {
                comReturn = (JiraCallout.getCommentsReturn)JSON.deserialize(res.getBody(), JiraCallout.getCommentsReturn.class);
                system.debug('Total: '+comReturn.total);
                if(comReturn.comments != null)
                {
                    for(Comments co:comReturn.comments)
                    {
                        Boolean exists = false;
                        for(Comments__c c:existingComList)
                        {
                            system.debug('c.Body__c: '+c.Body__c);
                            system.debug('co.body: '+co.body);

                            if(c.Body__c.contains(co.body))
                            {
                                exists = true;
                            }

                        }
                        if(!exists)
                        {
                            Comments__c com = new Comments__c();
                            if(isBug)com.Bug__c = id;
                            if(!isBug)com.SupportProcess__c = id;
                            com.Body__c = co.body;
                            com.CreatedInJira__c = true;
                            comList.add(com);
                        }
                    }
                }
                
                
            }
            if(comList.size()>0)insert comList;
        }
    }
    @future(callout=true)//called from the NoteTriggerHandler
    public static void addComment(List<String> commentIds)
    {
        Boolean isCreate = false;
        Boolean attachmentsExist = false;
        List<Comments__c> commentList = [Select Id,Name,Body__c,Bug__c,SupportProcess__c From Comments__c Where Id IN:commentIds];
        List<String>bugIds = new List<String>();
        List<String>supportIds = new List<String>();
        for(Comments__c n:commentList)
        {
            if(n.SupportProcess__c != null)
            {
                supportIds.add(n.SupportProcess__c);
            }
            if(n.Bug__c != null)
            {
               bugIds.add(n.Bug__c);
            }
        }
        List<SupportProcess__c> supPros = [Select Id,JIRASummary__c,Name,JIRAEscalationNotes__c,IssueCreated__c,JIRALink__c,JiraId__c,IssueSentToJiraStatus__c From SupportProcess__c Where Id IN: supportIds];
        
        List<Bug__c> bugs = [Select Id,UserCode__c,ProjectId__c,JiraStatus__c,Labels__c,Name,JiraId__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,IssueType__c,Priority__c,Project__c From Bug__c Where Id IN:bugIds]; 
        
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;
        for(Comments__c note:commentList)
        {
            if(bugs.size()>0)
            {
                for(Bug__c bug:bugs)
                {
                    if(bug.Id == note.Bug__c)
                    {
                        req.setMethod( 'POST');
                        req.setEndpoint(baseUrl + '/' + bug.JiraId__c + '/comment');
                        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
                        req.setHeader('Content-Type', 'application/json');
                        string body = '{'
                            + '"body" : "' + 'SALESFORCE COMMENT - '+note.Name + ', '+note.Body__c + '"'
                            + '}';
                        system.debug('body: ' + body);
                        req.setBody(body);
                        string errMsg = (isCreate?'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()):'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()));
                        system.debug('request: '+req);
                        try
                        {
                           res = (new Http()).send(req);
                           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
                           bug.IssueSentToJiraStatus__c = 'Comment Synced To Jira On: '+String.valueOf(DateTime.now());
                           system.debug('Successfully updated JIRA');
                        } 
                        Catch(Exception ex)
                        {
                            system.debug('exception: '+ex);
                        }
                    }       
                }
            }
            if(supPros.size()>0)
            {
                for(SupportProcess__c sup:supPros)
                {
                    if(sup.Id == note.SupportProcess__c)
                    {
                        req.setMethod( 'POST');
                        req.setEndpoint(baseUrl + '/' + sup.JiraId__c + '/comment');
                        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
                        req.setHeader('Content-Type', 'application/json');
                        string body = '{'
                            + '"body" : "' + 'SALESFORCE COMMENT - '+note.Name + ', '+note.Body__c + '"'
                            + '}';
                        system.debug('body: ' + body);
                        req.setBody(body);
                        string errMsg = (isCreate?'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()):'Comment Not Synced To Jira On: '+String.valueOf(DateTime.now()));
                        system.debug('request: '+req);
                        try
                        {
                           res = (new Http()).send(req);
                           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
                           sup.IssueSentToJiraStatus__c = 'Comment Synced To Jira On: '+String.valueOf(DateTime.now());
                           system.debug('Successfully updated JIRA');
                        } 
                        Catch(Exception ex)
                        {
                            system.debug('exception: '+ex);
                        }
                    }       
                }
            }
        }
        if(bugs.size()>0)update bugs;
        if(supPros.size()>0)update supPros;
    }
    @future (callout=true)
    public static void createAttachments(List<String> bugIds, boolean isCreate,List<String> attIds)
    {
        Boolean attachmentsExist = false;
        List<Bug__c> bugList = [Select Id,UserCode__c,JiraId__c,JiraAttachmentList__c From Bug__c Where Id IN:bugIds];
        List<Attachment> attachments = [Select Id,Name,BodyLength,ContentType,Description,Body,ParentId FROM Attachment Where Id IN:attIds];

        if(bugList.size()==0 || Attachments.size() == 0) return;
        createIssueReturn myReturn;
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }
        for(Bug__c bug:bugList)
        {
            Boolean exists = false;
            for(Attachment attach :attachments)
            {
                if(bug.JiraAttachmentList__c != null && bug.JiraAttachmentList__c.contains(attach.Name))
                {
                    system.debug('Attachment Exists');
                    exists = true;
                    bug.IssueSentToJiraStatus__c = 'Attachments Are Synced as-of: '+String.valueOf(DateTime.now());
                }
                if(bug.Id == attach.ParentId && bug.JiraId__c != null && exists == false)
                {
                    system.debug('Attachment does not exist');
                    Blob file_body = attach.Body;
                    String file_name = attach.Name;
                    String auth_header = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
                    String url = baseUrl+'/' + bug.JiraId__c + '/attachments';
                    String boundary = '----------------------------741e90d31eff';
                    String header = '--' + boundary + '\n' +
                        'Content-Disposition: form-data; name="file"; filename="' + file_name + '";\n' +
                        'Content-Type: application/octet-stream';
                    String footer = '--' + boundary + '--';
                    String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
                    while (headerEncoded.endsWith('=')){
                        header += ' ';
                        headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
                    }

                    String bodyEncoded = EncodingUtil.base64Encode(file_body);
                    Blob bodyBlob = null;
                    String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());

                    if (last4Bytes.endsWith('==')) {
                        last4Bytes = last4Bytes.substring(0, 2) + '0K';
                        bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;
                        
                        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                        bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);
                    } else if (last4Bytes.endsWith('=')) {
                        last4Bytes = last4Bytes.substring(0, 3) + 'N';
                        bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length()-4) + last4Bytes;
                        footer = '\n' + footer;
                        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                        bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);              
                    } else {
                        footer = '\r\n' + footer;
                        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                        bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);  
                    }

                    HttpRequest req = new HttpRequest();
                    req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
                    req.setHeader('Authorization', auth_header);
                    req.setHeader('X-Atlassian-Token', 'nocheck');
                    req.setMethod('POST');
                    req.setEndpoint(url);
                    req.setBodyAsBlob(bodyBlob);
                    req.setTimeout(120000);

                    try
                    {
                       res = (new Http()).send(req);
                       system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
                        
                    } Catch(Exception ex){
                         system.debug(ex);
                    }

                    if(res != null){
                        if(res.getStatusCode() == 200 || res.getStatusCode() == 201)
                        {
                            System.debug('Attachment successful');
                            bug.IssueSentToJiraStatus__c = 'Synced W/ Attachments On: '+String.valueOf(DateTime.now()) ; 
                            
                        } else {
                            bug.IssueSentToJiraStatus__c = 'Attachments Not Synced To Jira On: '+String.valueOf(DateTime.now());
                        }
                    }
                }
            }
        }
        update bugList;
    }
    public static string getSupportBody(SupportProcess__c c)
    {
        String projectId ='13600';
         String reporter = c.UserCode__c;
        if(reporter == null)reporter = 'SalesforceSystemIntegration';
        //String reporter = 'SalesforceSystemIntegration';
        //if(UserInfo.getName() == 'Alyssa Wilson')reporter = 'awilson';
        //if(UserInfo.getName() == 'Kevin Giltz')reporter = 'keving';
        //if(UserInfo.getName() == 'Deirdre Galluzzo')reporter = 'deirdre';
        //if(UserInfo.getName() == 'Kyle Thorup')reporter = 'kyle';
        //if(UserInfo.getName() == 'Kristine Ann Pielago ')reporter = 'krpielago';
        //if(UserInfo.getName() == 'Christina Caacoy')reporter = 'crcaacoy';
        

        String taskDesc = c.JIRAEscalationNotes__c;
        if(taskDesc != null)
        {
            taskDesc = taskDesc.stripHtmlTags();
            system.debug('taskDesc: '+taskDesc);
            taskDesc = taskDesc.replace('<br>','  ');
            taskDesc = taskDesc.replace('<b>','*');
            taskDesc = taskDesc.replace('<i>','_');
            taskDesc = taskDesc.replace('<p>', ' ');
            taskDesc = taskDesc.replace('<ul><li>', ' ');
            taskDesc = taskDesc.replace('<li>', ' ');
            taskDesc = taskDesc.replace('</li>', ' ');
            taskDesc = taskDesc.replace('</ul>', ' ');
            taskDesc = taskDesc.replace('</p>', ' ');
            taskDesc = taskDesc.replace('<a href=', ' ');
            taskDesc = taskDesc.replace('</a>', '  ');
            taskDesc = taskDesc.replace('\n',' ');
            //taskDesc = taskDesc.replace('target="_blank" title="Follow link">https://www.thumbtack.com/admin/requests/request?req=','   Thumbtack.com Id: ');
        
            taskDesc = taskDesc.escapeHtml4();
        }
        system.debug('taskDesc: '+taskDesc);
        String name = c.Name;
        if(name != null)name.escapeHtml4();
        String body=  
            '{' 
            + '"fields": {'
                + '"project": {'
                    + '"id": "' + projectId + '"'
                + '},'
                + '"summary": "' + name + '",'
                + '"issuetype": {'
                    + '"name": "' + 'Task' + '"'
                + '},'
               + '"reporter": {'
                    + '"name": "' + reporter + '"'
                + '},'
                + '"priority": {'
                    + '"name": "' + 'Low'+ '"'
                + '},'
                + '"description": "' + taskDesc + '"'
            + '}}';
            system.debug('body: '+body);
            return body;

    }
//{"fields": {"project": {"id": "13600"},"summary": "test summary","issuetype": {"name": "Task"},"priority": {"name": "Low"},"description": "test description"}}
    public static string getBody(Bug__c c, boolean isCreate)
    {
        String label1 = null;
        String label2 = null;
        String label3 = null;
        String label4 = null;
        String label5 = null;
        String label6 = null;
         String reporter = c.UserCode__c;
        if(reporter == null)reporter = 'SalesforceSystemIntegration';
        //String reporter = 'SalesforceSystemIntegration';
        //if(UserInfo.getName() == 'Alyssa Wilson')reporter = 'awilson';
        //if(UserInfo.getName() == 'Kevin Giltz')reporter = 'keving';
        //if(UserInfo.getName() == 'Deirdre Galluzzo')reporter = 'deirdre';
        //if(UserInfo.getName() == 'Kyle Thorup')reporter = 'kyle';
        //if(UserInfo.getName() == 'Kristine Ann Pielago ')reporter = 'krpielago';
        //if(UserInfo.getName() == 'Christina Caacoy')reporter = 'crcaacoy';
    	String Priority = c.Priority__c;
        if(priority == 'High')priority = 'High ';
        if(c.ProjectId__c != '10800' )
        {
            if(c.Labels__c != null)
            {
                List<String> labels = c.Labels__c.split(';');
                for(Integer i = 0;i<labels.size();i++)
                {
                    if(label1 != null && label2 != null && label3 != null && label4 != null && label5 == null)label4 = labels[i];
                    if(label1 != null && label2 != null && label3 != null && label4 == null)label4 = labels[i];
                    if(label1 != null && label2 != null && label3 == null)label3 = labels[i];
                    if(label1 != null && label2 == null)label2 = labels[i];
                    if(label1 == null)label1 = labels[i];
                }
            }
    	  system.debug('1:'+label1+', 2: '+label2+', 3: '+label3 + ', 4: '+label4 +', 5: '+label5);	    	
	    }

        String bugDesc = c.BugDescription__c;
        bugDesc = bugDesc.stripHtmlTags();
        bugDesc = bugDesc.replace('<br>','  ');
        bugDesc = bugDesc.replace('<b>','*');
        bugDesc = bugDesc.replace('<i>','_');
        bugDesc = bugDesc.replace('<p>', ' ');
        bugDesc = bugDesc.replace('<ul><li>', ' ');
        bugDesc = bugDesc.replace('<li>', ' \\n');
        bugDesc = bugDesc.replace('</li>', ' ');
        bugDesc = bugDesc.replace('</ul>', ' ');
        bugDesc = bugDesc.replace('</p>', ' ');
        bugDesc = bugDesc.replace('<a href=', ' ');
        bugDesc = bugDesc.replace('</a>', '  ');
        bugDesc = bugDesc.replace('\n','\\n');
        bugDesc = bugDesc.replace('target="_blank" title="Follow link">https://www.thumbtack.com/admin/requests/request?req=','   Thumbtack.com Id: ');
        bugDesc = bugDesc.escapeHtml4();
        String name = c.Name.escapeHtml4();
        String body=  
        	'{' 
            + '"fields": {'
                + '"project": {'
                    + '"id": "' + c.ProjectId__c + '"'
                + '},'
                + '"summary": "' + name + '",'
                + '"issuetype": {'
                    + '"name": "' + 'Bug' + '"'
                + '},'
               //+ '"reporter": {'
               //     + '"name": "' + reporter + '"'
               // + '},'
                + '"priority": {'
                    + '"name": "' + priority+ '"'
                + '},'
                + '"labels": [';
            if(c.ProjectId__c != '10800' )
            {
                if(label5 != null)body += '"'+label5+'",';
                if(label4 != null)body += '"'+label4+'",';
                if(label4 != null)body += '"'+label4+'",';
                if(label3 != null)body += '"'+label3+'",';
                if(label2 != null)body += '"'+label2+'",';
                if(label1 != null)body += '"'+label1+'"';
            }
            body +=  '],'
                + '"description": "' + bugDesc + '"'
            + '}}';
            system.debug('body: '+body);
            return body;

    }
    public static string getUpdateBody(Bug__c c, boolean isCreate)
    {
         String reporter = c.UserCode__c;
        if(reporter == null)reporter = 'SalesforceSystemIntegration';
        //String reporter = 'SalesforceSystemIntegration';
        //if(UserInfo.getName() == 'Alyssa Wilson')reporter = 'awilson';
        //if(UserInfo.getName() == 'Kevin Giltz')reporter = 'keving';
        //if(UserInfo.getName() == 'Deirdre Galluzzo')reporter = 'deirdre';
        //if(UserInfo.getName() == 'Kyle Thorup')reporter = 'kyle';
        //if(UserInfo.getName() == 'Kristine Ann Pielago ')reporter = 'krpielago';
        //if(UserInfo.getName() == 'Christina Caacoy')reporter = 'crcaacoy';
        String Priority = c.Priority__c;
        if(priority == 'High')priority = 'High ';
        String bugDesc = c.BugDescription__c;
        bugDesc = bugDesc.stripHtmlTags();
        bugDesc = bugDesc.replace('<br>','  ');
        bugDesc = bugDesc.replace('<b>','*');
        bugDesc = bugDesc.replace('<i>','_');
        bugDesc = bugDesc.replace('<p>', ' ');
        bugDesc = bugDesc.replace('<ul><li>', ' ');
        bugDesc = bugDesc.replace('<li>', ' \\n');
        bugDesc = bugDesc.replace('</li>', ' ');
        bugDesc = bugDesc.replace('</ul>', ' ');
        bugDesc = bugDesc.replace('</p>', ' ');
        bugDesc = bugDesc.replace('<a href=', ' ');
        bugDesc = bugDesc.replace('</a>', '  ');
        bugDesc = bugDesc.replace('target="_blank" title="Follow link">https://www.thumbtack.com/admin/requests/request?req=','   Thumbtack.com Id: ');
        bugDesc = bugDesc.replace('\n','\\n');
        bugDesc = bugDesc.escapeHtml4();
        String name = c.Name.escapeHtml4();
        String body=  
            '{' 
            +'"update": {'
            +'},'
            + '"fields": {'
                + '"summary": "' + name + '",'
              
                + '"priority": {'
                    + '"name": "' + priority+ '"'
                + '},'
                + '"description": "' + bugDesc + '"'
            + '}}';
            system.debug('body: '+body);
            return body;
    }

    public static getIssueObj jsonObj {get;set;}
    public class getIssueObj
    {
        public Status Status;
        public String key;

    }

    public class Status 
    {
        public String self;
        public String description;
        public String iconUrl;
        public String name;
        public String id;
    }
 
    public class createIssueReturn
    {
        public string Id;//unique Id
        public string key;//Id used for api calls and searching in JIRA
        public string self;//url to get the created issue
        public Fields fields;
    }
    public class Fields
    {
        public String summary;
        public String description;
    }
    public class getCommentsReturn
    {
        public Integer maxResults;
        public Integer total;
        public List<Comments> comments;
    }
    public class Comments
    {
        public string body;//comment body
    }
    public static JiraCallout.getIssueObj parse(String json) 
    {
        return (JiraCallout.getIssueObj) System.JSON.deserialize(json, JiraCallout.getIssueObj.class);
    }

}

    /*
    webservice static void addWatchers(Id bugId)
    {
        Bug__c bug = [Select Id,JiraId__c,WatchersAdded__c From Bug__c Where Id =:bugId LIMIT 1]; 
        if(bug == null || bug.WatchersAdded__c == true)return;
        
        String baseUrl; 
        String username;
        String password;
        for(JiraAPI__c jira : JiraAPI__c.getAll().values())
        {
            baseUrl = jira.BaseURL__c;        // Base URL of your JIRA instance
            username = jira.Username__c;       // JIRA username
            password = jira.Password__c;       // JIRA password
        }

        HttpRequest req = new HttpRequest();
        createIssueReturn myReturn;

        req.setMethod( 'POST');
        req.setEndpoint(baseUrl + '/' + bug.JiraId__c + '/watchers');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        req.setHeader('Content-Type', 'application/json');
        string body = 
        '{'
          +'"watchers": ['
            +'{'
              +'"username": "sarah"'
            +'},'
            +'{'
              +'"username": "kyle"'
            +'},'
            +'{'
              +'"username": "awilson"'
            +'},'
            +'{'
              +'"username": "deirdre"'
            +'},'
            +'{'
              +'"username": "keving"'
            +'},'
            +'{'
              +'"username": "crcaacoy"'
            +'}'
          +']'
        +'}';
        system.debug('body: ' + body);
        req.setBody(body);
        string errMsg = 'Watchers Not Synced To Jira On: '+String.valueOf(DateTime.now());
        system.debug('request: '+req);
        try
        {
           res = (new Http()).send(req);
           system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
           if(res.getStatusCode() == 200 || res.getStatusCode() == 201)
            {
               bug.IssueSentToJiraStatus__c = 'Watchers Synced To Jira On: '+String.valueOf(DateTime.now());
               bug.WatchersAdded__c = true;
               system.debug('Successfully updated JIRA');
            }
            else
            {
                bug.IssueSentToJiraStatus__c = errMsg;
            }
        } Catch(Exception ex){
            system.debug(system.LoggingLevel.ERROR,'Error: ' + ex);
            system.debug(system.LoggingLevel.ERROR,'res: ' + res); 
            bug.IssueSentToJiraStatus__c = errMsg;
        }
        update bug;
    }*/