CALL {
  USE fabric.forums
  MERGE (authorProxy:PersonID {id: $authorPersonId})
  WITH authorProxy
  MATCH (place:Place {id: $countryId})
  MATCH (forum:Forum {id: $forumId})
  CREATE (authorProxy)<-[:HAS_CREATOR]-(p:Post {
      id: $postId,
      creationDate: $creationDate,
      locationIP: $locationIP,
      browserUsed: $browserUsed,
      language: $language,
      content: CASE $content WHEN '' THEN NULL ELSE $content END,
      imageFile: CASE $imageFile WHEN '' THEN NULL ELSE $imageFile END,
      length: $length
    })-[:CONTAINER_FORUM]->(forum), (p)-[:IS_LOCATED_IN]->(place)
  WITH p
  UNWIND $tagIds AS tagId
    MATCH (t:Tag {id: tagId})
    CREATE (p)-[:HAS_TAG]->(t)
}
