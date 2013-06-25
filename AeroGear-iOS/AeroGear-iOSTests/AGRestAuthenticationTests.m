/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <SenTestingKit/SenTestingKit.h>
#import "AGHTTPMockHelper.h"

#import "AGRestAuthentication.h"
#import "AGAuthConfiguration.h"
#import "AGPipeline.h"

static NSString *const PASSING_USERNAME = @"john";
static NSString *const FAILING_USERNAME = @"fail";

static NSString *const LOGIN_PASSWORD = @"passwd";
static NSString *const ENROLL_PASSWORD = @"passwd";

static NSString *const LOGIN_SUCCESS_RESPONSE =  @"{\"username\":\"%@\",\"roles\":[\"admin\"]}";

@interface AGRestAuthenticationTests : SenTestCase

@end

@implementation AGRestAuthenticationTests {
    BOOL _finishedFlag;
    
    id<AGPipe> _projects;
    
    AGRestAuthentication* _restAuthModule;
}

-(void)setUp {
    [super setUp];
    
    NSURL* baseURL = [NSURL URLWithString:@"https://server.com/context/"];
    
    // setup REST Authenticator
    AGAuthConfiguration* config = [[AGAuthConfiguration alloc] init];
    [config setBaseURL:baseURL];
    [config setEnrollEndpoint:@"auth/register"];
    [config setTimeout:1]; // this is just for testing of timeout methods
    
    _restAuthModule = [AGRestAuthentication moduleWithConfig:config];
    
    // setup Pipeline
    AGPipeline* pipeline = [AGPipeline pipelineWithBaseURL:baseURL];
    _projects = [pipeline pipe:^(id<AGPipeConfig> config) {
        [config setName:@"projects"];
        [config setAuthModule:_restAuthModule];
    }];
}

-(void)tearDown {
    // remove all handlers installed by test methods
    // to avoid any interference
    [AGHTTPMockHelper clearAllMockedRequests];
    
    [super tearDown];
}

-(void)testRestAuthenticationCreation {
    STAssertNotNil(_restAuthModule, @"module should not be nil");
}

-(void) testLoginSuccess {
    // install the mock:
    [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                    dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
        STAssertEqualObjects(PASSING_USERNAME, [responseObject valueForKey:@"username"], @"should be equal");
        
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should have login", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testLoginWithTimeout {
    // simulate delay in response
    // Note that pipe has been default configured for a timeout in 1 sec
    // here we simulate a delay of 2 sec
    
    // install the mock:
    [AGHTTPMockHelper mockResponseTimeout:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                           dataUsingEncoding:NSUTF8StringEncoding]
                                   status:200
                             responseTime:2]; // two secs delay
    
    [_restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
        STFail(@"%@", @"should NOT have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testLoginFails {
    [AGHTTPMockHelper mockResponseStatus:401];
    
    [_restAuthModule login:@{@"loginName": FAILING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
        STFail(@"should not work");
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testLogout {
    // install the mock:
    [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                    dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id object) {
        
        [_restAuthModule logout:^{
            _finishedFlag = YES;
            
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            STFail(@"wrong logout...");
        }];
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"wrong login");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testLogoutWithTimeout {
    // install the mock:
    [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                    dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id object) {
        
        // install the mock:
        [AGHTTPMockHelper mockResponseTimeout:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                               dataUsingEncoding:NSUTF8StringEncoding]
                                       status:200
                                 responseTime:2]; // two secs delay
        
        [_restAuthModule logout:^{
            STFail(@"%@", @"should NOT have been called");
            _finishedFlag = YES;
            
        } failure:^(NSError *error) {
            STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
            _finishedFlag = YES;
        }];
    } failure:^(NSError *error) {
        STFail(@"%@", @"should NOT have been called");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEnrollSuccess {
    // install the mock:
    [AGHTTPMockHelper mockResponse:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                    dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];
    
    [registerPayload setValue:@"John" forKey:@"firstname"];
    [registerPayload setValue:@"Doe" forKey:@"lastname"];
    [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
    [registerPayload setValue:PASSING_USERNAME forKey:@"username"];
    [registerPayload setValue:LOGIN_PASSWORD forKey:@"password"];
    [registerPayload setValue:@"admin" forKey:@"role"];
    
    [_restAuthModule enroll:registerPayload success:^(id responseObject) {
        STAssertEqualObjects(PASSING_USERNAME, [responseObject valueForKey:@"username"], @"should be equal");
        
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should have enroll", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEnrollTimeout {
    // simulate delay in response
    // Note that pipe has been default configured for a timeout in 1 sec
    // here we simulate a delay of 2 sec
    
    // install the mock:
    [AGHTTPMockHelper mockResponseTimeout:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                           dataUsingEncoding:NSUTF8StringEncoding]
                                   status:200
                             responseTime:2]; // two secs delay
    
    NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];
    
    [registerPayload setValue:@"John" forKey:@"firstname"];
    [registerPayload setValue:@"Doe" forKey:@"lastname"];
    [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
    [registerPayload setValue:PASSING_USERNAME forKey:@"username"];
    [registerPayload setValue:LOGIN_PASSWORD forKey:@"password"];
    [registerPayload setValue:@"admin" forKey:@"role"];
    
    
    [_restAuthModule enroll:registerPayload success:^(id responseObject) {
        
        STFail(@"%@", @"should NOT have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        
        STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEnrollFails {
    // Simulate 'Bad Request' status
    [AGHTTPMockHelper mockResponseStatus:400];
    
    NSMutableDictionary* registerPayload = [NSMutableDictionary dictionary];
    
    [registerPayload setValue:@"John" forKey:@"firstname"];
    [registerPayload setValue:@"Doe" forKey:@"lastname"];
    [registerPayload setValue:@"emaadsil@mssssse.com" forKey:@"email"];
    [registerPayload setValue:PASSING_USERNAME forKey:@"username"];
    [registerPayload setValue:LOGIN_PASSWORD forKey:@"password"];
    [registerPayload setValue:@"admin" forKey:@"role"];
    
    [_restAuthModule enroll:registerPayload success:^(id responseObject) {
        STFail(@"should not work");
        _finishedFlag = YES;
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testCancel {
    // install the mock:
    [AGHTTPMockHelper mockResponseTimeout:[[NSString stringWithFormat:LOGIN_SUCCESS_RESPONSE, PASSING_USERNAME]
                                           dataUsingEncoding:NSUTF8StringEncoding]
                                   status:200
                             responseTime:2]; // two secs delay
    
    [_restAuthModule login:@{@"loginName": PASSING_USERNAME, @"password": LOGIN_PASSWORD} success:^(id responseObject) {
        
        STFail(@"login should not have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        STAssertEquals(-999, [error code], @"should be equal to code -999 [request cancelled]");
        _finishedFlag = YES;
    }];
    
    // cancel the request
    [_restAuthModule cancel];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

@end