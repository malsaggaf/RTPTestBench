#!/usr/bin/env python3
import re
import os
import sys
from collections import defaultdict

LOG_FILE = os.environ.get("GST_LATENCY_LOG", "gst_latency.log")

# Patterns seen in GST latency tracer logs (can vary by version)
LAT_PATTERNS = [
    re.compile(r"latency=(?P<us>\d+)\s*us"),
    re.compile(r"duration=(?P<ns>\d+)\s*ns"),
    # Match both: time=(guint64)12345, time=12345 ns, and time=(guint64)12345,
    re.compile(r"time=(?:\\(guint64\\))?(?P<ns2>\d+)(?:\\s*ns|,)?"),
]

ELEM_PATTERN = re.compile(r"(?:element|src-element|sink-element)=\\(string\\)(?P<elem>[^ ,]+)")

def parse_log(path: str):
    stats = defaultdict(list)
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                # [TRACE/DEBUG PRINTS REMOVED FOR NORMAL OPERATION]
                elem_matches = list(ELEM_PATTERN.finditer(line))
                val_us = None
                for pat in LAT_PATTERNS:
                    m = pat.search(line)
                    if not m:
                        continue
                    if "us" in m.groupdict():
                        val_us = float(m.group("us"))
                        break
                    if "ns" in m.groupdict():
                        val_us = float(m.group("ns")) / 1000.0
                        break
                    if "ns2" in m.groupdict():
                        val_us = float(m.group("ns2")) / 1000.0
                        break
                if val_us is not None and elem_matches:
                    sink_elem = None
                    for em in elem_matches:
                        if 'sink-element' in em.group(0):
                            sink_elem = em.group('elem')
                            break
                    if sink_elem:
                        stats[sink_elem].append(val_us)
                    else:
                        for em in elem_matches:
                            stats[em.group('elem')].append(val_us)
    except FileNotFoundError:
        print(f"Log file not found: {path}", file=sys.stderr)
        sys.exit(1)
    return stats

def summarize(stats):
    rows = []
    for elem, values in stats.items():
        if not values:
            continue
        vmin = min(values)
        vmax = max(values)
        avg = sum(values) / len(values)
        rows.append((elem, vmin, avg, vmax, len(values)))
    rows.sort(key=lambda r: r[2], reverse=True)
    return rows

def format_table(rows):
    if not rows:
        return "No latency entries parsed. Ensure GST_LATENCY_TRACE=1 and run receiver."
    header = ["element", "min (us)", "avg (us)", "max (us)", "samples"]
    widths = [max(len(h), *(len(f"{r[i]:.1f}") if i in (1,2,3) else len(str(r[i])) for r in rows)) for i,h in enumerate(header)]
    out = []
    out.append(" ".join(h.ljust(widths[i]) for i,h in enumerate(header)))
    out.append(" ".join("-"*widths[i] for i in range(len(header))))
    for elem, vmin, avg, vmax, n in rows:
        out.append(" ".join([
            str(elem).ljust(widths[0]),
            f"{vmin:.1f}".ljust(widths[1]),
            f"{avg:.1f}".ljust(widths[2]),
            f"{vmax:.1f}".ljust(widths[3]),
            str(n).ljust(widths[4])
        ]))
    # Heuristic end-to-end: max avg as rough bound
    max_avg_us = max((r[2] for r in rows), default=0.0)
    out.append("")
    out.append(f"Approx end-to-end (rough, from tracer): ~{max_avg_us/1000.0:.2f} ms")
    return "\n".join(out)

def main():
    path = LOG_FILE
    if len(sys.argv) > 1:
        path = sys.argv[1]
    stats = parse_log(path)
    rows = summarize(stats)
    print(format_table(rows))

if __name__ == "__main__":
    main()




