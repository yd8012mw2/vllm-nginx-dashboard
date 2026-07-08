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
