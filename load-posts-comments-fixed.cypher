// Load Only Posts and Comments (Fixed file paths)
// This script adds Posts and Comments to the existing forums data

// =============================================================================
// CONSTRAINTS (if not already created)
// =============================================================================
CREATE CONSTRAINT post_id IF NOT EXISTS FOR (p:Post) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT comment_id IF NOT EXISTS FOR (c:Comment) REQUIRE c.id IS UNIQUE;

// =============================================================================
// POSTS (Main Content)
// =============================================================================

// Load Posts - Part 1 (largest file ~23MB)
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00003-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

// Show progress
MATCH (p:Post) RETURN 'Posts loaded so far: ' + count(p) AS progress;

// Load Posts - Part 2  
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00008-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

// Show Posts total
MATCH (p:Post) RETURN 'Total Posts loaded: ' + count(p) AS posts_summary;

// =============================================================================
// COMMENTS (Replies to Posts and Comments)
// =============================================================================

// Load Comments - Part 1 (largest file ~61MB)
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment/part-00011-01afcac0-af10-4b69-8981-adf26d17579e-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

// Show progress
MATCH (c:Comment) RETURN 'Comments loaded so far: ' + count(c) AS progress;

// Load Comments - Part 2
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Comment/part-00022-01afcac0-af10-4b69-8981-adf26d17579e-c000.csv.gz" AS row FIELDTERMINATOR '|'
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
// RELATIONSHIPS - Connect Posts to Forums
// =============================================================================

// Connect Posts to their containing Forums
MATCH (p:Post), (f:Forum)
WHERE p.containerForumId = f.id
CREATE (f)-[:CONTAINER_OF]->(p);

// Show progress
MATCH ()-[r:CONTAINER_OF]->() RETURN 'Post-Forum relationships: ' + count(r) AS post_forum_rels;

// =============================================================================
// RELATIONSHIPS - Comments to Posts/Comments  
// =============================================================================

// Connect Comments to their parent Posts
MATCH (c:Comment), (p:Post)
WHERE c.parentPostId = p.id
CREATE (p)-[:HAS_COMMENT]->(c);

// Connect Comments to their parent Comments (nested comments)
MATCH (c1:Comment), (c2:Comment)
WHERE c1.parentCommentId = c2.id
CREATE (c2)-[:HAS_COMMENT]->(c1);

// =============================================================================
// FINAL SUMMARY
// =============================================================================

// Show final summary
MATCH (f:Forum) WITH count(f) as forumCount
MATCH (p:Post) WITH forumCount, count(p) as postCount  
MATCH (c:Comment) WITH forumCount, postCount, count(c) as commentCount
RETURN 
    'Forums: ' + forumCount AS forums,
    'Posts: ' + postCount AS posts,
    'Comments: ' + commentCount AS comments;

// Relationship summary
MATCH ()-[r:CONTAINER_OF]->() WITH count(r) as containsCount
MATCH ()-[r:HAS_COMMENT]->() WITH containsCount, count(r) as commentRelCount
RETURN 
    'Post-Forum relationships: ' + containsCount AS post_forum_rels,
    'Comment relationships: ' + commentRelCount AS comment_rels;