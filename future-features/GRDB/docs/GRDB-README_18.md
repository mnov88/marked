#### Available Callbacks
Here is a list with all the available [persistence callbacks], listed in the same order in which they will get called during the respective operations:
- Inserting a record (all `record.insert` and `record.upsert` methods)
    - `willSave`
    - `aroundSave`
    - `willInsert`
    - `aroundInsert`
    - `didInsert`
    - `didSave`
- Updating a record (all `record.update` methods)
    - `willSave`
    - `aroundSave`
    - `willUpdate`
    - `aroundUpdate`
    - `didUpdate`
    - `didSave`
- Deleting a record (only the `record.delete(_:)` method)
    - `willDelete`
    - `aroundDelete`
    - `didDelete`
For detailed information about each callback, check the [reference](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/mutablepersistablerecord/).
In the `MutablePersistableRecord` protocol, `willInsert` and `didInsert` are mutating methods. In `PersistableRecord`, they are not mutating.
> **Note**: The `record.save(_:)` method performs an UPDATE if the record has a non-null primary key, and then, if no row was modified, an INSERT. It directly performs an INSERT if the record has no primary key, or a null primary key. It triggers update and/or insert callbacks accordingly.
>
> **Warning**: Callbacks are only invoked from persistence methods called on record instances. Callbacks are not invoked when you call a type method, perform a batch operations, or execute raw SQL.
>
> **Warning**: When a `did***` callback is invoked, do not assume that the change is actually persisted on disk, because the database may still be inside an uncommitted transaction. When you need to handle transaction completions, use the [afterNextTransaction(onCommit:onRollback:)](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/afternexttransaction(oncommit:onrollback:)). For example:
>
> ```swift
> struct PictureFile: PersistableRecord {
>     var path: String
>     
>     func willDelete(_ db: Database) {
>         db.afterNextTransaction { _ in
>             try? deleteFileOnDisk()
>         }
>     }
> }
> ```
## Identifiable Records
**When a record type maps a table with a single-column primary key, it is recommended to have it adopt the standard [Identifiable] protocol.**
```swift
struct Player: Identifiable, FetchableRecord, PersistableRecord {
    var id: Int64 // fulfills the Identifiable requirement
    var name: String
    var score: Int
}
```
When `id` has a [database-compatible type](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasevalueconvertible) (Int64, Int, String, UUID, ...), the `Identifiable` conformance unlocks type-safe record and request methods:
```swift
let player = try Player.find(db, id: 1)               // Player
let player = try Player.fetchOne(db, id: 1)           // Player?
let players = try Player.fetchAll(db, ids: [1, 2, 3]) // [Player]
let players = try Player.fetchSet(db, ids: [1, 2, 3]) // Set<Player>

let request = Player.filter(id: 1)
let request = Player.filter(ids: [1, 2, 3])

try Player.deleteOne(db, id: 1)
try Player.deleteAll(db, ids: [1, 2, 3])
```
> **Note**: Not all record types can be made `Identifiable`, and not all tables have a single-column primary key. GRDB provides other methods that deal with primary and unique keys, but they won't check the type of their arguments:
> 
> ```swift
> // Available on non-Identifiable types
> try Player.fetchOne(db, key: 1)
> try Player.fetchOne(db, key: ["email": "arthur@example.com"])
> try Country.fetchAll(db, keys: ["FR", "US"])
> try Citizenship.fetchOne(db, key: ["citizenId": 1, "countryCode": "FR"])
> 
> let request = Player.filter(key: 1)
> let request = Player.filter(keys: [1, 2, 3])
> 
> try Player.deleteOne(db, key: 1)
> try Player.deleteAll(db, keys: [1, 2, 3])
> ```
> **Note**: It is not recommended to use `Identifiable` on record types that use an auto-incremented primary key:
>
> ```swift
> // AVOID declaring Identifiable conformance when key is auto-incremented
> struct Player {
>     var id: Int64? // Not an id suitable for Identifiable
>     var name: String
>     var score: Int
> }
> 
> extension Player: FetchableRecord, MutablePersistableRecord {
>     // Update auto-incremented id upon successful insertion
>     mutating func didInsert(_ inserted: InsertionSuccess) {
>         id = inserted.rowID
>     }
> }
> ```
>
> For a detailed rationale, please see [issue #1435](https://github.com/groue/GRDB.swift/issues/1435#issuecomment-1740857712).
Some database tables have a single-column primary key which is not called "id":
```swift
try db.create(table: "country") { t in
    t.primaryKey("isoCode", .text)
    t.column("name", .text).notNull()
    t.column("population", .integer).notNull()
}
```
