```swift
// Select a limited set of columns
struct RestrictedPlayer: TableRecord {
    static let databaseTableName = "player"
    
    enum Columns {
        static let id = Column("id")
        static let name = Column("name")
    }
    
    static var databaseSelection: [any SQLSelectable] {
        [Columns.id, Columns.name]
    }
}

// SELECT id, name FROM player
let request = RestrictedPlayer.all()
```
```swift
// Select all but a few columns
struct Player : TableRecord {
    static var databaseSelection: [any SQLSelectable] { 
        [.allColumns(excluding: ["generatedColumn"])]
    }
}

// SELECT id, name FROM player
let request = RestrictedPlayer.all()
```
```swift
// Select all columns and more
struct ExtendedPlayer : TableRecord {
    static let databaseTableName = "player"
    static var databaseSelection: [any SQLSelectable] {
        [.allColumns, .rowID]
    }
}

// SELECT *, rowid FROM player
let request = ExtendedPlayer.all()
```
> **Note**: make sure the `databaseSelection` property is explicitly declared as `[any SQLSelectable]`. If it is not, the Swift compiler may silently miss the protocol requirement, resulting in sticky `SELECT *` requests. To verify your setup, see the [How do I print a request as SQL?](#how-do-i-print-a-request-as-sql) FAQ.
## Expressions
Feed [requests](#requests) with SQL expressions built from your Swift code:
### SQL Operators
📖 [`SQLSpecificExpressible`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/sqlspecificexpressible)
GRDB comes with a Swift version of many SQLite [built-in operators](https://sqlite.org/lang_expr.html#operators), listed below. But not all: see [Embedding SQL in Query Interface Requests] for a way to add support for missing SQL operators.
- `=`, `<>`, `<`, `<=`, `>`, `>=`, `IS`, `IS NOT`
    Comparison operators are based on the Swift operators `==`, `!=`, `===`, `!==`, `<`, `<=`, `>`, `>=`:
    ```swift
    // SELECT * FROM player WHERE (name = 'Arthur')
    Player.filter { $0.name == "Arthur" }
    
    // SELECT * FROM player WHERE (name IS NULL)
    Player.filter { $0.name == nil }
    
    // SELECT * FROM player WHERE (score IS 1000)
    Player.filter { $0.score === 1000 }
    
    // SELECT * FROM rectangle WHERE width < height
    Rectangle.filter { $0.width < $0.height }
    ```
    Subqueries are supported:
    ```swift
    // SELECT * FROM player WHERE score = (SELECT max(score) FROM player)
    let maximumScore = Player.select { max($0.score) }
    Player.filter { $0.score == maximumScore }
    
    // SELECT * FROM player WHERE score = (SELECT max(score) FROM player)
    let maximumScore = SQLRequest("SELECT max(score) FROM player")
    Player.filter { $0.score == maximumScore }
    ```
    > **Note**: SQLite string comparison, by default, is case-sensitive and not Unicode-aware. See [string comparison](#string-comparison) if you need more control.
- `*`, `/`, `+`, `-`
    SQLite arithmetic operators are derived from their Swift equivalent:
    ```swift
    // SELECT ((temperature * 1.8) + 32) AS fahrenheit FROM planet
    Planet.select { ($0.temperature * 1.8 + 32).forKey("fahrenheit") }
    ```
    > **Note**: an expression like `nameColumn + "rrr"` will be interpreted by SQLite as a numerical addition (with funny results), not as a string concatenation. See the `concat` operator below.
    When you want to join a sequence of expressions with the `+` or `*` operator, use `joined(operator:)`:
    ```swift
    // SELECT score + bonus + 1000 FROM player
    Player.select {
        [$0.score, $0.bonus, 1000.databaseValue].joined(operator: .add)
    }
    ```
    Note in the example above how you concatenate raw values: `1000.databaseValue`. A plain `1000` would not compile.
    When the sequence is empty, `joined(operator: .add)` returns 0, and `joined(operator: .multiply)` returns 1.
- `&`, `|`, `~`, `<<`, `>>`
    Bitwise operations (bitwise and, or, not, left shift, right shift) are derived from their Swift equivalent:
    ```swift
    // SELECT mask & 2 AS isRocky FROM planet
    Planet.select { ($0.mask & 2).forKey("isRocky") }
    ```
- `||`
    Concatenate several strings:
    ```swift
    // SELECT firstName || ' ' || lastName FROM player
    Player.select {
        [$0.firstName, " ".databaseValue, $0.lastName].joined(operator: .concat)
    }
    ```
    Note in the example above how you concatenate raw strings: `" ".databaseValue`. A plain `" "` would not compile.
    When the sequence is empty, `joined(operator: .concat)` returns the empty string.
- `AND`, `OR`, `NOT`
    The SQL logical operators are derived from the Swift `&&`, `||` and `!`:
    ```swift
    // SELECT * FROM player WHERE ((NOT isVerified) OR (score < 1000))
    Player.filter { !$0.isVerified || $0.score < 1000 }
    ```
    When you want to join a sequence of expressions with the `AND` or `OR` operator, use `joined(operator:)`:
    ```swift
    // SELECT * FROM player WHERE (isVerified AND (score >= 1000) AND (name IS NOT NULL))
    Player.filter {
        [$0.isVerified, $0.score >= 1000, $0.name != nil].joined(operator: .and)
    }
    ```
