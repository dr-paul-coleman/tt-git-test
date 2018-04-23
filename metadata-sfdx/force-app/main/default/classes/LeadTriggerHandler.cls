/*
 Copyright (c) 2016 Thumbtack. All rights reserved.

 Change List:                                                               
 ------------
 Version    Date     Author            Description                          
 =======+===========+=================+==================================================
 1.0     2018-02-05  Meena Pisupati 	Created to handle Lead conversion to enrollments
										and Insert/Update Routing Profile for Phone Routing
 1.1     2018-04-01  Meena Pisupati 	Update to populate Account Manager on enrollment
										and fix for query error by adding size
 =======+===========+=================+==================================================*/
public without sharing class LeadTriggerHandler extends ThumbtackTriggerHandlerBase
{
    //Record type variables
    public static final Id LEAD_MA_RECORD_TYPE_ID = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Account Lead').getRecordTypeId();
    public static final	Id PRODUCT_ENABLED_RECORD_TYPE_ID = Enrollment__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Product Enabled').getRecordTypeId();
    public static final Id SMART_ROUTING_RECORD_TYPE_ID = RoutingProfile__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Smart Routing').getRecordTypeId();              

    //Recusion prevention
    private static Boolean isInAfterUpdateProcessing = false;
    private static Boolean isInAfterInsertProcessing = false;
    
    //Call doAfter update method and check recursion
    public override void onAfterUpdate(ThumbtackTriggerContext ctx)
    {
        if (!isInAfterUpdateProcessing)
        {
            isInAfterUpdateProcessing = true;  
            try
            {
                this.doAfterUpdate((Lead[])ctx.newRecords, (Map<Id, Lead>)ctx.oldRecordsMap);  
            }    
            finally
            {
                isInAfterUpdateProcessing = false;
            }    
        }
    }

    public override void onAfterInsert(ThumbtackTriggerContext ctx)
    {
        if (!isInAfterInsertProcessing)
        {

            if( Test.isRunningTest() ) { System.debug(LoggingLevel.FINEST, 'LEAD RECORDS AFTER INSERTED: ' + JSON.serialize((Lead[])ctx.newRecords)); }
            isInAfterInsertProcessing = true;
            try
            {
                this.createRoutingProfile((Lead[])ctx.newRecords, FALSE);
            }
            finally
            {
                isInAfterInsertProcessing = false;
            }
        }
    }

    //check if sales rep is updated and call createRoutingProfile method if so
    //check if user id is updated and call createEnrollment method if so
    private void doAfterUpdate(Lead[] triggerNew, Map<Id, Lead> triggerOldMap)
    {
        Lead[] newLeadUpdateRP = new Lead[0];
        Lead[] newLeadCreateEnrollment = new Lead[0];
        Map<Id, Lead> oldLeadMapCreateEnrollment = new Map<Id, Lead>();

        for (Lead ld : triggerNew)
        { 
            Lead oldLd = triggerOldMap.get(ld.id); 
            //check if salesrep field is updated
            if(oldLd.SalesRep__c != ld.SalesRep__c)
            {
               newLeadUpdateRP.add(ld);
            }
            //check if user id field is updated and add the old/new leads to a list and map
            if(NULL == ld.Enrollment__c && LEAD_MA_RECORD_TYPE_ID == ld.RecordTypeId)
            {
                String newUserId = (NULL == ld.UserID__c)?'':string.valueOf(ld.UserID__c);
                String oldUserId = (NULL == oldLd.UserID__c)?'':string.valueOf(oldLd.UserID__c);

                if(String.isNotEmpty(newUserId) && String.isEmpty(oldUserId))
                {
                    newLeadCreateEnrollment.add(ld);
                    oldLeadMapCreateEnrollment.put(oldLd.Id, oldLd);
                }
            }                      
        }
        //call createRoutingProfile if only sales rep is updated
        if(!newLeadUpdateRP.isEmpty())
        {
            this.createRoutingProfile(newLeadUpdateRP, TRUE);
        }
        //call createEnrollment if only user id is updated
        if(!oldLeadMapCreateEnrollment.isEmpty() && !newLeadCreateEnrollment.isEmpty())
        {
            this.createEnrollment(newLeadCreateEnrollment,oldLeadMapCreateEnrollment);
        }
    }
    
    //Checks existing enrollments, else creates a new Lead Acquisition enrollment 
    private void createEnrollment(Lead[] triggerNew, Map<Id, Lead> triggerOldMap)
    {        
        Enrollment__c[] enrollInsert = new Enrollment__c[0];
        Map<String,Id> enrollExistMap = new Map<String,Id>();
        Lead[] updatedLead = new Lead[0];
        Lead[] newEnrollLead = new Lead[0];
        String[] enrollmentIds = new String[0];
        Map<Id,Id> leadEnroll = new Map<Id,Id>();
        Id[] leadIds = new Id[0];
        Map<Id,RoutingProfile__c> leadRoutingProfiles= new Map<Id,RoutingProfile__c>(); 
        String errorMessage = '';
        RoutingProfile__c[] rpUpdate = new RoutingProfile__c[0];     
                
        for(Lead l: triggerNew){
            if(NULL != l.UserID__c)
            {
                enrollmentIds.add(string.valueOf(l.UserID__c)+'-Managed account');
                enrollmentIds.add(string.valueOf(l.UserID__c)+'-Lead acquisition');
                leadIds.add(l.Id);
            }
        }
        
        //Checking for existing Routing profiles
        if(!leadIds.isEmpty())
        {
            for(RoutingProfile__c rp: [SELECT Id,Lead__c FROM RoutingProfile__c WHERE Lead__c IN :leadIds])
            {
                leadRoutingProfiles.put(rp.Lead__c,rp);              
            } 
        }
                
        //Check for existing enrollments
        //Capture outreach type at the top level and use it here -done
        if(!enrollmentIds.isEmpty()){
            System.debug(LoggingLevel.DEBUG, 'UserIds in leadtrigger: ' + enrollmentIds);
            for(Enrollment__c e: [SELECT Id,user_id__c,outreach_type__c FROM Enrollment__c WHERE enrollment_id__c IN :enrollmentIds LIMIT :enrollmentIds.size()])
            {
                enrollExistMap.put(e.user_id__c, e.Id);             
            }
        }
        //Process the enrollment creation process
        for (Lead ld : triggerNew)
        {            
            Lead oldLd = triggerOldMap.get(ld.id);
            String newUserId = (NULL == ld.UserID__c)?'':string.valueOf(ld.UserID__c);
            String oldUserId = (NULL == oldLd.UserID__c)?'':string.valueOf(oldLd.UserID__c);
            if(String.isNotEmpty(newUserId) && String.isEmpty(oldUserId) || enrollExistMap.containsKey(String.valueOf(ld.UserID__c)))
            {                     
                if(!enrollExistMap.containsKey(String.valueOf(ld.UserID__c)))
                {                                       
                    Enrollment__c enroll = new Enrollment__c(); 
                    enroll.user_id__c = String.valueOf(ld.UserID__c);
                    enroll.Name = ld.Company+' - Lead Acquisition';
                    enroll.enrollment_id__c = ld.UserID__c+'-Lead acquisition';
                    enroll.outreach_type__c = 'lead_acquisition';
                    enroll.outreach_group__c = '0_MA';
                    enroll.Email__c = ld.Email;
                    enroll.FirstName__c = ld.FirstName;
                    enroll.LastName__c = ld.LastName;
                    enroll.BusinessName__c = ld.Company;
                    enroll.Phone__c = ld.Phone;
                    enroll.FunnelStep__c = 'Pre-Onboarding'; 
                    if(NULL != ld.AccountManager__c)
                    {
                        enroll.AccountManager__c = ld.AccountManager__c;
                    }
                    enrollInsert.add(enroll);
                    newEnrollLead.add(ld);                                               
                }
                else
                {
                    //Update leads with existing enrollments
                    Lead ldClone = ld.clone(true);
                    ldClone.enrollment__c = enrollExistMap.get(String.valueOf(ldClone.UserID__c));                         
                    updatedLead.add(ldClone);
                    leadEnroll.put(ldClone.enrollment__c,ldClone.Id);
                }                            
            }                 	            
        }        
        //Insert new enrollments and update their corresponding leads
        if(!enrollInsert.isEmpty())
        {      
            for (Database.saveResult result : Database.insert(enrollInsert, false))
            {
                if (!result.isSuccess()) 
                { 
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'LeadTriggerHandler.createEnrollment');
                errorMessage = ''; 
            }
            //Link the newly inserted enrollment to the lead
            for(Enrollment__c e: enrollInsert) 
            {
                for( Lead ld: newEnrollLead) 
                {
                    if(NULL == ld.Enrollment__c && String.valueOf(ld.UserID__c) == e.user_id__c)
                    {
                        Lead leadClone = ld.clone(true);
                        leadClone.enrollment__c =e.Id;                        
                        updatedLead.add(leadClone);  
                        leadEnroll.put(e.Id,leadClone.Id);
                        break;
                    }
                }                
            }
        }
        
        if(!updatedLead.isEmpty())
        {
            for (Database.saveResult result : Database.update(updatedLead, false))
            {
                if (!result.isSuccess()) 
                { 
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'LeadTriggerHandler.createEnrollment');
                errorMessage = '';
            }
        }

       	RoutingProfile__c[] rpInfo = [SELECT Id,Enrollment__c, Account__c, Lead__c FROM RoutingProfile__c WHERE Id IN :leadRoutingProfiles.values()] ;

        for(Enrollment__c e: [SELECT Id,user_id__c,FunnelStep__c,Account__c,Account__r.AccountManager__c, Account__r.AccountManager__r.Email FROM Enrollment__c WHERE Id IN :leadEnroll.keySet()])
        {        
            Id leadId = leadEnroll.get(e.Id);
            if(NULL != leadId)
            {
                for(RoutingProfile__c rp: rpInfo)  
                {
                    if(rp.Lead__c == leadId)
                    {
                        rp.Enrollment__c =e.Id;
                        rp.Account__c = e.Account__c;   
                        rp.ThumbtackID__c =Decimal.valueOf(e.user_id__c); 
                        if(String.isNotEmpty(e.Account__r.AccountManager__c) && 'Pre-Onboarding'.equals(e.FunnelStep__c))
                        {
                            rp.Sales__c = FALSE;
                            rp.RoutetoAgent__c = e.Account__r.AccountManager__r.Email;                            
                        }
                        else if(String.isEmpty(e.Account__r.AccountManager__c))
                        {
                            rp.RoutetoAgent__c = NULL;
                            rp.Enterprise__c = TRUE;
                            rp.Sales__c = FALSE;
                        }
                        rpUpdate.add(rp);
                        break;
                    }  
                }
            }
        }

        if(!rpUpdate.isEmpty())
        {
            for (Database.saveResult result : Database.update(rpUpdate, false))
            {
                if (!result.isSuccess()) 
                { 
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'LeadTriggerHandler.createRoutingProfile');
                errorMessage = '';
            }           
        }       	        
    }
    
    //Create Routing profile if it is insert and update RP if it is an update
    private void createRoutingProfile(Lead[] triggerNew, Boolean isUpdate)
    {
        Map<String,RoutingProfile__c> existingRoutingProfiles= new Map<String,RoutingProfile__c>(); 
       	Map<Id,RoutingProfile__c> updateRPOnLead = new Map<Id,RoutingProfile__c>();
        Id[] leadIds = new Id[0];
        RoutingProfile__c[] updateRPs = new RoutingProfile__c[0]; 
        String errorMessage = '';
        String phoneSOSLString = '';
        String phoneFieldForQuery = '';
        String[] leadEmails = new String[0];
        List<String> phoneFields = new List<String>{'Phone__c','Phone2__c','Phone3__c','Phone4__c','Phone5__c','Phone6__c','Phone7__c','Phone8__c','Phone9__c','Phone10__c'};
	
        //Get phone numbers of the leads and convert to a SOSL string
        for(Lead l: triggerNew)
        {    
            if(NULL != l.Phone && '' != l.Phone)
            {        	           
                phoneSOSLString += ( ''.equals(phoneSOSLString) )? l.Phone:( ( phoneSOSLString.length() + l.Phone.length()) < 19985 ? (' OR ' + phoneSOSLString) : '' ); //20k max SOSL limit
            }else if(NULL != l.Email && NULL == l.Phone && '' == l.Phone)
            {
                leadEmails.add(l.Email);
            }else if(isUpdate && NULL != l.Id)
            {
                leadIds.add(l.Id);
            }
        }
        
        //Form a string of phone field API names for query 
        for(String phAPI: phoneFields)
        {
            phoneFieldForQuery+=phAPI+',';
        }
        
        if(NULL != phoneSOSLString && '' != phoneSOSLString)
        {
            String searchQuery = 'FIND \'' + phoneSOSLString + '\' IN PHONE FIELDS RETURNING RoutingProfile__c('+phoneFieldForQuery+'Id)';
            List<RoutingProfile__c[]> soslResults = search.query(searchQuery);
            
            //Checking for existing Routing profiles
            for(RoutingProfile__c rp: soslResults[0])
            {
                for(String ph: phoneFields)
                {
                    Boolean matchBreak = false;
                    String valueOfPhoneField = String.valueOf(rp.get(ph));
                    if(NULL != valueOfPhoneField)
                    {
                        for(Lead l: triggerNew)
                        {
                            String leadPhone = l.Phone.replaceAll('[^0-9]','');                        
                            valueofPhoneField = valueofPhoneField.replaceAll('[^0-9]','');
                            if(NULL != leadPhone && valueofPhoneField.equals(leadPhone))
                            {
                                existingRoutingProfiles.put(valueofPhoneField,rp);  
                                matchbreak = true;
                                break;
                            }   
                        }  
                        if(matchbreak)
                        {
                            break;
                        }
                    }
                }
            }
        }else if(!leadEmails.isEmpty())
        {
            for(RoutingProfile__c rp: [SELECT Id, Email__c FROM RoutingProfile__c WHERE Email__c IN :leadEmails])
            {
                existingRoutingProfiles.put(String.valueOf(rp.Email__c),rp);
            } 
        }else
        {
            for(RoutingProfile__c rp: [SELECT Id,Lead__c FROM RoutingProfile__c WHERE Lead__c IN :leadIds])
            {
                existingRoutingProfiles.put(String.valueOf(rp.Lead__c),rp);
            } 
        }
        for (Lead ld : triggerNew)
        {             
            //If the method is not an update (but an insert)
            if (!isUpdate)
            {    
                if(NULL != ld.Phone)
                {
                   	String leadPhone = (''.equals(ld.Phone))?'':ld.Phone.replaceAll('[^0-9]','');   
                    if(!existingRoutingProfiles.containsKey(leadPhone))
                    {
                        leadIds.add(ld.Id);
                    }
                    else
                    {
                        Lead ldClone = ld.clone(true);
                        ldClone.Phone = ldClone.Phone.replaceAll('[^0-9]',''); 
                        updateRPOnLead.put(ldClone.Id, existingRoutingProfiles.get(ldClone.Phone));                 
                    } 
                }else if(NULL != ld.Email)
                {
                    if(!existingRoutingProfiles.containsKey(ld.Email))
                    {
                        leadIds.add(ld.Id);                        
                    }
                    else
                    {
                        Lead ldClone = ld.clone(true);
                        updateRPOnLead.put(ldClone.Id, existingRoutingProfiles.get(ldClone.Email));                 
                    } 
                }else
                {
                    leadIds.add(ld.Id);
                }
            }
            else
            {
                Lead ldClone = ld.clone(true);
                if(NULL != ldClone.Phone)
                {
                    ldClone.Phone = ldClone.Phone.replaceAll('[^0-9]',''); 
                    updateRPOnLead.put(ldClone.Id, existingRoutingProfiles.get(ldClone.Phone)); 
                }
                else if(NULL != ldClone.Email)
                {
                  	updateRPOnLead.put(ldClone.Id, existingRoutingProfiles.get(ldClone.Email)); 
                }
                else if(NULL != ldClone.Id && existingRoutingProfiles.containsKey(ldClone.Id))
                {
                    updateRPOnLead.put(ldClone.Id, existingRoutingProfiles.get(ldClone.Id));
                }
            }
        }
        
        //call method that creates new routing profile
        if(!leadIds.isEmpty())
        {
            this.getRoutingProfileRecord( leadIds, NULL, SMART_ROUTING_RECORD_TYPE_ID);
        }
        
        //if there is an existing RP, update it with Lead lookup value and set routing on RP
        if(!updateRPOnLead.isEmpty())
        {    
            for(Lead ld: [SELECT Id,SalesRep__c, SalesRep__r.Email FROM Lead WHERE Id IN :updateRPOnLead.keySet()])
            { 
                //Lead ldClone = ld.clone(true);
                RoutingProfile__c rp = updateRPOnLead.get(ld.Id); //(ldClone.Id);
                rp.Lead__c = ld.Id; //ldClone.Id;
                if (String.isNotEmpty(ld.SalesRep__c)) //(ldClone.SalesRep__c))
                {
                    rp.RoutetoAgent__c = ld.SalesRep__r.Email; //ldClone.SalesRep__r.Email;
                    rp.Enterprise__c = FALSE;
                }

                //if sales rep doesnt exist on lead, check 'Sales' to route to sales team
                else {
                    rp.Sales__c = TRUE;
                    rp.Enterprise__c = FALSE;
                    rp.RoutetoAgent__c = NULL;
                }
                updateRps.add(rp);

            }
        }       
        
        if(!updateRps.isEmpty())
        {
            for (Database.saveResult result : Database.update(updateRps, false))
            {
                if (!result.isSuccess()) 
                { 
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'LeadTriggerHandler.updateRoutingProfile');
                errorMessage = '';
            }             
        }
    } 

    //Store the lead ids, check if not empty, create a new RP and add it to queueable for insert
    private void getRoutingProfileRecord(Id[] newLd, Lead oldLd, Id recordTypeId)
    {        
        RoutingProfile__c[] newRoutingProfileRecords = new RoutingProfile__c[0];
        String errorMessage = '';
        for(Lead ld: [SELECT Id, Email, Phone, SalesRep__c, SalesRep__r.Email FROM Lead WHERE Id IN :newLd])
        {
            RoutingProfile__c rp = new RoutingProfile__c(
                RecordtypeId = recordTypeId,
                Name = 'Routing Profile for '+ld.Email,
                Email__c = ld.Email,
                Phone__c = ld.Phone,
                Lead__c = ld.Id //ldClone.Id      
            );
            if(String.isNotEmpty(ld.SalesRep__c))
            {
                rp.RoutetoAgent__c = ld.SalesRep__r.Email;
            }
            else
            {
                rp.Sales__c = TRUE;
            }
            newRoutingProfileRecords.add(rp);
        }
        
        if (!newRoutingProfileRecords.isEmpty()) 
        {
            for (Database.saveResult result : Database.insert(newRoutingProfileRecords, false))
            {
                if (!result.isSuccess()) 
                { 
                    errorMessage+=result.getErrors()[0].getMessage()+'</br>';
                }
            }
            if(String.isNotEmpty(errorMessage))
            {
                TackBotUtility.postTackLogErrorMessage(errorMessage,'LeadTriggerHandler.getRoutingProfileRecord');
                errorMessage = '';
            }           
        }       
    } 

}