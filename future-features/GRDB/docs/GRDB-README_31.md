See [fetching methods](#fetching-methods) for information about the `fetchCursor`, `fetchAll`, `fetchSet` and `fetchOne` methods.
**You sometimes want to fetch other values**.
The simplest way is to use the request as an argument to a fetching method of the desired type:
```swift
// Fetch an Int
let request = Player.select { max($0.score) }
let maxScore = try Int.fetchOne(db, request) // Int?

// Fetch a Row
let request = Player.select { [min($0.score), max($0.score)] }
let row = try Row.fetchOne(db, request)!     // Row
let minScore = row[0] as Int?
let maxScore = row[1] as Int?
```
You can also change the request so that it knows the type it has to fetch:
- With `asRequest(of:)`, useful when you use [Associations]:
    ```swift
    struct BookInfo: FetchableRecord, Decodable {
        var book: Book
        var author: Author
    }
    
    // A request of BookInfo
    let request = Book
        .including(required: Book.author)
        .asRequest(of: BookInfo.self)
    
    let bookInfos = try dbQueue.read { db in
        try request.fetchAll(db) // [BookInfo]
    }
    ```
- With `select(..., as:)`, which is handy when you change the selection:
    ```swift
    // A request of Int
    let request = Player.select({ max($0.score) }, as: Int.self)
    
    let maxScore = try dbQueue.read { db in
        try request.fetchOne(db) // Int?
    }
    ```
## Fetching by Key
**Fetching records according to their primary key** is a common task.
[Identifiable Records] can use the type-safe methods `find(_:id:)`, `fetchOne(_:id:)`, `fetchAll(_:ids:)` and `fetchSet(_:ids:)`:
```swift
try Player.find(db, id: 1)                   // Player
try Player.fetchOne(db, id: 1)               // Player?
try Country.fetchAll(db, ids: ["FR", "US"])  // [Countries]
```
All record types can use `find(_:key:)`, `fetchOne(_:key:)`, `fetchAll(_:keys:)` and `fetchSet(_:keys:)` that apply conditions on primary and unique keys:
```swift
try Player.find(db, key: 1)                  // Player
try Player.fetchOne(db, key: 1)              // Player?
try Country.fetchAll(db, keys: ["FR", "US"]) // [Country]
try Player.fetchOne(db, key: ["email": "arthur@example.com"])            // Player?
try Citizenship.fetchOne(db, key: ["citizenId": 1, "countryCode": "FR"]) // Citizenship?
```
When the table has no explicit primary key, GRDB uses the [hidden `rowid` column](https://www.sqlite.org/rowidtable.html):
```swift
// SELECT * FROM document WHERE rowid = 1
try Document.fetchOne(db, key: 1)            // Document?
```
**When you want to build a request and plan to fetch from it later**, use a `filter` method:
```swift
let request = Player.filter(id: 1)
let request = Country.filter(ids: ["FR", "US"])
let request = Player.filter(key: ["email": "arthur@example.com"])
let request = Citizenship.filter(key: ["citizenId": 1, "countryCode": "FR"])
```
## Testing for Record Existence
**You can check if a request has matching rows in the database.**
```swift
// Some request based on `Player`
let request = Player.filter { ... }...

// Check for player existence:
let noSuchPlayer = try request.isEmpty(db) // Bool
```
You should check for emptiness instead of counting:
```swift
// Correct
let noSuchPlayer = try request.fetchCount(db) == 0
// Even better
let noSuchPlayer = try request.isEmpty(db)
```
**You can also check if a given primary or unique key exists in the database.**
[Identifiable Records] can use the type-safe method `exists(_:id:)`:
```swift
try Player.exists(db, id: 1)
try Country.exists(db, id: "FR")
```
All record types can use `exists(_:key:)` that can check primary and unique keys:
```swift
try Player.exists(db, key: 1)
try Country.exists(db, key: "FR")
try Player.exists(db, key: ["email": "arthur@example.com"])
try Citizenship.exists(db, key: ["citizenId": 1, "countryCode": "FR"])
```
You should check for key existence instead of fetching a record and checking for nil:
```swift
// Correct
let playerExists = try Player.fetchOne(db, id: 1) != nil
// Even better
let playerExists = try Player.exists(db, id: 1)
```
## Fetching Aggregated Values
**Requests can count.** The `fetchCount()` method returns the number of rows that would be returned by a fetch request:
```swift
// SELECT COUNT(*) FROM player
let count = try Player.fetchCount(db) // Int

// SELECT COUNT(*) FROM player WHERE email IS NOT NULL
let count = try Player.filter { $0.email != nil }.fetchCount(db)

// SELECT COUNT(DISTINCT name) FROM player
let count = try Player.select(\.name).distinct().fetchCount(db)

// SELECT COUNT(*) FROM (SELECT DISTINCT name, score FROM player)
let count = try Player.select { [$0.name, $0.score] }.distinct().fetchCount(db)
```
