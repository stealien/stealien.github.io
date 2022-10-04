---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: Secure Coding Training System 개발기
date		: 2022-10-04 00:00:00 +0900
category	: R&D
author		: 윤석찬
author_email: scyoon@stealien.com
background	: /assets/bg.png
profile_image: /assets/2022-10-04-Secure-Coding-Training-System/profile.jpeg
summary		: "경희대학교 SW 보안대회 운영기"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2022-07-13/secure-coding-traing-system
---


# 개요

안녕하세요. 스틸리언 R&D팀 윤석찬입니다. 저는 스틸리언에서 모의해킹, 보안 기술 연구 뿐만 아니라 다양한 제품을 개발하고 있기도 합니다. 제가 개발에 참여한 대표적인 것 중 하나는 *Cyber Drill System*이라는 교육 플랫폼입니다. 스틸리언에서는 이 플랫폼을 이용해 학생 혹은 실무자 분들을 대상으로 교육하고 있습니다. 입사하고 약 2개월이 되던 때 쯔음 이 프로젝트에 참가하게 되었는데, 벌써 3년째가 되었네요 😄  저는 이 프로젝트를 좀 더 고도화하고 새로운 형식의 플랫폼을 위해서 노력하고 있습니다.

최근 몇몇 워게임, 해킹대회(CTF) 중에는 취약한 인스턴스를 할당받고, 이것을 공격하는 형태의 플랫폼이 증가하고 있습니다. 대표적으로는 HackTheBox, 드림핵 플랫폼이 있습니다. 이 중 HackTheBox 플랫폼은 실제 인스턴스를 할당받는 방식으로 구현되었으며, 독립적인 가상 서버에서 실습할 수 있기 때문에 좀 더 다양한 공격을 시도해볼 수 있게 됩니다. 

가령 일반적인 CTF 플랫폼에서는 하나의 가상서버에 여러 사용자가 접근하여 취약점을 공격하기 때문에 LPE* 기법을 쓰지 못하도록 막아놓는 경우가 일반적인 반면,  HackTheBox는 타겟의 쉘을 얻는 것에 그치지 않고 가상서버에서 얻은 쉘을 이용해 LPE까지 유도하기도 합니다. 저도 HackTheBox와 같은 인스턴스 할당 방식의 교육 훈련 시스템을 만들어서 효용성 높은 훈련 시스템을 만들고자 했고, docker command 중 몇 개를 python 코드에 매핑만 해두어도 충분히 구현할 수 있겠다는 생각이 들었습니다. 그렇게 관련 자료를 찾아보다 Docker SDK라는 라이브러리를 찾을 수 있었습니다.

\* LPE : Local Privilege Escalation


# Docker SDK

Docker SDK 라이브러리는 docker 안의 대부분의 명령어를 파이썬 코드로 매핑해놓은 라이브러리입니다. 그런데 제가 생각했던 점과 다른 점이 있다면 이 라이브러리는 `docker [command]` 형식의 커맨드를 매핑해놓은게 아니라, `/var/run/docker.sock` 에 마운트된 유닉스 소켓을 통한 HTTP API 통신으로 매핑해놓았다는 것입니다.

실제로 공식홈페이지에 들어가보면 도커 명령어를 파이썬 명령어로 실행시킬 수 있음을 확인할 수 있습니다.

***Using echo command in alpine image***
```python
>>> import docker
>>> client = docker.from_env()
>>> client.containers.run('alpine', 'echo hello world')
b'hello world\n'
```

***Managing your containers***
```python
>>> client.containers.list()
[<Container '45e6d2de7c54'>, <Container 'db18e4f20eaa'>, ...]
>>> container = client.containers.get('45e6d2de7c54')
>>> container.attrs['Config']['Image']
"bfirsh/reticulate-splines"
>>> container.logs()
"Reticulating spline 1...\n"
>>> container.stop()
```

