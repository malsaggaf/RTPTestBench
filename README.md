## rtp-h264-latency-lab

Estimate end-to-end latency of an RTP-over-UDP H.264 pipeline using GStreamer. Runs on one machine (localhost) or two machines. Includes sender/receiver scripts, optional network impairments (netem), Wireshark capture helpers, and two measurement methods: visual timestamp overlay and GStreamer latency tracer logs.

### Quick start (Ubuntu/Debian)

```bash
make install
make env   # then edit cfg/.env if desired
make send  # terminal A
make recv  # terminal B
```

### Measure visually
- Read SRC HH:MM:SS.uuuuuu at the sender overlay vs SINK HH:MM:SS.uuuuuu at the receiver overlay.
- The delta is the approximate end-to-end latency.

### Measure via tracer
```bash
make recv-trace     # runs receiver with GST latency tracer and writes gst_latency.log
make parse-latency  # prints summary of element latencies
```

### Inject impairments (netem)
```bash
make netem-add    # simulate delay/jitter/loss defined in cfg/.env
make netem-clear  # clear impairments
```

### Capture RTP with tshark
```bash
make capture
```
Open `captures/rtp.pcapng` in Wireshark and use filters such as `rtp` or `udp.port == 5000`. Inspect RTP timestamps vs arrival time to study jitter.

### Two-machine mode
- Set `HOST` in `cfg/.env` to the receiver IP.
- Change `IFACE` to your NIC for netem on the sender or a middlebox.

### Low-latency tips
- Keep `x264enc` tune=zerolatency speed-preset=ultrafast.
- Set `key-int-max` to `FPS`.
- Keep `rtpjitterbuffer` `latency` modest (e.g., 30–60 ms) unless the network is unstable.
- Use `SINK_SYNC=true` for realistic display timing; set `false` for minimal added latency during tests.

### Project layout
```
rtp-h264-latency-lab/
├─ README.md
├─ Makefile
├─ scripts/
│  ├─ install_deps.sh
│  ├─ rtp_sender.sh
│  ├─ rtp_receiver.sh
│  ├─ netem_add.sh
│  ├─ netem_clear.sh
│  ├─ capture_wireshark.sh
│  ├─ kill_pipelines.sh
│  └─ profile_cpu.sh (optional)
├─ cfg/
│  └─ env.example
├─ tools/
│  └─ parse_gst_latency.py
├─ docker/
│  ├─ Dockerfile
│  └─ entrypoint.sh
```
### Notes
- Dependencies installed by `make install`.
- `.env` is optional; defaults are sane. Copy from `cfg/env.example` with `make env`.
- On some systems `tshark` requires elevated privileges or capabilities to capture.
- All `*.sh` scripts expect bash and strict mode.

### Stream Pipeline and Latency Calculation

**Pipeline Flow:**
```
[Video Source] → [Encoder] → [RTP Payload] → [Network/UDP] → [RTP Depayload] → [Decoder] → [Display]
```

**End-to-End Latency Definition:**
Measured latency includes all delays from when a frame leaves the video source through network transmission, reception, decoding, and display. This does **NOT** include camera internal capture/sensor delays (e.g., frame interval of 33ms at 30 FPS).

**Components Included:**
- **Encoding delay**: H.264 encoding time (x264 with zerolatency preset)
- **Network delay**: UDP packet transmission, routing, and arrival
- **Jitterbuffer**: Receiver buffering to absorb network jitter (`JITTERBUFFER_LATENCY_MS`)
- **Decoding delay**: H.264 decode to raw video
- **Display delay**: Frame rendering and synchronization (`SINK_SYNC`)

**Measurement Method:**
GStreamer latency tracer records timestamps when buffers enter the pipeline (source pad) and when they exit at display sinks (sink pad). The difference (`time=(guint64)N nanoseconds`) is converted to microseconds and milliseconds for reporting.

**Output Format:**
```
element                      min(us) avg(us) max(us) samples
------------------------------------------------------------
fpsdisplaysink0                  X      Y      Z     N
...
Approx end-to-end (worst-sink): ~XX.XX ms
```
