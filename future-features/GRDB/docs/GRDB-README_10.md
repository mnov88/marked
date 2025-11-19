#### DateComponents
DateComponents is indirectly supported, through the **DatabaseDateComponents** helper type.
DatabaseDateComponents reads date components from all [date formats supported by SQLite](https://www.sqlite.org/lang_datefunc.html), and stores them in the format of your choice, from HH:MM to YYYY-MM-DD HH:MM:SS.SSS.
> **Warning**: the range of valid years is 0000-9999. You will experience problems with years outside of this range, such as decoding errors, or invalid date computations with [SQLite date & time functions](https://www.sqlite.org/lang_datefunc.html). See [Date](#date) for more information.
DatabaseDateComponents can be stored and fetched from the database just like other [values](#values):
```swift
let components = DateComponents()
components.year = 1973
components.month = 9
components.day = 18

// Store "1973-09-18"
let dbComponents = DatabaseDateComponents(components, format: .YMD)
try db.execute(
    sql: "INSERT INTO player (birthDate, ...) VALUES (?, ...)",
    arguments: [dbComponents, ...])

// Read "1973-09-18"
let row = try Row.fetchOne(db, sql: "SELECT birthDate ...")!
let dbComponents: DatabaseDateComponents = row["birthDate"]
dbComponents.format         // .YMD (the actual format found in the database)
dbComponents.dateComponents // DateComponents
```
### NSNumber, NSDecimalNumber, and Decimal
**NSNumber** and **Decimal** can be stored and fetched from the database just like other [values](#values).
Here is how GRDB supports the various data types supported by SQLite:
|                 |    Integer   |     Double   |    String    |
|:--------------- |:------------:|:------------:|:------------:|
| NSNumber        | Read / Write | Read / Write |     Read     |
| NSDecimalNumber | Read / Write | Read / Write |     Read     |
| Decimal         |     Read     |     Read     | Read / Write |
- All three types can decode database integers and doubles:
    ```swift
    let number = try NSNumber.fetchOne(db, sql: "SELECT 10")            // NSNumber
    let number = try NSDecimalNumber.fetchOne(db, sql: "SELECT 1.23")   // NSDecimalNumber
    let number = try Decimal.fetchOne(db, sql: "SELECT -100")           // Decimal
    ```
- All three types decode database strings as decimal numbers:
    ```swift
    let number = try NSNumber.fetchOne(db, sql: "SELECT '10'")          // NSDecimalNumber (sic)
    let number = try NSDecimalNumber.fetchOne(db, sql: "SELECT '1.23'") // NSDecimalNumber
    let number = try Decimal.fetchOne(db, sql: "SELECT '-100'")         // Decimal
    ```
- `NSNumber` and `NSDecimalNumber` send 64-bit signed integers and doubles in the database:
    ```swift
    // INSERT INTO transfer VALUES (10)
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [NSNumber(value: 10)])
    
    // INSERT INTO transfer VALUES (10.0)
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [NSNumber(value: 10.0)])
    
    // INSERT INTO transfer VALUES (10)
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [NSDecimalNumber(string: "10.0")])
    
    // INSERT INTO transfer VALUES (10.5)
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [NSDecimalNumber(string: "10.5")])
    ```
    > **Warning**: since SQLite does not support decimal numbers, sending a non-integer `NSDecimalNumber` can result in a loss of precision during the conversion to double.
    >
    > Instead of sending non-integer `NSDecimalNumber` to the database, you may prefer:
    >
    > - Send `Decimal` instead (those store decimal strings in the database).
    > - Send integers instead (for example, store amounts of cents instead of amounts of Euros).
- `Decimal` sends decimal strings in the database:
    ```swift
    // INSERT INTO transfer VALUES ('10')
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [Decimal(10)])
    
    // INSERT INTO transfer VALUES ('10.5')
    try db.execute(sql: "INSERT INTO transfer VALUES (?)", arguments: [Decimal(string: "10.5")!])
    ```
### UUID
**UUID** can be stored and fetched from the database just like other [values](#values).
GRDB stores uuids as 16-bytes data blobs, and decodes them from both 16-bytes data blobs and strings such as "E621E1F8-C36C-495A-93FC-0C247A3E6E5F".
### Swift Enums
**Swift enums** and generally all types that adopt the [RawRepresentable](https://developer.apple.com/library/tvos/documentation/Swift/Reference/Swift_RawRepresentable_Protocol/index.html) protocol can be stored and fetched from the database just like their raw [values](#values):
```swift
enum Color : Int {
    case red, white, rose
}

enum Grape : String {
    case chardonnay, merlot, riesling
}

// Declare empty DatabaseValueConvertible adoption
extension Color : DatabaseValueConvertible { }
extension Grape : DatabaseValueConvertible { }

// Store
try db.execute(
    sql: "INSERT INTO wine (grape, color) VALUES (?, ?)",
    arguments: [Grape.merlot, Color.red])

// Read
let rows = try Row.fetchCursor(db, sql: "SELECT * FROM wine")
while let row = try rows.next() {
    let grape: Grape = row["grape"]
    let color: Color = row["color"]
}
```
