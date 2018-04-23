/* +=====================================================================+    
 |                       Copyright (c) 2017 Thumbtack                    |    
 |                          All rights reserved.                         |    
 +=======================================================================+      
 Script File Name    : HCSiteMapController.cls
 Script Type         : Standard Apex Class 
 Description         : Controller for HCSiteMapText.vfp, for generating a site map for SEO.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-02-16  Ben Knight        Created 
 =======+===========+=================+=================================*/

public class HCSiteMapController {
    public string SiteMap {
        get {
        	List<String> urls = new List<String>();
            for(PublicArticle__kav p: [SELECT Id,KnowledgeArticleId,UrlName From PublicArticle__kav WHERE IsVisibleInPkb = true AND PublishStatus ='Online' AND Language = 'en_US'])
            {
                urls.add(this.UrlBase + 'article/' + p.UrlName);
            }
            return String.join(urls, '\n');
        } 
        set;
    }
    private string UrlBase = 'https://help.thumbtack.com/';
    
}