// Load Complete SF1 Persons Data 
// This script loads the full LDBC SNB SF1 persons data into the persons shard

// =============================================================================
// CONSTRAINTS
// =============================================================================
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT organisation_id IF NOT EXISTS FOR (o:Organisation) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT tagclass_id IF NOT EXISTS FOR (tc:TagClass) REQUIRE tc.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;

// =============================================================================
// STATIC DATA
// =============================================================================

// Load Places (all types - cities, countries, continents)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place/part-00000-a3bd38c5-4e4b-48a0-b2c3-f6e9a924b99a-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Place {
    id: toInteger(row.id),
    name: row.name,
    url: row.url,
    type: row.type
});

// Load Organizations (Companies and Universities)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Organisation/part-00000-a3d4936d-3ae8-443f-98f3-97b7c8b40c74-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Organisation {
    id: toInteger(row.id),
    type: row.type,
    name: row.name,
    url: row.url
});

// Load Tag Classes
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/TagClass/part-00000-4b03e81b-3ac7-478a-b77b-eded90c5d07e-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:TagClass {
    id: toInteger(row.id),
    name: row.name,
    url: row.url
});

// Load Tags (full tag set for person interests)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag/part-00000-166fdbfc-cb02-4c99-86e1-3397b1adc371-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Tag {
    id: toInteger(row.id),
    name: row.name,
    url: row.url
});

// =============================================================================
// DYNAMIC DATA - PERSONS
// =============================================================================

// Load Persons (main entity for persons shard)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
CREATE (:Person {
    id: toInteger(row.id),
    firstName: row.firstName,
    lastName: row.lastName,
    gender: row.gender,
    birthday: date(datetime({epochMillis: toInteger(row.birthday)})),
    creationDate: datetime({epochMillis: toInteger(row.creationDate)}),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed,
    speaks: split(replace(replace(row.speaks, '[', ''), ']', ''), ','),
    email: split(replace(replace(row.email, '[', ''), ']', ''), ',')
});

// =============================================================================
// STATIC RELATIONSHIPS
// =============================================================================

// Place isPartOf Place (hierarchical location structure)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place_isPartOf_Place/part-00000-a3bd38c5-4e4b-48a0-b2c3-f6e9a924b99a-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (child:Place {id: toInteger(row.`Place1.id`)})
MATCH (parent:Place {id: toInteger(row.`Place2.id`)})
CREATE (child)-[:IS_PART_OF]->(parent);

// Organisation isLocatedIn Place
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Organisation_isLocatedIn_Place/part-00000-a3d4936d-3ae8-443f-98f3-97b7c8b40c74-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (org:Organisation {id: toInteger(row.`Organisation.id`)})
MATCH (place:Place {id: toInteger(row.`Place.id`)})
CREATE (org)-[:IS_LOCATED_IN]->(place);

// TagClass isSubclassOf TagClass (hierarchical tag structure)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/TagClass_isSubclassOf_TagClass/part-00000-4b03e81b-3ac7-478a-b77b-eded90c5d07e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (child:TagClass {id: toInteger(row.`TagClass1.id`)})
MATCH (parent:TagClass {id: toInteger(row.`TagClass2.id`)})
CREATE (child)-[:IS_SUBCLASS_OF]->(parent);

// Tag hasType TagClass  
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag_hasType_TagClass/part-00000-166fdbfc-cb02-4c99-86e1-3397b1adc371-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (tag:Tag {id: toInteger(row.`Tag.id`)})
MATCH (tagClass:TagClass {id: toInteger(row.`TagClass.id`)})
CREATE (tag)-[:HAS_TYPE]->(tagClass);

// =============================================================================
// PERSON RELATIONSHIPS
// =============================================================================

// Person isLocatedIn Place (where person lives)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_isLocatedIn_Place/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (person:Person {id: toInteger(row.`Person.id`)})
MATCH (place:Place {id: toInteger(row.`Place.id`)})
CREATE (person)-[:IS_LOCATED_IN]->(place);

// Person workAt Organisation (employment history)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_workAt_Company/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (person:Person {id: toInteger(row.`Person.id`)})
MATCH (company:Organisation {id: toInteger(row.`Company.id`)})
CREATE (person)-[:WORKS_AT {workFrom: toInteger(row.workFrom)}]->(company);

// Person studyAt University (education history)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_studyAt_University/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (person:Person {id: toInteger(row.`Person.id`)})
MATCH (university:Organisation {id: toInteger(row.`University.id`)})
CREATE (person)-[:STUDY_AT {classYear: toInteger(row.classYear)}]->(university);

// Person knows Person (social network connections)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_knows_Person/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (person1:Person {id: toInteger(row.`Person1.id`)})
MATCH (person2:Person {id: toInteger(row.`Person2.id`)})
CREATE (person1)-[:KNOWS {creationDate: datetime({epochMillis: toInteger(row.creationDate)})}]->(person2);

// Person hasInterest Tag (interests and hobbies)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_hasInterest_Tag/part-00000-9b07c059-e67b-46d3-aee7-0fb51a9b2b4e-c000.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (person:Person {id: toInteger(row.`Person.id`)})
MATCH (tag:Tag {id: toInteger(row.`Tag.id`)})
CREATE (person)-[:HAS_INTEREST]->(tag);

// =============================================================================
// SUMMARY AND VERIFICATION
// =============================================================================

// Show summary of loaded data
MATCH (p:Person) WITH count(p) as personCount
MATCH (place:Place) WITH personCount, count(place) as placeCount
MATCH (org:Organisation) WITH personCount, placeCount, count(org) as orgCount
MATCH (tc:TagClass) WITH personCount, placeCount, orgCount, count(tc) as tagClassCount
MATCH (tag:Tag) WITH personCount, placeCount, orgCount, tagClassCount, count(tag) as tagCount
RETURN 
    'Persons: ' + personCount AS persons,
    'Places: ' + placeCount AS places,
    'Organizations: ' + orgCount AS organizations,
    'Tag Classes: ' + tagClassCount AS tagClasses,
    'Tags: ' + tagCount AS tags;

// Relationship summary
MATCH ()-[r:IS_LOCATED_IN]->() WITH count(r) as locationCount
MATCH ()-[r:WORKS_AT]->() WITH locationCount, count(r) as workCount
MATCH ()-[r:STUDY_AT]->() WITH locationCount, workCount, count(r) as studyCount
MATCH ()-[r:KNOWS]->() WITH locationCount, workCount, studyCount, count(r) as knowsCount
MATCH ()-[r:HAS_INTEREST]->() WITH locationCount, workCount, studyCount, knowsCount, count(r) as interestCount
MATCH ()-[r:IS_PART_OF]->() WITH locationCount, workCount, studyCount, knowsCount, interestCount, count(r) as partOfCount
RETURN 
    'Located In: ' + locationCount AS locations,
    'Works At: ' + workCount AS works,
    'Study At: ' + studyCount AS studies,
    'Knows: ' + knowsCount AS knows,
    'Interests: ' + interestCount AS interests,
    'Part Of: ' + partOfCount AS partOf;