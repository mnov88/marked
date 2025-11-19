> **Note**: Support for the `RETURNING` clause is available from SQLite 3.35.0+: iOS 15.0+, macOS 12.0+, tvOS 15.0+, watchOS 8.0+, or with a [custom SQLite build] or [SQLCipher](#encryption).
The `RETURNING` clause helps dealing with database features such as auto-incremented ids, default values, and [generated columns](https://sqlite.org/gencol.html). You can, for example, insert a few columns and fetch the default or generated ones in one step.
GRDB uses the `RETURNING` clause in all persistence methods that contain `AndFetch` in their name.
For example, given a database table with an auto-incremented primary key and a default score:
```swift
try dbQueue.write { db in
    try db.execute(sql: """
        CREATE TABLE player(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          score INTEGER NOT NULL DEFAULT 1000)
        """)
}
```
You can define a record type with full database information, and another partial record type that deals with a subset of columns:
```swift
// A player with full database information
struct Player: Codable, PersistableRecord, FetchableRecord {
    var id: Int64
    var name: String
    var score: Int
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}

// A partial player
struct PartialPlayer: Encodable, PersistableRecord {
    static let databaseTableName = "player"
    var name: String
    
    typealias Columns = Player.Columns
}
```
And now you can get a full player by inserting a partial one:
```swift
try dbQueue.write { db in
    let partialPlayer = PartialPlayer(name: "Alice")
    
    // INSERT INTO player (name) VALUES ('Alice') RETURNING *
    let player = try partialPlayer.insertAndFetch(db, as: Player.self)
    print(player.id)    // The inserted id
    print(player.name)  // The inserted name
    print(player.score) // The default score
}
```
For extra precision, you can select only the columns you need, and fetch the desired value from the provided prepared [`Statement`]:
```swift
try dbQueue.write { db in
    let partialPlayer = PartialPlayer(name: "Alice")
    
    // INSERT INTO player (name) VALUES ('Alice') RETURNING score
    let score = try partialPlayer.insertAndFetch(db) { statement in
        try Int.fetchOne(statement)
    } select: {
        [$0.score]
    }
    print(score) // Prints 1000, the default score
}
```
There are other similar persistence methods, such as `upsertAndFetch`, `saveAndFetch`, `updateAndFetch`, `updateChangesAndFetch`, etc. They all behave like `upsert`, `save`, `update`, `updateChanges`, except that they return saved values. For example:
```swift
// Save and return the saved player
let savedPlayer = try player.saveAndFetch(db)
```
See [Persistence Methods], [Upsert](#upsert), and [`updateChanges` methods](#the-updatechanges-methods) for more information.
**Batch operations** can return updated or deleted values:
> **Warning**: Make sure you check the [documentation of the `RETURNING` clause](https://www.sqlite.org/lang_returning.html#limitations_and_caveats), which describes important limitations and caveats for batch operations.
```swift
let request = Player.filter(...)...

// Fetch all deleted players
// DELETE FROM player RETURNING *
let deletedPlayers = try request.deleteAndFetchAll(db) // [Player]

// Fetch a selection of columns from the deleted rows
// DELETE FROM player RETURNING name
let statement = try request.deleteAndFetchStatement(db) { [$0.name] }
let deletedNames = try String.fetchSet(statement)

// Fetch all updated players
// UPDATE player SET score = score + 10 RETURNING *
let updatedPlayers = try request.updateAndFetchAll(db) { [$0.score += 10] } // [Player]

// Fetch a selection of columns from the updated rows
// UPDATE player SET score = score + 10 RETURNING score
let statement = try request.updateAndFetchStatement(db) {
    [$0.score += 10]
} select: {
    [$0.score]
}
let updatedScores = try Int.fetchAll(statement)
```
### Persistence Callbacks
Your custom type may want to perform extra work when the persistence methods are invoked.
To this end, your record type can implement **persistence callbacks**. Callbacks are methods that get called at certain moments of a record's life cycle. With callbacks it is possible to write code that will run whenever an record is inserted, updated, or deleted.
In order to use a callback method, you need to provide its implementation. For example, a frequently used callback is `didInsert`, in the case of auto-incremented database ids:
```swift
struct Player: MutablePersistableRecord {
    var id: Int64?
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

try dbQueue.write { db in
    var player = Player(id: nil, ...)
    try player.insert(db)
    print(player.id) // didInsert was called: prints some non-nil id
}
```
Callbacks can also help implementing record validation:
```swift
struct Link: PersistableRecord {
    var url: URL
    
    func willSave(_ db: Database) throws {
        if url.host == nil {
            throw ValidationError("url must be absolute.")
        }
    }
}

try link.insert(db) // Calls the willSave callback
try link.update(db) // Calls the willSave callback
try link.save(db)   // Calls the willSave callback
try link.upsert(db) // Calls the willSave callback
```
