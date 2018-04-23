/*
   Copyright (c) 2018 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
 1.0     2016-07-11  Paul Coleman     Created
 1.1     2016-07-20  Travis Oliver    Updated with exception handling
 1.2     2017-02-03  Paul Coleman     Add getService() function to parse 
                                      email addr from HTML
 1.3     2017-07-10  Paul Coleman     Mods for new HTML/Email Provider 
 =======+===========+=================+=================================================*/
 global class ProRequestsEmailService implements Messaging.InboundEmailHandler
 {
    
    global class TTServiceInfo
    {
        public String encodedServiceId;
        public String requestId;
        public String serviceUrl;
        public String parmJSON;
        public TTServiceInfo(String eId, String sUrl, Map<String,String> parmMap, String reqId)
        {
            this.encodedServiceId = eId;
            this.serviceUrl = sUrl;
            this.parmJSON = (null==parmMap)? '': JSON.serialize(parmMap);
            this.requestId = reqId;
        }
    }
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.Inboundenvelope envelope)
    {
        try
        {
            Id qId = [SELECT Id from Group WHERE Type='Queue' AND DeveloperName='ProAssistance' LIMIT 1].Id;
            Id rtId = Request__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Pro Assistance Request').getRecordTypeId();
            
            String rName = null!=email.subject? email.subject.trim().abbreviate(80) : ''; //name of Request__c record
            String headers = ''; //gather headers for field insert
            for(Messaging.InboundEmail.Header h: email.headers)
            {
                headers += h.name + ': ' + h.value + '\n';
            }
            
            //strip CSS style and img elements from message
            //testing with just the style strip...
            String htmlNoCss = email.htmlBody.replaceAll('<style([\\s\\S]+?)</style>', '<style></style>');
            String encodedServiceId;
            String requestId;
            String sendQuoteURL;
            String urlParms;
            TTServiceInfo serviceInfo = getServiceDetails(htmlNoCss);
            System.debug(LoggingLevel.FINEST,'PRO REQUEST PARSED SERVICE INFO: '+Json.serialize(serviceInfo));

            Id serviceId; //potential lookup field (Request__c->Service__c) if serviceInfo parsed OK
            try
            {
                encodedServiceId = serviceInfo.encodedServiceId;
                requestId = serviceInfo.requestId;
                sendQuoteURL = serviceInfo.serviceUrl;
                urlParms = serviceInfo.parmJSON;
                if( null != serviceInfo.encodedServiceId )
                {
                    // try to find Service__c for Pro by SOQL Lookup
                    serviceId = (null==encodedServiceId)? null: getServiceIdFromEncodedString(encodedServiceId);
                    // if not found by SOQL, try to find Service__c for Pro by email address SOSL and regex parse
                    serviceId = (null==serviceId)? getServiceIdFromEmailAddress(email.toAddresses[0], htmlNoCss): serviceId;
                }
                else
                {
                    // no encoded service id, try a SOSL find by email address and new regex parse
                    serviceId = (null==serviceId)? getServiceIdFromEmailAddress(email.toAddresses[0], htmlNoCss): serviceId;
                }
            //silent exception, if no service is found, skip it and move on to the Request__c insert
            }catch(Exception ex){ System.debug(LoggingLevel.ERROR, ex); }
            
            String fromAddr = email.fromAddress.left(80);
            String toAddr = email.toAddresses[0];
            String toAddrShort = toAddr.left(80);
            String plainTextEmail = getPlainText(htmlNoCss);
            Request__c newRequest = new Request__c(  EmailFromAddressText__c = email.fromAddress,
                                    EmailFromAddress__c=fromAddr,
                                    UrlParms__c=urlParms, 
                                    EmailHeaders__c=headers,
                                    EmailMessageId__c=email.messageId,
                                    EmailSubject__c=email.subject,
                                    EmailToAddressText__c=toAddr,
                                    EmailToAddress__c= toAddrShort,
                                    EmailSendQuoteLink__c=sendQuoteURL,
                                    EmailSendQuoteLinkPart1__c=sendQuoteURL,
                                    EncodedServiceID__c=encodedServiceId,
                                    EncodedRequestID__c=requestId,
                                    EmailTextBodyLong__c=plainTextEmail,
                                    Name=rName,
                                    OwnerId=qId, //ProAssistance Queue
                                    RecordTypeId=rtId,
                                    Service__c=serviceId);
            System.debug(LoggingLevel.FINEST,'NEW REQUEST__C RECORD: '+Json.serialize(newRequest));
            
            //set after log output to keep output minimal
            newRequest.EmailHTMLBody__c = htmlNoCss;
            newRequest.EmailHTMLBodyLong__c = htmlNoCss;
                                    
            insert newRequest;

        //Send email to admins if insert fails
        } catch(Exception ex){  CaseEmailHandler.sendAdminMail('ProRequestEmailService.handleInboundEmail() Processing Error', '<br/><b>Code Line #:</b>&nbsp;'+ex.getLineNumber()+'<br/><br/><b>Error Type:</b><br/>'+ ex.getTypeName() + '<br/><br/><b>Error Message:</b><br/>'+ ex.getMessage().abbreviate(255)+'<br/><br/><b>Stack Trace:</b><br/>'+ex.getStackTraceString().abbreviate(255)+'<br/><br/>' );}
        return null;
    }
    
    global static String getPlainText(String html) {
        //scrub out html and extra whitespace
        String scrubbed;
        try
        {
          scrubbed = html.replaceAll('</tr>','</tr>\n').replaceAll('<[^>]+>',' ').replace('     ',' ').replace('    ',' ').replace('  ',' ').replace('  ',' ').replace('\n ','\n').replace('\n\n','\n').replace('  ',' ').replace('  ',' ').replace('\n  ','\n').replace('\n ','\n').replace('\n\n','\n').replace('\n\n','\n').replace(' \n','\n').replace('\n\n','\n');
        } catch(Exception ex) { System.debug(LoggingLevel.ERROR, ex); /* not important enough to recover from ex */ }
        
        try
        { //separate try/catch to try an at least get a html-free version of the string, but neither scrubs interfere with Request__c processing
          scrubbed = EncodingUtil.urlDecode(scrubbed,'UTF-8');
        } catch(Exception ex) { System.debug(LoggingLevel.ERROR, ex); /* not important enough to recover from ex */ }
        return (null==scrubbed)? '': scrubbed;
    }
    
    //overloaded, lookup by regex parse if dom parse failed
    global static TTServiceInfo getServiceDetails(String htmlNoCss)
    {
        //try to parse out quote url from the html via regex
        TTServiceInfo result;
        if(null != htmlNoCss)
        {
            try
            {
                //get the url that contained the service_id query string parm
                String noCR = htmlNoCss.replaceAll('\n', '');
                String aRegex = '(?<=href=)"[\\s\\S][^"]+(?=")';
                Pattern aPattern = Pattern.compile(aRegex);
                Matcher matchedATags = aPattern.matcher(noCR);
                while (matchedATags.find())
                {
                    String href = matchedATags.group();
                    System.debug(LoggingLevel.FINEST,href);
                    if( href.contains('service_id=') && href.contains('request_id=') )
                    {
                        href = href.replaceAll('&amp;','&');
                        try
                        {
                            href = EncodingUtil.urlDecode(href,'UTF-8');
                        } catch(StringException decodeEx) {System.debug(LoggingLevel.ERROR, decodeEx);}
                        PageReference urlLink = new PageReference(href);
                        Map<String, String> parms = urlLink.getParameters();
                        String serviceId = parms.get('service_id');
                        String requestId = parms.get('request_id');
                        result = (String.isNotEmpty(serviceId))? new TTServiceInfo(serviceId,href,parms,requestId): new TTServiceInfo(null,href,parms,requestId);
                        break;
                    }
                }
            } catch(Exception ex) {
              System.debug(LoggingLevel.ERROR, ex);  
            }
        }
        return null==result? new TTServiceInfo(null,null,null,null): result;
    }
    
    global static Id getServiceIdFromEncodedString(String encodedServiceId)
    {
        Service__c[] services = [SELECT Id FROM Service__c WHERE EncodedServiceID__c=:encodedServiceId.left(100) LIMIT 1];
        return services.isEmpty()? null: services[0].Id;
    }
    
    global static Id getServiceIdFromEmailAddress(String toAddress, String htmlBody)
    {
        //declare lookup email address var
        String lookupAddr = '';
        if( null!=htmlBody )
        {
            //parse the email addr from html body
            //first remove all HTML tags
            String htmlText = htmlBody.replaceAll('<[^>]+>',' ').replace('  ',' ').replaceAll('\n', '');
            //split msg plain text on @yourpromail.com
            String[] parts = htmlText.split('\\@yourpromail.com');
            System.debug(LoggingLevel.FINEST,'# OF MSG PARTS AFTER @yourpromail.com SPLIT : ' + String.valueOf(parts.size()));
            if(1<parts.size() && -1!=htmlText.indexOf('To:'))
            {
                //parse email address from body -- 
                //there is more than one array element after the split (usually there will be two elements)
                //note: there could be multiple occourrences of the domain used to split
                String[] toStr = parts[(parts.size()-2)].split('To:');
                String mailbox = (2==toStr.size())? toStr[1].trim(): '';
                lookupAddr = (!''.equals(mailbox))? mailbox + '@yourpromail.com': '';
            }
            else if (-1!=htmlText.indexOf('To:') && htmlText.endsWith('@yourpromail.com'))
            {
                //the msg body actually ends in the email address, leaving only one array element after the split
                String[] toStr = parts[0].split('To:');
                String mailbox = (2==toStr.size())? toStr[1].trim(): '';
                lookupAddr = (!''.equals(mailbox))? mailbox + '@yourpromail.com': '';
            }
        }
        
        //validate that an email address was parsed successfully from htmlBody
        //Fallback: otherwise default to using the To: email address for service lookup
        if( ''.equals(lookupAddr) && null!=toAddress && toAddress.endsWith('@yourpromail.com') )
        {
            lookupAddr = toAddress;
        }

        System.debug(LoggingLevel.FINEST,'LOOKUP ADDRESS for Service__c SOSL: '+ lookupAddr );
        //added usr_email__c in case it is stored there. 
        Service__c[] services = String.isEmpty(lookupAddr)? new Service__c[0] : (Service__c[])[FIND :lookupAddr IN EMAIL FIELDS RETURNING Service__c(Id) LIMIT 1][0];
        return services.isEmpty()? null: services[0].Id;
    }

}