// Q5. New groups
/*
:params { personId: 6597069766734, minDate: 1288612800000 }
*/
CALL {
  USE fabric.persons
  MATCH (person:Person {id: $personId})-[:KNOWS*1..2]-(otherPerson)
  WHERE person <> otherPerson
  WITH DISTINCT otherPerson
  RETURN collect(otherPerson.id) AS otherPersonIds
}
CALL {
  WITH otherPersonIds
  USE fabric.forums
  UNWIND otherPersonIds AS otherPersonId
  MATCH (otherPersonProxy:PersonID {id: otherPersonId})<-[membership:HAS_MEMBER]-(forum)
  WHERE membership.creationDate > datetime({epochMillis: $minDate})
  WITH forum, collect(otherPersonId) AS forumMemberIds
  OPTIONAL MATCH (memberProxy:PersonID)<-[:HAS_CREATOR]-(post)-[:CONTAINER_FORUM]->(forum)
  WHERE memberProxy.id IN forumMemberIds
  WITH forum, count(post) AS postCount
  RETURN forum.title AS forumName, postCount, forum.id AS forumId
  ORDER BY postCount DESC, forumId ASC
  LIMIT 20
}
RETURN forumName, postCount
