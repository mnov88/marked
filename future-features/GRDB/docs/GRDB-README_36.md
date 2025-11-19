If you want to see statement arguments in the error description, [make statement arguments public](https://swiftpackageindex.com/groue/GRDB.swift/configuration/publicstatementarguments).
**SQLite uses [results codes](https://www.sqlite.org/rescode.html) to distinguish between various errors**.
You can catch a DatabaseError and match on result codes:
```swift
do {
    try ...
} catch let error as DatabaseError {
    switch error {
    case DatabaseError.SQLITE_CONSTRAINT_FOREIGNKEY:
        // foreign key constraint error
    case DatabaseError.SQLITE_CONSTRAINT:
        // any other constraint error
    default:
        // any other database error
    }
}
```
You can also directly match errors on result codes:
```swift
do {
    try ...
} catch DatabaseError.SQLITE_CONSTRAINT_FOREIGNKEY {
    // foreign key constraint error
} catch DatabaseError.SQLITE_CONSTRAINT {
    // any other constraint error
} catch {
    // any other database error
}
```
Each DatabaseError has two codes: an `extendedResultCode` (see [extended result code](https://www.sqlite.org/rescode.html#extended_result_code_list)), and a less precise `resultCode` (see [primary result code](https://www.sqlite.org/rescode.html#primary_result_code_list)). Extended result codes are refinements of primary result codes, as `SQLITE_CONSTRAINT_FOREIGNKEY` is to `SQLITE_CONSTRAINT`, for example.
> **Warning**: SQLite has progressively introduced extended result codes across its versions. The [SQLite release notes](http://www.sqlite.org/changes.html) are unfortunately not quite clear about that: write your handling of extended result codes with care.
### RecordError
📖 [`RecordError`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/recorderror)
**RecordError** is thrown by the [PersistableRecord] protocol when the `update` method could not find any row to update:
```swift
do {
    try player.update(db)
} catch let RecordError.recordNotFound(databaseTableName: table, key: key) {
    print("Key \(key) was not found in table \(table).")
}
```
**RecordError** is also thrown by the [FetchableRecord] protocol when the `find` method does not find any record:
```swift
do {
    let player = try Player.find(db, id: 42)
} catch let RecordError.recordNotFound(databaseTableName: table, key: key) {
    print("Key \(key) was not found in table \(table).")
}
```
### RowDecodingError
📖 [`RowDecodingError`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/rowdecodingerror)
**RowDecodingError** is thrown when the application can not decode a value from a database row. For example:
```swift
let row = try Row.fetchOne(db, sql: "SELECT NULL AS name")!
// RowDecodingError: could not decode String from database value NULL.
let name = try row.decode(String.self, forColumn: "name")
```
### Fatal Errors
**Fatal errors notify that the program, or the database, has to be changed.**
They uncover programmer errors, false assumptions, and prevent misuses. Here are a few examples:
- **The code asks for a non-optional value, when the database contains NULL:**
    ```swift
    // fatal error: could not convert NULL to String.
    let name: String = row["name"]
    ```
    Solution: fix the contents of the database, use [NOT NULL constraints](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/columndefinition/notnull(onconflict:)), or load an optional:
    ```swift
    let name: String? = row["name"]
    ```
- **Conversion from database value to Swift type fails:**
    ```swift
    // fatal error: could not convert "Mom’s birthday" to Date.
    let date: Date = row["date"]
    
    // fatal error: could not convert "" to URL.
    let url: URL = row["url"]
    ```
    Solution: fix the contents of the database, or use [DatabaseValue](#databasevalue) to handle all possible cases:
    ```swift
    let dbValue: DatabaseValue = row["date"]
    if dbValue.isNull {
        // Handle NULL
    } else if let date = Date.fromDatabaseValue(dbValue) {
        // Handle valid date
    } else {
        // Handle invalid date
    }
    ```
- **The database can't guarantee that the code does what it says:**
    ```swift
    // fatal error: table player has no unique index on column email
    try Player.deleteOne(db, key: ["email": "arthur@example.com"])
    ```
    Solution: add a unique index to the player.email column, or use the `deleteAll` method to make it clear that you may delete more than one row:
    ```swift
    try Player.filter { $0.email == "arthur@example.com" }.deleteAll(db)
    ```
- **Database connections are not reentrant:**
    ```swift
    // fatal error: Database methods are not reentrant.
    dbQueue.write { db in
        dbQueue.write { db in
            ...
        }
    }
    ```
