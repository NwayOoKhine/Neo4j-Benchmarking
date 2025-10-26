// DEL 5: Remove forum membership
// MATCH (:Forum {id: $forumId})-[hasMember:HAS_MEMBER]->(:Person {id: $personId})
// DELETE hasMember
// RETURN count(*)

// DEL 5 (Consistent)
/*
:params { forumId: 2147483648, personId: 10995116277794 }
*/
CALL {
  USE fabric.forums
  MATCH (:Forum {id: $forumId})-[hasMember:HAS_MEMBER]->(:PersonID {id: $personId})
  DELETE hasMember
  RETURN count(*) AS deletedMemberships
}
RETURN deletedMemberships

