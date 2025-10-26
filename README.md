# Neo4j Fabric Sharding Benchmark - Thesis Reproducibility Package

## 📚 Project Overview

This repository contains the complete benchmarking implementation for evaluating **Neo4j Fabric's sharded graph database architecture** using the LDBC Social Network Benchmark (SNB) Interactive Workload. This work is part of a thesis investigating:

- **Performance characteristics** of Neo4j Fabric with cross-shard queries
- **Coordinator overhead** introduced by the Fabric layer
- **Consistency issues** arising from distributed write operations
- **Concurrency limitations** in sharded configurations

### Key Findings
- Cross-shard queries (Q10) show 8-10× higher latency than intra-shard queries (Q11)
- Fabric coordinator introduces **latency overhead**
- System experiences connection pool exhaustion at **6-8 concurrent threads**
- Delete operations create **referential integrity violations** (dangling proxy nodes)
- Fabric's architectural constraint: **no cross-database writes in single transaction**

---

## 🔧 Prerequisites

Before running this benchmark, ensure you have the following installed:

### Required Software
- **Docker** (v20.10+) and **Docker Compose** (v2.0+)
- **Java** (JDK 11 or higher)
- **Maven** (3.6+)
- **Git**
- **wget** or **curl** (for dataset download)
- **tar** with **zstd** support (`apt-get install zstd` on Ubuntu/Debian)
- **PowerShell Core** (7.0+) - for Windows-based automation scripts

### System Requirements
- **RAM:** 16 GB minimum (32 GB recommended)
- **Disk Space:** ~20 GB free (dataset + Neo4j data + build artifacts)
- **CPU:** 4+ cores recommended for concurrent benchmarks

### Verify Prerequisites
```bash
# Check Java
java -version

# Check Maven
mvn -version

# Check Docker
docker --version
docker-compose --version

# Check zstd support
tar --help | grep zstd

# Check PowerShell (if on Windows)
pwsh --version
```

---

## 🚀 Setup Instructions

### Step 1: Clone This Repository
```bash
git clone https://github.com/NwayOoKhine/Neo4j-Benchmarking.git
cd Neo4j-Benchmarking
```

### Step 2: Run Environment Setup Script

This script will automatically:
- Clone the LDBC SNB Interactive v2 Driver
- Clone the LDBC SNB Interactive v2 Implementations (Cypher)
- Download the LDBC SNB SF1 dataset (~2-3 GB)
- Extract the dataset
- Build the LDBC driver and Cypher implementation
- **Apply custom benchmark configurations** (5 benchmark property files)
- **Apply modified queries** (23 query files for thesis experiments)

```bash
chmod +x setup_environment.sh
./setup_environment.sh
```

**Note:** The download is approximately 2-3 GB and extraction may take 5-10 additional minutes. Please be patient.

**Custom Configurations:** The setup script automatically copies your modified benchmark configs and query files from `configs/` and `custom-queries/` directories. This ensures complete reproducibility with all thesis modifications.

### Step 3: Start Neo4j Fabric Cluster

```bash
# Start all 3 Neo4j instances (Fabric coordinator + 2 shards)
docker-compose up -d

# Verify all containers are running
docker ps

# Expected output: 3 containers
#   - neo4j-fabric (coordinator, port 7687)
#   - neo4j-persons (persons shard, port 7688)
#   - neo4j-forums (forums shard, port 7689)
```

Wait ~30 seconds for all instances to fully start, then verify:
```bash
# Check Fabric coordinator
docker logs neo4j-fabric | grep "Started"

# Check Persons shard
docker logs neo4j-persons | grep "Started"

# Check Forums shard
docker logs neo4j-forums | grep "Started"
```

### Step 4: Load Data into Shards

**Load Persons Shard:**
```bash
docker cp scripts/load-persons-data-sf1-complete.cypher neo4j-persons:/var/lib/neo4j/import/
docker exec neo4j-persons cypher-shell -u neo4j -p password -f /var/lib/neo4j/import/load-persons-data-sf1-complete.cypher --format verbose
```

**Load Forums Shard:**
```bash
docker cp scripts/load-forums-data-sf1-complete.cypher neo4j-forums:/var/lib/neo4j/import/
docker exec neo4j-forums cypher-shell -u neo4j -p password -f /var/lib/neo4j/import/load-forums-data-sf1-complete.cypher --format verbose
```

**Loading time:** ~30-60 minutes per shard depending on hardware.

