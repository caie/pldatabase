/*
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


#import <SenTestingKit/SenTestingKit.h>

#import "PlausibleDatabase.h"

@interface PlausibleDatabaseTests : SenTestCase {
@private
}

@end

@implementation PlausibleDatabaseTests

/* Test NSError creation */
- (void) testDatabaseError {
    NSError *error = [PlausibleDatabase errorWithCode: PLDatabaseErrorFileNotFound 
                                 localizedDescription: @"test"
                                          queryString: @"query"
                                          vendorError: [NSNumber numberWithInt: 42]
                                    vendorErrorString: @"native"];

    STAssertTrue([PLDatabaseErrorDomain isEqual: [error domain]], @"Domain incorrect");
    STAssertEquals(PLDatabaseErrorFileNotFound, [error code], @"Code incorrect");
    STAssertTrue([@"test" isEqual: [error localizedDescription]], @"Description incorrect");

    STAssertTrue([@"query" isEqual: [[error userInfo] objectForKey: PLDatabaseErrorQueryStringKey]], @"Query string incorrect");
    
    STAssertEquals(42, [[[error userInfo] objectForKey: PLDatabaseErrorVendorErrorKey] intValue], @"Native error code incorrect");
    STAssertTrue([@"native" isEqual: [[error userInfo] objectForKey: PLDatabaseErrorVendorStringKey]], @"Native error string incorrect");
}

@end