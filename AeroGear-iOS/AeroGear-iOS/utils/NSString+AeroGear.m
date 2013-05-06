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

#import "NSString+AeroGear.h"

@implementation NSString (AeroGear)

-(NSDictionary *) transformQueryString {
    // we need to get rid of the '?' and everything before that (if present)
    NSRange range = [self rangeOfString:@"?"];

    NSString *value;
    
    if (range.location != NSNotFound) {
        value = [self substringFromIndex:NSMaxRange(range)];
    } else {
        value = self;
    }
    
    // chop the query string into a dictionary
    NSArray *components = [value componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    for (NSString *component in components) {
        [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:1] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:0]];
    }
    return parameters;
}

@end
