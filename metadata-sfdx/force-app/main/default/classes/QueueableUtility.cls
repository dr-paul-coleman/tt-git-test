/*
   Copyright (c) 2017 Thumbtack, All rights reserved.

Change List:
------------
Version      Date          Author            Description
========+============+=================+================================================
1.0       1/3/18      pcoleman           Created for reusable Queueable-related functions
========+============+=================+===============================================*/
public with sharing class QueueableUtility
{

    /**
    * @author Paul Coleman
    * @date 2018-01-03
    * @description Provides basic Queueable execution depending on governor limit context.
    * @parm Queueable A queueuable class that should execute asynchronously unless prohibited by governor limit.
    */
    public static void handleQueueable(Queueable job)
    {
        try
        {
            if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            {
                try
                {
                    System.enqueueJob(job);
                }
                catch (System.AsyncException ccEx) { job.execute(NULL); } catch (System.LimitException limitEx) { job.execute(NULL); }
            }
            else
            {
                job.execute(NULL);
            }
        }
        catch (Exception ex) { TackBotUtility.postTackLogException(ex, 'QueueableUtility.handleQueueable'); }
    }

}