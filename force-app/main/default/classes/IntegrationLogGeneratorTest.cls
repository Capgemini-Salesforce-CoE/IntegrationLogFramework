
@isTest
public class IntegrationLogGeneratorTest {
    
    @isTest
    public static void integrationLogTestSync(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockResponseIntegrationTest());
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://integrationCOEPoint.com/testEndPoint');
        request.setHeader('responseType', 'INITIAL');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        IntegrationLogGenerator.generateIntegrationLog(request.getEndpoint(), request.getMethod(),
                                                         new Map<string, string>{'responseType'=> request.getHeader('responseType')},
                                                         '', response.getStatusCode(), response.getStatus(), 
                                                         response.getBody());        
        Test.stopTest();
        Integer logCount = [SELECT count() FROM Integration_Log__c ];
        System.assertEquals(1, logCount, 'One Integration Log is created');
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
