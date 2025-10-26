#!/bin/bash

################################################################################
# Neo4j Fabric Sharding - Environment Setup Script
# 
# This script downloads and sets up the LDBC SNB benchmark environment including:
# - LDBC SNB Interactive v2 Driver
# - LDBC SNB Interactive v2 Implementations (Cypher)
# - LDBC SNB SF1 Dataset (~2-3 GB)
#
# Prerequisites:
# - wget (for downloading)
# - tar with zstd support (for extracting .tar.zst files)
# - Java 11+ (for building LDBC drivers)
# - Maven 3.6+ (for building LDBC drivers)
################################################################################

set -e  # Exit on any error

echo "========================================================================"
echo "Neo4j Fabric Sharding - Environment Setup"
echo "========================================================================"
echo ""

# Configuration
DATASET_URL="https://pub-383410a98aef4cb686f0c7601eddd25f.r2.dev/bi-sf1-composite-merged-fk.tar.zst"
DATASET_FILE="bi-sf1-composite-merged-fk.tar.zst"
DATASET_DIR="ldbc-snb-sf1"
DRIVER_REPO="https://github.com/ldbc/ldbc_snb_interactive_v2_driver.git"
IMPLS_REPO="https://github.com/ldbc/ldbc_snb_interactive_v2_impls.git"

# Check prerequisites
echo "Checking prerequisites..."
echo ""

command -v wget >/dev/null 2>&1 || { echo "ERROR: wget is required but not installed. Aborting." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "ERROR: tar is required but not installed. Aborting." >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "ERROR: Java is required but not installed. Aborting." >&2; exit 1; }
command -v mvn >/dev/null 2>&1 || { echo "ERROR: Maven is required but not installed. Aborting." >&2; exit 1; }

# Check zstd support
if ! tar --help | grep -q "zstd"; then
    echo "ERROR: tar with zstd support is required. Please install zstd." >&2
    exit 1
fi

echo "✓ All prerequisites found"
echo ""

################################################################################
# Step 1: Clone LDBC SNB Interactive v2 Driver
################################################################################

echo "========================================================================"
echo "Step 1: Cloning LDBC SNB Interactive v2 Driver"
echo "========================================================================"
echo ""

if [ -d "ldbc_snb_interactive_v2_driver" ]; then
    echo "Directory 'ldbc_snb_interactive_v2_driver' already exists. Skipping clone."
else
    echo "Cloning driver from: $DRIVER_REPO"
    git clone $DRIVER_REPO
    echo "✓ Driver cloned successfully"
fi
echo ""

################################################################################
# Step 2: Clone LDBC SNB Interactive v2 Implementations
################################################################################

echo "========================================================================"
echo "Step 2: Cloning LDBC SNB Interactive v2 Implementations (Cypher)"
echo "========================================================================"
echo ""

if [ -d "ldbc_snb_interactive_v2_impls" ]; then
    echo "Directory 'ldbc_snb_interactive_v2_impls' already exists. Skipping clone."
else
    echo "Cloning implementations from: $IMPLS_REPO"
    git clone $IMPLS_REPO
    echo "✓ Implementations cloned successfully"
fi
echo ""

################################################################################
# Step 3: Download LDBC SNB SF1 Dataset
################################################################################

echo "========================================================================"
echo "Step 3: Downloading LDBC SNB SF1 Dataset (~2-3 GB)"
echo "========================================================================"
echo ""

if [ -d "$DATASET_DIR" ]; then
    echo "Dataset directory '$DATASET_DIR' already exists. Skipping download."
elif [ -f "$DATASET_FILE" ]; then
    echo "Dataset file '$DATASET_FILE' already downloaded. Skipping download."
else
    echo "Downloading dataset from SURF repository..."
    echo "URL: $DATASET_URL"
    echo "This may take 10-30 minutes depending on your connection speed."
    echo ""
    wget --progress=bar:force:noscroll "$DATASET_URL"
    echo ""
    echo "✓ Dataset downloaded successfully"
fi
echo ""

