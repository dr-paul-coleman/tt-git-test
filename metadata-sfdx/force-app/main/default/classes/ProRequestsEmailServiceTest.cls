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
https://thumbtack--dev.cs17.my.salesforce.com
        
 Script File Name    : ProRequestsEmailService.cls  
 Script Type         : Standard Apex Email Service Class 
 Description         : Class to recieve inbound emails for ProRequests

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-07-11  Paul Coleman     Created
 1.1     2016-07-11  Travis Oliver    Update to email creation to get 100% code coverage
 1.2     2016-08-15  Travis Oliver    Update to service__c creation
 1.3     2016-08-24  Paul Coleman     Update to service__c creation to include ProAccount__c
 1.3     2017-02-03  Paul Coleman     Added Test method testMatchingHTMLAddress
 =======+===========+=================+=================================*/
@isTest 
private class ProRequestsEmailServiceTest {
    
    @isTest 
    static void testParsingUrl()
    {
        String emailAddr = 'chester@yourpromail.com';
        Account a = new Account(Name='Chester Pro',usr_user_id__c=123459999);
        insert a;
        Service__c s = new Service__c(ProAccount__c=a.Id,ProAssistantEmail__c=emailAddr,Name='Test Service');
        insert s;

        System.runAs( TestUtilities.USER_TACK_BOT ) {
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            email.fromAddress = 'do_not_reply@thumbtack.com';
            email.htmlBody = '<!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en" style="-moz-osx-font-smoothing: grayscale; -webkit-font-smoothing: antialiased;"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><meta name="viewport" content="width=device-width"/><title></title><style></style></head><body style="-moz-box-sizing: border-box; -moz-osx-font-smoothing: grayscale; -ms-text-size-adjust: 100%; -webkit-box-sizing: border-box; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: 100%; Margin: 0; box-sizing: border-box; color: #2f3033; font-family: Helvetica,Arial,sans-serif; font-size: 16px; font-weight: 400; line-height: 1.6; margin: 0; min-width: 100%; padding: 0; text-align: left; width: 100% !important;"><div><a href="https://www.thumbtack.com/dispatcher/profile/jobs?service_id=zZosSsEZAuogUg&category_id=nV8DGI4%3AdEUXtQ&auto-popup-tutorial=true&utm_source=user_generated&utm_medium=email&utm_campaign=invite.html&utm_content=20180222&source=email&pa_inv_exp1=true">Send Quote</span></a></div><div><a href="https://www.thumbtack.com/dispatcher/invite?request_id=9c5es0ti&service_id=zZosSsEZAuogUg&bid_source=invite_email&utm_source=user_generated&utm_medium=email&utm_campaign=invite.html&utm_content=20180222&source=email">Send REQUEST</span></a></div></body></html>';
            email.subject = 'Testing Pro Request Service';
            email.toAddresses = new String[]{emailAddr};
            Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
            email.headers=new Messaging.InboundEmail.Header[1];
            hditem.name='Date';
            hditem.value='Wed, 20 Apr 2016 15:46:00 -0700';
            email.headers[0]=hditem;
                                    
            Test.startTest(); 
                Test.setFixedSearchResults(new Id[]{s.Id});
                ProRequestsEmailService svc = new ProRequestsEmailService();
                svc.handleInboundEmail(email,null);
            Test.stopTest();

            Request__c[] r = [SELECT Id, EncodedRequestID__c, EncodedServiceID__c FROM Request__c LIMIT 1];
            System.assertEquals( false, r.isEmpty() ,'No Request__c record written from inbound Email');
            System.assertEquals( '9c5es0ti', r[0].EncodedRequestID__c ,'EncodedRequestID__c is NOT correct');
            System.assertEquals( 'zZosSsEZAuogUg', r[0].EncodedServiceID__c ,'EncodedServiceID__c is NOT correct');

        }
    }
    
    @isTest 
    static void testMatchingHTMLAddress()
    {
        String emailAddr = 'chester@yourpromail.com';
        Account a = new Account(Name='Chester Pro',usr_user_id__c=123459999);
        insert a;
        Service__c s = new Service__c(ProAccount__c=a.Id,ProAssistantEmail__c=emailAddr,Name='Test Service');
        insert s;
        
        System.runAs( TestUtilities.USER_TACK_BOT ) {
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            email.fromAddress = 'do_not_reply@thumbtack.com';
            email.htmlBody = '<div>this is a test of To: '+emailAddr+' and here is the plain text.<a href="https://www.thumbtack.com/dispatcher/invite"></a></div>';
            email.subject = 'Testing Pro Request Service';
            email.toAddresses = new String[]{'not_chester@bogus.email.com'};
            Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header(); 
            email.headers=new Messaging.InboundEmail.Header[1]; 
            hditem.name='Date'; 
            hditem.value='Wed, 20 Apr 2016 15:46:00 -0700'; 
            email.headers[0]=hditem;
                                    
            Test.startTest(); 
                Test.setFixedSearchResults(new Id[]{s.Id});
                ProRequestsEmailService svc = new ProRequestsEmailService();
                svc.handleInboundEmail(email,null);
                email.htmlBody = 'To: '+emailAddr;    
                svc.handleInboundEmail(email,null);
            Test.stopTest();

            //System.assert(0!=[SELECT count() FROM Request__c],'No Request__c record written from inbound Email');

        }
    }
}