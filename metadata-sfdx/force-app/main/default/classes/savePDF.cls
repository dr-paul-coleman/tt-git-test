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
========+============+=================+================================================
1.0       06-02-2017     Kritsin Hasna          Created
========+============+=================+===============================================*/
public class savePDF 
{

    Private MIIncidentAction__c pageAction;
    public Boolean initialised{get; set;}

    public savePDF(ApexPages.StandardController stdController) 
    {
        this.pageAction = (MIIncidentAction__c)stdController.getRecord();
        id PageActionId = ApexPages.currentPage().getParameters().get('id');
        initialised=false;
    }

    public void saveAttachement() 
    {
                    
        if (!initialised && pageAction.ID !=NULL) 
        {

            PageReference pdf = Page.MIPayoutsPDF;

            Attachment attach = new Attachment();

            Blob body;

            try 
            {

                body = pdf.getContentAsPDF();
          
            } 
            catch (VisualforceException e) 
            {
                 body = Blob.valueOf('Some Text');
            }

            attach.Body = body;
            attach.Name = 'PayoutFormForAccountsPayable.pdf';
            attach.IsPrivate = false;
            attach.ParentId = pageAction.Id;
            insert attach;
            initialised=true;
        } 
} 
}