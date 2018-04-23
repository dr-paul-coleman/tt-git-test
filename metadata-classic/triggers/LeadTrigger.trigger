/*
 Copyright (c) 2016 Thumbtack. All rights reserved.

 Change List:                                                               
 ------------
 Version    Date     Author            	Description                          
 =======+===========+==================+==================================================
 1.0     2018-02-05  Meenakshi Pisupati Created to handle lead conversion to enrollments
 =======+===========+==================+==================================================*/
trigger LeadTrigger on Lead (after update, after insert) {
    ThumbtackTriggerHandlerBase.doTrigger( 'LeadTriggerHandler' );
}