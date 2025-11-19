### SQLite error 10 "disk I/O error", SQLite error 23 "not authorized"
Those errors may be the sign that SQLite can't access the database due to [data protection](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files).
When your application should be able to run in the background on a locked device, it has to catch this error, and, for example, wait for [UIApplicationDelegate.applicationProtectedDataDidBecomeAvailable(_:)](https://developer.apple.com/reference/uikit/uiapplicationdelegate/1623044-applicationprotecteddatadidbecom) or [UIApplicationProtectedDataDidBecomeAvailable](https://developer.apple.com/reference/uikit/uiapplicationprotecteddatadidbecomeavailable) notification and retry the failed database operation.
```swift
do {
    try ...
} catch DatabaseError.SQLITE_IOERR, DatabaseError.SQLITE_AUTH {
    // Handle possible data protection error
}
```
This error can also be prevented altogether by using a more relaxed [file protection](https://developer.apple.com/reference/foundation/filemanager/1653059-file_protection_values).
### SQLite error 21 "wrong number of statement arguments" with LIKE queries
You may get the error "wrong number of statement arguments" when executing a LIKE query similar to:
```swift
let name = textField.text
let players = try dbQueue.read { db in
    try Player.fetchAll(db, sql: "SELECT * FROM player WHERE name LIKE '%?%'", arguments: [name])
}
```
The problem lies in the `'%?%'` pattern.
SQLite only interprets `?` as a parameter when it is a placeholder for a whole value (int, double, string, blob, null). In this incorrect query, `?` is just a character in the `'%?%'` string: it is not a query parameter, and is not processed in any way. See [https://www.sqlite.org/lang_expr.html#varparam](https://www.sqlite.org/lang_expr.html#varparam) for more information about SQLite parameters.
To fix the error, you can feed the request with the pattern itself, instead of the name:
```swift
let name = textField.text
let players: [Player] = try dbQueue.read { db in
    let pattern = "%\(name)%"
    return try Player.fetchAll(db, sql: "SELECT * FROM player WHERE name LIKE ?", arguments: [pattern])
}
```
Sample Code
===========
- The [Documentation](#documentation) is full of GRDB snippets.
- [Demo Applications]
- Open `GRDB.xcworkspace`: it contains GRDB-enabled playgrounds to play with.
- [groue/SortedDifference](https://github.com/groue/SortedDifference): How to synchronize a database table with a JSON payload
---
**Thanks**
- [Pierlis](http://pierlis.com), where we write great software.
- [@alextrob](https://github.com/alextrob), [@alexwlchan](https://github.com/alexwlchan), [@bellebethcooper](https://github.com/bellebethcooper), [@bfad](https://github.com/bfad), [@cfilipov](https://github.com/cfilipov), [@charlesmchen-signal](https://github.com/charlesmchen-signal), [@Chiliec](https://github.com/Chiliec), [@chrisballinger](https://github.com/chrisballinger), [@darrenclark](https://github.com/darrenclark), [@davidkraus](https://github.com/davidkraus), [@eburns-vmware](https://github.com/eburns-vmware), [@felixscheinost](https://github.com/felixscheinost), [@fpillet](https://github.com/fpillet), [@gcox](https://github.com/gcox), [@GetToSet](https://github.com/GetToSet), [@gjeck](https://github.com/gjeck), [@guidedways](https://github.com/guidedways), [@gusrota](https://github.com/gusrota), [@haikusw](https://github.com/haikusw), [@hartbit](https://github.com/hartbit), [@holsety](https://github.com/holsety), [@jroselightricks](https://github.com/jroselightricks), [@kdubb](https://github.com/kdubb), [@kluufger](https://github.com/kluufger), [@KyleLeneau](https://github.com/KyleLeneau), [@layoutSubviews](https://github.com/layoutSubviews), [@mallman](https://github.com/mallman), [@MartinP7r](https://github.com/MartinP7r), [@Marus](https://github.com/Marus), [@mattgallagher](https://github.com/mattgallagher), [@MaxDesiatov](https://github.com/MaxDesiatov), [@michaelkirk-signal](https://github.com/michaelkirk-signal), [@mtancock](https://github.com/mtancock), [@pakko972](https://github.com/pakko972), [@peter-ss](https://github.com/peter-ss), [@pierlo](https://github.com/pierlo), [@pocketpixels](https://github.com/pocketpixels), [@pp5x](https://github.com/pp5x), [@professordeng](https://github.com/professordeng), [@robcas3](https://github.com/robcas3), [@runhum](https://github.com/runhum), [@sberrevoets](https://github.com/sberrevoets), [@schveiguy](https://github.com/schveiguy), [@SD10](https://github.com/SD10), [@sobri909](https://github.com/sobri909), [@sroddy](https://github.com/sroddy), [@steipete](https://github.com/steipete), [@swiftlyfalling](https://github.com/swiftlyfalling), [@Timac](https://github.com/Timac), [@tternes](https://github.com/tternes), [@valexa](https://github.com/valexa), [@wuyuehyang](https://github.com/wuyuehyang), [@ZevEisenberg](https://github.com/ZevEisenberg), and [@zmeyc](https://github.com/zmeyc) for their contributions, help, and feedback on GRDB.
- [@aymerick](https://github.com/aymerick) and [@kali](https://github.com/kali) because SQL.
- [ccgus/fmdb](https://github.com/ccgus/fmdb) for its excellency.
---
[URIs don't change: people change them.](https://www.w3.org/Provider/Style/URI)
#### Adding support for missing SQL functions or operators
This chapter was renamed to [Embedding SQL in Query Interface Requests].
#### Advanced DatabasePool
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### After Commit Hook
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/afternexttransaction(oncommit:onrollback:)).
#### Asynchronous APIs
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### Changes Tracking
This chapter has been renamed [Record Comparison].
#### Concurrency
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### Custom Value Types
Custom Value Types conform to the [`DatabaseValueConvertible`] protocol.
#### Customized Decoding of Database Rows
This chapter has been renamed [Beyond FetchableRecord].
#### Customizing the Persistence Methods
This chapter was replaced with [Persistence Callbacks].
#### Database Changes Observation
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseobservation).
#### Database Configuration
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/configuration).
#### Database Queues
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasequeue).
#### Database Pools
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasepool).
#### Database Snapshots
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### DatabaseWriter and DatabaseReader Protocols
This chapter was removed. See the references of [DatabaseReader](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasereader) and [DatabaseWriter](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasewriter).
#### Date and UUID Coding Strategies
This chapter has been renamed [Data, Date, and UUID Coding Strategies].
#### Dealing with External Connections
This chapter has been superseded by the [Sharing a Database] guide.
#### Differences between Database Queues and Pools
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### Enabling FTS5 Support
FTS5 is enabled by default since GRDB 6.7.0.
#### FetchedRecordsController
FetchedRecordsController has been removed in GRDB 5.
The [Database Observation] chapter describes the other ways to observe the database.
#### Full-Text Search
This chapter has [moved](Documentation/FullTextSearch.md).
#### Guarantees and Rules
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### Joined Queries Support
This chapter was replaced with the documentation of [splittingRowAdapters(columnCounts:)](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/splittingrowadapters(columncounts:)).
#### List of Record Methods
See [Records and the Query Interface](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterface).
#### Migrations
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations).
#### NSNumber and NSDecimalNumber
This chapter has [moved](#nsnumber-nsdecimalnumber-and-decimal).
#### Persistable Protocol
This protocol has been renamed [PersistableRecord] in GRDB 3.0.
#### PersistenceError
This error was renamed to [RecordError].
#### Prepared Statements
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/statement).
#### Record Class
The [`Record`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/record) class is a legacy GRDB type. Since GRDB 7, it is not recommended to define record types by subclassing the `Record` class.
#### Row Adapters
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/rowadapter).
#### RowConvertible Protocol
This protocol has been renamed [FetchableRecord] in GRDB 3.0.
#### TableMapping Protocol
This protocol has been renamed [TableRecord] in GRDB 3.0.
#### Transactions and Savepoints
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/transactions).
#### Transaction Hook
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/afternexttransaction(oncommit:onrollback:)).
#### TransactionObserver Protocol
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/transactionobserver).
#### Unsafe Concurrency APIs
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/concurrency).
#### ValueObservation
This chapter has [moved](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/valueobservation).
