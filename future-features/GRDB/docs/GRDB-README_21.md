See the [query interface](#the-query-interface) and [Recommended Practices for Designing Record Types](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/recordrecommendedpractices) for further information.
## Record Comparison
**Records that adopt the [EncodableRecord] protocol can compare against other records, or against previous versions of themselves.**
This helps avoiding costly UPDATE statements when a record has not been edited.
- [The `updateChanges` Methods](#the-updatechanges-methods)
- [The `databaseEquals` Method](#the-databaseequals-method)
- [The `databaseChanges` and `hasDatabaseChanges` Methods](#the-databasechanges-and-hasdatabasechanges-methods)
### The `updateChanges` Methods
The `updateChanges` methods perform a database update of the changed columns only (and does nothing if record has no change).
- `updateChanges(_:from:)`
    This method lets you compare two records:
    ```swift
    if let oldPlayer = try Player.fetchOne(db, id: 42) {
        var newPlayer = oldPlayer
        newPlayer.score = 100
        if try newPlayer.updateChanges(db, from: oldPlayer) {
            print("player was modified, and updated in the database")
        } else {
            print("player was not modified, and database was not hit")
        }
    }
    ```
- `updateChanges(_:modify:)`
    This method lets you update a record in place:
    ```swift
    if var player = try Player.fetchOne(db, id: 42) {
        let modified = try player.updateChanges(db) {
            $0.score = 100
        }
        if modified {
            print("player was modified, and updated in the database")
        } else {
            print("player was not modified, and database was not hit")
        }
    }
    ```
### The `databaseEquals` Method
This method returns whether two records have the same database representation:
```swift
let oldPlayer: Player = ...
var newPlayer: Player = ...
if newPlayer.databaseEquals(oldPlayer) == false {
    try newPlayer.save(db)
}
```
> **Note**: The comparison is performed on the database representation of records. As long as your record type adopts the EncodableRecord protocol, you don't need to care about Equatable.
### The `databaseChanges` and `hasDatabaseChanges` Methods
`databaseChanges(from:)` returns a dictionary of differences between two records:
```swift
let oldPlayer = Player(id: 1, name: "Arthur", score: 100)
let newPlayer = Player(id: 1, name: "Arthur", score: 1000)
for (column, oldValue) in try newPlayer.databaseChanges(from: oldPlayer) {
    print("\(column) was \(oldValue)")
}
// prints "score was 100"
```
For an efficient algorithm which synchronizes the content of a database table with a JSON payload, check [groue/SortedDifference](https://github.com/groue/SortedDifference).
## Record Customization Options
GRDB records come with many default behaviors, that are designed to fit most situations. Many of those defaults can be customized for your specific needs:
- [Persistence Callbacks]: define what happens when you call a persistence method such as `player.insert(db)`
- [Conflict Resolution]: Run `INSERT OR REPLACE` queries, and generally define what happens when a persistence method violates a unique index.
- [Columns Selected by a Request]: define which columns are selected by requests such as `Player.fetchAll(db)`.
- [Beyond FetchableRecord]: the FetchableRecord protocol is not the end of the story.
[Codable Records] have a few extra options:
- [JSON Columns]: control the format of JSON columns.
- [Column Names Coding Strategies]: control how coding keys are turned into column names
- [Date and UUID Coding Strategies]: control the format of Date and UUID properties in your Codable records.
- [The userInfo Dictionary]: adapt your Codable implementation for the database.
### Conflict Resolution
**Insertions and updates can create conflicts**: for example, a query may attempt to insert a duplicate row that violates a unique index.
Those conflicts normally end with an error. Yet SQLite let you alter the default behavior, and handle conflicts with specific policies. For example, the `INSERT OR REPLACE` statement handles conflicts with the "replace" policy which replaces the conflicting row instead of throwing an error.
The [five different policies](https://www.sqlite.org/lang_conflict.html) are: abort (the default), replace, rollback, fail, and ignore.
**SQLite let you specify conflict policies at two different places:**
- In the definition of the database table:
    ```swift
    // CREATE TABLE player (
    //     id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     email TEXT UNIQUE ON CONFLICT REPLACE
    // )
    try db.create(table: "player") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("email", .text).unique(onConflict: .replace) // <--
    }
    
    // Despite the unique index on email, both inserts succeed.
    // The second insert replaces the first row:
    try db.execute(sql: "INSERT INTO player (email) VALUES (?)", arguments: ["arthur@example.com"])
    try db.execute(sql: "INSERT INTO player (email) VALUES (?)", arguments: ["arthur@example.com"])
    ```
