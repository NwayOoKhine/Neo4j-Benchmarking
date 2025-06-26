// Create a new file 'load-persons-data-v2.cypher'

// Constraints
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT place_id IF NOT EXISTS FOR (p:Place) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT organisation_id IF NOT EXISTS FOR (o:Organisation) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT tag_id IF NOT EXISTS FOR (t:Tag) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT tagclass_id IF NOT EXISTS FOR (t:TagClass) REQUIRE t.id IS UNIQUE;

// Static data
// Places
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/place_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Place {id: toInteger(row.id), name: row.name, url: row.url, type: row.type});

// Part of Place
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/place_isPartOf_place_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p1:Place {id: toInteger(row.`Place.id`)})
MATCH (p2:Place {id: toInteger(row.`Place.id_2`)})
CREATE (p1)-[:IS_PART_OF]->(p2);

// Organisations
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/organisation_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Organisation {id: toInteger(row.id), type: row.type, name: row.name, url: row.url});

// Organisation located in Place
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/organisation_isLocatedIn_place_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
MATCH (p:Place {id: toInteger(row.`Place.id`)})
CREATE (o)-[:IS_LOCATED_IN]->(p);

// TagClasses
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tagclass_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:TagClass {id: toInteger(row.id), name: row.name, url: row.url});

// TagClass is subclass of TagClass
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tagclass_isSubclassOf_tagclass_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (tc1:TagClass {id: toInteger(row.`TagClass.id`)})
MATCH (tc2:TagClass {id: toInteger(row.`TagClass.id_2`)})
CREATE (tc1)-[:IS_SUBCLASS_OF]->(tc2);

// Tags
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tag_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Tag {id: toInteger(row.id), name: row.name, url: row.url});

// Tag has type TagClass
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tag_hasType_tagclass_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
MATCH (tc:TagClass {id: toInteger(row.`TagClass.id`)})
CREATE (t)-[:HAS_TYPE]->(tc);


// Dynamic data
// Persons
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_0_0.csv" AS row FIELDTERMINATOR '|'
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

// Person located in Place
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_isLocatedIn_place_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (pe:Person {id: toInteger(row.`Person.id`)})
MATCH (pl:Place {id: toInteger(row.`Place.id`)})
CREATE (pe)-[:IS_LOCATED_IN]->(pl);

// Person speaks language
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_speaks_language_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MERGE (l:Language {name: row.language})
CREATE (p)-[:SPEAKS]->(l);

// Person email
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_email_emailaddress_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MERGE (e:Email {address: row.emailaddress})
CREATE (p)-[:HAS_EMAIL]->(e);

// Person study at Organisation
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_studyAt_organisation_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
CREATE (p)-[:STUDY_AT {classYear: toInteger(row.classYear)}]->(o);

// Person work at Organisation
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_workAt_organisation_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
CREATE (p)-[:WORK_AT {workFrom: toInteger(row.workFrom)}]->(o);

// Person has interest in Tag
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_hasInterest_tag_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (t:Tag {id: toInteger(row.`Tag.id`)})
CREATE (p)-[:HAS_INTEREST]->(t);

// Person knows Person
LOAD CSV WITH HEADERS FROM "file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_knows_person_0_0.csv" AS row FIELDTERMINATOR '|'
MATCH (p1:Person {id: toInteger(row.`Person.id`)})
MATCH (p2:Person {id: toInteger(row.`Person.id_2`)})
CREATE (p1)-[:KNOWS {creationDate: datetime(replace(row.creationDate, ' ', 'T'))}]->(p2); 