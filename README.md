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

**Complete Pipeline Flow:**
```
[Video Source] → [Encoder] → [RTP Payload] → [Network/UDP] → [RTP Depayload] → [Decoder] → [Display]
```

**Important: Measurement Scope vs. Complete Pipeline**

The diagram above shows the **complete pipeline**, but the **actual latency measurement starts at the receiver** (when packets arrive via UDP). This means:

- **What IS measured** (receiver-side only):
  - Network transmission delay (UDP packet arrival)
  - RTP depayload processing
  - Jitterbuffer delay (`JITTERBUFFER_LATENCY_MS`)
  - Decoding delay (H.264 decode to raw video)
  - Display delay (frame rendering and synchronization)

- **What is NOT measured directly** (sender-side):
  - Encoding delay (H.264 encoding on sender)
  - RTP payload packetization on sender

**Note:** Camera frame interval (calculated from `FPS`) is automatically added to provide total end-to-end latency, but encoder processing delay is not included.

**Latency Calculation:**

The measured pipeline latency (from network arrival to display) is automatically combined with **camera frame interval latency** to provide total end-to-end latency:

- **Network+Processing latency**: Measured from UDP packet arrival (`udpsrc`) through decode to display (receiver-side only)
- **Camera frame interval**: Calculated from `FPS` setting in `cfg/.env` as `1000ms / FPS` (e.g., 33.33 ms at 30 FPS)
- **Total end-to-end latency**: Sum of both above components

**Components Included in Network+Processing Measurement:**
- **Network delay**: UDP packet transmission, routing, and arrival (measured from `udpsrc`)
- **Jitterbuffer**: Receiver buffering to absorb network jitter (`JITTERBUFFER_LATENCY_MS`)
- **Decoding delay**: H.264 decode to raw video (`avdec_h264`)
- **Display delay**: Frame rendering and synchronization (`SINK_SYNC`)

**Why Camera Frame Interval is Added:**

The camera frame interval represents the minimum delay between consecutive frames at a given FPS (one frame period). This is added to the measured pipeline latency to estimate true end-to-end latency from camera capture to display. Note that encoder delay is not included (only camera frame interval).

**Measurement Method:**
GStreamer latency tracer records timestamps when buffers enter the receiver pipeline at `udpsrc` (source pad) and when they exit at display sinks (sink pad). The difference (`time=(guint64)N nanoseconds`) is converted to microseconds and milliseconds for reporting. The camera frame interval (from `FPS` in `cfg/.env`) is automatically added to provide total end-to-end latency.

**Output Format:**
```
element                      min(us) avg(us) max(us) samples
------------------------------------------------------------
fpsdisplaysink0                  X      Y      Z     N
...

Camera frame interval (30 FPS):                        33.33 ms
Network+Processing latency:                           76.00 ms
------------------------------------------------------------
Total end-to-end latency (worst-sink): fpsdisplaysink0 ~109.33 ms
```
