# QUERY LATENCY DATA FOR THESIS - INDIVIDUAL QUERY MEASUREMENTS

## DATA SOURCES

This document compiles query latency data from all your Path A benchmark runs. Note that these are **summary statistics** from the warmup phases (50 operations each), not raw individual observations. For true boxplots, you would need raw query logs.

---

## 1. PATH A - THREAD SWEEP (WARMUP PHASE)

### 1.1 Thread Count = 1

| Query | Count | Mean (ms) |
|-------|-------|-----------|
| Q4 | 9 | 86.11 |
| Q5 | 6 | 33.83 |
| Q9 | 2 | 29.00 |
| Q10 | 11 | 309.82 |
| Q11 | 22 | 36.82 |

**Observations:**
- Q10 (cross-shard) has the highest mean latency at 309.82 ms
- Q11 (intra-shard) is much faster at 36.82 ms
- Q9 has very few samples (only 2) due to the schedule

### 1.2 Thread Count = 2

| Query | Count | Mean (ms) |
|-------|-------|-----------|
| Q4 | 9 | 110.11 |
| Q5 | 6 | 34.00 |
| Q9 | 2 | 28.00 |
| Q10 | 11 | 337.00 |
| Q11 | 22 | 41.59 |

**Observations:**
- Q10 latency increased by 8.8% (309.82 → 337.00 ms)
- Q11 latency increased by 12.9% (36.82 → 41.59 ms)
- Q4 latency increased by 27.9% (86.11 → 110.11 ms)

###1.3 Thread Count = 4

| Query | Count | Mean (ms) |
|-------|-------|-----------|
| Q4 | 9 | 176.00 |
| Q5 | 6 | 35.67 |
| Q9 | 2 | 31.00 |
| Q10 | 11 | 300.09 |
| Q11 | 22 | 49.32 |

**Observations:**
- Q10 latency **decreased** slightly (-3.2%) despite higher concurrency
- Q11 latency increased by 33.9% (36.82 → 49.32 ms) compared to 1 thread
- Q4 latency increased by 104.4% (86.11 → 176.00 ms) compared to 1 thread
- **Run crashed** after warmup phase due to Q9 data type error

---

## 2. COORDINATOR OVERHEAD EXPERIMENT (Q11 ONLY)

### 2.1 Via Fabric Coordinator

| Metric | Value |
|--------|-------|
| Count | 500 |
| Mean | 11.98 ms |
| P50 | 9.00 ms |
| P95 | 37.00 ms |

### 2.2 Direct to Shard (No Coordinator)

| Metric | Value |
|--------|-------|
| Count | 500 |
| Mean | 6.73 ms |
| P50 | 6.00 ms |
| P95 | 9.00 ms |

### 2.3 Coordinator Tax Analysis

| Metric | Fabric | Direct | Overhead (%) |
|--------|--------|--------|--------------|
| Mean | 11.98 ms | 6.73 ms | **+78.0%** |
| P50 | 9.00 ms | 6.00 ms | **+50.0%** |
| P95 | 37.00 ms | 9.00 ms | **+311.1%** |

**Key Finding:** Fabric coordinator introduces significant latency overhead (78% mean, 311% P95) for intra-shard queries.

---

## 3. MIXED WORKLOAD WITH DELETES (1 THREAD)

### 3.1 Read Queries

| Query | Count | Mean (ms) | P50 (ms) | P95 (ms) |
|-------|-------|-----------|----------|----------|
| Q4 | 296 | 45.29 | 19.00 | 214.00 |
| Q10 | 355 | 139.46 | 12.00 | 1257.00 |
| Q11 | 667 | 15.84 | 12.00 | 40.00 |

**Observations:**
- Q10 has highly variable latency (P50=12ms, P95=1257ms) - 100x variance
- Q11 is consistently fast (P50=12ms, P95=40ms)
- Q4 has moderate variability

### 3.2 Write Queries (Inserts)

