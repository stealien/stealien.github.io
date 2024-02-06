# 스틸리언 기술블로그

## 환경 구성
스틸리언 기술블로그는 ruby jekyll 라이브러리 기반으로 구성됩니다. 아래 명령어를 통해 미리 블로그 글 배포 전 환경 구성을 해주시길 바랍니다.

```bash 
sudo gem install bundler:2.2.26
bundle install
```

위 명령어 입력 후에 아래 명령어를 입력해서 환경 구성이 잘 되었는지 확인하실 수 있습니다.
```bash 
bundle exec jekyll build
```
위 명령어를 입력하셨을 때 아무런 오류 메시지가 없다면 환경구성이 완료되었다고 보시면 됩니다.

## 파일 구조 설명
- `_includes/`: `_layouts/` 디렉터리 내 파일에 의해 참조되는 파일들이 저장되는 디렉터리입니다.
- `_layouts/`: 가장 기본이 되는 템플릿 파일이 저장되는 디렉터리입니다.
- `_posts`: 글 올리실 때 여기 디렉터리에 파일을 생성해주시면 됩니다.
- `_site`: jekyll build 후 파일이 저장되는 디렉터리입니다. 지우셔도 무방합니다.
- `docs/`: 실제 블로그가 보이는 html 파일들이 저장되는 디렉터리입니다.
- `assets/`: 이미지, pdf 등 첨부파일 저장용 디렉터리입니다.

## 배포 관련

인니어를 지원하기 위해서 불가피하게 ``jekyll-polyglot`` 라이브러리를 사용하게 되었습니다.
따라서 기술블로그 업로드 전 별도 빌드 과정이 필요합니다. 배포하기 전 **환경 구성**해주시고 아래 명령어를 입력해주시기 바랍니다.

```bash
./publi.sh
```

명령어 실행 후 github credential을 입력하면 배포가 완료됩니다.


## 블로그 글 작성 시 유의사항
### 1. 파일 업로드 관련

큰 파일은 되도록 다른 링크(e.g. 구글 드라이브 등)를 사용해주시기 바랍니다. 
큰 파일이 올라갈수록 (당연하게도) github repository 크기가 커지고,
github 내에서 `docs/` 내용을 실제 서버로 업데이트 할 때 시간이 많이 소요됩니다.

### 2. 글 작성 관련

**📌 매우 중요합니다**

한국어와 인니어 글 구분을 위해 `_posts/` 내 파일을 생성하실 때 ``YYYY-MM-DD-[title]-(ko|id).(md|markdown)`` 규칙을 지켜서 생성해주시기 바랍니다.

#### e.g. 세준님 글
- 한국어 버전 파일 이름: `2021-10-13-MikroTik-PostAuth-RCE-ko.markdown`
- 인니어 버전 파일 이름: `2021-10-13-MikroTik-PostAuth-RCE-id.markdown`

### 3. 글 메타데이터 설정 관련

아래 형식을 따라 작성해주시기 바랍니다.

```
---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : [제목]
date            : [업로드 날짜]
category        : [글 카테고리 (R&D|Dev|ETC)]
author          : [이름]
author_email    : [이메일]
background      : /assets/bg.png
profile_image   : [프로필 사진 링크]
summary         : [글 한줄 요약 혹은 무제]
thumbnail       : /assets/stealien.png
lang            : ko
permalink       : [글 링크]
---
```

#### 예시

```
---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Analyzing Django ORM with 1-day vulnerabilities and sql bug
date            : 2022-12-16 00:00:00 +0900
category        : R&D
author          : Seokchan Yoon
author_email    : scyoon@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2022-10-04-Secure-Coding-Training-System/profile.jpeg
summary         : "Let's analyze django, the king of Python web library"
thumbnail       : /assets/stealien.png
lang            : ko
permalink       : /2022-12-16/analyzing-django-orm-with-1-day
---
```
