---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Metasploit Community CTF Review
date            : 2021-01-28 13:20:00 +0900
category        : R&D
author          : 김도현
author_email    : dhkim@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2021-01-28-metasploit-ctf-review/profile_image.jpg
summary         : Metasploit Community CTF Review.
thumbnail       : /assets/stealien.png
---
# 개요

2020년 12월 초 쯤, 영국에 살고있는 @timwr이란 친구한테 Slack DM이 왔다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/overview-1.png"><br>
    <i>나를 잊지 않아 준 @timwr.</i>
</p>

사실 2019년 말에도 이 CTF를 같이 할지 물어 봤었는데, 나는 CTF Pro Player도 아니고, CTF에 흥미를 그렇게 크게 느끼는 사람이 아니었기 때문에 미안하다고 하고 지나갔었다.

근데 이 날은 왠지 할 것도 없고, 코로나 때문에 방에 박혀만 있어서 그런지 흥미가 생겨서 한번 도전 해 보았다.

Teammates는 나 포함 다음 네명이었다.
- [@timwr](https://twitter.com/timwr)
- [@lucyoas](https://twitter.com/lucyoas)
- [@xaitax](https://twitter.com/xaitax)
- [@314ckC47](https://twitter.com/314ckC47)

문제는 내가 알던 'Common Jeopardy CTF'[^1]가 아니었다는 점이다.

<br>

# 2020 Metasploit Community CTF 리뷰

**Metaploit Community CTF**[^2]는 다음과 같은 방식으로 진행 되었다.

1. 각 팀에게는 한개의 Kali Linux Container, Ubuntu Container가 제공된다.
2. Kali Linux와 Ubuntu는 같은 네트워크 상에 존재한다.
3. Kali Linux에 접근 할 수 있는 정보를 제공한다. (IP, SSH Key)
4. Kali Linux를 이용하여 Ubuntu에 열려있는 각 서비스를 장악 또는 정보를 획득하여 Flag를 찾아내면 된다.

다른 CTF를 조금이라도 해 보았다면, 이런 진행 방식의 CTF는 생소할 수도 있을것이다. *왜냐면 내가 그랬기 때문에...*

하지만 이런 환경 정보를 머리속에 집어 넣자, 문제 출제의 의도가 보였다. **'실제 모의 해킹 업무와 비슷한 환경에서의 CTF'**가 이 CTF의 목표인것으로 파악이 되었다.

그렇다면, 접근도 **모의 해킹**처럼 진행 해야겠다고 생각하고 착수를 시작했다.

<br>
## Challenge

> 밑의 문제에 대한 설명은 Slack Message 및 흐릿한 기억에 기반을 두고 작성 되었습니다.

<br>
우선 Kali Linux로 접근하여 타겟 Ubuntu에 nmap[^3]을 이용한 Port Scanning을 시도했다.
```
PORT     STATE SERVICE VERSION
80/tcp   open  http    nginx 1.19.5
1080/tcp open  socks5  (No authentication; connection failed)
5555/tcp open  telnet
8080/tcp open  http    Apache httpd 2.4.38 ((Debian))
8200/tcp open  http    Apache httpd 2.4.38 ((Debian))
8888/tcp open  http    Werkzeug httpd 1.0.1 (Python 3.8.5)
9000/tcp open  http    WEBrick httpd 1.6.0 (Ruby 2.7.0 (2019-12-25))
9001/tcp open  http    Thin httpd
9009/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
9010/tcp open  http    Apache httpd 2.4.38
```

<br>

80번 포트가 너무 맛있어 보여 접근 해 보니, HTML이 어떤 이미지 파일을 링크하고 있었다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/challenge-1.png"><br>
    <i>이상한 이미지 파일.</i>
</p>

이 이미지 파일 EXIF[^4]를 뜯어 보고 있던 찰나, 팀원에게 메세지를 받았다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/challenge-2.png"><br>
    <i>Flag였잖아?!</i>
</p>

알고보니 이 이미지 파일이 플래그였던 것이다. 해당 이미지 파일을 `md5sum` 한 hex string을 인증 하면 되었다.

<br>

이런 방식으로 문제를 풀면 되는데, 내가 푼 문제들 중 한가지 흥미로웠던 문제를 소개 하겠다.

<br>

팀원이 무작위 대입을 통해 SSH 서비스(port 9009)의 ID/Password를 알아냈다. 해당 Account 정보를 이용해 접근 하면, bash 쉘이 열렸고, 우리는 공격 목표를 찾아야 했다.

모두 FTZ[^5]의 1번 문제를 기억하는가? `find` 명령어를 이용하여 로컬 시스템에서 Privilege Escalation의 가능성이 있는 프로그램이 존재하는지 찾아보았다.

```
$ find / -user root -perm -4000 2>/dev/null
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/openssh/ssh-keysign
/usr/bin/passwd
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/chsh
/opt/vpn_connect
/bin/umount
/bin/mount
/bin/su
```

`/opt/vpn_connect`라는 프로그램이 아주 맛이 있어보이게 생겼다.

저 프로그램을 리버싱하면, 단순히 ID/Password 값을 바이너리에 존재하는 문자열과 비교 후 True/False를 출력하는 프로그램이다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/challenge-3.png"><br>
    <i>싸나이는 IDA 테마따위 쓰지 않는다 1.</i>
</p>

다만 한가지 특징은, 사용자의 인풋이 들어가는 로그파일을 사용자가 원하는 위치에 작성 할 수 있다는 건데...

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/challenge-4.png"><br>
    <i>싸나이는 IDA 테마따위 쓰지 않는다 2.</i>
</p>
<br>

이걸 이용해서 다음과 같이 Root shell을 획득 할 수 있었다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/challenge-5.png"><br>
    <i>사실 이거 푼다고 시간을 꽤 썼다.</i>
</p>

우선 로그를 `/etc/passwd`에 다음과 같이 작성하게 되면, `Attempting to connect to server with a and `까지가 Username이 되고, 그 뒤의 값이 Password가 된다. 사실 되게 간단한 문제[^5]인데 아이디어를 생각 하는데 이렇게 오래 걸렸는지.... '가끔 그럴때가 있어야 인간미가 있다'고 생각하려고 한다.

<br>

# 결과

먼저 이 CTF에 대해 평가를 해 보자면, 기존의 Jeopardy 방식 CTF Player라면 적응이 힘들 수도 있다. 무작위대입이라던가, 어느정도의 게싱이 필요하기 때문이다. 하지만 내가 실무를 겪으며 생각 한 것은, 실제로 어느정도의 게싱과 무작위대입은 필요하다. 이 때문에 나는 이 CTF의 컨셉이 아주 잘 짜여졌고, 많이 배울 수 있었다고 생각한다.

<p align="center">
    <img src="/assets/2021-01-28-metasploit-ctf-review/result-1.png"><br>
    <i>3등이다!</i>
</p>
시스템 해킹이 많이 없어서 문제를 많이 풀진 못했지만... 결국 3등을 땄다. 사실 가장 중요한 문제는 3등상이 무엇인가가 중요하지 않겠는가? 그래서 확인 해 보니까... 3등은 100$치의 아마존 기프트카드 1장과 HackTheBox 3개월치 VIP+를 주는 것 아닌가? 그래서 다음 리뷰 포스팅에는 HackTheBox를 리뷰 해 보겠다.

<br>

# References
[^1]: https://kitribob.wiki/wiki/CTF
[^2]: https://metasploitctf.com/
[^3]: https://nmap.org/
[^4]: https://en.wikipedia.org/wiki/Exif
[^5]: https://materials.rangeforce.com/tutorial/2019/11/07/Linux-PrivEsc-SUID-Bit/