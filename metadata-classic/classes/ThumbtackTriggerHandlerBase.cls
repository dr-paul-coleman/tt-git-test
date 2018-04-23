/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version   Date         Author           Description
========+============+=================+================================================
1.0       10/5/17      paulcoleman          Created
========+============+=================+===============================================*/
public virtual class ThumbtackTriggerHandlerBase
{

    public class ThumbtackTriggerHandlerException extends Exception {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called prior to execution of any other BEFORE trigger handler. This can be used
	*				to load lookup data or cache data, etc.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void doBeforeProcessing(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called prior to execution of any other AFTER trigger handler.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void doAfterProcessing(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called for records to be inserted during a BEFORE trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onBeforeInsert(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called for records to be updated during a BEFORE trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onBeforeUpdate(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called for records to be deleted during a BEFORE trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onBeforeDelete(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called for records inserted during an AFTER trigger. Always put field validation
	*				in the 'After' methods in case another trigger has modified any values. The record is 'read only'
	*				at this point.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onAfterInsert(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called iteratively for each record updated during an AFTER trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onAfterUpdate(ThumbtackTriggerContext tgr){}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called iteratively for each record deleted during an AFTER trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onAfterDelete(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is called prior to execution of a AFTER UNDELETE trigger.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void onAfterUnDelete(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method is after all other processing is complete.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void doFinalProcessing(ThumbtackTriggerContext tgr) {}

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This method can be overridden in a handler implementation class and used for diverting recursive trigger handler execution in conjunction with static context Boolean values.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object
	*/
    public virtual void doRecursiveProcessing(ThumbtackTriggerContext tgr) {}


    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This is a core method for invoking a trigger event's handler(s). NOTE: The doBeforeProcessing, doAfterProcessing, and doFinalProcessing functions are optional catch-all event handlers.
	* @param ThumbtackTriggerContext A wrapper of the System.Trigger context object that is passed to each event handler function
	*/
    public virtual void doEvent(ThumbtackTriggerContext tctx)
    {
        String event = String.valueOf(tctx.dmlEvent).toLowerCase();
        Boolean isBefore = event.startsWith('before');

        try
        {
            if (isBefore) // Handle before trigger events
            {
                this.doBeforeProcessing(tctx);
                if (event.endsWith('delete'))
                    this.onBeforeDelete(tctx);
                else if (event.endsWith('insert'))
                    this.onBeforeInsert(tctx);
                else if (event.endsWith('update'))
                    this.onBeforeUpdate(tctx);
            }
            else    // Handle after trigger events
            {
                this.doAfterProcessing(tctx);
                if (event.endsWith('delete'))
                    this.onAfterDelete(tctx);
                else if (event.endsWith('insert'))
                    this.onAfterInsert(tctx);
                else if (event.endsWith('update'))
                    this.onAfterUpdate(tctx);
                else if (event.endsWith('undelete'))
                    this.onAfterUnDelete(tctx);
            }
        }
        finally
        {
            this.doFinalProcessing(tctx);
        }
    }

    /***************************************************************************************/
    /* BEGIN STATIC FACTORY FUNCTIONS for instantiating Handler class with trigger context */

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description This is the core method for all trigger handler execution (the trigger entry point), e.g. ThumbtackTriggerHandlerBase.doTrigger('handler class name').
	* @param String The name of the trigger handler class that must extend ThumbtackTriggerHandlerBase.
	*/
    public static void doTrigger(String handlerClassName)
    {
        ThumbtackTriggerHandlerBase handler = getTriggerHandler(handlerClassName);
        if ( NULL == handler ) { throw new ThumbtackTriggerHandlerException('No Trigger handler found for class name: ' + handlerClassName); }

        //ByPassTriggerHandlers Custom Label contains comma-delimited list of Handler Classes to skip
        Set<String> bypassTheseHandlers = new Set<String>(Label.ByPassTriggerHandlers.toLowerCase().replaceAll(' ', '').split(','));
        Boolean isTriggerDisabled = bypassTheseHandlers.contains('all') || bypassTheseHandlers.contains(handlerClassName.toLowerCase());
        // always run handler code in Test runs to avoid having to switch all tests to compensate for disabled triggers
        isTriggerDisabled = Test.isRunningTest()? false : isTriggerDisabled;
        if (!isTriggerDisabled)
        {
            ThumbtackTriggerContext tcontext = new ThumbtackTriggerContext(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap,
                    Trigger.isBefore, Trigger.isAfter, Trigger.isDelete,
                    Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete, Trigger.isExecuting, Trigger.size);

            handler.doEvent(tcontext);
        }
        else
        {
            System.debug(LoggingLevel.WARN, 'Trigger handler class ' + handlerClassName + ' is disabled in Custom Label ByPassTriggerHandlers.' + (bypassTheseHandlers.contains('all') ? '[ALL HANDLERS BYPASSED]' : ''));
        }
    }

    /**
	* @author Paul Coleman
	* @date 2017-10-05
	* @description Instantiates a trigger handler type by class name.
	* @param String The name of the trigger handler class that must extend ThumbtackTriggerHandlerBase.
	*/
    private static ThumbtackTriggerHandlerBase getTriggerHandler(String triggerHandlerForName)
    {
        Type obType = Type.forName(triggerHandlerForName);
        ThumbtackTriggerHandlerBase handlerInstance = (obType == null) ? null : (ThumbtackTriggerHandlerBase) obType.newInstance();
        return handlerInstance;
    }

    /* END STATIC FACTORY FUNCTIONS for instantiating Handler class with trigger context */
    /*************************************************************************************/


}