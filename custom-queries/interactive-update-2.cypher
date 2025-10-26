CALL {
  USE fabric.forums
  MATCH (post:Post {id: $postId})
  MERGE (personProxy:PersonID {id: $personId})
  CREATE (personProxy)-[:LIKES {creationDate: $creationDate}]->(post)
}
