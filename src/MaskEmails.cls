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

	public static void mask(string e) {				

		//assign sandboxName to parameter passed in to the method call.
		sandboxName = e;

		//the list of sObjects we will update
		List<sObject> objectsToUpdate = new List<sObject>();		

		//loop through every sObjectType that is in our GlobalDescribe map.
		for (Schema.SObjectType objectType : GlobalDescribe.values()) {					
			
			//loop through every field for every sObject				
			for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {	

				//if the fieldType is email and the field is updateable, then update all the email fields with the sandboxName appended to the end.
				if (field.getDescribe().getType() == Schema.DisplayType.Email && field.getDescribe().isUpdateable()) {								

					//call the updateRecords method and pass string representations of the objectType API name and the field API name. 
					List<sObject> updated = changeEmails(String.valueOf(objectType), field.getDescribe().getName());	

					//if records were updated, add them to the objectsToUpdate list. 
					if(!updated.isEmpty()){

						objectsToUpdate.addAll(updated);
					}						
				}
			}		
		}

		//update all the records and allow for partial update
		database.update(objectsToUpdate, false);
	}

	private static List<sObject> changeEmails(String objectType, String field){

		//the list of objects we wil return
		List<sObject> returnObjects = new List<sObject>();

		//the list of objects returned by our query
		List<sObject> objects = new List<SObject>();

		//build query string with the field API name and the sObject API name.
		String query = 'SELECT ' + field + ' FROM ' + objectType + '';

		try {
		objects = Database.query(query);
		}
		catch (exception e) {
			system.debug(e);
			return null;
		}

		//check to see if the objects list is empty
		if(!objects.isEmpty()){

			//loop through every object that is returned from our query
			for (sObject obj : objects){

				//get the old email and cast it to a string.
				String email = (String) obj.get(field);

				if(email != null){

					//update the field. Append the sandboxName to the end of the old email.
					obj.put(field, '' + email + '' + sandboxName);

				 	//add the object to the return list
					returnObjects.add(obj);
					
				}
			}
		}
		
		return returnObjects;
	}

}