// Load SF1 data into Persons Shard - TEST VERSION
// Start with basic entities only

// Constraints
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT organisation_id IF NOT EXISTS FOR (o:Organisation) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT tagclass_id IF NOT EXISTS FOR (t:TagClass) REQUIRE t.id IS UNIQUE;

// Static data - Using exact file names
// Places
LOAD CSV WITH HEADERS FROM 'file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place/part-00000-ee123d60-fc7e-463c-a6cb-0a6ef4cfa2b6-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Place {id: toInteger(row.id), name: row.name, url: row.url, type: row.type});

// Organisations
LOAD CSV WITH HEADERS FROM 'file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Organisation/part-00000-ae05c232-68e5-4c3e-9d0b-c95290cb4921-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Organisation {id: toInteger(row.id), type: row.type, name: row.name, url: row.url});

// Tags
LOAD CSV WITH HEADERS FROM 'file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag/part-00000-166fdbfc-cb02-4c99-86e1-3397b1adc371-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Tag {id: toInteger(row.id), name: row.name, url: row.url});

// TagClasses
LOAD CSV WITH HEADERS FROM 'file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/TagClass/part-00000-c38e6689-0343-4235-b2eb-0d07b53db5f9-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:TagClass {id: toInteger(row.id), name: row.name, url: row.url});

// Dynamic data - Persons only (Load all part files)
LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person/part-00000-6119ed75-e2e6-4689-bfff-7b8cac94eb89-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Person {
    id: toInteger(row.id),
    firstName: row.firstName,
    lastName: row.lastName,
    gender: row.gender,
    birthday: datetime(replace(row.birthday, ' ', 'T')),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed
});

LOAD CSV WITH HEADERS FROM "file:///bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person/part-00001-6119ed75-e2e6-4689-bfff-7b8cac94eb89-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Person {
    id: toInteger(row.id),
    firstName: row.firstName,
    lastName: row.lastName,
    gender: row.gender,
    birthday: datetime(replace(row.birthday, ' ', 'T')),
    creationDate: datetime(replace(row.creationDate, ' ', 'T')),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed
}); 