---
layout: post
markdown: kramdown
highlighter: rouge
title: "뉴비들의 하드웨어 해킹 입문기"
date: 2024-02-06 10:00:0 +0900
category: R&D
author: 이주협, 이주영
author_email: jhlee2@stealien.com, jylee3@stealien.com
background: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary: "뉴비들의 하드웨어 해킹 입문기"
thumbnail: /assets/stealien.png
lang: ko
---

# 뉴비들의 하드웨어 해킹 입문기

> 이 포스트는 스틸리언 선제대응팀의 '이주협' 선임 연구원님과 '이주영' 연구원님이 정성스럽게 작성 해 주셨습니다.
>
> 선제대응팀(Team Defend Forward)은 IoT, 임베디드 디바이스, 네트워크 디바이스같은 장비의 취약점 분석은 물론이고,
> 모바일 디바이스 어플리케이션, 웹 서비스/어플리케이션, 데스크탑/서버 어플리케이션/서비스 등 다양한 소프트웨어에 대한
> 화이트박스/블랙박스 펜테스팅 서비스를 제공하고 있습니다.
>
> by 선제대응팀 팀장 김도현

## 목차

- UART
  - 필요한 장비 정리
  - 메인 칩셋 데이터 시트 참고하는 법
- Desoldering
- FlashROM을 통한 펌웨어 추출
- 펌웨어 조작 - 쉘 떨구기
- Soldering
- Glitching
  - Serial Data Output Pin Glitching

## 1. 인트로

> 본 블로그 포스트는 SPI를 사용하는 Router의 하드웨어 해킹을 기준 해 작성했습니다. 라우터의 구현에 따른 한가지 방법일 뿐, 일반적으로 통용되는 하드웨어 해킹 방법론이 아님을 명시합니다.

## 2. UART

![UART drawio](/assets/2024-02-06-IoT-TechBlog/UART.drawio.png)

UART(Universal Asynchronous Receiver/Transmitter)는 두 하드웨어 기기가 서로 Serial 통신할 때 사용하는 프로토콜입니다. 주로 하드웨어 개발자들이 디버깅 용도로 사용합니다.

### 2.1. UART를 사용하는 이유

경우에 따라 다르지만 UART로 Login Prompt 또는 OS Shell을 제공하는 하드웨어 기기가 있습니다. 하드웨어 기기의 쉘에 접근하면 기기 내에 동작하는 프로세스를 확인하거나 gdb와 같은 디버거를 원격으로 업로드하여 프로세스를 직접 디버깅하는 등의 분석을 수행할 수 있습니다.

UART로 쉘을 제공하지 않더라도 부팅 로그를 출력하는 경우도 있습니다. 이 경우, 부팅 로그에 펌웨어 복호화 키와 같은 민감한 정보가 포함되어 있을 수 있습니다. 따라서 하드웨어 기기의 UART를 확인해야 하는 근거는 충분합니다.

### 2.2. UART 연결 준비

UART 연결에 필요한 장비는 다음과 같습니다.

| 장비                  | 역할                                                        |
| --------------------- | ----------------------------------------------------------- |
| USB to TTL            | 기기의 UART와 PC 간 시리얼 통신을 위한 USB Converter        |
| 점퍼 케이블(optional) | USB to TTL과 기기의 UART 핀을 연결하는 케이블               |
| MultiMeter            | 전기 및 전자 장비의 전압, 전류, 저항 등을 측정하는 테스트기 |

### 2.2.1. UART의 종류

UART에 연결하기 전 기기마다 가질 수 있는 UART 형태의 종류를 알아보겠습니다.

![ipTIME N704VS router UART PIN](/assets/2024-02-06-IoT-TechBlog/ipTIME_N704VS_UART.jpg)

ipTIME N704VS router UART PIN

ipTIME N704VS 라우터의 경우, UART에 핀 헤더가 연결되어 있기 때문에 각 핀의 역할만 찾으면 바로 USB to TTL과 연결하여 Serial 통신이 가능합니다.

![Netis router UART PIN](/assets/2024-02-06-IoT-TechBlog/Netis_UART.jpg)

Netis router UART PIN

Netis 라우터의 UART 핀입니다. 대부분의 UART 핀은 위 사진과 같이 4개의 패드로 존재합니다. 이러한 경우 암-수 점퍼 케이블을 연결하거나, 홀에 헤더핀을 납땜하여 암-암 점퍼케이블로 USB to TTL과 연결할 수 있습니다.

### 2.2.2. 점퍼 케이블 종류

점퍼 케이블의 종류는 다음과 같습니다.

