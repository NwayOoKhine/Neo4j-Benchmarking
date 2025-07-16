// Load SF1 Forums Data (without Posts/Comments to avoid memory issues)
// This gives us the full 100,830 forums for realistic scale testing

// Constraints for Forum-related entities
CREATE CONSTRAINT forum_id IF NOT EXISTS FOR (f:Forum) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;

// Load all Forums (~100,830 forums)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

// Forum has member Person (cross-shard relationship)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasMember_Person/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
// Create lightweight Person reference for cross-shard relationships
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MEMBER {joinDate: datetime(replace(row.joinDate, ' ', 'T'))}]->(p);

// Forum has moderator Person (cross-shard relationship)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasModerator_Person/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MODERATOR]->(p);

// Forum has tag
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasTag_Tag/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
// Create lightweight Tag reference
MERGE (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (f)-[:HAS_TAG]->(t);

// Show summary of what was loaded
MATCH (f:Forum) RETURN 'Forums loaded: ' + count(f) AS summary
UNION ALL
MATCH (p:Person) RETURN 'Person references: ' + count(p) AS summary
UNION ALL
MATCH (t:Tag) RETURN 'Tag references: ' + count(t) AS summary
UNION ALL
MATCH ()-[r:HAS_MEMBER]->() RETURN 'Forum memberships: ' + count(r) AS summary
UNION ALL
MATCH ()-[r:HAS_MODERATOR]->() RETURN 'Forum moderators: ' + count(r) AS summary; 