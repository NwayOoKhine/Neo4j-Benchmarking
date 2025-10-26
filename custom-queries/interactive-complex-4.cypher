// Q4. New topics
/*
:params { personId: 4398046511333, startDate: 1275350400000, endDate: 1277856000000 }
*/
CALL {
  USE fabric.persons
  MATCH (person:Person {id: $personId})-[:KNOWS]-(friend:Person)
  RETURN collect(friend.id) AS friendIds
}
CALL {
  WITH friendIds
  USE fabric.forums
  UNWIND friendIds AS friendId
  MATCH (friendProxy:PersonID {id: friendId})<-[:HAS_CREATOR]-(post:Post)-[:HAS_TAG]->(tag)
  WITH DISTINCT tag, post
  WITH tag,
       CASE
         WHEN post.creationDate >= datetime({epochMillis: $startDate}) AND post.creationDate < datetime({epochMillis: $endDate}) THEN 1
         ELSE 0
       END AS valid,
       CASE
         WHEN post.creationDate < datetime({epochMillis: $startDate}) THEN 1
         ELSE 0
       END AS inValid
  WITH tag, sum(valid) AS postCount, sum(inValid) AS inValidPostCount
  WHERE postCount > 0 AND inValidPostCount = 0
  RETURN tag.name AS tagName, postCount
  ORDER BY postCount DESC, tagName ASC
  LIMIT 10
}
RETURN tagName, postCount
