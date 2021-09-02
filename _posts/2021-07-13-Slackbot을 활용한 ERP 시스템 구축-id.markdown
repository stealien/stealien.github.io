---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Membangun sistem ERP menggunakan Slackbot
date            : 2021-07-13 13:13:02 +0900
category        : Dev
author          : 이창호
author_email    : chlee@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/slackbot.png
summary         : Bangun sistem ERP menggunakan fitur Langganan Acara Slackbot
thumbnail       : /assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/thumbnail.png
lang            : id
permalink       : /dev/2021/07/13/Slackbot을-활용한-ERP-시스템-구축.html
---

# Membangun sistem ERP menggunakan Slackbot

## Ringkasan
Sebelumnya, tidak ada sistem manajemen yang terpisah karena tidak banyak orang di perusahaan, tetapi dengan bertambahnya jumlah anggota perusahaan, diperlukan sesuatu yang dapat mengatur proses secara sistematis seperti permintaan/persetujuan/pengelolaan pembayaran.

Karena perusahaan telah lama menggunakan Slack sebagai in-house messenger, ada pendapat untuk mengelola proses pembayaran di Slack.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/thirdparty.png" alt="thirdparty" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| Kami tidak memiliki aplikasi yang kami inginkan.                         |

Namun, saya mencari berbagai kata kunci seperti HR/Setuju/kantor/manajemen dan mencari aplikasi dalam kategori terkait, tetapi tidak ada aplikasi yang saya suka.

Setelah itu, saya mencari beberapa alternatif lagi, tetapi pada akhirnya, saya sampai pada kesimpulan bahwa yang terbaik adalah menerapkannya sendiri.

## konfigurasi lingkungan
Pertama, Anda memerlukan server web untuk menangani acara slackbot. Saya membangun server yang menangani permintaan menggunakan Flask dan mengatur semua koneksi domain untuk terhubung dari luar.
```python
from flask import Flask
app = Flask(__name__)
@app.route("/slack_msg", methods=["POST"])
def slack_msg():
    slack_event = json.loads(request.data)
    return make_response(slack_event["challenge"], 200, {"content_type": "application/json"})
    # Untuk verifikasi server, data tantangan slackbot harus dikembalikan, dan setelah verifikasi server selesai, data tersebut dapat dihapus.
app.run(host="0.0.0.0", port=8391)
```

<br>
Setelah itu, atur pengaturan terkait bot di https://api.slack.com/apps.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/1.create_slackbot.png" alt="create_slackbot" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| membuat bot                         |

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/2.event_subscription.png" alt="event_subscription" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| Siapkan Langganan Acara     |

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/3.request_url.png" alt="request_url" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| Masukkan url server yang Anda buat sebelumnya.     |

Sekarang mari kita uji apakah lingkungan yang dibangun bekerja secara normal.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/4.dm_slack.png" alt="request_url" style="max-width:800px; height:auto;" /> |

Jika Anda mengirim DM ke slackbot

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
Anda dapat melihat bahwa acara tersebut berjalan dengan baik.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/5.slackbot_token.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| Pastikan token tidak terekspos ke luar     |

Sekarang, setelah mendapatkan token slackbot untuk berinteraksi

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

Jika Anda menulis kode seperti ini

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/6.response.png" style="max-width:800px; height:auto;" /> |

Anda dapat melihat pengguna berinteraksi dengan slackbot.

## Implementasi fitur
Akhirnya, pengaturan lingkungan selesai. Sekarang mari kita masuk ke implementasi fungsi yang sebenarnya.

Hal pertama yang harus dipertimbangkan adalah "bagaimana menerima permintaan pengguna".

Awalnya, permintaan pengguna ditangani oleh input teks.

```text
$Ajukan cuti
Liburan: Lee Chang-ho
Tanggal Liburan: 1/7 ~ 12/31
Alasan: alasan pribadi
```
Dengan menandai bot, menginformasikan bahwa "pengguna telah mengirim permintaan", memisahkan permintaan dengan $, dan kemudian mengisi konten sesuai dengan formulir.

Namun, ketika metode ini digunakan, pengguna harus menyalin dan menempelkan konten setiap kali mereka mendaftar untuk menulis konten, dan sisi server harus menerima konten yang diminta dan memprosesnya dengan ekspresi reguler, yang tidak praktis untuk kedua sisi.

Sebagai alternatif untuk ini, modal slackbot ditemukan.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/7.slackbot_modal.png" style="max-width:800px; height:auto;" /> |
| -------------------------------------------------- ---------- ---------- |
| Untuk informasi lebih lanjut, kunjungi https://api.slack.com/surfaces/modals/using|

Modal adalah metode yang membuat formulir sesuai keinginan pengembang dan memproses permintaan jika pengguna hanya memasukkannya sesuai dengan formulir.

Padahal, dengan membuat form terlebih dahulu dengan modal, pengguna hanya perlu menginput nilai dan developer hanya perlu mendapatkan nilai dari format yang telah ditetapkan, sehingga logika yang ada dapat ditangani dengan lebih rapi.

Untuk menggunakan modal, modal harus diatur untuk menangani tindakan pengguna (acara dan tindakan berbeda).

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/8.action_url.png" style="max-width:800px; height:auto;" /> |
| -------------------------------------------------- ---------- ---------- |
| Tidak seperti Langganan Acara, proses verifikasi url terdaftar tidak diperlukan.|

Pertama, daftarkan URL untuk memproses tindakan di slackbot.

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
            "text":"Tinggalkan permintaan",
            
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
    if user_message == "Tinggalkan permintaan":
        slack.chat_postMessage(channel=user, text=user_message, blocks=request_buttons)
```

Tulis kode untuk membuat tombol ketika input tertentu diterima


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
- modal view 코드는 너무 길어서 [링크](/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/modal_view.html){: target="_blank"}로 대체한다.

이렇게 해주면 slackbot을 (드디어)interactive하게 사용할 수 있다.

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/9.interactive_sample.png" style="max-width:800px; height:auto;" /> |

지정한 input이 들어오면 버튼을 생성해주고

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/10.modal.png" style="max-width:800px; height:auto;" /> |
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

| <img src="/assets/2021-07-13-Slackbot을-활용한-ERP-시스템-구축/11.app_home.png" style="max-width:800px; height:auto;" /> |
| ------------------------------------------------------------ |
| 이거 만들려고 원래 있던 코드 싹 갈아 엎고 새로 만들었다.     |

위 기능은 slackbot의 app_home을 활용해 만들었으며, 관련된 내용은 다음에 기회가 된다면 포스팅  할 예정이다.