| 케이블 명         | 설명                                                               |
| ----------------- | ------------------------------------------------------------------ |
| 암-암 점퍼 케이블 | 케이블 헤더에 핀이 존재하지 않아 UART 핀과 탈부착할 수 있는 케이블 |
| 암-수 점퍼 케이블 | 케이블의 한쪽 헤더에만 핀이 고정 되어있는 케이블                   |
| 수-수 점퍼 케이블 | 케이블의 양쪽 헤더에 핀이 고정 되어있는 케이블                     |

일반 USB to TTL은 별도의 암-수 점퍼 케이블이나 암-암 점퍼 케이블과 핀 헤더가 필요합니다.

케이블 일체형 USB to TTL은 암-암 점퍼 케이블이 내장되어 있어 별도의 암-암 점퍼 케이블 없이도 UART 핀에 연결할 수 있습니다. 각 UART 핀의 역할을 점퍼 케이블의 색깔로 구분하여 연결합니다.

### 2.2.3. UART Pin의 종류

![UART Pin drawio](/assets/2024-02-06-IoT-TechBlog/UART_Pin.drawio.png)

UART 핀의 각 역할은 다음과 같습니다.

| UART 핀 | 역할                                |
| ------- | ----------------------------------- |
| GND     | 메인 보드의 기준 전압을 맞춰주는 핀 |
| TX      | 시리얼 데이터를 송신하는 핀         |
| RX      | 시리얼 데이터를 수신하는 핀         |
| VCC     | 전원을 공급하는 핀                  |

하드웨어 기기에 전원 케이블을 통해서 전원 공급이 가능하다면 VCC 핀은 연결하지 않습니다.

UART 핀의 역할을 알아보았으니 각 UART 핀을 식별해 봅시다.

## 2.3. UART PIN 식별

### 2.3.1. UART GND PIN 식별

UART의 GND 핀은 멀티미터를 통해 찾을 수 있습니다. 멀티미터의 Conductivity 모드는 전기회로가 서로 연결 되어있을 때 부저음을 출력합니다. PCB[^1]에서 SPI Flash 칩의 GND 핀과 UART의 GND 핀은 연결되어 있습니다.

따라서 SPI Flash 칩의 GND 핀 위치를 찾고 각 UART 핀과 한번씩 연결해보는 방식으로 부저음을 통해서 UART의 GND 핀을 찾을 수 있습니다.

**(1) SPI Flash Chip GND PIN → UART GND PIN**

SPI Flash 칩에서 GND 핀 위치는 데이터 시트를 통해 찾을 수 있습니다. SPI Flash 칩의 모델명을 확인하여 데이터 시트를 검색합니다.

![SPI Flash chip](/assets/2024-02-06-IoT-TechBlog/flashchip.jpg)

![SPI Flash chip datasheet](/assets/2024-02-06-IoT-TechBlog/flashchip_datasheet.png)

![SPI Flash chip datasheet table](/assets/2024-02-06-IoT-TechBlog/flashchip_datasheet_table.png)

데이터 시트를 통해 SPI Flash 칩의 GND 핀은 점을 기준으로 4번째 핀인 VSS 핀임을 알 수 있습니다.

이제 UART의 GND 핀을 식별해봅시다. 기기에 전원을 공급하지 않은 상태에서, 멀티미터를 Conductivity 모드로 설정합니다.

![conductivity mode](/assets/2024-02-06-IoT-TechBlog/conductivity_mode.jpg)

멀티미터의 검은 리드선[^2]을 SPI Flash 칩의 GND 핀에 고정한 상태에서 빨간 리드선을 각 UART 핀에 한번씩 연결합니다.

**(2) Other Method**

데이터시트를 찾지 못한 이유로 SPI Flash 칩의 GND 핀 위치를 찾지 못할 수 있습니다. 해당 경우에는 멀티미터의 검은 리드선을 PCB의 구리 홀에 연결하고, 빨간 리드선을 각 UART 핀에 한번씩 연결하여 UART의 GND 핀을 찾을 수 있습니다.

### 2.3.2. TX & RX 식별

**(1) MCU와 UART의 단락 상태 검사**

UART의 TX, RX핀은 MCU의 TX와 RX 핀과 연결되어 있습니다. 이를 이용해서 MCU의 TX와 RX 핀을 찾고 멀티미터 Conductivity 모드로 UART의 TX와 RX 핀을 찾을 수 있습니다.

![mcu](/assets/2024-02-06-IoT-TechBlog/mcu.jpg)

