---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Slackbot을 활용한 ERP 시스템 구축
date            : 2021-07-13 13:13:02 +0900
category        : Dev
author          : 이창호
author_email    : chlee@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/slackbot.png
summary         : Slackbot의 Event Subscriptions 기능을 사용해 ERP 시스템 구축
thumbnail       : /assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/thumbnail.png
---

# Slackbot을 활용한 ERP 시스템 구축

## 개요
이전에는 회사 인원이 많지 않아 별도의 관리 시스템이 없었는데, 회사의 구성원이 점점 많아지며 자연스럽게 결재 요청/승인/관리와 같은 프로세스를 체계적으로 관리할 수 있는 무언가가 필요했다.

회사 내부에서는 예전부터 사내 메신저로 Slack을 사용해왔기 때문에 Slack에서 결재 프로세스를 관리해 보자는 의견이 있었고, 처음에는 이를 활용할 수 있는 Slack의 서드파티 앱들을 찾아보았다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/thirdparty.png" alt="thirdparty" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 우리가 원하던 앱은 없었다.                         |

하지만 HR/Approve/office/management 등 다양한 키워드로 검색해보기도 하고 관련 카테고리의 앱들을 찾아봤으나 마음에 드는 앱은 없었다.

그 이후로도 몇가지 대안을 더 찾아보긴 했으나.. 최종적으로는 직접 구현하는게 가장 베스트라는 결론이 나왔다.

## 환경 구성
첫번째로, slackbot의 이벤트를 처리해줄 웹서버가 필요하다. Flask를 사용해 Request 요청을 처리해주는 서버를 구축하고 외부에서 접속하기 위해 도메인 연결까지 모두 설정해 두었다.~~아저씨는 미리 준비해 왔어요~~
```python
from flask import Flask
app = Flask(__name__)
@app.route("/slack_msg", methods=["POST"])
def slack_msg():
    slack_event = json.loads(request.data)
    return make_response(slack_event["challenge"], 200, {"content_type": "application/json"})
    # 서버의 검증을 위해 slackbot의 challenge 데이터를 리턴해야 하며, 서버 검증이 끝난 후 삭제해주면 된다.
app.run(host="0.0.0.0", port=8391)
```

<br>
이후 https://api.slack.com/apps에서 bot과 관련된 설정을 해준다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/1.create_slackbot.png" alt="create_slackbot" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 봇을 만들어주고                         |

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/2.event_subscription.png" alt="event_subscription" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| Event Subscriptions을 설정해 주고     |

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/3.request_url.png" alt="request_url" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 미리 만들어둔 서버의 url을 입력한다.     |

이제 구축한 환경이 정상적으로 동작하는지 테스트해보자.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/4.dm_slack.png" alt="request_url" style="max-width:800px; height:auto;" /> |

slackbot에 dm을 보내보면

```json
{
  ...
    "event":{
      ...
              "elements":[
                {
                  "type":"text",
                  "text":"Hello World!"
                }
            ]
    },
  }
```
이벤트가 잘 동작하는것을 볼 수 있다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/5.slackbot_token.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 토큰은 외부에 노출되지 않도록 하자     |

이제 상호작용을 하기 위해 slackbot의 token을 가져온 후

```python
from flask import Flask, request, make_response
from slack import WebClient
import json
app  = Flask(__name__)
slack = WebClient(token="my-secret-token")
@app.route("/slack_msg", methods=["POST"])
def slack_msg():
    slack_event = json.loads(request.data)
    user_message = slack_event["event"]["blocks"][0]["elements"][0]["elements"][0]["text"]
    user         = slack_event["event"]["user"]
    if user_message == "Hello World!":
        slack.chat_postMessage(channel=user, text=user_message)

    return make_response("", 200, {"X-Slack-No-Retry": 1})

app.run(host="0.0.0.0", port=8391)
```

이런식으로 코드를 짜주면

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/6.response.png" style="max-width:800px; height:auto;" /> |

사용자와 slackbot이 상호작용 하는 것을 볼 수 있다.

