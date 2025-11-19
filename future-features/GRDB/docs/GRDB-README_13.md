- [Record Protocols Overview](#record-protocols-overview)
- [FetchableRecord Protocol](#fetchablerecord-protocol)
- [TableRecord Protocol](#tablerecord-protocol)
- [PersistableRecord Protocol](#persistablerecord-protocol)
    - [Persistence Methods]
    - [Persistence Methods and the `RETURNING` clause]
    - [Persistence Callbacks]
- [Identifiable Records]
- [Codable Records]
- [Record Comparison]
- [Record Customization Options]
- [Record Timestamps and Transaction Date]
### Inserting Records
To insert a record in the database, call the `insert` method:
```swift
let player = Player(id: 1, name: "Arthur", score: 1000)
try player.insert(db)
```
:point_right: `insert` is available for types that adopt the [PersistableRecord] protocol.
### Fetching Records
To fetch records from the database, call a [fetching method](#fetching-methods):
```swift
let arthur = try Player.fetchOne(db,            // Player?
    sql: "SELECT * FROM players WHERE name = ?",
    arguments: ["Arthur"])

let bestPlayers = try Player                    // [Player]
    .order(\.score.desc)
    .limit(10)
    .fetchAll(db)
    
let spain = try Country.fetchOne(db, id: "ES")  // Country?
let italy = try Country.find(db, id: "IT")      // Country
```
:point_right: Fetching from raw SQL is available for types that adopt the [FetchableRecord] protocol.
:point_right: Fetching without SQL, using the [query interface](#the-query-interface), is available for types that adopt both [FetchableRecord] and [TableRecord] protocol.
### Updating Records
To update a record in the database, call the `update` method:
```swift
var player: Player = ...
player.score = 1000
try player.update(db)
```
It is possible to [avoid useless updates](#record-comparison):
```swift
// does not hit the database if score has not changed
try player.updateChanges(db) {
    $0.score = 1000
}
```
See the [query interface](#the-query-interface) for batch updates:
```swift
try Player
    .filter { $0.team == "red" }
    .updateAll(db) { $0.score += 1 }
```
:point_right: update methods are available for types that adopt the [PersistableRecord] protocol. Batch updates are available on the [TableRecord] protocol.
### Deleting Records
To delete a record in the database, call the `delete` method:
```swift
let player: Player = ...
try player.delete(db)
```
You can also delete by primary key, unique key, or perform batch deletes (see [Delete Requests](#delete-requests)):
```swift
try Player.deleteOne(db, id: 1)
try Player.deleteOne(db, key: ["email": "arthur@example.com"])
try Country.deleteAll(db, ids: ["FR", "US"])
try Player
    .filter { $0.email == nil }
    .deleteAll(db)
```
:point_right: delete methods are available for types that adopt the [PersistableRecord] protocol. Batch deletes are available on the [TableRecord] protocol.
### Counting Records
To count records, call the `fetchCount` method:
```swift
let playerCount: Int = try Player.fetchCount(db)

let playerWithEmailCount: Int = try Player
    .filter { $0.email == nil }
    .fetchCount(db)
```
:point_right: `fetchCount` is available for types that adopt the [TableRecord] protocol.
Details follow:
- [Record Protocols Overview](#record-protocols-overview)
- [FetchableRecord Protocol](#fetchablerecord-protocol)
- [TableRecord Protocol](#tablerecord-protocol)
- [PersistableRecord Protocol](#persistablerecord-protocol)
- [Identifiable Records]
- [Codable Records]
- [Record Comparison]
- [Record Customization Options]
- [Examples of Record Definitions](#examples-of-record-definitions)
## Record Protocols Overview
**GRDB ships with three record protocols**. Your own types will adopt one or several of them, according to the abilities you want to extend your types with.
- [FetchableRecord] is able to **decode database rows**.
    ```swift
    struct Place: FetchableRecord { ... }
    
    let places = try dbQueue.read { db in
        try Place.fetchAll(db, sql: "SELECT * FROM place")
    }
    ```
    > :bulb: **Tip**: `FetchableRecord` can derive its implementation from the standard `Decodable` protocol. See [Codable Records] for more information.
    `FetchableRecord` can decode database rows, but it is not able to build SQL requests for you. For that, you also need `TableRecord`:
- [TableRecord] is able to **generate SQL queries**:
    ```swift
    struct Place: TableRecord { ... }
    
    let placeCount = try dbQueue.read { db in
        // Generates and runs `SELECT COUNT(*) FROM place`
        try Place.fetchCount(db)
    }
    ```
    When a type adopts both `TableRecord` and `FetchableRecord`, it can load from those requests:
    ```swift
    struct Place: TableRecord, FetchableRecord { ... }
    
    try dbQueue.read { db in
        let places = try Place.order(\.title).fetchAll(db)
        let paris = try Place.fetchOne(id: 1)
    }
    ```
- [PersistableRecord] is able to **write**: it can create, update, and delete rows in the database:
