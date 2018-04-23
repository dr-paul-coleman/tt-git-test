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
Version      Date          Author            Description
========+============+=================+================================================
1.0       06-26-2017     Scott Purcell          Created-for MIINcidentBidCheckComponent
========+============+=================+===============================================*/
public class PicklistEntryWrapper{
    
    public PicklistEntryWrapper(){            
        }
   public String active {get;set;}
   public String defaultValue {get;set;}
   public String label {get;set;}
   public String value {get;set;}
   public String validFor {get;set;}
}