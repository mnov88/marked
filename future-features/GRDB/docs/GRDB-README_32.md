**Other aggregated values** can also be selected and fetched (see [SQL Functions](#sql-functions)):
```swift
let request = Player.select { max($0.score) }
let maxScore = try Int.fetchOne(db, request) // Int?

let request = Player.select { [min($0.score), max($0.score)] }
let row = try Row.fetchOne(db, request)!     // Row
let minScore = row[0] as Int?
let maxScore = row[1] as Int?
```
## Delete Requests
**Requests can delete records**, with the `deleteAll()` method:
```swift
// DELETE FROM player
try Player.deleteAll(db)

// DELETE FROM player WHERE team = 'Reds'
try Player
    .filter { $0.team == "Reds" }
    .deleteAll(db)

// DELETE FROM player ORDER BY score LIMIT 10
try Player
    .order(\.score)
    .limit(10)
    .deleteAll(db)
```
> **Note** Deletion methods are available on types that adopt the [TableRecord] protocol, and `Table`:
>
> ```swift
> struct Player: TableRecord { ... }
> try Player.deleteAll(db)          // Fine
> try Table("player").deleteAll(db) // Just as fine
> ```
**Deleting records according to their primary key** is a common task.
[Identifiable Records] can use the type-safe methods `deleteOne(_:id:)` and `deleteAll(_:ids:)`:
```swift
try Player.deleteOne(db, id: 1)
try Country.deleteAll(db, ids: ["FR", "US"])
```
All record types can use `deleteOne(_:key:)` and `deleteAll(_:keys:)` that apply conditions on primary and unique keys:
```swift
try Player.deleteOne(db, key: 1)
try Country.deleteAll(db, keys: ["FR", "US"])
try Player.deleteOne(db, key: ["email": "arthur@example.com"])
try Citizenship.deleteOne(db, key: ["citizenId": 1, "countryCode": "FR"])
```
When the table has no explicit primary key, GRDB uses the [hidden `rowid` column](https://www.sqlite.org/rowidtable.html):
```swift
// DELETE FROM document WHERE rowid = 1
try Document.deleteOne(db, id: 1)             // Document?
```
## Update Requests
**Requests can batch update records**. The `updateAll()` method accepts *column assignments* defined with the `set(to:)` method:
```swift
// UPDATE player SET score = 0, isHealthy = 1, bonus = NULL
try Player.updateAll(db) { [
    $0.score.set(to: 0), 
    $0.isHealthy.set(to: true), 
    $0.bonus.set(to: nil),
] }

// UPDATE player SET score = 0 WHERE team = 'Reds'
try Player
    .filter { $0.team == "Reds" }
    .updateAll(db) { $0.score.set(to: 0) }

// UPDATE player SET isGreat = 1 ORDER BY score DESC LIMIT 10
try Player
    .order(\.score.desc)
    .limit(10)
    .updateAll(db) { $0.isGreat.set(to: true) }

// UPDATE country SET population = 67848156 WHERE id = 'FR'
try Country
    .filter(id: "FR")
    .updateAll(db) { $0.population.set(to: 67_848_156) }
```
Column assignments accept any expression:
```swift
// UPDATE player SET score = score + (bonus * 2)
try Player.updateAll(db) {
    $0.score.set(to: $0.score + $0.bonus * 2)
}
```
As a convenience, you can also use the `+=`, `-=`, `*=`, or `/=` operators:
```swift
// UPDATE player SET score = score + (bonus * 2)
try Player.updateAll(db) { $0.score += $0.bonus * 2 }
```
Default [Conflict Resolution] rules apply, and you may also provide a specific one:
```swift
// UPDATE OR IGNORE player SET ...
try Player.updateAll(db, onConflict: .ignore) { /* assignments... */ }
```
> **Note** The `updateAll` method is available on types that adopt the [TableRecord] protocol, and `Table`:
>
> ```swift
> struct Player: TableRecord { ... }
> try Player.updateAll(db, ...)          // Fine
> try Table("player").updateAll(db, ...) // Just as fine
> ```
## Custom Requests
Until now, we have seen [requests](#requests) created from any type that adopts the [TableRecord] protocol:
```swift
let request = Player.all()  // QueryInterfaceRequest<Player>
```
Those requests of type `QueryInterfaceRequest` can fetch and count:
```swift
try request.fetchCursor(db) // A Cursor of Player
try request.fetchAll(db)    // [Player]
try request.fetchSet(db)    // Set<Player>
try request.fetchOne(db)    // Player?
try request.fetchCount(db)  // Int
```
**When the query interface can not generate the SQL you need**, you can still fallback to [raw SQL](#fetch-queries):
```swift
// Custom SQL is always welcome
try Player.fetchAll(db, sql: "SELECT ...")   // [Player]
```
But you may prefer to bring some elegance back in, and build custom requests:
```swift
// No custom SQL in sight
try Player.customRequest().fetchAll(db) // [Player]
```
