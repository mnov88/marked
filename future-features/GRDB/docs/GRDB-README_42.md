If after all those steps (thanks you!), your observation is still failing you, please [open an issue](https://github.com/groue/GRDB.swift/issues/new) and provide a [minimal reproducible example](https://stackoverflow.com/help/minimal-reproducible-example)!
## FAQ: Errors
- :arrow_up: [FAQ]
- [Generic parameter 'T' could not be inferred](#generic-parameter-t-could-not-be-inferred)
- [Mutation of captured var in concurrently-executing code](#mutation-of-captured-var-in-concurrently-executing-code)
- [SQLite error 1 "no such column"](#sqlite-error-1-no-such-column)
- [SQLite error 10 "disk I/O error", SQLite error 23 "not authorized"](#sqlite-error-10-disk-io-error-sqlite-error-23-not-authorized)
- [SQLite error 21 "wrong number of statement arguments" with LIKE queries](#sqlite-error-21-wrong-number-of-statement-arguments-with-like-queries)
### Generic parameter 'T' could not be inferred
You may get this error when using the `read` and `write` methods of database queues and pools:
```swift
// Generic parameter 'T' could not be inferred
let string = try dbQueue.read { db in
    let result = try String.fetchOne(db, ...)
    return result
}
```
This is a limitation of the Swift compiler.
The general workaround is to explicitly declare the type of the closure result:
```swift
// General Workaround
let string = try dbQueue.read { db -> String? in
    let result = try String.fetchOne(db, ...)
    return result
}
```
You can also, when possible, write a single-line closure:
```swift
// Single-line closure workaround:
let string = try dbQueue.read { db in
    try String.fetchOne(db, ...)
}
```
### Mutation of captured var in concurrently-executing code
The `insert` and `save` [persistence methods](#persistablerecord-protocol) can trigger a compiler error in async contexts:
```swift
var player = Player(id: nil, name: "Arthur")
try await dbWriter.write { db in
    // Error: Mutation of captured var 'player' in concurrently-executing code
    try player.insert(db)
}
print(player.id) // A non-nil id
```
When this happens, prefer the `inserted` and `saved` methods instead:
```swift
// OK
var player = Player(id: nil, name: "Arthur")
player = try await dbWriter.write { [player] db in
    return try player.inserted(db)
}
print(player.id) // A non-nil id
```
### SQLite error 1 "no such column"
This error message is self-explanatory: do check for misspelled or non-existing column names.
However, sometimes this error only happens when an app runs on a recent operating system (iOS 14+, Big Sur+, etc.) The error does not happen with previous ones.
When this is the case, there are two possible explanations:
1. Maybe a column name is *really* misspelled or missing from the database schema.
    To find it, check the SQL statement that comes with the [DatabaseError](#databaseerror).
2. Maybe the application is using the character `"` instead of the single quote `'` as the delimiter for string literals in raw SQL queries. Recent versions of SQLite have learned to tell about this deviation from the SQL standard, and this is why you are seeing this error. 
    For example: this is not standard SQL: `UPDATE player SET name = "Arthur"`.
    The standard version is: `UPDATE player SET name = 'Arthur'`.
    It just happens that old versions of SQLite used to accept the former, non-standard version. Newer versions are able to reject it with an error.
    The fix is to change the SQL statements run by the application: replace `"` with `'` in your string literals.
    It may also be time to learn about statement arguments and [SQL injection](#avoiding-sql-injection):
    ```swift
    let name: String = ...
    
    // NOT STANDARD (double quote)
    try db.execute(sql: """
        UPDATE player SET name = "\(name)"
        """)
    
    // STANDARD, BUT STILL NOT RECOMMENDED (single quote)
    try db.execute(sql: "UPDATE player SET name = '\(name)'")
    
    // STANDARD, AND RECOMMENDED (statement arguments)
    try db.execute(sql: "UPDATE player SET name = ?", arguments: [name])
    
    // STANDARD, AND RECOMMENDED (SQL interpolation)
    try db.execute(literal: "UPDATE player SET name = \(name)")
    ```
For more information, see [Double-quoted String Literals Are Accepted](https://sqlite.org/quirks.html#double_quoted_string_literals_are_accepted), and [Configuration.acceptsDoubleQuotedStringLiterals](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/configuration/acceptsdoublequotedstringliterals).
