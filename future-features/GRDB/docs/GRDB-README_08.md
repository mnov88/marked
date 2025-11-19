There are many supported value types (Bool, Int, String, Date, Swift enums, etc.). See [Values](#values) for more information.
## Values
GRDB ships with built-in support for the following value types:
- **Swift Standard Library**: Bool, Double, Float, all signed and unsigned integer types, String, [Swift enums](#swift-enums).
- **Foundation**: [Data](#data-and-memory-savings), [Date](#date-and-datecomponents), [DateComponents](#date-and-datecomponents), [Decimal](#nsnumber-nsdecimalnumber-and-decimal), NSNull, [NSNumber](#nsnumber-nsdecimalnumber-and-decimal), NSString, URL, [UUID](#uuid).
- **CoreGraphics**: CGFloat.
- **[DatabaseValue](#databasevalue)**, the type which gives information about the raw value stored in the database.
- **Full-Text Patterns**: [FTS3Pattern](Documentation/FullTextSearch.md#fts3pattern) and [FTS5Pattern](Documentation/FullTextSearch.md#fts5pattern).
- Generally speaking, all types that adopt the [`DatabaseValueConvertible`] protocol.
Values can be used as [statement arguments](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/statementarguments):
```swift
let url: URL = ...
let verified: Bool = ...
try db.execute(
    sql: "INSERT INTO link (url, verified) VALUES (?, ?)",
    arguments: [url, verified])
```
Values can be [extracted from rows](#column-values):
```swift
let rows = try Row.fetchCursor(db, sql: "SELECT * FROM link")
while let row = try rows.next() {
    let url: URL = row["url"]
    let verified: Bool = row["verified"]
}
```
Values can be [directly fetched](#value-queries):
```swift
let urls = try URL.fetchAll(db, sql: "SELECT url FROM link")  // [URL]
```
Use values in [Records](#records):
```swift
struct Link: FetchableRecord {
    var url: URL
    var isVerified: Bool
    
    init(row: Row) {
        url = row["url"]
        isVerified = row["verified"]
    }
}
```
Use values in the [query interface](#the-query-interface):
```swift
let url: URL = ...
let link = try Link.filter { $0.url == url }.fetchOne(db)
```
### Data (and Memory Savings)
**Data** suits the BLOB SQLite columns. It can be stored and fetched from the database just like other [values](#values):
```swift
let rows = try Row.fetchCursor(db, sql: "SELECT data, ...")
while let row = try rows.next() {
    let data: Data = row["data"]
}
```
At each step of the request iteration, the `row[]` subscript creates *two copies* of the database bytes: one fetched by SQLite, and another, stored in the Swift Data value.
**You have the opportunity to save memory** by not copying the data fetched by SQLite:
```swift
while let row = try rows.next() {
    try row.withUnsafeData(name: "data") { (data: Data?) in
        ...
    }
}
```
The non-copied data does not live longer than the iteration step: make sure that you do not use it past this point.
### Date and DateComponents
[**Date**](#date) and [**DateComponents**](#datecomponents) can be stored and fetched from the database.
Here is how GRDB supports the various [date formats](https://www.sqlite.org/lang_datefunc.html) supported by SQLite:
| SQLite format                | Date               | DateComponents |
|:---------------------------- |:------------------:|:--------------:|
| YYYY-MM-DD                   |       Read ¹       | Read / Write   |
| YYYY-MM-DD HH:MM             |       Read ¹ ²     | Read ² / Write |
| YYYY-MM-DD HH:MM:SS          |       Read ¹ ²     | Read ² / Write |
| YYYY-MM-DD HH:MM:SS.SSS      | Read ¹ ² / Write ¹ | Read ² / Write |
| YYYY-MM-DD**T**HH:MM         |       Read ¹ ²     |      Read ²    |
| YYYY-MM-DD**T**HH:MM:SS      |       Read ¹ ²     |      Read ²    |
| YYYY-MM-DD**T**HH:MM:SS.SSS  |       Read ¹ ²     |      Read ²    |
| HH:MM                        |                    | Read ² / Write |
| HH:MM:SS                     |                    | Read ² / Write |
| HH:MM:SS.SSS                 |                    | Read ² / Write |
| Timestamps since unix epoch  |       Read ³       |                |
| `now`                        |                    |                |
¹ Missing components are assumed to be zero. Dates are stored and read in the UTC time zone, unless the format is followed by a timezone indicator ⁽²⁾.
² This format may be optionally followed by a timezone indicator of the form `[+-]HH:MM` or just `Z`.
³ GRDB 2+ interprets numerical values as timestamps that fuel `Date(timeIntervalSince1970:)`. Previous GRDB versions used to interpret numbers as [julian days](https://en.wikipedia.org/wiki/Julian_day). Julian days are still supported, with the `Date(julianDay:)` initializer.
> **Warning**: the range of valid years in the SQLite date formats is 0000-9999. You will need to pick another date format when your application needs to process years outside of this range. See the following chapters.
