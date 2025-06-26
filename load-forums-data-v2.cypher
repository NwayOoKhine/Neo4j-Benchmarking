// Create a new file 'load-forums-data-v2.cypher'

// Constraints
CREATE CONSTRAINT post_id IF NOT EXISTS FOR (p:Post) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT comment_id IF NOT EXISTS FOR (c:Comment) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT forum_id IF NOT EXISTS FOR (f:Forum) REQUIRE f.id IS UNIQUE;

// Forums
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_0_0.csv" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

// Forum has moderator Person
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_hasModerator_person_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MODERATOR]->(p);

// Forum has member Person
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_hasMember_person_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MEMBER {joinDate: datetime(replace(row.joinDate, ' ', 'T'))}]->(p);

// Forum has tag Tag
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_hasTag_tag_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (f)-[:HAS_TAG]->(t);

// Posts
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_0_0.csv" AS row FIELDTERMINATOR '|'
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

// Post is located in Place
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_isLocatedIn_place_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (po:Post {id: toInteger(row.`Post.id`)})
MATCH (pl:Place {id: toInteger(row.`Place.id`)})
CREATE (po)-[:IS_LOCATED_IN]->(pl);

// Post has creator Person
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_hasCreator_person_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (po:Post {id: toInteger(row.`Post.id`)})
MATCH (pe:Person {id: toInteger(row.`Person.id`)})
CREATE (po)-[:HAS_CREATOR]->(pe);

// Post has tag Tag
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_hasTag_tag_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (po:Post {id: toInteger(row.`Post.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (po)-[:HAS_TAG]->(t);

// Forum container of Post
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_containerOf_post_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (po:Post {id: toInteger(row.`Post.id`)})
CREATE (f)-[:CONTAINER_OF]->(po);

// Comments
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_0_0.csv" AS row FIELDTERMINATOR '|'
CREATE (:Comment {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    content: row.content,
    length: toInteger(row.length)
});

// Comment is located in Place
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_isLocatedIn_place_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (pl:Place {id: toInteger(row.`Place.id`)})
CREATE (c)-[:IS_LOCATED_IN]->(pl);

// Comment has creator Person
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_hasCreator_person_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (pe:Person {id: toInteger(row.`Person.id`)})
CREATE (c)-[:HAS_CREATOR]->(pe);

// Comment has tag Tag
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_hasTag_tag_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (c)-[:HAS_TAG]->(t);

// Comment reply of Post
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_replyOf_post_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (po:Post {id: toInteger(row.`Post.id`)})
CREATE (c)-[:REPLY_OF]->(po);

// Comment reply of Comment
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_replyOf_comment_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (c1:Comment {id: toInteger(row.`Comment.id`)})
MATCH (c2:Comment {id: toInteger(row.`Comment.id_2`)})
CREATE (c1)-[:REPLY_OF]->(c2);

// Person likes Post
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_likes_post_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (po:Post {id: toInteger(row.`Post.id`)})
CREATE (p)-[:LIKES {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(po);

// Person likes Comment
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_likes_comment_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
CREATE (p)-[:LIKES {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(c); 