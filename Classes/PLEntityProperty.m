/*
 * Copyright (c) 2008 Plausible Labs.
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

#import "PlausibleDatabase.h"

/*
 * @name Property Options
 * @{
 */

/** If present, the property is considered a primary key value. */
NSString *PLEntityPAPrimaryKey = @"PLEntityPAPrimaryKey";

/** If present, the value will be considered generated. */
NSString *PLEntityPAGenerated = @"PLEntityPAGenerated";

/*
 * @} Property Options
 */

/**
 * Represents a single database column.
 *
 * @par Thread Safety
 * PLEntityProperty instances are immutable, and may be shared between threads
 * without synchronization.
 */
@implementation PLEntityProperty

/**
 * Create and return a description with the provided Key Value Coding key and
 * database column name.
 *
 * @param key KVC key used to access the column value.
 * @param columnName The corresponding database column.

 */
+ (id) propertyWithKey: (NSString *) key columnName: (NSString *) columnName {
    return [PLEntityProperty propertyWithKey: key columnName: columnName isPrimaryKey: NO];
}


/**
 * Create and return a description with the provided Key Value Coding key and
 * database column name.
 *
 * @param key KVC key used to access the column value.
 * @param columnName The corresponding database column.
 * @param primaryKey YES if the property comprises the object's primary key.
 */
+ (id) propertyWithKey: (NSString *) key columnName: (NSString *) columnName isPrimaryKey: (BOOL) primaryKey {
    return [[[PLEntityProperty alloc] initWithKey: key columnName: columnName isPrimaryKey: primaryKey] autorelease];
}

/**
 * @internal
 */
- (id) initWithKey: (NSString *) key columnName: (NSString *) columnName option: (NSString *) firstOption optionsv: (va_list) optionsv {
    NSString *option = firstOption;

    for (option = firstOption; option != nil; option = va_arg(optionsv, id)) {
        NSLog(@"GOT OPTION %@\n", option);
    }

    return nil;
}

/**
 * Create and return a description with the provided Key Value Coding key and
 * database column name.
 *
 * @param key KVC key used to access the column value.
 * @param columnName The corresponding database column.
 */
+ (id) propertyWithKey: (NSString *) key columnName: (NSString *) columnName options: (NSString *) firstOption, ... {
    PLEntityProperty *ret;
    va_list args;

    va_start(args, firstOption);
    ret = [[[PLEntityProperty alloc] initWithKey: key columnName: columnName option: firstOption optionsv: args] autorelease];
    va_end(args);

    return ret;
}


/**
 * Initialize with the Key Value Coding key and database column name.
 *
 * @param key KVC key used to access the column value.
 * @param columnName The corresponding database column.
 * @param primaryKey YES if the property comprises the object's primary key.
 *
 * @par Designated Initializer
 * This method is the designated initializer for the PLEntityProperty class.
 */
- (id) initWithKey: (NSString *) key columnName: (NSString *) columnName isPrimaryKey: (BOOL) primaryKey {
    if ((self = [super init]) == nil)
        return nil;

    _key = [key retain];
    _columnName = [columnName retain];
    _primaryKey = primaryKey;
    
    return self;
}

- (void) dealloc {
    [_key release];
    [_columnName release];

    [super dealloc];
}

@end

/**
 * @internal
 * Private library methods.
 */
@implementation PLEntityProperty (PLEntityPropertyDescriptionLibraryPrivate)

/**
 * Return the the property's key.
 */
- (NSString *) key {
    return _key;
}


/**
 * Return the database column name.
 */
- (NSString *) columnName {
    return _columnName;
}

/**
 * Return YES if the property is part of the table's primary key.
 */
- (BOOL) isPrimaryKey {
    return _primaryKey;
}


@end