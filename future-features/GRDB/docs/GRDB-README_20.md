To sum up: dates encode themselves in the "YYYY-MM-DD HH:MM:SS.SSS" format, in the UTC time zone, and decode a variety of date formats and timestamps. UUIDs encode themselves as 16-bytes data blobs, and decode both 16-bytes data blobs and strings such as "E621E1F8-C36C-495A-93FC-0C247A3E6E5F".
Those behaviors can be overridden:
```swift
protocol FetchableRecord {
    static func databaseDataDecodingStrategy(for column: String) -> DatabaseDataDecodingStrategy
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy
}

protocol EncodableRecord {
    static func databaseDataEncodingStrategy(for column: String) -> DatabaseDataEncodingStrategy
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy
    static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy
}
```
See [DatabaseDataDecodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasedatadecodingstrategy/), [DatabaseDateDecodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasedatedecodingstrategy/), [DatabaseDataEncodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasedataencodingstrategy/), [DatabaseDateEncodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasedateencodingstrategy/), and [DatabaseUUIDEncodingStrategy](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseuuidencodingstrategy/) to learn about all available strategies.
There is no customization of uuid decoding, because UUID can already decode all its encoded variants (16-bytes blobs and uuid strings, both uppercase and lowercase).
Customized coding strategies apply:
- When encoding and decoding database rows to and from records (fetching and persistence methods).
- In requests by single-column primary key: `fetchOne(_:id:)`, `filter(id:)`, `deleteAll(_:keys:)`, etc.
*They do not apply* in other requests based on data, date, or uuid values.
So make sure that those are properly encoded in your requests. For example:
```swift
struct Player: Codable, FetchableRecord, PersistableRecord, Identifiable {
    // UUIDs are stored as strings
    static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        .uppercaseString
    }
    
    var id: UUID
    ...
}

try dbQueue.write { db in
    let uuid = UUID()
    let player = Player(id: uuid, ...)
    
    // OK: inserts a player in the database, with a string uuid
    try player.insert(db)
    
    // OK: performs a string-based query, finds the inserted player
    _ = try Player.filter(id: uuid).fetchOne(db)

    // NOT OK: performs a blob-based query, fails to find the inserted player
    _ = try Player.filter { $0.id == uuid }.fetchOne(db)
    
    // OK: performs a string-based query, finds the inserted player
    _ = try Player.filter { $0.id == uuid.uuidString }.fetchOne(db)
}
```
### The userInfo Dictionary
Your [Codable Records] can be stored in the database, but they may also have other purposes. In this case, you may need to customize their implementations of `Decodable.init(from:)` and `Encodable.encode(to:)`, depending on the context.
The standard way to provide such context is the `userInfo` dictionary. Implement those properties:
```swift
protocol FetchableRecord {
    static var databaseDecodingUserInfo: [CodingUserInfoKey: Any] { get }
}

protocol EncodableRecord {
    static var databaseEncodingUserInfo: [CodingUserInfoKey: Any] { get }
}
```
For example, here is a Player type that customizes its decoding:
```swift
// A key that holds a decoder's name
let decoderName = CodingUserInfoKey(rawValue: "decoderName")!

struct Player: FetchableRecord, Decodable {
    init(from decoder: Decoder) throws {
        // Print the decoder name
        let decoderName = decoder.userInfo[decoderName] as? String
        print("Decoded from \(decoderName ?? "unknown decoder")")
        ...
    }
}
```
You can have a specific decoding from JSON...
```swift
// prints "Decoded from JSON"
let decoder = JSONDecoder()
decoder.userInfo = [decoderName: "JSON"]
let player = try decoder.decode(Player.self, from: jsonData)
```
... and another one from database rows:
```swift
extension Player: FetchableRecord {
    static var databaseDecodingUserInfo: [CodingUserInfoKey: Any] {
        [decoderName: "database row"]
    }
}

// prints "Decoded from database row"
let player = try Player.fetchOne(db, ...)
```
> **Note**: make sure the `databaseDecodingUserInfo` and `databaseEncodingUserInfo` properties are explicitly declared as `[CodingUserInfoKey: Any]`. If they are not, the Swift compiler may silently miss the protocol requirement, resulting in sticky empty userInfo.
### Tip: Derive Columns from Coding Keys
Codable types are granted with a [CodingKeys](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types) enum. You can use them to safely define database columns:
```swift
struct Player: Codable {
    var id: Int64
    var name: String
    var score: Int
}

extension Player: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}
```
