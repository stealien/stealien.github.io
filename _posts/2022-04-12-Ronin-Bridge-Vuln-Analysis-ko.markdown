---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: Ronin Bridge Vulnerability Analysis 
date		: 2022-04-12 00:00:00 +0900
category	: R&D
author		: 한호정
author_email: hjhan@stealien.com
background	: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary		: "Ronin Bridge 취약점 분석"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2022-04-12/ronin-bridge-vuln-analysis
---

# Ronin Bridge 취약점 분석

## 요약
Ethereum의 side-chain인 'Ronin Network'가 해킹을 당해 6억1500만달러(약 7400억원) 규모의 Ethereum이 탈취된 사건이 최근 알려졌다. 이 글에서는 Ronin Network가 무엇인지 알아보고 어떤 요소때문에 자금이 유출된건지, 대응은 어떻게 하고있는지에 대해서 알아본다

## Ronin Network?
유명인기게임 "Axie Infinity"를 개발한 베트남의 "Sky mavis"라는 회사에서 Ethereum Network의 높은 수수료와 낮은 처리속도를 보완하기 위한 Side chain으로 등장했다.

## Side Chain?
사이드체인은 서로 다른 블록체인들 위에 존재하는 자산들을 쉽게 거래할 수 있도록 하는 기술이다. 
만약 모든 데이터를 Main Chain의 노드 안에 넣어 처리한다면 노드의 처리속도를 점점 느리게할 것이며, Main Chain에서 점점 많아지는 노드의 수로 인해서 발생하는 합의시간의 증가는 메인체인에서의 많은 문제점을 야기할 것이다.. 

TPS는 점점 느려질 수 밖에 없고 수수료의 값은 점점 올라가게 되는 것이다. 

이러한 문제로 암호화폐의 상용성에 대해 많은 문제제기를 하게 되고 이에 대한 해결책으로 사이드체인이 등장하게 되었다. 

Main Chain에 있는 자산을 Side Chain으로 옮겨 Transaction을 처리한다. 

Side Chain에서 복수의 Transaction이 모두 끝나면 다시 중요한 정보만을 Main Chain로 보내주고 저장함으로써 Transaction을 상당히 간소화시킬 수 있다.

즉, Main Chain에서 모든 Transaction을 처리하는 것이 아니라 Side Chain이 Main Chain이 할 일을 나누어 도와주는 것이라고 할 수 있다.


## 무슨일이 일어난건가?
> The Ronin bridge has been exploited for 173,600 Ethereum and 25.5M USDC. The Ronin bridge and Katana Dex have been halted.
(Twitter @Ronin_Network)

위의 트윗 내용에 따르면 173,600 Ethereum과 25.5M USDC가 유출되었다고 하며, 이를 확인한 즉시 Ronin Bridge와 Katana Dex는 운영을 중단했다고 한다.

다소 놀라운 것은 Ronin Bridge에서 자금이 유출되고 6일이 경과한 후에 일반 사용자가 자신의 자산을 출금하지 못한다는 문의로 인해 사고의 발생을 알게된 것이다.


## 어떻게 발생한건가?
Ronin network는 Ethereum network의 side chain으로써 기본적으로 Ethereum network에서 발생하는 다량의 transaction을 Ethereum network보다 비교적 속도가 빠르고 낮은 수수료를 소비하는 Ronin network에서 처리하고 그 결과만을 Ethereum network에 반영한다.

이러한 과정 중에 서로 다른 network로부터 오고가는 transaction의 유효성을 검증하기 위해서 validator라는 요소를 두게 된다.

![image](/assets/2022-04-12-Ronin-Bridge-Vuln-Analysis/image.png)

위 사진은 블록체인 트릴레마라고 불리우는 난제이며, 모든 블록체인 네트워크에서 위 사진의 3가지를 효과적으로 해결할 수 있는 것을 목표로 하고 있다.

Ronin network에서 validator의 수를 결정할 때 블록체인 트릴레마에 대한 것을 생각해보면 Security와 Scalability는 trade-off관계임을 알 수 있다.

validator의 수를 많이 두자니 보안이 향상될 것이나 성능이 저하될 것이고, validator의 수를 적게 두자니 성능이 향상될 것이나 성능이 저하될 것이다.

이러한 이유로 인해서 Ronin network에서는 어느정도 보안을 포기하고 성능을 챙기려고 했던건지 validator의 수를 적게 둔 것이 취약점의 시발점이었다.

보안사고가 터진 것을 인식하기 전 Ronin network는 총 9개의 validator로 구성되어있었고, 5개의 validator 이상이 승인하면 유효한 transaction으로 승인되었다.

