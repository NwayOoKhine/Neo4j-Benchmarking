#!/bin/bash

################################################################################
# Cleanup Redundant Files
# This script removes temporary, duplicate, and unused files from the repository
################################################################################

set -e

echo "========================================================================"
echo "Repository Cleanup - Removing Redundant Files"
echo "========================================================================"
echo ""

FILES_DELETED=0

# Function to safely delete file/directory
safe_delete() {
    if [ -e "$1" ]; then
        rm -rf "$1"
        echo "✓ Deleted: $1"
        FILES_DELETED=$((FILES_DELETED + 1))
    else
        echo "  (already gone): $1"
    fi
}

echo "=== Cleaning Benchmark Properties Files ==="
safe_delete "ldbc_snb_interactive_v2_impls/cypher/driver/benchmark.properties"
safe_delete "ldbc_snb_interactive_v2_impls/cypher/driver/benchmark.properties.temp"
safe_delete "ldbc_snb_interactive_v2_impls/cypher/driver/benchmark-test.properties"
safe_delete "ldbc_snb_interactive_v2_impls/cypher/driver/benchmark-pathB.properties"
safe_delete "ldbc_snb_interactive_v2_impls/cypher/driver/benchmark-mixed.properties"
echo ""

echo "=== Cleaning Redundant Scripts ==="
safe_delete "scripts/run_benchmark.ps1"
safe_delete "scripts/run_mixed_with_consistency.ps1"
safe_delete "scripts/run_pathA.ps1"
safe_delete "scripts/run_set_sharded.sh"
safe_delete "scripts/compare_sharded_vs_baseline.ps1"
safe_delete "scripts/generate_summary_metrics.ps1"
safe_delete "scripts/parse_ldbc_results.ps1"
safe_delete "scripts/parse_neo4j_querylogs.ps1"
safe_delete "scripts/docker_stats_sampler.ps1"
safe_delete "scripts/restart_cold.ps1"
safe_delete "scripts/D"
echo ""

echo "=== Cleaning Temporary Benchmark Files ==="
safe_delete "scripts/.benchmark_temp_20251004_002405_sanity_check_fabric_read_1t_warm.properties"
safe_delete "scripts/.benchmark_temp_20251004_002425_sanity_check_fabric_read_1t_warm.properties"
safe_delete "scripts/.benchmark_temp_20251004_002459_sanity_test_fabric_read_1t_warm.properties"
safe_delete "scripts/.benchmark_temp_20251004_004238_test_1thread_read_fabric_read_1t_warm.properties"
safe_delete "scripts/.benchmark_temp_20251004_004314_test_1t_fabric_read_1t_warm.properties"
safe_delete "scripts/.benchmark_temp_20251004_004401_complex_test_1t_fabric_read_1t_warm.properties"
safe_delete "scripts/.tmp_results_20251004_002405_sanity_check_fabric_read_1t_warm"
safe_delete "scripts/.tmp_results_20251004_002425_sanity_check_fabric_read_1t_warm"
safe_delete "scripts/.tmp_results_20251004_002459_sanity_test_fabric_read_1t_warm"
safe_delete "scripts/.tmp_results_20251004_004238_test_1thread_read_fabric_read_1t_warm"
safe_delete "scripts/.tmp_results_20251004_004314_test_1t_fabric_read_1t_warm"
safe_delete "scripts/.tmp_results_20251004_004401_complex_test_1t_fabric_read_1t_warm"
echo ""

echo "=== Cleaning Old/Duplicate Data Loading Scripts ==="
safe_delete "load-persons-data-sf1.cypher"
safe_delete "load-persons-data-sf1-test.cypher"
safe_delete "load-persons-data-v2.cypher"
safe_delete "load-forums-data-sf1.cypher"
safe_delete "load-forums-data-sf1-test.cypher"
safe_delete "load-forums-data-sf1-minimal.cypher"
safe_delete "load-forums-data-sf1-forums-only.cypher"
safe_delete "load-forums-data-v2.cypher"
safe_delete "load-posts-comments-fixed.cypher"
safe_delete "load-forum-members.cypher"
safe_delete "scripts/load-persons-data.cypher"
safe_delete "scripts/load-forums-data.cypher"
echo ""

echo "=== Moving Essential Loading Scripts to scripts/ ==="
if [ -f "load-persons-data-sf1-complete.cypher" ]; then
    mv load-persons-data-sf1-complete.cypher scripts/
    echo "✓ Moved: load-persons-data-sf1-complete.cypher → scripts/"
fi
if [ -f "load-forums-data-sf1-complete.cypher" ]; then
    mv load-forums-data-sf1-complete.cypher scripts/
    echo "✓ Moved: load-forums-data-sf1-complete.cypher → scripts/"
fi
echo ""

echo "=== Cleaning Temporary Analysis Files ==="
safe_delete "barplot.png"
safe_delete "benchmark_results.csv"
safe_delete "inconsistency_log.csv"
safe_delete "temp_analysis"
safe_delete "temp_q10.txt"
safe_delete "temp_q11.txt"
safe_delete "logs"
echo ""

echo "=== Cleaning Old Test Result Directories ==="
safe_delete "results/sharded/raw"
safe_delete "results/logs"
echo ""

echo "========================================================================"
echo "Cleanup Complete!"
echo "========================================================================"
echo "Files/directories deleted: $FILES_DELETED"
echo ""
echo "Essential files preserved:"
echo "  - 5 benchmark properties files (pathA, overhead-fabric, overhead-direct, mixed-deletes, mixed-cleanup)"
echo "  - 2 data loading scripts (in scripts/ directory)"
echo "  - 6 essential automation scripts"
echo "  - All thesis result files and analysis documents"
echo "  - All LDBC query files"
echo ""
echo "Next steps:"
echo "  1. Review remaining files: ls -R"
echo "  2. Run setup script: ./setup_environment.sh"
echo "  3. Start benchmarking: Follow README.md instructions"
echo ""
echo "========================================================================"

