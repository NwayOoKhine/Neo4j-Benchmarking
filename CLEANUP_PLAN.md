# Repository Cleanup Plan for Thesis Reproducibility

## Summary
This document identifies files to **KEEP** (essential for reproducibility) and **DELETE** (temporary/redundant).

---

## ✅ FILES TO KEEP

### 1. Configuration Files (Root)
- ✅ `docker-compose.yml` - Neo4j Fabric cluster setup
- ✅ `README.md` - Will be rewritten in Task 3

### 2. Benchmark Properties Files (ldbc_snb_interactive_v2_impls/cypher/driver/)
**Essential (Used in thesis experiments):**
- ✅ `benchmark-pathA.properties` - Read-only thread sweep (Experiment 1)
- ✅ `benchmark-overhead-fabric.properties` - Coordinator overhead via Fabric (Experiment 2)
- ✅ `benchmark-overhead-direct.properties` - Coordinator overhead direct (Experiment 2)
- ✅ `benchmark-mixed-deletes.properties` - Mixed workload with deletes (Experiment 3)
- ✅ `benchmark-mixed-cleanup.properties` - Cleanup-aware deletes (Experiment 4)

**To DELETE (redundant/unused):**
- ❌ `benchmark.properties` - Generic template
- ❌ `benchmark.properties.temp` - Temporary
- ❌ `benchmark-test.properties` - Test file
- ❌ `benchmark-pathB.properties` - Relaxed schedule experiment (not completed)
- ❌ `benchmark-mixed.properties` - Superseded by benchmark-mixed-deletes.properties

### 3. PowerShell/Python Scripts (scripts/)
**Essential:**
- ✅ `consistency_checks.ps1` - Pre/post benchmark consistency validation
- ✅ `extract_query_latencies.py` - Thesis data extraction
- ✅ `run_mixed_deletes.ps1` - Run mixed workload experiment
- ✅ `run_mixed_cleanup.ps1` - Run cleanup-aware experiment
- ✅ `backup-sharded-database.sh` - Database backup utility
- ✅ `restore-sharded-database.sh` - Database restore utility

**To DELETE (redundant/intermediate):**
- ❌ `run_benchmark.ps1` - Generic runner, superseded
- ❌ `run_mixed_with_consistency.ps1` - Superseded by run_mixed_deletes.ps1
- ❌ `run_pathA.ps1` - Can be replaced with direct java command
- ❌ `run_set_sharded.sh` - Old test script
- ❌ `compare_sharded_vs_baseline.ps1` - Analysis script, not needed for reproduction
- ❌ `generate_summary_metrics.ps1` - Analysis script, not needed for reproduction
- ❌ `parse_ldbc_results.ps1` - Superseded by extract_query_latencies.py
- ❌ `parse_neo4j_querylogs.ps1` - Analysis script
- ❌ `docker_stats_sampler.ps1` - Monitoring script, not essential
- ❌ `restart_cold.ps1` - Test utility
- ❌ `scripts/D/` directory - Appears to be accidental duplicate
- ❌ `.benchmark_temp_*.properties` files - Temporary benchmark configs
- ❌ `.tmp_results_*/` directories - Temporary result directories

### 4. Cypher Data Loading Files (Root & scripts/)
**Essential:**
- ✅ `load-persons-data-sf1-complete.cypher` - Final persons shard data loader
- ✅ `load-forums-data-sf1-complete.cypher` - Final forums shard data loader

**To DELETE (test/old versions):**
- ❌ `load-persons-data-sf1.cypher` - Superseded by -complete version
- ❌ `load-persons-data-sf1-test.cypher` - Test version
- ❌ `load-persons-data-v2.cypher` - Old version
- ❌ `load-forums-data-sf1.cypher` - Superseded by -complete version
- ❌ `load-forums-data-sf1-test.cypher` - Test version
- ❌ `load-forums-data-sf1-minimal.cypher` - Test version
- ❌ `load-forums-data-sf1-forums-only.cypher` - Partial loader
- ❌ `load-forums-data-v2.cypher` - Old version
- ❌ `load-posts-comments-fixed.cypher` - Old fix attempt
- ❌ `load-forum-members.cypher` - Partial loader
- ❌ `scripts/load-persons-data.cypher` - Duplicate
- ❌ `scripts/load-forums-data.cypher` - Duplicate

### 5. Cypher Query Files (ldbc_snb_interactive_v2_impls/cypher/queries/)
**Essential:**
- ✅ Keep all `interactive-complex-*.cypher` files (standard LDBC queries)
- ✅ Keep all `interactive-delete-*.cypher` files (delete operations)
- ✅ Keep all `interactive-insert-*.cypher` files (insert operations)
- ✅ Keep all `interactive-short-*.cypher` files (short reads)
- ✅ `interactive-complex-11-direct.cypher` - Direct-to-shard version for overhead experiment

**Note:** The `queries-direct/` directory should be kept if it contains modified queries for overhead experiment.

