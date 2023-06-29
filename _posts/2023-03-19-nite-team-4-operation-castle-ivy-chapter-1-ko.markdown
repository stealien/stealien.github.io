---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: "NITE Team 4: OPERATION CASTLE IVY Chapter 1 리뷰"
date		: 2023-03-19 00:00:00 +0900
category	: R&D
author		: 김도현
author_email: dhkim@stealien.com
background	: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary		: "비전공자의 시야로 고증의 측면에서"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2023-03-19/nite-team-4-operation-castle-ivy-chapter-1
---

# NITE Team 4

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/nite-team-4.webp"><br>
    <i>NITE Team 4</i>
</p>

"NITE Team 4"는 플레이어가 군의 해킹 부서에서 오퍼레이터로 근무하며 지시에 따라 해킹 작전을 수행하는 것을 간접적으로 체험해 볼 수 있는 시뮬레이션 게임입니다.

플레이어는 스토리/캠페인의 목적에 따라 적합한 해킹 도구를 사용하여 첩보를 수집하고 분석하는 것으로 마치 퍼즐을 푸는 것 처럼 게임을 진행할 수 있습니다.

---

# STINGER OS

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/stinger-os.png"><br>
    <i>STINGER OS</i>
</p>

"NITE Team 4"에서는 *STINGER OS*라고 부르는 다양한 해킹 도구가 포함된 운영체제를 이용하여 작전을 수행하게 됩니다.

앞으로 STINGER OS를 이용하여 작전의 목적에 따라 대상을 해킹하고, 첩보를 처리, 분석하게 될 것입니다.

## 🔎 운영체제 (OS, Operating System)

우리가 많이 사용하는 웹 브라우져, 파일 탐색기, 문서 편집기 등을 "응용 프로그램"이라고 부릅니다.

"응용 프로그램"을 잘 실행시키고, 편리하게 사용기기 위해서는 "운영체제"가 필요합니다.

여러분이 웹 브라우져로 여러개의 탭을 이용하여 웹 서핑을 할 수 있는 이유도, 파일을 복사하여 문서에 붙여넣을 수 있는 이유도, 결국 이 "운영체제"가 그런 기능을 구현하고, 응용할 수 있도록 만들어 주기 때문입니다.

우리가 실제로 많이 쓰는 운영체제로는 *Microsoft Windows*, *Apple macOS*가 있죠.

모바일 디바이스에서는 *Google Android*, *Apple iOS*가 있을 수 있겠네요.

## 🔎 해킹을 위한 OS

"NITE Team 4"의 STINGER OS처럼, 현실에도 해킹을 위한 OS가 존재합니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/kali-linux.jpg"><br>
    <i>Kali Linux</i>
</p>

