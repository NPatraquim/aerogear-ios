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

#import "AGHttpClient.h"
#import "AGMultipart.h"

@implementation AGHttpClient

+ (instancetype)clientFor:(NSURL *)url {
    return [[[self class] alloc] initWithBaseURL:url timeout:60 sessionConfiguration:nil];
}

+ (instancetype)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval {
    return [[[self class] alloc] initWithBaseURL:url timeout:interval sessionConfiguration:nil];
}

+ (instancetype)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [[[self class] alloc] initWithBaseURL:url timeout:interval sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url timeout:(NSTimeInterval)interval
        sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];

    if (!self) {
        return nil;
    }

    // initialize with JSON request/response serializers
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];

    // set the timeout interval
    self.requestSerializer.timeoutInterval = interval;

    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    return (self);
}

#pragma mark - AFHTTPSessionManager override

// override to construct a multipart request if required by the params passed in
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {

    return [self processRequestWithMethod:@"POST" URLString:URLString parameters:parameters success:success failure:failure];

}

// override to construct a multipart request if required by the params passed in
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {

    return [self processRequestWithMethod:@"PUT" URLString:URLString parameters:parameters success:success failure:failure];
}

#pragma mark - utility methods

- (NSURLSessionDataTask *)processRequestWithMethod:(NSString *)method
                                         URLString:(NSString *)URLString
                                        parameters:(NSDictionary *)parameters
                                           success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    __block NSURLSessionDataTask *task;

    // let's define up-front the completion callback since it's common
    id completionCallback = ^(NSURLSessionDataTask *task, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
    };

    if ([self hasMultipartData:parameters]) {
        NSError *error = nil;

        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:method
                                                                       path:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                                 parameters:parameters error:&error];

        // if there was an error during multipart processing
        // or in the construction of request
        if (error) {
            failure(nil, error);
            return nil;
        }

        [self applyAuthTokensOnRequest:request];

        task = [self uploadTaskWithStreamedRequest:request progress:nil completionHandler:completionCallback];

    } else {

        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method
                                                                       URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                                      parameters:parameters error:nil];

        [self applyAuthTokensOnRequest:request];

        task = [self dataTaskWithRequest:request completionHandler:completionCallback];
    }

    [task resume];

    return task;
}

// construct a multi-part request
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError **) error {

    NSMutableURLRequest *req;

    // extract multipart data;
    NSMutableDictionary *parts = [[NSMutableDictionary alloc] init];

    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)]) {
            // add it
            parts[key] = obj;
        }  else if ([obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            obj = [[AGFilePart alloc] initWithFileURL:obj name:key];
            parts[key] = obj;
        }
    }];

    // cater for AFNetworking default behaviour to call [object description]
    // for parameters other than NSData and NSNull. We need to filter
    // AGMultipart objects from the request and apply them in the block later on
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params removeObjectsForKeys:[parts allKeys]];

    // will hold any error that occurs during multipart add
    __block NSError *err;

    req = [self.requestSerializer multipartFormRequestWithMethod:method URLString:path parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {

        [parts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[AGFilePart class]]) {
                AGFilePart *part = (AGFilePart *) obj;
                [formData appendPartWithFileURL:part.fileURL
                                           name:part.name
                                          error:&err];

                // if there was any error adding the
                // file stop immediately
                if (err)
                    *stop = YES;

            } else if ([obj isKindOfClass:[AGFileDataPart class]]) {
                AGFileDataPart *part = (AGFileDataPart *) obj;

                [formData appendPartWithFileData:part.data
                                            name:part.name
                                        fileName:part.fileName
                                        mimeType:part.mimeType];

            } else if ([obj isKindOfClass:[AGStreamPart class]]) {
                AGStreamPart *part = (AGStreamPart *) obj;

                [formData appendPartWithInputStream:part.inputStream
                                               name:part.name
                                           fileName:part.fileName
                                             length:part.length
                                           mimeType:part.mimeType];
            }
        }];
    } error:error];

    if (err) { // if there was error adding multipart
        *error = err;
        return nil;
    }

    return req;
}

// check if any file objects(if any) are embedded in the params
- (BOOL)hasMultipartData:(NSDictionary *)parameters {
    __block BOOL hasMultipart = NO;

    [[parameters allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)] ||
                [obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            hasMultipart = YES;
            *stop = YES; // no need to continue further
        }
    }];

    return hasMultipart;
}

// apply auth/authz headers (if any) on request
- (void)applyAuthTokensOnRequest:(NSMutableURLRequest *)request {
    NSDictionary *headers;

    if (_authModule && [_authModule isAuthenticated]) {
        headers = [_authModule authTokens];
    } else if (_authzModule && [_authzModule isAuthorized]) {
        headers = [_authzModule accessTokens];
    }

    // apply them
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id name, id value, BOOL *stop) {
            [request setValue:value forHTTPHeaderField:name];
        }];
    }
}

@end