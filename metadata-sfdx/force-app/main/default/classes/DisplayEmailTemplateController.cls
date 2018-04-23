global with sharing class DisplayEmailTemplateController {

global static List<EmailTemplate> getTempList() {
 return[SELECT Id,Folder.Name,Name,Subject,TemplateType,IsActive,Description,TimesUsed,LastUsedDate,CreatedDate,LastModifiedDate,LastModifiedBy.Name 
            FROM EmailTemplate ORDER BY LastModifiedDate DESC];
   }
}