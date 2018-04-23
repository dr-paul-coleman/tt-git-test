/*  Copyright (c) 2017 Thumbtack.  All rights reserved.

 Change List:                                                               
 ------------                                                               

 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-04-26  Ben Knight        Cloned from HCRewriter and updated 
                                       to reference /hcpagermo as part of
                                       the new help center admin
                                       rearchitecture
 =======+===========+=================+=================================*/

// Reference: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_site_urlRewriter.htm
global with sharing class HCRewriterRMO implements Site.UrlRewriter
{
    global PageReference mapRequestUrl(PageReference myFriendlyUrl)
    {
        String url = myFriendlyUrl.getUrl();
        PageReference helpcenter = new PageReference('/hcpagermo');
        PageReference solutioncenter = new PageReference('/solutioncenter');
        if (url.startsWith('/article/')) {
            helpcenter.getParameters().put('ar', url.substring('/article/'.length()));
            return helpcenter;
        }
        if (url.startsWith('/suggestions')) {
            helpcenter.getParameters().put('vw', 'sg');
            return helpcenter;
        }
        if (url.startsWith('/report-a-concern')) {
            helpcenter.getParameters().put('vw', 'pg');
            return helpcenter;
        }
        if (url.startsWith('/videos')) {
            helpcenter.getParameters().put('vw', 'vd');
            return helpcenter;
        }
        if (
                url.startsWith('/contact-thumbtack') ||
                        url.startsWith('/customers') ||
                        url.startsWith('/pros') ||
                        url.startsWith('/search') ||
                        url.startsWith('/subtopic') ||
                        url.startsWith('/preview-article') ||
                        url.startsWith('/request-a-call') ||
                        url.startsWith('/callback-request')
                ) {
            return helpcenter;
        }
        if (url.startsWith('/solutioncenter'))
        {
            return solutioncenter;
        }
        return null;
    }
    global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls){
        return mySalesforceUrls;
    }
}