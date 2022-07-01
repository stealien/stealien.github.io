---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: React로 pdf 다루기
date		: 2022-06-30 00:00:00 +0900
category	: Dev
author		: 하준혁
author_email: jhha@stealien.com
background	: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary		: "React로 pdf 다루기"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2022-06-30/pdf-with-react
---


# React로 pdf 다루기

올해 초, **월간 레포트 리뉴얼** 이라는 업무를 새롭게 배정받게 되었습니다.
디자인은 회사 대표 디자이너이신 재성님이 아주 아름답게 만들어주셨지만, 코드로 PDF를 만들거나 다뤄본 적이 없는 저는 막연한 두려움을 갖게 되었습니다.

## 왜 리뉴얼을 진행했나?

기존에 사용하던 코드로도 월말마다 회사 Jira에 저장되는 이슈들을 정리하여 메일로 보내기에는 충분했습니다.
하지만 프로젝트 코드가 관리가 잘 되지 않아서 새로운 디자인을 적용하고, 새로운 데이터를 뽑아내기 위해 이 코드를 처음부터 리딩하기는 조금 힘든 상황이였습니다.
특히, 주로 사용하는 언어도 다르기도 했구요.

| <img src="/assets/2022-06-30-PDF-with-React/code-manage-not-good.png" alt="codemanage" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------------------------------------------------ |
| 코드 관리 절망편                                                                                       |

따라서 저는 제가 주로 사용하는 Typescript와 React 기반으로 월간 레포트 시스템을 새로 만들기로 했습니다. 기존처럼 스크립트 형태로도 작성할 수 있지만, 예전에 보낸 레포트 조회나 이미지 변경 등을 개발자인 저 뿐만 아니라, 다른 분들도 플랫폼을 통해 확인할 수 있으면 더 좋을 것 같아서 웹 시스템으로 개발하기 위한 계획을 세웠습니다.

## React-PDF

