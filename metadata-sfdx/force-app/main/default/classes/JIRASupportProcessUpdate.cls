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
=======+===========+=================+================================================
*/
global class JIRASupportProcessUpdate {
	public static HttpResponse res {get;set;}
    public class customException extends Exception{}

	webservice static void getIssue(String spId )
    {
        List<Comments__c> noteList = new List<Comments__c>();
        List<Comments__c> notes = [Select Id,Body__c,Name From Comments__c WHERE SupportProcess__c =: spId];
        Boolean isCreate = false;
        Boolean attachmentsExist = false;
        SupportProcess__c supportProcess = [Select Id,JIRAComments__c,Comments__c,Name,JiraId__c,IssueSentToJiraStatus__c,JIRALink__c From SupportProcess__c Where Id =:spID LIMIT 1]; 
        if(supportProcess == null || supportProcess.JiraId__c == null) return;
        
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

        
            req.setMethod( 'GET');
            req.setEndpoint(baseUrl + '/'+ supportProcess.JiraId__c);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
            req.setHeader('Content-Type', 'application/json');
            //req.setBody(getbody(supportProcess,isCreate));
            string errMsg = (isCreate?'Not Created':'Not Synced To Salesforce On: '+String.valueOf(Date.today()));
            system.debug('request: '+req);
            try
            {
               res = (new Http()).send(req);
               system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
                
            } Catch(Exception ex){
                /*CustomException__c exeption = new CustomException__c();
                exeption.Name = 'JIRASupportProcessUpdate Exeption';
                exeption.ErrorMessage__c = ex.getMessage();
                exeption.RecordId__c = bugId;
                insert exeption;*/
                system.debug(ex);
                
                
            }

            if(res != null){
                
                if(res.getStatusCode() == 200)
                {
                    //success
                    getIssueObj myReturn = (JIRASupportProcessUpdate.getIssueObj)JSON.deserialize(res.getBody(), JIRASupportProcessUpdate.getIssueObj.class);
                    
                  
                  
                    
                    if(myReturn.Fields.comment != null)
                    {
                        for(Comments c:myReturn.Fields.comment.comments)
                        {
                            Boolean exist = false;
                            for(Comments__c note:notes)
                            {
                                if(note.Name.contains(c.id) || c.body.contains('SALESFORCE COMMENT'))
                                {
                                    system.debug('Exists = true');
                                    exist = true;
                                }
                            }
                            if(exist == false)
                            {
                                system.debug('exists = false');
                                Comments__c n = new Comments__c();
                                n.SupportProcess__c = spId;
                                n.Name = 'JIRA COMMENT - '+c.Id;
                                n.Body__c = c.body;
                                noteList.add(n);
                                system.debug('c.body: '+c.body);
                            }
                            
                        }
                    }
                    supportProcess.IssueSentToJiraStatus__c = 'Issue Synced to Salesforce On: '+String.valueOf(Date.today());
                    
                } else {
                    supportProcess.IssueSentToJiraStatus__c = errMsg;
                }
                
            }
        update supportProcess;
        if(noteList.size()>0)if(!Test.isRunningTest())insert noteList;
    }
    

    
    public class getIssueObj{

        public Status Status;
        public Attachment Attachment;
        public Assignee Assignee;
        public Comment Comment;

        public String expand;
        public String id;
        public String self;
        public String key;
        public Fields fields;

        public Priority Priority;
        public Watches Watches;
        public Comments Comments;
        public Components Components;
        public Project Project;
        public StatusCategory StatusCategory;
        public Issuetype Issuetype;

    }

    public class Status {
        public String self;
        public String description;
        public String iconUrl;
        public String name;
        public String id;
    }
    public class Attachments {
        public String self;
        public String id;
        public String filename;
    }

    public class Assignee {
        public String self;
        public String name;
        public String key;
        public String emailAddress;
        //public AvatarUrls avatarUrls;
        public String displayName;
        public Boolean active;
        public String timeZone;
    }
    public class Comment {
        public Integer startAt;
        public Integer maxResults;
        public Integer total;
        public List<Comments> comments;
    }
    

    public class Priority {
        public String self;
        public String iconUrl;
        public String name;
        public String id;
    }

    public class Watches {
        public String self;
        public Integer watchCount;
        public Boolean isWatching;
    }

    public class Comments {
        public String id;
        public String self;
        public String body;
        public DateTime created;
    }

    public class Customfield_10030 {
        public String self;
        public String value;
        public String id;
    }

    public class Components {
        public String self;
        public String id;
        public String name;
    }

    public class Project {
        public String self;
        public String id;
        public String key;
        public String name;
    }

    public class StatusCategory {
        public String self;
        public Integer id;
        public String key;
        public String colorName;
        public String name;
    }

    public class Fields {
        public Issuetype issuetype;
        public Project project;
        public List<FixVersions> fixVersions;
        public Integer workratio;
        public String lastViewed;
        public Watches watches;
        public String created;
        public Priority priority;
        public List<FixVersions> versions;
        public Assignee assignee;
        public String updated;
        public Status status;
        public List<Components> components;
        public String description;
        public String summary;
        public Assignee creator;
        public Assignee reporter;
        public Comment comment;
        public Votes votes;
        public List<Attachments> attachment;
    }

    public class FixVersions {
        public String self;
        public String id;
        public String description;
        public String name;
        public Boolean archived;
        public Boolean released;
    }

    public class Issuetype {
        public String self;
        public String id;
        public String description;
        public String iconUrl;
        public String name;
        public Boolean subtask;
        public Integer avatarId;
    }

    public class Votes {
        public String self;
        public Integer votes;
        public Boolean hasVoted;
    }

    public class createIssueReturn{
        public string Id;//unique Id
        public string key;//Id used for api calls and searching in JIRA
        public string self;//url to get the created issue
    }
}