// Q11. Job referral
/*
:params {
  personId: 10995116277918,
  countryName: "Hungary",
  workFromYear: 2011
}
*/
CALL {
    USE fabric.persons
    MATCH (person:Person {id: $personId})-[:KNOWS*1..2]-(friend:Person)
    WHERE not(person=friend)
    WITH DISTINCT friend
    MATCH (friend)-[workAt:WORKS_AT]->(org:Organisation)-[:IS_LOCATED_IN]->(country:Place {name: $countryName, type: 'Country'})
    WHERE workAt.workFrom < $workFromYear
    RETURN
        friend.id AS personId,
        friend.firstName AS personFirstName,
        friend.lastName AS personLastName,
        org.name AS organizationName,
        workAt.workFrom AS organizationWorkFromYear
    ORDER BY
        organizationWorkFromYear ASC,
        toInteger(personId) ASC,
        organizationName DESC
    LIMIT 10
}
RETURN
    personId,
    personFirstName,
    personLastName,
    organizationName,
    organizationWorkFromYear
ORDER BY
    organizationWorkFromYear ASC,
    toInteger(personId) ASC,
    organizationName DESC
