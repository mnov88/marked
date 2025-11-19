    ```swift
    struct Place : PersistableRecord { ... }
    
    try dbQueue.write { db in
        try Place.delete(db, id: 1)
        try Place(...).insert(db)
    }
    ```
    A persistable record can also [compare](#record-comparison) itself against other records, and avoid useless database updates.
    > :bulb: **Tip**: `PersistableRecord` can derive its implementation from the standard `Encodable` protocol. See [Codable Records] for more information.
## FetchableRecord Protocol
📖 [`FetchableRecord`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/fetchablerecord)
**The FetchableRecord protocol grants fetching methods to any type** that can be built from a database row:
```swift
protocol FetchableRecord {
    /// Row initializer
    init(row: Row) throws
}
```
For example:
```swift
struct Place {
    var id: Int64?
    var title: String
    var coordinate: CLLocationCoordinate2D
}

extension Place: FetchableRecord {
    enum Columns {
        static let id = Column("id")
        static let title = Column("title")
        static let latitude = Column("latitude")
        static let longitude = Column("longitude")
    }
    
    init(row: Row) {
        id = row[Columns.id]
        title = row[Columns.title]
        coordinate = CLLocationCoordinate2D(
            latitude: row[Columns.latitude],
            longitude: row[Columns.longitude])
    }
}
```
See [column values](#column-values) for more information about the `row[]` subscript.
When your record type adopts the standard Decodable protocol, you don't have to provide the implementation for `init(row:)`. See [Codable Records] for more information:
```swift
// That's all
struct Player: Decodable, FetchableRecord {
    var id: Int64
    var name: String
    var score: Int
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}
```
FetchableRecord allows adopting types to be fetched from SQL queries:
```swift
try Place.fetchCursor(db, sql: "SELECT ...", arguments:...) // A Cursor of Place
try Place.fetchAll(db, sql: "SELECT ...", arguments:...)    // [Place]
try Place.fetchSet(db, sql: "SELECT ...", arguments:...)    // Set<Place>
try Place.fetchOne(db, sql: "SELECT ...", arguments:...)    // Place?
```
See [fetching methods](#fetching-methods) for information about the `fetchCursor`, `fetchAll`, `fetchSet` and `fetchOne` methods. See [`StatementArguments`] for more information about the query arguments.
> **Note**: for performance reasons, the same row argument to `init(row:)` is reused during the iteration of a fetch query. If you want to keep the row for later use, make sure to store a copy: `self.row = row.copy()`.
> **Note**: The `FetchableRecord.init(row:)` initializer fits the needs of most applications. But some application are more demanding than others. When FetchableRecord does not exactly provide the support you need, have a look at the [Beyond FetchableRecord] chapter.
## TableRecord Protocol
📖 [`TableRecord`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerecord)
**The TableRecord protocol** generates SQL for you:
```swift
protocol TableRecord {
    static var databaseTableName: String { get }
    static var databaseSelection: [any SQLSelectable] { get }
}
```
The `databaseSelection` type property is optional, and documented in the [Columns Selected by a Request] chapter.
The `databaseTableName` type property is the name of a database table. By default, it is derived from the type name:
```swift
struct Place: TableRecord { }

print(Place.databaseTableName) // prints "place"
```
For example:
- Place: `place`
- Country: `country`
- PostalAddress: `postalAddress`
- HTTPRequest: `httpRequest`
- TOEFL: `toefl`
You can still provide a custom table name:
```swift
struct Place: TableRecord {
    static let databaseTableName = "location"
}

print(Place.databaseTableName) // prints "location"
```
When a type adopts both TableRecord and [FetchableRecord](#fetchablerecord-protocol), it can be fetched using the [query interface](#the-query-interface):
```swift
// SELECT * FROM place WHERE name = 'Paris'
let paris = try Place.filter { $0.name == "Paris" }.fetchOne(db)
```
TableRecord can also fetch deal with primary and unique keys: see [Fetching by Key](#fetching-by-key) and [Testing for Record Existence](#testing-for-record-existence).
## PersistableRecord Protocol
📖 [`EncodableRecord`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/encodablerecord), [`MutablePersistableRecord`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/mutablepersistablerecord), [`PersistableRecord`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/persistablerecord)
**GRDB record types can create, update, and delete rows in the database.**
Those abilities are granted by three protocols:
```swift
// Defines how a record encodes itself into the database
protocol EncodableRecord {
    /// Defines the values persisted in the database
    func encode(to container: inout PersistenceContainer) throws
}

// Adds persistence methods
protocol MutablePersistableRecord: TableRecord, EncodableRecord {
    /// Optional method that lets your adopting type store its rowID upon
    /// successful insertion. Don't call it directly: it is called for you.
    mutating func didInsert(_ inserted: InsertionSuccess)
}

// Adds immutability
protocol PersistableRecord: MutablePersistableRecord {
    /// Non-mutating version of the optional didInsert(_:)
    func didInsert(_ inserted: InsertionSuccess)
}
```