## 기능 구현
드디어 환경 구축이 끝났다. 이제 본격적으로 기능 구현에 들어가보자.

가장 먼저 고민해야 할 부분은, "사용자의 요청을 어떻게 받는가" 이다.

처음에는 텍스트 입력으로 사용자의 요청을 처리했다.

```text
@STLBOT
$휴가신청
휴가자 : 이창호
휴가일시 : 7/1 ~ 12/31
사유 : 개인사유
```
봇을 태그하는 것으로 "사용자가 요청을 보냈다" 라는 것을 알려주고, $로 요청 내용을 구분한 후 양식에 맞춰 내용을 작성하는 것이었다.

하지만 이 방식을 사용했을 때 사용자는 신청할 때마다 내용을 복사 붙여넣기 해서 내용을 쓰고, 서버쪽에서는 요청 내용을 받아 정규식으로 처리해야 했기 때문에 양쪽 모두 번거로움이 있었다.

이에 대한 대안으로 찾은 것이 slackbot의 modal이다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/7.slackbot_modal.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 자세한 내용은 https://api.slack.com/surfaces/modals/using 에서 확인할 수 있다.|

modal은 개발자가 원하는 방식대로 폼을 만들어 두고 사용자는 폼에 맞게 입력만 해주면 요청을 처리해주는 방식인데, slack에서는 modal을 사용하면 사용자의 요청을 interactive하게 처리해줄 수 있다고 한다.

실제로도 modal로 미리 폼을 만들어 두니 사용자는 값만 입력하면 되고 개발자는 정해진 서식에서 값을 가져오기만 하면 되기 때문에 기존 로직들을 훨씬 깔끔하게 처리할 수 있었다.

modal을 사용하기 위해서는 사용자의 action을 처리할 수 있도록 설정해줘야 한다.(event와 action은 다르다.)

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/8.action_url.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 여기는 Event Subscriptions와는 다르게 등록하는 url의 검증과정이 필요하지 않다.|

먼저 slackbot에서 action을 처리할 url을 등록해주자.

```python
request_buttons = [
    {
      "type":"actions",
      "block_id":"msg_button_click",
      "elements":[
        {
          "type":"button",
          "action_id":"msg_button_click_vacation",
          "text":{
            "type":"plain_text",
            "text":"휴가신청",
            
          },
          "value":"request_vacation_button"
        }        
      ]
    }
  ]

@app.route("/slack_msg", methods=["POST"])
def slack_msg():
    slack_event = json.loads(request.data)
    user_message = slack_event["event"]["blocks"][0]["elements"][0]["elements"][0]["text"]
    user         = slack_event["event"]["user"]
    if user_message == "휴가신청":
        slack.chat_postMessage(channel=user, text=user_message, blocks=request_buttons)
```

특정 입력이 들어왔을 때 버튼이 생성되도록 코드를 짜주고


```python
@app.route("/action", methods=["POST"])
def action():
    slack_event = json.loads(request.form.get("payload"))
    trigger_id = slack_event["trigger_id"]
    #modal view를 열기 위해서는 action의 input data중 하나인 trigger_id가 필요하며 해당 값은 3초간 유효하다.
    slack.views_open(trigger_id=trigger_id, view=modal.request_vacation)
    return make_response("", 200, {"X-Slack-No-Retry": 1})
```

