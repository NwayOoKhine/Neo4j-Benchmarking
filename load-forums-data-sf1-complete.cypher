// Load Complete SF1 Forums Data including Posts and Comments
// This script loads the full LDBC SNB SF1 dataset into the forums shard

// =============================================================================
// CONSTRAINTS
// =============================================================================
CREATE CONSTRAINT forum_id IF NOT EXISTS FOR (f:Forum) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT post_id IF NOT EXISTS FOR (p:Post) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT comment_id IF NOT EXISTS FOR (c:Comment) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;

// =============================================================================
// STATIC DATA - Tags and Places (Referenced by Posts/Comments)
// =============================================================================

// Load Tags (referenced by Posts and Comments)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag/part-00000-166fdbfc-cb02-4c99-86e1-3397b1adc371-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Tag {
    id: toInteger(row.id),
    name: row.name,
    url: row.url
});

// Load Places (Countries - referenced by Posts/Comments location)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place/part-00000-a3bd38c5-4e4b-48a0-b2c3-f6e9a924b99a-c000.csv.gz" AS row FIELDTERMINATOR '|'
WHERE row.type = 'country'  // Only load countries for Posts/Comments
CREATE (:Place {
    id: toInteger(row.id),
    name: row.name,
    url: row.url,
    type: row.type
});

// =============================================================================
// FORUMS
// =============================================================================

// Load all Forums (~100,830 forums)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

// =============================================================================
// POSTS (Main Content)
// =============================================================================

// Load Posts - Part 1 (largest file)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00003-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Post {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    imageFile: row.imageFile,
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    language: row.language,
    content: row.content,
    length: toInteger(row.length),
    creatorPersonId: toInteger(row.CreatorPersonId),
    containerForumId: toInteger(row.ContainerForumId),
    locationCountryId: toInteger(row.LocationCountryId)
});

// Load Posts - Part 2  
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00008-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Post {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    imageFile: row.imageFile,
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    language: row.language,
    content: row.content,
    length: toInteger(row.length),
    creatorPersonId: toInteger(row.CreatorPersonId),
    containerForumId: toInteger(row.ContainerForumId),
    locationCountryId: toInteger(row.LocationCountryId)
});

// =============================================================================
// COMMENTS (Replies to Posts and Comments)
// =============================================================================

// Load Comments - Part 1 (largest file)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment/part-00011-01afcac0-af10-4b69-8981-adf26d17579e-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Comment {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    content: row.content,
    length: toInteger(row.length),
    creatorPersonId: toInteger(row.CreatorPersonId),
    locationCountryId: toInteger(row.LocationCountryId),
    parentPostId: CASE WHEN row.ParentPostId = '' THEN null ELSE toInteger(row.ParentPostId) END,
    parentCommentId: CASE WHEN row.ParentCommentId = '' THEN null ELSE toInteger(row.ParentCommentId) END
});

// Load Comments - Part 2
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment/part-00022-01afcac0-af10-4b69-8981-adf26d17579e-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Comment {
    id: toInteger(row.id),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    content: row.content,
    length: toInteger(row.length),
    creatorPersonId: toInteger(row.CreatorPersonId),
    locationCountryId: toInteger(row.LocationCountryId),
    parentPostId: CASE WHEN row.ParentPostId = '' THEN null ELSE toInteger(row.ParentPostId) END,
    parentCommentId: CASE WHEN row.ParentCommentId = '' THEN null ELSE toInteger(row.ParentCommentId) END
});

// =============================================================================
// RELATIONSHIPS - Posts to Forums and Locations
// =============================================================================

// Connect Posts to their containing Forums
MATCH (p:Post), (f:Forum)
WHERE p.containerForumId = f.id
CREATE (f)-[:CONTAINER_OF]->(p);

// Connect Posts to their location countries
MATCH (p:Post), (c:Place)
WHERE p.locationCountryId = c.id AND c.type = 'country'
CREATE (p)-[:IS_LOCATED_IN]->(c);

// =============================================================================
// RELATIONSHIPS - Comments to Posts/Comments and Locations  
// =============================================================================

// Connect Comments to their parent Posts
MATCH (c:Comment), (p:Post)
WHERE c.parentPostId = p.id
CREATE (p)-[:HAS_COMMENT]->(c);

// Connect Comments to their parent Comments (nested comments)
MATCH (c1:Comment), (c2:Comment)
WHERE c1.parentCommentId = c2.id
CREATE (c2)-[:HAS_COMMENT]->(c1);