여기서 공격자는 validator 4개의 private key를 갖고있었고 특정 방법(?, Ronin network의 rpc node를 통해 axie dao 소유의 validator private key에 접근할 수 있는 백도어가 있었다고하는데 정확한 보고서나 직접 확인을 하기 위한 RPC Node 주소가 공개되어있지 않은듯함.)으로 인해서 Axie DAO가 운영하는 validator의 private key를 얻을 수 있었으며, 이를 악용하여 Ronin network에서는 실제로 자산이 없는데 자산이 있는 것처럼 속여 Ethereum network로 transaction을 보냈다.

Ethereum network에 존재하는 Ronin Network Contract는 이를 정상적인 transaction으로 인식하여 지정된 수신자에게 
[173,600 Ethereum](https://etherscan.io/tx/0xc28fad5e8d5e0ce6a2eaf67b6687be5d58113e16be590824d6cfa1a94467d0b7)과 [25.5M USDC](https://etherscan.io/tx/0xed2c72ef1a552ddaec6dd1f5cddf0b59a8f37f82bdda5257d9c7c37db7bb9b08)를 송신했다.

Ronin Network에서 자금을 유출하기 위해서 사용한 validator의 주소는 다음과 같다.
- [0x11360eacdedd59bc433afad4fc8f0417d1fbebab](https://explorer.roninchain.com/address/0x11360eacdedd59bc433afad4fc8f0417d1fbebab/txs)
- [0x1a15a5e25811fe1349d636a5053a0e59d53961c9](https://explorer.roninchain.com/address/0x1a15a5e25811fe1349d636a5053a0e59d53961c9/txs)
- [0x70bb1fb41c8c42f6ddd53a708e2b82209495e455](https://explorer.roninchain.com/address/0x70bb1fb41c8c42f6ddd53a708e2b82209495e455/txs)
- [0xb9e59d56fd1632fc250935182bdd5c59188b2302 \| Axie DAO](https://explorer.roninchain.com/address/0xb9e59d56fd1632fc250935182bdd5c59188b2302/txs)
- [0xf224beff587362a88d859e899d0d80c080e1e812](https://explorer.roninchain.com/address/0xf224beff587362a88d859e899d0d80c080e1e812/txs)


분석을 하면서 나온 결론은 해당 사고는 Smart Contract Code Level에서 발생한 것이 아니라 Ronin Network의 한축을 담당하고 있는 validator의 private key 유출로 인해서 벌어진 일이라는 것이다.

## 범인을 특정할 수 있을까?
아래의 주소는 공개된 공격자의 지갑 주소이다.
- [0x098b716b8aaf21512996dc57eb0615e2383e2f96](https://etherscan.io/address/0x098b716b8aaf21512996dc57eb0615e2383e2f96)

보통 블록체인 상에서 보안사고가 발생하면 공격자는 유출한 금액을 Tornado.cash나 다른 mixer를 이용해서 자금의 추적을 어렵게하는데 해당 사고의 공격자는 상당히 대범하게 곧바로 binance, FTX, huobi의 핫월렛에 입금하는 것을 볼 수 있다.

- [Binance Hotwallet에서 1 Ether 출금하는 Transaction](https://etherscan.io/tx/0xe0669bbaaa12cf5ecc682848ddc373a9b86e1351bccc01092b744099bf52a87d)
- [Huobi Hotwallet으로 입금하는 Transaction list](https://etherscan.io/tx/0x075df6c4b44733a0e76aa4947b56b4c0c00ec136d7865edc1ac7068264e15704)
- [FTX Hotwallet으로 입금하는 Transaction list](https://etherscan.io/address/0x5b5082214d62585d686850ab8d9e3f6b6a5c58ff)

입출금한 거래소가 KYC를 요구하는 거래소라는 점을 생각해볼 때 얼마 지나지않아 공격자의 신원이 특정될 것으로 예상한다.

## 어떻게 조치를 하고있는가?
우선 9개의 validator 중 공격에 사용된 validator의 권한을 정지시켰으며, 기존에 9개의 validator 중 5개의 validator만 승인했던 것에서 8개 이상의 validator가 승인해야만 정상적인 transaction 승인 받도록 변경되었다.

이것은 미봉책에 불과하며, 향후 validator의 수를 늘릴 것으로 공표했다.


## 비슷한 유형의 사건이 있을까?
- [Convex Finance addresses bug that could've led to a $15 billion rug pull](https://www.theblockcrypto.com/post/140554/convex-finance-addresses-bug-that-couldve-led-to-a-15-billion-rug-pull)


## 정리하며
기존에 본인이 분석해왔던 블록체인 쪽의 보안사고와는 다소 다른 유형의 사고였다.
지금까지 Smart contract의 Code level상의 취약점만 보다가 Architecture 상 중요한 역할을 하는 EOA의 private key가 유출되어서 그것이 플랫폼 자금의 유출로 이어지는 사건은 처음 분석해보았다.
이로 인해 느낀점은 Smart Contract상에서 Code 뿐만 아니라 구성하고있는 EOA에 대한 보안도 신경써서 관리해야함을 다시한번 깨달았다.