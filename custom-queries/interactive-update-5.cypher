CALL {
  USE fabric.forums
  MATCH (f:Forum {id: $forumId})
  MERGE (personProxy:PersonID {id: $personId})
  CREATE (f)-[:HAS_MEMBER {creationDate: $creationDate}]->(personProxy)
}
