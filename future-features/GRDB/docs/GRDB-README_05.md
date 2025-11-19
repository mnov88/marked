## Fetch Queries
[Database connections] let you fetch database rows, plain values, and custom models aka "records".
**Rows** are the raw results of SQL queries:
```swift
try dbQueue.read { db in
    if let row = try Row.fetchOne(db, sql: "SELECT * FROM wine WHERE id = ?", arguments: [1]) {
        let name: String = row["name"]
        let color: Color = row["color"]
        print(name, color)
    }
}
```
**Values** are the Bool, Int, String, Date, Swift enums, etc. stored in row columns:
```swift
try dbQueue.read { db in
    let urls = try URL.fetchCursor(db, sql: "SELECT url FROM wine")
    while let url = try urls.next() {
        print(url)
    }
}
```
**Records** are your application objects that can initialize themselves from rows:
```swift
let wines = try dbQueue.read { db in
    try Wine.fetchAll(db, sql: "SELECT * FROM wine")
}
```
- [Fetching Methods](#fetching-methods) and [Cursors](#cursors)
- [Row Queries](#row-queries)
- [Value Queries](#value-queries)
- [Records](#records)
### Fetching Methods
**Throughout GRDB**, you can always fetch *cursors*, *arrays*, *sets*, or *single values* of any fetchable type (database [row](#row-queries), simple [value](#value-queries), or custom [record](#records)):
```swift
try Row.fetchCursor(...) // A Cursor of Row
try Row.fetchAll(...)    // [Row]
try Row.fetchSet(...)    // Set<Row>
try Row.fetchOne(...)    // Row?
```
- `fetchCursor` returns a **[cursor](#cursors)** over fetched values:
    ```swift
    let rows = try Row.fetchCursor(db, sql: "SELECT ...") // A Cursor of Row
    ```
- `fetchAll` returns an **array**:
    ```swift
    let players = try Player.fetchAll(db, sql: "SELECT ...") // [Player]
    ```
- `fetchSet` returns a **set**:
    ```swift
    let names = try String.fetchSet(db, sql: "SELECT ...") // Set<String>
    ```
- `fetchOne` returns a **single optional value**, and consumes a single database row (if any).
    ```swift
    let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) ...") // Int?
    ```
**All those fetching methods require an SQL string that contains a single SQL statement.** When you want to fetch from multiple statements joined with a semicolon, iterate the multiple [prepared statements] found in the SQL string.
### Cursors
📖 [`Cursor`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/cursor)
**Whenever you consume several rows from the database, you can fetch an Array, a Set, or a Cursor**.
The `fetchAll()` and `fetchSet()` methods return regular Swift array and sets, that you iterate like all other arrays and sets:
```swift
try dbQueue.read { db in
    // [Player]
    let players = try Player.fetchAll(db, sql: "SELECT ...")
    for player in players {
        // use player
    }
}
```
Unlike arrays and sets, cursors returned by `fetchCursor()` load their results step after step:
```swift
try dbQueue.read { db in
    // Cursor of Player
    let players = try Player.fetchCursor(db, sql: "SELECT ...")
    while let player = try players.next() {
        // use player
    }
}
```
- **Cursors can not be used on any thread**: you must consume a cursor on the dispatch queue it was created in. Particularly, don't extract a cursor out of a database access method:
    ```swift
    // Wrong
    let cursor = try dbQueue.read { db in
        try Player.fetchCursor(db, ...)
    }
    while let player = try cursor.next() { ... }
    ```
    Conversely, arrays and sets may be consumed on any thread:
    ```swift
    // OK
    let array = try dbQueue.read { db in
        try Player.fetchAll(db, ...)
    }
    for player in array { ... }
    ```
- **Cursors can be iterated only one time.** Arrays and sets can be iterated many times.
- **Cursors iterate database results in a lazy fashion**, and don't consume much memory. Arrays and sets contain copies of database values, and may take a lot of memory when there are many fetched results.
- **Cursors are granted with direct access to SQLite,** unlike arrays and sets that have to take the time to copy database values. If you look after extra performance, you may prefer cursors.
- **Cursors can feed Swift collections.**
    You will most of the time use `fetchAll` or `fetchSet` when you want an array or a set. For more specific needs, you may prefer one of the initializers below. All of them accept an extra optional `minimumCapacity` argument which helps optimizing your app when you have an idea of the number of elements in a cursor (the built-in `fetchAll` and `fetchSet` do not perform such an optimization).
    **Arrays** and all types conforming to `RangeReplaceableCollection`:
    ```swift
    // [String]
    let cursor = try String.fetchCursor(db, ...)
    let array = try Array(cursor)
    ```
    **Sets**:
    ```swift
    // Set<Int>
    let cursor = try Int.fetchCursor(db, ...)
    let set = try Set(cursor)
    ```
    **Dictionaries**:
    ```swift
    // [Int64: [Player]]
    let cursor = try Player.fetchCursor(db)
    let dictionary = try Dictionary(grouping: cursor, by: { $0.teamID })
    
    // [Int64: Player]
    let cursor = try Player.fetchCursor(db).map { ($0.id, $0) }
    let dictionary = try Dictionary(uniqueKeysWithValues: cursor)
    ```
- **Cursors adopt the [Cursor](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/cursor) protocol, which looks a lot like standard [lazy sequences](https://developer.apple.com/reference/swift/lazysequenceprotocol) of Swift.** As such, cursors come with many convenience methods: `compactMap`, `contains`, `dropFirst`, `dropLast`, `drop(while:)`, `enumerated`, `filter`, `first`, `flatMap`, `forEach`, `joined`, `joined(separator:)`, `max`, `max(by:)`, `min`, `min(by:)`, `map`, `prefix`, `prefix(while:)`, `reduce`, `reduce(into:)`, `suffix`:
    ```swift
    // Prints all Github links
    try URL
        .fetchCursor(db, sql: "SELECT url FROM link")
        .filter { url in url.host == "github.com" }
        .forEach { url in print(url) }
    
    // An efficient cursor of coordinates:
    let locations = try Row.
        .fetchCursor(db, sql: "SELECT latitude, longitude FROM place")
        .map { row in
            CLLocationCoordinate2D(latitude: row[0], longitude: row[1])
        }
    ```
- **Cursors are not Swift sequences.** That's because Swift sequences can't handle iteration errors, when reading SQLite results may fail at any time.
- **Cursors require a little care**:
    - Don't modify the results during a cursor iteration:
        ```swift
        // Undefined behavior
        while let player = try players.next() {
            try db.execute(sql: "DELETE ...")
        }
        ```
    - Don't turn a cursor of `Row` into an array or a set. You would not get the distinct rows you expect. To get a array of rows, use `Row.fetchAll(...)`. To get a set of rows, use `Row.fetchSet(...)`. Generally speaking, make sure you copy a row whenever you extract it from a cursor for later use: `row.copy()`.
If you don't see, or don't care about the difference, use arrays. If you care about memory and performance, use cursors when appropriate.
### Row Queries
- [Fetching Rows](#fetching-rows)
- [Column Values](#column-values)
- [DatabaseValue](#databasevalue)
- [Rows as Dictionaries](#rows-as-dictionaries)
- 📖 [`Row`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/row)
#### Fetching Rows
Fetch **cursors** of rows, **arrays**, **sets**, or **single** rows (see [fetching methods](#fetching-methods)):
```swift
try dbQueue.read { db in
    try Row.fetchCursor(db, sql: "SELECT ...", arguments: ...) // A Cursor of Row
    try Row.fetchAll(db, sql: "SELECT ...", arguments: ...)    // [Row]
    try Row.fetchSet(db, sql: "SELECT ...", arguments: ...)    // Set<Row>
    try Row.fetchOne(db, sql: "SELECT ...", arguments: ...)    // Row?
    
    let rows = try Row.fetchCursor(db, sql: "SELECT * FROM wine")
    while let row = try rows.next() {
        let name: String = row["name"]
        let color: Color = row["color"]
        print(name, color)
    }
}

let rows = try dbQueue.read { db in
    try Row.fetchAll(db, sql: "SELECT * FROM player")
}
```
Arguments are optional arrays or dictionaries that fill the positional `?` and colon-prefixed keys like `:name` in the query:
```swift
let rows = try Row.fetchAll(db,
    sql: "SELECT * FROM player WHERE name = ?",
    arguments: ["Arthur"])

let rows = try Row.fetchAll(db,
    sql: "SELECT * FROM player WHERE name = :name",
    arguments: ["name": "Arthur"])
```
See [Values](#values) for more information on supported arguments types (Bool, Int, String, Date, Swift enums, etc.), and [`StatementArguments`] for a detailed documentation of SQLite arguments.
Unlike row arrays that contain copies of the database rows, row cursors are close to the SQLite metal, and require a little care:
> **Note**: **Don't turn a cursor of `Row` into an array or a set**. You would not get the distinct rows you expect. To get a array of rows, use `Row.fetchAll(...)`. To get a set of rows, use `Row.fetchSet(...)`. Generally speaking, make sure you copy a row whenever you extract it from a cursor for later use: `row.copy()`.
