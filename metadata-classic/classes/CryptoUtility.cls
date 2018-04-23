/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2/2/18      pcoleman           Created
========+============+=================+===============================================*/
public with sharing class CryptoUtility
{
    private static final Map<String,String> hashKeyMap = new Map<String, String>{
            Schema.Dispute__c.sObjectType.getDescribe().getKeyPrefix() => 'D',
            Schema.DisputeOffer__c.sObjectType.getDescribe().getKeyPrefix() => 'O',
            Schema.DisputeMessage__c.sObjectType.getDescribe().getKeyPrefix() => 'M',
            Schema.Account.sObjectType.getDescribe().getKeyPrefix() => 'A',
            Schema.Contact.sObjectType.getDescribe().getKeyPrefix()  => 'C'
    };

    public static String hashId( String recordId )
    {
        String result = '';
        if( !String.isEmpty(recordId) )
        {
            String keyPrefix = recordId.left(3);
            String idStr = recordId.left(15).right(12);
            String prefix = hashKeyMap.get(keyPrefix);
            result = ( prefix + idStr).replace('0000', prefix.toLowerCase() );
        }
        return result;
    }

    public static String getIdHash(SObject so)
    {
        DescribeSObjectResult[] describe = Schema.describeSObjects( new String[]{so.getSObjectType().getDescribe().name} );
        String keyPrefix = describe[0].keyPrefix;
        String prefix = hashKeyMap.get(keyPrefix);
        return prefix + generateRandomString(9);
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod( Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

}