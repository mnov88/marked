    ```swift
    // SELECT * FROM player ORDER BY name
    Player.order(\.score).order(\.name)
    ```
- [`reversed()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/orderedrequest/reversed()) reverses the eventual orderings.
    ```swift
    // SELECT * FROM player ORDER BY score ASC, name DESC
    Player.order { [$0.score.desc, $0.name] }.reversed()
    ```
    If no ordering was already specified, this method has no effect:
    ```swift
    // SELECT * FROM player
    Player.all().reversed()
    ```
- [`limit(limit, offset: offset)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterfacerequest/limit(_:offset:)) limits and pages results.
    ```swift
    // SELECT * FROM player LIMIT 5
    Player.limit(5)
    
    // SELECT * FROM player LIMIT 5 OFFSET 10
    Player.limit(5, offset: 10)
    ```
- [`joining(required:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/joining(required:)), [`joining(optional:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/joining(optional:)), [`including(required:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/including(required:)), [`including(optional:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/including(optional:)), and [`including(all:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/including(all:)) fetch and join records through [Associations].
    ```swift
    // SELECT player.*, team.*
    // FROM player
    // JOIN team ON team.id = player.teamId
    Player.including(required: Player.team)
    ```
- [`with(cte)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/derivablerequest/with(_:)) embeds a [common table expression]:
    ```swift
    // WITH ... SELECT * FROM player
    let cte = CommonTableExpression(...)
    Player.with(cte)
    ```
- Other requests that involve the primary key:
    - [`selectPrimaryKey(as:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/queryinterfacerequest/selectprimarykey(as:)) selects the primary key.
        ```swift
        // SELECT id FROM player
        Player.selectPrimaryKey(as: Int64.self)    // QueryInterfaceRequest<Int64>
        
        // SELECT code FROM country
        Country.selectPrimaryKey(as: String.self)  // QueryInterfaceRequest<String>
        
        // SELECT citizenId, countryCode FROM citizenship
        Citizenship.selectPrimaryKey(as: Row.self) // QueryInterfaceRequest<Row>
        ```
    - [`orderByPrimaryKey()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/orderbyprimarykey()) sorts by primary key.
        ```swift
        // SELECT * FROM player ORDER BY id
        Player.orderByPrimaryKey()
        
        // SELECT * FROM country ORDER BY code
        Country.orderByPrimaryKey()
        
        // SELECT * FROM citizenship ORDER BY citizenId, countryCode
        Citizenship.orderByPrimaryKey()
        ```
    - [`groupByPrimaryKey()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/groupbyprimarykey()) groups rows by primary key.
You can refine requests by chaining those methods:
```swift
// SELECT * FROM player WHERE (email IS NOT NULL) ORDER BY name
Player.order(\.name).filter { $0.email != nil }
```
The `select`, `order`, `group`, and `limit` methods ignore and replace previously applied selection, orderings, grouping, and limits. On the opposite, `filter`, `matching`, and `having` methods extend the query:
```swift
Player                          // SELECT * FROM player
    .filter { $0.name != nil }  // WHERE (name IS NOT NULL)
    .filter { $0.email != nil } //        AND (email IS NOT NULL)
    .order(\.name)              // - ignored -
    .reversed()                 // - ignored -
    .order(\.score)             // ORDER BY score
    .limit(20, offset: 40)      // - ignored -
    .limit(10)                  // LIMIT 10
```
Raw SQL snippets are also accepted, with eventual [arguments](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/statementarguments):
```swift
// SELECT DATE(creationDate), COUNT(*) FROM player WHERE name = 'Arthur' GROUP BY date(creationDate)
Player
    .select(sql: "DATE(creationDate), COUNT(*)")
    .filter(sql: "name = ?", arguments: ["Arthur"])
    .group(sql: "DATE(creationDate)")
```
### Columns Selected by a Request
By default, query interface requests select all columns:
```swift
// SELECT * FROM player
struct Player: TableRecord { ... }
let request = Player.all()

// SELECT * FROM player
let table = Table("player")
let request = table.all()
```
**The selection can be changed for each individual requests, or in the case of record-based requests, for all requests built from this record type.**
The `select(...)` and `select(..., as:)` methods change the selection of a single request (see [Fetching from Requests] for detailed information):
```swift
let request = Player.select { max($0.score) }
let maxScore = try Int.fetchOne(db, request) // Int?

let request = Player.select({ max($0.score) }, as: Int.self)
let maxScore = try request.fetchOne(db)      // Int?
```
The default selection for a record type is controlled by the `databaseSelection` property. For example:
