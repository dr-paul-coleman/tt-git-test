/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/23/17      pcoleman           Created to consolidate Sys Admin (Tackbot) related
                                             Utility functions, such as sending Exception Emails etc
1.1       11/22/17      pcoleman           Over ride tackbot email distro in favor of select list by Label
                                             Also added the TackLog__c custom object records
1.2       2017-12-14  Mendel Guillaume     Added method to retrieve tackbot user
========+============+=================+===============================================*/
public without sharing class TackBotUtility
{

    /**
    * @author Paul Coleman
    * @date 2017-11-12
    * @deprecated
    * @description A function to capture and send via email any Apex exceptions caught within code
    *           segments (and overtly utilized by developers).
    * @param Exception The exception object caught by the Apex code.
    * @param String The context of the execution in the form of 'ClassName.functionName'.
    */
    public static Messaging.SendEmailResult[] sendExceptionEmail(Exception ex, String contextClassFunction)
    {
        System.debug( LoggingLevel.ERROR, ex );
        return TackBotUtility.sendAdminMail( ( null == contextClassFunction? 'Functional': contextClassFunction ) + ' Processing Error', '<br/><b>Code Line #:</b>&nbsp;'+ex.getLineNumber()+'<br/><br/><b>Error Type:</b><br/>'+ ex.getTypeName() + '<br/><br/><b>Error Message:</b><br/>'+ ex.getMessage().abbreviate(1024)+'<br/><br/><b>Stack Trace:</b><br/>'+ex.getStackTraceString().abbreviate(1024)+'<br/><br/>' );
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-12
    * @deprecated
    * @description Originally did the same thing as sendDevMail but to the tackbot user's email address
    *       which sent the emails to systems@ (too many unconcerned people). Method was refactored
    *       to call the new sendDevMail function until an alternative strategy could be defined.
    * @param String The subject of the email.
    * @param String The html content of the email to be sent.
    */
    public static Messaging.SendEmailResult[] sendAdminMail( String subject, String bodyHTML )
    {
        // temporary override of sys admin email notices (was going to a broader group)
        return TackBotUtility.sendDevMail( subject, bodyHTML );
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-12
    * @description Posts a TackLog__c record for specific exceptions that are caught thoughout the Apex codebase
    *   and sends an email notification if the custom label DevEmailDistroList specifies any address(s) -- space-delimited.
    * @param String The subject of the email.
    * @param String The html content of the email to be sent.
    */
    public static Messaging.SendEmailResult[] sendDevMail( String subject, String bodyHTML )
    {

        TackBotUtility.postTackLog( new TackLog__c( Description__c = bodyHTML.abbreviate(32765) ) );

        Messaging.SendEmailResult[] result;
        String toAddressString = Label.DevEmailDistroList;
        if( !'none'.equals(toAddressString.toLowerCase() ) )
        {
            String[] toAddresses = toAddressString.split(' ');
            if ( Test.isRunningTest() ) { System.debug( LoggingLevel.INFO, 'DEV EMAIL DISTRO LIST: ' + toAddresses ); }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses( toAddresses ) ;
            mail.setSubject( subject );

            String body = '<html lang="en"><body>' + bodyHTML + '</body></html>';
            mail.setHtmlBody( body );
            try
            {
                if( !Test.isRunningTest() ) { Messaging.reserveSingleEmailCapacity(toAddresses.size()); }
                result = ( Test.isRunningTest() ) ? new Messaging.SendEmailResult[0] : Messaging.sendEmail( new Messaging.SingleEmailMessage[] {mail} ); //don't attempt to send email during test runs
            }
            catch ( Exception ex )
            {
                // skip errors where email is not possible, such as in a sandbox, else re-throw exception
                TackBotUtility.postTackLogException( ex, 'TackBotUtility.sendDevMail' );
            }
        }
        return result;
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-12
    * @description Loads a TackLog__c record for specific exceptions that are caught within the Apex codebase.
    *               contextClassFunction parm should be of format Classname.functionName
    */
    public static void postTackLogException(Exception ex, String contextClassFunction)
    {
        String[] classFunction = ( NULL == contextClassFunction )? new String[0] : contextClassFunction.split('\\.');
        TackLog__c log = new TackLog__c();
        log.ClassContext__c =  ( classFunction.isEmpty() ) ? NULL : classFunction[0];
        log.ClassFunction__c = ( classFunction.size() > 1 ) ? classFunction[1] : NULL;
        log.Description__c = ('<html lang="en"><body>Processing Error<br/><br/><b>Code Line #:</b>&nbsp;'+ex.getLineNumber()+'<br/><br/><b>Error Type:</b><br/>'+ ex.getTypeName() + '<br/><br/><b>Error Message:</b><br/>'+ ex.getMessage().abbreviate(2048)+'</body></html>').abbreviate(32765);
        log.StackTrace__c = ex.getStackTraceString().abbreviate(131069);
        TackBotUtility.postTackLog( log );
    }

    /**
    * @author Paul Coleman
    * @date 2017-11-12
    * @description Posts a TackLog__c record for specific exceptions that are caught thoughout the Apex codebase.
    */
    public static void postTackLog(TackLog__c log) {
        System.debug( LoggingLevel.INFO, 'TackLog DML RESULT' + JSON.serialize( Database.insert( log ) ) );
    }

    /**
    * @author Meena Pisupati
    * @date 2018-02-22
    * @description Tracks Error Message
    * @param String This is the text of the error message.
    * @param String Expected value is [ClassName.MethodName].
    */
    public static void postTackLogErrorMessage(String errorMessage, String contextClassFunction)
    {

        String[] classFunction = ( NULL == contextClassFunction )? new String[0] : contextClassFunction.split('\\.');
        TackLog__c log = new TackLog__c();
        log.ClassContext__c =  ( classFunction.isEmpty() ) ? NULL : classFunction[0];
        log.ClassFunction__c = ( classFunction.size() > 1 ) ? classFunction[1] : NULL;
        log.Description__c = ('<html lang="en"><body>Processing Error</br><br/><b>Error Message:</b><br/>'+ errorMessage.abbreviate(2048)+'</body></html>').abbreviate(32765);
        TackBotUtility.postTackLog( log );
    }

    /**
    * @author Mendel Guillaume
    * @date 2017-12-12
    * @description Fetches the ubiquitous tackbot User for various needs including TestUtilities RunAs() usages.
    * @return User The TackBot System Administrator user.
    */
    public static User getTackBotUser()
    {
        return [SELECT Id FROM User WHERE Alias = 'tackbot' AND IsActive = true LIMIT 1];
    } 
}