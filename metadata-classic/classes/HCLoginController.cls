/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       2/27/18      pcoleman           Created
========+============+=================+===============================================*/
public with sharing class HCLoginController
{
    public PageReference init()
    {
        return new PageReference('/');
    }
}