[Kali Linux](https://www.kali.org/get-kali/)는 Offensive Security사에서 개발한 해킹을 위한 OS입니다.

Linux라는 OS를 기반하고 있으며, 앞으로 "NITE Team 4"에서 사용할 많은 도구들 중 일부들가 kali Linux에 포함된 도구를 벤치마킹하고 있습니다.

하지만 Kali Linux는 STINGER OS와 다르게 해킹의 전반적인 작업들을 자동화 해 주지는 못합니다. Kali Linux에는 해킹을 위한 다양한 오픈소스 도구들이 집합되어 있을 뿐, 실제로 해킹을 수행하기 위해서는 각 도구의 원리와 사용 방법에 대한 이해가 필요합니다.

현실에서는 이 Kali Linux를 기업 또는 단체에서 모의해킹, 침투 테스팅, 레드팀을 이용한 정보 보안 강화에 많이 사용하고 있습니다.

비슷한 OS로는 [Black Arch Linux](https://blackarch.org/), [Parrot OS](https://www.parrotsec.org/)가 있습니다.

---

# OPERATION CASTLE IVY

STINGER OS에 대한 교육이 끝난 후, operator는 실제 작전에 투입됩니다.

## INTRO

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/intro.png"><br>
    <i>Operation CASTLE IVY Intro</i>
</p>

> 상부는 "NITE Team 4"의 군용 멀웨어가 도난 당했음을 확인했습니다.  
> SAD는 Bureau 121의 소행으로 추정하고 있지만, 뒷덜미를 잡을만한 증거가 부족합니다.  
> 2017년 NSA의 익스플로잇 유출로 10B$ 추정의 손해가 있었던 만큼, 빠르게 이를 조사해야합니다.
> 우리는 현장에 남겨진 증거들을 활용하여 얼마만큼의 유출이 발생했는지 확인해야 합니다.

### 🔎 Malware - 멀웨어, 악성코드

Malware는 Malicious Software, 즉 악성 소프트웨어 또는 악성 코드의 줄임말입니다.

Malware는 그 특성에 따라 분류되고 있으며, 대표적인 몇가지를 소개 드리겠습니다.

#### 🔎 Backdoor

시스템에서 Backdoor가 실행될 경우, 악성 행위자는 Backdoor가 설치된 시스템에 마치 뒷문을 드나들 듯 인증 과정 또는 반드시 수행 해야하는 절차 없이 시스템의 핵심 명령 장치 등에 접근할 수 있게 됩니다.

Backdoor를 통해 악성 행위자는 웹캠을 통한 실시간 감시, 실시간 화면 녹화 또는 다른 악성 코드를 설치할 수 있게 되며, 내부망의 다른 대상으로 공격을 뻗쳐 나갈 수도 있게 됩니다.

악성 행위자는 Backdoor를 통해 과거에 장악했던 시스템에 대해서 다시 공격하여 장악할  수고를 덜 수 있을 뿐더러, 추가적인 공격으로 이어 나갈 수 있는 가능성 덕분에 많이 사용되고 있습니다.

소프트웨어나 제품에 기본적으로 탑재되는 형식의 Backdoor 공격 사례 또한 다수 존재합니다.

유명한 Backdoor로는 ["The Bvp47 - Equation Group"](https://www.pangulab.cn/en/post/the_bvp47_a_top-tier_backdoor_of_us_nsa_equation_group/), ["IPVM - Hikvision Backdoor Exploit"](https://ipvm.com/reports/hik-exploit), ["ES File Explorer Backdoor"](https://twitter.com/fs0c131y/status/1085460755313508352)가 있습니다.

#### 🔎 InfoStealer

시스템에서 InfoStealer가 실행될 경우 시스템에 저장되어 있는 문서, 비트코인 지갑, 패스워드 등 민감 정보를 추출하여 악성 행위자에게 전송합니다.

#### 🔎 Ransomware

Ransomware는 몸값이라는 뜻의 ransom과 software의 합성어로, Ransomware가 설치된 시스템의 파일들을 악성 행위자만이 알고 있는 패스워드로 암호화하고 인질로 만들어 피해자에게 금전을 요구하도록 유도하는 악성코드입니다.

Ransomware는 InfoStealer의 기능을 포함하기도 합니다.

최근에는 기업 대상 공격으로 - 핵심 기술 또는 데이터를 유출하겠다고 협박하며 추가적인 금전을 요구하는 형태로도 발전하고 있습니다.

또한, 랜섬웨어를 큰 노력 안들이며 만들어주고, 피해자를 관리하는 서비스를 제공하는 등 Ransomware as a Service(RaaS)의 형태로 랜섬웨어 조직은 확장되고 있습니다. 랜섬웨어를 이용하고자 하는 공격자는 랜섬웨어를 직접 제작할 필요 없이 일부 수익만 공유하면 손쉽게 공격에 랜섬웨어를 이용할 수 있습니다.

#### 🔎 Malware 참고 자료 (References)

- [Ahnlab ASEC](https://www.ahnlab.com/kr/site/securityinfo/securityinfoMain.do)
- [IGLOO, "2022년 사이버 보안위협에 따른 악성코드 패러다임"](https://www.igloo.co.kr/security-information/2022%eb%85%84-%ec%82%ac%ec%9d%b4%eb%b2%84-%eb%b3%b4%ec%95%88%ec%9c%84%ed%98%91%ec%97%90-%eb%94%b0%eb%a5%b8-%ec%95%85%ec%84%b1%ec%bd%94%eb%93%9c-%ed%8c%a8%eb%9f%ac%eb%8b%a4%ec%9e%84/)

### 🔎 CIA SAD

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/cia-sad-pag.jpg"><br>
    <i>CIA SAD/PAG</i>
</p>

"NITE Team 4"에서 언급한 SAD가 CIA의 SAD인지는 확실하지 않습니다.

하지만 미국의 중앙 정보국(Central Intelligence Agency, CIA)에는 특수 활동 부서(Special Activities Division, SAD)가 있으며, SAD의 정치적 작전 그룹(Political Action Group, PAG)의 주요 작전 범위에 사이버 전쟁이 포함되어 있습니다.

현재는 특수 활동 본부(Special Activities Center, SAC)라고 불리고 있습니다.

#### 🔎 CIA SAD 참고 자료 (References)

- [grey dynamics, "CIA Special Activities Center: The Third Option"](https://greydynamics.com/cia_special_activities_center)
- [Operation Military Kids, "CIA Speical Activities Division (SAD)"](https://www.operationmilitarykids.org/cia-special-activities-division-sad/#cia-branches)

### 🔎 Bureau 121 - 정찰총국 121국

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/sony-gop-hacked.webp"><br>
    <i>Sony Pictures 해킹 사건 당시 Sony Pictures의 웹사이트</i>
</p>

Bureau 121은 북한의 정찰총국 121국으로 불리며, 북한의 사이버 전쟁을 위한 집단입니다.
2014년 소니 픽쳐스 해킹의 배후로 잘 알려져 있습니다.

6,000명 이상의 인원으로 구성되어 있으며, 각 Andariel, Bluenoroff, Lazarus라고 불리는 악성 행위자 그룹이 121국에 속해 있는것으로 파악하고 있습니다. (2021)

121국의 악성 행위자들은 중국, 인도, 러시아, 벨라루스, 말레이시아와 같은 여러 국가들을 거점으로 활동하고 있는 것으로 알려져 있습니다.

#### 🔎 Bureau 121 참고 자료 (References)

- [U.S. Department of Health & Human Service, "North Korean Cyber Activity"](https://www.hhs.gov/sites/default/files/dprk-cyber-espionage.pdf)
- [Center for a New American Security, "Exposing the Financial Footprints of North Korea’s Hackers"](https://www.cnas.org/publications/reports/exposing-the-financial-footprints-of-north-koreas-hackers)

### 🔎 The Shadow Brokers Leak

2016년, "The Shadow Brokers" 해커 그룹이 "Equation Group" 해커 그룹을 해킹하여, 그들의 해킹 도구를 탈취하고, 경매에 부치고, 유출시킨 사건이 발생했습니다.

"Equation Group"은 이란의 우라늄 농축 시설 파괴를 목표로한 "Stuxnet" 악성코드를 개발하는 등 당시 최고의 기술력을 가지고 있는 해커 집단으로 잘 알려져 있었습니다.

또한, "Equation Group"은 미국 국가안보국(National Security Agency, NSA)의 TAO(Tailored Access Operations)가 "Equation Group"의 배후라고 생각되기도 합니다.

이 유출 사건으로 인해 "Equation Group"의 핵심 해킹 기술과 도구들이 대거 유출되고 악영되며 사회에 큰 파장을 일으켰습니다.

#### 🔎 The Shadow Brokers Leak 참고 자료 (References)

- [Wikipedia, "Equation Group"](https://en.wikipedia.org/wiki/Equation_Group)
- [Wikipedia, "The Shadow Brokers"](https://www.cnas.org/publications/reports/exposing-the-financial-footprints-of-north-koreas-hackers)
- [Wikipedia, "WannaCry"](https://en.wikipedia.org/wiki/WannaCry_ransomware_attack)

## Chapter 1, 브리핑

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-breifing.png"><br>
    <i>Chapter 1 브리핑</i>
</p>

**배경**

- "NITE Team 4"는 미정부와 협력하에 Turbine C2 Platform을 운영중이다.
- "Turbine C2 Platform"은 네트워크를 통해 다수의 implant를 관리하는 플랫폼이다.
- Malware가 implant(설치)되면, 자동으로 Turbine C2 Card의 형태로 플랫픔/시스템에 등록된다.
- 각각의 Turbine C2 Card는 관리되는 고유한 ID와 접근 권한 코드를 가지고 있다.

**상황**

- 4시간 전, BloodDove라는 멀웨어가 어떤 대상에 설치되어 식별되지 않은 ID를 통해 활성화된 것을 포착했다.
- 이 멀웨어는 현재 "NITE Team 4"에서 진행되고 있는 작전들과 아무런 연관성이 없는 것으로 파악된다.
- 따라서, 이 사건에 대하여 조사가 필요하다.

**목표**

- 미식별된 C2 card에 접근한다.
- 공유 디렉토리를 식별하고 접근 권한을 획득한다.
- BloodDove 멀웨어의 실제 위치를 파악한다.

### Turbine C2 Platform

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/turbine-c2.png"><br>
    <i>Turbine C2 Platform</i>
</p>

게임에서 Turbine C2 Platform을 통해 작전 대상 네트워크에 접근할 수 있습니다.

### 🔎 Command & Control (a.k.a C&C or C2)

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/c2-diagram.png"><br>
    <i>C2 Diagram</i>
</p>

공격자는 C2 서버를 공격의 경유지로 사용하거나, 멀웨어로 감염된 디바이스들을 원격에서 관리하는 등의 역할을 수행합니다.

현실에는 [Metasploit](https://www.metasploit.com/), [CobaltStrike](https://www.cobaltstrike.com/)와 같은 상용 침투 테스팅 도구에 포함되어 있거나, [오픈소스](https://github.com/tcostam/awesome-command-control)의 형태로도 존재합니다.

## Chapter 1, Workaround

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-1.png"><br>
    <i>Connected to OPERATION CASTLE IVY network.</i>
</p>

우선, 위와 같이 작전 대상 네트워크에 진입합니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-2.png"><br>
    <i>netscan result</i>
</p>

`Information Gathering Module -> WMI Scanner`를 실행 후, `netscan` 명령을 입력하여 현재 네트워크에서 접근 가능한 WMI path를 확인합니다.

WMI path 중, `/user/nlightman/c$`가 존재하는 것을 알 수 있는데, 이 문자열을 통해 다음과 같은 사실을 추측할 수 있습니다:

- 사용자 ID가 `nlightman`이다.
- `c$`는 `C:` 드라이브 오브젝트를 나타낸다.

따라서 해당 경로는 `nlightman` 사용자의 드라이브에 접근할 수 있는 WMI path일 가능성이 높습니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-3.png"><br>
    <i>password attack 1</i>
</p>

`Network Intrusion -> Password Attack`을 실행하고, 아까 확보한 경로와 아이디를 입력합니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-4.png"><br>
    <i>password attack 2</i>
</p>

여기서, `John The Ripper` 파라미터를 선택합니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-5.png"><br>
    <i>password attack 3</i>
</p>

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-6.png"><br>
    <i>password attack 4</i>
</p>

위와 같이 성공적으로 패스워드 공격을 수행했습니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-7.png"><br>
    <i>file browser connect 1</i>
</p>

`Data Forensic -> File Browser`를 실행 후, 아까 확보한 경로를 입력하고 연결을 시도합니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-8.png"><br>
    <i>file browser connect 2</i>
</p>

Password Attack 단계에서 확보한 계정의 패스워드를 입력하여 대상의 파일에 접근할 수 있습니다.

<p align="center">
    <img src="/assets/2023-03-19-nite-team-4-operation-castle-ivy-chapter-1/chapter1-9.png"><br>
    <i>file browser connect 3</i>
</p>

최종적으로 `BloodDove`와 함께, 다른 수상한 멀웨어들도 발견했습니다.

이후에는 지시에 따라 `uni74455.dll`을 다운로드 받으면 임무가 완료됩니다.

### 🔎 WMI scanner

WMI는 Windows Management Instrumentation라는 뜻의 Windows OS 관리 시스템입니다.

공격자는 WMI를 통해 내부망에서 장악한 시스템템 원격지의 윈도우 시스템의 취약점과 노출 부분을 파악하고, 침투한 시스템에서부터 공격을 확장하는 등에 사용할 수 있습니다.

게임에서는 단순히 `netscan`을 이용하여 현재 네트워크에 공격 가능한 지점이 어디 있는지 파악하는 용도로 사용할 수 있습니다.

### 🔎 Bruteforce 공격

무작위 대입 공격이라고도 부르는 Bruteforce 공격은 어떤 암호, 인증 등을 통과하기 위해 가능한 모든 키를 사용하여 대입해보는 아주 무식한 공격 기법 중 하나입니다.

무식해 보이는 Bruteforce 공격 기법에도 몇가지 방법들이 있는데요, 말 그대로 모든 가능한 값을 대입하는 방식, 사전(Dictionary)의 데이터를 하나씩 대입하는 이 두가지 방식이 대표적입니다.

### 🔎 John The Ripper

[John The Ripper](https://github.com/openwall/john)는 유명한 오픈소스 패스워드 해킹 툴입니다 - 정확히는 패스워드의 해쉬를 해킹하여 패스워드 원문을 알아내는 도구입니다.

패스워드를 시스템에 저장 할 때는 악의적인 의도를 가진 시스템 관리자, 개발자 또는 어떤 해킹이나 유출 사건으로부터 패스워드 원문을 보호하기 위해 해쉬 함수를 이용하여 고정된 길이의 (랜덤하게 보이는) 데이터로 변환시킵니다.

John The Ripper는 이 해쉬 함수를 통해 생성된 해쉬로부터 원문의 패스워드를 알아내도록 도와주는 도구입니다.

게임에서는 네트워크 서비스의 어떤 ID에 대응하는 패스워드를 bruteforce로 알아내기 위해 사용되는 사전(Dictionary)의 종류로 등장합니다.

### 🔎 rockyou.txt

RockYou라는 IT 서비스 업체가 해킹 공격을 당해 그 고객들의 패스워드가 원문으로 노출된 적 있습니다.

RockYou는 고객들의 패스워드를 원문(plain-text) 형태로 저장하여 그들의 시스템에서 사용하였으며, 이것이 유출된 것입니다.

총 3200만개 가량의 패스워드가 유출 되었으며, 공격자들은 이 데이터셋을 bruteforcing 공격에 종종 이용하고는 합니다.

## Closing

"NITE Team 4"를 통해 해킹의 가장 기본적인 도구와 개념들에 대해 알아볼 수 있었습니다.

Chapter 2에서는 XKeyScore, Phone CID Backdoor와 같은 복잡하고 높은 기술력을 필요로하는 도구들에 대해 설명드릴 예정입니다. 특히 XKeyScore의 경우, 실제로 NSA에서 사용하던 감시체계의 이름이기도 합니다.

혹시 "NITE Team 4"를 이미 플레이 해 보신 분은 [TryHackMe](https://tryhackme.com/), [HackTheBox](https://www.hackthebox.com/)와 같은 플랫폼에서 실전 해킹을 탐구하고 연습 해 보셔도 좋겠네요.

이 포스팅은 시리즈로 이어집니다! 여러분의 많은 관심 부탁드립니다 :)

