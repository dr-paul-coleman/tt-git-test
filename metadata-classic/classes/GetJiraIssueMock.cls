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
Version    Date     Author            Description
=======+===========+=================+================================================
1.0     02-27-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@isTest
global class GetJiraIssueMock implements HttpCalloutMock{
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
       
        String body=  
        	'{' 
            + '"fields": {'
                + '"summary": "' + 'summarryName' + '",'
                + '"issuetype": {'
                    + '"name": "' + 'Bug' + '"'
                + '},'
               + '"status": {'
                    + '"name": "' + 'To Do' + '"'
                + '},'
                + '"description": "' + 'This is a description' + '",'
                + '"priority": {'
                    + '"name": "' + 'High'+ '"'
                + '},'
                +'"comment": {'
                  +'"comments": ['
                    +'{'
                      +'"self": "' + 'https://thumbtack.atlassian.net/rest/api/2/issue/40854/comment/46837' +'",'
                      +'"id": "' + '46837' +'",'
                      +'"body": "' + 'This is a comment' +'"'
                    +'}'
                 +']}'
                
            + '}}';
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}