Yes, three protocols instead of one. Here is how you pick one or the other:
- **If your type is a class**, choose `PersistableRecord`. On top of that, implement `didInsert(_:)` if the database table has an auto-incremented primary key.
- **If your type is a struct, and the database table has an auto-incremented primary key**, choose `MutablePersistableRecord`, and implement `didInsert(_:)`.
- **Otherwise**, choose `PersistableRecord`, and ignore `didInsert(_:)`.
The `encode(to:)` method defines which [values](#values) (Bool, Int, String, Date, Swift enums, etc.) are assigned to database columns.
The optional `didInsert` method lets the adopting type store its rowID after successful insertion, and is only useful for tables that have an auto-incremented primary key. It is called from a protected dispatch queue, and serialized with all database updates.
For example:
```swift
extension Place: MutablePersistableRecord {
    enum Columns {
        static let id = Column("id")
        static let title = Column("title")
        static let latitude = Column("latitude")
        static let longitude = Column("longitude")
    }
    
    /// The values persisted in the database
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.title] = title
        container[Columns.latitude] = coordinate.latitude
        container[Columns.longitude] = coordinate.longitude
    }
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

var paris = Place(
    id: nil,
    title: "Paris",
    coordinate: CLLocationCoordinate2D(latitude: 48.8534100, longitude: 2.3488000))

try paris.insert(db)
paris.id   // some value
```
When your record type adopts the standard Encodable protocol, you don't have to provide the implementation for `encode(to:)`. See [Codable Records] for more information:
```swift
// That's all
struct Player: Encodable, MutablePersistableRecord {
    var id: Int64?
    var name: String
    var score: Int
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```
### Persistence Methods
Types that adopt the [PersistableRecord] protocol are given methods that insert, update, and delete:
```swift
// INSERT
try place.insert(db)
let insertedPlace = try place.inserted(db) // non-mutating

// UPDATE
try place.update(db)
try place.update(db, columns: ["title"])

// Maybe UPDATE
try place.updateChanges(db, from: otherPlace)
try place.updateChanges(db) { $0.isFavorite = true }

// INSERT or UPDATE
try place.save(db)
let savedPlace = place.saved(db) // non-mutating

// UPSERT
try place.upsert(db)
let insertedPlace = place.upsertAndFetch(db)

// DELETE
try place.delete(db)

// EXISTENCE CHECK
let exists = try place.exists(db)
```
See [Upsert](#upsert) below for more information about upserts.
**The [TableRecord] protocol comes with batch operations**:
```swift
// UPDATE
try Place.updateAll(db, ...)

// DELETE
try Place.deleteAll(db)
try Place.deleteAll(db, ids:...)
try Place.deleteAll(db, keys:...)
try Place.deleteOne(db, id:...)
try Place.deleteOne(db, key:...)
```
For more information about batch updates, see [Update Requests](#update-requests).
- All persistence methods can throw a [DatabaseError](#error-handling).
- `update` and `updateChanges` throw [RecordError] if the database does not contain any row for the primary key of the record.
- `save` makes sure your values are stored in the database. It performs an UPDATE if the record has a non-null primary key, and then, if no row was modified, an INSERT. It directly performs an INSERT if the record has no primary key, or a null primary key.
- `delete` and `deleteOne` returns whether a database row was deleted or not. `deleteAll` returns the number of deleted rows. `updateAll` returns the number of updated rows. `updateChanges` returns whether a database row was updated or not.
**All primary keys are supported**, including composite primary keys that span several columns, and the [hidden `rowid` column](https://www.sqlite.org/rowidtable.html).
**To customize persistence methods**, you provide [Persistence Callbacks], described below. Do not attempt at overriding the ready-made persistence methods.