// Connect Comments to their location countries
MATCH (c:Comment), (place:Place)
WHERE c.locationCountryId = place.id AND place.type = 'country'
CREATE (c)-[:IS_LOCATED_IN]->(place);

// =============================================================================
// RELATIONSHIPS - Tags
// =============================================================================

// Post has Tag relationships
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post_hasTag_Tag/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p:Post {id: toInteger(row.`Post.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (p)-[:HAS_TAG]->(t);

// Comment has Tag relationships
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment_hasTag_Tag/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (c:Comment {id: toInteger(row.`Comment.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (c)-[:HAS_TAG]->(t);

// =============================================================================
// CROSS-SHARD REFERENCES - Person Lightweight Nodes
// =============================================================================

// Create lightweight Person references for Posts creators (cross-shard)
MATCH (p:Post)
WITH DISTINCT p.creatorPersonId as personId
MERGE (:Person {id: personId});

// Create lightweight Person references for Comments creators (cross-shard)
MATCH (c:Comment)
WITH DISTINCT c.creatorPersonId as personId
MERGE (:Person {id: personId});

// Forum membership and moderation (reloading for completeness)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasMember_Person/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MEMBER {joinDate: datetime(replace(row.joinDate, ' ', 'T'))}]->(p);

LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasModerator_Person/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MERGE (p:Person {id: toInteger(row.`Person.id`)})
CREATE (f)-[:HAS_MODERATOR]->(p);

// Forum has Tag relationships (reloading for completeness)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum_hasTag_Tag/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (f:Forum {id: toInteger(row.`Forum.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (f)-[:HAS_TAG]->(t);

// =============================================================================
// CROSS-SHARD RELATIONSHIPS - Likes (People like Posts/Comments)
// =============================================================================

// Person likes Post (cross-shard relationship)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_likes_Post/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MERGE (p:Person {id: toInteger(row.`Person.id`)})
MATCH (post:Post {id: toInteger(row.`Post.id`)})
CREATE (p)-[:LIKES {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(post);

// Person likes Comment (cross-shard relationship)  
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_likes_Comment/part-00000-76b8c8a8-5e3e-4d1c-a5dc-7c9b5b1c3c93-c000.csv.gz" AS row FIELDTERMINATOR '|'
MERGE (p:Person {id: toInteger(row.`Person.id`)})
MATCH (comment:Comment {id: toInteger(row.`Comment.id`)})
CREATE (p)-[:LIKES {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(comment);

// =============================================================================
// SUMMARY AND VERIFICATION
// =============================================================================

// Show summary of loaded data
MATCH (f:Forum) WITH count(f) as forumCount
MATCH (p:Post) WITH forumCount, count(p) as postCount  
MATCH (c:Comment) WITH forumCount, postCount, count(c) as commentCount
MATCH (t:Tag) WITH forumCount, postCount, commentCount, count(t) as tagCount
MATCH (person:Person) WITH forumCount, postCount, commentCount, tagCount, count(person) as personRefCount
MATCH (place:Place) WITH forumCount, postCount, commentCount, tagCount, personRefCount, count(place) as placeCount
RETURN 
    'Forums: ' + forumCount AS forums,
    'Posts: ' + postCount AS posts,
    'Comments: ' + commentCount AS comments,
    'Tags: ' + tagCount AS tags,
    'Person refs: ' + personRefCount AS persons,
    'Places: ' + placeCount AS places;

// Relationship summary
MATCH ()-[r:HAS_MEMBER]->() WITH count(r) as memberCount
MATCH ()-[r:HAS_MODERATOR]->() WITH memberCount, count(r) as moderatorCount
MATCH ()-[r:CONTAINER_OF]->() WITH memberCount, moderatorCount, count(r) as containsCount
MATCH ()-[r:HAS_COMMENT]->() WITH memberCount, moderatorCount, containsCount, count(r) as commentRelCount
MATCH ()-[r:HAS_TAG]->() WITH memberCount, moderatorCount, containsCount, commentRelCount, count(r) as tagRelCount
MATCH ()-[r:LIKES]->() WITH memberCount, moderatorCount, containsCount, commentRelCount, tagRelCount, count(r) as likesCount
RETURN 
    'Memberships: ' + memberCount AS memberships,
    'Moderators: ' + moderatorCount AS moderators,
    'Contains: ' + containsCount AS contains,
    'Comment Rels: ' + commentRelCount AS commentRels,
    'Tag Rels: ' + tagRelCount AS tagRels,
    'Likes: ' + likesCount AS likes;