[참고] : [https://docker-py.readthedocs.io/en/stable/](https://docker-py.readthedocs.io/en/stable/)

위처럼 Docker SDK를 통해 docker command를 자동화할 수 있고, 만들 수 있는 것들이 무궁무진해집니다. 이 라이브러리를 사용하면 docker를 통한 이미지, 컨테이너 관리 작업을 코드 상에서 안정적으로 구현할 수 있습니다. 저는 이것을 통해 AWS EC2 서비스 같은 VPC (Virtual Private Cloud) 서비스를 구현해볼 수 있을 것 같다는 생각이 들었습니다.


# Simple VPC Service

그래서 Docker SDK 라이브러리로 처음 구현해본 서비스는 VPC 서비스입니다. 제가 만든 VPC 서비스의 주요 기능은 사용자가 버튼을 클릭하면 SSH 서버를 제공하는 것입니다. 이 기능을 구현하기 위해 내부적으로 거쳐야 하는 과정은 다음과 같습니다.

1. 사용자의 정보를 확인해서 서버 생성 권한이 있는지 확인한다.
2. 사용자로부터 포트 번호를 받는다.
3. `openssh-server` 패키지가 설치된 컨테이너 이미지를 기반으로 컨테이너를 생성하고, 사용자가 입력한 포트번호로 컨테이너의 22번 포트를 연결한다.
4.  생성한 컨테이너에 foreground에서 종료되지 않고 무기한으로 실행할 수 있는 명령어를 실행해서 컨테이너를 유지한다. (e.g. `tail -f /dev/null` , `
`sleep infinity`) 
5. 생성한 컨테이너를 사용자에게 전달한다.

위 과정에서 사용된 컨테이너 이미지를 빌드하기 위한 `Dockerfile` 은 아래와 같습니다.

```Dockerfile
FROM ubuntu:latest

RUN apt-get update -y
RUN apt-get install -y openssh-server vim

# change root password
RUN echo 'root:admin123' | chpasswd

# change ssh configure
RUN echo PermitRootLogin yes >> /etc/ssh/sshd_config && service ssh restart

RUN service ssh restart
```

(tl;dr) 위와 같은 식으로 VPC 서비스를 구현하고 제가 다니는 학교에 프로젝트 과제로 제출해서 좋은 성적을 받은 경험이 있습니다. ^^ v 소스코드는 현재 비공개로 되어있으며 현재는 사내 git 내부 프로젝트로 옮겨두었습니다.


# CCE 2021

저는 국가정보원에서 주최한 2021 사이버공격방어대회(CCE)에 한국수력원자력 연합팀으로 공공부문에 참가한 경험이 있습니다. CCE는 우리나라에서 규모가 큰 대회이고 본선에서 공방전 형식 등 다양한 포맷을 시도하는 것으로 유명한 대회입니다. 저는 처음 CCE 본선 무대에 발을 딛은 터라 새로운 형식의 대회에 크게 감명 받았습니다.

본선 대회 형식은 라운드 별로 나뉘었던 것으로 기억합니다. 팀 내에서 제가 주도적으로 참여했던 첫번째 라운드는 출제진 쪽에서 제공한 가상 인스턴스에 ssh로 접속해서 취약한 소스코드를 수정하고 SLA 체크 후 점수가 변동되는 형식이었습니다. SLA 체크는 자동 스크립트를 통해 가상 인스턴스의 가용성, 취약성을 검사입니다. 30초마다 문제 출제진 쪽에서 만든 SLA 체크 스크립트를 돌려서 취약점이 아직 존재하거나 서비스의 가용성이 훼손된 경우 팀 점수에서 차감되는 형식입니다.

CCE에서 만난 제가 만든 VPC 서비스를 좀 더 발전시켜서 CCE 본선에서 봤던 시스템을 구현할 수 있겠다는 생각이 들었습니다.


# Secure Coding Training Platform

2022년 내에 교내 보안대회에서 사용하겠다는 목표로 시큐어 코딩 교육 플랫폼을 만들었습니다. 원래는 ssh 정보만 주고 `vi` 명령으로 소스코드를 수정하는 형식으로 운영하고자 했으나, 터미널에 익숙하지 않은 분들이 많다는 점을 알게 되어 WEB IDE를 제공하는 형식으로 개발했습니다. WEB IDE는  `monaco-editor` 라이브러리를 사용하여 React를 기반으로 만들어졌고, 이미지화하여 활용성을 높게 하였습니다.

WEB IDE를 생성하는 과정은 다음과 같습니다.
1. 문제 출제자가 지정한 이미지 이름을 가져와 컨테이너를 생성한다.
2. 생성한 컨테이너에서 문제 출제자가 지정한 디렉터리에서 소스코드를 복사한다.
3. 사용자에게 제공될 WEB-IDE를 생성한다.
4. 컨테이너에서 복사한 소스코드를 WEB IDE 안에 복사한다.
5. 사용자에게 WEB IDE 접속 정보를 출력한다.

SLA 체크 과정은 다음과 같습니다.
1. 사용자가 해당 문제를 이미 풀었는지 등을 확인한다.
2. 사용자가 수정한 파일들을 관리 서버에 복사한다.
3. build 및 SLA 용 컨테이너를 생성한다.
4. 3에서 생성한 컨테이너에 사용자가 수정한 파일을 붙여넣는다.
5. 문제에 지정된 TestCase 명령어들을 수행하고 점수를 매긴다.

(tl;dr) 이 프로젝트도 소스코드는 현재 비공개로 되어있으며 현재는 사내 git 내부 프로젝트로 옮겨두었습니다.


# 경희대학교 SW 보안대회

<img src="/assets/2022-10-04-Secure-Coding-Training-System/poster.png" width="400px" title="KHUCTF Poster"/>


실제로 해당 플랫폼으로 경희대학교에서 SW 보안대회를 진행했습니다. RAON, ENKI 등 국내 유명한 보안 업체 소속인 제 친구들과 재직자 분들께 부탁을 해서 양질의 문제를 출제할 수 있었습니다. 실제 문제 풀이자가 그렇게 많지 않아 사용자 피드백이 적다는 점이 아쉽긴하나, 이 대회를 계기로 회사 내에서 만들고 있는 사이드 프로젝트에 큰 도움이 되었습니다.


# 마무리

Docker SDK를 통해 실제 소프트웨어 보안대회에 사용되는 플랫폼을 개발하기까지의 과정을 한 예시로 설명드렸습니다. 클라우드 서비스 상품과 라이브러리는 지금도 다양하게 제공되고 있어서 쉽게 기능을 개발할 수 있습니다.

> 거인의 어깨 위에 서서 더 높은 가치를 만들어낼 수 있습니다.

