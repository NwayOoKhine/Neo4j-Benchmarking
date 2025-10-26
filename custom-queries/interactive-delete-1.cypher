// ============================================================================
// DELETE 1: Remove Person (TWO VERSIONS)
// ============================================================================

// ----------------------------------------------------------------------------
// VERSION 1: BUGGY - Leaves Dangling Proxy (Original - Used in Inconsistency Demo)
// ----------------------------------------------------------------------------
// // DEL 1 (Inconsistency demo)
// // Delete only Person in persons shard, do NOT touch proxy PersonID in forums
// /*
// :params { personId: 10995116277794 }
// */
// CALL {
//   USE fabric.persons
//   MATCH (person:Person {id: $personId})
//   DETACH DELETE person
//   RETURN count(*) AS deletedPersons
// }
// RETURN deletedPersons

// ----------------------------------------------------------------------------
// VERSION 2: CLEANUP-AWARE - Deletes Proxy to Prevent Inconsistency (ACTIVE)
// ----------------------------------------------------------------------------
// DEL 1 (Cleanup-aware)
// Delete Person in persons shard AND proxy PersonID in forums shard
/*
:params { personId: 10995116277794 }
*/
USE fabric.persons
MATCH (p:Person {id: $personId})
DETACH DELETE p;

USE fabric.forums
MATCH (proxy:PersonID {id:$personId})
OPTIONAL MATCH (m:Post|Comment)-[:HAS_CREATOR]->(proxy)
OPTIONAL MATCH (f:Forum)-[mod:HAS_MODERATOR]->(proxy)
OPTIONAL MATCH (f2:Forum)-[mem:HAS_MEMBER]->(proxy)
DETACH DELETE m
DELETE mod, mem
DETACH DELETE proxy;