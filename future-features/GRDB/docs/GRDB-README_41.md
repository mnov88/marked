This request uses a TableAlias in order to be able to filter on the eventual associated author. We make sure that the `Author.primaryKey` is nil, which is another way to say it does not exist: the book has no author.
See [How do I filter records and only keep those that are associated to another record?](#how-do-i-filter-records-and-only-keep-those-that-are-associated-to-another-record) above for the opposite question.
### How do I select only one column of an associated record?
Let's say you have two record types, `Book` and `Author`, and you want to fetch all books with their author name, but not the full associated author records.
We start by defining the association between books and authors:
```swift
struct Book: Decodable, TableRecord {
    ...
    static let author = belongsTo(Author.self)
}

struct Author: Decodable, TableRecord {
    ...
    enum Columns {
        static let name = Column(CodingKeys.name)
    }
}
```
And then we can write our request and the ad-hoc record that decodes it:
```swift
struct BookInfo: Decodable, FetchableRecord {
    var book: Book
    var authorName: String? // nil when the book is anonymous
    
    static func all() -> QueryInterfaceRequest<BookInfo> {
        // SELECT book.*, author.name AS authorName
        // FROM book
        // LEFT JOIN author ON author.id = book.authorID
        return Book
            .annotated(withOptional: Book.author.select { 
                $0.name.forKey(CodingKeys.authorName)
            })
            .asRequest(of: BookInfo.self)
    }
}

let bookInfos: [BookInfo] = try dbQueue.read { db in
    BookInfo.all().fetchAll(db)
}
```
By defining the request as a static method of BookInfo, you have access to the private `CodingKeys.authorName`, and a compiler-checked SQL column name.
By using the `annotated(withOptional:)` method, you append the author name to the top-level selection that can be decoded by the ad-hoc record.
By using `asRequest(of:)`, you enhance the type-safety of your request.
## FAQ: ValueObservation
- :arrow_up: [FAQ]
- [Why is ValueObservation not publishing value changes?](#why-is-valueobservation-not-publishing-value-changes)
### Why is ValueObservation not publishing value changes?
Sometimes it looks that a [ValueObservation] does not notify the changes you expect.
There may be four possible reasons for this:
1. The expected changes were not committed into the database.
2. The expected changes were committed into the database, but were quickly overwritten.
3. The observation was stopped.
4. The observation does not track the expected database region.
To answer the first two questions, look at SQL statements executed by the database. This is done when you open the database connection:
```swift
// Prints all SQL statements
var config = Configuration()
config.prepareDatabase { db in
    db.trace { print("SQL: \($0)") }
}
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
```
If, after that, you are convinced that the expected changes were committed into the database, and not overwritten soon after, trace observation events:
```swift
let observation = ValueObservation
    .tracking { db in ... }
    .print() // <- trace observation events
let cancellable = observation.start(...)
```
Look at the observation logs which start with `cancel` or `failure`: maybe the observation was cancelled by your app, or did fail with an error.
Look at the observation logs which start with `value`: make sure, again, that the expected value was not actually notified, then overwritten.
Finally, look at the observation logs which start with `tracked region`. Does the printed database region cover the expected changes?
For example:
- `empty`: The empty region, which tracks nothing and never triggers the observation.
- `player(*)`: The full `player` table
- `player(id,name)`: The `id` and `name` columns of the `player` table
- `player(id,name)[1]`: The `id` and `name` columns of the row with id 1 in the `player` table
- `player(*),team(*)`: Both the full `player` and `team` tables
If you happen to use the `ValueObservation.trackingConstantRegion(_:)` method and see a mismatch between the tracked region and your expectation, then change the definition of your observation by using `tracking(_:)`. You should witness that the logs which start with `tracked region` now evolve in order to include the expected changes, and that you get the expected notifications.
