#### Column Values
**Read column values** by index or column name:
```swift
let name: String = row[0]      // 0 is the leftmost column
let name: String = row["name"] // Leftmost matching column - lookup is case-insensitive
let name: String = row[Column("name")] // Using query interface's Column
```
Make sure to ask for an optional when the value may be NULL:
```swift
let name: String? = row["name"]
```
The `row[]` subscript returns the type you ask for. See [Values](#values) for more information on supported value types:
```swift
let bookCount: Int     = row["bookCount"]
let bookCount64: Int64 = row["bookCount"]
let hasBooks: Bool     = row["bookCount"] // false when 0

let string: String     = row["date"]      // "2015-09-11 18:14:15.123"
let date: Date         = row["date"]      // Date
self.date = row["date"] // Depends on the type of the property.
```
You can also use the `as` type casting operator:
```swift
row[...] as Int
row[...] as Int?
```
Throwing accessors exist as well. Their use is not encouraged, because a database decoding error is a programming error. If an application stores invalid data in the database file, that is a bug that needs to be fixed:
```swift
let name = try row.decode(String.self, atIndex: 0)
let bookCount = try row.decode(Int.self, forColumn: "bookCount")
```
> **Warning**: avoid the `as!` and `as?` operators:
> 
> ```swift
> if let int = row[...] as? Int { ... } // BAD - doesn't work
> if let int = row[...] as Int? { ... } // GOOD
> ```
> **Warning**: avoid nil-coalescing row values, and prefer the `coalesce` method instead:
>
> ```swift
> let name: String? = row["nickname"] ?? row["name"]     // BAD - doesn't work
> let name: String? = row.coalesce(["nickname", "name"]) // GOOD
> ```
Generally speaking, you can extract the type you need, provided it can be converted from the underlying SQLite value:
- **Successful conversions include:**
    - All numeric SQLite values to all numeric Swift types, and Bool (zero is the only false boolean).
    - Text SQLite values to Swift String.
    - Blob SQLite values to Foundation Data.
    See [Values](#values) for more information on supported types (Bool, Int, String, Date, Swift enums, etc.)
- **NULL returns nil.**
    ```swift
    let row = try Row.fetchOne(db, sql: "SELECT NULL")!
    row[0] as Int? // nil
    row[0] as Int  // fatal error: could not convert NULL to Int.
    ```
    There is one exception, though: the [DatabaseValue](#databasevalue) type:
    ```swift
    row[0] as DatabaseValue // DatabaseValue.null
    ```
- **Missing columns return nil.**
    ```swift
    let row = try Row.fetchOne(db, sql: "SELECT 'foo' AS foo")!
    row["missing"] as String? // nil
    row["missing"] as String  // fatal error: no such column: missing
    ```
    You can explicitly check for a column presence with the `hasColumn` method.
- **Invalid conversions throw a fatal error.**
    ```swift
    let row = try Row.fetchOne(db, sql: "SELECT 'Mom’s birthday'")!
    row[0] as String // "Mom’s birthday"
    row[0] as Date?  // fatal error: could not convert "Mom’s birthday" to Date.
    row[0] as Date   // fatal error: could not convert "Mom’s birthday" to Date.
    
    let row = try Row.fetchOne(db, sql: "SELECT 256")!
    row[0] as Int    // 256
    row[0] as UInt8? // fatal error: could not convert 256 to UInt8.
    row[0] as UInt8  // fatal error: could not convert 256 to UInt8.
    ```
    Those conversion fatal errors can be avoided with the [DatabaseValue](#databasevalue) type:
    ```swift
    let row = try Row.fetchOne(db, sql: "SELECT 'Mom’s birthday'")!
    let dbValue: DatabaseValue = row[0]
    if dbValue.isNull {
        // Handle NULL
    } else if let date = Date.fromDatabaseValue(dbValue) {
        // Handle valid date
    } else {
        // Handle invalid date
    }
    ```
    This extra verbosity is the consequence of having to deal with an untrusted database: you may consider fixing the content of your database instead. See [Fatal Errors](#fatal-errors) for more information.
- **SQLite has a weak type system, and provides [convenience conversions](https://www.sqlite.org/c3ref/column_blob.html) that can turn String to Int, Double to Blob, etc.**
    GRDB will sometimes let those conversions go through:
    ```swift
    let rows = try Row.fetchCursor(db, sql: "SELECT '20 small cigars'")
    while let row = try rows.next() {
        row[0] as Int   // 20
    }
    ```
    Don't freak out: those conversions did not prevent SQLite from becoming the immensely successful database engine you want to use. And GRDB adds safety checks described just above. You can also prevent those convenience conversions altogether by using the [DatabaseValue](#databasevalue) type.
#### DatabaseValue
📖 [`DatabaseValue`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasevalue)
**`DatabaseValue` is an intermediate type between SQLite and your values, which gives information about the raw value stored in the database.**
You get `DatabaseValue` just like other value types:
```swift
let dbValue: DatabaseValue = row[0]
let dbValue: DatabaseValue? = row["name"] // nil if and only if column does not exist

// Check for NULL:
dbValue.isNull // Bool

// The stored value:
dbValue.storage.value // Int64, Double, String, Data, or nil

// All the five storage classes supported by SQLite:
switch dbValue.storage {
case .null:                 print("NULL")
case .int64(let int64):     print("Int64: \(int64)")
case .double(let double):   print("Double: \(double)")
case .string(let string):   print("String: \(string)")
case .blob(let data):       print("Data: \(data)")
}
```
You can extract regular [values](#values) (Bool, Int, String, Date, Swift enums, etc.) from `DatabaseValue` with the [fromDatabaseValue()](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasevalueconvertible/fromdatabasevalue(_:)-21zzv) method:
```swift
let dbValue: DatabaseValue = row["bookCount"]
let bookCount   = Int.fromDatabaseValue(dbValue)   // Int?
let bookCount64 = Int64.fromDatabaseValue(dbValue) // Int64?
let hasBooks    = Bool.fromDatabaseValue(dbValue)  // Bool?, false when 0

let dbValue: DatabaseValue = row["date"]
let string = String.fromDatabaseValue(dbValue)     // "2015-09-11 18:14:15.123"
let date   = Date.fromDatabaseValue(dbValue)       // Date?
```
`fromDatabaseValue` returns nil for invalid conversions:
```swift
let row = try Row.fetchOne(db, sql: "SELECT 'Mom’s birthday'")!
let dbValue: DatabaseValue = row[0]
let string = String.fromDatabaseValue(dbValue) // "Mom’s birthday"
let int    = Int.fromDatabaseValue(dbValue)    // nil
let date   = Date.fromDatabaseValue(dbValue)   // nil
```
