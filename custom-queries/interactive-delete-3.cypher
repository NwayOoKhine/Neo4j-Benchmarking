// DEL 3: Remove comment like
// MATCH (:Person {id: $personId})-[likes:LIKES]->(:Comment {id: $commentId})
// DELETE likes
// RETURN count(*)

// DEL 3 (Inconsistency demo)
/*
:params { personId: 10995116277794, commentId: 1924145348615 }
*/
CALL {
  USE fabric.forums
  MATCH (pid:PersonID {id: $personId})-[likes:LIKES]->(:Comment {id: $commentId})
  DELETE likes
  RETURN count(*) AS deletedLikes
}
RETURN deletedLikes

