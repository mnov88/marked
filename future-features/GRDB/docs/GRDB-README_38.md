If you can't or don't want to define the comparison behavior of a column (see warning above), you can still use an explicit collation in SQL requests and in the [query interface](#the-query-interface):
```swift
let collation = DatabaseCollation.localizedCaseInsensitiveCompare
let players = try Player.fetchAll(db,
    sql: "SELECT * FROM player ORDER BY name COLLATE \(collation.name))")
let players = try Player.order { $0.name.collating(collation) }.fetchAll(db)
```
**You can also define your own collations**:
```swift
let collation = DatabaseCollation("customCollation") { (lhs, rhs) -> NSComparisonResult in
    // return the comparison of lhs and rhs strings.
}

// Make the collation available to a database connection
var config = Configuration()
config.prepareDatabase { db in
    db.add(collation: collation)
}
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
```
## Memory Management
Both SQLite and GRDB use non-essential memory that help them perform better.
You can reclaim this memory with the `releaseMemory` method:
```swift
// Release as much memory as possible.
dbQueue.releaseMemory()
dbPool.releaseMemory()
```
This method blocks the current thread until all current database accesses are completed, and the memory collected.
> **Warning**: If `DatabasePool.releaseMemory()` is called while a long read is performed concurrently, then no other read access will be possible until this long read has completed, and the memory has been released. If this does not suit your application needs, look for the asynchronous options below:
You can release memory in an asynchronous way as well:
```swift
// On a DatabaseQueue
dbQueue.asyncWriteWithoutTransaction { db in
    db.releaseMemory()
}

// On a DatabasePool
dbPool.releaseMemoryEventually()
```
`DatabasePool.releaseMemoryEventually()` does not block the current thread, and does not prevent concurrent database accesses. In exchange for this convenience, you don't know when memory has been freed.
### Memory Management on iOS
**The iOS operating system likes applications that do not consume much memory.**
[Database queues] and [pools](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasepool) automatically free non-essential memory when the application receives a memory warning, and when the application enters background.
You can opt out of this automatic memory management:
```swift
var config = Configuration()
config.automaticMemoryManagement = false
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config) // or DatabasePool
```
FAQ
===
**[FAQ: Opening Connections](#faq-opening-connections)**
- [How do I create a database in my application?](#how-do-i-create-a-database-in-my-application)
- [How do I open a database stored as a resource of my application?](#how-do-i-open-a-database-stored-as-a-resource-of-my-application)
- [How do I close a database connection?](#how-do-i-close-a-database-connection)
**[FAQ: SQL](#faq-sql)**
- [How do I print a request as SQL?](#how-do-i-print-a-request-as-sql)
**[FAQ: General](#faq-general)**
- [How do I monitor the duration of database statements execution?](#how-do-i-monitor-the-duration-of-database-statements-execution)
- [What Are Experimental Features?](#what-are-experimental-features)
- [Does GRDB support library evolution and ABI stability?](#does-grdb-support-library-evolution-and-abi-stability)
**[FAQ: Associations](#faq-associations)**
- [How do I filter records and only keep those that are associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-associated-to-another-record)
- [How do I filter records and only keep those that are NOT associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-not-associated-to-another-record)
- [How do I select only one column of an associated record?](#how-do-i-select-only-one-column-of-an-associated-record)
**[FAQ: ValueObservation](#faq-valueobservation)**
- [Why is ValueObservation not publishing value changes?](#why-is-valueobservation-not-publishing-value-changes)
**[FAQ: Errors](#faq-errors)**
- [Generic parameter 'T' could not be inferred](#generic-parameter-t-could-not-be-inferred)
- [Mutation of captured var in concurrently-executing code](#mutation-of-captured-var-in-concurrently-executing-code)
- [SQLite error 1 "no such column"](#sqlite-error-1-no-such-column)
- [SQLite error 10 "disk I/O error", SQLite error 23 "not authorized"](#sqlite-error-10-disk-io-error-sqlite-error-23-not-authorized)
- [SQLite error 21 "wrong number of statement arguments" with LIKE queries](#sqlite-error-21-wrong-number-of-statement-arguments-with-like-queries)
