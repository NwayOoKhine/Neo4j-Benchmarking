// DEL 7: Remove comment subthread
// MATCH (:Comment {id: $commentId})<-[:REPLY_OF*0..]-(comment:Comment)
// DETACH DELETE comment
// RETURN count(*)

// Check Comment creators without valid Person
CALL {
  USE fabric.forums
  MATCH (c:Comment)-[:HAS_CREATOR]->(pid:PersonID)
  RETURN c.id AS commentId, pid.id AS proxyId
}
CALL {
  USE fabric.persons
  MATCH (p:Person)
  RETURN collect(p.id) AS validPersons
}
WITH commentId, proxyId, validPersons
WHERE NOT proxyId IN validPersons
RETURN commentId, proxyId AS danglingCommentCreator
