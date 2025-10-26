CALL {
  USE fabric.forums
  MERGE (authorProxy:PersonID {id: $authorPersonId})
  WITH authorProxy
  MATCH (place:Place {id: $countryId})
  OPTIONAL MATCH (replyToPost:Post {id: $replyToPostId})
  OPTIONAL MATCH (replyToComment:Comment {id: $replyToCommentId})
  WITH authorProxy, place, coalesce(replyToPost, replyToComment) AS message
  WHERE message IS NOT NULL
  CREATE (authorProxy)<-[:HAS_CREATOR]-(c:Comment {
      id: $commentId,
      creationDate: $creationDate,
      locationIP: $locationIP,
      browserUsed: $browserUsed,
      content: $content,
      length: $length
    })-[:REPLY_OF]->(message),
    (c)-[:IS_LOCATED_IN]->(place)
  WITH c
  UNWIND $tagIds AS tagId
    MATCH (t:Tag {id: tagId})
    CREATE (c)-[:HAS_TAG]->(t)
}
