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

#import "PLSqliteResultSet.h"

@interface PLSqliteResultSetTests : SenTestCase {
@private
    PLSqliteDatabase *_db;
}

@end

@implementation PLSqliteResultSetTests

- (void) setUp {
    _db = [[PLSqliteDatabase alloc] initWithPath: @":memory:"];
    STAssertTrue([_db open], @"Couldn't open the test database");
}

- (void) tearDown {
    [_db release];
}

/* Test close by trying to rollback a transaction after opening (and closing) a result set. */
- (void) testClose {
    /* Start the transaction and create the test data */
    STAssertTrue([_db beginTransaction], @"Could not start a transaction");
    
    /* Create a result, move to the first row, and then close it */
    id<PLResultSet> result = [_db executeQuery: @"PRAGMA user_version"];
    [result next];
    [result close];

    /* Roll back the transaction */
    STAssertTrue([_db rollbackTransaction], @"Could not roll back, was result actually closed?");
}

/* Test block-based iteration of a result set */
- (void) testBlockIteration {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a int)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithInt: 1]]), @"Could not insert row");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithInt: 2]]), @"Could not insert row");

    NSError *error;
    result = [_db executeQuery: @"SELECT a FROM test"];
    __block NSInteger iterations = 0;
    BOOL success = [result enumerateAndReturnError: &error block: ^(id<PLResultSet> rs, BOOL *stop) {
        STAssertEquals(1, [rs intForColumn: @"a"], @"Did not return correct date value");
        iterations++;
        *stop = YES;
    }];

    STAssertTrue(success, @"Did not iterate successfully: %@", error);
    STAssertEquals((NSInteger)1, iterations, @"Did not stop when requested");

    [result close];
}

/*
 * Test the implicit completion close behavior of block-based iteration
 */
- (void) testBlockEnumerationCompletionClosure {
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a int)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithInt: 1]]), @"Could not insert row");

    /* Enumerate the table */
    NSError *error;
    PLSqliteResultSet *rs = [_db executeQueryAndReturnError: &error statement: @"SELECT a FROM test"];
    STAssertNotNil(rs, @"Failed to parse query: %@", error);

    BOOL success = [rs enumerateAndReturnError: &error block: ^(id <PLResultSet> rs, BOOL *stop) {}];
    STAssertTrue(success, @"Did not iterate successfully: %@", error);
    
    /* Assert that the result set was closed */
    STAssertTrue(rs.isClosed, @"Result set was not closed");
    
    /* Verify that the result set is not closed if *stop is set, even if all rows are enumerated */
    rs = [_db executeQueryAndReturnError: &error statement: @"SELECT a FROM test"];
    success = [rs enumerateAndReturnError: &error block:^(id <PLResultSet> rs, BOOL *stop) {
        *stop = YES;
    }];
    
    STAssertTrue(success, @"Did not iterate successfully: %@", error);
    STAssertFalse(rs.isClosed, @"Result set was closed");
    [rs close];
}

/*
 * Test the implicit close behavior of block-based iteration when an error occurs.
 */
- (void) testBlockEnumerationErrorClosure {
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a int NOT NULL)"], @"Create table failed");
    
    /* Perform error-inducing enumeration by triggering a constraint error. */
    NSError *error;
    PLSqliteResultSet *rs = [_db executeQueryAndReturnError: &error statement: @"INSERT INTO test (a) VALUES (NULL)"];
    STAssertNotNil(rs, @"Failed to parse query: %@", error);
    
    BOOL success = [rs enumerateAndReturnError: &error block: ^(id <PLResultSet> rs, BOOL *stop) {}];
    STAssertFalse(success, @"Executing the query did not trigger a constraint error");
    
    /* Assert that the result set was closed */
    STAssertTrue(rs.isClosed, @"Result set was not closed on error");
}

- (void) testNextErrorHandling {
    NSError *error;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a int NOT NULL)"], @"Create table failed");

    /* Trigger an error by inserting NULL data into NOT NULL column. */
    id<PLResultSet> result = [_db executeQuery: @"INSERT INTO test VALUES (NULL)"];
    STAssertNotNil(result, @"Failed to execute query");

    STAssertEquals(PLResultSetStatusError, [result nextAndReturnError: &error], @"Result set did not return an error");
    
    [result close];
}


- (void) testColumnIndexForName {
    id<PLResultSet> result = [_db executeQuery: @"PRAGMA user_version"];
    STAssertEquals(0, [result columnIndexForName: @"user_version"], @"user_version column not found");
    STAssertEquals(0, [result columnIndexForName: @"USER_VERSION"], @"Column index lookup appears to be case sensitive.");

    STAssertThrows([result columnIndexForName: @"not_a_column"], @"Did not throw an exception for bad column");

    [result close];
}

- (void) testDateForColumn {
    id<PLResultSet> result;
    NSDate *now = [NSDate date];
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a date)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", now]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertEquals([now timeIntervalSince1970], [[result dateForColumn: @"a"] timeIntervalSince1970], @"Did not return correct date value");
    
    [result close];
}

