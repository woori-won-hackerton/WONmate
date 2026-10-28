</details>

<details>
<summary><b>주요 API</b></summary>

| 기능 | Method | Endpoint |
| --- | --- | --- |
| 로그인 · 내 정보 | `POST` `GET` | `/api/auth/login`, `/api/users/me` |
| 담당 고객 | `GET` | `/api/customers`, `/api/customers/{id}` |
| 계약 | `GET` | `/api/contracts/{customerId}` |
| 고객 위키 | `GET` `POST` | `/api/customers/{id}/wiki`, `/wiki/entries` |
| 상담 일정 | `GET` `POST` | `/api/consults`, `/api/consults/{id}`, `/api/consults/records` |
| AI 브리핑 | `POST` `GET` | `/api/consults/{id}/briefing` |
| 상담 메모 · 완료 | `GET` `PATCH` `POST` | `/api/consults/{id}/memo`, `/complete` |
| AI 상담 요약 | `POST` `GET` `PATCH` | `/api/consults/{id}/ai-record`, `/ai-record/confirm` |
| 할 일 | `GET` `POST` `PATCH` | `/api/todos`, `/api/todos/{id}/status` |
| AI 챗봇 | `POST` | `/api/rag/ask` |
| 상품 · 문서 | `GET` | `/api/products`, `/api/documents`, `/api/documents/{id}/file` |

전체 명세는 Swagger(`/swagger-ui/index.html`)에서 확인할 수 있어요.
</details>

---

## 📸 화면

### 홈

<img src="docs/screenshots/home.png"/>

### AI 챗봇

<img src="docs/screenshots/chat.png"/>

---

## 🚀 프로토타입 실행 방법

### 바로 써보기

| | |
| --- | --- |
| **시연 주소** | `http://<서버 주소>` |
| **시연 계정** | `fc01` ~ `fc05` / `Wonmate2026!` |

> 모든 고객 · 계약 데이터는 가상입니다. 계정마다 담당 고객 5명과 보유 계약이 들어 있어요.

### 내 PC에서 실행하기

**준비물**: [Docker Desktop](https://www.docker.com/products/docker-desktop/) · OpenAI API Key · 약관 PDF(`documents/`)

**1. 소스 받기**

```bash
mkdir wonmate && cd wonmate
git clone https://github.com/woori-won-hackerton/WONmate-Frontend.git frontend
git clone -b develop https://github.com/woori-won-hackerton/WONmate-Backend.git backend
cp -r backend/deploy/. .        # docker-compose.yml, db-init/, .env.example
```

**2. 환경 변수 (`.env`)**

```bash
cp .env.example .env
```

```env
DB_NAME=wonmate
DB_USERNAME=wonmate
DB_PASSWORD=원하는_비밀번호
JWT_SECRET=32자_이상_랜덤_문자열
OPENAI_API_KEY=sk-...
RAG_INGEST_ON_STARTUP=true
JWT_ACCESS_TOKEN_EXPIRATION_SECONDS=43200
```

**3. 약관 PDF 넣기**

documents/
└── product_01/
├── metadata.json # 상품명 · 파일명 · 문서 종류(TERMS/SUMMARY)
├── ..._약관.pdf
└── ..._상품요약서.pdf

**4. 실행**

```bash
docker compose up -d --build
docker compose logs -f backend    # "RAG ingest: finished" 가 찍히면 챗봇 준비 완료
```

**5. 접속**

| 서비스 | 주소 |
| --- | --- |
| 웹 | http://localhost |
| API 문서 (Swagger) | http://localhost:8080/swagger-ui/index.html |

로그인: `fc01` ~ `fc05` / `Wonmate2026!`

> DB는 처음 만들 때만 초기화 SQL(시연 데이터)이 실행돼요. 처음부터 다시 시작하려면 `docker compose down -v` 후 다시 실행하세요.
> 약관 PDF는 처음 한 번만 적재돼요 (문서 20개 기준 약 10분). 이미 적재한 파일은 다시 켜도 건너뜁니다.

### 서버 배포

```bash
# 내 PC (루트)
docker compose build
docker compose push

# 서버 (docker-compose.yml · .env · documents/ 필요)
docker compose pull
docker compose up -d --no-build
```

---

<div align="center">

**WONmate** — 신입 FC 곁의 든든한 상담 파트너

</div>