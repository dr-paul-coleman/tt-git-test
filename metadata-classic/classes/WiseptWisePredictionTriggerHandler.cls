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
========+============+=================+========================================
1.0       2016-12-11    Scott Purcell		Moved from Trigger
1.1       2016-12-16	Scott Purcell		Added an additional check to line 34
========+============+=================+========================================*/
public with sharing class WiseptWisePredictionTriggerHandler {
	public static void OnAfterInsertUpdate(List<wisespt__WisePrediction__c> afterInsert) 
	{
		Set<id> caseIds = new Set<id>();
	    for (wisespt__WisePrediction__c wp : afterInsert){
	        caseIds.add(wp.wisespt__CaseID__c); 
	    }   
	    List<Case> caseList = [Select Id, Status, Category__c, SubCategory__c, OwnerId, WisePredictionProcessed__c, OriginalQueue__c, TierCategoryTriageDateTime__c, AutoResponseRule__c, (Select Id, IsNoise__c, PredictedOwnerId__c, PredictedOriginalQueue__c, ShouldBeProcessed__c, wisethumbtack__WiseTag_Category__c,wisethumbtack__WiseTag_SubCategory__c, ThumbtackAutoResponseRule__c From wisespt__WisePredictions__r) from Case where Id in :caseIds];
	    for(Case c : caseList){
	        for(wisespt__WisePrediction__c w: c.wisespt__WisePredictions__r){
	            if(w.ShouldBeProcessed__c == true && c.WisePredictionProcessed__c == false){
	                if(w.IsNoise__c){
	                    c.Category__c = 'Other';
	                    c.SubCategory__c = 'Noise';
	                }
	                else{
	                    /* Commented out based on Channel Cohesion phase 3 changes.
	                    if (w.wisethumbtack__WiseTag_Category__c =='Other' && w.wisethumbtack__WiseTag_SubCategory__c == 'Noise'){
	                        // do nothing
	                    }
	                    else{ 
	                        c.Category__c = w.wisethumbtack__WiseTag_Category__c;
	                        c.SubCategory__c = w.wisethumbtack__WiseTag_SubCategory__c;
	                    }*/
	                    
	                    c.Category__c = w.wisethumbtack__WiseTag_Category__c;
	                    c.SubCategory__c = w.wisethumbtack__WiseTag_SubCategory__c;
	                }
	                c.OwnerId = w.PredictedOwnerId__c;
	                c.WisePredictionProcessed__c = true;
	                c.OriginalQueue__c = w.PredictedOriginalQueue__c;
	                c.TierCategoryTriageDateTime__c = DateTime.now();
	                c.AutoResponseRule__c = w.ThumbtackAutoResponseRule__c;
	            }
	        }
	    }
	    if(!caseList.isEmpty()) Update caseList;
		
	}

}