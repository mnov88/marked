    When the sequence is empty, `joined(operator: .and)` returns true, and `joined(operator: .or)` returns false:
- `BETWEEN`, `IN`, `NOT IN`
    To check inclusion in a Swift sequence (array, set, range…), call the `contains` method:
    ```swift
    // SELECT * FROM player WHERE id IN (1, 2, 3)
    Player.filter { [1, 2, 3].contains($0.id) }
    
    // SELECT * FROM player WHERE id NOT IN (1, 2, 3)
    Player.filter { ![1, 2, 3].contains($0.id) }
    
    // SELECT * FROM player WHERE score BETWEEN 0 AND 1000
    Player.filter { (0...1000).contains($0.score) }
    
    // SELECT * FROM player WHERE (score >= 0) AND (score < 1000)
    Player.filter { (0..<1000).contains($0.score) }
    
    // SELECT * FROM player WHERE initial BETWEEN 'A' AND 'N'
    Player.filter { ("A"..."N").contains($0.initial) }
    
    // SELECT * FROM player WHERE (initial >= 'A') AND (initial < 'N')
    Player.filter { ("A"..<"N").contains($0.initial) }
    ```
    To check inclusion inside a subquery, call the `contains` method as well:
    ```swift
    // SELECT * FROM player WHERE id IN (SELECT playerId FROM playerSelection)
    let selectedPlayerIds = PlayerSelection.select(\.playerId)
    Player.filter { selectedPlayerIds.contains($0.id) }
    
    // SELECT * FROM player WHERE id IN (SELECT playerId FROM playerSelection)
    let selectedPlayerIds = SQLRequest("SELECT playerId FROM playerSelection")
    Player.filter { selectedPlayerIds.contains($0.id) }
    ```
    To check inclusion inside a [common table expression], call the `contains` method as well:
    ```swift
    // WITH selectedName AS (...)
    // SELECT * FROM player WHERE name IN selectedName
    let cte = CommonTableExpression(named: "selectedName", ...)
    Player
        .with(cte)
        .filter { cte.contains($0.name) }
    ```
    > **Note**: SQLite string comparison, by default, is case-sensitive and not Unicode-aware. See [string comparison](#string-comparison) if you need more control.
- `EXISTS`, `NOT EXISTS`
    To check if a subquery would return rows, call the `exists` method:
    ```swift
    // Teams that have at least one other player
    //
    //  SELECT * FROM team
    //  WHERE EXISTS (SELECT * FROM player WHERE teamId = team.id)
    let teamAlias = TableAlias<Team>()
    let player = Player.filter { $0.teamId == teamAlias.id }
    let teams = Team.aliased(teamAlias).filter(player.exists())
    
    // Teams that have no player
    //
    //  SELECT * FROM team
    //  WHERE NOT EXISTS (SELECT * FROM player WHERE teamId = team.id)
    let teams = Team.aliased(teamAlias).filter(!player.exists())
    ```
    In the above example, you use a `TableAlias` in order to let a subquery refer to a column from another table.
    In the next example, which involves the same table twice, the table alias requires an explicit disambiguation with `TableAlias(name:)`:
    ```swift    
    // Players who coach at least one other player
    //
    //  SELECT coach.* FROM player coach
    //  WHERE EXISTS (SELECT * FROM player WHERE coachId = coach.id)
    let coachAlias = TableAlias<Player>(name: "coach")
    let coachedPlayer = Player.filter { $0.coachId == coachAlias.id }
    let coaches = Player.aliased(coachAlias).filter(coachedPlayer.exists())
    ```
    Finally, subqueries can also be expressed as SQL, with [SQL Interpolation]:
    ```swift
    // SELECT coach.* FROM player coach
    // WHERE EXISTS (SELECT * FROM player WHERE coachId = coach.id)
    let coachedPlayer = SQLRequest("SELECT * FROM player WHERE coachId = \(coachAlias.id)")
    let coaches = Player.aliased(coachAlias).filter(coachedPlayer.exists())
    ```
- `LIKE`
    The SQLite LIKE operator is available as the `like` method:
    ```swift
    // SELECT * FROM player WHERE (email LIKE '%@example.com')
    Player.filter { $0.email.like("%@example.com") }
    
    // SELECT * FROM book WHERE (title LIKE '%10\%%' ESCAPE '\')
    Player.filter { $0.email.like("%10\\%%", escape: "\\") }
    ```
    > **Note**: the SQLite LIKE operator is case-insensitive but not Unicode-aware. For example, the expression `'a' LIKE 'A'` is true but `'æ' LIKE 'Æ'` is false.
- `MATCH`
    The full-text MATCH operator is available through [FTS3Pattern](Documentation/FullTextSearch.md#fts3pattern) (for FTS3 and FTS4 tables) and [FTS5Pattern](Documentation/FullTextSearch.md#fts5pattern) (for FTS5):
    FTS3 and FTS4:
    ```swift
    let pattern = FTS3Pattern(matchingAllTokensIn: "SQLite database")
    
    // SELECT * FROM document WHERE document MATCH 'sqlite database'
    Document.matching(pattern)
    
    // SELECT * FROM document WHERE content MATCH 'sqlite database'
    Document.filter { $0.content.match(pattern) }
    ```
    FTS5:
    ```swift
    let pattern = FTS5Pattern(matchingAllTokensIn: "SQLite database")
    
    // SELECT * FROM document WHERE document MATCH 'sqlite database'
    Document.matching(pattern)
    ```