**Verify Data Loaded:**
```bash
# Check Persons shard
docker exec neo4j-persons cypher-shell -u neo4j -p password \
  "MATCH (p:Person) RETURN count(p) AS personCount"
# Expected: ~10,925 persons

# Check Forums shard  
docker exec neo4j-forums cypher-shell -u neo4j -p password \
  "MATCH (f:Forum) RETURN count(f) AS forumCount"
# Expected: ~100,830 forums
```

---

## 📊 Running Benchmarks

### Experiment 1: Path A - Read-Only Thread Sweep

Tests read-only performance with increasing concurrency (1, 2, 4 threads).

**Queries:** Q4, Q5, Q9, Q10, Q11  
**Thread Counts:** 1, 2, 4  
**Duration:** ~2-5 minutes per run  

```bash
cd ldbc_snb_interactive_v2_impls/cypher

# 1 Thread
java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-pathA.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/ \
  -p thread_count=1

# 2 Threads
java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-pathA.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/ \
  -p thread_count=2

# 4 Threads
java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-pathA.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/ \
  -p thread_count=4
```

**Note:** The 4-thread run may crash due to Q9 data type issues (documented in thesis).

---

### Experiment 2: Coordinator Overhead (Q11 Only)

Compares Q11 performance via Fabric coordinator vs. direct shard access.

**Duration:** ~2 minutes per run

**2a) Via Fabric Coordinator:**
```bash
cd ldbc_snb_interactive_v2_impls/cypher

java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-overhead-fabric.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/
```

**2b) Direct to Persons Shard:**
```bash
cd ldbc_snb_interactive_v2_impls/cypher

java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-overhead-direct.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/
```

**Expected Result:** Fabric adds latency

---

### Experiment 3: Mixed Workload with Deletes (Consistency Test)

Tests referential integrity violations with concurrent read/insert/delete operations.

**Duration:** ~5-10 minutes  
**Queries:** Q4, Q10, Q11 (reads) + Insert1-8 + Delete1-5,8

```bash
# Windows PowerShell
cd scripts
pwsh -File run_mixed_deletes.ps1

# Linux/Mac (adapt PowerShell script or run manually)
cd ../ldbc_snb_interactive_v2_impls/cypher
java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-mixed-deletes.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/
```

**Expected Result:** Detects dangling proxy nodes (referential integrity violations).

---

### Experiment 4: Cleanup-Aware Deletes (Architectural Limitation Test)

Tests atomic cross-shard cleanup to prevent inconsistencies.

**Duration:** ~2 minutes (will crash due to Fabric limitation)

```bash
# Windows PowerShell
cd scripts
pwsh -File run_mixed_cleanup.ps1

# Linux/Mac (adapt PowerShell script or run manually)
cd ../ldbc_snb_interactive_v2_impls/cypher
java -cp target/cypher-implementation.jar:../../ldbc_snb_interactive_v2_driver/target/driver.jar \
  org.ldbcouncil.snb.driver.Client \
  -P driver/benchmark-mixed-cleanup.properties \
  -p ldbc.snb.interactive.parameters_dir=../../ldbc_snb_interactive_v2_driver/substitution_parameters/ \
  -p ldbc.snb.interactive.updates_dir=../../ldbc_snb_interactive_v2_impls/update-streams/
```

**Expected Result:** Benchmark crashes with error: `"Writing to more than one database per transaction is not allowed"`

---

## 📁 Repository Structure

