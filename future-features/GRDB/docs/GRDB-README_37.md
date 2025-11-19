    Solution: avoid reentrancy, and instead pass a database connection along.
### How to Deal with Untrusted Inputs
Let's consider the code below:
```swift
let sql = "SELECT ..."

// Some untrusted arguments for the query
let arguments: [String: Any] = ...
let rows = try Row.fetchCursor(db, sql: sql, arguments: StatementArguments(arguments))

while let row = try rows.next() {
    // Some untrusted database value:
    let date: Date? = row[0]
}
```
It has two opportunities to throw fatal errors:
- **Untrusted arguments**: The dictionary may contain values that do not conform to the [DatabaseValueConvertible protocol](#values), or may miss keys required by the statement.
- **Untrusted database content**: The row may contain a non-null value that can't be turned into a date.
In such a situation, you can still avoid fatal errors by exposing and handling each failure point, one level down in the GRDB API:
```swift
// Untrusted arguments
if let arguments = StatementArguments(arguments) {
    let statement = try db.makeStatement(sql: sql)
    try statement.setArguments(arguments)
    
    var cursor = try Row.fetchCursor(statement)
    while let row = try iterator.next() {
        // Untrusted database content
        let dbValue: DatabaseValue = row[0]
        if dbValue.isNull {
            // Handle NULL
        if let date = Date.fromDatabaseValue(dbValue) {
            // Handle valid date
        } else {
            // Handle invalid date
        }
    }
}
```
See [`Statement`] and [DatabaseValue](#databasevalue) for more information.
### Error Log
**SQLite can be configured to invoke a callback function containing an error code and a terse error message whenever anomalies occur.**
This global error callback must be configured early in the lifetime of your application:
```swift
Database.logError = { (resultCode, message) in
    NSLog("%@", "SQLite error \(resultCode): \(message)")
}
```
> **Warning**: Database.logError must be set before any database connection is opened. This includes the connections that your application opens with GRDB, but also connections opened by other tools, such as third-party libraries. Setting it after a connection has been opened is an SQLite misuse, and has no effect.
See [The Error And Warning Log](https://sqlite.org/errlog.html) for more information.
## Unicode
SQLite lets you store unicode strings in the database.
However, SQLite does not provide any unicode-aware string transformations or comparisons.
### Unicode functions
The `UPPER` and `LOWER` built-in SQLite functions are not unicode-aware:
```swift
// "JéRôME"
try String.fetchOne(db, sql: "SELECT UPPER('Jérôme')")
```
GRDB extends SQLite with [SQL functions](#custom-sql-functions-and-aggregates) that call the Swift built-in string functions `capitalized`, `lowercased`, `uppercased`, `localizedCapitalized`, `localizedLowercased` and `localizedUppercased`:
```swift
// "JÉRÔME"
let uppercased = DatabaseFunction.uppercase
try String.fetchOne(db, sql: "SELECT \(uppercased.name)('Jérôme')")
```
Those unicode-aware string functions are also readily available in the [query interface](#sql-functions):
```swift
Player.select { $0.name.uppercased }
```
### String Comparison
SQLite compares strings in many occasions: when you sort rows according to a string column, or when you use a comparison operator such as `=` and `<=`.
The comparison result comes from a *collating function*, or *collation*. SQLite comes with three built-in collations that do not support Unicode: [binary, nocase, and rtrim](https://www.sqlite.org/datatype3.html#collation).
GRDB comes with five extra collations that leverage unicode-aware comparisons based on the standard Swift String comparison functions and operators:
- `unicodeCompare` (uses the built-in `<=` and `==` Swift operators)
- `caseInsensitiveCompare`
- `localizedCaseInsensitiveCompare`
- `localizedCompare`
- `localizedStandardCompare`
A collation can be applied to a table column. All comparisons involving this column will then automatically trigger the comparison function:
```swift
try db.create(table: "player") { t in
    // Guarantees case-insensitive email unicity
    t.column("email", .text).unique().collate(.nocase)
    
    // Sort names in a localized case insensitive way
    t.column("name", .text).collate(.localizedCaseInsensitiveCompare)
}

// Players are sorted in a localized case insensitive way:
let players = try Player.order(\.name).fetchAll(db)
```
> **Warning**: SQLite *requires* host applications to provide the definition of any collation other than binary, nocase and rtrim. When a database file has to be shared or migrated to another SQLite library of platform (such as the Android version of your application), make sure you provide a compatible collation.
