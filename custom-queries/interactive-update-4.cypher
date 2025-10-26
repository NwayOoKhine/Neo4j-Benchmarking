CALL {
  USE fabric.forums
  MERGE (moderatorProxy:PersonID {id: $moderatorPersonId})
  CREATE (f:Forum {id: $forumId, title: $forumTitle, creationDate: $creationDate})-[:HAS_MODERATOR]->(moderatorProxy)
  WITH f
  UNWIND $tagIds AS tagId
    MATCH (t:Tag {id: tagId})
    CREATE (f)-[:HAS_TAG]->(t)
}
