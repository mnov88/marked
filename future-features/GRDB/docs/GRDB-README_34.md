#### Passphrase availability vs. Database availability
When the passphrase is securely stored in the system keychain, your application can protect it using the [`kSecAttrAccessible`](https://developer.apple.com/documentation/security/ksecattraccessible) attribute.
Such protection prevents GRDB from creating SQLite connections when the passphrase is not available:
```swift
var config = Configuration()
config.prepareDatabase { db in
    let passphrase = try loadPassphraseFromSystemKeychain()
    try db.usePassphrase(passphrase)
}

// Success if and only if the passphrase is available
let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
```
For the same reason, [database pools], which open SQLite connections on demand, may fail at any time as soon as the passphrase becomes unavailable:
```swift
// Success if and only if the passphrase is available
let dbPool = try DatabasePool(path: dbPath, configuration: config)

// May fail if passphrase has turned unavailable
try dbPool.read { ... }

// May trigger value observation failure if passphrase has turned unavailable
try dbPool.write { ... }
```
Because DatabasePool maintains a pool of long-lived SQLite connections, some database accesses will use an existing connection, and succeed. And some other database accesses will fail, as soon as the pool wants to open a new connection. It is impossible to predict which accesses will succeed or fail.
For the same reason, a database queue, which also maintains a long-lived SQLite connection, will remain available even after the passphrase has turned unavailable.
Applications are thus responsible for protecting database accesses when the passphrase is unavailable. To this end, they can use [Data Protection](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files). They can also destroy their instances of database queue or pool when the passphrase becomes unavailable.
## Backup
**You can backup (copy) a database into another.**
Backups can for example help you copying an in-memory database to and from a database file when you implement NSDocument subclasses.
```swift
let source: DatabaseQueue = ...      // or DatabasePool
let destination: DatabaseQueue = ... // or DatabasePool
try source.backup(to: destination)
```
The `backup` method blocks the current thread until the destination database contains the same contents as the source database.
When the source is a [database pool](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databasepool), concurrent writes can happen during the backup. Those writes may, or may not, be reflected in the backup, but they won't trigger any error.
`Database` has an analogous `backup` method.
```swift
let source: DatabaseQueue = ...      // or DatabasePool
let destination: DatabaseQueue = ... // or DatabasePool
try source.write { sourceDb in
    try destination.barrierWriteWithoutTransaction { destDb in
        try sourceDb.backup(to: destDb)
    }
}
```
This method allows for the choice of source and destination `Database` handles with which to backup the database.
### Backup Progress Reporting
The `backup` methods take optional `pagesPerStep` and `progress` parameters. Together these parameters can be used to track a database backup in progress and abort an incomplete backup.
When `pagesPerStep` is provided, the database backup is performed in _steps_. At each step, no more than `pagesPerStep` database pages are copied from the source to the destination. The backup proceeds one step at a time until all pages have been copied.
When a `progress` callback is provided, `progress` is called after every backup step, including the last. Even if a non-default `pagesPerStep` is specified or the backup is otherwise completed in a single step, the `progress` callback will be called.
```swift
try source.backup(
    to: destination,
    pagesPerStep: ...)
    { backupProgress in
       print("Database backup progress:", backupProgress)
    }
```
### Aborting an Incomplete Backup
If a call to `progress` throws when `backupProgress.isComplete == false`, the backup will be aborted and the error rethrown. However, if a call to `progress` throws when `backupProgress.isComplete == true`, the backup is unaffected and the error is silently ignored.
> **Warning**: Passing non-default values of `pagesPerStep` or `progress` to the backup methods is an advanced API intended to provide additional capabilities to expert users. GRDB's backup API provides a faithful, low-level wrapper to the underlying SQLite online backup API. GRDB's documentation is not a comprehensive substitute for the official SQLite [documentation of their backup API](https://www.sqlite.org/c3ref/backup_finish.html).