들어온 action을 처리할 코드를 짜준다.
- modal view 코드는 너무 길어서 [링크](https://app.slack.com/block-kit-builder/TP0SDQZEC#%7B%22blocks%22:%5B%7B%22type%22:%22actions%22,%22block_id%22:%22vacation_request_list%22,%22elements%22:%5B%7B%22action_id%22:%22select_modal_vacation_request_list%22,%22type%22:%22static_select%22,%22placeholder%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EC%9A%94%EC%B2%AD%20%EC%9C%A0%ED%98%95%20%EC%84%A0%ED%83%9D%22%7D,%22options%22:%5B%7B%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%ED%9C%B4%EA%B0%80%22%7D,%22value%22:%22vacation%22%7D,%7B%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EB%B0%98%EC%B0%A8%22%7D,%22value%22:%22half_vacation%22%7D,%7B%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EB%B0%98%EB%B0%98%EC%B0%A8%22%7D,%22value%22:%22quarter_vacation%22%7D,%7B%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EB%B3%91%EA%B0%80%22%7D,%22value%22:%22sick_vacation%22%7D,%7B%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EC%99%B8%EC%B6%9C%22%7D,%22value%22:%22outing%22%7D%5D%7D%5D%7D,%7B%22type%22:%22section%22,%22block_id%22:%22%22,%22text%22:%7B%22type%22:%22mrkdwn%22,%22text%22:%22*%EB%82%A0%EC%A7%9C%20%EC%84%A0%ED%83%9D*%22%7D%7D,%7B%22type%22:%22actions%22,%22block_id%22:%22datepicker_select_period_block%22,%22elements%22:%5B%7B%22type%22:%22datepicker%22,%22action_id%22:%22datepicker_start_date_action%22,%22placeholder%22:%7B%22type%22:%22plain_text%22,%22text%22:%22Select%20start%20date%22%7D%7D,%7B%22type%22:%22datepicker%22,%22action_id%22:%22datepicker_end_date_action%22,%22placeholder%22:%7B%22type%22:%22plain_text%22,%22text%22:%22Select%20end%20date%22%7D%7D%5D%7D,%7B%22type%22:%22input%22,%22block_id%22:%22reason_text_block%22,%22element%22:%7B%22type%22:%22plain_text_input%22,%22action_id%22:%22reason_text_action%22%7D,%22label%22:%7B%22type%22:%22plain_text%22,%22text%22:%22%EC%82%AC%EC%9C%A0%22%7D%7D,%7B%22type%22:%22section%22,%22block_id%22:%22confirm_datetime_block%22,%22text%22:%7B%22type%22:%22mrkdwn%22,%22text%22:%22*%EB%82%A0%EC%A7%9C%20%ED%99%95%EC%9D%B8*%5Cn%60%EC%8B%9C%EC%9E%91%20%EB%82%A0%EC%A7%9C%20%EC%84%A0%ED%83%9D%20%EC%95%88%EB%90%A8%60%22%7D%7D%5D%7D){: target="_blank"}로 대체한다.

이렇게 해주면 slackbot을 (드디어)interactive하게 사용할 수 있다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/9.interactive_sample.png" style="max-width:800px; height:auto;" /> |

지정한 input이 들어오면 버튼을 생성해주고

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/10.modal.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 개발은 텍스트 input으로 받는게 더 쉬웠다는건 비밀     |

버튼을 누르면 이런 창이 나온다.

여기까지 왔으면 절반은 완성된거다. 나머지 필요한 로직들은 지금까지 개발했던 코드들을 활용해 주기만 하면 된다.

이후 구현한 알고리즘은 아래와 같다.
- 관리자 채널에 요청한 내용을 전달해준다.
- 관리자는 요청을 승인or거절한다.
- 직원에게는 결과를 dm으로 보내고 이력을 저장한다.

사용자가 요청을 Submit했을 때 관련 데이터는 /action으로 들어오게 되고, 그 다음은 입맛에 맞게 코딩하다 보면 어느순간 프로그램은 완성되어 있을 것이다.

### 후기
slackbot을 활용해 보면서 느낀 점은 slack을 활용하기에 따라서 만들 수 있는 것들이 무궁무진해 진다는 것이다.

결재요청 프로그램을 만들고 나서 회사가 자율출퇴근제로 변경이 됐는데, 지금은 출결관리도 slackbot으로 하고 있다.

| <img src="/assets/2021-07-08-Slackbot을-활용한-ERP-시스템-구축/11.app_home.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 이거 만들려고 원래 있던 코드 싹 갈아 엎고 새로 만들었다.     |

위 기능은 slackbot의 app_home을 활용해 만들었으며, 관련된 내용은 다음에 기회가 된다면 포스팅  할 예정이다.
