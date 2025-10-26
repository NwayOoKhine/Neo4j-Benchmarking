# Custom Benchmark Configurations

This directory contains custom LDBC SNB benchmark property files used in the thesis experiments.

## Files

### 1. `benchmark-pathA.properties`
**Experiment:** Path A - Read-Only Thread Sweep  
**Purpose:** Tests cross-shard and intra-shard read queries with increasing concurrency  
**Queries:** Q4, Q5, Q9, Q10, Q11  
**Thread Counts:** 1, 2, 4 (manual override)  
**Key Settings:**
- Q1 disabled (unstable query)
- All write operations disabled
- Schedule enforcement enabled

### 2. `benchmark-overhead-fabric.properties`
**Experiment:** Coordinator Overhead (via Fabric)  
**Purpose:** Measures Q11 latency when routing through Fabric coordinator  
**Queries:** Q11 only  
**Thread Count:** 4  
**Endpoint:** `bolt://localhost:7687` (Fabric coordinator)

### 3. `benchmark-overhead-direct.properties`
**Experiment:** Coordinator Overhead (direct to shard)  
**Purpose:** Measures Q11 latency when connecting directly to Persons shard  
**Queries:** Q11 only  
**Thread Count:** 4  
**Endpoint:** `bolt://localhost:7688` (Persons shard directly)  
**Query Directory:** `queries-direct/` (modified queries without USE fabric.* syntax)

### 4. `benchmark-mixed-deletes.properties`
**Experiment:** Mixed Workload with Deletes (Consistency Test)  
**Purpose:** Tests referential integrity violations with read/insert/delete operations  
**Queries:** Q4, Q10, Q11 (reads) + Insert1-8 + Delete1-5,8  
**Thread Count:** 1  
**Key Findings:** Detects dangling proxy nodes

### 5. `benchmark-mixed-cleanup.properties`
**Experiment:** Cleanup-Aware Deletes (Architectural Limitation Test)  
**Purpose:** Tests atomic cross-shard cleanup to prevent inconsistencies  
**Queries:** Q10, Q11 + Inserts + cleanup-aware DELETE1  
**Thread Count:** 1  
**Key Findings:** Crashes due to Fabric's "no cross-database writes" limitation

---

## Usage

These files are automatically copied to `ldbc_snb_interactive_v2_impls/cypher/driver/` during setup:

```bash
./setup_environment.sh
```

Or manually:

```bash
cp configs/*.properties ldbc_snb_interactive_v2_impls/cypher/driver/
```

---

## Common Configuration Settings

All benchmark configs include:
- **Endpoint:** `bolt://localhost:7687` (Fabric) or `bolt://localhost:7688` (direct)
- **Credentials:** `neo4j/password`
- **Database:** `fabric`
- **Encryption:** Disabled (`neo4j.encryption=false`)
- **Operation Count:** 5,000 (run phase)
- **Warmup Count:** 50
- **Time Compression Ratio:** 0.001
- **Connection Pool:** Max 50 connections, 60s timeout (for higher thread counts)

---

## Modification Notes

If you need to modify these configs:
1. Edit files in `configs/` directory (not in `ldbc_snb_interactive_v2_impls/`)
2. Re-run setup or manually copy: `cp configs/*.properties ldbc_snb_interactive_v2_impls/cypher/driver/`
3. Commit changes to git

**Important:** Do not modify files in `ldbc_snb_interactive_v2_impls/` directly as this directory is cloned fresh during setup and changes will be lost.

