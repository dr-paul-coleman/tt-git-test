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
  


Change List:
------------
Version      Date          Author            Description
========+============+=================+=========================================
1.1       2016-12-11     Scott Purcell          Edited to work with Trigger Handler
========+============+=================+=========================================*/
@isTest
public class WiseptWisePredictionTriggerTest {
    
    static testMethod void testShouldBeNoise() {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        Id categorizationQueueId = [SELECT id FROM group WHERE Type = 'Queue' AND DeveloperName = 'Categorization' LIMIT 1][0].Id;
        Id noiseQueueId = [SELECT id FROM group WHERE Type = 'Queue' AND DeveloperName = 'Noise' LIMIT 1][0].Id;
        Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        
        System.runAs(testUser) {
            List<Case> caseList = new List<Case>();
            Integer casesToCreate = 1; //Adjust to control # of cases and predictions to be created
            Integer i;
            for (i=0; i<casesToCreate; i++) {
                Case a = new Case( RecordTypeID=caseRTId, 
                                  Origin='Web', 
                                  ManualCaseCreation__c = false, 
                                  WisePredictionProcessed__c = false, 
                                  OwnerId = categorizationQueueId 
                                 );
                caseList.add(a);
            }
            insert caseList;

            List<wisespt__WisePrediction__c> wiseList = new List<wisespt__WisePrediction__c>();
            Integer j;
            for (j=0; j<caseList.size(); j++) {
                wisespt__WisePrediction__c b = new wisespt__WisePrediction__c( 
                    wisespt__CaseID__c = caseList[j].Id, 
                    wisethumbtack__WiseTag_Noise__c='noise', 
                    wisethumbtack__WiseTag_Category__c = 'Quotes', 
                    wisethumbtack__WiseTag_SubCategory__c = 'Test',
                    wisethumbtack__WiseTag_Noise_confident__c=true, 
                    wisethumbtack__WiseTag_Tier__c='tier-1'
                );
                wiseList.add(b);    
            }
            
            Test.startTest();
            insert wiseList;
            Test.stopTest();
            
            Double q = Math.floor(Math.random()*caseList.size());
            Integer r = q.intValue();
            Case testCase = [SELECT Id, OwnerId FROM Case WHERE Id = :caseList[r].Id];
            System.assert(testCase.OwnerId == noiseQueueId, 'Case ownerId (' + testCase.Ownerid + ') != noise queue id (' + noiseQueueId + ')');        
        }
    }
        static testMethod void testCaseUpdate() {
        User testUser = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];
        Id categorizationQueueId = [SELECT id FROM group WHERE Type = 'Queue' AND DeveloperName = 'Categorization' LIMIT 1][0].Id;
        Id noiseQueueId = [SELECT id FROM group WHERE Type = 'Queue' AND DeveloperName = 'Noise' LIMIT 1][0].Id;
        Id caseRTId=Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer Support').getRecordTypeId();
        
        System.runAs(testUser) {
            List<Case> caseList = new List<Case>();
            Integer casesToCreate = 1; //Adjust to control # of cases and predictions to be created
            Integer i;
            for (i=0; i<casesToCreate; i++) {
                Case a = new Case( RecordTypeID=caseRTId, 
                                  Origin='Web', 
                                  ManualCaseCreation__c = false, 
                                  WisePredictionProcessed__c = false, 
                                  OwnerId = categorizationQueueId 
                                 );
                caseList.add(a);
            }
            insert caseList;

            List<wisespt__WisePrediction__c> wiseList = new List<wisespt__WisePrediction__c>();
            Integer j;
            for (j=0; j<caseList.size(); j++) {
                wisespt__WisePrediction__c b = new wisespt__WisePrediction__c( 
                    wisespt__CaseID__c = caseList[j].Id, 
                    wisethumbtack__WiseTag_Noise__c='noise', 
                    wisethumbtack__WiseTag_Category__c = 'Test', 
                    wisethumbtack__WiseTag_SubCategory__c = 'Test',
                    wisethumbtack__WiseTag_Noise_confident__c=false, 
                    wisethumbtack__WiseTag_Tier__c='tier-1'
                );
                wiseList.add(b);    
            }
            
            Test.startTest();
            insert wiseList;
            Test.stopTest();
            
            Double q = Math.floor(Math.random()*caseList.size());
            Integer r = q.intValue();
            Case testCase = [SELECT Id, Category__c FROM Case WHERE Id = :caseList[r].Id];
            System.assert(testCase.Category__c == 'Test', 'Case Category (' + testCase.Category__c + ') != predictected category');        
        }
    }
}