################################################################################
# Step 4: Extract Dataset
################################################################################

echo "========================================================================"
echo "Step 4: Extracting Dataset"
echo "========================================================================"
echo ""

if [ -d "$DATASET_DIR" ]; then
    echo "Dataset already extracted in '$DATASET_DIR'. Skipping extraction."
else
    echo "Extracting $DATASET_FILE..."
    echo "This may take 5-10 minutes..."
    echo ""
    
    # Extract to temporary directory first
    tar -xv --use-compress-program=unzstd -f "$DATASET_FILE"
    
    # Move to expected location
    mkdir -p ldbc_snb_interactive_v2_impls
    mv bi-sf1-composite-merged-fk ldbc_snb_interactive_v2_impls/ldbc-snb-sf1/
    
    echo ""
    echo "✓ Dataset extracted successfully"
fi
echo ""

################################################################################
# Step 5: Build LDBC Driver
################################################################################

echo "========================================================================"
echo "Step 5: Building LDBC SNB Driver"
echo "========================================================================"
echo ""

cd ldbc_snb_interactive_v2_driver
echo "Building driver with Maven (skipping tests)..."
mvn clean package -DskipTests
cd ..

echo "✓ Driver built successfully"
echo ""

################################################################################
# Step 6: Build Cypher Implementation
################################################################################

echo "========================================================================"
echo "Step 6: Building Cypher Implementation"
echo "========================================================================"
echo ""

cd ldbc_snb_interactive_v2_impls/cypher
echo "Building Cypher implementation with Maven (skipping tests)..."
mvn clean package -DskipTests
cd ../..

echo "✓ Cypher implementation built successfully"
echo ""

################################################################################
# Step 7: Apply Custom Configurations
################################################################################

echo "========================================================================"
echo "Step 7: Applying Custom Benchmark Configurations"
echo "========================================================================"
echo ""

echo "Copying custom benchmark properties..."
cp -v configs/*.properties ldbc_snb_interactive_v2_impls/cypher/driver/

echo ""
echo "Copying modified queries to main queries directory..."
# Copy all modified queries (Q4, Q5, Q9, Q10, Q11, all deletes, all updates)
cp -v custom-queries/interactive-complex-4.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-complex-5.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-complex-9.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-complex-10.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-complex-11.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-delete-*.cypher ldbc_snb_interactive_v2_impls/cypher/queries/
cp -v custom-queries/interactive-update-*.cypher ldbc_snb_interactive_v2_impls/cypher/queries/

echo ""
echo "Creating queries-direct directory and copying direct-access queries..."
mkdir -p ldbc_snb_interactive_v2_impls/cypher/queries-direct
cp -v custom-queries/interactive-complex-10-direct.cypher ldbc_snb_interactive_v2_impls/cypher/queries-direct/
cp -v custom-queries/interactive-complex-11-direct.cypher ldbc_snb_interactive_v2_impls/cypher/queries-direct/

echo ""
echo "✓ Custom configurations applied successfully"
echo ""

################################################################################
# Completion
################################################################################

echo "========================================================================"
echo "Setup Complete!"
echo "========================================================================"
echo ""
echo "Environment is ready for benchmarking."
echo ""
echo "Next steps:"
echo "  1. Start Neo4j Fabric cluster: docker-compose up -d"
echo "  2. Load data into shards (see README.md for commands)"
echo "  3. Run benchmarks (see README.md for benchmark scripts)"
echo ""
echo "Dataset location: ldbc_snb_interactive_v2_impls/ldbc-snb-sf1/"
echo "Driver JAR: ldbc_snb_interactive_v2_driver/target/driver.jar"
echo "Cypher JAR: ldbc_snb_interactive_v2_impls/cypher/target/cypher-implementation.jar"
echo ""
echo "Custom configurations:"
echo "  - 5 benchmark property files copied to driver/"
echo "  - 23 modified query files copied to queries/"
echo "  - 2 direct-access queries copied to queries-direct/"
echo ""
echo "========================================================================"

