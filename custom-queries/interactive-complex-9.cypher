// Q9. Recent messages by friends or friends of friends
/*
:params { personId: 4398046511268, maxDate: 1289908800000 }
*/
CALL {
  USE fabric.persons
  MATCH (root:Person {id: $personId})-[:KNOWS*1..2]-(friend:Person)
  WHERE NOT friend = root
  WITH DISTINCT friend
  RETURN collect(friend.id) AS friendIds
}
CALL {
  WITH friendIds
  USE fabric.forums
  UNWIND friendIds AS friendId
  MATCH (friendProxy:PersonID {id: friendId})<-[:HAS_CREATOR]-(message)
  WHERE (message:Post OR message:Comment) AND message.creationDate < datetime({epochMillis: $maxDate})
  RETURN message.id AS commentOrPostId,
         coalesce(message.content, message.imageFile) AS commentOrPostContent,
         message.creationDate AS commentOrPostCreationDate,
         friendId AS authorId
  ORDER BY message.creationDate DESC, message.id ASC
  LIMIT 20
}
CALL {
  WITH authorId
  USE fabric.persons
  MATCH (person:Person {id: authorId})
  RETURN person.id AS personId, person.firstName AS personFirstName, person.lastName AS personLastName
}
RETURN personId, personFirstName, personLastName, commentOrPostId, commentOrPostContent, commentOrPostCreationDate