| Operation | Count | Mean (ms) | P50 (ms) | P95 (ms) |
|-----------|-------|-----------|----------|----------|
| Insert1 (AddPerson) | 2 | 324.00 | 24.00 | 624.00 |
| Insert2 (AddPostLike) | 359 | 19.98 | 18.00 | 34.00 |
| Insert3 (AddCommentLike) | 20 | 28.05 | 20.00 | 61.00 |
| Insert4 (AddForum) | 42 | 23.31 | 20.00 | 50.00 |
| Insert5 (AddForumMembership) | 2027 | 17.75 | 15.00 | 32.00 |
| Insert6 (AddPost) | 77 | 24.56 | 23.00 | 55.00 |
| Insert7 (AddComment) | 882 | 25.41 | 22.00 | 48.00 |
| Insert8 (AddFriendship) | 195 | 17.01 | 16.00 | 31.00 |

**Observations:**
- Insert5 (AddForumMembership) is the most frequent operation (2027 ops)
- Most inserts are fast (15-25 ms mean)
- Insert1 has very low sample count (only 2)

### 3.3 Write Queries (Deletes)

| Operation | Count | Mean (ms) | P50 (ms) | P95 (ms) |
|-----------|-------|-----------|----------|----------|
| Delete1 (RemovePerson) | 1 | 151.00 | 151.00 | 151.00 |
| Delete2 (RemovePostLike) | 14 | 94.50 | 58.00 | 535.00 |
| Delete3 (RemoveCommentLike) | 47 | 64.06 | 49.00 | 123.00 |
| Delete4 (RemoveForum) | 3 | 286.00 | 125.00 | 648.00 |
| Delete5 (RemoveForumMembership) | 1 | 124.00 | 124.00 | 124.00 |
| Delete8 (RemoveFriendship) | 11 | 94.36 | 52.00 | 338.00 |

**Observations:**
- Delete operations are generally slower than inserts (50-150 ms vs 15-25 ms)
- Delete4 (RemoveForum) is the slowest (286 ms mean)
- Very low sample counts for Delete1 and Delete5 (only 1 each)

---

## 4. DATA COMPLETENESS NOTES

### Available Data:
- ✅ **Path A (1, 2, 4 threads):** Mean latencies only (from warmup phase)
- ✅ **Coordinator Overhead:** Full percentiles (Mean, P50, P90, P95, P99)
- ✅ **Mixed Workload with Deletes:** Full percentiles for all operations

### Missing Data:
- ❌ **Path A Run Phase:** 4-thread run crashed, 1 & 2-thread run data not fully logged
- ❌ **Path A (8 threads):** Connection pool exhaustion prevented completion
- ❌ **Individual query observations:** Would need to parse raw query logs from Neo4j

### Recommendation for Boxplots:
Since you only have summary statistics (percentiles), true boxplots aren't possible. Instead, consider:
1. **Bar charts** with error bars showing P50 and P95
2. **Violin plots** approximated from percentile data
3. **Latency distribution tables** showing the percentile breakdown

---

## 5. QUICK REFERENCE - KEY FINDINGS

| Finding | Value | Queries |
|---------|-------|---------|
| Fastest query | 6.73 ms (mean) | Q11 direct to shard |
| Slowest query | 337 ms (mean) | Q10 at 2 threads |
| Coordinator overhead | +78% (mean) | Q11 via Fabric |
| Max P95 latency | 1257 ms | Q10 in mixed workload |
| Most frequent operation | 2027 ops | Insert5 (AddForumMembership) |
| Slowest delete | 286 ms (mean) | Delete4 (RemoveForum) |

---

## 6. CSV FILE LOCATION

The extracted data has been saved to:
```
results/query_latencies_for_boxplot.csv
```

This CSV contains:
- Benchmark name
- Query name
- Operation count
- Mean latency (ms)
- Min, Max, P50, P90, P95, P99 percentiles (where available)

---

**Note:** This data represents the actual performance measurements from your LDBC benchmarks on Neo4j Fabric SF1 dataset. All times are in milliseconds.

