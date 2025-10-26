// Q10. Friend recommendation
/*
:params { personId: 4398046511333, month: 5 }
*/
CALL {
    USE fabric.persons
    MATCH (person:Person {id: $personId})-[:KNOWS*2..2]-(friend),
           (friend)-[:IS_LOCATED_IN]->(city:Place {type: 'City'})
    WHERE NOT friend = person AND
          NOT (friend)-[:KNOWS]-(person)
    WITH person, city, friend, date(friend.birthday) AS birthday
    WHERE (birthday.month = $month AND birthday.day >= 21) OR
          (birthday.month = ($month%12)+1 AND birthday.day < 22)
    WITH DISTINCT friend, city, person
    RETURN friend.id AS friendId,
           friend.firstName AS firstName,
           friend.lastName AS lastName,
           friend.gender AS gender,
           city.name AS cityName,
           person.id AS startPersonId
}
CALL {
    WITH friendId, startPersonId
    USE fabric.forums
    OPTIONAL MATCH (friendProxy:PersonID {id: friendId})<-[:HAS_CREATOR]-(post:Post)
    WITH friendProxy, collect(post) AS posts, startPersonId
    OPTIONAL MATCH (startProxy:PersonID {id: startPersonId})-[:HAS_INTEREST]->(tag:Tag)<-[:HAS_TAG]-(commonPost:Post)
    WHERE commonPost IN posts
    RETURN size(posts) AS postCount,
           count(DISTINCT commonPost) AS commonPostCount
}
WITH friendId AS personId,
     firstName AS personFirstName,
     lastName AS personLastName,
     gender AS personGender,
     cityName AS personCityName,
     commonPostCount - (postCount - commonPostCount) AS commonInterestScore
RETURN personId,
       personFirstName,
       personLastName,
       commonInterestScore,
       personGender,
       personCityName
ORDER BY commonInterestScore DESC, personId ASC
LIMIT 10
