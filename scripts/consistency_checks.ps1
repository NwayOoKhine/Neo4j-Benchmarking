# Run consistency checks on sharded Neo4j Fabric deployment
# Usage: .\consistency_checks.ps1 -Tag <pre|post>

param(
    [Parameter(Mandatory=$true)]
    [string]$Tag
)

$REPO_ROOT = "D:\Honours\Thesis\neo4j-fabric-project"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$OUTPUT_DIR = "$REPO_ROOT\results\sharded\raw\${TIMESTAMP}_${Tag}_consistency"

New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Running Consistency Checks ($Tag)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check 1: Dangling PersonID proxies
Write-Host "1. Checking for dangling PersonID proxies..." -ForegroundColor Yellow

$QUERY1 = @"
CALL { USE fabric.forums MATCH (pid:PersonID) RETURN pid.id AS proxyId }
CALL { USE fabric.persons MATCH (p:Person) RETURN collect(p.id) AS validPersonIds }
WITH proxyId, validPersonIds
WHERE NOT proxyId IN validPersonIds
RETURN proxyId AS danglingProxy
"@

$result1 = docker exec neo4j-fabric cypher-shell -u neo4j -p password -d fabric $QUERY1 --format plain 2>&1
$result1 | Out-File "$OUTPUT_DIR\dangling_proxies.csv" -Encoding utf8

$dangling_count = ($result1 | Select-String -Pattern "^\d+" | Measure-Object).Count
Write-Host "   Found $dangling_count dangling proxies" -ForegroundColor $(if ($dangling_count -eq 0) { 'Green' } else { 'Red' })

# Check 2: Dangling moderators
Write-Host "2. Checking for dangling moderators..." -ForegroundColor Yellow

$QUERY2 = @"
CALL { USE fabric.forums MATCH (f:Forum)-[:HAS_MODERATOR]->(pid:PersonID) RETURN f.id AS forumId, pid.id AS proxyId }
CALL { USE fabric.persons MATCH (p:Person) RETURN collect(p.id) AS validPersons }
WITH forumId, proxyId, validPersons
WHERE NOT proxyId IN validPersons
RETURN forumId, proxyId AS danglingModerator
"@

$result2 = docker exec neo4j-fabric cypher-shell -u neo4j -p password -d fabric $QUERY2 --format plain 2>&1
$result2 | Out-File "$OUTPUT_DIR\dangling_moderators.csv" -Encoding utf8

$moderator_count = ($result2 | Select-String -Pattern "^\d+" | Measure-Object).Count
Write-Host "   Found $moderator_count dangling moderators" -ForegroundColor $(if ($moderator_count -eq 0) { 'Green' } else { 'Red' })

# Check 3: Orphan proxies (no relationships)
Write-Host "3. Checking for orphan proxies..." -ForegroundColor Yellow

$QUERY3 = @"
CALL { USE fabric.forums MATCH (pid:PersonID) WHERE NOT (pid)--() RETURN pid.id AS orphanProxy }
RETURN orphanProxy
"@

$result3 = docker exec neo4j-fabric cypher-shell -u neo4j -p password -d fabric $QUERY3 --format plain 2>&1
$result3 | Out-File "$OUTPUT_DIR\orphan_proxies.csv" -Encoding utf8

$orphan_count = ($result3 | Select-String -Pattern "^\d+" | Measure-Object).Count
Write-Host "   Found $orphan_count orphan proxies" -ForegroundColor $(if ($orphan_count -eq 0) { 'Green' } else { 'Red' })

# Summary
$summary = "$TIMESTAMP,$Tag,$dangling_count,$moderator_count,$orphan_count"
if (-not (Test-Path "$REPO_ROOT\results\consistency_index.csv")) {
    "timestamp,tag,dangling_proxies,dangling_moderators,orphan_proxies" | Out-File "$REPO_ROOT\results\consistency_index.csv" -Encoding utf8
}
Add-Content "$REPO_ROOT\results\consistency_index.csv" $summary

$total_issues = $dangling_count + $moderator_count + $orphan_count

Write-Host "`n========================================" -ForegroundColor $(if ($total_issues -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Consistency check complete: $total_issues total issues" -ForegroundColor $(if ($total_issues -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Results saved to: $OUTPUT_DIR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor $(if ($total_issues -eq 0) { 'Green' } else { 'Yellow' })

exit $(if ($total_issues -eq 0) { 0 } else { 1 })

