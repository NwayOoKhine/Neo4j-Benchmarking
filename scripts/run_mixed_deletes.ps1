# Mixed Read/Write Benchmark WITH DELETES - Consistency Testing
# Purpose: Enable delete operations to detect dangling proxies and consistency issues

$ErrorActionPreference = "Stop"
$REPO_ROOT = "D:\Honours\Thesis\neo4j-fabric-project"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "  MIXED BENCHMARK WITH DELETES - CONSISTENCY TESTING" -ForegroundColor Cyan
Write-Host "=============================================================`n" -ForegroundColor Cyan

# PHASE 1: PRE-BENCHMARK CONSISTENCY CHECK
Write-Host "`n[PHASE 1/4] Pre-Benchmark Consistency Check" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

& "$REPO_ROOT\scripts\consistency_checks.ps1" -Tag "pre_deletes_${TIMESTAMP}"
$pre_result = $LASTEXITCODE

if ($pre_result -ne 0) {
    Write-Host "`n[WARNING] Found existing consistency issues!" -ForegroundColor Yellow
}

# PHASE 2: CLEAR LOGS
Write-Host "`n[PHASE 2/4] Preparing Benchmark Environment" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

Write-Host "  * Clearing Neo4j query logs..."
docker exec neo4j-fabric sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>&1 | Out-Null
docker exec neo4j-persons sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>&1 | Out-Null
docker exec neo4j-forums sh -c "truncate -s 0 /var/lib/neo4j/logs/query.log" 2>&1 | Out-Null
Write-Host "  [OK] Logs cleared" -ForegroundColor Green

# PHASE 3: RUN MIXED BENCHMARK WITH DELETES
Write-Host "`n[PHASE 3/4] Running Mixed Benchmark (INCLUDES DELETES)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Configuration:" -ForegroundColor Cyan
Write-Host "    - Thread Count: 1" -ForegroundColor White
Write-Host "    - Operations: 500" -ForegroundColor White
Write-Host "    - Workload: Reads + Inserts + DELETES" -ForegroundColor White
Write-Host "    - Expected: Consistency issues likely!" -ForegroundColor Yellow
Write-Host "`n  Starting benchmark...`n" -ForegroundColor Cyan

$START_TIME = Get-Date

try {
    java -Xms2g -Xmx4g `
        -cp "ldbc_snb_interactive_v2_driver\target\driver-standalone.jar;ldbc_snb_interactive_v2_impls\cypher\target\cypher-2.0.0-SNAPSHOT.jar" `
        org.ldbcouncil.snb.driver.Client `
        -P "ldbc_snb_interactive_v2_impls\cypher\driver\benchmark-mixed-deletes.properties" `
        | Tee-Object -FilePath "results\mixed_deletes_${TIMESTAMP}_console.log"
    
    $benchmark_result = $LASTEXITCODE
} catch {
    Write-Host "`n[ERROR] Benchmark crashed: $_" -ForegroundColor Red
    $benchmark_result = 1
}

$END_TIME = Get-Date
$DURATION = ($END_TIME - $START_TIME).TotalSeconds

Write-Host "`n-------------------------------------------------------------" -ForegroundColor DarkGray
if ($benchmark_result -eq 0) {
    Write-Host "  [OK] Benchmark completed" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Benchmark completed with errors (expected)" -ForegroundColor Yellow
}
Write-Host "  Duration: $([math]::Round($DURATION, 2)) seconds" -ForegroundColor White

# PHASE 4: POST-BENCHMARK CONSISTENCY CHECK
Write-Host "`n[PHASE 4/4] Post-Benchmark Consistency Check" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

& "$REPO_ROOT\scripts\consistency_checks.ps1" -Tag "post_deletes_${TIMESTAMP}"
$post_result = $LASTEXITCODE

# EXTRACT QUERY LOGS
Write-Host "`n[BONUS] Extracting Neo4j Query Logs" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

& "$REPO_ROOT\scripts\parse_neo4j_querylogs.ps1" `
    -ContainerName "neo4j-persons" `
    -OutputFile "results\mixed_deletes_${TIMESTAMP}_persons.csv"

& "$REPO_ROOT\scripts\parse_neo4j_querylogs.ps1" `
    -ContainerName "neo4j-forums" `
    -OutputFile "results\mixed_deletes_${TIMESTAMP}_forums.csv"

# FINAL SUMMARY
Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "                    EXPERIMENT COMPLETE" -ForegroundColor Cyan
Write-Host "=============================================================`n" -ForegroundColor Cyan

Write-Host "RESULTS SUMMARY:" -ForegroundColor Yellow
Write-Host "   Pre-Benchmark:  $(if ($pre_result -eq 0) { '[CLEAN]' } else { '[ISSUES]' })" -ForegroundColor $(if ($pre_result -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "   Benchmark:      $(if ($benchmark_result -eq 0) { '[SUCCESS]' } else { '[PARTIAL]' })" -ForegroundColor $(if ($benchmark_result -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "   Post-Benchmark: $(if ($post_result -eq 0) { '[CLEAN]' } else { '[ISSUES DETECTED]' })" -ForegroundColor $(if ($post_result -eq 0) { 'Green' } else { 'Red' })

Write-Host "`nOUTPUT FILES:" -ForegroundColor Yellow
Write-Host "   - Benchmark Log:    results\mixed_deletes_${TIMESTAMP}_console.log" -ForegroundColor White
Write-Host "   - Persons Queries:  results\mixed_deletes_${TIMESTAMP}_persons.csv" -ForegroundColor White
Write-Host "   - Forums Queries:   results\mixed_deletes_${TIMESTAMP}_forums.csv" -ForegroundColor White
Write-Host "   - Consistency Data: results\consistency_index.csv" -ForegroundColor White

if ($post_result -ne 0 -and $pre_result -eq 0) {
    Write-Host "`n[THESIS FINDING] NEW consistency issues detected!" -ForegroundColor Red
    Write-Host "   Delete operations created dangling proxies or orphaned data." -ForegroundColor Red
    Write-Host "   This proves sharding introduces consistency challenges!" -ForegroundColor Red
} elseif ($post_result -eq 0) {
    Write-Host "`n[SURPRISING] No new consistency issues detected." -ForegroundColor Green
    Write-Host "   Fabric handled deletes correctly despite expectations." -ForegroundColor Green
} else {
    Write-Host "`n[NOTE] Baseline already had issues - compare counts to see delta." -ForegroundColor Yellow
}

Write-Host "`n=============================================================`n" -ForegroundColor Cyan


