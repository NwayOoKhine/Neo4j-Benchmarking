# Orchestrator for running LDBC SNB benchmark sets on sharded Neo4j Fabric
# Usage: .\run_set_sharded.ps1 [-Sets <comma-separated list>]

param(
    [string]$Sets = "threads_sweep_read_warm,threads_sweep_mixed_warm,cold_vs_warm_read"
)

$REPO_ROOT = "D:\Honours\Thesis\neo4j-fabric-project"
$SCRIPT_DIR = "$REPO_ROOT\scripts"

# Define benchmark sets
$BENCHMARK_SETS = @{
    'threads_sweep_read_warm' = @{
        'mode' = 'fabric'
        'mix' = 'read'
        'cold' = 'warm'
        'duration_min' = 10
        'threads' = @(1, 2, 4, 8, 16, 32)
    }
    'threads_sweep_mixed_warm' = @{
        'mode' = 'fabric'
        'mix' = 'mixed'
        'cold' = 'warm'
        'duration_min' = 10
        'threads' = @(1, 2, 4, 8, 16)
    }
    'cold_vs_warm_read' = @{
        'mode' = 'fabric'
        'mix' = 'read'
        'duration_min' = 10
        'runs' = @(
            @{ 'cache_state' = 'cold'; 'threads' = 8 }
            @{ 'cache_state' = 'warm'; 'threads' = 8 }
        )
    }
    'fabric_overhead_intra' = @{
        'mix' = 'read'
        'duration_min' = 10
        'threads' = 8
        'modes' = @('fabric', 'direct_persons', 'direct_forums')
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "LDBC SNB Sharded Benchmark Orchestrator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$sets_to_run = $Sets -split ','
$completed_runs = @()
$failed_runs = @()

foreach ($set_name in $sets_to_run) {
    $set_name = $set_name.Trim()
    
    if (-not $BENCHMARK_SETS.ContainsKey($set_name)) {
        Write-Host "WARNING: Unknown set '$set_name', skipping" -ForegroundColor Yellow
        continue
    }
    
    $set = $BENCHMARK_SETS[$set_name]
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "Running benchmark set: $set_name" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    # Handle different set structures
    if ($set.ContainsKey('runs')) {
        # Custom runs (like cold_vs_warm)
        foreach ($run in $set['runs']) {
            $cache = $run['cache_state']
            $threads = $run['threads']
            
            # Restart for cold cache
            if ($cache -eq 'cold') {
                Write-Host "`nRestarting containers for cold cache..." -ForegroundColor Yellow
                & "$SCRIPT_DIR\restart_cold.ps1"
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "ERROR: Failed to restart containers" -ForegroundColor Red
                    $failed_runs += "${set_name}_${cache}_${threads}t"
                    continue
                }
                
                Write-Host "Running pre-benchmark consistency check..." -ForegroundColor Yellow
                & "$SCRIPT_DIR\consistency_checks.ps1" -Tag "pre_${set_name}_${cache}"
            }
            
            # Start stats sampler
            $stats_file = "$REPO_ROOT\results\sharded\raw\$(Get-Date -Format 'yyyyMMdd_HHmmss')_${set_name}_${cache}_${threads}t_docker_stats.csv"
            $sampler_job = Start-Job -ScriptBlock {
                param($script, $file)
                & $script -OutputFile $file
            } -ArgumentList "$SCRIPT_DIR\docker_stats_sampler.ps1", $stats_file
            
            Start-Sleep -Seconds 2
            
            # Run benchmark
            Write-Host "`nRunning: $set_name (cache=$cache, threads=$threads)..." -ForegroundColor Green
            & "$SCRIPT_DIR\run_benchmark.ps1" -Mode $set['mode'] -Mix $set['mix'] -Threads $threads -DurationMin $set['duration_min'] -Name "${set_name}_${cache}" -Cold $cache
            
            if ($LASTEXITCODE -eq 0) {
                $completed_runs += "${set_name}_${cache}_${threads}t"
            } else {
                $failed_runs += "${set_name}_${cache}_${threads}t"
            }
            
            # Stop stats sampler
            New-Item -ItemType File -Force -Path "$SCRIPT_DIR\.stop_stats" | Out-Null
            Wait-Job $sampler_job -Timeout 10 | Out-Null
            Stop-Job $sampler_job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job $sampler_job -Force -ErrorAction SilentlyContinue | Out-Null
            
            # Post-benchmark consistency check
            if ($cache -eq 'cold') {
                Write-Host "Running post-benchmark consistency check..." -ForegroundColor Yellow
                & "$SCRIPT_DIR\consistency_checks.ps1" -Tag "post_${set_name}_${cache}"
            }
        }
    }
    elseif ($set.ContainsKey('modes')) {
        # Multiple modes (like fabric_overhead)
        foreach ($mode in $set['modes']) {
            # Start stats sampler
            $stats_file = "$REPO_ROOT\results\sharded\raw\$(Get-Date -Format 'yyyyMMdd_HHmmss')_${set_name}_${mode}_docker_stats.csv"
            $sampler_job = Start-Job -ScriptBlock {
                param($script, $file)
                & $script -OutputFile $file
            } -ArgumentList "$SCRIPT_DIR\docker_stats_sampler.ps1", $stats_file
            
            Start-Sleep -Seconds 2
            
            # Run benchmark
            Write-Host "`nRunning: $set_name (mode=$mode, threads=$($set['threads']))..." -ForegroundColor Green
            & "$SCRIPT_DIR\run_benchmark.ps1" -Mode $mode -Mix $set['mix'] -Threads $set['threads'] -DurationMin $set['duration_min'] -Name "${set_name}_${mode}" -Cold 'warm'
            
            if ($LASTEXITCODE -eq 0) {
                $completed_runs += "${set_name}_${mode}"
            } else {
                $failed_runs += "${set_name}_${mode}"
            }
            
            # Stop stats sampler
            New-Item -ItemType File -Force -Path "$SCRIPT_DIR\.stop_stats" | Out-Null
            Wait-Job $sampler_job -Timeout 10 | Out-Null
            Stop-Job $sampler_job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job $sampler_job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
    else {
        # Thread sweep
        foreach ($thread_count in $set['threads']) {
            # Start stats sampler
            $stats_file = "$REPO_ROOT\results\sharded\raw\$(Get-Date -Format 'yyyyMMdd_HHmmss')_${set_name}_${thread_count}t_docker_stats.csv"
            $sampler_job = Start-Job -ScriptBlock {
                param($script, $file)
                & $script -OutputFile $file
            } -ArgumentList "$SCRIPT_DIR\docker_stats_sampler.ps1", $stats_file
            
            Start-Sleep -Seconds 2
            
            # Run benchmark
            Write-Host "`nRunning: $set_name (threads=$thread_count)..." -ForegroundColor Green
            & "$SCRIPT_DIR\run_benchmark.ps1" -Mode $set['mode'] -Mix $set['mix'] -Threads $thread_count -DurationMin $set['duration_min'] -Name $set_name -Cold $set['cold']
            
            if ($LASTEXITCODE -eq 0) {
                $completed_runs += "${set_name}_${thread_count}t"
            } else {
                $failed_runs += "${set_name}_${thread_count}t"
            }
            
            # Stop stats sampler
            New-Item -ItemType File -Force -Path "$SCRIPT_DIR\.stop_stats" | Out-Null
            Wait-Job $sampler_job -Timeout 10 | Out-Null
            Stop-Job $sampler_job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job $sampler_job -Force -ErrorAction SilentlyContinue | Out-Null
            
            # Brief pause between runs
            Start-Sleep -Seconds 5
        }
    }
}

# Print summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Benchmark Orchestration Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Completed runs: $($completed_runs.Count)" -ForegroundColor Green
foreach ($run in $completed_runs) {
    Write-Host "  ✓ $run" -ForegroundColor Green
}

if ($failed_runs.Count -gt 0) {
    Write-Host "`nFailed runs: $($failed_runs.Count)" -ForegroundColor Red
    foreach ($run in $failed_runs) {
        Write-Host "  ✗ $run" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Run Index:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if (Test-Path "$REPO_ROOT\results\run_index.csv") {
    Get-Content "$REPO_ROOT\results\run_index.csv" | Select-Object -Last 20
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Results Archive:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Get-ChildItem "$REPO_ROOT\results\sharded\raw" -Filter "*.tar.gz" -ErrorAction SilentlyContinue | Select-Object -Last 10 Name, Length, LastWriteTime | Format-Table
Get-ChildItem "$REPO_ROOT\results\sharded\raw" -Filter "*.zip" -ErrorAction SilentlyContinue | Select-Object -Last 10 Name, Length, LastWriteTime | Format-Table

exit $(if ($failed_runs.Count -eq 0) { 0 } else { 1 })

