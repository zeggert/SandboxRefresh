public with sharing class SandboxRefreshController {
	public boolean isSandbox {get;set;}
	public boolean rallyUpdated {get;set;}
	public string orgId {get;set;}
	public String endPointURL {get;set;}
	public String flexeraURL {get;set;}
	public String imageNowURL {get;set;}
	public String sandboxName {get;set;}
	public Integer emailCount {get;set;}
	public Integer jobsAborted {get;set;}
	public SandboxRefreshController() {
		Organization org = [SELECT id, isSandbox FROM Organization LIMIT 1];
		isSandbox = org.isSandbox;
		orgId = UserInfo.getOrganizationId();
		//envURL = ApexPages.currentPage().getHeaders().get('Host');		
	}

	public void maskEmails(){
		if(sandboxName != null && isSandbox){
			emailCount = maskEmails.mask(sandboxName);
		}
	}

	public void updateEndPoint(){
		if(endPointURL != null && endPointURL != '' && isSandbox){
			LX_IDM_End_Points__c endPoint = [SELECT Name, End_Point__c FROM LX_IDM_End_Points__c WHERE Name = 'EndPoint'];
			endPoint.End_Point__c = endPointURL;
			update endPoint;
		}
	}
	public void updateFlexera(){
		if(flexeraURL != null && flexeraURL != '' && isSandbox){
			URL_Parameter__c flexeraLogin = [SELECT Name, URL_Value__c FROM URL_Parameter__c WHERE Name = 'Flexera_Login'];
			flexeraLogin.URL_Value__c = flexeraURL;
			update flexeraLogin;
		}
	}

	public void updateImageNow(){
		if(imageNowURL != null && imageNowURL != '' && isSandbox){
			URL_Parameter__c imageNow = [SELECT Name, URL_Value__c FROM URL_Parameter__c WHERE Name = 'ImageNow Host'];
			imageNow.URL_Value__c = imageNowURL;
			update imageNow;
		}
	}

	//update Custom Setting: a10i0000000575O Rename all https://rally1.rallydev.com to https://sandbox.rallydev.com
	public void updateRallySettings(){
		rallyUpdated = false;
		Rally_Integration_Callout_Settings__c rally = [SELECT Upsert_Endpoint__c, Users_EndPoint__c, Fetch_Endpoint__c, Workspace__c FROM Rally_Integration_Callout_Settings__c WHERE Name = 'Rally'];
		
		rally.Upsert_Endpoint__c = rally.Upsert_Endpoint__c.replaceAll('https://rally1.rallydev.com', 'https://sandbox.rallydev.com');
		rally.Users_EndPoint__c = rally.Users_EndPoint__c.replaceAll('https://rally1.rallydev.com', 'https://sandbox.rallydev.com');
		rally.Fetch_Endpoint__c = rally.Fetch_Endpoint__c.replaceAll('https://rally1.rallydev.com', 'https://sandbox.rallydev.com');
		rally.Workspace__c = rally.Workspace__c.replaceAll('https://rally1.rallydev.com', 'https://sandbox.rallydev.com');

		try{
			update rally;
			rallyUpdated = true;
		}
		catch(exception e){
			System.debug(e);
		}
	}

	public void abortJobs(){
		
		jobsAborted = 0;
		
			if(isSandbox){
				
				//get all scheduled Jobs
				List<CronTrigger> jobs = [SELECT Id, CronJobDetail.JobType FROM CronTrigger];
				//loop through all scheduled jobs
				for(CronTrigger ct : jobs){
					//if the JobType == '7', then it is scheduled apex. Abort all jobs that do not have a JobType == '7' 
					if (ct.CronJobDetail.JobType != '7'){
						System.abortJob(ct.Id);
						jobsAborted = jobsAborted + 1;
					}
				}
			}
		
	}
	
}