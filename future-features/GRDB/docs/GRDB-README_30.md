    The selection can be provided with [SQL Interpolation]:
    ```swift
    // SELECT IFNULL(name, 'O''Brien'), score FROM player
    let defaultName = "O'Brien"
    let request = Player.select(literal: "IFNULL(name, \(defaultName)), score")
    ```
    The selection can be provided with a mix of Swift and [SQL Interpolation]:
    ```swift
    // SELECT IFNULL(name, 'O''Brien') AS displayName, score FROM player
    let defaultName = "O'Brien"
    let request = Player.select {
        let displayName: SQL = "IFNULL(\($0.name), \(defaultName)) AS displayName"
        return [displayName, $0.score]
    }
    ```
    When the custom SQL snippet should behave as a full-fledged expression, with support for the `+` Swift operator, the `forKey` aliasing method, and all other [SQL Operators](#sql-operators), build an _expression literal_ with the `SQL.sqlExpression` method:
    ```swift
    // SELECT IFNULL(name, 'O''Brien') AS displayName, score FROM player
    let defaultName = "O'Brien"
    let request = Player.select {
        let displayName = SQL("IFNULL(\($0.name), \(defaultName))").sqlExpression
        return [displayName.forKey("displayName"), $0.score]
    }
    ```
    Such expression literals allow you to build a reusable support library of SQL functions or operators that are missing from the query interface. For example, you can define a Swift `date` function:
    ```swift
    func date(_ value: some SQLSpecificExpressible) -> SQLExpression {
        SQL("DATE(\(value))").sqlExpression
    }
    
    // SELECT * FROM "player" WHERE DATE("createdAt") = '2020-01-23'
    let request = Player.filter { date($0.createdAt) == "2020-01-23" }
    ```
    See the [Query Interface Organization] for more information about `SQLSpecificExpressible` and `SQLExpression`.
3. `FROM ...`: only one table is supported here. You can not customize this SQL part.
4. `JOIN ...`: joins are fully controlled by [Associations]. You can not customize this SQL part.
5. `WHERE ...`
    The WHERE clause can be provided as raw SQL:
    ```swift
    // SELECT * FROM player WHERE score >= 1000
    let request = Player.filter(sql: "score >= 1000")
    
    // SELECT * FROM player WHERE score >= 1000
    let minScore = 1000
    let request = Player.filter(sql: "score >= ?", arguments: [minScore])
    ```
    The WHERE clause can be provided with [SQL Interpolation]:
    ```swift
    // SELECT * FROM player WHERE score >= 1000
    let minScore = 1000
    let request = Player.filter(literal: "score >= \(minScore)")
    ```
    The WHERE clause can be provided with a mix of Swift and [SQL Interpolation]:
    ```swift
    // SELECT * FROM player WHERE (score >= 1000) AND (team = 'red')
    let minScore = 1000
    let request = Player.filter { 
        let scoreCondition: SQL = "\($0.score) >= \(minScore)"
        return scoreCondition && $0.team == "red"
    }
    ```
    See `SELECT ...` above for more SQL Interpolation examples.
6. `GROUP BY ...`
    The GROUP BY clause can be provided as raw SQL, SQL Interpolation, or a mix of Swift and SQL Interpolation, just as the selection and the WHERE clause (see above).
7. `HAVING ...`
    The HAVING clause can be provided as raw SQL, SQL Interpolation, or a mix of Swift and SQL Interpolation, just as the selection and the WHERE clause (see above).
8. `ORDER BY ...`
    The ORDER BY clause can be provided as raw SQL, SQL Interpolation, or a mix of Swift and SQL Interpolation, just as the selection and the WHERE clause (see above).
    In order to support the `desc` and `asc` query interface operators, and the `reversed()` query interface method, you must provide your orderings as _expression literals_ with the `SQL.sqlExpression` method:
    ```swift
    // SELECT * FROM "player" 
    // ORDER BY (score + bonus) ASC, name DESC
    let request = Player
        .order {
            let total = SQL("(\($0.score) + \($0.bonus))").sqlExpression
            return [total.desc, $0.name]
        }
        .reversed()
    ```
9. `LIMIT ...`: use the `limit(_:offset:)` method. You can not customize this SQL part.
## Fetching from Requests
Once you have a request, you can fetch the records at the origin of the request:
```swift
// Some request based on `Player`
let request = Player.filter { ... }... // QueryInterfaceRequest<Player>

// Fetch players:
try request.fetchCursor(db) // A Cursor of Player
try request.fetchAll(db)    // [Player]
try request.fetchSet(db)    // Set<Player>
try request.fetchOne(db)    // Player?
```
For example:
```swift
let allPlayers = try Player.fetchAll(db)                            // [Player]
let arthur = try Player.filter { $0.name == "Arthur" }.fetchOne(db) // Player?
```
