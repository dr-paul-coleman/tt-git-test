/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       10/26/17      pcoleman           Created a class to wrap a standard Id data type
                                                with more String-like methods -- without
                                                having to cast the Id var as a String
========+============+=================+===============================================*/
public with sharing class TId
{
    private String rId;

    public TId(Id recordId) {
        this.rId = recordId;
    }

    public String keyPrefix()
    {
        return this.rId.left(3);
    }

    public Boolean isCase() {  return this.isSObject('Case'); }
    public Boolean isAccount() {  return this.isSObject('Account'); }
    public Boolean isContact() {  return this.isSObject('Contact'); }
    public Boolean isUser() {  return this.isSObject('User'); }
    public Boolean isGroup() {  return this.isSObject('Group'); }
    public Boolean isQueue() {  return this.isSObject('Queue'); }
    public Boolean isLead() {  return this.isSObject('Lead'); }
    public Boolean isOpportunity() {  return this.isSObject('Opportunity'); }

    private Boolean isSObject(String sobjectType)
    {
        String sType = sobjectType.toLowerCase();
        SObject so;
        try
        {
            if( sType.equals('case') ) { so = new Case(Id=this.rId); }
            if( sType.equals('account') ) { so = new Account(Id=this.rId); }
            if( sType.equals('contact') ) { so = new Contact(Id=this.rId); }
            if( sType.equals('user') ) { so = new User(Id=this.rId); }
            if( sType.equals('opportunity') ) { so = new Opportunity(Id=this.rId); }
            if( sType.equals('lead') ) { so = new Lead(Id=this.rId); }
            if( sType.equals('group') ) { so = new Group(Id=this.rId); }
            if( sType.equals('queue') ) { so = new Group(Id=this.rId); }
        }
        catch (Exception ex)
        {
            if ( !ex.getTypeName().toLowerCase().endsWith('typeexception') ) { throw ex; }
        }
        return ( NULL != so );
    }

    public static String get(Id recId)
    {
        return (String)recId;
    }

}