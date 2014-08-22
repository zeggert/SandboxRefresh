/*
***How to Execute in code***
MaskEmails.mask('.qa'); 

or
MaskEmails.mask('.dev');

or whatever else you want to mask the emails with.
*/

public with sharing class MaskEmails {

	//creates a map for every object in the database with the API names as search the search terms and Schema.SObjectType as the return values
	private static final Map<String, Schema.SObjectType> GlobalDescribe = Schema.getGlobalDescribe();

	//the string that we will append to the end of all the emails
	private static string sandboxName;	
	
	//contructor
	public MaskEmails(){
		
	}

	public static integer mask(string e) {				

		//assign sandboxName to parameter passed in to the method call.
		sandboxName = e;
		//the list of sObjects we will update
		List<sObject> objectsToUpdate = new List<sObject>();		
		System.debug('Update List: ' + objectsToUpdate);
		//loop through every sObjectType that is in our GlobalDescribe map.
		for (Schema.SObjectType objectType : GlobalDescribe.values()) {		

			//hard coding Contact objectType because I get an error when I try to search all objectTypes for email fields. 
			if(objectType.getDescribe().isUpdateable() && objectType.getDescribe().isQueryable() && String.valueOf(objectType) == 'Contact'){			
				List<String> emailFields = new List<String>();
				Set<sObject> updated = new Set<sObject>();
				System.debug('Updated: ' + updated);
				//loop through every field for every sObject				
				for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {	

					//if the fieldType is email and the field is updateable, then update all the email fields with the sandboxName appended to the end.
					if (field.getDescribe().getType() == Schema.DisplayType.Email && field.getDescribe().isUpdateable()) {								
						emailFields.add(field.getDescribe().getName());
					}
				}

				if(!emailFields.isEmpty()){
					//call the updateRecords method and pass string representations of the objectType API name and the field API name. 
					updated = changeEmails(String.valueOf(objectType), emailFields);	
					System.debug('Updated: ' + updated);

					//if records were updated, add them to the objectsToUpdate list. 
					if(!updated.isEmpty()){
						//if(objectsToUpdate.size() < 10){
							//List<sObject> objects = new List<sObject>();

							System.debug('objectsToUpdate: ' + objectsToUpdate);
							//objects.addAll(updated);
							objectsToUpdate.addAll(updated);
							//System.debug('Added ' + objects + ' to the update list');
							System.debug('objectsToUpdate: ' + objectsToUpdate);
						//}
					}						
				}
			}					
		}		
		System.debug('Update List: ' + objectsToUpdate);
		//update all the records and allow for partial update
		//for (integer i = 0; i<objectsToUpdate.size(); i++){
		//	database.update(objectsToUpdate[i], false);
		//}
		
		database.update(objectsToUpdate, false);
		System.debug('Size: ' + objectsToUpdate.size());
		return objectsToUpdate.size();
	}

	private static Set<sObject> changeEmails(String objectType, List<String> fields){

		//the list of objects we wil returnS
		Set<sObject> returnObjects = new Set<sObject>();

		//the list of objects returned by our query
		List<sObject> objects = new List<SObject>();		

		//build query string with the field API names and the sObject API name.
		String query = 'SELECT ';
		integer count = 0;
		for(String field : fields){
			if(count == 0){
				query = query + '' + field;
			}
			else {
				query = query + ', ' + field;
			}
			count ++;
		}

		query = query  + ' FROM ' + objectType + ' WHERE ';
		count = 0;
		//create search filters for query. Only want objects where the field is not null and does not already have the sandboxName masking it.
		for(String field : fields){

			if(count == 0){
				query = query + '( ' + field + '!=null AND (NOT ' + field + ' like \'%' + sandboxName + '\'))';
			}
			else{
				query = query + ' OR ( ' + field + '!=null AND (NOT ' + field + ' like \'%' + sandboxName + '\'))';
			}
			count ++;
		}
		system.debug(query);
		try {
		objects = Database.query(query);		
		}
		catch (exception e) {			
			system.debug(e);
			return null;
		}

		//check to see if the objects list is empty
		if(!objects.isEmpty()){
			System.debug('Objects: ' + objects);
			//loop through every object that is returned from our query
			for (sObject obj : objects){
				boolean updated = false;
				for(String field : fields){
					//get the old email and cast it to a string.
					String email = (String) obj.get(field);
					System.debug(field + ': ' + email);

					if(email != null){

						//update the field. Append the sandboxName to the end of the old email.
						try{
							obj.put(field, '' + email + '' + sandboxName);
					 		updated = true;
					 	} 
					 	catch (exception ex){
					 		System.debug(ex);
					 	}				
					}
				}
			//add the object to the return list
				if((!returnObjects.contains(obj)) && updated) {
					returnObjects.add(obj);
					System.debug('Added ' + obj + ' to the list');
				}
			}
		}
		
		return returnObjects;
	}

}