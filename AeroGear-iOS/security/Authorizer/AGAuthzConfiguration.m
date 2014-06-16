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

#import "AGAuthzConfiguration.h"

@implementation AGAuthzConfiguration

// private getters...
@synthesize baseURL = _baseURL;
@synthesize authzEndpoint = _authzEndpoint;
@synthesize accessTokenEndpoint = _accessTokenEndpoint;
@synthesize revokeTokenEndpoint = _revokeTokenEndpoint;
@synthesize redirectURL = _redirectURL;
@synthesize scopes = _scopes;
@synthesize clientId = _clientId;
@synthesize clientSecret = _clienSecret;
@synthesize timeout = _timeout;
@synthesize accountId = _accountId;

@synthesize name = _name;
@synthesize type = _type;

- (NSString *)authzEndpoint {
    return [self trimTrailingSlash:_authzEndpoint];
}

- (NSString *)accessTokenEndpoint {
    return [self trimTrailingSlash:_accessTokenEndpoint];
}

- (NSString *)revokeTokenEndpoint {
    return [self trimTrailingSlash:_revokeTokenEndpoint];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // default values:
        _type = @"AG_OAUTH2";
        _authzEndpoint = @"oauth2/auth";
        _accessTokenEndpoint = @"oauth2/access/codes";
        _revokeTokenEndpoint =@"oauth2/revoke";
        _redirectURL = @"myURL";
        _scopes = @[@"email"];
        _timeout = 60; // the default timeout interval of NSMutableURLRequest (60 secs)
    }
    
    return self;
}

- (NSString *)trimTrailingSlash:(NSString *)endpoint {
    if (!endpoint)
        return nil;
    
    NSString* correctlyFormattedTokenEndpoint = endpoint;
    if ([correctlyFormattedTokenEndpoint hasPrefix:@"/"]) {
        correctlyFormattedTokenEndpoint = [correctlyFormattedTokenEndpoint substringFromIndex:1];
    }
    
    return correctlyFormattedTokenEndpoint;
}

@end