### 6. Results & Analysis (results/)
**Essential (Thesis data):**
- ✅ `THESIS_CONSISTENCY_ANALYSIS.md` - Consistency experiment analysis
- ✅ `THESIS_COORDINATOR_OVERHEAD_ANALYSIS.md` - Overhead experiment analysis
- ✅ `THESIS_COORDINATOR_OVERHEAD_TABLE.csv` - Overhead data table
- ✅ `THESIS_COORDINATOR_OVERHEAD_LATEX.txt` - LaTeX formatted results
- ✅ `THESIS_SUMMARY_TABLE.csv` - Overall summary
- ✅ `THESIS_LATEX_TABLE.txt` - LaTeX formatted summary
- ✅ `THESIS_QUERY_LATENCIES_SUMMARY.md` - Query latency analysis
- ✅ `query_latencies_for_boxplot.csv` - Extracted latency data
- ✅ `pathA_*_console.log` - Path A benchmark logs (1, 2, 4 threads)
- ✅ `overhead_fabric_console.log` - Overhead experiment log
- ✅ `overhead_direct_console.log` - Overhead experiment log
- ✅ `mixed_deletes_*_console.log` - Mixed workload logs (final run)
- ✅ `mixed_cleanup_*_console.log` - Cleanup experiment logs (final run)
- ✅ `LDBC-SNB-*-results.json` - Final LDBC result files
- ✅ `LDBC-SNB-*-results_log.csv` - Final LDBC logs
- ✅ `consistency_index.csv` - Consistency check index

**To DELETE (intermediate/old runs):**
- ❌ `results/sharded/raw/*` - Old test runs (keep only final documented runs)
- ❌ Multiple duplicate log files from early testing
- ❌ `manual_recording_template.csv` - Template, not needed

### 7. Temporary/Generated Files (Root)
**To DELETE:**
- ❌ `barplot.png` - Analysis output
- ❌ `benchmark_results.csv` - Intermediate results
- ❌ `inconsistency_log.csv` - Superseded by results in results/
- ❌ `temp_analysis/` - All temporary analysis files
- ❌ `temp_q10.txt` - Temporary
- ❌ `temp_q11.txt` - Temporary
- ❌ `logs/` - Can be regenerated

### 8. Submodules/Large Directories (DO NOT DELETE - Will be in .gitignore)
- ✅ `ldbc_snb_interactive_v2_driver/` - LDBC driver (will be cloned by setup script)
- ✅ `ldbc_snb_interactive_v2_impls/` - LDBC implementations (will be cloned by setup script)
- ✅ `backups/` - Database backups
- ✅ `ldbc_snb_interactive_v2_impls/ldbc-snb-sf1/` - Dataset (will be downloaded by setup script)

---

## 📝 SUMMARY

### Files to Keep: ~40-50 essential files
- 1 docker-compose.yml
- 5 benchmark properties files
- 6-7 essential scripts
- 2 data loading scripts
- All query files in queries/ directory
- ~10-15 key result/analysis files

### Files to Delete: ~100+ redundant files
- 5 redundant benchmark properties
- 10+ old/duplicate scripts
- 10+ old data loading scripts
- Temporary analysis files
- Old test run logs
- Duplicate files

---

## 🎯 RECOMMENDED FINAL STRUCTURE

```
neo4j-fabric-project/
├── docker-compose.yml
├── README.md
├── setup_environment.sh               [NEW - Task 2]
├── .gitignore                         [Updated]
│
├── ldbc_snb_interactive_v2_driver/    [Cloned by setup script]
├── ldbc_snb_interactive_v2_impls/     [Cloned by setup script]
│   └── cypher/
│       ├── driver/
│       │   ├── benchmark-pathA.properties
│       │   ├── benchmark-overhead-fabric.properties
│       │   ├── benchmark-overhead-direct.properties
│       │   ├── benchmark-mixed-deletes.properties
│       │   └── benchmark-mixed-cleanup.properties
│       └── queries/
│           ├── interactive-complex-*.cypher
│           ├── interactive-delete-*.cypher
│           ├── interactive-insert-*.cypher
│           └── interactive-complex-11-direct.cypher
│
├── scripts/
│   ├── consistency_checks.ps1
│   ├── extract_query_latencies.py
│   ├── run_mixed_deletes.ps1
│   ├── run_mixed_cleanup.ps1
│   ├── backup-sharded-database.sh
│   ├── restore-sharded-database.sh
│   ├── load-persons-data-sf1-complete.cypher
│   └── load-forums-data-sf1-complete.cypher
│
├── results/
│   ├── THESIS_CONSISTENCY_ANALYSIS.md
│   ├── THESIS_COORDINATOR_OVERHEAD_ANALYSIS.md
│   ├── THESIS_QUERY_LATENCIES_SUMMARY.md
│   ├── *.csv (key data files)
│   ├── *.log (final experiment logs)
│   └── *.json (LDBC results)
│
└── backups/                           [In .gitignore]
    ├── neo4j-data-forums-backup.tar.gz
    ├── neo4j-data-main-backup.tar.gz
    └── neo4j-data-persons-backup.tar.gz
```

---

## ⚠️ BEFORE PROCEEDING

**Question for user:** 
1. Did you complete an unsharded baseline benchmark? If so, where are those files?
2. Which exact SF1 dataset did you download? (Need URL for setup script)
3. Should I keep `pathA_8threads_console.log` even though it failed? (For documentation)
4. Any other specific result files you want to preserve?