경우에 따라 MCU 위에 방열판이 덮고 있을 수 있습니다. MCU를 덮고 있는 방열판을 제거하고 MCU 칩 정보를 확인하여 데이터 시트를 검색합니다:

![mcu datasheet](/assets/2024-02-06-IoT-TechBlog/mcu_datasheet.png)

![mcu datasheet table](/assets/2024-02-06-IoT-TechBlog/mcu_datasheet_table.png)

UART 핀은 125번 핀과 126번 핀입니다. MCU의 기준점(사진의 빨간 동그라미)을 바탕으로 125번, 126번 핀의 실제 위치를 찾을 수 있습니다.

![mcu highlighted](/assets/2024-02-06-IoT-TechBlog/mcu_highlighted.jpg)

이제 기기에 전원을 공급하지 않은 상태에서 멀티미터를 Conductivity 모드로 설정합니다. 검은색 리드선을 MCU의 RX에 고정하고 빨간색 리드선을 각 UART 핀에 연결했을 때, 부저음을 출력하는 핀이 UART의 RX 핀입니다. TX도 같은 방식으로 식별해봅시다.

**(2) 핀의 전압, 전류 측정**

이번에는 MCU의 데이터시트가 없어 RX와 TX를 찾지 못한 경우에 UART의 RX와 TX 핀을 식별할 수 있는 방법을 사용해봅시다.

멀티미터를 DCV(직류전압) 모드로 설정한 후 검은색 프로브를 COM 단자, 빨간색 프로브를 V-Ω 단자에 연결합니다. 기기에 전원을 공급한 후, 검은색 리드선을 기기의 GND와 접촉하고, 빨간색 리드선은 식별하고자 하는 UART핀과 접촉하여 전압을 측정합니다.

![dcv](/assets/2024-02-06-IoT-TechBlog/dcv.jpg)

일반적으로 전압이 2.4V ~ 3.3V 사이를 지속적으로 변한다면 TX 핀, 전압이 0.0V이면 RX 핀입니다. TX 핀은 다양한 데이터를 송신하기 때문에 2.4V ~ 3.3V 사이에서 전압이 지속적으로 변합니다. RX 핀은 송신 행위 없이 데이터를 수신하는 역할만 수행하기 때문에 0.0V의 전압을 띄고 있습니다. 하지만 전원이 들어온 상태에서 TX와 RX의 전압을 측정할 때 노이즈가 발생하므로 경우에 따라 UART의 TX와 RX 전압이 거의 동일하게 측정됩니다.

전압으로 TX와 RX를 구분할 수 없는 경우라면 전류를 측정하여 구분해봅니다. 멀티미터를 DCA(직류 전압) 모드로 설정한 후 검은색 프로브는 COM 단자에, 빨간색 프로브는 전류측정단자(~mA)에 연결합니다. 검은색 리드선은 기기의 GND와 접촉하고 빨간색 리드선은 식별대상 UART 핀에 접촉합니다. 기기에 전원을 공급한 후 측정되는 전류를 관찰합니다. 일반적으로 VCC, GND, RX는 전류가 흐르지 않고(0mA) TX의 경우에만 23mA~44mA 사이의 전류가 흐르고 있습니다.

| mode | PIN1 | PIN2 | PIN3    | PIN4   |
| ---- | ---- | ---- | ------- | ------ |
| DCV  | 0 V  | 0 V  | 3.25 V  | 3.25 V |
| DCA  | 0 mA | 0 mA | 23.4 mA | -      |
|      | GND  | RX   | TX      | VCC    |

- TIP: 멀티미터를 통한 RX, TX 구분이 어렵다면 :
  - MCU의 데이터시트를 참고하여 정확하게 식별합니다.
  - 일단 RX, TX를 임의로 가정한 후 뒤의 과정대로 연결 수행 → 시리얼 통신 시 아무 반응이 없다면 바꿔서 연결합니다.

## 2.4. Baud Rate란

GND, TX, RX 핀을 모두 식별하였으니 UART 통신에 필요한 Baud Rate 개념을 알아야 합니다.

Baud Rate는 1초에 전송할 수 있는 symbol[^3]의 수입니다. 따라서 IoT 기기와 UART Serial 통신을 하기 위해서는 각 기기마다 사용하는 Baud Rate에 맞춰 통신 속도를 설정해야 합니다.

아래는 UART에서 흔히 사용하는 Baud Rate 리스트입니다. `115200` 이하 값을 주로 사용합니다.

