/* +=====================================================================+    
 |                       Copyright (c) 2016 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : ReviewTrigger.cls  
 Script Type         : Standard Apex Trigger Class 
 Description         : ReviewTrigger Trigger Events Processing

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2016-06-08  Travis Oliver     Created (w/Paul Coleman)
 =======+===========+=================+=================================*/
trigger ReviewTrigger on Review__c (before insert, before update) {
ReviewTriggerHandler.actionNeededOutcomeStr();
}