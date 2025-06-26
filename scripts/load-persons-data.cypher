// Create constraints for the persons database
CREATE CONSTRAINT ON (p:Person) ASSERT p.id IS UNIQUE;
CREATE CONSTRAINT ON (p:Place) ASSERT p.id IS UNIQUE;
CREATE CONSTRAINT ON (o:Organisation) ASSERT o.id IS UNIQUE;
CREATE CONSTRAINT ON (t:TagClass) ASSERT t.id IS UNIQUE;

// Load static data for the persons graph

// Places
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/place_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Place {
    id: toInteger(row.id),
    name: row.name,
    url: row.url,
    type: row.type
});

// Organisations
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/organisation_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Organisation {
    id: toInteger(row.id),
    type: row.type,
    name: row.name,
    url: row.url
});

// Tag Classes
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/static/tagclass_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:TagClass {
    id: toInteger(row.id),
    name: row.name,
    url: row.url
});


// Load dynamic data for the persons graph

// Persons
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_0_0.csv' AS row FIELDTERMINATOR '|'
CREATE (:Person {
    id: toInteger(row.id),
    firstName: row.firstName,
    lastName: row.lastName,
    gender: row.gender,
    birthday: date(datetime({epochMillis: toInteger(row.birthday)})),
    creationDate: datetime({epochMillis: toInteger(row.creationDate)}),
    locationIP: row.locationIP,
    browserUsed: row.browserUsed
});

// Relationships

// Person is located in Place
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_isLocatedIn_place_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (pl:Place {id: toInteger(row.`Place.id`)})
CREATE (p)-[:IS_LOCATED_IN]->(pl);

// Person works at Company
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_workAt_organisation_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
CREATE (p)-[:WORKS_AT {workFrom: toInteger(row.workFrom)}]->(o);

// Person studies at University
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_studyAt_organisation_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p:Person {id: toInteger(row.`Person.id`)})
MATCH (o:Organisation {id: toInteger(row.`Organisation.id`)})
CREATE (p)-[:STUDY_AT {classYear: toInteger(row.classYear)}]->(o);

// Person knows Person
LOAD CSV WITH HEADERS FROM 'file:///social_network-csv_basic-longdateformatter-sf0.1/dynamic/person_knows_person_0_0.csv' AS row FIELDTERMINATOR '|'
MATCH (p1:Person {id: toInteger(row.`Person1.id`)})
MATCH (p2:Person {id: toInteger(row.`Person2.id`)})
CREATE (p1)-[:KNOWS {creationDate: datetime({epochMillis: toInteger(row.creationDate)})}]->(p2); 