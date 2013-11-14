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

#import "AGPassPhraseCryptoConfig.h"

@implementation AGPassPhraseCryptoConfig

@synthesize name = _name;
@synthesize type = _type;

@synthesize passphrase = _passphrase;
@synthesize salt = _salt;

- (id)init {
    self = [super init];
    if (self) {
        _type = @"AGPassPhraseCryptoConfig";
        #if TARGET_IPHONE_SIMULATOR
            _name = @"name";
        #else
            _name = [[NSBundle mainBundle] bundleIdentifier];
        #endif
    }
    
    return self;
}

@end