| Baud Rate |
| --------- |
| 4147200   |
| 921600    |
| 576000    |
| 460800    |
| 115200    |
| 57600     |
| 38400     |
| 28800     |
| 19200     |
| 9600      |
| 4800      |
| 2400      |
| 1200      |

Baud Rate 개념까지 알았으니 다음으로는 USB to TTL을 통해 UART Serial 통신을 해봅시다.

위의 값들이 아닌 다른 Baud Rate 값을 사용한다면, Logical Analyzer를 사용하거나 기기 이름의 buad rate에 대해 검색하는 등의 방법을 사용할 수 있습니다.

## 2.5. UART 연결

### 2.5.1. Mac 환경

본 항목에서는 Mac 환경에서의 UART 연결 방법에 대해서 다루겠습니다. Serial 통신 콘솔을 위해 minicom 프로그램을 사용합니다.

점퍼 케이블을 사용해 USB to TTL의 케이블을 UART핀에 연결 합니다. 각 케이블의 역할은 아래와 같습니다.

| 케이블 색 | USB to TTL 핀 | UART 핀 |
| --------- | ------------- | ------- |
| 검은색    | GND           | GND     |
| 흰색      | RX            | TX      |
| 청록색    | TX            | RX      |

연결 시 UART의 TX 핀에는 USB to TTL의 RX 케이블을, UART RX 핀에는 USB to TTL의 TX 케이블을 연결하도록 주의해야 합니다. IoT 기기에서 송신한 데이터를 USB to TTL이 수신하고, USB to TTL이 송신한 데이터를 IoT 기기가 수신하기 때문입니다.

![lsusb](/assets/2024-02-06-IoT-TechBlog/lsusb.png)

USB to TTL의 USB 포트는 PC에 연결합니다. `lsusb` 명령어를 사용해서 USB to TTL이 PC에 제대로 연결되었는지 확인할 수 있습니다. minicom의 Serial 장치를 설정하기 위해 `ls /dev | grep usb` 명령어로 연결된 USB to TTL의 장치 이름을 확인합니다.

![list dev directory](/assets/2024-02-06-IoT-TechBlog/ls_dev.png)

![minicom setting](/assets/2024-02-06-IoT-TechBlog/minicom_s.png)

USB to TTL의 장치 이름을 알았으니 `minicom -s` 명령어로 UART 통신을 설정합니다. Serial 장치를 설정하고 Baud Rate를 `38400`으로 설정하여 UART 통신 시 출력이 제대로 되는지 확인합니다. 만약 출력 결과를 읽을 수 없다면 Baud Rate를 바꿔가면서 정확한 값을 구할 수 있습니다.

Baud Rate을 바꿔줄 때마다 장치 재부팅이 필요합니다. 부트 로그가 UART로 모두 출력되었다면 더 이상 출력할 데이터가 없습니다. 이 때문에 재부팅 없이 Baud Rate 값만 바꿔주면 값이 올바른지 여부가 의심스럽습니다. 따라서 Baud Rate 테스트를 진행할 때 기기를 재부팅해야 모든 부트 로그를 확인할 수 있습니다.

![uart](/assets/2024-02-06-IoT-TechBlog/uart.png)

확인 결과 부트로그가 제대로 출력 되었습니다.

### 2.5.2. Windows 환경

본 항목에서는 Windows 환경에서 UART를 연결해보겠습니다. Serial 통신을 위해서 PuTTY 프로그램을 사용한다는 점이 Mac 환경과 다릅니다.

USB to TTL의 점퍼 케이블을 IoT 기기의 UART에 연결한 후 PC에 USB를 연결합니다. `내 컴퓨터 > 장치관리자` 의 `포트` 탭에서 USB to TTL이 PC에 올바르게 인식되는지 확인할 수 있습니다. PuTTY의 Serial line을 설정하기 위해 인식된 USB to TTL 장치의 이름을 확인합니다. (만약 포트 탭에 장치가 인식되지 않는다면, 기타 장치 탭을 확인해봅시다. 기타 장치로 인식되었다면 드라이버를 설치해야 합니다.)

![windows device manager](/assets/2024-02-06-IoT-TechBlog/windows_device_manager.png)

Serial 장치를 설정한 후 정확한 Baud Rate 값을 구합니다. UART 통신을 모두 설정하였다면 IoT 기기의 전원을 공급하여 부팅 시 로그가 출력 되는지 확인합니다.

![putty setting](/assets/2024-02-06-IoT-TechBlog/putty_s.png)

![putty](/assets/2024-02-06-IoT-TechBlog/putty.png)

## 3. SPI 통신으로 펌웨어 추출하기

### 3.1. SPI란

