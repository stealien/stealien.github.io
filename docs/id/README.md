# STEALIEN Tech Blog

스틸리언 기술 블로그 — [ufo.stealien.com](http://ufo.stealien.com)

## 환경 구성

Ruby가 설치되어 있어야 합니다. (Ruby 3.x 권장)

```bash
bundle install
```

설치 확인:

```bash
bundle exec jekyll build
```

오류 없이 완료되면 환경 구성이 끝난 것입니다.

## 로컬에서 미리보기

```bash
bundle exec jekyll serve
```

브라우저에서 `http://localhost:4000` 으로 접속하면 블로그를 확인할 수 있습니다.

## 배포

```bash
./publi.sh
```

이 스크립트가 빌드 → `docs/` 디렉터리 생성 → git commit & push까지 자동으로 처리합니다.

> `docs/` 디렉터리는 빌드 결과물입니다. 직접 수정하지 마세요.

---

## 글 작성 가이드

### 1. 파일 생성

`_posts/` 디렉터리에 아래 규칙으로 파일을 만듭니다:

```
YYYY-MM-DD-제목-슬러그-ko.md
```

**예시:**

```
2025-04-22-IoT-Firmware-ko.md
```

인도네시아어 버전이 있다면 같은 이름에 `-id`로 만듭니다:

```
2025-04-22-IoT-Firmware-id.md
```

### 2. 메타데이터 작성

파일 최상단에 아래 형식을 복사해서 내용을 채워 넣으세요:

```yaml
---
layout: post
markdown: kramdown
highlighter: rouge
title: "글 제목"
date: 2025-04-22 00:00:00 +0900
category: R&D
author: 홍길동
author_email: hong@stealien.com
background: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary: "글 한줄 요약"
thumbnail: /assets/stealien.png
lang: ko
---
```

| 항목 | 설명 |
|------|------|
| `title` | 글 제목 (따옴표로 감싸주세요) |
| `date` | 발행일 (`YYYY-MM-DD HH:MM:SS +0900`) |
| `category` | `R&D`, `Dev`, `CTI` 중 하나 |
| `author` | 작성자 이름 |
| `author_email` | 작성자 이메일 |
| `profile_image` | 프로필 사진 경로 (기본값: `/assets/stealien_inverse.png`) |
| `summary` | 글 목록에 표시될 한줄 요약 |
| `lang` | `ko` (한국어) 또는 `id` (인도네시아어) |

### 3. 이미지 추가

`assets/` 아래에 글과 같은 이름의 폴더를 만들고 이미지를 넣습니다:

```
assets/2025-04-22-IoT-Firmware/
├── image1.png
└── image2.png
```

글 본문에서 이렇게 참조합니다:

```markdown
![설명](/assets/2025-04-22-IoT-Firmware/image1.png)
```

> 큰 파일(영상 등)은 구글 드라이브 등 외부 링크를 사용해주세요.

### 4. 글 작성

메타데이터(`---`) 아래부터 Markdown으로 자유롭게 작성하면 됩니다.

**YouTube 영상 삽입:**

```
{% youtube VIDEO_ID %}
```

---

## 카테고리 추가 가이드

현재 카테고리: `R&D`, `Dev`, `CTI`

새 카테고리를 추가하려면:

**1)** 프로젝트 루트에 카테고리 페이지 파일 생성 (예: `categories_new.markdown`):

```yaml
---
layout: category
title: New Category
permalink: /categories/New
category: New
---
```

**2)** `_includes/category_tabs.html`에서 탭 목록에 추가:

```liquid
{% assign tab_order = "R&D,Dev,CTI,New" | split: "," %}
```

---

## 파일 구조

```
_posts/          → 블로그 글 (Markdown)
_layouts/        → HTML 템플릿
_includes/       → 재사용 HTML 조각 (헤더, 푸터, 탭 등)
_plugins/        → Jekyll 플러그인 (YouTube 임베드)
assets/          → 이미지, CSS 등 정적 파일
assets/css/      → 스타일시트
docs/            → 빌드 결과물 (수정 금지)
_config.yml      → 사이트 설정
Gemfile          → Ruby 의존성
publi.sh         → 배포 스크립트
```

## 기술 스택

- Jekyll 4.4
- kramdown (GFM) + Rouge
- jekyll-polyglot (한국어/인도네시아어)
- Bootstrap 4.5
