In this case, `Identifiable` conformance can be achieved, for example, by returning the primary key column from the `id` property:
```swift
struct Country: Identifiable, FetchableRecord, PersistableRecord {
    var isoCode: String
    var name: String
    var population: Int
    
    // Fulfill the Identifiable requirement
    var id: String { isoCode }
}

let france = try dbQueue.read { db in
    try Country.fetchOne(db, id: "FR")
}
```
## Codable Records
Record types that adopt an archival protocol ([Codable, Encodable or Decodable](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)) get free database support just by declaring conformance to the desired [record protocols](#record-protocols-overview):
```swift
// Declare a record...
struct Player: Codable, FetchableRecord, PersistableRecord {
    var id: Int64
    var name: String
    var score: Int
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}

// ...and there you go:
try dbQueue.write { db in
    try Player(id: 1, name: "Arthur", score: 100).insert(db)
    let players = try Player.order(\.score.desc).fetchAll(db)
}
```
Codable records encode and decode their properties according to their own implementation of the Encodable and Decodable protocols. Yet databases have specific requirements:
- Properties are always coded according to their preferred database representation, when they have one (all [values](#values) that adopt the [`DatabaseValueConvertible`] protocol).
- You can customize the encoding and decoding of dates and uuids.
- Complex properties (arrays, dictionaries, nested structs, etc.) are stored as JSON.
For more information about Codable records, see:
- [JSON Columns]
- [Column Names Coding Strategies]
- [Data, Date, and UUID Coding Strategies]
- [The userInfo Dictionary]
- [Tip: Derive Columns from Coding Keys](#tip-derive-columns-from-coding-keys)
> :bulb: **Tip**: see the [Demo Applications] for sample code that uses Codable records.
### JSON Columns
When a [Codable record](#codable-records) contains a property that is not a simple [value](#values) (Bool, Int, String, Date, Swift enums, etc.), that value is encoded and decoded as a **JSON string**. For example:
```swift
enum AchievementColor: String, Codable {
    case bronze, silver, gold
}

struct Achievement: Codable {
    var name: String
    var color: AchievementColor
}

struct Player: Codable, FetchableRecord, PersistableRecord {
    var name: String
    var score: Int
    var achievements: [Achievement] // stored in a JSON column
}

try dbQueue.write { db in
    // INSERT INTO player (name, score, achievements)
    // VALUES (
    //   'Arthur',
    //   100,
    //   '[{"color":"gold","name":"Use Codable Records"}]')
    let achievement = Achievement(name: "Use Codable Records", color: .gold)
    let player = Player(name: "Arthur", score: 100, achievements: [achievement])
    try player.insert(db)
}
```
GRDB uses the standard [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder) and [JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder) from Foundation. By default, Data values are handled with the `.base64` strategy, Date with the `.millisecondsSince1970` strategy, and non conforming floats with the `.throw` strategy.
You can customize the JSON format by implementing those methods:
```swift
protocol FetchableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder
}

protocol EncodableRecord {
    static func databaseJSONEncoder(for column: String) -> JSONEncoder
}
```
> :bulb: **Tip**: Make sure you set the JSONEncoder `sortedKeys` option. This option makes sure that the JSON output is stable. This stability is required for [Record Comparison] to work as expected, and database observation tools such as [ValueObservation] to accurately recognize changed records.
### Column Names Coding Strategies
By default, [Codable Records] store their values into database columns that match their coding keys: the `teamID` property is stored into the `teamID` column.
This behavior can be overridden, so that you can, for example, store the `teamID` property into the `team_id` column:
```swift
protocol FetchableRecord {
    static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy { get }
}

protocol EncodableRecord {
    static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy { get }
}
```
See [DatabaseColumnDecodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasecolumndecodingstrategy) and [DatabaseColumnEncodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasecolumnencodingstrategy/) to learn about all available strategies.
### Data, Date, and UUID Coding Strategies
By default, [Codable Records] encode and decode their Data properties as blobs, and Date and UUID properties as described in the general [Date and DateComponents](#date-and-datecomponents) and [UUID](#uuid) chapters.
