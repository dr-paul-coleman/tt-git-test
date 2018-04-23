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
global class GetJiraIssue {
	public static HttpResponse res {get;set;}
    public class customException extends Exception{}

	webservice static void getIssue(String bugId )
    {
        List<Comments__c> noteList = new List<Comments__c>();
        List<Comments__c> notes = [Select Id,Body__c,Name From Comments__c WHERE Bug__c =: bugId];
        Boolean isCreate = false;
        Boolean attachmentsExist = false;
        Bug__c bug = [Select Id,ProjectId__c,JIRAComments__c,JiraAttachmentList__c,Labels__c,Comments__c,Name,JiraStatus__c,JiraId__c,BugDescription__c,DateFixed__c,DateLogged__c,IssueSentToJiraStatus__c,JIRALink__c,IssueType__c,Priority__c,Project__c From Bug__c Where Id =:bugId LIMIT 1]; 
        if(bug == null) return;
        
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
            req.setEndpoint(baseUrl + '/'+ bug.JiraId__c);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
            req.setHeader('Content-Type', 'application/json');
            //req.setBody(getbody(bug,isCreate));
            string errMsg = (isCreate?'Not Created':'Not Synced To Salesforce On: '+String.valueOf(Date.today()));
            system.debug('request: '+req);
            try
            {
               res = (new Http()).send(req);
               system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res);
                
            } Catch(Exception ex){
                /*CustomException__c exeption = new CustomException__c();
                exeption.Name = 'GetJiraIssue Exeption';
                exeption.ErrorMessage__c = ex.getMessage();
                exeption.RecordId__c = bugId;
                insert exeption;*/
                system.debug(ex);
                
                
            }

            if(res != null){
                
                if(res.getStatusCode() == 200)
                {
                    //success
                    getIssueObj myReturn = (GetJiraIssue.getIssueObj)JSON.deserialize(res.getBody(), GetJiraIssue.getIssueObj.class);
                    
                    //bug.Summary__c = myReturn.Fields.summary;
                    bug.JiraStatus__c = myReturn.Fields.status.name;
                    bug.Priority__c = myReturn.Fields.priority.name;
                   /* bug.BugDescription__c = myReturn.Fields.description;
                    system.debug('description from JIRA: '+bug.BugDescription__c);
                    bug.BugDescription__c = bug.BugDescription__c .unescapeHtml4();
                    bug.BugDescription__c = bug.BugDescription__c.replace('"https://','<br>"https://');
                    bug.BugDescription__c = bug.BugDescription__c.replace('"https://','<br>"https://');
                    system.debug('description from JIRA: '+bug.BugDescription__c);*/
                    //************************ TODO COmments ********************
                    system.debug('attachments: '+myReturn.Fields.attachment);
                    bug.JiraAttachmentList__c = null;
                    if(myReturn.Fields.attachment !=null)
                    {
                        for(Attachments a:myReturn.Fields.attachment)
                        {
                            bug.JiraAttachmentList__c += a.filename+',';
                        }
                    }
                    system.debug('bug.JiraAttachmentList__c: '+bug.JiraAttachmentList__c);
                    if(myReturn.Fields.comment != null)
                    {
                        for(Comments c:myReturn.Fields.comment.comments)
                        {
                            Boolean exist = false;
                            for(Comments__c note:notes)
                            {
                                //system.debug('not.Title: '+note.Title + ', comment.Id: JIRA COMMENT -'+c.id);
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
                                n.Bug__c = bugId;
                                n.Name = 'JIRA COMMENT - '+c.Id;
                                n.Body__c = c.body;
                                noteList.add(n);
                                system.debug('c.body: '+c.body);
                            }
                            
                        }
                    }
                    bug.IssueSentToJiraStatus__c = 'Issue Synced to Salesforce On: '+String.valueOf(Date.today());
                    
                } else {
                   /* CustomException__c exeption = new CustomException__c();
                    exeption.Name = 'GetJiraIssue Exeption';
                    exeption.ErrorMessage__c = res.getBody();
                    exeption.RecordId__c = bugId;
                    exeption.BugRecordType__c = 'Jira Integration';
                    insert exeption;*/
                    bug.IssueSentToJiraStatus__c = errMsg;
                }
                
            }
        update bug;
        if(noteList.size()>0)insert noteList;
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