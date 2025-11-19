### Upsert
[UPSERT](https://www.sqlite.org/lang_UPSERT.html) is an SQLite feature that causes an INSERT to behave as an UPDATE or a no-op if the INSERT would violate a uniqueness constraint (primary key or unique index).
> **Note**: Upsert apis are available from SQLite 3.35.0+: iOS 15.0+, macOS 12.0+, tvOS 15.0+, watchOS 8.0+, or with a [custom SQLite build] or [SQLCipher](#encryption).
>
> **Note**: With regard to [persistence callbacks](#available-callbacks), an upsert behaves exactly like an insert. In particular: the `aroundInsert(_:)` and `didInsert(_:)` callbacks reports the rowid of the inserted or updated row; `willUpdate`, `aroundUpdate`, `didUpdate` are not called.
[PersistableRecord] provides three upsert methods:
- `upsert(_:)`
    Inserts or updates a record.
    The upsert behavior is triggered by a violation of any uniqueness constraint on the table (primary key or unique index). In case of conflict, all columns but the primary key are overwritten with the inserted values:
    ```swift
    struct Player: Encodable, PersistableRecord {
        var id: Int64
        var name: String
        var score: Int
    }
    
    // INSERT INTO player (id, name, score)
    // VALUES (1, 'Arthur', 1000)
    // ON CONFLICT DO UPDATE SET
    //   name = excluded.name,
    //   score = excluded.score
    let player = Player(id: 1, name: "Arthur", score: 1000)
    try player.upsert(db)
    ```
- `upsertAndFetch(_:onConflict:doUpdate:)` (requires [FetchableRecord] conformance)
    Inserts or updates a record, and returns the upserted record.
    The `onConflict` and `doUpdate` arguments let you further control the upsert behavior. Make sure you check the [SQLite UPSERT documentation](https://www.sqlite.org/lang_UPSERT.html) for detailed information.
    - `onConflict`: the "conflict target" is the array of columns in the uniqueness constraint (primary key or unique index) that triggers the upsert.
        If empty (the default), all uniqueness constraint are considered.
    - `doUpdate`: a closure that returns columns assignments to perform in case of conflict. Other columns are overwritten with the inserted values.
        By default, all inserted columns but the primary key and the conflict target are overwritten.
    In the example below, we upsert the new vocabulary word "jovial". It is inserted if that word is not already in the dictionary. Otherwise, `count` is incremented, `isTainted` is not overwritten, and `kind` is overwritten:
    ```swift
    // CREATE TABLE vocabulary(
    //   word TEXT NOT NULL PRIMARY KEY,
    //   kind TEXT NOT NULL,
    //   isTainted BOOLEAN DEFAULT 0,
    //   count INT DEFAULT 1))
    struct Vocabulary: Encodable, PersistableRecord {
        var word: String
        var kind: String
        var isTainted: Bool
    }
    
    // INSERT INTO vocabulary(word, kind, isTainted)
    // VALUES('jovial', 'adjective', 0)
    // ON CONFLICT(word) DO UPDATE SET \
    //   count = count + 1,   -- on conflict, count is incremented
    //   kind = excluded.kind -- on conflict, kind is overwritten
    // RETURNING *
    let vocabulary = Vocabulary(word: "jovial", kind: "adjective", isTainted: false)
    let upserted = try vocabulary.upsertAndFetch(
        db, onConflict: ["word"],
        doUpdate: { _ in
            [Column("count") += 1,            // on conflict, count is incremented
             Column("isTainted").noOverwrite] // on conflict, isTainted is NOT overwritten
        })
    ```
    The `doUpdate` closure accepts an `excluded` TableAlias argument that refers to the inserted values that trigger the conflict. You can use it to specify an explicit overwrite, or to perform a computation. In the next example, the upsert keeps the maximum date in case of conflict:
    ```swift
    // INSERT INTO message(id, text, date)
    // VALUES(...)
    // ON CONFLICT DO UPDATE SET \
    //   text = excluded.text,
    //   date = MAX(date, excluded.date)
    // RETURNING *
    let upserted = try message.upsertAndFetch(doUpdate: { excluded in
        // keep the maximum date in case of conflict
        [Column("date").set(to: max(Column("date"), excluded["date"]))]
    })
    ```
- `upsertAndFetch(_:as:onConflict:doUpdate:)` (does not require [FetchableRecord] conformance)
    This method is identical to `upsertAndFetch(_:onConflict:doUpdate:)` described above, but you can provide a distinct [FetchableRecord] record type as a result, in order to specify the returned columns.
### Persistence Methods and the `RETURNING` clause
SQLite is able to return values from a inserted, updated, or deleted row, with the [`RETURNING` clause](https://www.sqlite.org/lang_returning.html).
