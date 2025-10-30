SHELL := /bin/bash

.PHONY: install env send recv recv-trace netem-add netem-clear capture parse-latency clean kill docker-build docker-run

install:
	@chmod +x scripts/*.sh docker/entrypoint.sh 2>/dev/null || true
	@./scripts/install_deps.sh

env:
	@mkdir -p cfg
	@[ -f cfg/.env ] || cp cfg/env.example cfg/.env
	@echo "Environment ready at cfg/.env"

send:
	@./scripts/rtp_sender.sh

recv:
	@./scripts/rtp_receiver.sh

recv-trace:
	@GST_LATENCY_TRACE=1 ./scripts/rtp_receiver.sh

netem-add:
	@./scripts/netem_add.sh

netem-clear:
	@./scripts/netem_clear.sh

capture:
	@./scripts/capture_wireshark.sh

parse-latency:
	sed 's/\x1b\[[0-9;]*m//g' gst_latency.log > gst_latency_clean.log
	python3 analyze_latency.py gst_latency_clean.log

kill:
	@./scripts/kill_pipelines.sh

clean:
	@rm -f gst_latency.log
	@rm -rf captures/
	@echo "Cleaned logs and captures"

docker-build:
	@docker build -t rtp-h264-latency-lab -f docker/Dockerfile .

docker-run:
	@docker run --rm -it \
		--net=host \
		-v $$PWD:/work \
		rtp-h264-latency-lab /bin/bash



