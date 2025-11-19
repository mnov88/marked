#### Companion Libraries
- [GRDBQuery](https://github.com/groue/GRDBQuery): Access and observe the database from your SwiftUI views.
- [GRDBSnapshotTesting](https://github.com/groue/GRDBSnapshotTesting): Test your database. 
**[FAQ]**
**[Sample Code](#sample-code)**
Installation
============
**The installation procedures below have GRDB use the version of SQLite that ships with the target operating system.**
See [Encryption](#encryption) for the installation procedure of GRDB with SQLCipher.
See [Custom SQLite builds](Documentation/CustomSQLiteBuilds.md) for the installation procedure of GRDB with a customized build of SQLite.
## Swift Package Manager
The [Swift Package Manager](https://swift.org/package-manager/) automates the distribution of Swift code. To use GRDB with SPM, add a dependency to `https://github.com/groue/GRDB.swift.git`
GRDB offers two libraries, `GRDB` and `GRDB-dynamic`. Pick only one. When in doubt, prefer `GRDB`. The `GRDB-dynamic` library can reveal useful if you are going to link it with multiple targets within your app and only wish to link to a shared, dynamic framework once. See [How to link a Swift Package as dynamic](https://forums.swift.org/t/how-to-link-a-swift-package-as-dynamic/32062) for more information.
> **Note**: Linux support is provided by contributors. It is not automatically tested, and not officially maintained. If you notice a build or runtime failure on Linux, please open a pull request with the necessary fix, thank you!
## CocoaPods
[CocoaPods](http://cocoapods.org/) is a dependency manager for Xcode projects. To use GRDB with CocoaPods (version 1.2 or higher), specify in your `Podfile`:
```ruby
pod 'GRDB.swift'
```
GRDB can be installed as a framework, or a static library.
**Important Note for CocoaPods installation**
Due to an [issue](https://github.com/CocoaPods/CocoaPods/issues/11839) in CocoaPods, it is currently not possible to deploy new versions of GRDB to CocoaPods. The last version available on CocoaPods is 6.24.1. To install later versions of GRDB using CocoaPods, use one of the following workarounds:
- Depend on the `GRDB7` branch. This is more or less equivalent to what `pod 'GRDB.swift', '~> 7.0'` would normally do, if CocoaPods would accept new GRDB versions to be published:
    ```ruby
    # Can't use semantic versioning due to https://github.com/CocoaPods/CocoaPods/issues/11839
    pod 'GRDB.swift', git: 'https://github.com/groue/GRDB.swift.git', branch: 'GRDB7'
    ```
- Depend on a specific version explicitly (Replace the tag with the version you want to use):
    ```ruby
    # Can't use semantic versioning due to https://github.com/CocoaPods/CocoaPods/issues/11839
    # Replace the tag with the tag that you want to use.
    pod 'GRDB.swift', git: 'https://github.com/groue/GRDB.swift.git', tag: 'v6.29.0' 
    ```
## Carthage
[Carthage](https://github.com/Carthage/Carthage) is **unsupported**. For some context about this decision, see [#433](https://github.com/groue/GRDB.swift/issues/433).
## Manually
1. [Download](https://github.com/groue/GRDB.swift/releases) a copy of GRDB, or clone its repository and make sure you checkout the latest tagged version.
2. Embed the `GRDB.xcodeproj` project in your own project.
3. Add the `GRDB` target in the **Target Dependencies** section of the **Build Phases** tab of your application target (extension target for WatchOS).
4. Add the `GRDB.framework` to the **Embedded Binaries** section of the **General**  tab of your application target (extension target for WatchOS).
Database Connections
====================
GRDB provides two classes for accessing SQLite databases: [`DatabaseQueue`] and [`DatabasePool`]:
```swift
import GRDB

// Pick one:
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")
let dbPool = try DatabasePool(path: "/path/to/database.sqlite")
```
The differences are:
- Database pools allow concurrent database accesses (this can improve the performance of multithreaded applications).
- Database pools open your SQLite database in the [WAL mode](https://www.sqlite.org/wal.html) (unless read-only).
- Database queues support [in-memory databases](https://www.sqlite.org/inmemorydb.html).
