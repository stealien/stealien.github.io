---
layout: post
markdown: kramdown
highlighter: rouge
title: "IoT 보안의 시작, 펌웨어 분석 이야기 1부"
date: 2025-04-22 14:00:0 +0900
category: R&D
author: 김도환, 조준형
author_email: dhkim2@stealien.com, jhjo@stealien.com
background: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary: "IoT 보안의 시작, 펌웨어 분석 이야기 1부"
thumbnail: /assets/stealien.png
lang: ko
---

# IoT 보안의 시작, 펌웨어 분석 이야기 1부

> 본 포스팅은 스틸리언 선제대응팀의 '김도환' 선임 연구원과 '조준형' 연구원의 IoT 분석 경험을 기반으로 작성되었습니다.
> 

---
## 목차

- [소개](#소개)
    -  [IoT 해킹과 펌웨어 분석의 중요성](#iot-해킹과-펌웨어-분석의-중요성)
    - [펌웨어(Firmware)란?](#펌웨어firmware란)
    - [펌웨어의 전체 구조](#펌웨어의-전체-구조)
    - [펌웨어 추출 방법](#펌웨어-추출-방법)
    - [주요 도구](#주요-도구)
- [제조사 제공](#제조사-제공)
    - [공식 경로로 펌웨어 받기](#공식-경로로-펌웨어-받기)
    - [펌웨어 분석 도구 – Binwalk](#펌웨어-분석-도구--binwalk)
    - [부트로더(bootloader)는 포함되지 않는 이유](#부트로더bootloader는-포함되지-않는-이유)
- [UART](#uart)
    - [연결](#연결)
        - [홀 또는 핀이 표기가 되어있는 경우](#홀-또는-핀이-표기가-되어있는-경우)
        - [홀 또는 핀이 표기가 되어있지 않은 경우](#홀-또는-핀이-표기가-되어있지-않은-경우)
    - [추출](#추출)
        - [메모리 덤프 (Bootloader 단계)](#메모리-덤프-bootloader-단계)
        - [직접 획득 (OS Shell)](#직접-획득-os-shell)
- [결론](#결론)
---

# 소개

##  IoT 해킹과 펌웨어 분석의 중요성

IoT(Internet of Things)는 사물 간 인터넷 연결을 통해 데이터를 주고받는 기술로, 다양한 기기들이 일상 속에 깊이 침투해 있습니다. 이러한 IoT 기기가 해킹될 경우 **제어권 탈취**나 **개인 정보 유출**과 같은 심각한 피해로 이어질 수 있습니다.

IoT 해킹은 일반적으로 다음과 같은 흐름으로 진행됩니다:

![[그림 1.] IoT 해킹 과정](/assets/2025-04-22-IoT-Firmware/IoT.hack.png)

[그림 1.] IoT 해킹 과정

이 과정에서 **펌웨어 획득은 핵심적인 시작점**입니다. 펌웨어는 IoT 기기의 동작 로직과 구성 정보를 담고 있기 때문에, 이를 확보하고 분석함으로써 내부 구조를 이해하고 보안 취약점을 효과적으로 찾아낼 수 있습니다.

결과적으로, 우리가 펌웨어에 집중하는 이유는 **IoT 해킹을 가능하게 만드는 실질적 기반 분석이 바로 펌웨어에 있기 때문**입니다.

## 펌웨어(Firmware)란?

펌웨어(firmware)는 **하드웨어 장치에 포함된 소프트웨어**로, 하드웨어의 기본적인 동작을 제어하는 역할을 하기때문에 소프트웨어와 하드웨어의 성질을 모두 가진다고 할 수 있습니다. 또한 다른 소프트웨어보다 우선적으로 하드웨어를 제어할 수 있는 소프트웨어 입니다.

##  펌웨어의 전체 구조

![[그림 2.] 펌웨어 구조](/assets/2025-04-22-IoT-Firmware/firmware.png)

[그림 2.] 펌웨어 구조

###  각 구성 요소 설명

| **구성 요소** | **설명** |
| --- | --- |
| **Header** | 펌웨어 이미지의 가장 앞 부분에 존재. 전체 구조에 대한 **Metadata** 포함 (예: 전체 길이, 각 파티션의 위치, Checksum, 버전 정보 등). 분석 시 포맷을 이해하는 데 매우 중요. |
| **Bootloader** | 시스템 부팅 시 가장 먼저 실행. Kernel을 메모리로 불러오고, RootFS 적재. 대표적으로 **U-Boot**, **RedBoot** 등이 사용. |
| **Kernel** | 리눅스 기반의 OS Kernel이 대부분. 메모리, 파일 시스템, 장치 드라이버 등을 제어. `zImage`, `uImage` 등으로 존재. |
| **Root File System (RootFS)** | 기기 내부 프로그램과 설정 파일들이 위치. `/bin`, `/etc`, `/lib` 등 리눅스 디렉토리 구조로 구성. 보통 `squashfs`, `cramfs` 같은 읽기 전용 압축 파일 시스템 사용. |

이처럼 펌웨어는 **Header, Bootloader, Kernel, RootFS** 등으로 구성되어 있으며, 각각의 구성 요소는 **IoT 기기의 동작과 보안에 핵심적인 역할**을 합니다. [4]

펌웨어는 바이너리 형태로 저장되어 있고, 기기 제조사 또한 펌웨어에 관한 내용을 공개하지 않으므로, 펌웨어 분석을 위해서는 펌웨어 추출 과정이 우선으로 수행되어야 합니다.

## 펌웨어 추출 방법

1. **제조사 제공**
    - 공식 홈페이지에서 펌웨어 업데이트 파일을 다운로드
    - 고객지원 채널을 통한 이메일 요청 등
2. **하드웨어 기반 추출**
    - **UART(시리얼 통신)**:  기기의 UART 핀에 접근해 시스템 콘솔을 열고 직접 추출
    - **FlashROM**:  납땜 또는 테스트 클립 방식으로 메모리 칩을 직접 읽어 펌웨어를 추출

##  주요 도구

| **도구/장비** | **설명** | **지원 운영 체제** |
| --- | --- | --- |
| **Binwalk** | 펌웨어 파일의 구조를 분석하고 섹션을 자동으로 분리하는 분석 도구 | Linux, macOS, Windows (WSL) |
| **USB to TTL 장치** | UART 통신을 가능하게 해주는 장치로, 기기의 UART 핀과 PC를 연결 | Windows, Linux, macOS |

# 제조사 제공

##  공식 경로로 펌웨어 받기

펌웨어를 획득하는 가장 간단하고 안정적인 방법은 **제조사 공식 홈페이지를 통해 기기 별로 제공되는 펌웨어 파일을 직접 다운로드**하는 것입니다.

국내에서 널리 사용되고 있는 **EFM 네트웍스의 ipTIME** 공유기는 공식 웹사이트를 통해 각 모델에 대한 펌웨어를 제공하고 있습니다.

[ipTIME 펌웨어 다운로드 링크](https://iptime.com/iptime/?pageid=1&page_id=126)

![[그림 3.] EFM 네트웍스에서 제공하는 ipTime 공유기 펌웨어 목록](/assets/2025-04-22-IoT-Firmware/firmware.list.png)

[그림 3.] EFM 네트웍스에서 제공하는 ipTime 공유기 펌웨어 목록

##  펌웨어 분석 도구 – Binwalk

펌웨어를 다운로드한 후, 내부 파일 시스템을 추출하고 분석하기 위해 **Binwalk** 라는 도구를 사용합니다.

**Binwalk**는 바이너리 파일 내부에 숨겨진 파일 시그니처(Signature)를 식별해

- 파일 시스템 이미지
- 압축 파일
- 임베디드 리소스

등을 찾아내는 강력한 분석 도구입니다. [2]

주로 임베디드 시스템의 펌웨어 분석에 사용되며, 파일 시스템 구조 파악에 유용합니다.

###  주요 명령어

- 펌웨어 분석
    
    ```bash
    binwalk <타겟 파일명>
    ```
    
- 자동 추출
    
    ```bash
    binwalk -e <타겟 파일명>
    ```
    

분석 결과 예시는 다음과 같습니다.

![[그림 4.] Binwalk 활용한 분석 예](/assets/2025-04-22-IoT-Firmware/binwalk.example.png)

[그림 4.] Binwalk 활용한 분석 예

## 부트로더(bootloader)는 포함되지 않는 이유

제조사에서 제공하는 펌웨어는 **주로 시스템 업데이트용**으로, 일반적으로 **Bootloader는 포함되지 않습니다.**

- 펌웨어 업데이트는 안정성을 위해 **Kernel과 RootFS만 교체**하도록 구성
- Bootloader는 초기 부팅을 담당하는 핵심 구성 요소로, **손상 시 복구가 어려움**
- 따라서 제조사는 Bootloader를 업데이트 범위에서 제외하여 **시스템 안전성을 확보**

---

이처럼 제조사 제공 펌웨어는 분석을 시작하기에 가장 접근하기 쉬운 자료이며, 이후 **Binwalk**와 같은 도구를 활용해 내부 구조를 정밀하게 분석할 수 있습니다.

# UART

UART(Universal Asynchronous Receiver/Transmitter)는 비동기 방식의 직렬 통신 인터페이스로, 임베디드 시스템 및 IoT 기기에서 널리 사용되는 디버깅 및 데이터 전송 수단입니다.

UART는 일반적으로 **TX(Transmit), RX(Receive), GND(Ground)** 세 가지 라인을 통해 통신하며, 콘솔 접근 및 펌웨어 추출, 부트로더 제어 등에 활용됩니다.

이 장에서는 **UART 인터페이스를 이용하여 펌웨어를 획득하기 위한 연결 방식과 데이터 추출 방법**에 대해 설명합니다.

##  연결

### 홀 또는 핀이 표기가 되어있는 경우

기판 상에 **UART 포트의 TX, RX, GND 핀이 실크로 인쇄**되어 있는 경우, 비교적 쉽게 연결이 가능합니다.

![[그림 5.] UART Hole](/assets/2025-04-22-IoT-Firmware/UART.hole.png)

[그림 5.] UART Hole

UART 연결 시 주의할 점은, **정상적인 데이터 송수신을 위해 TX(Transmit)와 RX(Receive) 라인을 교차로 연결해야 한다는 것**입니다.

![[그림 6.] RX TX 교차 연결](/assets/2025-04-22-IoT-Firmware/UART.rx.tx.png)

[그림 6.] RX TX 교차 연결

즉, 분석 장비의 TX(Transmit)는 대상 장비의 RX(Receive)에, 분석 장비의 RX(Receive)는 대상 장비의 TX(Transmit)에 연결해야 하며, 이를 통해 양방향 통신이 원활하게 이루어질 수 있습니다.

또한 UART 통신은 일반적으로 **대상 장비가 자체적으로 전원을 공급 받는 상태에서 수행**되므로, **전압 공급의 중복으로 인한 손상을 방지하기 위해 VCC는 연결하지 않고**, **TX, RX, GND 세 핀만 연결하는 것이 안전합니다.**

![[그림 7.] USB to TTL](/assets/2025-04-22-IoT-Firmware/UART.usb.png)

[그림 7.] USB to TTL
 
![[그림 8.] USB to TTL UART 연결](/assets/2025-04-22-IoT-Firmware/UART.usb2.png)

[그림 8.] USB to TTL UART 연결

USB to TTL 컨버터와 **젠더형 점퍼선(또는 암-수 점퍼선) 3개**를 준비하였으며, **PuTTY의 Serial 연결 기능**을 이용하여 통신합니다.

![[그림 9.] Putty Serial 연결](/assets/2025-04-22-IoT-Firmware/putty.png)

[그림 9.] Putty Serial 연결

PuTTY를 사용하여 Serial로 접속할 경우, 먼저 USB 포트에 연결된 Serial 포트 번호(Serial Line)를 확인한 후, 기기에 맞는 통신 속도(Baud Rate)를 설정하여 접속해야 합니다.

일반적으로 사용하는 Baud Rate는 115200bps이며, 이는 기기 사양에 따라 다를 수 있습니다.

![[그림 10.] U-Boot console](/assets/2025-04-22-IoT-Firmware/bootloader_shell.jpg)

[그림 10.] U-Boot console

### 홀 또는 핀이 표기가 되어있지 않은 경우

기기를 분석하다 보면, **UART 핀이나 홀이 표기되지 않은 PCB 기판**을 접하게 되는 경우가 있습니다.

이러한 경우에는 단순히 육안으로 UART 위치를 식별할 수 없기 때문에, **기판의 회로를 직접 추적하거나 신호 분석 도구를 활용하여 UART 라인을 찾아내야 합니다.**

아래 PCB 예시를 보면, 일반적인 경우와 달리 **TX, RX와 같은 UART 핀 이름 표기나 전용 홀이 존재하지 않는 것**을 확인할 수 있습니다.

이처럼 핀 정보가 명확히 드러나지 않는 경우, **테스트 포인트 분석, IC 주변 라우팅 확인, 전압 측정, 로직 애널라이저 등을 활용한 수동적인 식별 작업**이 필요합니다.

![[그림 11.] UART 홀 또는 핀이 없는 PCB 기판](/assets/2025-04-22-IoT-Firmware/UART.pcb.png)

[그림 11.] UART 홀 또는 핀이 없는 PCB 기판

이처럼 일부 제조사의 경우, **UART 포트가 명시적으로 표시되지 않거나**, 디버깅을 방지하기 위해 **의도적으로 숨겨져 있는 경우**도 존재합니다. 이러한 상황에서는 기판 상에 형성된 **작은 패드(Pad)** 또는 홀(Hole)을 통해 UART 신호 라인을 추적해야 합니다.

이를 위해서는 먼저, 해당 기기에 탑재된 SoC(System on Chip)의 데이터시트(Data Sheet)를 확인하는 것이 중요합니다. 데이터시트에는 UART 인터페이스가 연결되는 **핀 번호(Pinout)** 및 **기본 입출력 기능(IO configuration)** 정보가 포함되어 있어, UART 라인의 후보를 좁히고 PCB 상의 경로를 추적하는 데 핵심적인 참고 자료로 활용됩니다.

![[그림 12.] RTL8197FH Pinmap](/assets/2025-04-22-IoT-Firmware/UART.pinmap.png)

[그림 12.] RTL8197FH Pinmap

UART의 TX(Transmit) 및 RX(Receive) 핀 위치를 특정한 후에는, 해당 핀에서 PCB 상으로 이어지는 회로(트레이스, Trace)를 추적하여, 외부에서 접근 가능한 패드(Pad)나 홀(Hole)을 식별하는 과정이 필요합니다.

이러한 트레이스 추적은 보통 다음과 같은 순서로 진행됩니다:

1. 해당 핀에서 시작되는 트레이스를 육안 또는 확대경, 멀티미터(도통 테스트)를 이용해 **기판 상의 경로를 따라가며 분석**합니다.
2. 트레이스가 도달하는 끝지점에서 **테스트 포인트 형태의 노출된 패드나 홀**, 또는 **실크 없이 배치된 납땜 포인트**를 찾아냅니다.
3. 이 위치에 **USB to TTL 컨버터를 이용한 연결 시도**를 통해 실제 UART 신호가 나오는지 확인합니다.

이러한 방식은 **UART 포트가 숨겨져 있거나 명시되지 않은 경우**에도 UART 인터페이스를 찾아내기 위한 실질적인 분석 기법이며, 하드웨어 리버스 엔지니어링에서 자주 활용되는 절차입니다.

![[그림 13.] 확대경으로 기판 상 경로 분석 #1](/assets/2025-04-22-IoT-Firmware/UART.trace1.png)

[그림 13.] 확대경으로 기판 상 경로 분석 #1

![[그림 14.] 확대경으로 기판 상 경로 분석 #2](/assets/2025-04-22-IoT-Firmware/UART.trace2.png)

[그림 14.] 확대경으로 기판 상 경로 분석 #2

![[그림 15.] 확대경으로 기판상 경로 분석 #3](/assets/2025-04-22-IoT-Firmware/UART.trace3.png)

[그림 15.] 확대경으로 기판상 경로 분석 #3

이 과정을 통해 식별한 **두 개의 패드에 대해 멀티미터를 이용한 도통(Continuity) 테스트 및 전압 측정**을 수행한 결과, 각각이 **TX(Transmit)와 RX(Receive)** 신호 라인에 해당함을 확인할 수 있었습니다. [3]

![[그림 16.] UART 핀 연결 ](/assets/2025-04-22-IoT-Firmware/pcbite.jpg)

[그림 16.] UART 핀 연결 

이를 기반으로 USB to TTL 컨버터를 이용한 **UART 통신 환경을 구성**하였고 시리얼 통신 프로그램(PuTTY 등)을 통해 기기 콘솔에 접근하는 데 성공하여 **UART 기반의 시스템 분석을 본격적으로 진행할 수 있는 기반을 마련**하였습니다.

이와 같은 절차는 UART 포트가 외부에 드러나 있지 않거나 식별되지 않은 기기에서도 **직접적인 하드웨어 분석을 통해 UART 인터페이스를 복원하고 내부 시스템에 접근할 수 있는 실질적인 방법**으로 활용됩니다.

## 추출

UART 연결을 통해 기기와의 통신이 가능해졌다면, 다음 단계로는 **펌웨어 내부 데이터를 추출**하는 과정이 필요합니다. 펌웨어를 추출하는 이유는 단순히 기기와 연결된 것만으로는 **시스템의 구조, 설정, 보안 메커니즘 등을 충분히 이해할 수 없기 때문**입니다.

따라서 펌웨어 이미지 전체 또는 일부를 **기기에서 외부로 가져와 분석 가능한 상태로 확보**해야 합니다.

UART를 통한 펌웨어 추출 방식은 기기의 상태에 따라 다음 두 가지로 구분됩니다.

1. **메모리 덤프 (Bootloader 단계)**
2. **직접 획득 (OS Shell 단계)**

이처럼 펌웨어 추출은 **기기 내부 구조를 확인하고 보안 분석을 수행하기 위한 핵심 절차**이며, 단순한 연결 성공 이후에도 반드시 수행되어야 할 중요한 분석 단계입니다.

### 메모리 덤프 (Bootloader 단계)

메모리 덤프(Bootloader)는 부팅 초기에 UART 콘솔을 통해 Bootloader(U-Boot 등)에 접근할 수 있다면, Bootloader의 명령어를 이용해 **지정된 메모리 영역을 직접 읽고 외부로 덤프**하는 방식입니다. 이 방식은 운영체제가 올라오기 전 단계에서 **보다 저수준 접근이 가능**하다는 장점이 있습니다.

메모리 덤프 단계에서도 Bootloader의 Shell로 접근해야 가능하며, 상위 기기의 Bootloader Shell을 획득하면 다음 사진과 같습니다.

![[그림 17.] Bootloader Shell](/assets/2025-04-22-IoT-Firmware/bootloader_shell2.png)

[그림 17.] Bootloader Shell

Bootloader의 Shell을 확보했다면, 사용 가능한 명령어 중에서 메모리 덤프와 관련된 명령어(`md`, `nand`, `read` 등)를 찾아낸 후 이를 통해 펌웨어를 추출할 수 있습니다.

### 직접 획득 (OS Shell)

직접 획득(OS Shell)은 시스템이 부팅된 이후, UART 콘솔을 통해 Root Shell 또는 제한된 CLI 환경에 접근할 수 있다면, **내장된 명령어를 통해 파일 시스템 또는 저장 장치의 특정 파티션을 직접 추출**하는 방식입니다.

`/proc/mtd`를 통해 파티션 정보를 확인한 뒤 `dd` 명령어로 펌웨어 이미지를 덤프할 수 있습니다.

![[그림 18.] 파티션 정보 (/proc/mtd)](/assets/2025-04-22-IoT-Firmware/partition.png)

[그림 18.] 파티션 정보 (/proc/mtd)

Bootloader 영역을 추출하고자 할 경우, `dd` 명령어를 사용하여 **해당 메모리 블록을 파일 형태로 덤프**할 수 있습니다. [5]

이때 `if=`는 **input file**을 의미하며, 추출 대상인 메모리 디바이스 경로를 지정하고, `of=`는 **output file**로 덤프한 데이터를 저장할 경로를 의미합니다. 또한 `bs`는 **block size**를 의미하며, 한 번에 읽어올 데이터의 크기를 설정합니다.

예시 명령어는 다음과 같습니다

```bash
dd if=/dev/mtd0 of=/tmp/bootloader.bin bs=1M
```

위 명령어는 `/dev/mtd0`에 마운트된 부트로더 영역을 1MB 단위로 읽어 `/tmp/bootloader.bin`에 저장하는 작업을 수행합니다. (MTD 번호는 시스템에 따라 다를 수 있으므로, `/proc/mtd` 또는 `/proc/partitions`  통해 확인이 필요합니다.)

펌웨어 덤프가 완료된 후에는 다음과 같은 방식으로 분석 장비로 복사할 수 있습니다:

- **네트워크 전송 도구**: `nc`(netcat), `scp`, `tftp` 등을 활용하여 로컬 머신으로 전송
- **USB 저장장치**: 기기가 USB OTG 또는 저장장치 마운트를 지원하는 경우 직접 복사

이후 확보한 펌웨어 파일을 기반으로, `binwalk`, `firmwalker` 등의 도구를 활용해 **파일 시스템 구조 분석**, **설정 파일 검색**, **취약점 분석** 등의 정적 분석을 진행할 수 있습니다.

# 결론

소개한 기술은 단순한 장비 조작을 넘어서, **IoT 기기의 내부 동작 원리를 이해하고, 시스템 보안 상태를 정확히 진단할 수 있는 기반 기술**입니다.
특히 제조사로부터 펌웨어가 제공되지 않거나 내부 구조가 문서화되어 있지 않은 경우, **직접 기기를 분석하고 펌웨어를 획득해 구조를 파악하는 기술이 필수적입니다.**

본 포스팅에서 설명한 일련의 절차와 기술들은 **실제 현장에서의 보안 진단, 침해 대응, 취약점 발굴 등 다양한 보안 업무에서 실질적인 효용성을 가지며**, IoT 보안 연구 및 실무 대응을 위한 **기초이자 핵심 도구**로 활용될 수 있습니다.

다음 2부에서는 플래시 메모리를 통해 직접 펌웨어를 추출하는 방식을 소개 하고자 합니다.

감사합니다
---

[참고 문헌]

- [1] Wikipedia, *”펌웨어”*([https://ko.wikipedia.org/wiki/펌웨어](https://ko.wikipedia.org/wiki/%ED%8E%8C%EC%9B%A8%EC%96%B4))
- [2] ReFirm Labs, ”*binwalk: Firmware analysis tool”*([https://www.kali.org/tools/binwalk/](https://www.kali.org/tools/binwalk/))
- [3] 78ResearchLab, ”*펌웨어 추출 방법”*([https://blog.78researchlab.com/56a2ef92-05c6-44fc-8436-8f00dbc6c087](https://blog.78researchlab.com/56a2ef92-05c6-44fc-8436-8f00dbc6c087))
- [4] ResearchGate , ”*Structure of general-purpose IoT devices*.”, Jan 2021 ([https://www.researchgate.net/figure/Structure-of-general-purpose-IoT-devices_fig1_353468054](https://www.researchgate.net/figure/Structure-of-general-purpose-IoT-devices_fig1_353468054))
- [5] HackerSchool ,”*Embedded System의 Firmware 획득하기*.” ([https://www.hackerschool.org/HardwareHacking/Embedded System의 Firmware 획득하기.pdf](https://www.hackerschool.org/HardwareHacking/Embedded%20System%EC%9D%98%20Firmware%20%ED%9A%8D%EB%93%9D%ED%95%98%EA%B8%B0.pdf))
