// Load SF1 data into Forums Shard - TEST VERSION
// Basic entities only

// Constraints for Forum-related entities
CREATE CONSTRAINT forum_id IF NOT EXISTS FOR (f:Forum) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT post_id IF NOT EXISTS FOR (p:Post) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT comment_id IF NOT EXISTS FOR (c:Comment) REQUIRE c.id IS UNIQUE;

// Forums (Load both part files)
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum/part-00000-4a9657d7-88ea-41ad-bf22-f134eca8c497-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Forum/part-00001-4a9657d7-88ea-41ad-bf22-f134eca8c497-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Forum {
    id: toInteger(row.id),
    title: row.title,
    creationDate: datetime(replace(row.creationDate, ' ', 'T'))
});

// Posts (Load the larger part files)
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00003-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Post/part-00008-65ef8cff-d384-4fd1-aa20-eb48ba0dd532-c000.csv.gz" AS row FIELDTERMINATOR '|'
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