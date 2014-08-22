/* 
deletes all Scheduled Jobs except for Scheduled Apex. 
 -- to execute in code --
 DeleteJobs.abortAll();  
 */
public with sharing class DeleteJobs {
	
	public DeleteJobs() {
	}

	public static void abortAll(){
		//get all scheduled Jobs
		List<CronTrigger> jobs = [SELECT Id, CronJobDetail.JobType FROM CronTrigger];
		//loop through all scheduled jobs
		for(CronTrigger ct : jobs){
			//if the JobType == '7', then it is scheduled apex. Abort all jobs that do not have a JobType == '7' 
			if (ct.CronJobDetail.JobType != '7'){
				System.abortJob(ct.Id);
			}
		}
	}
}