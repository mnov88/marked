### How do I monitor the duration of database statements execution?
Use the `trace(options:_:)` method, with the `.profile` option:
```swift
var config = Configuration()
config.prepareDatabase { db in
    db.trace(options: .profile) { event in
        // Prints all SQL statements with their duration
        print(event)
        
        // Access to detailed profiling information
        if case let .profile(statement, duration) = event, duration > 0.5 {
            print("Slow query: \(statement.sql)")
        }
    }
}
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

try dbQueue.read { db in
    let players = try Player.filter { $0.email == "arthur@example.com" }.fetchAll(db)
    // Prints "0.003s SELECT * FROM player WHERE email = ?"
}
```
If you want to see statement arguments such as `'arthur@example.com'` in the logged statements, [make statement arguments public](https://swiftpackageindex.com/groue/GRDB.swift/configuration/publicstatementarguments).
### What Are Experimental Features?
Since GRDB 1.0, all backwards compatibility guarantees of [semantic versioning](http://semver.org) apply: no breaking change will happen until the next major version of the library.
There is an exception, though: *experimental features*, marked with the "**:fire: EXPERIMENTAL**" badge. Those are advanced features that are too young, or lack user feedback. They are not stabilized yet.
Those experimental features are not protected by semantic versioning, and may break between two minor releases of the library. To help them becoming stable, [your feedback](https://github.com/groue/GRDB.swift/issues) is greatly appreciated.
### Does GRDB support library evolution and ABI stability?
No, GRDB does not support library evolution and ABI stability. The only promise is API stability according to [semantic versioning](http://semver.org), with an exception for [experimental features](#what-are-experimental-features).
Yet, GRDB can be built with the "Build Libraries for Distribution" Xcode option (`BUILD_LIBRARY_FOR_DISTRIBUTION`), so that you can build binary frameworks at your convenience.
## FAQ: Associations
- :arrow_up: [FAQ]
- [How do I filter records and only keep those that are associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-associated-to-another-record)
- [How do I filter records and only keep those that are NOT associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-not-associated-to-another-record)
- [How do I select only one column of an associated record?](#how-do-i-select-only-one-column-of-an-associated-record)
### How do I filter records and only keep those that are associated to another record?
Let's say you have two record types, `Book` and `Author`, and you want to only fetch books that have an author, and discard anonymous books.
We start by defining the association between books and authors:
```swift
struct Book: TableRecord {
    ...
    static let author = belongsTo(Author.self)
}

struct Author: TableRecord {
    ...
}
```
And then we can write our request and only fetch books that have an author, discarding anonymous ones:
```swift
let books: [Book] = try dbQueue.read { db in
    // SELECT book.* FROM book 
    // JOIN author ON author.id = book.authorID
    let request = Book.joining(required: Book.author)
    return try request.fetchAll(db)
}
```
Note how this request does not use the `filter` method. Indeed, we don't have any condition to express on any column. Instead, we just need to "require that a book can be joined to its author".
See [How do I filter records and only keep those that are NOT associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-not-associated-to-another-record) below for the opposite question.
### How do I filter records and only keep those that are NOT associated to another record?
Let's say you have two record types, `Book` and `Author`, and you want to only fetch anonymous books that do not have any author.
We start by defining the association between books and authors:
```swift
struct Book: TableRecord {
    ...
    static let author = belongsTo(Author.self)
}

struct Author: TableRecord {
    ...
}
```
And then we can write our request and only fetch anonymous books that don't have any author:
```swift
let books: [Book] = try dbQueue.read { db in
    // SELECT book.* FROM book
    // LEFT JOIN author ON author.id = book.authorID
    // WHERE author.id IS NULL
    let authorAlias = TableAlias<Author>()
    let request = Book
        .joining(optional: Book.author.aliased(authorAlias))
        .filter(!authorAlias.exists)
    return try request.fetchAll(db)
}
```
