- [`annotated(withRequired: association)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/annotated(withrequired:)) and [`annotated(withOptional: association)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/joinablerequest/annotated(withoptional:)) extends the selection with [Associations].
    ```swift
    // SELECT player.*, team.color
    // FROM player
    // JOIN team ON team.id = player.teamId
    Player.annotated(withRequired: Player.team.select(\.color))
    ```
- [`distinct()`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/derivablerequest/distinct()) performs uniquing.
    ```swift
    // SELECT DISTINCT name FROM player
    Player.select(\.name, as: String.self).distinct()
    ```
- [`filter(expression)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/filteredrequest/filter(_:)-6xr3d) applies conditions.
    ```swift
    // SELECT * FROM player WHERE id IN (1, 2, 3)
    Player.filter { [1,2,3].contains($0.id) }
    
    // SELECT * FROM player WHERE (name IS NOT NULL) AND (height > 1.75)
    Player.filter { $0.name != nil && $0.height > 1.75 }
    ```
- [`filter(id:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/filter(id:)) and [`filter(ids:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/filter(ids:)) are type-safe methods available on [Identifiable Records]:
    ```swift
    // SELECT * FROM player WHERE id = 1
    Player.filter(id: 1)
    
    // SELECT * FROM country WHERE isoCode IN ('FR', 'US')
    Country.filter(ids: ["FR", "US"])
    ```
- [`filter(key:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/filter(key:)-1p9sq) and [`filter(keys:)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/filter(keys:)-6ggt1) apply conditions on primary and unique keys:
    ```swift
    // SELECT * FROM player WHERE id = 1
    Player.filter(key: 1)
    
    // SELECT * FROM country WHERE isoCode IN ('FR', 'US')
    Country.filter(keys: ["FR", "US"])
    
    // SELECT * FROM citizenship WHERE citizenId = 1 AND countryCode = 'FR'
    Citizenship.filter(key: ["citizenId": 1, "countryCode": "FR"])
    
    // SELECT * FROM player WHERE email = 'arthur@example.com'
    Player.filter(key: ["email": "arthur@example.com"])
    ```
- `matching(pattern)` ([FTS3](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/matching(_:)-3s3zr), [FTS5](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/tablerequest/matching(_:)-7c1e8)) performs [full-text search](Documentation/FullTextSearch.md).
    ```swift
    // SELECT * FROM document WHERE document MATCH 'sqlite database'
    let pattern = FTS3Pattern(matchingAllTokensIn: "SQLite database")
    Document.matching(pattern)
    ```
    When the pattern is nil, no row will match.
- [`group(expression, ...)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/aggregatingrequest/group(_:)-2g7br) groups rows.
    ```swift
    // SELECT name, MAX(score) FROM player GROUP BY name
    Player
        .select { [$0.name, max($0.score)] }
        .group(\.name)
    ```
- [`having(expression)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/aggregatingrequest/having(_:)-2oggh) applies conditions on grouped rows.
    ```swift
    // SELECT team, MAX(score) FROM player GROUP BY team HAVING MIN(score) >= 1000
    Player
        .select { [$0.team, max($0.score)] }
        .group(\.team)
        .having { min($0.score) >= 1000 }
    ```
- [`having(aggregate)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/derivablerequest/having(_:)) applies conditions on grouped rows, according to an [association aggregate](Documentation/AssociationsBasics.md#association-aggregates).
    ```swift
    // SELECT team.*
    // FROM team
    // LEFT JOIN player ON player.teamId = team.id
    // GROUP BY team.id
    // HAVING COUNT(DISTINCT player.id) >= 5
    Team.having(Team.players.count >= 5)
    ```
- [`order(ordering, ...)`](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/orderedrequest/order(_:)-9d0hr) sorts.
    ```swift
    // SELECT * FROM player ORDER BY name
    Player.order(\.name)
    
    // SELECT * FROM player ORDER BY score DESC
    Player.order(\.score.desc)
    
    // SELECT * FROM player ORDER BY score DESC, name
    Player.order { [$0.score.desc, $0.name] }
    ```
    SQLite considers NULL values to be smaller than any other values for sorting purposes. Hence, NULLs naturally appear at the beginning of an ascending ordering and at the end of a descending ordering. With a [custom SQLite build], this can be changed using `.ascNullsLast` and `.descNullsFirst`:
    ```swift
    // SELECT * FROM player ORDER BY score ASC NULLS LAST
    Player.order(\.name.ascNullsLast)
    ```
    Each `order` call clears any previous ordering:
