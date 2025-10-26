# Mixed Read/Write Benchmark WITH CLEANUP-AWARE DELETES
# Purpose: Verify that fixed DELETE operations do NOT create consistency issues
# Expected: ZERO dangling proxies after completion

$ErrorActionPreference = "Stop"
$REPO_ROOT = "D:\Honours\Thesis\neo4j-fabric-project"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "  MIXED BENCHMARK WITH CLEANUP-AWARE DELETES" -ForegroundColor Cyan
Write-Host "=============================================================`n" -ForegroundColor Cyan

# PHASE 1: PRE-BENCHMARK CONSISTENCY CHECK
Write-Host "`n[PHASE 1/4] Pre-Benchmark Consistency Check" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

& "$REPO_ROOT\scripts\consistency_checks.ps1" -Tag "pre_cleanup_${TIMESTAMP}"
$pre_result = $LASTEXITCODE
if ($pre_result -ne 0) {
    Write-Host "WARNING: Pre-check found existing issues (Exit $pre_result)" -ForegroundColor Yellow
}

# PHASE 2: CLEAR LOGS
Write-Host "`n[PHASE 2/4] Preparing Benchmark Environment" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  * Clearing Neo4j query logs..."

docker exec neo4j-fabric sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>$null
docker exec neo4j-persons sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>$null
docker exec neo4j-forums sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>$null

Write-Host "  [OK] Logs cleared"

# PHASE 3: RUN BENCHMARK
Write-Host "`n[PHASE 3/4] Running Mixed Benchmark (CLEANUP-AWARE DELETES)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Configuration:"
Write-Host "    - Thread Count: 1"
Write-Host "    - Operations: 5000"
Write-Host "    - Workload: Reads + Inserts + CLEANUP-AWARE DELETES"
Write-Host "    - Expected: ZERO consistency violations!"
Write-Host ""
Write-Host "  Starting benchmark..."

$console_log = "$REPO_ROOT\results\mixed_cleanup_${TIMESTAMP}_console.log"

java -Xms2g -Xmx4g `
  -cp "$REPO_ROOT\ldbc_snb_interactive_v2_driver\target\driver-standalone.jar;$REPO_ROOT\ldbc_snb_interactive_v2_impls\cypher\target\cypher-2.0.0-SNAPSHOT.jar" `
  org.ldbcouncil.snb.driver.Client `
  -P "$REPO_ROOT\ldbc_snb_interactive_v2_impls\cypher\driver\benchmark-mixed-cleanup.properties" `
  | Tee-Object -FilePath $console_log

$bench_result = $LASTEXITCODE

if ($bench_result -ne 0) {
    Write-Host "`nWARNING: Benchmark exited with code $bench_result" -ForegroundColor Yellow
    Write-Host "This may be due to late operations (expected behavior)" -ForegroundColor DarkGray
} else {
    Write-Host "`nSUCCESS: Benchmark completed!" -ForegroundColor Green
}

# PHASE 4: POST-BENCHMARK CONSISTENCY CHECK
Write-Host "`n[PHASE 4/4] Post-Benchmark Consistency Check" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

& "$REPO_ROOT\scripts\consistency_checks.ps1" -Tag "post_cleanup_${TIMESTAMP}"
$post_result = $LASTEXITCODE

# EXTRACT QUERY LOGS
Write-Host "`nExtracting query logs..." -ForegroundColor Yellow

& "$REPO_ROOT\scripts\parse_neo4j_querylogs.ps1" `
  -ContainerName "neo4j-persons" `
  -OutputFile "$REPO_ROOT\results\mixed_cleanup_${TIMESTAMP}_persons.csv" 2>$null

& "$REPO_ROOT\scripts\parse_neo4j_querylogs.ps1" `
  -ContainerName "neo4j-forums" `
  -OutputFile "$REPO_ROOT\results\mixed_cleanup_${TIMESTAMP}_forums.csv" 2>$null

Write-Host "[OK] Logs extracted" -ForegroundColor Green

# SUMMARY
Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "                    BENCHMARK SUMMARY                        " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

Write-Host "`nConsistency Check Results:" -ForegroundColor Yellow
Write-Host "  Pre-Benchmark:  Exit code $pre_result"
Write-Host "  Post-Benchmark: Exit code $post_result"

if ($post_result -eq 0) {
    Write-Host "`nRESULT: ZERO CONSISTENCY VIOLATIONS DETECTED!" -ForegroundColor Green
    Write-Host "  Cleanup-aware deletes successfully prevented dangling proxies." -ForegroundColor Green
} else {
    Write-Host "`nRESULT: Consistency issues detected (Exit $post_result)" -ForegroundColor Red
    Write-Host "  Check results directory for details." -ForegroundColor Yellow
}

Write-Host "`nOutput Files:" -ForegroundColor Yellow
Write-Host "  Console Log:  $console_log"
Write-Host "  Persons CSV:  $REPO_ROOT\results\mixed_cleanup_${TIMESTAMP}_persons.csv"
Write-Host "  Forums CSV:   $REPO_ROOT\results\mixed_cleanup_${TIMESTAMP}_forums.csv"

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "                    EXPERIMENT COMPLETE                       " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

