/**
  Copyright (c) 2017 Thumbtack. All rights reserved.

  Version      Date          Author            Description
  ========+============+=================+================================================
  1.0      2017-12-06   Mendel Guillaume       Created
  1.1	   2018-02-09   Mendel Guillaume       Modified to account for HTML tags
  ========+============+=================+===============================================
 */

public with sharing class ParentCasePostFeedController
{
	@AuraEnabled
	public static String submit(String post, String caseId)
	{
		String result = 'Success';

		try
		{
			String body = post.replace('</p>', '{br}').replace('<br>', '{br}').replace('<br/>', '{br}').stripHtmlTags().replace('{br}', '<p>&nbsp;</p>');
			insert new FeedItem(ParentId = caseId, Body = body, Type = 'TextPost', IsRichText = true);
		}
		catch (Exception ex)
		{
			result = ex.getMessage();
		}

		return result;
	}
}