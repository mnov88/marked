- In each modification query:
    ```swift
    // CREATE TABLE player (
    //     id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     email TEXT UNIQUE
    // )
    try db.create(table: "player") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("email", .text).unique()
    }
    
    // Again, despite the unique index on email, both inserts succeed.
    try db.execute(sql: "INSERT OR REPLACE INTO player (email) VALUES (?)", arguments: ["arthur@example.com"])
    try db.execute(sql: "INSERT OR REPLACE INTO player (email) VALUES (?)", arguments: ["arthur@example.com"])
    ```
When you want to handle conflicts at the query level, specify a custom `persistenceConflictPolicy` in your type that adopts the PersistableRecord protocol. It will alter the INSERT and UPDATE queries run by the `insert`, `update` and `save` [persistence methods]:
```swift
protocol MutablePersistableRecord {
    /// The policy that handles SQLite conflicts when records are
    /// inserted or updated.
    ///
    /// This property is optional: its default value uses the ABORT
    /// policy for both insertions and updates, so that GRDB generate
    /// regular INSERT and UPDATE queries.
    static var persistenceConflictPolicy: PersistenceConflictPolicy { get }
}

struct Player : MutablePersistableRecord {
    static let persistenceConflictPolicy = PersistenceConflictPolicy(
        insert: .replace,
        update: .replace)
}

// INSERT OR REPLACE INTO player (...) VALUES (...)
try player.insert(db)
```
> **Note**: If you specify the `ignore` policy for inserts, the [`didInsert` callback](#persistence-callbacks) will be called with some random id in case of failed insert. You can detect failed insertions with `insertAndFetch`:
>     
> ```swift
> // How to detect failed `INSERT OR IGNORE`:
> // INSERT OR IGNORE INTO player ... RETURNING *
> do {
>     let insertedPlayer = try player.insertAndFetch(db) {
>     // Successful insertion
> catch RecordError.recordNotFound {
>     // Failed insertion due to IGNORE policy
> }
> ```
>
> **Note**: The `replace` policy may have to delete rows so that inserts and updates can succeed. Those deletions are not reported to [transaction observers](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/transactionobserver) (this might change in a future release of SQLite).
### Beyond FetchableRecord
**Some GRDB users eventually discover that the [FetchableRecord] protocol does not fit all situations.** Use cases that are not well handled by FetchableRecord include:
- Your application needs polymorphic row decoding: it decodes some type or another, depending on the values contained in a database row.
- Your application needs to decode rows with a context: each decoded value should be initialized with some extra value that does not come from the database.
Since those use cases are not well handled by FetchableRecord, don't try to implement them on top of this protocol: you'll just fight the framework.
## Examples of Record Definitions
We will show below how to declare a record type for the following database table:
```swift
try dbQueue.write { db in
    try db.create(table: "place") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("title", .text).notNull()
        t.column("isFavorite", .boolean).notNull().defaults(to: false)
        t.column("longitude", .double).notNull()
        t.column("latitude", .double).notNull()
    }
}
```
Each one of the three examples below is correct. You will pick one or the other depending on your personal preferences and the requirements of your application:
<details>
  <summary>Define a Codable struct, and adopt the record protocols you need</summary>
This is the shortest way to define a record type.
See the [Record Protocols Overview](#record-protocols-overview), and [Codable Records] for more information.
```swift
struct Place: Codable {
    var id: Int64?
    var title: String
    var isFavorite: Bool
    private var latitude: CLLocationDegrees
    private var longitude: CLLocationDegrees
    
    var coordinate: CLLocationCoordinate2D {
        get {
            CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}

// SQL generation
extension Place: TableRecord {
    /// The table columns
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let isFavorite = Column(CodingKeys.isFavorite)
        static let latitude = Column(CodingKeys.latitude)
        static let longitude = Column(CodingKeys.longitude)
    }
}

// Fetching methods
extension Place: FetchableRecord { }

// Persistence methods
extension Place: MutablePersistableRecord {
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```
