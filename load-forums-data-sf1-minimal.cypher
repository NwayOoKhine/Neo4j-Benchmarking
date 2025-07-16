// Minimal Forums Data Loading Script for Consistency Tests
// This script creates a small amount of test data to enable cross-shard transactions
// without overwhelming the 2GB heap limit.

// Create a few test Forum nodes
CREATE (f1:Forum {
  id: 'test-forum-001',
  title: 'Test Forum 1 for Consistency Tests',
  creationDate: datetime('2023-01-01T10:00:00Z')
});

CREATE (f2:Forum {
  id: 'test-forum-002', 
  title: 'Test Forum 2 for Consistency Tests',
  creationDate: datetime('2023-01-02T10:00:00Z')
});

CREATE (f3:Forum {
  id: 'test-forum-003',
  title: 'Test Forum 3 for Consistency Tests', 
  creationDate: datetime('2023-01-03T10:00:00Z')
});

// Create a few test Place nodes (Countries) that Forums can be located in
CREATE (p1:Place {
  id: 'test-country-001',
  name: 'Test Country 1',
  type: 'country'
});

CREATE (p2:Place {
  id: 'test-country-002', 
  name: 'Test Country 2',
  type: 'country'
});

// Create relationships between Forums and Places
MATCH (f:Forum {id: 'test-forum-001'}), (p:Place {id: 'test-country-001'})
CREATE (f)-[:IS_LOCATED_IN]->(p);

MATCH (f:Forum {id: 'test-forum-002'}), (p:Place {id: 'test-country-002'})
CREATE (f)-[:IS_LOCATED_IN]->(p);

MATCH (f:Forum {id: 'test-forum-003'}), (p:Place {id: 'test-country-001'})
CREATE (f)-[:IS_LOCATED_IN]->(p);

// Create a few test Tag nodes for Posts to reference
CREATE (t1:Tag {
  id: 'test-tag-001',
  name: 'test-tag-1'
});

CREATE (t2:Tag {
  id: 'test-tag-002',
  name: 'test-tag-2'
});

CREATE (t3:Tag {
  id: 'test-tag-003', 
  name: 'test-tag-3'
});

// Display summary of what was created
MATCH (f:Forum) RETURN 'Forums created: ' + count(f) AS summary
UNION ALL
MATCH (p:Place) RETURN 'Places created: ' + count(p) AS summary  
UNION ALL
MATCH (t:Tag) RETURN 'Tags created: ' + count(t) AS summary; 