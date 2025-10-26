# Custom Query Files

This directory contains **23 modified LDBC SNB query files** used in the thesis experiments.

## Summary

| Category | Files | Purpose |
|----------|-------|---------|
| **Read Queries** | Q4, Q5, Q9, Q10, Q11 | Thesis benchmark queries |
| **Direct-Access** | Q11-direct | Coordinator overhead experiment |
| **Delete Operations** | Delete 1-8 | Mixed workload with consistency tests |
| **Insert/Update Operations** | Update 1-8 | Mixed workload operations |

**Total: 23 query files**

---

## 1. Modified Read Queries (5 files)

### `interactive-complex-4.cypher` - Person's Content
**Modifications:** Configured for Fabric sharding  
**Shard:** Intra-shard (Persons only)

### `interactive-complex-5.cypher` - New Groups
**Modifications:** Cross-shard optimization  
**Shards:** Persons + Forums

### `interactive-complex-9.cypher` - Recent Messages
**Modifications:** Configured for Fabric  
**Shard:** Intra-shard (Persons only)  
**Note:** Has data type issues causing crashes at >2 threads

### `interactive-complex-10.cypher` - Friend Recommendations
**Modifications:** Cross-shard query optimization  
**Shards:** Persons + Forums  
**Performance:** 8-10× slower than intra-shard queries

### `interactive-complex-11.cypher` - Job Offers
**Modifications:** Configured for Fabric  
**Shard:** Intra-shard (Persons only)

---

## 2. Direct-Access Queries (2 files)

### `interactive-complex-10-direct.cypher`
**Purpose:** Q10 for direct shard access (overhead experiment)  
**Modifications:** 
- Removed `USE fabric.persons` and `USE fabric.forums` clauses
- Note: Cannot be used for cross-shard query via direct connection
- Primarily for comparison purposes

### `interactive-complex-11-direct.cypher`
**Purpose:** Q11 for direct shard access (overhead experiment)  
**Modifications:**
- Removed `USE fabric.persons` clause
- Executes directly on Persons shard

**Experiment Results:**
| Metric | Via Fabric | Direct | Overhead |
|--------|------------|--------|----------|
| Mean | 27.36 ms | 6.73 ms | **+306%** |
| P95 | 37 ms | 9 ms | **+311%** |

---

## 3. Delete Operations (8 files)

### `interactive-delete-1.cypher` - Remove Person
**Modifications:** 
- **Version 1 (Buggy):** Only deletes Person, leaves proxy (inconsistency demo)
- **Version 2 (Cleanup-Aware - ACTIVE):** Attempts cross-shard cleanup
- **Result:** Crashes due to Fabric's "no cross-database writes" limitation

### `interactive-delete-2.cypher` - Remove Post Like
**Modifications:** Configured for Fabric Forums shard

### `interactive-delete-3.cypher` - Remove Comment Like
**Modifications:** Configured for Fabric Forums shard

### `interactive-delete-4.cypher` - Remove Forum
**Modifications:** Configured for Fabric Forums shard

### `interactive-delete-5.cypher` - Remove Forum Membership
**Modifications:** Configured for Fabric Forums shard

### `interactive-delete-6.cypher` - Remove Post Thread
**Modifications:** Configured for Fabric Forums shard  
**Note:** Disabled in experiments due to deadlock issues

### `interactive-delete-7.cypher` - Remove Comment Subthread
**Modifications:** Configured for Fabric Forums shard  
**Note:** Disabled in experiments due to deadlock issues

### `interactive-delete-8.cypher` - Remove Friendship
**Modifications:** Configured for Fabric Persons shard

**Consistency Impact:**
- Buggy deletes → **5 dangling proxies detected**
- Cleanup-aware deletes → **Fabric architectural limitation discovered**

---

## 4. Insert/Update Operations (8 files)

### `interactive-update-1.cypher` - Add Person
**Modifications:** Cross-shard insert (Persons + Forums proxy creation)

### `interactive-update-2.cypher` - Add Post Like
**Modifications:** Forums shard insert

### `interactive-update-3.cypher` - Add Comment Like
**Modifications:** Forums shard insert

### `interactive-update-4.cypher` - Add Forum
**Modifications:** Forums shard insert

### `interactive-update-5.cypher` - Add Forum Membership
**Modifications:** Forums shard insert  
**Note:** Most frequent operation (2027 ops in mixed workload)

### `interactive-update-6.cypher` - Add Post
**Modifications:** Forums shard insert

### `interactive-update-7.cypher` - Add Comment
**Modifications:** Forums shard insert

### `interactive-update-8.cypher` - Add Friendship
**Modifications:** Persons shard insert

---

## Usage

These files are automatically copied during setup:

```bash
./setup_environment.sh
```

**Setup script does:**
1. Copies 21 queries to `ldbc_snb_interactive_v2_impls/cypher/queries/`
   - Q4, Q5, Q9, Q10, Q11
   - Delete 1-8
   - Update 1-8
   
2. Copies 2 queries to `ldbc_snb_interactive_v2_impls/cypher/queries-direct/`
   - Q10-direct
   - Q11-direct

---

## Key Modification Patterns

### 1. Fabric Routing Syntax
```cypher
CALL {
  USE fabric.persons    // Route to Persons shard
  MATCH (p:Person)...
}
CALL {
  USE fabric.forums     // Route to Forums shard
  MATCH (f:Forum)...
}
```

### 2. Cross-Shard Coordination
Queries that access both shards use separate `CALL { USE fabric.* }` blocks and merge results at coordinator level.

### 3. Direct-Access Queries
Remove all `USE fabric.*` clauses to enable direct shard connection.

---

## Thesis Experiments Using These Queries

### Experiment 1: Path A (Read-Only)
**Queries:** Q4, Q5, Q9, Q10, Q11  
**Files:** interactive-complex-{4,5,9,10,11}.cypher

### Experiment 2: Coordinator Overhead
**Queries:** Q11 (via Fabric vs. direct)  
**Files:** interactive-complex-11.cypher, interactive-complex-11-direct.cypher

### Experiment 3: Mixed Workload with Deletes
**Queries:** Q4, Q10, Q11 + All inserts + Deletes 1-5,8  
**Files:** All interactive-delete-*.cypher, interactive-update-*.cypher

### Experiment 4: Cleanup-Aware Deletes
**Queries:** Q10, Q11 + Inserts + cleanup-aware Delete 1  
**Files:** interactive-delete-1.cypher (Version 2)

---

## Important Notes

1. **Do NOT modify queries in `ldbc_snb_interactive_v2_impls/cypher/queries/`**  
   That directory is cloned fresh during setup. All changes will be lost.

2. **Modify queries in `custom-queries/` directory instead**  
   Changes here are version-controlled and automatically applied during setup.

3. **To add new modified queries:**
   ```bash
   # Edit in custom-queries/
   nano custom-queries/interactive-complex-XX.cypher
   
   # Re-run setup (or manually copy)
   ./setup_environment.sh
   
   # Commit to git
   git add custom-queries/
   git commit -m "Update query XX"
   ```

---

## Maintenance

**Last updated:** October 2025  
**Total modified queries:** 23
