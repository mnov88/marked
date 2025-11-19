#### Date
**Date** can be stored and fetched from the database just like other [values](#values):
```swift
try db.execute(
    sql: "INSERT INTO player (creationDate, ...) VALUES (?, ...)",
    arguments: [Date(), ...])

let row = try Row.fetchOne(db, ...)!
let creationDate: Date = row["creationDate"]
```
Dates are stored using the format "YYYY-MM-DD HH:MM:SS.SSS" in the UTC time zone. It is precise to the millisecond.
> **Note**: this format was chosen because it is the only format that is:
> 
> - Comparable (`ORDER BY date` works)
> - Comparable with the SQLite keyword CURRENT_TIMESTAMP (`WHERE date > CURRENT_TIMESTAMP` works)
> - Able to feed [SQLite date & time functions](https://www.sqlite.org/lang_datefunc.html)
> - Precise enough
>
> **Warning**: the range of valid years in the SQLite date format is 0000-9999. You will experience problems with years outside of this range, such as decoding errors, or invalid date computations with [SQLite date & time functions](https://www.sqlite.org/lang_datefunc.html).
Some applications may prefer another date format:
- Some may prefer ISO-8601, with a `T` separator.
- Some may prefer ISO-8601, with a time zone.
- Some may need to store years beyond the 0000-9999 range.
- Some may need sub-millisecond precision.
- Some may need exact `Date` roundtrip.
- Etc.
**You should think twice before choosing a different date format:**
- ISO-8601 is about *exchange and communication*, when SQLite is about *storage and data manipulation*. Sharing the same representation in your database and in JSON files only provides a superficial convenience, and should be the least of your priorities. Don't store dates as ISO-8601 without understanding what you lose. For example, ISO-8601 time zones forbid database-level date comparison. 
- Sub-millisecond precision and exact `Date` roundtrip are not as obvious needs as it seems at first sight. Dates generally don't precisely roundtrip as soon as they leave your application anyway, because the other systems your app communicates with use their own date representation (the Android version of your app, the server your application is talking to, etc.) On top of that, `Date` comparison is at least as hard and nasty as [floating point comparison](https://www.google.com/search?q=floating+point+comparison+is+hard).
The customization of date format is explicit. For example:
```swift
let date = Date()
let timeInterval = date.timeIntervalSinceReferenceDate
try db.execute(
    sql: "INSERT INTO player (creationDate, ...) VALUES (?, ...)",
    arguments: [timeInterval, ...])

if let row = try Row.fetchOne(db, ...) {
    let timeInterval: TimeInterval = row["creationDate"]
    let creationDate = Date(timeIntervalSinceReferenceDate: timeInterval)
}
```
See also [Codable Records] for more date customization options, and [`DatabaseValueConvertible`] if you want to define a Date-wrapping type with customized database representation.
