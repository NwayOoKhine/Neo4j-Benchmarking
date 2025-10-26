// DEL 8: Remove friendship
// MATCH (:Person {id: $person1Id})-[knows:KNOWS]-(:Person {id: $person2Id})
// DELETE knows
// RETURN count(*)

// DEL 8 (Consistent)
/*
:params { person1Id: 10995116277794, person2Id: 10995116277795 }
*/
CALL {
  USE fabric.persons
  MATCH (:Person {id: $person1Id})-[knows:KNOWS]-(:Person {id: $person2Id})
  DELETE knows
  RETURN count(*) AS deletedFriendships
}
RETURN deletedFriendships
