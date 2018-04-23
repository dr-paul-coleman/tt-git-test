/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

 Change List:
 ------------
 Version    Date     Author            Description
 =======+===========+=================+=================================
 1.0     2017-09-25  Paul Coleman      Created
 1.1     2018-01-30  Paul Coleman      Randomized User PK values between tests
 =======+===========+=================+=================================*/
@isTest
public with sharing class ThumbtackUserSSOProvisionerTest
{

    // mimic SAML Attribute map
    private static Map<String,String> getAttributeMap( String userId ){
        return new Map<String, String> {'email'=>'ssotest.script.'+ EncodingUtil.convertToHex( Crypto.generateDigest( 'MD5', Blob.valueOf( userId + String.valueOf(System.now().getTime()) ) ) )+'@thumbtack.com',
        'first_name'=>'Kevin',
        'last_name'=>'Nelson',
        'timezone'=>'America/Los_Angeles',
        'user_id' => userId,
        'user_type'=>'Customer',
        'business_name'=>'Testing Plumber'};
    }

    /**
    * @author Paul Coleman
    * @date 2018-01-30
    * @description Create a random User PK string value for use in each provisioning test
    *                   Randomize to make sure the test pk does not conflict with the growing
    *                   set of User.FederationIdentifier values over time.
    * @return String The unique pk id.
    */
    private static String getRandomPK()
    {
        String newFedId;
        Set<String> fedIds = new Set<String>();
        for( User u: [SELECT FederationIdentifier FROM User] )
        {
            fedIds.add( u.FederationIdentifier );
        }
        newFedId = String.valueOf( Crypto.getRandomInteger() );
        while( fedIds.contains( newFedId ) )
        {
            newFedId = String.valueOf( Crypto.getRandomInteger() );
        }
        return newFedId;
    }

    /**
    * @author Paul Coleman
    * @date 2017-09-25
    * @description Test New Account and User simultaneously.
    */
    @isTest
    private static void testJITProvisioningNewAccount()
    {
        String pkId = getRandomPK();
        ThumbtackUserSSOProvisioner provisioner;
        System.runAs( TestUtilities.USER_TACK_BOT )
        {
            Test.startTest();

                provisioner = new ThumbtackUserSSOProvisioner();
                provisioner.createUser(null, null, null, pkId, getAttributeMap(pkId), null);

            Test.stopTest();

            User[]  newUser = [SELECT Id,Profile.Name,AccountId,Account.user_pk_id__c,Contact.AccountId,ContactId FROM User WHERE FederationIdentifier = :pkId LIMIT 1];
            System.assert( !newUser.isEmpty(), 'User provisioner failed in insert new community User record bound to test FederationIdentifier (thumbtack pk id)' );
            System.assert( 'Thumbtack User' == newUser[0].Profile.Name, 'New community User record is not the correct ProfileId' );
            System.assert( null != newUser[0].ContactId, 'User provisioner failed create new Contact and/or assign ContactId' );
            System.assert( null != newUser[0].AccountId, 'User provisioner failed assign Contact\'s AccountId' );
            System.assert( newUser[0].Contact.AccountId.equals( newUser[0].AccountId ), 'User provisioner failed relate User.AccountId to the Contact\'s AccountId' );
            System.assert( pkId.equals( newUser[0].Account.user_pk_id__c ), 'User provisioner failed assign Account.user_pk_id__c' );

            //grab complete code coverage for empty interface method
            provisioner.updateUser(null, null, null, null, pkId, getAttributeMap( pkId ), null);
        }
    }

    /**
    * @author Paul Coleman
    * @date 2017-09-25
    * @description Test User already exists flow.
    */
    @isTest
    private static void testJITProvisioningExistingUser()
    {
        String pkId = getRandomPK();
        System.runAs( TestUtilities.USER_TACK_BOT )
        {
            User[] guineaPigs = [SELECT Id,Name FROM User WHERE Profile.Name != 'System Administrator' AND IsActive=true AND Id != :TestUtilities.USER_TACK_BOT.Id AND UserType IN ('Standard','CspLitePortal') LIMIT 1];
            if( !guineaPigs.isEmpty() )
            {
                User guineaPig = guineaPigs[0];
                guineaPig.FederationIdentifier = pkId;
                guineaPig.IsActive = false;
                update guineaPig;

                Test.startTest();

                try
                {
                    new ThumbtackUserSSOProvisioner().createUser(null, null, null, pkId, getAttributeMap(pkId), null);
                }
                catch (ThumbtackUserSSOProvisioner.JitUserException je)
                {
                    System.assert(je.getMessage().startsWith('User is no longer active'), 'ThumbtackUserSSOProvisioner.JitUserException not thrown by existing InActive User provisioning test');
                }

                Test.stopTest();
            }

        }
    }

    /**
    * @author Paul Coleman
    * @date 2017-09-25
    * @description Test Account already exists, User-only provisioning.
    */
    @isTest
    private static void testJITProvisioningAccountAlreadyExists()
    {
        String pkId = getRandomPK();
        //get tackbot as test user
        System.runAs( TestUtilities.USER_TACK_BOT )
        {
            Id accountProRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
            Map<String,String> attrMap = getAttributeMap( pkId );
            Account newA =  new Account(  Name = attrMap.get('business_name'),
                    usr_email__c = attrMap.get('email'),
                    usr_first_name__c = attrMap.get('first_name'),
                    usr_last_name__c = attrMap.get('last_name'),
                    usr_timezone__c = attrMap.get('timezone'),
                    user_pk_id__c = pkId,
                    usr_user_id__c = Decimal.valueOf( attrMap.get('user_id') ),
                    RecordTypeId = accountProRtId
            );
            insert newA;
            Test.setFixedSearchResults( new Id[]{newA.Id} );

            Test.startTest();

                new ThumbtackUserSSOProvisioner().createUser(null, null, null, pkId, getAttributeMap( pkId ), null);

            Test.stopTest();

            Account[] accounts = [SELECT Id, user_pk_id__c, (SELECT Id FROM Contacts) FROM Account WHERE user_pk_id__c = :pkId LIMIT 1];
            System.assert( !accounts.isEmpty(), 'User provisioner failed in insert new community User record' );
            User[]  newUser = [SELECT Id,FederationIdentifier,Profile.Name,AccountId,Contact.AccountId,ContactId FROM User WHERE FederationIdentifier = :pkId LIMIT 1];
            System.assert( !newUser.isEmpty(), 'User provisioner failed in insert new community User record bound to test FederationIdentifier (thumbtack pk id)' );

        }
    }
}