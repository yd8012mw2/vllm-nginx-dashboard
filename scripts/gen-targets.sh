#!/bin/sh
# .env의 VLLM_NODES를 Prometheus file_sd_configs용 JSON으로 변환
# 결과: /prometheus-targets/vllm.json
set -e

OUTFILE=/prometheus-targets/vllm.json

if [ -z "$VLLM_NODES" ]; then
    echo "ERROR: VLLM_NODES is not set" >&2
    exit 1
fi

printf '[{"targets":[' > "$OUTFILE"
sep=""

OLD_IFS="$IFS"
IFS=","
for node in $VLLM_NODES; do
    node=$(echo "$node" | tr -d ' \t\r\n')
    [ -z "$node" ] && continue
    printf '%s"%s"' "$sep" "$node" >> "$OUTFILE"
    sep=","
done
IFS="$OLD_IFS"

printf ']}]\n' >> "$OUTFILE"

echo "==> prometheus targets generated:"
cat "$OUTFILE"

# prometheus.yml.tmpl의 ${VAR} 플레이스홀더를 실제 값으로 치환
# (prometheus는 --config.expand-env 플래그를 지원하지 않으므로 여기서 처리)
CONFIG_OUT=/prometheus-targets/prometheus.yml
sed \
    -e "s|\${SCRAPE_INTERVAL}|${SCRAPE_INTERVAL:-15s}|g" \
    -e "s|\${EVALUATION_INTERVAL}|${EVALUATION_INTERVAL:-15s}|g" \
    -e "s|\${VLLM_METRICS_PATH}|${VLLM_METRICS_PATH:-/metrics}|g" \
    /prometheus.yml.tmpl > "$CONFIG_OUT"

echo "==> prometheus config rendered:"
cat "$CONFIG_OUT"
