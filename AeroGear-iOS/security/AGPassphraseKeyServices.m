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

#import "AGPassphraseKeyServices.h"

#import <AGPBKDF2.h>
#import <AGSecretBox.h>

@implementation AGPassphraseKeyServices

- (id)initWithConfig:(AGPassphraseCryptoConfig *)config {
    self = [super init];
    
    if (self) {
        AGPBKDF2 *keyGenerator = [[AGPBKDF2 alloc] init];
        
        // derive key
        NSData *key = [keyGenerator deriveKey:config.passphrase salt:config.salt];
        
        // initialize cryptobox
        _secretBox = [[AGSecretBox alloc] initWithKey:key];
    }
    
    return self;
}

@end
