# Neo4j LDBC Benchmarking with Fabric Sharding

This project implements a **sharded Neo4j Fabric deployment** for benchmarking the **LDBC Social Network Benchmark (SNB) Interactive v2** workload using **heterogeneous sharding strategies**.

## 🏗️ Architecture

- **Neo4j Fabric Coordinator**: Routes queries across shards
- **Persons Shard**: Contains Person nodes and their relationships
- **Forums Shard**: Contains Forum, Post, Comment nodes and PersonID proxy nodes
- **Cross-shard Relationships**: Implemented using PersonID proxy nodes and graph relationships

## 📋 Prerequisites

- Docker & Docker Compose
- At least 16GB RAM recommended
- LDBC SNB v2 SF1 dataset (see dataset setup below)

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/NwayOoKhine/Neo4j-LDBC-Benchmarking.git
cd Neo4j-LDBC-Benchmarking
```

### 2. Download LDBC SNB Dataset
Download the **LDBC SNB Interactive v2 SF1 dataset** and extract to:
- `ldbc_snb_interactive_v2_impls/ldbc-snb-sf1/`

**Dataset Structure Expected:**
```
ldbc_snb_interactive_v2_impls/
└── ldbc-snb-sf1/
    └── bi-sf1-composite-merged-fk/
        └── graphs/
            └── csv/
                └── bi/
                    └── composite-merged-fk/
                        └── initial_snapshot/
                            ├── dynamic/
                            └── static/
```

### 3. Start Neo4j Fabric Cluster
```bash
docker-compose up -d
```

**Containers:**
- `neo4j-fabric`: Coordinator (ports 7474, 7687)
- `neo4j-persons`: Persons shard (ports 7475, 7688)  
- `neo4j-forums`: Forums shard (ports 7476, 7689)

### 4. Load Data
Load the complete LDBC SNB SF1 dataset using the provided Cypher scripts:

```bash
# Load persons data
docker exec neo4j-persons cypher-shell -u neo4j -p password < scripts/load-persons-data.cypher

# Load forums data  
docker exec neo4j-forums cypher-shell -u neo4j -p password -d forums < scripts/load-forums-data.cypher
```

### 5. Run Benchmarks
```bash
cd ldbc_snb_interactive_v2_impls/cypher/driver
./benchmark.sh
```

## 📊 Dataset Overview

The loaded dataset includes:

**Persons Shard:**
- ~10K Person nodes
- ~16K Tag, TagClass nodes  
- ~3K Organisation, Place nodes
- Relationships: KNOWS, WORKS_AT, HAS_INTEREST, etc.

**Forums Shard:**
- ~100K Forum nodes
- ~1.1M Post nodes
- ~2.3M Comment nodes
- ~10K PersonID proxy nodes
- ~328K Forum-Tag relationships
- Relationships: HAS_CREATOR, CONTAINER_OF, HAS_TAG, etc.

## 🔧 Configuration

### Memory Configuration
The default configuration allocates:
- Fabric coordinator: 4GB
- Persons shard: 4GB  
- Forums shard: 6GB

Adjust in `docker-compose.yml` based on your system resources.

### Benchmark Configuration
Edit `ldbc_snb_interactive_v2_impls/cypher/driver/benchmark.properties` to:
- Set operation counts
- Enable/disable specific queries
- Configure result logging

## 🧪 Cross-Shard Queries

Example cross-shard query to find posts by a specific person:

```cypher
CALL { 
    USE fabric.persons 
    MATCH (p:Person {id: 14}) 
    RETURN p.id as personId, p.firstName as firstName 
} 
CALL { 
    USE fabric.forums 
    MATCH (pid:PersonID {id: 14})-[:HAS_CREATOR]-(post:Post) 
    RETURN post.id as postId, post.content as content 
} 
WITH personId, firstName, postId, content 
RETURN personId, firstName, postId, content;
```

## 📁 Project Structure

```
├── docker-compose.yml              # Neo4j Fabric cluster definition
├── ldbc_snb_interactive_v2_driver/ # LDBC benchmark driver
├── ldbc_snb_interactive_v2_impls/  # Database implementations
│   └── cypher/                     # Neo4j/Cypher implementation
├── scripts/                        # Data loading scripts
└── consistency_checks/             # Data consistency validation
```

## 🔍 Key Features

- **Heterogeneous Sharding**: Person vs Forum-centric shards
- **Cross-shard Relationships**: PersonID proxy nodes with graph relationships
- **Batch Loading**: Memory-efficient data loading for large datasets
- **Quarantine Recovery**: Database recovery mechanisms
- **Comprehensive Schema**: Full LDBC SNB v2 schema implementation

## 📈 Benchmarking Results

Results are saved to `ldbc_snb_interactive_v2_impls/cypher/results/` after running benchmarks.

## 🐛 Troubleshooting

### Database Quarantine Issues
If a database becomes quarantined:
```bash
docker exec neo4j-forums cypher-shell -u neo4j -p password -d system "CALL dbms.quarantineDatabase('forums', false);"
```

### Memory Issues
Increase memory limits in `docker-compose.yml` or use batch loading for large operations.

## 📜 License

This project uses the LDBC SNB benchmark suite and Neo4j Enterprise Edition for research purposes.

## 🤝 Contributing

This is a research project. For questions or collaboration, please open an issue.

---

**Note**: This implementation focuses on LDBC SNB Interactive v2 workload with Neo4j Fabric for graph database sharding research.