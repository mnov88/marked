## FAQ: Opening Connections
- :arrow_up: [FAQ]
- [How do I create a database in my application?](#how-do-i-create-a-database-in-my-application)
- [How do I open a database stored as a resource of my application?](#how-do-i-open-a-database-stored-as-a-resource-of-my-application)
- [How do I close a database connection?](#how-do-i-close-a-database-connection)
### How do I create a database in my application?
First choose a proper location for the database file. Document-based applications will let the user pick a location. Apps that use the database as a global storage will prefer the Application Support directory.
The sample code below creates or opens a database file inside its dedicated directory (a [recommended practice](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections)). On the first run, a new empty database file is created. On subsequent runs, the database file already exists, so it just opens a connection:
```swift
// HOW TO create an empty database, or open an existing database file

// Create the "Application Support/MyDatabase" directory
let fileManager = FileManager.default
let appSupportURL = try fileManager.url(
    for: .applicationSupportDirectory, in: .userDomainMask,
    appropriateFor: nil, create: true) 
let directoryURL = appSupportURL.appendingPathComponent("MyDatabase", isDirectory: true)
try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

// Open or create the database
let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
let dbQueue = try DatabaseQueue(path: databaseURL.path)
```
### How do I open a database stored as a resource of my application?
Open a read-only connection to your resource:
```swift
// HOW TO open a read-only connection to a database resource

// Get the path to the database resource.
if let dbPath = Bundle.main.path(forResource: "db", ofType: "sqlite") {
    // If the resource exists, open a read-only connection.
    // Writes are disallowed because resources can not be modified. 
    var config = Configuration()
    config.readonly = true
    let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
} else {
    // The database resource can not be found.
    // Fix your setup, or report the problem to the user. 
}
```
### How do I close a database connection?
Database connections are automatically closed when `DatabaseQueue` or `DatabasePool` instances are deinitialized.
If the correct execution of your program depends on precise database closing, perform an explicit call to [`close()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasereader/close()). This method may fail and create zombie connections, so please check its detailed documentation.
## FAQ: SQL
- :arrow_up: [FAQ]
- [How do I print a request as SQL?](#how-do-i-print-a-request-as-sql)
### How do I print a request as SQL?
When you want to debug a request that does not deliver the expected results, you may want to print the SQL that is actually executed.
You can compile the request into a prepared [`Statement`]:
```swift
try dbQueue.read { db in
    let request = Player.filter { $0.email == "arthur@example.com" }
    let statement = try request.makePreparedRequest(db).statement
    print(statement) // SELECT * FROM player WHERE email = ?
    print(statement.arguments) // ["arthur@example.com"]
}
```
Another option is to setup a tracing function that prints out the executed SQL requests. For example, provide a tracing function when you connect to the database:
```swift
// Prints all SQL statements
var config = Configuration()
config.prepareDatabase { db in
    db.trace { print($0) }
}
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

try dbQueue.read { db in
    // Prints "SELECT * FROM player WHERE email = ?"
    let players = try Player.filter { $0.email == "arthur@example.com" }.fetchAll(db)
}
```
If you want to see statement arguments such as `'arthur@example.com'` in the logged statements, [make statement arguments public](https://swiftpackageindex.com/groue/GRDB.swift/configuration/publicstatementarguments).
> **Note**: the generated SQL may change between GRDB releases, without notice: don't have your application rely on any specific SQL output.
## FAQ: General
- :arrow_up: [FAQ]
- [How do I monitor the duration of database statements execution?](#how-do-i-monitor-the-duration-of-database-statements-execution)
- [What Are Experimental Features?](#what-are-experimental-features)
- [Does GRDB support library evolution and ABI stability?](#does-grdb-support-library-evolution-and-abi-stability)