![I2C drawio](/assets/2024-02-06-IoT-TechBlog/I2C.drawio.png)

SPI 통신을 이해하기 위해서는 먼저 I2C 통신을 알아야 합니다. I2C(Inter-Integrated Circuit)는 2개의 직렬 버스로 여러 디바이스와 통신할 수 있는 프로토콜입니다. 한 개의 Master 디바이스와 여러 Slave 디바이스로 구성될 수 있습니다. 2개의 직렬 버스 중 SDA 선은 시리얼 데이터를 송수신하는 버스이고, SCL 선은 Master가 생성한 기준 클럭을 전송하는 버스입니다. 따라서 Master 디바이스에서 기준 클럭을 생성하고 해당 클럭에 맞춰서 I2C 통신에서는 반이중(Half-Duplex) 방식으로 시리얼 데이터를 송수신하게 됩니다.

![SPI drawio](/assets/2024-02-06-IoT-TechBlog/SPI.drawio.png)

SPI(Serial Peripheral Interface)는 I2C 통신 방식과 비슷한 방식이며, MCU와 주변 회로 간 통신에서 가장 널리 사용되는 통신 방식입니다. SPI 통신은 I2C 통신과 다르게 전이중(Full-Duplex) 방식으로 시리얼 데이터를 송수신합니다. 또한 MOSI 선, MISO 선, Clock 선과 SS 선이 사용됩니다.

- MOSI(Master Out Slave IN) 선 : Master → Slave 시리얼 데이터 전송 선
- MISO(Master In Slave Out) 선 : Slave → Master 시리얼 데이터 전송 선
- Clock(SCLK, CLK) 선 : 동기화 신호를 위한 클럭 전송 선
- SS, CS(Slave Select, Chip Select) 선 : 여러 Slave 디바이스 중 통신을 위해 시리얼 데이터를 보낼 경로를 결정하는 신호 선

  Master 디바이스가 Slave 디바이스로 시리얼 데이터를 전송하면, Slave 디바이스의 Shift Register 데이터는 1 클럭 당 1 비트의 시리얼 데이터가 MSB(Most Significant Bit) 혹은 LSB(Least Significant Bit) 방식으로 shift 되어 데이터가 저장되는 구조로 동작합니다.

### 3.2. 방법

일반적으로 MCU는 부팅 단계에서 SPI Flash 칩과 통신하여 펌웨어를 얻습니다. 우리는 동일한 방법을 통해서 SPI Flash 칩으로부터 펌웨어를 얻으려고 합니다. 따라서 SPI Flash 칩의 데이터 시트를 참고하여 SPI 통신에 필요한 정보를 수집해야 합니다.

저희는 flashrom[^4] 프로그램을 사용할 것입니다. flashrom은 Flash 칩을 식별하여 reading, writing, verifying, erasing 등의 작업을 수행해주는 유틸리티 프로그램입니다. 476개 이상의 Flash 칩, 291개의 칩셋, 500개의 메인보드 등과 통신할 수 있습니다. 따라서 SPI Flash 칩의 데이터시트에 명시된 명령어들을 몰라도 flashrom 명령어를 통해 읽기, 쓰기 등의 작업을 수행할 수 있습니다.

최신 버전의 flashrom을 라즈베리파이에 빌드하여 사용합니다.

SPI Flash 칩의 데이터시트에서 핀 맵을 확인합니다. 이를 라즈베리파이의 SPI 핀과 매핑합니다.

### 3.3. SOIC Test-Clip 사용

데이터 시트를 참고하여 암-암 점퍼 케이블로 라즈베리파이와 SOIC-CLIP을 연결해줍니다.

| 사용 장비        | 역할                                             |
| ---------------- | ------------------------------------------------ |
| POMONA SOIC-CLIP | 점퍼케이블로 8 PIN SOIC와 연결할 수 있게 해준다. |
| 라즈베리파이     | flashrom을 실행하여 flash memory와 통신          |
| 분석용 PC        | 라즈베리파이에 접속(ssh)                         |

**펌웨어 추출 과정**

분석용 PC와 라즈베리파이를 같은 네트워크 대역에 연결한 후, PC에서 라즈베리파이에 접속합니다.

```bash
$ ssh user@xxx.xxx.xxx.xxx
```

라즈베리파이에서 flashrom을 이용해 firmware를 추출합니다.

```bash
$ sudo flashrom -p linux_spi:dev=/dev/spidev0.0 -r [filename]
```

