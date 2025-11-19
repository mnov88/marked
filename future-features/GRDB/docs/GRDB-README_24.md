> **Note**: the generated SQL may change between GRDB releases, without notice: don't have your application rely on any specific SQL output.
- [The Database Schema](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema)
- [Requests](#requests)
- [Expressions](#expressions)
    - [SQL Operators](#sql-operators)
    - [SQL Functions](#sql-functions)
- [Embedding SQL in Query Interface Requests]
- [Fetching from Requests]
- [Fetching by Key](#fetching-by-key)
- [Testing for Record Existence](#testing-for-record-existence)
- [Fetching Aggregated Values](#fetching-aggregated-values)
- [Delete Requests](#delete-requests)
- [Update Requests](#update-requests)
- [Custom Requests](#custom-requests)
- :blue_book: [Associations and Joins](Documentation/AssociationsBasics.md)
- :blue_book: [Common Table Expressions]
- :blue_book: [Query Interface Organization]
## Requests
📖 [`QueryInterfaceRequest`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterfacerequest), [`Table`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/table)
**The query interface requests** let you fetch values from the database:
```swift
let request = Player.filter { $0.email != nil }.order(\.name)
let players = try request.fetchAll(db)  // [Player]
let count = try request.fetchCount(db)  // Int
```
Query interface requests usually start from **a type** that adopts the `TableRecord` protocol:
```swift
struct Player: TableRecord { ... }

// The request for all players:
let request = Player.all()
let players = try request.fetchAll(db) // [Player]
```
When you can not use a record type, use `Table`:
```swift
// The request for all rows from the player table:
let table = Table("player")
let request = table.all()
let rows = try request.fetchAll(db)    // [Row]

// The request for all players from the player table:
let table = Table<Player>("player")
let request = table.all()
let players = try request.fetchAll(db) // [Player]
```
> **Note**: all examples in the documentation below use a record type, but you can always substitute a `Table` instead.
Next, declare the table **columns** that you want to use for filtering, or sorting, in a nested type named `Columns`:
```swift
extension Player {
    enum Columns {
        static let id = Column("id")
        static let name = Column("name")
    }
}
```
When `Player` is `Codable`, you'll prefer defining columns from coding keys:
```swift
extension Player {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}
```
You can now build requests with the following methods: `all`, `none`, `select`, `distinct`, `filter`, `matching`, `group`, `having`, `order`, `reversed`, `limit`, `joining`, `including`, `with`. All those methods return another request, which you can further refine by applying another method: `Player.select(...).filter(...).order(...)`.
- [`all()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerecord/all()), [`none()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerecord/none()): the requests for all rows, or no row.
    ```swift
    // SELECT * FROM player
    Player.all()
    ```
    By default, all columns are selected. See [Columns Selected by a Request].
- [`select(...)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/selectionrequest/select(_:)-ruzy) and [`select(..., as:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterfacerequest/select(_:as:)-58954) define the selected columns. See [Columns Selected by a Request].
    ```swift
    // SELECT name FROM player
    Player.select(\.name, as: String.self)
    ```
- [`selectID()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterfacerequest/selectID()) is available on [Identifiable Records]. It supports all tables that have a single-column primary key:
    ```swift
    // SELECT id FROM player
    Player.selectID()
    
    // SELECT id FROM player WHERE name IS NOT NULL
    Player.filter { $0.name != nil }.selectID()
    ```
- [`annotated(with: expression...)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/selectionrequest/annotated(with:)-1satx) extends the selection.
    ```swift
    // SELECT *, (score + bonus) AS total FROM player
    Player.annotated { ($0.score + $0.bonus).forKey("total") }
    ```
- [`annotated(with: aggregate)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/derivablerequest/annotated(with:)-74xfs) extends the selection with [association aggregates](Documentation/AssociationsBasics.md#association-aggregates).
    ```swift
    // SELECT team.*, COUNT(DISTINCT player.id) AS playerCount
    // FROM team
    // LEFT JOIN player ON player.teamId = team.id
    // GROUP BY team.id
    Team.annotated(with: Team.players.count)
    ```
