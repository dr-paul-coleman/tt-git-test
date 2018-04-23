/* +=====================================================================+    
 |                       Copyright (c) 2017 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : HCRewriterRMOTest.cls  
 Script Type         : Standard Apex Test Class 
 Description         : URL Rewriter Tests for HCRewriterRMO.cls

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-04-26  Ben Knight      Cloned from HCRewriter as part of the 
                                     new help center admin rearchitecture
 =======+===========+=================+=================================*/
@isTest
global with sharing class HCRewriterRMOTest {
    
    @isTest
    private static void testHCRewriterURLContexts() {
        System.runAs([SELECT Id FROM User WHERE IsActive=true AND Profile.Name='System Administrator' LIMIT 1][0]) {
            HCRewriterRMO wrtr = new HCRewriterRMO();
            wrtr.mapRequestUrl(new PageReference('/hcpagermo'));
            wrtr.mapRequestUrl(new PageReference('/article/bogus'));
            wrtr.mapRequestUrl(new PageReference('/suggestions'));
            wrtr.mapRequestUrl(new PageReference('/report-a-concern'));
            wrtr.mapRequestUrl(new PageReference('/videos'));
            wrtr.mapRequestUrl(new PageReference('/contact-thumbtack'));
            wrtr.mapRequestUrl(new PageReference('/customers'));
            wrtr.mapRequestUrl(new PageReference('/pros'));
            wrtr.mapRequestUrl(new PageReference('/search'));
            wrtr.mapRequestUrl(new PageReference('/subtopic'));
            wrtr.mapRequestUrl(new PageReference('/preview-article'));
            wrtr.mapRequestUrl(new PageReference('/request-a-call'));
            wrtr.generateUrlFor(new List<PageReference>());
        }
    } 
}