// DEL 4: Remove forum and its content
// MATCH (forum:Forum {id: $forumId})
// OPTIONAL MATCH (forum)-[:CONTAINER_OF]->(:Post)<-[:REPLY_OF*0..]-(message:Message)
// DETACH DELETE forum, message
// RETURN count(*)

// DEL 4 (Inconsistency demo)
/*
:params { forumId: 2147483648 }
*/
CALL {
  USE fabric.forums
  MATCH (forum:Forum {id: $forumId})
  OPTIONAL MATCH (forum)-[:CONTAINER_FORUM]->(:Post)<-[:REPLY_OF*0..]-(message:Comment)
  DETACH DELETE forum, message
  RETURN count(*) AS deletedForums
}
RETURN deletedForums
