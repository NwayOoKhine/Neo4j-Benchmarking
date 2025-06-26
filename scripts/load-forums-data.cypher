// Create constraints for the forums database
CREATE CONSTRAINT ON (f:Forum) ASSERT f.id IS UNIQUE;
CREATE CONSTRAINT ON (p:Post) ASSERT p.id IS UNIQUE;
CREATE CONSTRAINT ON (c:Comment) ASSERT c.id IS UNIQUE;
CREATE CONSTRAINT ON (t:Tag) ASSERT t.id IS UNIQUE;


// Load static data for the forums graph

// Tags
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tag_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Tag {
    id: toInteger(row.id),
    name: row.name,
    url: row.url
});


// Load dynamic data for the forums graph

// Forums
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime({epochMillis: toInteger(row.creationDate)})
});

// Posts
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Post {
    id: toInteger(row.id),
    imageFile: row.imageFile,
    creationDate: datetime({epochMillis: toInteger(row.creationDate)}),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    language: row.language,
    content: row.content,
    length: toInteger(row.length)
});

// Comments
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Comment {
    id: toInteger(row.id),
    creationDate: datetime({epochMillis: toInteger(row.creationDate)}),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    content: row.content,
    length: toInteger(row.length)
});


// Relationships

// Forum has member Person
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_hasMember_person_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MEMBER {joinDate: datetime({epochMillis: toInteger(row.joinDate)})}]->(p);

// Forum has tag Tag
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_hasTag_tag_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (f)-[:HAS_TAG]->(t);

// Post has creator Person
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_hasCreator_person_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (po:Post {id: toInteger(row.`Post.id`)})
MATCH (pe:Person {id: toInteger(row.`Person.id`)})
CREATE (po)-[:HAS_CREATOR]->(pe);

// Comment has creator Person
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_hasCreator_person_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (p:Person {id: toInteger(row.`Person.id`)})
CREATE (c)-[:HAS_CREATOR]->(p);

// Post has tag Tag
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/post_hasTag_tag_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (po:Post {id: toInteger(row.`Post.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (po)-[:HAS_TAG]->(t);

// Comment has tag Tag
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_hasTag_tag_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (c)-[:HAS_TAG]->(t);

// Comment replies to Post
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_replyOf_post_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (p:Post {id: toInteger(row.`Post.id`)})
CREATE (c)-[:REPLY_OF]->(p);

// Comment replies to Comment
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/comment_replyOf_comment_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (c1:Comment {id: toInteger(row.`Comment1.id`)})
MATCH (c2:Comment {id: toInteger(row.`Comment2.id`)})
CREATE (c1)-[:REPLY_OF]->(c2);

// Tag has type TagClass
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tag_hasType_tagclass_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
MATCH (tc:TagClass {id: toInteger(row.`TagClass.id`)})
CREATE (t)-[:HAS_TYPE]->(tc);

// Forum container of Post
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/forum_containerOf_post_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (p:Post {id: toInteger(row.`Post.id`)})
CREATE (f)-[:CONTAINER_OF]->(p);

// Person likes Post
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_likes_post_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (po:Post {id: toInteger(row.`Post.id`)})
CREATE (p)-[:LIKES {creationDate: datetime({epochMillis: toInteger(row.creationDate)})}]->(po);

// Person likes Comment
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_likes_comment_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
CREATE (p)-[:LIKES {creationDate: datetime({epochMillis: toInteger(row.creationDate)})}]->(c); 