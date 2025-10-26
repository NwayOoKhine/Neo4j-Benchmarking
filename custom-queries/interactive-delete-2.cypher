// DEL 2: Remove post like
// MATCH (:Person {id: $personId})-[likes:LIKES]->(:Post {id: $postId})
// DELETE likes
// RETURN count(*) 

// DEL 2 (Inconsistency demo)
// Try to delete like — but only within one shard
/*
:params { personId: 10995116277794, postId: 206158431836 }
*/
CALL {
  USE fabric.forums
  MATCH (pid:PersonID {id: $personId})-[likes:LIKES]->(:Post {id: $postId})
  DELETE likes
  RETURN count(*) AS deletedLikes
}
RETURN deletedLikes

