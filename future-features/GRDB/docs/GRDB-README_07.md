#### Rows as Dictionaries
Row adopts the standard [RandomAccessCollection](https://developer.apple.com/documentation/swift/randomaccesscollection) protocol, and can be seen as a dictionary of [DatabaseValue](#databasevalue):
```swift
// All the (columnName, dbValue) tuples, from left to right:
for (columnName, dbValue) in row {
    ...
}
```
**You can build rows from dictionaries** (standard Swift dictionaries and NSDictionary). See [Values](#values) for more information on supported types:
```swift
let row: Row = ["name": "foo", "date": nil]
let row = Row(["name": "foo", "date": nil])
let row = Row(/* [AnyHashable: Any] */) // nil if invalid dictionary
```
Yet rows are not real dictionaries: they may contain duplicate columns:
```swift
let row = try Row.fetchOne(db, sql: "SELECT 1 AS foo, 2 AS foo")!
row.columnNames    // ["foo", "foo"]
row.databaseValues // [1, 2]
row["foo"]         // 1 (leftmost matching column)
for (columnName, dbValue) in row { ... } // ("foo", 1), ("foo", 2)
```
**When you build a dictionary from a row**, you have to disambiguate identical columns, and choose how to present database values. For example:
- A `[String: DatabaseValue]` dictionary that keeps leftmost value in case of duplicated column name:
    ```swift
    let dict = Dictionary(row, uniquingKeysWith: { (left, _) in left })
    ```
- A `[String: AnyObject]` dictionary which keeps rightmost value in case of duplicated column name. This dictionary is identical to FMResultSet's resultDictionary from FMDB. It contains NSNull values for null columns, and can be shared with Objective-C:
    ```swift
    let dict = Dictionary(
        row.map { (column, dbValue) in
            (column, dbValue.storage.value as AnyObject)
        },
        uniquingKeysWith: { (_, right) in right })
    ```
- A `[String: Any]` dictionary that can feed, for example, JSONSerialization:
    ```swift
    let dict = Dictionary(
        row.map { (column, dbValue) in
            (column, dbValue.storage.value)
        },
        uniquingKeysWith: { (left, _) in left })
    ```
See the documentation of [`Dictionary.init(_:uniquingKeysWith:)`](https://developer.apple.com/documentation/swift/dictionary/2892961-init) for more information.
### Value Queries
📖 [`DatabaseValueConvertible`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasevalueconvertible)
**Instead of rows, you can directly fetch values.** There are many supported [value types](#values) (Bool, Int, String, Date, Swift enums, etc.).
Like rows, fetch values as **cursors**, **arrays**, **sets**, or **single** values (see [fetching methods](#fetching-methods)). Values are extracted from the leftmost column of the SQL queries:
```swift
try dbQueue.read { db in
    try Int.fetchCursor(db, sql: "SELECT ...", arguments: ...) // A Cursor of Int
    try Int.fetchAll(db, sql: "SELECT ...", arguments: ...)    // [Int]
    try Int.fetchSet(db, sql: "SELECT ...", arguments: ...)    // Set<Int>
    try Int.fetchOne(db, sql: "SELECT ...", arguments: ...)    // Int?
    
    let maxScore = try Int.fetchOne(db, sql: "SELECT MAX(score) FROM player") // Int?
    let names = try String.fetchAll(db, sql: "SELECT name FROM player")       // [String]
}
```
`Int.fetchOne` returns nil in two cases: either the SELECT statement yielded no row, or one row with a NULL value:
```swift
// No row:
try Int.fetchOne(db, sql: "SELECT 42 WHERE FALSE") // nil

// One row with a NULL value:
try Int.fetchOne(db, sql: "SELECT NULL")           // nil

// One row with a non-NULL value:
try Int.fetchOne(db, sql: "SELECT 42")             // 42
```
For requests which may contain NULL, fetch optionals:
```swift
try dbQueue.read { db in
    try Optional<Int>.fetchCursor(db, sql: "SELECT ...", arguments: ...) // A Cursor of Int?
    try Optional<Int>.fetchAll(db, sql: "SELECT ...", arguments: ...)    // [Int?]
    try Optional<Int>.fetchSet(db, sql: "SELECT ...", arguments: ...)    // Set<Int?>
}
```
> :bulb: **Tip**: One advanced use case, when you fetch one value, is to distinguish the cases of a statement that yields no row, or one row with a NULL value. To do so, use `Optional<Int>.fetchOne`, which returns a double optional `Int??`:
> 
> ```swift
> // No row:
> try Optional<Int>.fetchOne(db, sql: "SELECT 42 WHERE FALSE") // .none
> // One row with a NULL value:
> try Optional<Int>.fetchOne(db, sql: "SELECT NULL")           // .some(.none)
> // One row with a non-NULL value:
> try Optional<Int>.fetchOne(db, sql: "SELECT 42")             // .some(.some(42))
> ```
