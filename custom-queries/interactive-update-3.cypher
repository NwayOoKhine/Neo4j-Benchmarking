CALL {
  USE fabric.forums
  MATCH (comment:Comment {id: $commentId})
  MERGE (personProxy:PersonID {id: $personId})
  CREATE (personProxy)-[:LIKES {creationDate: $creationDate}]->(comment)
}
