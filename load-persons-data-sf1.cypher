// Load SF1 data into Persons Shard
// Handles directory-based compressed CSV structure

// Constraints
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT organisation_id IF NOT EXISTS FOR (o:Organisation) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT tagclass_id IF NOT EXISTS FOR (t:TagClass) REQUIRE t.id IS UNIQUE;

// Static data
// Places
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place/part-00000-ee123d60-fc7e-463c-a6cb-0a6ef4cfa2b6-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Place {id: toInteger(row.id), name: row.name, url: row.url, type: row.type});

// Part of Place  
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Place_isPartOf_Place/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
MATCH (p1:Place {id: toInteger(row.`Place.id`)})
MATCH (p2:Place {id: toInteger(row.`Place.id.1`)})
CREATE (p1)-[:IS_PART_OF]->(p2);

// Organisations
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Organisation/part-00000-ae05c232-68e5-4c3e-9d0b-c95290cb4921-c000.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Organisation {id: toInteger(row.id), type: row.type, name: row.name, url: row.url});

// Organisation located in Place
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Organisation_isLocatedIn_Place/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
MATCH (p:Place {id: toInteger(row.`Place.id`)})
CREATE (o)-[:IS_LOCATED_IN]->(p);

// TagClasses
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/TagClass/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:TagClass {id: toInteger(row.id), name: row.name, url: row.url});

// TagClass is subclass of TagClass
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/TagClass_isSubclassOf_TagClass/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
MATCH (tc1:TagClass {id: toInteger(row.`TagClass.id`)})
MATCH (tc2:TagClass {id: toInteger(row.`TagClass.id.1`)})
CREATE (tc1)-[:IS_SUBCLASS_OF]->(tc2);

// Tags
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
CREATE (:Tag {id: toInteger(row.id), name: row.name, url: row.url});

// Tag has type TagClass
LOAD CSV WITH HEADERS FROM 'file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/static/Tag_hasType_TagClass/part-00000-*.csv.gz' AS row FIELDTERMINATOR '|'
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
MATCH (tc:TagClass {id: toInteger(row.`TagClass.id`)})
CREATE (t)-[:HAS_TYPE]->(tc);

// Dynamic data
// Persons (Load all part files)
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person/part-00000-6119ed75-e2e6-4689-bfff-7b8cac94eb89-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person/part-00001-6119ed75-e2e6-4689-bfff-7b8cac94eb89-c000.csv.gz" AS row FIELDTERMINATOR '|'
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

// Person relationships (load all relationship files)
// Person located in Place
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_isLocatedIn_City/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (pe:Person {id: toInteger(row.`Person.id`)})
MATCH (pl:Place {id: toInteger(row.`City.id`)})
CREATE (pe)-[:IS_LOCATED_IN]->(pl);

// Person has interest in Tag
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_hasInterest_Tag/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (p)-[:HAS_INTEREST]->(t);

// Person knows Person
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_knows_Person/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p1:Person {id: toInteger(row.`Person.id`)})
MATCH (p2:Person {id: toInteger(row.`Person.id.1`)})
CREATE (p1)-[:KNOWS {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(p2);

// Person study at University
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_studyAt_University/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`University.id`)})
CREATE (p)-[:STUDY_AT {classYear: toInteger(row.classYear)}]->(o);

// Person work at Company
LOAD CSV WITH HEADERS FROM "file:///ldbc-snb-sf1/bi-sf1-composite-merged-fk/graphs/csv/bi/composite-merged-fk/initial_snapshot/dynamic/Person_workAt_Company/part-00000-*.csv.gz" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`Company.id`)})
CREATE (p)-[:WORK_AT {workFrom: toInteger(row.workFrom)}]->(o); 