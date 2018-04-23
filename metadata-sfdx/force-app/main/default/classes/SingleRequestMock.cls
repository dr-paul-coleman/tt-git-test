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
1.0     04-02-2017  Scott Purcell      Created
=======+===========+=================+================================================
*/
@isTest
public class SingleRequestMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String bodyAsString;
		protected Blob bodyAsBlob;
		protected Map<String, String> responseHeaders;

		public SingleRequestMock(Integer code, String status, String body,
                                         Map<String, String> responseHeaders) {
			this.code = code;
			this.status = status;
			this.bodyAsString = body;
			this.bodyAsBlob = null;
			this.responseHeaders = responseHeaders;
		}

		public SingleRequestMock(Integer code, String status, Blob body,
                                         Map<String, String> responseHeaders) {
			this.code = code;
			this.status = status;
			this.bodyAsBlob = body;
			this.bodyAsString = null;
			this.responseHeaders = responseHeaders;
		}

	    public HTTPResponse respond(HTTPRequest req) {
	        HttpResponse resp = new HttpResponse();
			resp.setStatusCode(code);
			resp.setStatus(status);
			if (bodyAsBlob != null) {
				resp.setBodyAsBlob(bodyAsBlob);
			} else {
				resp.setBody(bodyAsString);
			}

			if (responseHeaders != null) {
			     for (String key : responseHeaders.keySet()) {
				resp.setHeader(key, responseHeaders.get(key));
			     }
			}
			system.debug('****************************** SingleRequestMock - Response being returned:'+resp+'  ****************************');
			return resp;
	    }
}

/*code for the test class to implement this mock/include at top of each test class using a mock
SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'Complete',
                                                 '{"id":"58c95f513327c30040b768da","object":"county_criminal_search","uri":"/v1/county_criminal_searches/58c95f513327c30040b768da","status":"consider","county":"Hamilton","state":"OH","created_at":"2017-03-15T15:35:45Z","completed_at":"2017-03-15T17:19:21Z","turnaround_time":6216,"records":[{"id":"58c977996107d900215ca687","case_number":"17CRB4073","file_date":"2017-02-15","arresting_agency":"HAMILTON COUNTY","court_jurisdiction":"MUNICIPAL COURT","court_of_record":null,"dob":"1978-08-22","yob":null,"full_name":"JAYSON MELTON","county":"HAMILTON","state":"OH","charges":[{"charge":"POSSESSION OF DRUGS","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"GUILTY","probation_status":null,"offense_date":"2014-02-06","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2017-02-15","conviction_date":null,"release_date":null,"court":null,"plea":""}],"address":{"street":"3247 Lndale Mt","unit":"","city":"Holly Amelia","state":"OH","zipcode":"45102","county":null}},{"id":"58c977996107d900215ca68c","case_number":"C12CRB5620","file_date":"2012-02-27","arresting_agency":"HAMILTON COUNTY","court_jurisdiction":"MUNICIPAL COURT","court_of_record":null,"dob":"1978-08-22","yob":null,"full_name":"JAYSON M MELTON","county":"HAMILTON","state":"OH","charges":[{"charge":"POSSESSION OF DRUGS","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"GUILTY","probation_status":null,"offense_date":"2012-02-22","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2012-03-09","conviction_date":null,"release_date":null,"court":null,"plea":""},{"charge":"POSSESS ILLEGAL DRUG PARAPHERNALIA","charge_type":"MISDEMEANOR","charge_id":null,"classification":null,"deposition":null,"defendant":null,"plaintiff":null,"sentence":"","disposition":"DISMISSED","probation_status":null,"offense_date":"2012-02-22","deposition_date":null,"arrest_date":null,"charge_date":null,"sentence_date":null,"disposition_date":"2012-03-09","conviction_date":null,"release_date":null,"court":null,"plea":""}],"address":{"street":"3247 Lindale Ct","unit":"","city":"Amelia","state":"OH","zipcode":"45102","county":null}}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
*/