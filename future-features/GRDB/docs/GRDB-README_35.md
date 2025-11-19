## Interrupt a Database
**The `interrupt()` method** causes any pending database operation to abort and return at its earliest opportunity.
It can be called from any thread.
```swift
dbQueue.interrupt()
dbPool.interrupt()
```
A call to `interrupt()` that occurs when there are no running SQL statements is a no-op and has no effect on SQL statements that are started after `interrupt()` returns.
A database operation that is interrupted will throw a DatabaseError with code `SQLITE_INTERRUPT`. If the interrupted SQL operation is an INSERT, UPDATE, or DELETE that is inside an explicit transaction, then the entire transaction will be rolled back automatically. If the rolled back transaction was started by a transaction-wrapping method such as `DatabaseWriter.write` or `Database.inTransaction`, then all database accesses will throw a DatabaseError with code `SQLITE_ABORT` until the wrapping method returns.
For example:
```swift
try dbQueue.write { db in
    try Player(...).insert(db)     // throws SQLITE_INTERRUPT
    try Player(...).insert(db)     // not executed
}                                  // throws SQLITE_INTERRUPT

try dbQueue.write { db in
    do {
        try Player(...).insert(db) // throws SQLITE_INTERRUPT
    } catch { }
}                                  // throws SQLITE_ABORT

try dbQueue.write { db in
    do {
        try Player(...).insert(db) // throws SQLITE_INTERRUPT
    } catch { }
    try Player(...).insert(db)     // throws SQLITE_ABORT
}                                  // throws SQLITE_ABORT
```
You can catch both `SQLITE_INTERRUPT` and `SQLITE_ABORT` errors:
```swift
do {
    try dbPool.write { db in ... }
} catch DatabaseError.SQLITE_INTERRUPT, DatabaseError.SQLITE_ABORT {
    // Oops, the database was interrupted.
}
```
For more information, see [Interrupt A Long-Running Query](https://www.sqlite.org/c3ref/interrupt.html).
## Avoiding SQL Injection
SQL injection is a technique that lets an attacker nuke your database.
> ![XKCD: Exploits of a Mom](https://imgs.xkcd.com/comics/exploits_of_a_mom.png)
>
> https://xkcd.com/327/
Here is an example of code that is vulnerable to SQL injection:
```swift
// BAD BAD BAD
let id = 1
let name = textField.text
try dbQueue.write { db in
    try db.execute(sql: "UPDATE students SET name = '\(name)' WHERE id = \(id)")
}
```
If the user enters a funny string like `Robert'; DROP TABLE students; --`, SQLite will see the following SQL, and drop your database table instead of updating a name as intended:
```sql
UPDATE students SET name = 'Robert';
DROP TABLE students;
--' WHERE id = 1
```
To avoid those problems, **never embed raw values in your SQL queries**. The only correct technique is to provide [arguments](#executing-updates) to your raw SQL queries:
```swift
let name = textField.text
try dbQueue.write { db in
    // Good
    try db.execute(
        sql: "UPDATE students SET name = ? WHERE id = ?",
        arguments: [name, id])
    
    // Just as good
    try db.execute(
        sql: "UPDATE students SET name = :name WHERE id = :id",
        arguments: ["name": name, "id": id])
}
```
When you use [records](#records) and the [query interface](#the-query-interface), GRDB always prevents SQL injection for you:
```swift
let id = 1
let name = textField.text
try dbQueue.write { db in
    if var student = try Student.fetchOne(db, id: id) {
        student.name = name
        try student.update(db)
    }
}
```
## Error Handling
GRDB can throw [DatabaseError](#databaseerror), [RecordError], [RowDecodingError], or crash your program with a [fatal error](#fatal-errors).
Considering that a local database is not some JSON loaded from a remote server, GRDB focuses on **trusted databases**. Dealing with [untrusted databases](#how-to-deal-with-untrusted-inputs) requires extra care.
- [DatabaseError](#databaseerror)
- [RecordError]
- [RowDecodingError]
- [Fatal Errors](#fatal-errors)
- [How to Deal with Untrusted Inputs](#how-to-deal-with-untrusted-inputs)
- [Error Log](#error-log)
### DatabaseError
📖 [`DatabaseError`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseerror)
**DatabaseError** are thrown on SQLite errors:
```swift
do {
    try Pet(masterId: 1, name: "Bobby").insert(db)
} catch let error as DatabaseError {
    // The SQLite error code: 19 (SQLITE_CONSTRAINT)
    error.resultCode
    
    // The extended error code: 787 (SQLITE_CONSTRAINT_FOREIGNKEY)
    error.extendedResultCode
    
    // The eventual SQLite message: FOREIGN KEY constraint failed
    error.message
    
    // The eventual erroneous SQL query
    // "INSERT INTO pet (masterId, name) VALUES (?, ?)"
    error.sql
    
    // The eventual SQL arguments
    // [1, "Bobby"]
    error.arguments
    
    // Full error description
    // > SQLite error 19: FOREIGN KEY constraint failed -
    // > while executing `INSERT INTO pet (masterId, name) VALUES (?, ?)`
    error.description
}
```