월간 레포트에서 사용하는 데이터는 저희 Jira와 Confluence에서 가져오게 됩니다.
사실 Jira나 Confluence에서 데이터를 불러오거나 페이지를 생성하는 [API](https://github.com/mrrefactoring/jira.js/)는 너무나도 잘 되어있어서 큰 무리 없이 사용할 수 있었습니다.

하지만, 가장 큰 문제는 역시 가져온 데이터를 기반으로 새로운 PDF 를 생성하는 과정이였습니다.

![react-pdf](/assets/2022-06-30-PDF-with-React/react-pdf.png)

[react-pdf](https://react-pdf.org/)는 React를 기반으로 PDF를 렌더링하거나 생성할 수 있는 라이브러리 입니다.
라이브러리에서 제공하는 `Document` 컴포넌트를 기반으로 PDF 파일을 렌더링하며, `StyleSheet`를 통해서 기존 jsx 처럼 글자나 뷰 자체에 스타일링을 할 수 있도록하는 다양하고 필수적인 기능을 포함하고 있습니다.

또한 `svg`도 지원하기 때문에, 이미지나 차트 등도 쉽게 표현할 수 있습니다.

그래서 저는 `react-pdf`를 기반으로 디자인된 PDF를 만들기 시작했습니다.

## 위기

사실 `react-pdf`라는 라이브러리를 발견했을 때, 작업이 금방 끝날 줄 알았습니다.
하지만, 사용하다보니 생각하지 못한 몇 가지 문제점들을 마주하게 되었습니다.

1. Vite 환경에서 react-pdf가 잘 작동하지 않았습니다.
  - [issue](https://github.com/vitejs/vite/issues/3405)
  - Vite에서 사용하기 위해서는 추가적으로 브라우저용 라이브러리를 추가해주어야 합니다.
  - 이 [라이브러리](https://github.com/exogee-technology/vite-plugin-shim-react-pdf) 로 해결했습니다.

2. 프론트엔드에서 pdf를 생성하다보니, 브라우저 콘솔에서 많은 에러가 발생했습니다.
  - 클라이언트쪽에서 렌더링을 하는 과정에서 이슈가 있는 것 같았습니다.
  - 다행히, 작동에는 이상이 없어서 우선 넘어가게 되었습니다.

3. 차트를 그리기가 조금 까다로웠습니다.
  - svg를 지원한다고 해서 [nivo](https://nivo.rocks/)를 사용하려고 했는데, 구조상 `차트컴포넌트 -> svg -> react-pdf` 의 형식으로 쓰면 오류가 발생하는 바람에 결국 스스로 만들어서 썼습니다.

특히, 마지막 3번이 저를 굉장히 괴롭히게 되었습니다.

월간 레포트의 특성 상, 차트나 표가 대부분의 데이터를 이루고 있었습니다.
특히, 차트는 원형, 막대형 그래프 등 다양한 그래프를 사용할 예정이였기 때문에 작업에 지장이 있을 수 밖에 없었습니다.

다행히, `react-pdf` 에서는 svg를 다루기 위한 여러 컴포넌트가 존재하고 있었습니다.
그 중에서 사용한 것은 `Path` 이였습니다.

PieGraph를 만들 때, 전체 데이터 중에서 차지하는 부분의 각도와 반지름을 통해 각각의 좌표를 구했습니다.

```javascript
function _toXY(cX: number, cY: number, r: number, degrees: number) {
  const rad = (degrees * Math.PI) / 180.0;
  return {
    x: cX + r * Math.cos(rad),
    y: cY + r * Math.sin(rad),
  };
}

function toPieChartItemPath(
  x: number,
  y: number,
  radiusIn: number,
  radiusOut: number,
  startAngle: number,
  endAngle: number
) {
  startAngle += 270;
  endAngle += 270;
  const startIn = _toXY(x, y, radiusIn, endAngle);
  const endIn = _toXY(x, y, radiusIn, startAngle);
  const startOut = _toXY(x, y, radiusOut, endAngle);
  const endOut = _toXY(x, y, radiusOut, startAngle);
  const arcSweep = endAngle - startAngle <= 180 ? "0" : "1";
  const d = [
    "M",
    startIn.x,
    startIn.y,
    "L",
    startOut.x,
    startOut.y,
    "A",
    radiusOut,
    radiusOut,
    0,
    arcSweep,
    0,
    endOut.x,
    endOut.y,
    "L",
    endIn.x,
    endIn.y,
    "A",
    radiusIn,
    radiusIn,
    0,
    arcSweep,
    1,
    startIn.x,
    startIn.y,
    "z",
  ].join(" ");
  return d;
}
```

이를 Svg 안의 Path 객체로 선을 그리고, 그 안을 색으로 채워 그래프를 그릴 수 있게 했습니다. 코드는 다음과 같습니다.

```javascript
const PieGraph:React.FC<{datas: Data[]}> = ({datas}) => {
  return <Svg width="256" height="172">
      {data.map((item, idx) => (
        <Path
          key={item.id}
          d={toPieChartItemPath(128, 86, 0, 64, range[idx], range[idx + 1])}
          fill={colors[item.id]}
        />
      ))}
      </Svg>
}
```

**예시**

![chart](/assets/2022-06-30-PDF-with-React/chart.png)

`PolyLine` 컴포넌트를 통해 외부에 퍼센트를 나타낼 수 있게도 구현하였습니다.

이런 방식으로 PieGraph와 LineGraph도 그릴 수 있었습니다.

아마도 `react-pdf`에서 일반적인 태그를 사용하지 않아서 nivo와 같은 차트 라이브러리들이 작동하지 않았을 것 같습니다.

## 결론

이제는 제가 만든 새로운 코드를 기반으로 많은 고객사에 앱슈트 월간 레포트가 전달되고 있습니다.

처음에 기획했던 기능들을 전부 넣지는 못했지만, 계속 업데이트를 해서 사내에서 가장 유용하게 사용하는 프로젝트가 되기를 바랍니다.
