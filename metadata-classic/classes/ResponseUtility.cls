/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
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

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-31   Mendel Guillaume       Created
========+============+=================+===============================================*/

public class ResponseUtility
{
	@AuraEnabled
	public Boolean success{get;set;}

	@AuraEnabled
	public String error{get;set;}

	@AuraEnabled
	public Object record{get;set;}

	public ResponseUtility()
	{
		this(null, false);
	}

	public ResponseUtility(Boolean success)
	{
		this(null, success);
	}

	public ResponseUtility(Object record, Boolean success)
	{
		this.success = success;
		this.record = record;
	}
}