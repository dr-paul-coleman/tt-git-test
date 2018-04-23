/* 
   Copyright (c) 2017 Thumbtack, All rights reserved.

 Change List:                                                               
 ------------                                                               
 Version    Date     Author            Description                          
 =======+===========+=================+=================================
 1.0     2017-09-12  Paul Coleman      Created 
 =======+===========+=================+=================================*/
 
global class ThumbtackUserSSOProvisioner implements Auth.SamlJitHandler 
{
    public class JitUserException extends Exception{}
    private static final String ACCOUNT_LOOKUP_QUERY = 'SELECT Id, Phone, user_pk_id__c, usr_timezone__c, usr_email__c, usr_first_name__c, usr_last_name__c, (SELECT Id,AccountId,user_pk_id__c, LastName, FirstName FROM Contacts) FROM Account';
    private static final String USER_PROFILE_NAME = 'Thumbtack User';
    private static final Id THUMBTACK_USER_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =:USER_PROFILE_NAME LIMIT 1].Id;

    private User insertUser( User salesforceUser )
    {
        Database.SaveResult result = Database.insert(salesforceUser);
        if(!result.isSuccess())
        {
            System.debug( LoggingLevel.ERROR, 'SSO JIT Provisioning ERROR: ' + JSON.serialize(result));

        } else {
            System.debug(LoggingLevel.FINEST, 'INSERTED USER: ' + JSON.serialize(salesforceUser));
        }
        return salesforceUser;
    }

    public User[] createThumbackUsers( Set<Id> accountIds )
    {
        User[] newUsers = new User[0];
        for( Account ttuser: (Account[])Database.query( ACCOUNT_LOOKUP_QUERY +' WHERE Id IN :accountIds LIMIT 1') )
        {
            User salesforceUser = new User( FederationIdentifier = ttuser.user_pk_id__c,
                    Email = ttuser.usr_email__c,
                    FirstName = ttuser.usr_first_name__c,
                    LastName = ttuser.usr_last_name__c,
                    Phone = ( null == ttuser.Phone || ''.equals(ttuser.Phone) )? null: ttuser.Phone.replaceAll('[^0-9]',''),
                    ProfileId = THUMBTACK_USER_PROFILE_ID
                );
            newUsers.add( this.createThumbtackUser( ttuser, salesforceUser ) );
        }
        return newUsers;
    }
            
    private User createThumbtackUser( Account thumbtackUser, User salesforceUser )
    {
       
        if ( null != thumbtackUser && null != salesforceUser.FederationIdentifier && null != thumbtackUser.Contacts && !thumbtackUser.Contacts.isEmpty() ) 
        {
            System.debug(LoggingLevel.FINEST, 'TARGET ACCOUNT/CONTACT: ' + JSON.serialize(thumbtackUser));
            
            // vars to load up new User record
            String fedId = salesforceUser.FederationIdentifier;
            Boolean isProdOrg = ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            String timeZone = ( null == thumbtackUser.usr_timezone__c || ''.equals(thumbtackUser.usr_timezone__c.trim()) )? 'America/Los_Angeles': validateTimeZone(thumbtackUser.usr_timezone__c);
            String contactId = thumbtackUser.Contacts[0].Id;
            String emailaddress = '_'+fedId + '@siteuser.thumbtack.com';

            // avoid automatically sending email to Thumtback Users from Salesforce
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.TriggerUserEmail = false;
            dmo.EmailHeader.TriggerOtherEmail = false;
            dmo.EmailHeader.TriggerAutoResponseEmail = false;
            dmo.optAllOrNone = false;
            salesforceUser.setOptions(dmo);

            // set req'd User fields
            salesforceUser.ContactId             = contactId;
            salesforceUser.Username              = emailaddress + ( isProdOrg? '': '._'+UserInfo.getOrganizationId() );
            salesforceUser.Email                 = emailaddress;
            salesforceUser.Alias                 = contactId.right(8); //must be unique 8 bytes
            salesforceUser.CommunityNickname     = fedId.left(40);
            salesforceUser.EmailEncodingKey      = 'UTF-8';  
            salesforceUser.LanguageLocaleKey     = 'en_US'; 
            salesforceUser.LocalesIdKey          = 'en_US';
            salesforceUser.TimezonesIdKey        = timeZone;
            salesforceUser.isActive              = true;
            salesforceUser.UserPreferencesHideS1BrowserUI = true;
        }
          else 
        {
            System.debug( LoggingLevel.ERROR, 'SSO JIT Provisioning ERROR, REQUIRED PARM MISSING: A valid Contact and fedIdentifier are required parameters for ThumbtackUserSSOProvisioner.createThumbtackUser()');
        }

        return salesforceUser;
    }
    
    private String validateTimeZone(String tz) 
    {
        String result = 'America/Los_Angeles'; //default tz
        if( null != tz && !''.equals(tz.trim()) ) 
        {
            //verify that the tz function parm (SAML Attribute) is a valid TimeZoneIdKey for User records, otherwise use a default value
            Schema.DescribeFieldResult tzField = User.TimezonesIdKey.getDescribe();
            for( Schema.PicklistEntry plVal: tzField.getPicklistValues() )
            {
                if(plVal.isActive() && tz.toLowerCase().equals(plVal.getValue().toLowerCase()))
                {
                    result = tz;
                    break;
                }
            }
        }

        return result;
    }
    
    private void createAccount(User salesforceUser, Map<String,String> samlAttributes)
    {
        Id accountCustomerRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Id accountProRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Thumbtack Pro').getRecordTypeId();
        String ttBusinessName = samlAttributes.get('business_name');
        Id rtId = 'Customer'.equals(samlAttributes.get('user_type'))? accountCustomerRtId: accountProRtId; //default to PRO
        String nameStr =  ( null == ttBusinessName || ''.equals(ttBusinessName.trim() ) )? salesforceUser.FirstName + ' ' + salesforceUser.LastName: ttBusinessName;
        String ttUserId = samlAttributes.get('user_id');

        //load up default Account values from the new User record in combo with the inbound SAML Attributes
        Account ttAccount = new Account( Name = nameStr.left(80), 
                                         Phone = salesforceUser.Phone,
                                         usr_email__c = salesforceUser.Email, 
                                         usr_user_id__c =  ( null == ttUserId || ''.equals(ttUserId) )? null: Decimal.valueOf(ttUserId),
                                         user_pk_id__c =  salesforceUser.FederationIdentifier,
                                         usr_timezone__c = samlAttributes.get('timezone'), //validated before User insert in createUser()
                                         usr_first_name__c = salesforceUser.FirstName,  
                                         usr_last_name__c = salesforceUser.LastName,
                                         RecordTypeId = rtId,
                                         SyncedWithBequerel__c = false
                                       );
                
        Database.SaveResult result = Database.insert( ttAccount, false ); //Contact will be inserted by Account Trigger Handler. Next, get Account/Contact pair for User insert (ContactId is req'd)
        if ( result.isSuccess() )
        {
            Id accountId = ttAccount.Id;
            this.insertUser( this.createThumbtackUser( (Account)Database.query( ACCOUNT_LOOKUP_QUERY +' WHERE Id = :accountId LIMIT 1')[0], salesforceUser) );

        }
    }

    
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String fedIdentifier, Map<String, String> attributes, String assertion) 
    {
        System.debug(LoggingLevel.FINEST, 'SAML ATTRIBUTES' + JSON.serialize(attributes));
        String phone = attributes.get('phone'); //strip formatting chars below
        // 1] make sure user doesn't exist or hasn't been deactivated (supposed to be handled by SF before calling into this class)
        User[] salesforceUsers = [SELECT Id, IsActive FROM User WHERE FederationIdentifier = :fedIdentifier LIMIT 1];
        // 2] if no user, start loading up a new one
        User salesforceUser = salesforceUsers.isEmpty()? new User( FederationIdentifier = fedIdentifier,
                                        Email = attributes.get('email'),
                                        FirstName = attributes.get('first_name'),
                                        LastName = attributes.get('last_name'),
                                        Phone = ( null == phone || ''.equals(phone.trim()) )? null: phone.replaceAll('[^0-9]',''),
                                        ProfileId = THUMBTACK_USER_PROFILE_ID
                                        ): salesforceUsers[0];
        if ( !salesforceUsers.isEmpty() ) 
        {
            if( !salesforceUser.IsActive ) 
            {
              throw new JitUserException('User is no longer active: ' + fedIdentifier);
            }
        } 
            else 
        {
            // 3] no matching user (good), see if an account exists with inbound federationidentifer (Account/Contact user_pk_id__c)
            String fedId = salesforceUser.FederationIdentifier;
            List<Account> thumbtackUser = Database.query( ACCOUNT_LOOKUP_QUERY +' WHERE user_pk_id__c = :fedId LIMIT 1');
            if( thumbtackUser.isEmpty() ) 
            {
                // 4a] insert a new Account & Contact, then a new User
                this.createAccount(salesforceUser, attributes);
            } 
              else 
            {
                // 4b] insert a new User bound to the matching Account/Contact (NOTE: current Account.OwnerId must have a RoleId != null)
                this.insertUser( this.createThumbtackUser(thumbtackUser[0], salesforceUser) );
            }
        }
        return salesforceUser;
    }


    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String fedIdentifier, Map<String, String> attributes, String assertion) 
    {
        //req'd interafce function, but not needed, we do not update User records for Thumbtack SSO purposes
    }

}