- (void) testStringForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a varchar(30))"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", @"TestString"]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertTrue([@"TestString" isEqual: [result stringForColumn: @"a"]], @"Did not return correct string value");
    
    [result close];
}

- (void) testIntForColumn {
    id<PLResultSet> result = [_db executeQuery: @"PRAGMA user_version"];
    STAssertNotNil(result, @"No result returned from query");
    STAssertTrue([result next], @"No rows were returned");
    
    STAssertEquals(0, [result intForColumn: @"user_version"], @"Could not retrieve user_version column");

    [result close];
}

- (void) testBigIntForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a bigint)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithLongLong: INT64_MAX]]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertEquals(INT64_MAX, [result bigIntForColumn: @"a"], @"Did not return correct big integer value");
    
    [result close];
}

- (void) testBoolForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a bool)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithBool: YES]]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertTrue([result boolForColumn: @"a"], @"Did not return correct bool value");
    
    [result close];
}

- (void) testFloatForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a float)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithFloat: 3.14]]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertEquals(3.14f, [result floatForColumn: @"a"], @"Did not return correct float value");
    
    [result close];
}

- (void) testDoubleForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a double)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", [NSNumber numberWithDouble: 3.14159]]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertEquals(3.14159, [result doubleForColumn: @"a"], @"Did not return correct double value");
    
    [result close];
}

- (void) testDataForColumn {
    const char bytes[] = "This is some example test data";
    NSData *data = [NSData dataWithBytes: bytes length: sizeof(bytes)];
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a blob)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", data]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertTrue([data isEqualToData: [result dataForColumn: @"a"]], @"Did not return correct data value");
    
    [result close];
}

- (void) testIsNullForColumn {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a integer)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", nil]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    STAssertEquals(0, [result intForColumn: @"a"], @"NULL column should return 0");
    STAssertTrue([result isNullForColumn: @"a"], @"Column value should be NULL");
    
    [result close];
}

/* Test that dereferencing a null value returns a proper default 0 value */
- (void) testNullValueHandling {
    id<PLResultSet> result;
    
    STAssertTrue([_db executeUpdate: @"CREATE TABLE test (a integer)"], @"Create table failed");
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a) VALUES (?)", nil]), @"Could not insert row");
    
    result = [_db executeQuery: @"SELECT a FROM test"];
    STAssertTrue([result next], @"No rows returned");
    
    STAssertEquals(0, [result intForColumn: @"a"], @"Expected 0 value");
    STAssertEquals((int64_t)0, [result bigIntForColumn: @"a"], @"Expected 0 value");
    STAssertEquals(0.0f, [result floatForColumn: @"a"], @"Expected 0 value");
    STAssertEquals(0.0, [result doubleForColumn: @"a"], @"Expected 0 value");
    STAssertEquals(NO, [result boolForColumn: @"a"], @"Expected 0 value");
    STAssertTrue([result stringForColumn: @"a"] == nil, @"Expected nil value");
    STAssertTrue([result dateForColumn: @"a"] == nil, @"Expected nil value");
    STAssertTrue([result dataForColumn: @"a"] == nil, @"Expected nil value");
    STAssertTrue([result objectForColumn: @"a"] == nil, @"Expected nil value");

    [result close];
}

- (void) testObjectForColumn {
    id<PLResultSet> result;
    NSNumber *testInteger;
    NSString *testString;
    NSNumber *testDouble;
    NSData *testBlob;
    NSError *error;
    
    /* Initialize test data */
    testInteger = [NSNumber numberWithInt: 42];
    testString = @"Test string";
    testDouble = [NSNumber numberWithDouble: 42.42];
    testBlob = [@"Test data" dataUsingEncoding: NSUTF8StringEncoding]; 

    STAssertTrue([_db executeUpdateAndReturnError: &error statement: @"CREATE TABLE test (a integer, b varchar(20), c double, d blob, e varchar(20))"], @"Create table failed: %@", error);
    STAssertTrue(([_db executeUpdate: @"INSERT INTO test (a, b, c, d, e) VALUES (?, ?, ?, ?, ?)",
                   testInteger, testString, testDouble, testBlob, nil]), @"Could not insert row");
    
    /* Query the data */
    result = [_db executeQuery: @"SELECT * FROM test"];
    STAssertTrue([result next], @"No rows returned");
    
    STAssertTrue([testInteger isEqual: [result objectForColumn: @"a"]], @"Did not return correct integer value");
    STAssertTrue([testString isEqual: [result objectForColumn: @"b"]], @"Did not return correct string value");
    STAssertTrue([testDouble isEqual: [result objectForColumn: @"c"]], @"Did not return correct double value");
    STAssertTrue([testBlob isEqual: [result objectForColumn: @"d"]], @"Did not return correct data value");
    STAssertTrue(nil == [result objectForColumn: @"e"], @"Did not return correct NSNull value");
    
    [result close];
}

@end