추출한 펌웨어를 binwalk를 이용해서 분석합니다. binwalk는 펌웨어와 같은 바이너리 파일의 구조을 분석하고, 펌웨어에 포함된 파일을 추출 및 압축 해제할 수 있는 도구입니다. binwalk는 파일 시그니처를 기반으로 바이너리 파일의 구조를 분석해줍니다.

- 펌웨어 구조 확인

  ```bash
  $ binwalk [filename]
  ```

  ```bash
  user@raspberrypi:~/ $ flashrom -p linux_spi:dev=/dev/spidev0.0 -r firmware.bin -c "EN25QH32B"
  flashrom 1.4.0-devel (git:v1.2-1386-g5106287e) on Linux 6.1.0-rpi6-rpi-v8 (aarch64)
  flashrom is free software, get the source code at https://flashrom.org

  Using clock_ gettime for delay loops (clk_id: 1, resolution: 1ns).
  Using default 2000kHz clock. Use 'spispeed' parameter to override.
  Found Eon flash chip "EN25QH32B" (4096 kB, SPI) on linux_spi.
  ニニニ
  This flash part has status UNTESTED for operations: WP
  The test status of this chip may have been updated in the latest development version of flashrom. If you are running the latest development version, please email a report to flashrom@flashrom.org if any of the above operations work correctly for you with this flash chip. Please include the flashrom log file for all operations you tested (see the man page for details), and mention which mainboard or programmer you tested in the subject line.
  Thanks for your help!
  Reading flash... done.

  user@raspberrypi:~/ $ binwalk firmware.bin
  DECIMAL		HEXADECIMAL	  DESCRIPTION
  ------------------------------------------------------------------------------
  5360		  0x14F0		    LZMA compressed data, properties: 0x5D, dictionary size: 8388608 bytes, uncompressed size: 60784 bytes
  65584		  0x10030		    gzip compressed data, maximum compression, from Unix, last modified: 2013-12-31 15:00:48
  141408		0x22860		    LZMA compressed data, properties: 0x5D, dictionary size: 8388608 bytes, uncompressed size: 4119960 bytes
  1441792		0x160000	    Squashfs filesystem, little endian, version 4.0, compression:xz, size: 2489160 bytes, 1364 inodes, blocksize: 131072 bytes, created: 2021-04-19 03:14:42
  ```

추출된 결과의 상단에는 LZMA, gzip으로 압축된 파일들이 보이고, 그 밑에 SquashFS filesystem이 파일을 확인할 수 있습니다. SquashFS는 경량 리눅스 디바이스에서 사용하는 읽기 전용 파일시스템으로, 여러 파일과 디렉토리를 단일 파일에 압축하여 저장할 수 있습니다.

offset을 확인했을 때 앞부분부터 끝까지 잘 식별한 걸 보니, 펌웨어가 잘 추출된 것 같습니다. 만약 펌웨어를 제대로 읽지 못했다면, 3.4. Desoldering 과정으로 진행합니다.

## 3.4. Desoldering

여기서는 땜납을 녹여 직접 SPI Flash 칩을 떼어낸 후 펌웨어를 추출하겠습니다. 3.2. 과정에서 펌웨어 추출에 성공하였다면, Desoldering 과정은 생략하여도 괜찮습니다.

| 장비                  | 역할                                                                          |
| --------------------- | ----------------------------------------------------------------------------- |
| Heat gun              | 뜨거운 바람으로 납을 녹인다.                                                  |
| SOP8 - DIP8 변환 소켓 | 8핀 flash chip의 핀을 점퍼케이블(DIP) 핀 규격으로 변환해주는 어댑터           |
| 라즈베리파이          | flashrom을 실행하여 flash memory와 통신                                       |
| 분석용 PC             | 라즈베리파이에 접속(ssh)                                                      |
| 핀셋                  | Flash 칩을 PCB 기판에서 분리할 때 사용. 없어도 괜찮지만 있으면 매우 편리하다. |

SPI Flash 칩을 PCB 기판에서 떼어낸 후 펌웨어를 추출하는 이유는 PCB 기판의 노이즈를 줄여 펌웨어를 정상적으로 추출하기 위해서 입니다.

히트건으로 납을 데워 녹이고(저희는 온도 380도, 바람세기 6으로 설정하였습니다), 핀셋으로 SPI Flash 칩을 들어내면 PCB 기판으로부터 분리할 수 있습니다.

분리한 SPI Flash 칩을 SOP8-DIP8 변환 소켓에 꽂아주고, 암-암 점퍼케이블을 사용해 라즈베리파이와 연결합니다. 이후 과정은 3.3. SOIC Test-Clip 사용 - 펌웨어 추출 과정과 동일하게 진행합니다.

