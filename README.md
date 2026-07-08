# vllm-nginx-dashboard

vLLM 클러스터 실시간 모니터링 대시보드. Prometheus가 각 노드의 메트릭을 수집하고, 브라우저 대시보드가 Prometheus API를 직접 쿼리해 표시합니다.

```
vLLM nodes ──scrape──▶ Prometheus ──query──▶ Dashboard (browser)
nginx LB   ──scrape──▶ Prometheus            Grafana (optional)
```

---

## 요구 사항

- Docker 24+ 및 Docker Compose v2 (`docker compose` 명령)
- vLLM 노드들이 `/metrics` 엔드포인트를 노출하고 있을 것 (기본 포트 `8000`)
- 이 스택을 실행하는 머신에서 vLLM 노드 IP로 네트워크 접근 가능할 것

---

## 설치 및 실행

### 1. 저장소 클론

```bash
git clone https://github.com/yd8012mw2/vllm-nginx-dashboard.git
cd vllm-nginx-dashboard
```

### 2. 환경 변수 설정

```bash
cp .env.example .env
```

`.env`를 열어 vLLM 노드 목록을 수정합니다.

```env
# 쉼표로 구분, 노드 수 제한 없음 (1개 이상)
VLLM_NODES=192.168.1.10:8000,192.168.1.11:8000,192.168.1.12:8000
```

그 외 포트나 Grafana 비밀번호도 필요에 따라 변경합니다.

### 3. 스택 실행

```bash
docker compose up -d
```

최초 실행 시 이미지 pull 및 아래 순서로 기동됩니다.

```
setup (타겟 JSON 생성) → prometheus → grafana → frontend
```

### 4. 접속

| 서비스 | URL | 비고 |
|--------|-----|------|
| 대시보드 | http://localhost:8080 | 기본 포트 |
| Grafana | http://localhost:8080/grafana/ | admin / `.env`의 `GF_SECURITY_ADMIN_PASSWORD` |
| Prometheus | http://localhost:9090 | 직접 접속 |

> 포트를 변경하려면 `.env`의 `FRONTEND_PORT`, `GRAFANA_PORT`, `PROMETHEUS_PORT`를 수정하세요.

---

## 노드 추가 / 변경

`.env`의 `VLLM_NODES`를 수정한 뒤:

```bash
docker compose up -d --force-recreate setup prometheus
```

Prometheus는 `file_sd_configs`를 30초마다 재읽으므로, `prometheus` 재시작 없이 노드가 자동으로 반영됩니다.

---

## nginx 메트릭 수집 (선택)

기존 nginx에서 `stub_status`를 활성화한 경우 nginx-prometheus-exporter를 함께 띄울 수 있습니다.

**nginx.conf에 추가:**

```nginx
location /nginx_status {
    stub_status;
    allow 127.0.0.1;
    deny all;
}
```

**.env에서 URL 확인:**

```env
NGINX_STUB_STATUS_URL=http://host.docker.internal/nginx_status
```

**exporter 프로필로 실행:**

```bash
docker compose --profile nginx-metrics up -d
```

---

## 중지 / 데이터 초기화

```bash
# 중지 (데이터 유지)
docker compose down

# 중지 + Prometheus/Grafana 데이터 삭제
docker compose down -v
```

---

## 디렉터리 구조

```
.
├── .env.example                         # 환경 변수 템플릿
├── docker-compose.yml
├── vLLM Cluster Monitor.dc.html         # 브라우저 대시보드
├── support.js                           # 대시보드 런타임
├── prometheus/
│   └── prometheus.yml                   # 스크레이프 설정
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── prometheus.yml           # Grafana 데이터소스 자동 등록
├── nginx/
│   ├── default.conf                     # 프론트엔드 서빙 + 역방향 프록시
│   └── config.js.tmpl                   # .env → config.js 생성 템플릿
└── scripts/
    └── gen-targets.sh                   # VLLM_NODES → Prometheus file_sd JSON
```

---

## 수집 메트릭

대시보드는 아래 vLLM 네이티브 메트릭을 사용합니다.

| 메트릭 | 설명 |
|--------|------|
| `vllm:prompt_tokens_total` | Prefill 처리량 |
| `vllm:generation_tokens_total` | Generation 처리량 |
| `vllm:request_success_total` | 성공 요청 수 |
| `vllm:num_requests_running` | 현재 실행 중인 요청 수 |
| `vllm:num_requests_waiting` | 대기 중인 요청 수 |
| `vllm:time_to_first_token_seconds` | TTFT 히스토그램 |
| `vllm:gpu_cache_usage_perc` | KV 캐시 사용률 |
| `up{job="vllm"}` | 노드 생존 여부 |
