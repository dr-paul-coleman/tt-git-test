/* +=====================================================================+    
 |                       Copyright (c) 2017 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : HCSiteMapControllerTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : Tests for HCSiteMapController

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-02-16  Ben Knight        Created 
 =======+===========+=================+=================================*/

@isTest(seeAllData=true)
global with sharing class HCSiteMapControllerTest {
    @isTest
    private static void testHCSiteMap() {
        System.runAs([SELECT Id FROM User WHERE IsActive=true AND Profile.Name='System Administrator' LIMIT 1][0]) {
            HCSiteMapController siteMapController = new HCSiteMapController();
            system.assert(siteMapController.SiteMap != null);
        }
    } 
}