import re
import sys
import os

if len(sys.argv) < 2:
    print("Usage: python3 analyze_latency.py LOGFILE")
    sys.exit(1)

LOGFILE = sys.argv[1]

# Read FPS from .env file to calculate camera frame interval
FPS = 30  # default
try:
    # Try to find cfg/.env relative to script location or current directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.join(script_dir, 'cfg', '.env')
    if not os.path.exists(env_file):
        # Fallback: try current directory
        env_file = 'cfg/.env'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                if line.startswith('FPS='):
                    FPS = int(line.split('=')[1].strip())
                    break
except (ValueError, FileNotFoundError, IndexError):
    pass

# Calculate camera frame interval (in microseconds)
camera_latency_us = (1000.0 / FPS) * 1000.0  # ms to microseconds

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
max_avg_us = sum(max_elem[1]) / len(max_elem[1])
max_avg_ms = max_avg_us / 1000.0

# Calculate total E2E including camera
total_e2e_us = max_avg_us + camera_latency_us
total_e2e_ms = total_e2e_us / 1000.0
camera_latency_ms = camera_latency_us / 1000.0

print(f"\nCamera frame interval ({FPS} FPS):                    {camera_latency_ms:8.2f} ms")
print(f"Network+Processing latency:                          {max_avg_ms:8.2f} ms")
print("-" * 60)
print(f"Total end-to-end latency (worst-sink): {max_elem[0]} ~{total_e2e_ms:.2f} ms")
