/**********************************************************************************************************************
* @Author:      Tirthankar (Capgemini COE)  
* @Date:        25/05/2020
* @Description: creates integration log records for each callout. part of integration framework.
***********************************************************************************************************************/
public without sharing class IntegrationLogGenerator {

    private static List<Integration_Log__c> integrationLogList = new List<Integration_Log__c>();
    public static boolean invokedFromFuture = false;
    private static Integration_Settings__mdt integrationSettings;
    //This Switch requires if multiple chain callout is being made in a single transaction.
    //Integration Log MUST be inserted after all the callout made to avoid DML exception.
    public static boolean onlyAddToList = false;

    /*******************************************************************************************************************
    * @Author:      Tirthankar (Capgemini COE)  
    * @Date:        25/05/2020
    * @Description: Method for populating integrationSettings
    ********************************************************************************************************************/
    private static void populateSettings(){
        //Populate Integration Settings option from custom meta data
        if(integrationSettings == null){            
            List<Integration_Settings__mdt> integrationSettingsList = [SELECT 
                                                                        Generate_Log__c
                                                                        FROM Integration_Settings__mdt];
            if(integrationSettingsList.size() > 0){
                integrationSettings = integrationSettingsList[0];
            }
        }
    }
    
    /*******************************************************************************************************************
    * @Author:      Tirthankar (Capgemini COE)  
    * @Date:        25/05/2020
    * @Description: creates integration log records for each callout
    * @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
    ********************************************************************************************************************/
    public static void generateIntegrationLog(String endpoint, String method, Map<String, String> headerParamsMap, String requestBody, Integer responseStatusCode, String responseStatus, String responseBody) {
        populateSettings();   
        if(!onlyAddToList){
            if((integrationSettings != null) && integrationSettings.Generate_Log__c){
                if(invokedFromFuture){
                    insertIntegrationLogRecord(endpoint, method, headerParamsMap, requestBody, responseStatusCode, responseStatus, responseBody);
                }else{
                    insertIntegrationLogRecordAsync(endpoint, method, headerParamsMap, requestBody, responseStatusCode, responseStatus, responseBody);
                }    
            }else{
                system.debug('Integration LOG --- '+ endpoint + ' : ' + method + ' : ' + requestBody + ' : ' + responseBody);
            }
        }
        else{
            pushIntegrationLogToList(endpoint, method, headerParamsMap, requestBody, responseStatusCode, responseStatus, responseBody);
        }
    }

    /************************************************************************************************************************************
    * @Author:      Tirthankar Dastidar  
    * @Date:        25/05/2020
    * @Description: this method logs the integration to a separate object in asynchronous way
    ************************************************************************************************************************************/
	@future
	private static void insertIntegrationLogRecordAsync(String endpoint, String method, Map<String, String> headerParamsMap, String requestBody, Integer responseStatusCode, String responseStatus, String responseBody){
        insertIntegrationLogRecord(endpoint, method, headerParamsMap, requestBody, responseStatusCode, responseStatus, responseBody);
	}

    /************************************************************************************************************************************
    * @Author:      Tirthankar Dastidar  
    * @Date:        25/05/2020
    * @Description: this method logs the integration to a separate object in synchronous way
    ************************************************************************************************************************************/
    private static void insertIntegrationLogRecord(String endpoint, String method, Map<String, String> headerParamsMap, String requestBody, Integer responseStatusCode, String responseStatus, String responseBody){
		try{
            pushIntegrationLogToList(endpoint, method, headerParamsMap, requestBody, responseStatusCode, responseStatus, responseBody);
            insertIntegrationLog();
		} catch(Exception e){
			system.debug('IntegrationLogGenerator - insertIntegrationLogRecord - ' + e.getMessage());
		}
    }
    
    /*******************************************************************************************************************
    * @Author:      Tirthankar (Capgemini COE)  
    * @Date:        25/05/2020
    * @Description: push variables into integration log list 
    ********************************************************************************************************************/
    private static void pushIntegrationLogToList(String endpoint, String method, Map<String, String> headerParamsMap, String requestBody, Integer responseStatusCode, String responseStatus, String responseBody){
        Integration_Log__c intLog = new Integration_Log__c();
        intLog.Endpoint__c = endpoint;
        intLog.Method__c = method;
        intLog.Headers__c = JSON.serialize(headerParamsMap);
        intLog.Request_Body__c = requestBody;   
        intLog.Status_Code__c = responseStatusCode;
        intLog.Status_Message__c = responseStatus;
        intLog.Response_Body__c = responseBody;
        if(responseStatusCode != 200){
            intLog.IsError__c = true;
        }
        integrationLogList.add(intLog);
    }   
    
    /************************************************************************************************************************************
    * @Author:      Tirthankar (Capgemini COE)  
    * @Date:        10/02/2019
    * @Description: invoke this method directly to insert pending integration logs (applicable wen async insert is not feasible)
    ************************************************************************************************************************************/
	public static void insertIntegrationLog(){
        if(!integrationLogList.isEmpty()){
            insert integrationLogList;
            integrationLogList.clear();
        } 
    }    
}