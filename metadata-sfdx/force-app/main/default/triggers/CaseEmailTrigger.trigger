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
 Script File Name    : CaseEmailTrigger.cls  
 Script Type         : Standard Apex Trigger Class 
 Description         : Methods for processing Case->EmailMessage records

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-04-15  Paul Coleman      Created 
 1.1     2016-09-30  Paul Coleman      added doDupedCaseDetection and isolation try/catch
 =======+===========+=================+=================================*/
 trigger CaseEmailTrigger on EmailMessage (after insert) 
 {
    if(Trigger.isAfter && Trigger.isInsert) 
    {
    	try{CaseEmailHandler.doCheckr(Trigger.New);}catch(Exception e){System.debug(LoggingLevel.ERROR,e);}
        try{CaseEmailHandler.doUnmonitoredEmailScrub(Trigger.New);}catch(Exception e){System.debug(LoggingLevel.ERROR,e);}
        try{CaseEmailHandler.doDupedCaseDetection(Trigger.NewMap);}catch(Exception e){System.debug(LoggingLevel.ERROR,e);}
        
    }

}