# 4. 펌웨어 조작(Fusing)

성공적으로 `firmware.bin` 이름의 펌웨어 파일을 획득했습니다. 본 항목에서는 펌웨어의 파일시스템만 추출할 것입니다.

```bash
user@raspberrypi:~/ $ binwalk firmware.bin
DECIMAL		HEXADECIMAL	  DESCRIPTION
------------------------------------------------------------------------------
5360		  0x14F0		    LZMA compressed data, properties: 0x5D, dictionary size: 8388608 bytes, uncompressed size: 60784 bytes
65584		  0x10030		    gzip compressed data, maximum compression, from Unix, last modified: 2013-12-31 15:00:48
141408		0x22860		    LZMA compressed data, properties: 0x5D, dictionary size: 8388608 bytes, uncompressed size: 4119960 bytes
1441792		0x160000	    Squashfs filesystem, little endian, version 4.0, compression:xz, size: 2489160 bytes, 1364 inodes, blocksize: 131072 bytes, created: 2021-04-19 03:14:42
```

binwalk 명령어의 분석 결과에서 파일시스템을 찾고, 파일시스템 시작 offset과 size를 확인합니다. 파일시스템의 offset에 맞춰, `dd` 명령어로 파일시스템을 추출할 수 있습니다. skip은 추출하려는 파일의 시작 오프셋, count는 크기를 의미합니다. skip값과 count값은 10진수로 전달해주어야 합니다.

```bash
$ dd if=./firmware.bin of=./extract_squashfs skip=[1441792] bs=1 count=[2489160]
```

저희의 분석장비 펌웨어에서 사용하는 파일시스템은 SquashFS 파일시스템입니다. 따라서 squashfs-tools를 사용하여 분석을 진행하겠습니다.

`firmware.bin` 파일을 skip부터 count까지를 추출하여 `extract_squashfs`로 저장하였습니다.

unsquashfs를 사용해서 파일시스템을 마운트합니다.

```bash
$ sudo apt install squashfs-tools
$ sudo unsquashfs ./extract_squashfs
```

위 과정을 통해 파일시스템의 `squashfs-root` 를 획득하였습니다!

![dd extraction](/assets/2024-02-06-IoT-TechBlog/dd_extract.jpg)

여기서 기기가 부팅된 후 초기에 실행되는 코드를 조작해보겠습니다.

기기가 부팅될 때 가장 처음 실행되는 코드를 찾아봅시다. 보통은 `/etc/init.d`에 위치한 `rcS`가 가장 먼저 실행됩니다. 저희 분석 장비에서는 `/default/rcS` 입니다.

![inittab](/assets/2024-02-06-IoT-TechBlog/inittab.png)

해당 파일의 제일 마지막줄에 원하는 명령어를 추가해볼겁니다.

`/bin` `/sbin` `/usr/bin` `/usr/sbin` 에서 사용 가능한 명령어들을 찾아봅시다. 제일 관심 있는 명령어는 `telnet`이나 `telnetd` 입니다.

![sbin](/assets/2024-02-06-IoT-TechBlog/sbin.jpg)

![telnetd](/assets/2024-02-06-IoT-TechBlog/telnetd.jpg)

`/default/rcS` 마지막줄에 아래 명령어를 추가합니다.

```
/usr/sbin/telnetd -l /bin/sh
```

![firmware modify](/assets/2024-02-06-IoT-TechBlog/firmware_modify.jpg)

이 명령어가 실행되면 부팅 후 telnet을 통해 `/bin/sh`에 접속할 수 있을 것입니다.

이제 우리가 삽입한 코드를 원본 파일시스템에 패치합니다.

- 수정한 파일 시스템을 원본 파일시스템에 패치
  ```bash
  $ sudo mksquashfs squashfs-root squashfs_patched -comp xz
  ```
  ![recompression](/assets/2024-02-06-IoT-TechBlog/recompression.jpg)

hex editor를 사용해 펌웨어의 파일시스템 영역을 조작한 파일 시스템으로 바꾸겠습니다. 파일시스템이 조작된 펌웨어를 `firmware_patched.bin` 으로 저장합니다.

![010 hexeditor](/assets/2024-02-06-IoT-TechBlog/010hexedit.jpg)

조작한 펌웨어인 `firmware_patched.bin`을 기기의 SPI Flash 칩에 다시 써주면 완성입니다.

```bash
$ sudo flashrom -p linux_spi:dev=/dev/spidev0.0 -w firmware_patched.bin
```

# 5. Soldering

