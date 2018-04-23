/* Copyright (c) [2015 -] 2017 Thumbtack. All rights reserved.

Version    Date     Author            Description
=======+===========+=================+================================================
1.0     2017-03-17  Scott Purcell      Created
1.1     2017-10-11  Mendel Guillaume   Modified to prevent duplicate Contact creation
1.2     2017-10-30  Paul Coleman       Added NULL exclusion condition
=======+===========+=================+================================================
*/
global with sharing class CheckrAPI
{
    public static Id miRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Marketplace Integrity Restricted').getRecordTypeId();
    public static Id cRTId=Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
    public static Group miQueue = [Select Id from Group where Type = 'Queue' AND Name = 'Marketplace Integrity' LIMIT 1];
    public static String returnMessage {get;set;}
    public static HttpResponse res {get;set;}
    public static String username  {get;set;}
    public static String password  {get;set;}
    public static String baseUrl  {get;set;}

    public static HttpRequest getRequest()
    {
        HttpRequest reqs = new HttpRequest();
        reqs.setMethod( 'GET');
        reqs.setTimeout(60000);
        reqs.setHeader('Content-Type', 'application/json');
        reqs.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username+ ':'+password)));
        return reqs;
    }
    public static void getSettings()
    {
        CheckerAPISettings__c checkr = CheckerAPISettings__c.getInstance('default');
        baseUrl = checkr.BaseURL__c;
        username = checkr.Username__c;
        password = checkr.Password__c;
    }
    @future(callout=true) public static void getCheckr(List<String> reportIds)
    {
        //HttpRequest req = getRequest();
        getSettings();
        List<String> bCheckReportIDs = new List<String>();
        Map<String,BackgroundCheck__c> bCheckMap = new Map<String,BackgroundCheck__c>();
        List<BackgroundCheck__c> bChecks = [Select Id,Name,GlobalWatchlistSearch__c,CountyCriminalSearchId__c,StateCriminalSearchId__c,
                StateCriminalSearch__c,CountyCriminalSearch__c,NationalCriminalSearch__c,SexOffenderSearch__c,ReportId__c,
                CandidateName__c,SuppliedEmail__c,DOB__c,NationalCriminalSearchId__c,
                GlobalWatchlistSearchId__c,SexOffenderSearchId__c,CandidateId__c ,AdverseItems__c FROM BackgroundCheck__c  Where ReportId__c IN:reportIds];
        system.debug('bChecks: '+bChecks.size());
        for(BackgroundCheck__c b:bChecks)
        {
            bCheckMap.put(b.ReportId__c,b);
            bCheckReportIDs.add(b.ReportId__c);
        }
        List<Case> cases = [Select Id,BGCReportId__c,BGCCharges__c,Subject From Case Where BGCReportId__c IN:bCheckMap.keyset()];
        //making inital callout to get bcheck info from Checkr
        for(BackgroundCheck__c b:bChecks)
        {
            if(b.ReportId__c != null)
            {
                HttpRequest req = getRequest();
                req.setEndpoint(baseUrl + 'reports/'+b.ReportId__c+'?include=candidate,county_criminal_searches,sex_offender_searches,national_criminal_searches,global_watchlist_searches');
                system.debug('request: '+req);
                try
                {
                    res = (new Http()).send(req);
                    system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());
                    if(res.getStatusCode() == 200)
                    {
                        bCheckMap = initialLogic(b.ReportId__c,res.getBody(),cases,bCheckMap);
                        system.debug('initialLogic done: ');
                        secondaryCallout(Bchecks,res.getBody());
                        system.debug('callouts done: ');
                    }
                } Catch(Exception ex){
                    system.debug(ex.getMessage());
                }
            }
        }
    }

    public static Map<String,BackgroundCheck__c> initialLogic(String rId,String result,List<Case> cases,Map<String,BackgroundCheck__c> bCheckMap)
    {

        checkrReturn myReturn = (CheckrAPI.checkrReturn)JSON.deserialize(result, CheckrAPI.checkrReturn.class);
        system.debug('myReturn: '+myReturn);
        for(Case css:cases)
        {
            if(bCheckMap.containsKey(css.BGCReportId__c))
            {
                css.BackgroundCheck__c = bCheckMap.get(css.BGCReportId__c).Id;
                if(bCheckMap.get(css.BGCReportId__c).Name != css.Subject.abbreviate(79)) bCheckMap.get(css.BGCReportId__c).Name = css.Subject.abbreviate(79);
            }
        }
        return bCheckMap;
    }

    webservice static void getReportsBulk() //call from ScheduledBackgroundCheckSyncReports
    {
        system.debug('in getreportsBulk');
        List<BackgroundCheck__c> bChecks = [Select Id,Name,GlobalWatchlistSearch__c,CountyCriminalSearchId__c,StateCriminalSearchId__c,
                StateCriminalSearch__c,CountyCriminalSearch__c,NationalCriminalSearch__c,SexOffenderSearch__c,ReportId__c,
                CandidateName__c,SuppliedEmail__c,DOB__c,NationalCriminalSearchId__c,
                GlobalWatchlistSearchId__c,SexOffenderSearchId__c,CandidateId__c ,AdverseItems__c FROM BackgroundCheck__c  WHERE (BackgroundCheckComplete__c =: false  AND Account__c =: null) OR (CandidateId__c=:null AND Account__c != null) Limit 49];
        system.debug('bChecks.size(): '+bChecks.size()+', Bchecks:'+bChecks);
        secondaryCallout(bchecks,null);
    }

    webservice static void getReports(String bCheckId)//called from button
    {
        system.debug('in getreports');
        List<BackgroundCheck__c> bChecks = [Select Id,Name,GlobalWatchlistSearch__c,CountyCriminalSearchId__c,StateCriminalSearchId__c,
                StateCriminalSearch__c,CountyCriminalSearch__c,NationalCriminalSearch__c,SexOffenderSearch__c,ReportId__c,
                CandidateName__c,SuppliedEmail__c,DOB__c,NationalCriminalSearchId__c,
                GlobalWatchlistSearchId__c,SexOffenderSearchId__c,CandidateId__c ,AdverseItems__c FROM BackgroundCheck__c  Where Id =:bCheckId LIMIT 1];
        system.debug('bChecks.size(): '+bChecks.size());
        secondaryCallout(bchecks,null);
    }

    public static void secondaryCallout(List<BackgroundCheck__c>bChecks,String result)
    {
        Map<String,BackgroundCheck__c> bCheckMap = new Map<String,BackgroundCheck__c>();
        Map<String,Account> emailAccountMap = new Map<String,Account>();
        List<Account> accountsThatNeedContacts = new List<Account>();
        Map<Id,Contact> contactAccountMap = new Map<Id,Contact>();
        List<Contact> consForOneAccount = new List<Contact>();
        List<Account> accListToInsert = new List<Account>();
        List<Contact> conListToInsert = new List<Contact>();
        List<Account> allAccounts = new List<Account>();
        Set<Contact> conSet = new Set<Contact>();
        List<Decimal>conIDs = new List<Decimal>();
        List<String> emails = new List<String>();
        List<Decimal>usrIds = new List<Decimal>();
        for(BackgroundCheck__c b: bChecks)
        {
            bCheckMap.put(b.ReportId__c,b);
        }
        List<Case> cases =[Select Id,BGCCharges__c,Subject,RecordTypeId,SuppliedEmail,Category__c,BackgroundCheck__c,OwnerID,BGCReportId__c From Case Where BGCReportId__c IN: bCheckMap.keyset()];
        system.debug('cases.size(): '+cases.size());
        //update case information
        for(Case c:cases)
        {
            if(bCheckMap.containsKey(c.BGCReportId__c))
            {
                c.BGCCharges__c = bCheckMap.get(c.BGCReportId__c).AdverseItems__c;
                if(c.BackgroundCheck__c == null)c.BackgroundCheck__c = bCheckMap.get(c.BGCReportId__c).Id;
                if(c.OwnerID == '00531000007OiRr')c.OwnerId= miQueue.Id;
                c.SuppliedEmail = bCheckMap.get(c.BGCReportId__c).SuppliedEmail__c;
                c.Category__c = 'Other';
                c.SubCategory__c = 'Background check (not clear)';
                c.RecordTypeId = miRecordTypeId;
                String name = c.Subject;
                if(name.length()>80)name = name.abbreviate(79);
                bCheckMap.get(c.BGCReportId__c).name = name;
            }
        }
        //doing the callout
        for(BackgroundCheck__c bCheck:bCheckMap.values())
        {
            getSettings();
            HttpRequest req = getRequest();
            req.setEndpoint(baseUrl + 'reports/'+bCheck.ReportId__c+'?include=candidate,county_criminal_searches,sex_offender_searches,national_criminal_searches,global_watchlist_searches');
            system.debug('request: '+req);
            try
            {
                if(result != null)bCheck = doLogic(bCheck,result);
                //only make the callout if it has not been done already
                if(result == null)
                {
                    res = (new Http()).send(req);
                    result = res.getBody();
                    system.debug('result.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());
                    if(res.getStatusCode() == 200)
                    {
                        system.debug('returned status code :200');
                        bCheck = doLogic(bCheck,result);
                    }
                }
            }
            Catch(Exception ex)
            {
                system.debug(ex.getMessage());
            }
        }
        //************** find account and Contact and attach to bcheck record******************* 
        system.debug('starting-find account and Contact and attach to bcheck record');
        for(BackgroundCheck__c b:bCheckMap.values())
        {
            if( NULL != b.SuppliedEmail__c ) { emails.add(b.SuppliedEmail__c); }
        }

        List<Account> accs = [Select Id,Name,usr_email__c,usr_user_id__c From Account Where usr_email__c IN: emails];
        system.debug('accs.size()'+accs.size());
        //for(Account acc:accs)usrIds.add(acc.usr_user_id__c);
        // PBC 2017-10-30 Emergency Fix for caused by: System.LimitException: Too many query rows: 50001
        // added NULL exclusion condition
        for(Account acc:accs) {  if( NULL != acc.usr_user_id__c) { usrIds.add(acc.usr_user_id__c); } }
        List<Contact> cons = [Select Id,Email,AccountID,usr_user_id__c From Contact Where Email IN:emails OR usr_user_id__c IN: usrIds];
        for(Contact con:cons)contactAccountMap.put(con.AccountID,con);
        system.debug('cons.size()'+cons.size());
        //check for existing Accounts
        for(BackgroundCheck__c b:bCheckMap.values())
        {
            system.debug('b.CandidateName__c: '+b.CandidateName__c+', b.SuppliedEmail__c: '+b.SuppliedEmail__c);
            Boolean exist = false;
            for(Account acc:accs)
            {
                if(acc.usr_email__c == b.SuppliedEmail__c)
                {
                    b.Account__c = acc.Id;
                    allAccounts.add(acc);
                    exist = true;
                }
            }
            //create new Accoiunt if not exists
            if(!exist && b.CandidateName__c !=null)
            {
                system.debug('b.CandidateName__c: '+b.CandidateName__c+', b.SuppliedEmail__c: '+b.SuppliedEmail__c);
                String first = null;
                String last = null;
                String[] resultName = b.CandidateName__c.split(' ');
                system.debug('result:'+resultName.size());
                if(resultName.size()>0)first = resultName[0];
                if(resultName.size()>1 && resultName.size()==2)last = resultName[1];
                if(resultName.size()>2 && resultName.size()==3)last = resultName[2];
                Account acc = new Account();
                acc.Name = b.CandidateName__c;
                acc.usr_first_name__c = first ;
                acc.usr_last_name__c =last;
                acc.ContactCreatedInBcheck__c=true;
                acc.usr_email__c = b.SuppliedEmail__c;
                acc.LastSyncedWithDataPlatform__c = DateTime.now();
                system.debug('account does not exist-creating new account ');
                accListToInsert.add(acc);
                emailAccountMap.put(acc.usr_email__c,acc);
                allAccounts.add(acc);
            }
        }
        try{if(accListToInsert.size()>0)insert accListToInsert;}//insert new accounts
        catch(DmlException e){system.debug(e);}
        system.debug('accListToInsert.size()'+accListToInsert.size());

        /*for(Account ac:allAccounts)
        {
            Boolean exist = false;
            //check for existing contact
            for(Contact c:cons)if(c.Email == ac.usr_email__c || c.usr_user_id__c == ac.usr_user_id__c)exist = true;
            //create contact of not exists
            if(!exist)
            {
                String first = null;
                String last = null;
                String[] resultName = ac.Name.split(' ');
                system.debug('resultName:'+resultName.size());
                if(resultName.size()>0)first = resultName[0];
                if(resultName.size()>1 && resultName.size()==2)last = resultName[1];
                if(resultName.size()>2 && resultName.size()==3)last = resultName[2];
                Contact cc = new Contact(AccountId=ac.Id,RecordTypeId=cRtId,FirstName = first, LastName=last, Email=ac.usr_email__c,usr_user_id__c=ac.usr_user_id__c);
                if(cc.LastName == null && cc.FirstName != null)cc.LastName = cc.FirstName;
                if(cc.LastName != null)
                {
                    conSet.add(cc);
                    if(cc.usr_user_id__c != null)conIds.add(cc.usr_user_id__c);
                    contactAccountMap.put(cc.AccountID,cc);
                    system.debug('Contact does not exist-contact created ');
                }
            }
        }
        List<Contact> consToCheck = [Select Id,usr_user_id__c From Contact WHERE usr_user_id__c IN: conIDs];
        //inserting new contacts
        for(Contact c:conSet)
        {
            boolean exists = false;
            for(Contact cc:consToCheck)
            {
                if(cc.usr_user_id__c == c.usr_user_id__c)exists = true;
            }
            if(!exists)conListToInsert.add(c);
        }
        //insert the new contacts
        try{if(conListToInsert.size()>0)insert conListToInsert;}
        catch(DmlException e){system.debug(e);}*/

        cons = [Select Id,Email,AccountID,usr_user_id__c
        From Contact
        Where Email IN:emails OR usr_user_id__c IN: usrIds];

        for(Contact con:cons)
        {
            contactAccountMap.put(con.AccountID,con);
        }
        //setting the account on the bcheck
        for(BackgroundCheck__c b:bCheckMap.values())
        {
            if(emailAccountMap.containsKey(b.SuppliedEmail__c))
            {
                system.debug('setting account on bcheck');
                b.Account__c = emailAccountMap.get(b.SuppliedEmail__c).Id;
            }

            if(b.Account__c != null)
            {
                Contact c = contactAccountMap.get(b.Account__c);

                if(c != null)
                {
                    b.Contact__c = c.Id;
                }

                if (b.CandidateId__c != null)
                {
                    b.BackgroundCheckComplete__c = true;
                }
            }

            /*//setting contact on the bcheck
            for(Contact c:cons)
            {
                if(b.Account__c == c.AccountID)
                {
                    b.Contact__c = c.Id;
                    system.debug('Choosing 1 contact to add to bcheck');
                }
                if(b.Account__c != null && b.CandidateId__c != null)b.BackgroundCheckComplete__c = true;
            }
            //setting contact on the bcheck
            for(Contact c:conListToInsert)
            {
                if(b.Account__c == c.AccountID)
                {
                    b.Contact__c = c.Id;
                    system.debug('Choosing 1 contact to add to bcheck');
                }
                if(b.Account__c != null && b.CandidateId__c != null)b.BackgroundCheckComplete__c = true;
            }*/
        }
        system.debug(allAccounts);
        for(Case c:cases)//sync bcheck info to Case
        {
            if(bCheckMap.containsKey(c.BGCReportId__c))
            {
                c.BGCCharges__c = bCheckMap.get(c.BGCReportId__c).AdverseItems__c;
                if(c.BackgroundCheck__c == null)c.BackgroundCheck__c = bCheckMap.get(c.BGCReportId__c).Id;
                if(c.OwnerID == '00531000007OiRr')c.OwnerId= miQueue.Id;
                c.Category__c = 'Other';
                c.SubCategory__c = 'Background check (not clear)';
                c.RecordTypeId = miRecordTypeId;
                c.SuppliedEmail = bCheckMap.get(c.BGCReportId__c).SuppliedEmail__c;
                c.SuppliedName = bCheckMap.get(c.BGCReportId__c).CandidateName__c;
                c.AccountId = bCheckMap.get(c.BGCReportId__c).Account__c;
                c.ContactID = bCheckMap.get(c.BGCReportId__c).Contact__c;
                if(bCheckMap.get(c.BGCReportId__c).Contact__c != null && bCheckMap.get(c.BGCReportId__c).Account__c != null)bCheckMap.get(c.BGCReportId__c).BackgroundCheckComplete__c = true;
            }
        }
        try
        {
            update cases;
            system.debug('bcheck && cases updated');
            bCheckMap = syncContactToBcheck(bCheckMap,cases);
            update bCheckMap.values();
            system.debug('bcheck updated');
            syncCaseToBCheck(bCheckMap,cases);
        }
        catch(DmlException e){system.debug(e);}
    }

    public static BackgroundCheck__c doLogic(BackgroundCheck__c bCheck,String result)
    {
        system.debug('in- doLogic');
        String reportResult;
        String recordList;
        String chargeList;
        checkrReturn myReturn = (CheckrAPI.checkrReturn)JSON.deserialize(result, CheckrAPI.checkrReturn.class);
        system.debug('here');
        //*************** candidate *************
        if(myReturn.Candidate.middle_name == null)bCheck.CandidateName__c = myReturn.Candidate.first_name +' '+myReturn.Candidate.last_name;
        else bCheck.CandidateName__c = myReturn.Candidate.first_name +' '+myReturn.Candidate.middle_name+' '+myReturn.Candidate.last_name;
        bCheck.CandidateId__c = myReturn.Candidate.id;
        bCheck.SuppliedEmail__c = myReturn.Candidate.email;
        bCheck.DOB__c = myReturn.Candidate.dob;
        bCheck.EncodedId__c = myReturn.Candidate.custom_id;
        system.debug('bCheck.SuppliedEmail__c');
        //*************** adversitems *************

        bCheck = getAdverseItems(bCheck,bCheck.ReportId__c);
        system.debug('here');
        if(myReturn.sex_offender_search != null)
        {
            bCheck.SexOffenderSearch__c = reportHandler(myReturn.sex_offender_search.records,myReturn.sex_offender_search.created_at);
            bCheck.SexOffenderSearchId__c = myReturn.sex_offender_search.id;
            if(bCheck.SexOffenderSearch__c ==null || bCheck.SexOffenderSearch__c.length()<20)bCheck.SexOffenderSearch__c  = 'NO REPORT FOUND';
            system.debug('here');
        }
        system.debug('here');
        if(myReturn.national_criminal_search != null)
        {
            bCheck.NationalCriminalSearch__c = chargeHandler(myReturn.national_criminal_search.records,myReturn.national_criminal_search.created_at);
            bCheck.NationalCriminalSearchId__c = myReturn.national_criminal_search.id;
            if(bCheck.NationalCriminalSearch__c ==null || bCheck.NationalCriminalSearch__c.length()<50)bCheck.NationalCriminalSearch__c  = 'NO REPORT FOUND';
            system.debug('here');
        }
        system.debug('here');
        if(myReturn.global_watchlist_search != null)
        {

            bCheck.GlobalWatchlistSearch__c = chargeHandler(myReturn.global_watchlist_search.records,myReturn.global_watchlist_search.created_at);
            bCheck.GlobalWatchlistSearchId__c = myReturn.global_watchlist_search.id;
            if(bCheck.GlobalWatchlistSearch__c ==null || bCheck.GlobalWatchlistSearch__c.length()<50)bCheck.GlobalWatchlistSearch__c  = 'NO REPORT FOUND';
            system.debug('here');
        }
        system.debug('here');
        if(myReturn.county_criminal_searches.size()>0)
        {
            bCheck.CountyCriminalSearch__c = ' ';
            bCheck.CountyCriminalSearchId__c = ' ';
            for(County cs:myReturn.county_criminal_searches)
            {
                bCheck.CountyCriminalSearch__c += chargeHandler(cs.records,cs.created_at);
                if(cs.id != 'null')bCheck.CountyCriminalSearchId__c += cs.id+',';
            }
            if(bCheck.CountyCriminalSearch__c ==null || bCheck.CountyCriminalSearch__c.length()<50)bCheck.CountyCriminalSearch__c  = 'NO REPORT FOUND';
        }

        if(bCheck.StateCriminalSearch__c ==null || bCheck.StateCriminalSearch__c.length()<50)bCheck.StateCriminalSearch__c  = 'NO REPORT FOUND';
        system.debug('here');
        return bCheck;
    }

    webservice static BackgroundCheck__c getAdverseItems(BackgroundCheck__c bCheck,String Id)
    {
        system.debug('in adverseItems');
        List<BackgroundCheck__c> bChecksToUpdate = new List<BackgroundCheck__c>();
        HttpRequest req = getRequest();
        req.setEndpoint(baseUrl + 'reports/'+Id+'/adverse_items');
        system.debug('request: '+req);
        try
        {
            res = (new Http()).send(req);
            system.debug('res.getStatusCode(): '+res.getStatusCode()+', result: '+res+ 'res.body: '+res.getBody());
            if(res.getStatusCode() == 200)
            {
                bCheck.AdverseItems__c = null;
                checkrReturn myReturn = (CheckrAPI.checkrReturn)JSON.deserialize(res.getBody(), CheckrAPI.checkrReturn.class);
                if(myReturn.data.size()>0)
                {
                    for(Data s:myReturn.data)
                    {
                        if(!s.text.contains('DISPOSITION: DISMISSED'))
                        {
                            if(s.text != 'null')bCheck.AdverseItems__c += s.text+'\n';
                            bCheck.AdverseItems__c  = bCheck.AdverseItems__c .replace('nullCHARGE','CHARGE');
                            bCheck.AdverseItems__c  = bCheck.AdverseItems__c .replace('nullREGISTRATION','REGISTRATION');
                        }
                        else{bCheck.AdverseItems__c = 'NO CONVICTIONS';}
                    }
                }
                return bCheck;
            }
            return bCheck;
        } Catch(Exception ex){
            system.debug(ex.getMessage());
            returnMessage = ex.getMessage();
            return bCheck;
        }
    }
    public static String chargeHandler(List<Records> myReturn,DateTime createdAt)
    {
        system.debug('chargeHandler');
        String chargeList = ' ';
        String reportResult = 'Created Date: '+createdAt + ' ';
        for(Records record:myReturn)
        {
            system.debug('here');
            for(Charges charge:record.Charges)
            {
                system.debug('here');
                if(charge.disposition != 'DISMISSED' && charge.disposition != 'NOLLE PROSSE')
                {
                    chargeList += '       \nCHARGE: '+charge.charge+' * ';
                    chargelist += '  * DISPOSITION: '+charge.disposition+' * ';
                    chargelist += '  * Type: '+charge.charge_type+' * ';
                    chargelist += '  * Classification: '+charge.classification+' * ';
                    chargelist += '  * Disposition Date: '+charge.disposition_date+' * ';
                    charge.sentence = charge.sentence.remove('\n');
                    chargelist += '  * Sentence: '+charge.sentence+' * \n';
                }
                reportResult += 'CASE NUMBER:  '+record.case_number+'\n' + chargeList+'\n';

            }
        }

        return reportResult.replace('null','');
    }
    public static String reportHandler(List<Records> myReturn,DateTime createdAt)
    {
        system.debug('chargeHandler');
        String chargeList = ' ';
        String reportResult = ' ';
        for(Records record:myReturn)
        {
            if(record.registry != null)chargelist += 'State Registered: '+record.registry;
            if(record.registration_start != null)chargelist += ', Registration Start: '+record.registration_start;
            if(record.registration_end != null)chargelist += ', Registration End: '+record.registration_end;
            system.debug('chargeList: '+chargeList.length());

            reportResult +=chargeList+'\n';
        }

        return reportResult.replace('null','');
    }
    public static Map<String,BackgroundCheck__c> syncContactToBcheck(Map<String,BackgroundCheck__c> bChecksMap,List<Case> cases)
    {
        Map<Id,BackgroundCheck__c> bCheckMap=new Map<Id,BackgroundCheck__c>();
        Map<String,Account> accMap = new Map<String,Account>();
        List<Contact>consToInsert = new List<Contact>();
        List<Contact>allContacts = new List<Contact>();

        for(BackgroundCheck__c b:bChecksMap.values()) { if( NULL != b.Account__c ) { bCheckMap.put(b.Account__c,b); } }
        List<Account> accs = [Select Id,Name,usr_user_id__c,usr_first_name__c,usr_last_name__c,usr_email__c From Account WHERE Id IN:bCheckMap.keyset()];
        For(Account acc:accs)accMap.put(acc.Id,acc);
        system.debug('accs.size(): '+accs.size());
        List<Contact> cons = [Select Id,AccountId From Contact Where AccountId IN: accMap.keyset()];
        for(Account acc:accMap.values())
        {
            Boolean exists = false;
            for(contact c:cons)
            {
                allContacts.add(c);
                if(c.AccountId == acc.Id)
                {
                    exists = true;
                    if(bCheckMap.containsKey(acc.Id))
                    {
                        bCheckMap.get(acc.Id).Contact__c = c.Id;
                    }
                }
            }
            if(!exists)
            {
                String first = acc.usr_first_name__c;
                String last = acc.usr_last_name__c;
                if(last == null && first != null)last = first;
                if(last == null)last = acc.Name;
                Contact cc = new Contact(AccountId=acc.Id,RecordTypeId=cRtId,FirstName = first, LastName=last, Email=acc.usr_email__c,usr_user_id__c=acc.usr_user_id__c);
                allContacts.add(cc);
                consToInsert.add(cc);
            }
        }
        if(consToInsert.size()>0)insert consToInsert;
        for(Account acc:accMap.values())
        {
            for(contact c:consToInsert)
            {
                if(c.AccountId == acc.Id)
                {
                    if(bCheckMap.containsKey(acc.Id))
                    {
                        bCheckMap.get(acc.Id).Contact__c = c.Id;
                    }
                }
            }
        }
        for(Contact c:allContacts)
        {
            if(bCheckMap.containsKey(c.AccountId))
            {
                bCheckMap.get(c.AccountId).Contact__c = c.Id;
            }

        }
        return bChecksMap;
    }

    public static void syncCaseToBCheck(Map<String,BackgroundCheck__c> bChecksMap,List<Case> cases)
    {
        system.debug('Syncing cases');
        List<Case>casesToUpdate = new List<Case>();
        for(Case c:cases)
        {
            if(bChecksMap.containsKey(c.BGCReportId__c))
            {
                c.BGCCharges__c = bChecksMap.get(c.BGCReportId__c).AdverseItems__c;
                if(c.BackgroundCheck__c == null)c.BackgroundCheck__c = bChecksMap.get(c.BGCReportId__c).Id;
                if(c.OwnerId == '00531000007OiRr')c.OwnerId= miQueue.Id;
                c.Category__c = 'Other';
                c.SubCategory__c = 'Background check (not clear)';
                c.RecordTypeId = miRecordTypeId;
                c.SuppliedEmail = bChecksMap.get(c.BGCReportId__c).SuppliedEmail__c;
                c.SuppliedName = bChecksMap.get(c.BGCReportId__c).CandidateName__c;
                c.AccountId = bChecksMap.get(c.BGCReportId__c).Account__c;
                c.ContactID = bChecksMap.get(c.BGCReportId__c).Contact__c;
                casesToUpdate.add(c);
            }
        }
        try{if(casesToUpdate.size()>0)update casesToUpdate;}
        catch(Exception e){system.debug(e);}
    }

    public class checkrReturn
    {
        public String id;
        //public String object;
        public String uri;
        public DateTime created_at;
        //********** candidate *************
        public String first_name;
        public String last_name;
        public String middle_name;
        public String mother_maiden_name;
        public String dob;
        public String ssn;
        public String email;
        public String zipcode;
        public String phone;
        public String driver_license_state;
        public String driver_license_number;
        public Boolean copy_requested;
        public String previous_driver_license_state;
        public String previous_driver_license_number;
        public String custom_id;
        public String no_middle_name;
        public List<String> report_ids;
        public List<String> geo_ids;
        //******** report ************
        public String status;
        public DateTime completed_at;
        public DateTime upgraded_at;
        public Integer turnaround_time;
        public DateTime due_time;
        //public String package;
        public List<String> tags;
        public String adjudication;
        public String candidate_id;
        public List<String> county_criminal_search_ids;
        public List<String> document_ids;
        public String federal_criminal_search_id;
        public String global_watchlist_search_id;
        public String motor_vehicle_report_id;
        public String national_criminal_search_id;
        public List<String> personal_reference_verification_ids;
        public List<String> professional_reference_verification_ids;
        public String sex_offender_search_id;
        public String ssn_trace_id;
        public List<String> state_criminal_search_ids;
        public String terrorist_watchlist_search_id;
        public String facis_search_id;

        //************* adverse items *************
        public List<Data> data;
        public List<AdverseItems> adverse_items;
        public Integer count;
        public String report_id;
        public List<Records> records;
        public List<County> county_criminal_searches;
        public National national_criminal_search;
        public SexOffender sex_offender_search;
        public Candidate candidate;
        public GlobalSearch global_watchlist_search;
    }
    public class County
    {
        public String id;
        public String status;
        public String county;
        public String state;
        public DateTime created_at;
        public List<Records> Records;
    }
    public class SexOffender
    {
        public String id;
        public String status;
        public DateTime created_at;
        public List<Records> Records;
    }
    public class Candidate
    {
        public String id;
        public String first_name;
        public String last_name;
        public String middle_name;
        public String mother_maiden_name;
        public String dob;
        public String ssn;
        public String email;
        public String zipcode;
        public String phone;
        public String driver_license_state;
        public String driver_license_number;
        public Boolean copy_requested;
        public String previous_driver_license_state;
        public String previous_driver_license_number;
        public String custom_id;
        public String no_middle_name;
        public List<String> report_ids;
        public List<String> geo_ids;
    }
    public class National
    {
        public String id;
        public String status;
        public String county;
        public String state;
        public DateTime created_at;
        public List<Records> Records;
    }
    public class GlobalSearch
    {
        public String id;
        public String status;
        public String county;
        public String state;
        public DateTime created_at;
        public List<Records> Records;
    }
    public class Data{
        public String id;
        public String text;
    }
    public class AdverseItems
    {
        public String id;
        public String text;
    }
    public class Records
    {
        public String case_number;
        public Date file_date;
        public String arresting_agency;
        public String court_jurisdiction;
        public String court_of_record;
        public Date dob;
        public String full_name;
        public String registry;
        public DateTime registration_start;
        public DateTime registration_end;
        public List<Charges> charges;
    }
    public class Charges
    {
        public String charge;
        public String charge_type;
        public String classification;
        public String deposition;
        public String defendant;
        public String plaintiff;
        public String sentence;
        public String disposition;
        public String probation_status;
        public Date offense_date;
        public Date deposition_date;
        public Date arrest_date;
        public Date charge_date;
        public Date sentence_date;
        public Date disposition_date;
    }
}