global class ScheduledBackgroundCheckSyncReports implements Schedulable, Database.AllowsCallouts {
	global void execute(SchedulableContext sc) {
		
			if(!Test.isRunningTest())CheckrAPI.getReportsBulk();
		
	}
}
/*
ScheduledBackgroundCheckSyncReports m = new ScheduledBackgroundCheckSyncReports();

String sch = '0 0 4 * * ?';
String jobID = system.schedule('ScheduledBackgroundCheckSyncReports-4am', sch, m);
sch = '0 0 8 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-8am', sch, m);
sch = '0 0 12 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-10am', sch, m);
sch = '0 0 14 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-12pm', sch, m);
sch = '0 0 16 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-2pm', sch, m);
sch = '0 0 18 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-4pm', sch, m);
sch = '0 0 20 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-6pm', sch, m);
sch = '0 0 22 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-8pm', sch, m);
sch = '0 0 24 * * ?';
jobID = system.schedule('ScheduledBackgroundCheckSyncReports-12am', sch, m);

*/