**If you are not sure, choose [`DatabaseQueue`].** You will always be able to switch to [`DatabasePool`] later.
For more information and tips when opening connections, see [Database Connections](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections).
SQLite API
==========
**In this section of the documentation, we will talk SQL.** Jump to the [query interface](#the-query-interface) if SQL is not your cup of tea.
- [Executing Updates](#executing-updates)
- [Fetch Queries](#fetch-queries)
    - [Fetching Methods](#fetching-methods)
    - [Row Queries](#row-queries)
    - [Value Queries](#value-queries)
- [Values](#values)
    - [Data](#data-and-memory-savings)
    - [Date and DateComponents](#date-and-datecomponents)
    - [NSNumber, NSDecimalNumber, and Decimal](#nsnumber-nsdecimalnumber-and-decimal)
    - [Swift enums](#swift-enums)
    - [`DatabaseValueConvertible`]: the protocol for custom value types
- [Transactions and Savepoints]
- [SQL Interpolation]
Advanced topics:
- [Prepared Statements]
- [Custom SQL Functions and Aggregates](#custom-sql-functions-and-aggregates)
- [Database Schema Introspection](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschemaintrospection)
- [Row Adapters](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/rowadapter)
- [Raw SQLite Pointers](#raw-sqlite-pointers)
## Executing Updates
Once granted with a [database connection], the [`execute(sql:arguments:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/execute(sql:arguments:)) method executes the SQL statements that do not return any database row, such as `CREATE TABLE`, `INSERT`, `DELETE`, `ALTER`, etc.
For example:
```swift
try dbQueue.write { db in
    try db.execute(sql: """
        CREATE TABLE player (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            score INT)
        """)
    
    try db.execute(
        sql: "INSERT INTO player (name, score) VALUES (?, ?)",
        arguments: ["Barbara", 1000])
    
    try db.execute(
        sql: "UPDATE player SET score = :score WHERE id = :id",
        arguments: ["score": 1000, "id": 1])
    }
}
```
The `?` and colon-prefixed keys like `:score` in the SQL query are the **statements arguments**. You pass arguments with arrays or dictionaries, as in the example above. See [Values](#values) for more information on supported arguments types (Bool, Int, String, Date, Swift enums, etc.), and [`StatementArguments`] for a detailed documentation of SQLite arguments.
You can also embed query arguments right into your SQL queries, with [`execute(literal:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/execute(literal:)), as in the example below. See [SQL Interpolation] for more details.
```swift
try dbQueue.write { db in
    let name = "O'Brien"
    let score = 550
    try db.execute(literal: """
        INSERT INTO player (name, score) VALUES (\(name), \(score))
        """)
}
```
**Never ever embed values directly in your raw SQL strings**. See [Avoiding SQL Injection](#avoiding-sql-injection) for more information:
```swift
// WRONG: don't embed values in raw SQL strings
let id = 123
let name = textField.text
try db.execute(
    sql: "UPDATE player SET name = '\(name)' WHERE id = \(id)")

// CORRECT: use arguments dictionary
try db.execute(
    sql: "UPDATE player SET name = :name WHERE id = :id",
    arguments: ["name": name, "id": id])

// CORRECT: use arguments array
try db.execute(
    sql: "UPDATE player SET name = ? WHERE id = ?",
    arguments: [name, id])

// CORRECT: use SQL Interpolation
try db.execute(
    literal: "UPDATE player SET name = \(name) WHERE id = \(id)")
```
**Join multiple statements with a semicolon**:
```swift
try db.execute(sql: """
    INSERT INTO player (name, score) VALUES (?, ?);
    INSERT INTO player (name, score) VALUES (?, ?);
    """, arguments: ["Arthur", 750, "Barbara", 1000])

try db.execute(literal: """
    INSERT INTO player (name, score) VALUES (\("Arthur"), \(750));
    INSERT INTO player (name, score) VALUES (\("Barbara"), \(1000));
    """)
```
When you want to make sure that a single statement is executed, use a prepared [`Statement`].
**After an INSERT statement**, you can get the row ID of the inserted row with [`lastInsertedRowID`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/lastinsertedrowid):
```swift
try db.execute(
    sql: "INSERT INTO player (name, score) VALUES (?, ?)",
    arguments: ["Arthur", 1000])
let playerId = db.lastInsertedRowID
```
Don't miss [Records](#records), that provide classic **persistence methods**:
```swift
var player = Player(name: "Arthur", score: 1000)
try player.insert(db)
let playerId = player.id
```