앞서 SPI Flash 칩을 디솔더링하여 분리하였다면 부팅을 위해 다시 기기의 PCB 기판에 연결해야합니다.

| 장비          | 역할                                         |
| ------------- | -------------------------------------------- |
| 솔더 페이스트 | Flux를 포함하고 있어 납의 칙소성을 높여준다. |
| 인두기        | 납을 데워서 녹인다.                          |
| 납실          | PCB와 Flash memory를 결합하여 고정한다.      |
| 면봉          | 납땜 후 잔여물을 닦아내는 데 사용한다.       |

솔더 페이스트를 PCB 기판 위에 바르고 그 위에 인두기로 납을 녹여서 문지르면 납이 동그랗고 예쁘게 올라갑니다. SPI Flash 칩을 원위치에 올리고, 열풍기로 납을 살짝 녹여 리솔더링을 해줍니다.

![solder paste](/assets/2024-02-06-IoT-TechBlog/solderpaste.jpg)

![resoldering](/assets/2024-02-06-IoT-TechBlog/resoldering.jpg)

# 6. Glitching

Fault Injection이라고도 하는 글리칭은 제조 시의 한계를 벗어나는 조건으로 공격 대상 장치에서 고장을 유발합니다. 이를 통해 인증 우회, 미인가된 코드 접근, 로직 값 변경, 장치의 종료 또는 재시작 등의 결과를 이끌어냅니다. 글리칭 공격 방법에는 여러 가지가 있는데, 전압 글리칭, 클록 글리킹, 전자기 폴트 인젝션, 광학 폴트 인젝션이 그 예시입니다.

이 중 별도의 장비 없이 수-수 점퍼케이블로 해볼 수 있는 Serial Data Output Fault Injection을 수행해보겠습니다. 이 방법은 MCU가 펌웨어를 얻지 못하는 오류를 유발하는 공격입니다. 부팅 중 MCU가 펌웨어를 얻지 못했을 때의 결과가 제조사마다 다르고, 정교한 오류상태를 주입하는 것이 아니기 때문에 성공률이 높지 않은 편입니다.

![SPI Flash chip glitching point](/assets/2024-02-06-IoT-TechBlog/spi_flashchip_glitching_point.jpg)

![SPI Flash chip glitching](/assets/2024-02-06-IoT-TechBlog/spi_flashchip_glitching.jpg)

우선, 데이터시트를 참고하여 SPI Flash 칩의 Serial Data Output 핀과 GND 핀의 위치를 알아냅니다. 그리고 SPI Flash 칩의 Data Output 핀과 GND 핀을 수-수 점퍼 케이블로 연결합니다. MCU가 SPI Flash로 펌웨어를 요청했을 때의 output 데이터가 MCU가 아닌 GND 핀으로 빠지고, 결과적으로 MCU가 펌웨어를 제대로 얻지 못하게 됩니다.

![bootloader shell](/assets/2024-02-06-IoT-TechBlog/bootloader_shell.png)

UART를 연결한 상태에서 Serial Data Output Faul Injection 공격을 수행하였고, 부팅이 정상적으로 이루어지지 않은 결과로 부트 로더의 쉘에 접근이 가능해졌습니다.

부트 로더의 Memory Reading을 통해 펌웨어를 추출할 수 있습니다.

# 7. 마치며

본 과정을 거쳐 기기의 원본 펌웨어를 얻을 수 있었고, 원격으로 쉘 접속이 가능해졌습니다. 따라서 취약점을 디버깅하기에 수월한 환경 구성이 끝나게 되었습니다.

본 글 작성을 도와주신 김도현 팀장님과 임원빈 선임연구원님, 구본근 선임연구원님을 비롯한 선제대응팀 팀원분들께 감사드립니다.

모두 즐거운 하드웨어 해킹하세요!👽

---

[각주]

[^1]: Printed Curcit Board, 인쇄회로조립체
[^2]: 일반적으로 검은색 선은 (-), 빨간색 선은 (+)이다. 따라서 검은색 리드선을 GND에 연결한다.
[^3]: symbol, 의미있는 데이터 묶음
[^4]: [flashrom 빌드 방법](https://github.com/flashrom/flashrom)

    칩에 접근하는 모든 작업에 `-p` 또는 `--programmer` 옵션을 사용해야 한다.

    `-p <programmername>[:<parameters>]`

    - `linux_spi` (for SPI flash ROMs accessible via /dev/spidevX.Y on Linux)

    `-r`, `--read <file>`

    `-w`, `--write <file>`

    `-c`, `-chip <chipname>`
