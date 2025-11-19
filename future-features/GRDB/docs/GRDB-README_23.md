</details>
<details>
  <summary>Define a plain struct, and adopt the record protocols you need</summary>
See the [Record Protocols Overview](#record-protocols-overview) for more information.
```swift
struct Place {
    var id: Int64?
    var title: String
    var isFavorite: Bool
    var coordinate: CLLocationCoordinate2D
}

// SQL generation
extension Place: TableRecord {
    /// The table columns
    enum Columns {
        static let id = Column("id")
        static let title = Column("title")
        static let isFavorite = Column("isFavorite")
        static let latitude = Column("latitude")
        static let longitude = Column("longitude")
    }
}

// Fetching methods
extension Place: FetchableRecord {
    /// Creates a record from a database row
    init(row: Row) {
        id = row[Columns.id]
        title = row[Columns.title]
        isFavorite = row[Columns.isFavorite]
        coordinate = CLLocationCoordinate2D(
            latitude: row[Columns.latitude],
            longitude: row[Columns.longitude])
    }
}

// Persistence methods
extension Place: MutablePersistableRecord {
    /// The values persisted in the database
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.title] = title
        container[Columns.isFavorite] = isFavorite
        container[Columns.latitude] = coordinate.latitude
        container[Columns.longitude] = coordinate.longitude
    }
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```
</details>
<details>
  <summary>Define a plain struct optimized for fetching performance</summary>
This struct derives its persistence methods from the standard Encodable protocol (see [Codable Records]), but performs optimized row decoding by accessing database columns with numeric indexes.
See the [Record Protocols Overview](#record-protocols-overview) for more information.
```swift
struct Place: Encodable {
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
    
    /// Arrange the selected columns and lock their order
    static var databaseSelection: [any SQLSelectable] {
        [
            Columns.id,
            Columns.title,
            Columns.favorite,
            Columns.latitude,
            Columns.longitude,
        ]
    }
}

// Fetching methods
extension Place: FetchableRecord {
    /// Creates a record from a database row
    init(row: Row) {
        // For high performance, use numeric indexes that match the
        // order of Place.databaseSelection
        id = row[0]
        title = row[1]
        isFavorite = row[2]
        coordinate = CLLocationCoordinate2D(
            latitude: row[3],
            longitude: row[4])
    }
}

// Persistence methods
extension Place: MutablePersistableRecord {
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```
</details>
The Query Interface
===================
**The query interface lets you write pure Swift instead of SQL:**
```swift
try dbQueue.write { db in
    // Update database schema
    try db.create(table: "player") { t in ... }
    
    // Fetch records
    let bestPlayers = try Player
        .order(\.score.desc)
        .limit(10)
        .fetchAll(db)
    
    // Count
    let count = try Player
        .filter { $0.score >= 1000 }
        .fetchCount(db)
    
    // Batch update
    try Player
        .filter { $0.team == "Reds" }
        .updateAll(db) { $0.score += 100 }
    
    // Batch delete
    try Player
        .filter { $0.score == 0 }
        .deleteAll(db)
}
```
You need to open a [database connection] before you can query the database.
Please bear in mind that the query interface can not generate all possible SQL queries. You may also *prefer* writing SQL, and this is just OK. From little snippets to full queries, your SQL skills are welcome:
```swift
try dbQueue.write { db in
    // Update database schema (with SQL)
    try db.execute(sql: "CREATE TABLE player (...)")
    
    // Fetch records (with SQL)
    let bestPlayers = try Player.fetchAll(db, sql: """
        SELECT * FROM player ORDER BY score DESC LIMIT 10
        """)
    
    // Count (with an SQL snippet)
    let minScore = 1000
    let count = try Player
        .filter(sql: "score >= ?", arguments: [minScore])
        .fetchCount(db)
    
    // Update (with SQL)
    try db.execute(sql: "UPDATE player SET score = score + 100 WHERE team = 'Reds'")
    
    // Delete (with SQL)
    try db.execute(sql: "DELETE FROM player WHERE score = 0")
}
```
So don't miss the [SQL API](#sqlite-api).
