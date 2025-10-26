// DEL 6: Remove post thread
// MATCH (:Post {id: $postId})<-[:REPLY_OF*0..]-(message:Message) // DEL 6/7
// DETACH DELETE message
// RETURN count(*)

CALL {
  USE fabric.forums
  MATCH (:Post {id: $postId})<-[:REPLY_OF*0..]-(message:Comment)
  DETACH DELETE message
  RETURN count(*) AS deletedMessages
}
RETURN deletedMessages