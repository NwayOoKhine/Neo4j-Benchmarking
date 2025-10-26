import re
import json
import csv
from pathlib import Path

# Function to parse LDBC JSON results
def parse_json_results(json_path):
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    results = []
    for metric in data.get('all_metrics', []):
        query_name = metric['name']
        run_time = metric['run_time']
        results.append({
            'query': query_name,
            'count': run_time['count'],
            'mean': run_time['mean'],
            'min': run_time['min'],
            'max': run_time['max'],
            'p25': run_time.get('25th_percentile', run_time.get('25_percentile')),
            'p50': run_time.get('50th_percentile', run_time.get('50_percentile')),
            'p75': run_time.get('75th_percentile', run_time.get('75_percentile')),
            'p90': run_time.get('90th_percentile', run_time.get('90_percentile')),
            'p95': run_time.get('95th_percentile', run_time.get('95_percentile')),
            'p99': run_time.get('99th_percentile', run_time.get('99_percentile')),
            'std_dev': run_time.get('std_dev', 0)
        })
    return results

# Function to extract summary stats from console logs
def parse_console_log(log_path, debug=False):
    # Try UTF-16 encoding first (Windows PowerShell default), then UTF-8
    try:
        with open(log_path, 'r', encoding='utf-16') as f:
            content = f.read()
    except:
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    
    if debug:
        print(f"    Content length: {len(content)} chars")
    
    # Try pattern 1: With percentiles (detailed format)
    pattern1 = r'LdbcQuery(\d+)\s+Count:\s+(\d+)\s+Min:\s+([0-9.]+)\s+ms\s+Max:\s+([0-9.]+)\s+ms\s+Mean:\s+([0-9.]+)\s+ms(?:\s+50th:\s+([0-9.]+)\s+ms)?(?:\s+90th:\s+([0-9.]+)\s+ms)?(?:\s+95th:\s+([0-9.]+)\s+ms)?(?:\s+99th:\s+([0-9.]+)\s+ms)?'
    matches1 = re.findall(pattern1, content)
    
    # Try pattern 2: Simple format (warmup)
    pattern2 = r'LdbcQuery(\d+)\s+Count:\s+(\d+)\s+Mean:\s+([0-9.]+)\s+ms'
    matches2 = re.findall(pattern2, content)
    
    if debug:
        print(f"    Pattern 1 matches: {len(matches1)}")
        print(f"    Pattern 2 matches: {len(matches2)}")
    
    results = []
    
    if matches1:
        # Detailed format found
        for match in matches1:
            query_num = match[0]
            results.append({
                'query': f'LdbcQuery{query_num}',
                'count': int(match[1]),
                'min': float(match[2]),
                'max': float(match[3]),
                'mean': float(match[4]),
                'p50': float(match[5]) if match[5] else None,
                'p90': float(match[6]) if match[6] else None,
                'p95': float(match[7]) if match[7] else None,
                'p99': float(match[8]) if match[8] else None,
            })
    elif matches2:
        # Simple warmup format
        for match in matches2:
            query_num = match[0]
            results.append({
                'query': f'LdbcQuery{query_num}',
                'count': int(match[1]),
                'mean': float(match[2]),
                'min': None,
                'max': None,
                'p50': None,
                'p90': None,
                'p95': None,
                'p99': None,
            })
    
    return results

# Main extraction
results_dir = Path('results')

# Dictionary to store all benchmark data
all_data = {}

# Path A benchmarks
path_a_runs = [
    ('1_thread', 'pathA_1thread_console.log'),
    ('2_threads', 'pathA_2threads_console.log'),
    ('4_threads', 'pathA_4threads_console.log'),
]

print("="*80)
print("EXTRACTING QUERY LATENCY DATA FROM PATH A BENCHMARKS")
print("="*80)

for run_name, log_file in path_a_runs:
    log_path = results_dir / log_file
    if not log_path.exists():
        print(f"\n[NOT FOUND] {run_name}: Log file not found")
        continue
    
    print(f"\n{run_name.upper()}:")
    print(f"  Reading: {log_path}")
    print("-" * 60)
    
    data = parse_console_log(log_path, debug=False)
    all_data[run_name] = data
    
    for query in data:
        p50_str = f"{query['p50']:.2f}" if query['p50'] is not None else 'N/A'
        p95_str = f"{query['p95']:.2f}" if query['p95'] is not None else 'N/A'
        min_str = f"{query['min']:.2f}" if query['min'] is not None else 'N/A'
        max_str = f"{query['max']:.2f}" if query['max'] is not None else 'N/A'
        print(f"  {query['query']:12s} | Count: {query['count']:4d} | "
              f"Mean: {query['mean']:7.2f} | Min: {min_str:>7s} | Max: {max_str:>7s} | "
              f"P50: {p50_str:>7s} | P95: {p95_str:>7s}")

# Also check JSON files for complete data
print("\n\n" + "="*80)
print("CHECKING FOR JSON RESULTS FILES")
print("="*80)

json_patterns = [
    ('Path A Warmup', 'LDBC-SNB-PathA-WARMUP--results.json'),
    ('Mixed Deletes', 'LDBC-SNB-Mixed-Deletes-results.json'),
    ('Overhead Fabric', 'LDBC-SNB-Overhead-Fabric-results.json'),
    ('Overhead Direct', 'LDBC-SNB-Overhead-Direct-results.json'),
]

for name, json_file in json_patterns:
    json_path = results_dir / json_file
    if json_path.exists():
        print(f"\n[FOUND] {name}")
        try:
            data = parse_json_results(json_path)
            for query in data:
                print(f"  {query['query']:12s} | Count: {query['count']:4d} | "
                      f"Mean: {query['mean']:8.2f} | P50: {query['p50']:8.2f} | P95: {query['p95']:8.2f}")
        except Exception as e:
            print(f"  [WARNING] Error parsing: {e}")
    else:
        print(f"\n[NOT FOUND] {name}")

# Export to CSV for easy import
print("\n\n" + "="*80)
print("EXPORTING TO CSV")
print("="*80)

output_path = results_dir / 'query_latencies_for_boxplot.csv'
with open(output_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Benchmark', 'Query', 'Count', 'Mean_ms', 'Min_ms', 'Max_ms', 'P50_ms', 'P90_ms', 'P95_ms', 'P99_ms'])
    
    for bench_name, queries in all_data.items():
        for q in queries:
            writer.writerow([
                bench_name,
                q['query'],
                q['count'],
                q['mean'],
                q['min'] if q['min'] is not None else '',
                q['max'] if q['max'] is not None else '',
                q['p50'] if q['p50'] is not None else '',
                q['p90'] if q['p90'] is not None else '',
                q['p95'] if q['p95'] is not None else '',
                q['p99'] if q['p99'] is not None else '',
            ])

print(f"[SUCCESS] Exported to: {output_path}")
print("\nNote: For true boxplot data (individual observations), you would need the")
print("raw query logs. This CSV contains summary statistics (percentiles) only.")