```
neo4j-fabric-project/
├── docker-compose.yml                    # Neo4j Fabric 3-node cluster config
├── setup_environment.sh                  # Automated environment setup script
├── README.md                             # This file
│
├── configs/                              # Custom benchmark configurations (tracked in git)
│   ├── README.md                         # Documentation for each config file
│   ├── benchmark-pathA.properties        # Experiment 1: Read-only thread sweep
│   ├── benchmark-overhead-fabric.properties  # Experiment 2a: Via Fabric coordinator
│   ├── benchmark-overhead-direct.properties  # Experiment 2b: Direct to shard
│   ├── benchmark-mixed-deletes.properties    # Experiment 3: Mixed with deletes
│   └── benchmark-mixed-cleanup.properties    # Experiment 4: Cleanup-aware deletes
│
├── custom-queries/                       # Modified LDBC queries (tracked in git)
│   ├── README.md                         # Documentation for all modifications
│   ├── interactive-complex-{4,5,9,10,11}.cypher      # 5 modified read queries
│   ├── interactive-complex-{10,11}-direct.cypher     # 2 direct-access queries
│   ├── interactive-delete-{1-8}.cypher               # 8 modified delete operations
│   └── interactive-update-{1-8}.cypher               # 8 modified insert operations
│
├── ldbc_snb_interactive_v2_driver/       # LDBC driver (cloned by setup script)
├── ldbc_snb_interactive_v2_impls/        # LDBC implementations (cloned by setup script)
│   └── cypher/
│       ├── driver/                       # Benchmark configs copied from configs/
│       └── queries/                      # Modified queries copied from custom-queries/
│
├── scripts/
│   ├── load-persons-data-sf1-complete.cypher          # Persons shard data loader
│   ├── load-forums-data-sf1-complete.cypher           # Forums shard data loader
│   ├── consistency_checks.ps1                         # Pre/post consistency validation
│   ├── run_mixed_deletes.ps1                          # Experiment 3 automation
│   ├── run_mixed_cleanup.ps1                          # Experiment 4 automation
│   ├── extract_query_latencies.py                     # Result data extraction
│   ├── backup-sharded-database.sh                     # Database backup utility
│   └── restore-sharded-database.sh                    # Database restore utility
│
└── results/
    ├── THESIS_CONSISTENCY_ANALYSIS.md                 # Experiment 3 analysis
    ├── THESIS_COORDINATOR_OVERHEAD_ANALYSIS.md        # Experiment 2 analysis
    ├── THESIS_QUERY_LATENCIES_SUMMARY.md              # Complete latency data
    ├── query_latencies_for_boxplot.csv                # Extracted metrics (CSV)
    ├── *.json                                         # LDBC result files
    └── *.log                                          # Benchmark console logs
```

**Note:** The `configs/` and `custom-queries/` directories contain all thesis-specific modifications and are tracked in git. During setup, these files are automatically copied to the appropriate locations in the cloned LDBC repositories, ensuring complete reproducibility.

---

## 📈 Extracting Results

After running benchmarks, extract metrics using the Python script:

```bash
cd scripts
python extract_query_latencies.py
```

This generates:
- `results/query_latencies_for_boxplot.csv` - Summary statistics for all queries
- Console output with mean, P50, P95 latencies

---

## 🔄 Database Backup & Restore

**Backup (after data loading):**
```bash
# Stop containers
docker-compose down

# Run backup script
./scripts/backup-sharded-database.sh

# Restart containers
docker-compose up -d
```

**Restore:**
```bash
# Stop containers
docker-compose down

# Run restore script
./scripts/restore-sharded-database.sh

# Restart containers
docker-compose up -d
```

Backups are stored in `backups/` directory:
- `neo4j-data-main-backup.tar.gz` (Fabric coordinator)
- `neo4j-data-persons-backup.tar.gz` (Persons shard)
- `neo4j-data-forums-backup.tar.gz` (Forums shard)

---

## 🐛 Troubleshooting

### Issue: `Unable to establish connection in 30000ms`
**Cause:** Connection pool exhaustion at high thread counts  
**Solution:** This is a documented limitation. Use thread_count ≤ 4 or increase pool settings in properties files

### Issue: `Cannot coerce DATE_TIME to Java long` (Q9)
**Cause:** Data type mismatch in Q9 query implementation  
**Solution:** This is a known bug documented in thesis. Disable Q9 or run with 1-2 threads only

### Issue: Docker containers won't start
**Cause:** Insufficient memory or port conflicts  
**Solution:** 
```bash
# Check Docker resources
docker system df

# Free up space
docker system prune -a

# Check port availability
netstat -tuln | grep -E '7687|7688|7689'
```

### Issue: Data loading fails
**Cause:** Missing dataset files or incorrect paths  
**Solution:**
```bash
# Verify dataset exists
ls -lh ldbc_snb_interactive_v2_impls/ldbc-snb-sf1/

# Re-run setup if needed
./setup_environment.sh
```

---

## 📧 Contact

For questions about this implementation, please contact:
- **GitHub:** [@NwayOoKhine](https://github.com/NwayOoKhine)
- **Repository:** https://github.com/NwayOoKhine/Neo4j-Benchmarking

---

## 📄 License

The LDBC SNB benchmark framework is used under its respective license.

---

## 🙏 Acknowledgments

- **LDBC Council** for the SNB benchmark specification and reference implementations
- **Neo4j** for the Fabric distributed graph database architecture
- Thesis supervisors and reviewers for guidance

---

**Last Updated:** October 2025
