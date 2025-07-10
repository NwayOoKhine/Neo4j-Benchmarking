// Load SF1 data into Forums Shard
// Handles directory-based compressed CSV structure

// Constraints for Forum-related entities
CREATE CONSTRAINT forum_id IF NOT EXISTS FOR (f:Forum) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT post_id IF NOT EXISTS FOR (p:Post) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT comment_id IF NOT EXISTS FOR (c:Comment) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;

// Forums
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

// Posts
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Post {
    id: toInteger(row.id),
    imageFile: row.imageFile,
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    language: row.language,
    content: row.content,
    length: toInteger(row.length)
});

// Comments
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Comment {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    content: row.content,
    length: toInteger(row.length)
});

// Relationships
// Forum has member Person (requires cross-shard reference to Person)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasMember_Person/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
// Create lightweight Person reference for cross-shard relationships
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MEMBER {joinDate: datetime(replace(row.joinDate, ' ', 'T'))}]->(p);

// Forum has moderator Person
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasModerator_Person/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MODERATOR]->(p);

// Forum has tag
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasTag_Tag/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
// Create lightweight Tag reference
MERGE (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (f)-[:HAS_TAG]->(t);

// Post has creator Person
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post_hasCreator_Person/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (post:Post {id: toInteger(row.`Post.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (post)-[:HAS_CREATOR]->(p);

// Post has tag
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post_hasTag_Tag/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (post:Post {id: toInteger(row.`Post.id`)})
MERGE (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (post)-[:HAS_TAG]->(t);

// Post located in Country
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post_isLocatedIn_Country/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (post:Post {id: toInteger(row.`Post.id`)})
// Create lightweight Country reference
MERGE (c:Place {id: toInteger(row.`Country.id`)})
CREATE (post)-[:IS_LOCATED_IN]->(c);

// Comment has creator Person
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_hasCreator_Person/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (c)-[:HAS_CREATOR]->(p);

// Comment has tag
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_hasTag_Tag/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MERGE (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (c)-[:HAS_TAG]->(t);

// Comment located in Country
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_isLocatedIn_Country/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MERGE (country:Place {id: toInteger(row.`Country.id`)})
CREATE (c)-[:IS_LOCATED_IN]->(country);

// Comment replies to Post
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_replyOf_Post/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (p:Post {id: toInteger(row.`Post.id`)})
CREATE (c)-[:REPLY_OF]->(p);

// Comment replies to Comment
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_replyOf_Comment/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c1:Comment {id: toInteger(row.`Comment.id`)})
MATCH (c2:Comment {id: toInteger(row.`Comment.id.1`)})
CREATE (c1)-[:REPLY_OF]->(c2);

// Container of relationships
// Post is in Forum
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post_isPartOf_Forum/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p:Post {id: toInteger(row.`Post.id`)})
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
CREATE (p)-[:CONTAINER_OF]->(f); 