
@isTest
public class IntegrationLogGeneratorTest {
    
    @isTest
    //Standard Integration Log operation
    // Call the IntegrationLogGenerator after response is being recieved with request and response.
    public static void integrationLogTestSync(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockResponseIntegrationTest());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://integrationCOEPoint.com/testEndPoint');
        request.setHeader('responseType', 'INITIAL');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        IntegrationLogGenerator.generateIntegrationLog(request, response,
                                                        new Map<string, string>{'responseType'=> request.getHeader('responseType')}
                                                         );        
        Test.stopTest();
        Integer logCount = [SELECT count() FROM Integration_Log__c ];
        System.assertEquals(1, logCount, 'One Integration Log is created');
        Boolean isError = [SELECT IsError__c FROM Integration_Log__c][0].IsError__c;
        System.assertEquals(false, isError, 'Is Error is false for Correct Response');
    }

    @isTest
    // Contunuation Integration Log operation
    //Logging in between two integration callout will throw exception. Here, the records need to be stacked.
    // Call the IntegrationLogGenerator after response is being recieved with request and response.
    public static void integrationLogTestContinuation(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockResponseIntegrationTest());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://integrationCOEPoint.com/testEndPoint');
        request.setHeader('responseType', 'INITIAL');
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        IntegrationLogGenerator.onlyAddToList = true;
        IntegrationLogGenerator.generateIntegrationLog(request, response,
                                                        new Map<string, string>{'responseType'=> request.getHeader('responseType')}
                                                         );
        
        Http httpNew = new Http();
        HttpRequest requestNew = new HttpRequest();
        requestNew.setEndpoint('https://integrationCOEPoint.com/testEndPoint2');
        requestNew.setHeader('responseType', 'MORE');
        requestNew.setMethod('POST');
        requestNew.setBody('request Body');
        HttpResponse responseNew = http.send(requestNew);
        IntegrationLogGenerator.onlyAddToList = false;
        IntegrationLogGenerator.generateIntegrationLog(requestNew, responseNew,
                                                        new Map<string, string>{'responseType'=> requestNew.getHeader('responseType')}
                                                         );                                                 
        Test.stopTest();
        Integer logCount = [SELECT count() FROM Integration_Log__c ];
        System.assertEquals(2, logCount, 'Two Integration Log is created');
    }

    @isTest
    // Log Integration payload when callout is made at Async mode i.e. future call
    // Since Integration Log is created at async mode, in the async mode log should be created in sync
    // Set invokedFromFuture = true to create integration log in sync
    public static void integrationLogTestAsync(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockResponseIntegrationTest());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://integrationCOEPoint.com/testEndPoint');
        request.setHeader('responseType', 'INITIAL');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        IntegrationLogGenerator.invokedFromFuture = true;
        IntegrationLogGenerator.generateIntegrationLog(request, response,
                                                        new Map<string, string>{'responseType'=> request.getHeader('responseType')}
                                                         );        
        Test.stopTest();
        Integer logCount = [SELECT count() FROM Integration_Log__c ];
        System.assertEquals(1, logCount, 'One Integration Log is created');
        Boolean isError = [SELECT IsError__c FROM Integration_Log__c][0].IsError__c;
        System.assertEquals(false, isError, 'Is Error is false for Correct Response');
    }

    @isTest
    public static void integrationLogTestError(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockResponseIntegrationTest());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://integrationCOEPoint.com/testEndPoint');
        request.setHeader('responseType', 'ERROR');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        IntegrationLogGenerator.generateIntegrationLog(request, response,
                                                        new Map<string, string>{'responseType'=> request.getHeader('responseType')}
                                                         );        
        Test.stopTest();
        Integer logCount = [SELECT count() FROM Integration_Log__c ];
        System.assertEquals(1, logCount, 'One Integration Log is created');
        Boolean isError = [SELECT IsError__c FROM Integration_Log__c][0].IsError__c;
        System.assertEquals(true, isError, 'Is Error is true for Error Response');
    }

    private class HttpMockResponseIntegrationTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            if(req.getHeader('responseType') == 'ERROR'){
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Test Integration":"www.testIntegration.com", "Response" : "Fail"}');
                res.setStatusCode(501);
                return res;
            }else if(req.getHeader('responseType') == 'MORE'){
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Test Integration":"www.testIntegration.com", "Response" : "More"}');
                res.setStatusCode(200);
                return res;
            }else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Test Integration":"www.testIntegration.com", "Response" : "Pass"}');
                res.setStatusCode(200);
                return res;
            }            
        }
    }
}
