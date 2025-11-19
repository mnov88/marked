- `AS`
    To give an alias to an expression, use the `forKey` method:
    ```swift
    // SELECT (score + bonus) AS total
    // FROM player
    Player.select { ($0.score + $0.bonus).forKey("total") }
    ```
    If you need to refer to this aliased column in another place of the request, use a detached column:
    ```swift
    // SELECT (score + bonus) AS total
    // FROM player 
    // ORDER BY total
    Player
        .select { ($0.score + $0.bonus).forKey("total") }
        .order(Column("total").detached)
    ```
    The detached column `Column("total").detached` is not considered as a part of the "player" table, so it is always rendered as `total` in the generated SQL, even when the request involves other tables via an [association](Documentation/AssociationsBasics.md) or a [common table expression].
### SQL Functions
📖 [`SQLSpecificExpressible`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/sqlspecificexpressible)
GRDB comes with a Swift version of many SQLite [built-in functions](https://sqlite.org/lang_corefunc.html), listed below. But not all: see [Embedding SQL in Query Interface Requests] for a way to add support for missing SQL functions.
- `ABS`, `AVG`, `COALESCE`, `COUNT`, `DATETIME`, `JULIANDAY`, `LENGTH`, `MAX`, `MIN`, `SUM`, `TOTAL`:
    Those are based on the `abs`, `average`, `coalesce`, `count`, `dateTime`, `julianDay`, `length`, `max`, `min`, `sum`, and `total` Swift functions:
    ```swift
    // SELECT MIN(score), MAX(score) FROM player
    Player.select { [min($0.score), max($0.score)] }
    
    // SELECT COUNT(name) FROM player
    Player.select { count($0.name) }
    
    // SELECT COUNT(DISTINCT name) FROM player
    Player.select { count(distinct: $0.name) }
    
    // SELECT JULIANDAY(date, 'start of year') FROM game
    Game.select { julianDay($0.date, .startOfYear) }
    ```
    For more information about the functions `dateTime` and `julianDay`, see [Date And Time Functions](https://www.sqlite.org/lang_datefunc.html).
- `CAST`
    Use the `cast` Swift function:
    ```swift
    // SELECT (CAST(wins AS REAL) / games) AS successRate FROM player
    Player.select { (cast($0.wins, as: .real) / $0.games).forKey("successRate") }
    ```
    See [CAST expressions](https://www.sqlite.org/lang_expr.html#castexpr) for more information about SQLite conversions.
- `IFNULL`
    Use the Swift `??` operator:
    ```swift
    // SELECT IFNULL(name, 'Anonymous') FROM player
    Player.select { $0.name ?? "Anonymous" }
    
    // SELECT IFNULL(name, email) FROM player
    Player.select { $0.name ?? $0.email }
    ```
- `LOWER`, `UPPER`
    The query interface does not give access to those SQLite functions. Nothing against them, but they are not unicode aware.
    Instead, GRDB extends SQLite with SQL functions that call the Swift built-in string functions `capitalized`, `lowercased`, `uppercased`, `localizedCapitalized`, `localizedLowercased` and `localizedUppercased`:
    ```swift
    Player.select { $0.name.uppercased() }
    ```
    > **Note**: When *comparing* strings, you'd rather use a [collation](#string-comparison):
    >
    > ```swift
    > let name: String = ...
    >
    > // Not recommended
    > Player.filter { $0.name.uppercased() == name.uppercased() }
    >
    > // Better
    > Player.filter { $0.name.collating(.caseInsensitiveCompare) == name }
    > ```
- Custom SQL functions and aggregates
    You can apply your own [custom SQL functions and aggregates](#custom-functions-):
    ```swift
    let myFunction = DatabaseFunction("myFunction", ...)
    
    // SELECT myFunction(name) FROM player
    Player.select { myFunction($0.name) }
    ```
## Embedding SQL in Query Interface Requests
You will sometimes want to extend your query interface requests with SQL snippets. This can happen because GRDB does not provide a Swift interface for some SQL function or operator, or because you want to use an SQLite construct that GRDB does not support.
Support for extensibility is large, but not unlimited. All the SQL queries built by the query interface request have the shape below. _If you need something else, you'll have to use [raw SQL requests](#sqlite-api)._
```sql
WITH ...     -- 1
SELECT ...   -- 2
FROM ...     -- 3
JOIN ...     -- 4
WHERE ...    -- 5
GROUP BY ... -- 6
HAVING ...   -- 7
ORDER BY ... -- 8
LIMIT ...    -- 9
```
1. `WITH ...`: see [Common Table Expressions].
2. `SELECT ...`
    The selection can be provided as raw SQL:
    ```swift
    // SELECT IFNULL(name, 'O''Brien'), score FROM player
    let request = Player.select(sql: "IFNULL(name, 'O''Brien'), score")
    
    // SELECT IFNULL(name, 'O''Brien'), score FROM player
    let defaultName = "O'Brien"
    let request = Player.select(sql: "IFNULL(name, ?), score", arguments: [suffix])
    ```
