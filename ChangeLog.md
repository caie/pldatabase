#### 1.1.1 (11-23-2008) ####

- Same-day minor release to fix build issues with newly released Xcode 3.1.2 ([Issue #7](https://code.google.com/p/pldatabase/issues/detail?id=#7))

#### 1.1 (11-23-2008) ####

- Promoted 1.1-RC2 to final 1.1 release.

#### 1.1-RC2 (10-29-2008) ####

- Fixed [issue #6](https://code.google.com/p/pldatabase/issues/detail?id=#6) from trunk: `-[PLSqliteDatabase executeUpdate:]` methods do not explicitly close the autoreleased statement

#### 1.0.1 (8-01-2008) ####

- Backported a fix from trunk for `-[PLSqliteResultSet close]`. Ensures that close calls sqlite3\_finalize() only once (either at release time, or when close is called manually).

#### 1.1-RC1 (6-13-2008) ####

- Added `-[PLResultSet objectForColumn:]`, returning column values as a Foundation data-type.

- Added PLPreparedStatement, with support for pre-compiled statements, named parameter binding, and positional parameter binding.

- Added an explicit `-[PLDatabase close]` method, to support timely resource release in a GC environment.

- Documented library error handling and thread-safety guidelines.

#### 1.0 (6-13-2008) ####

Released RC1 as the final 1.0 release.

#### 1.0-RC1 (5-19-2008) ####

It is highly recommended that all users update to the release candidate.

- Fixed a bug in string encoding handling in PLSqliteResultSet, which may have resulted in  `-[PLResultSet stringForColumn:]` returning invalid strings due to a buffer over-read. Thanks to Paul Phillips for reporting this ([Issue #2](https://code.google.com/p/pldatabase/issues/detail?id=#2)).

No further API changes or features will be added to the 1.0 branch prior to release.

#### 1.0-PR2 (5-13-2008) ####

- Added bin/embedded-build.sh, supports building an embeddable, universal library for arbitrary SDKs (including the iPhone SDK).

- Expanded error handling support. Provides access to vendor error codes and messages via NSError.

#### 1.0-PR1 ####
- Initial Release