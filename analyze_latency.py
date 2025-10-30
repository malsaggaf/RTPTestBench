import re
import sys

if len(sys.argv) < 2:
    print("Usage: python3 analyze_latency.py LOGFILE")
    sys.exit(1)

LOGFILE = sys.argv[1]

latency_re = re.compile(r'sink-element=\(string\)([^\s,]+).*?time=\(guint64\)(\d+)', re.DOTALL)

latencies = {}
with open(LOGFILE, encoding="utf-8", errors="ignore") as f:
    for line in f:
        m = latency_re.search(line)
        if m:
            elem = m.group(1)
            t_ns = int(m.group(2))
            t_us = t_ns / 1000.0
            if elem not in latencies:
                latencies[elem] = []
            latencies[elem].append(t_us)

if not latencies:
    print("No latency entries parsed. Ensure the tracer log is cleaned and not empty.")
    sys.exit(0)

print("element".ljust(28), "min(us)", "avg(us)", "max(us)", "samples")
print("-" * 60)
for elem, vals in latencies.items():
    vmin, vmax = min(vals), max(vals)
    avg = sum(vals) / len(vals)
    print(elem.ljust(28), f"{vmin:8.1f}", f"{avg:8.1f}", f"{vmax:8.1f}", f"{len(vals):7d}")
max_elem = max(latencies.items(), key=lambda kv: sum(kv[1]) / len(kv[1]))
max_avg_ms = sum(max_elem[1]) / len(max_elem[1]) / 1000.0
print(f"\nApprox end-to-end (worst-sink): {max_elem[0]} ~{max_avg_ms:.2f} ms")
