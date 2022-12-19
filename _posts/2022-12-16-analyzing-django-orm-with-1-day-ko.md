---
layout        : post
markdown    : kramdown
highlighter    : rouge
title        : Analyzing Django ORM with 1-day vulnerabilities and sql bug
date        : 2022-12-16 00:00:00 +0900
category    : R&D
author        : Seokchan Yoon
author_email: scyoon@stealien.com
background    : /assets/bg.png
profile_image: /assets/2022-10-04-Secure-Coding-Training-System/profile.jpeg
summary        : "Let's analyze django, the king of Python web library"
thumbnail    : /assets/stealien.png
lang        : ko
permalink   : /2022-12-16/analyzing-django-orm-with-1-day
---

<br>
<div style="text-align: left">목차</div>
<div style="text-align: left">
    <a href="#0-introduction">0. Introduction</a>
</div>
<div style="text-align: left">
    <a href="#1-how-does-django-execute-sql-query">1. How does Django execute SQL query?</a>
</div>
<div style="text-align: left">
    <a href="#2-cve-2022-28346">2. CVE-2022-28346</a>
</div>
<div style="text-align: left">
    <a href="#3-cve-2022-28347">3. CVE-2022-28347</a>
</div>
<div style="text-align: left">
    <a href="#4-cve-2022-34265">4. CVE-2022-34265</a>
</div>
<div style="text-align: left">
    <a href="#5-django-single-quote-unescaping-bug-in-keytransform-class">5. Django Single Quote Unescaped Bug</a>
</div>
<div style="text-align: left">
    <a href="#6-끝으로">6. 끝으로</a>
</div>


<br>

# 0. Introduction

안녕하세요. 스틸리언 R&D팀 윤석찬 연구원입니다. 이번 차례에도 제가 기술블로그에 글을 쓰게 되었습니다. 벌써 12월이 되었는데 다들 올해 원하시던 목표 이루셨는지요? 제가 올해 세웠던 목표 중 하나는 Python의 `Django` 나 `Flask`, NodeJS의  `express.js` 처럼 대중적으로 사용되는 웹 프레임워크에서 유의미한 보안 취약점을 찾아서 제보하는 것이었습니다. 결과적으로 말씀드리자면 목표를 달성하진 못했지만, 그래도 Django라는 국제적으로 유명한 대형 오픈소스 프로젝트를 분석하면서 배웠던 점이 많았던 것 같습니다.

이 글에서는 2022년에 제보된 Django 1-day 취약점들과 제가 발견한 SQL Single Quote Unescaped Bug를 소개하고자 합니다. 글이 다소 길고 첨부된 소스코드가 많아서 PC에서 보시는 것을 추천드립니다.

_

올해는 Django 버전이 4.0으로 업그레이드된 첫 해로, 저 같이 Django를 즐겨서 사용하는 사용자로서는 의미있는 한해였다고 생각합니다. 4.0으로 업데이트되면서 뷰에서 `async` 기능을 사용할 수 있게 되었고, `JSONField`, `ArrayField`, `BigAutoField` 같은 새로운 데이터베이스 Field Type이 등장하기도 했습니다. 실제로 어떤 기능이 업데이트되었는지는 아래 링크에서 자세히 확인해볼 수 있습니다.

> [https://docs.djangoproject.com/en/4.1/releases/4.0/](https://docs.djangoproject.com/en/4.1/releases/4.0/)
<br/>
<br/>

올해도 Django에 여러 취약점이 제보되었습니다. 2021년 12월 6일 배포된 Django 4.0을 기준으로, 2022년에 `Severity Level`\*이 **`Critical`** 로 분류된 취약점은 총 3건이었고 모두 SQL Injection 취약점이었습니다. 

\* `Severity Level`은 보안 취약점은 파급력에 따라 `Low`, `Medium`, `High`, `Critical` 4가지 등급으로 분류됩니다. 이 중 `Critical` 등급은 가장 파급력이 높은 보안 취약점으로 평가됩니다.

Django는 2005년에 처음 시작되어 올해로 18년 째 유지되고 있는 대형 프로젝트입니다. 이 프로젝트에서 절대 발견되지 않을 것 같았던 SQL Injection 취약점이,  그것도 3개나 연달아서 발견되는 것은 이례적인 일이라고 생각해서 관심을 갖게 되었습니다. Django에 제보된 취약점은 아래 링크에서 확인해보실 수 있습니다.

> [https://security.snyk.io/package/pip/django](https://security.snyk.io/package/pip/django)

* [CVE-2022-28346](https://www.cve.org/CVERecord?id=CVE-2022-28346)
* [CVE-2022-28347](https://www.cve.org/CVERecord?id=CVE-2022-28347)
* [CVE-2022-34265](https://www.cve.org/CVERecord?id=CVE-2022-34265)


<br>

# 1. How does Django execute SQL query?

Django에서는 ORM으로 SQL을 어떻게 실행하는지 알아둘 필요가 있습니다. 아래 링크에 Django ORM이 실제로 어떻게 쿼리를 만들고 실행하는지 정리해두었습니다.

> [How does Django execute SQL Query?](https://blog.ch4n3.kr/569)

<br>

# 2. CVE-2022-28346
**CVE-2022-28346: Potential SQL injection in ``QuerySet.annotate()``, ``aggregate()``, and `extra()`**

- [https://github.com/django/django/commit/93cae5cb2f9a4ef1514cf1a41f714fef08005200](https://github.com/django/django/commit/93cae5cb2f9a4ef1514cf1a41f714fef08005200)

취약점이 발생하는 메소드는 `django.db.models.query`에 지정된 `QuerySet` 클래스 내의  `annotate()`, `aggregate()`, `extra()` 메소드로, 이 세 메소드는 공통적으로 alias 기능이 내포되어 있다는 특징이 있습니다. 예를 들어 `annotate()` 메소드는 아래와 같이 사용합니다. 아래 예시를 보면 `Count()` 결과 값을 `num_books` 라는 이름으로 alias 처리하는 것을 볼 수 있습니다.

![Pasted image 20221216162758.png](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221216162758.png)


결과적으로 말하자면 이 취약점은 `annotate()` 메소드에 `kwargs` 방식으로 전달하여, `kwargs`의 `key` 값으로 alias를 지정할 때 이 `key` 값을 검증하지 않기 때문에 발생합니다. `annotate()` 메소드를 수행하면 내부적으로는 아래와 같은 과정을 거칩니다.


## 2-1. `QuerySet.annotate()`

`annotate()` 메소드를 실행하면 `QuerySet` 클래스 내부 `_annotate()` 메소드 실행합니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/1.png)

## 2-2. `QuerySet._annotate()`
![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/2.png)

`_annotate()` 메소드에서는 `kwargs`로 전달된 정보를 내부 변수 `annotations`에 저장하고, 이를 `Query` 클래스의 `add_annnotation()`에 전달합니다.


## 2-3. `Query.add_annotation()`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/3.png)

`Query` 클래스에서는 이전 `QuerySet._annotate()` 에서 전달된 `annotations`를 내부 `self.annotations`에 설정하여 Alias 기능을 구현합니다. 그리고 다른 클래스에서 설정된 `self.annotations`를 가져올 때 `@property`로 설정된 `annotation_slect()` 함수를 실행해서 `self.annotations`를 반환합니다.


## 2-4. `django.db.models.sql.compiler`
![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221218152519.png)

`SQLCompiler` 클래스의 `as_sql()` 메소드는 실제 실행될 SQL 쿼리를 만듭니다. `self.select`에 저장된 값을 SQL `AS` 구문으로 쿼리를 생성합니다. `QuerySet`클래스의 `annotate()` 메소드를 실행할 때 전달한 `kwargs`의 키 값은 `self.connection.ops.quote_name()` 을 거쳐 SQL에 들어갑니다. 이 `quote_name()` 메소드는 각 DBMS 별로 정의되어 있습니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221218152848.png)

MySQL을 예로 들자면 Backtick 문자로 지정해주는 것을 볼 수 있습니다. 하지만 이 전까지 `key` 값에 대한 escape 처리가 없었기 때문에 여기서 SQL Injection 취약점이 발생할 수 있습니다.

## 2-5. 패치

해당 취약점은 Django 4.0.4에서 수정되었고  `django.db.models.sql.query.Query` 클래스에서 `add_annotation()` 메소드를 수행할 때 내부적으로 `check_alias()` 메소드를 호출하는 식으로 취약점이 제거되었습니다. 

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221218153153.png)

<br/>

# 3. CVE-2022-28347
**CVE-2022-28347: Potential SQL injection via `QuerySet.explain(**options)` on PostgreSQL**

이 취약점은 PostgreSQL 환경에서 Django `QuerySet`의 `explain()` 메소드를 수행할 때 발생 가능한 SQL Injection 취약점입니다.
- [https://github.com/advisories/GHSA-w24h-v9qh-8gxj](https://github.com/advisories/GHSA-w24h-v9qh-8gxj)



![explain()](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted image 20221218043457.png)
[https://docs.djangoproject.com/en/4.1/ref/models/querysets/#explain](https://docs.djangoproject.com/en/4.1/ref/models/querysets/#explain)

Django Project Docs에는 위 예시가 작성되어 있습니다. 위 예시처럼 `explain()`은 실행하고자하는 데이터베이스 쿼리의 성능을 테스트하는 메소드입니다. 이 메소드를 실행하면 SQL의 `EXPLAIN` 명령을 사용할 수 있고, MySQL과 PostgreSQL에서는 특별히 EXPLAIN에 옵션까지 지정이 가능합니다.


이때 explain() 메소드의 구현에서 SQL Injection이 가능했던 CVE-2022-28347 취약점을 분석해보고자 합니다.


## 3-1. `QuerySet`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/4.png)

`QuerySet` 클래스의 `explain()` 메소드는 위와 같이 정의되었습니다. 내부적으로 `self.query.explain()`를 수행합니다. `self.query`는 `django/db/models/sql/query.py`에 정의된 `Query` 클래스의 객체입니다.


## 3-2. `Query`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/5.png)

`Query`클래스의 `explain()` 메소드는 `get_compiler()` 메소드를 통해 `compiler`를 가져오고 사용하는 DB에 맞추어 `django.db.models.sql.compiler.SQLCompiler`를 상속한 클래스의 `explain_query()` 메소드를 실행시켜줍니다. **여기서 kwargs 형식으로 인자를 받는 `**options`, 그리고 `q.explain_info`가 `ExplainInfo` 객체로 설정되었음을 기억해야합니다.**


## 3-3. `SQLCompiler`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/6.png)

`SQLCompiler` 클래스 내부의 `explain_query()` 메소드에서는 동일 클래스의 `execute_sql()`를 실행합니다. `execute_sql()` 메소드는 실제로 `self.as_sql()` 메소드를 실행해서 컴파일된 SQL Query구문을 실행하는 메소드입니다. 실제 쿼리를 생성하는 `as_sql()` 메소드는 각 DBMS마다 정의된 `explain_query_prefix()` 메소드를 실행합니다.


## 3-4. `django/db/backends/postgresql/operations.py`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/7.png)

Postgresql을 위해 정의된 `explain_query_prefix()` 메소드입니다. 앞서 `QuerySet` 클래스의 `explain()` 메소드를 설명할 때 `**options`에 kwargs 형식으로 `dict` 형식의 값이 들어갈 수 있음을 언급했습니다. 이 값이 그대로 `explain_query_prefix()` 메소드에 전달되며 `prefix` 에 그대로 쿼리가 저장되면서, `options`에 저장된 `dict` 값 key 부분에서 SQL Injection이 가능해집니다.

## 3-5. 패치

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/8.png)

이 취약점은 `DatabaseOperations` 클래스에 `explain_options` 변수를 두어 `key` 부분에 대한 검증 로직이 추가되며 수정되었습니다. 아무래도 `options`의 key에 여러 값이 들어갈 수 있다보니, Django 사용자가 변수로 전달할 수 있는 여지를 인정한 것 같습니다.

<br/>

# 4. CVE-2022-34265
**CVE-2022-34265: Potential SQL injection via ``Trunc(kind)`` and ``Extract(lookup_name)`` arguments.**
- [https://github.com/django/django/commit/284b188a4194e8fa5d72a73b09a869d7dd9f0dc5](https://github.com/django/django/commit/284b188a4194e8fa5d72a73b09a869d7dd9f0dc5 )

이 취약점은 `django/db/models/query.py` 에 정의된 `QuerySet` 클래스의 `dates()` 메소드로부터 시작됩니다. `dates()` 메소드의 쓰임은 아래 `docs.djangoproject.com` 링크에서 확인할 수 있습니다. 이 메소드는 내부적으로 `Trunc` 클래스를 사용하는데, `Trunc` 클래스에서 취약점이 발견되었습니다.
* `dates()` : [https://docs.djangoproject.com/en/4.0/ref/models/querysets/#dates](https://docs.djangoproject.com/en/4.0/ref/models/querysets/#dates )

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221218033513.png)

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/12.png)


## 4-1. `Trunc` 

위와 같이 `dates()` 메소드는 `DateField`로 지정된 `field`를 `datetime.date` 객체로 반환해주는 역할을 합니다. `dates()` 메소드를 실행할 때는 첫번째 `field` 인자 두번째 `kind` 인자를 넘깁니다. 이 중 두번째 `kind` 인자는  `str` 형식의 값을 받으며, `django/db/models/functions/datetime.py`에 정의된 `Trunc` 클래스에 인자로 넘겨집니다. 

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/9.png)

위 `Trunc` 클래스는 `TruncBase` 클래스를 상속받은 형태로, `DateField` 를 `datetime.date` 객체로 변환시켜주는 클래스입니다. `__init__()` 메소드에서 `expression`, `kind` 를 받아 내부 property로 저장합니다. Django Project Docs에 올라온 예시를 보았을 때 두 파라미터 모두 `str` 형식으로 사용자의 입력값이 충분히 들어갈 수 있습니다. 결과적으로 `expression` 파라미터는 부모클래스 `__init__()` 메소드에 전해지며 `django/db/models/expressions.py` 에 정의된 `F` 클래스로 저장됩니다. **하지만 `kind` 는 아무런 검증 없이 `self.kind` 에 저장된다는 점을 기억해두어야 합니다.**


## 4-2. `TruncBase` 

실질적으로 Django ORM으로 `QuerySet` 클래스를 SQL 쿼리로 변환하는 기능은, 동일 파일에 정의된 `TruncBase` 클래스의 `as_sql()` 메소드로 정의되어 있기 때문에 다음은 `TruncBase` 클래스를 분석해보는 것으로 합니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/10.png)

이는 인자로 넘겨진 `self.output_field` 변수의 type 별로 `datetime_trunc_sql()`, `date_trunc_sql()`, `time_trunc_sql()` 메소드를 호출합니다. 여기서 세 메소드 모두 이전 `Trunc` 클래스에서 사용자로부터 아무런 검증없이 받을 수 있는  `self.kind` 를 인자로 취한다는 점이 중요합니다. 이 메소드들은 각 데이터베이스 문법에 따라 각각 정의되어 있으며, 예시로 SQLite3에서는 아래와 같이 구현되었습니다.

## 4-3. `DatabaseOperations`

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/11.png)

두 번째에 전달되는 인자 `lookup_type`에는 이전 `Trunc` 클래스에서 사용자로부터 받은 인자 `kind` 가 전달이 되는데, 실제 SQL Query를 만들기까지 `kind` 값에 대한 아무런 검증이 없습니다. 때문에 `kind` 값을 통해 SQL Injection이 가능합니다.


## 4-4. 패치

`django/db/models/functions/datetime.py`에 정의된 `TruncBase` 클래스의 `as_sql()` 메소드에 아래처럼 변경되었습니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/13.png)

`as_sql()` 메소드를 호출하고 나서 `extract_trunc_lookup_pattern`을 인자로 넘겨진 `kind` 값과 정규식 기능을 통해 비교합니다. 정규식으로 검사하는 값은 `_lazy_re_compile(r"[\w\-_()]+")` 으로, `dates()` 메소드의 인자 `kind`에 특수문자를 사용하지 못하도록 하여 SQL Injection 취약점을 수정했습니다. 


<br/>


# 5. Django Single Quote Unescaping Bug in `KeyTransform` class

위 세 개의 취약점이 크게 인상깊어서 올해 6월 경부터 Django 프레임워크에서 SQL Injection 취약점을 찾아내겠다는 목표를 갖고 취약점 분석을 시작했습니다. 그래서 결국 Oracle 데이터베이스 환경에서 특정 기능을 이용할 때 특수문자가 unescaped 되어 SQL 쿼리를 탈출할 수 있는 버그를 찾았습니다.

## 5-1. `KeyTransform`

`django.db.models.fields.json`에 정의된 `KeyTransform` 클래스는 MySQL의 `JSON_EXTRACT()` 함수를 Django ORM으로 구현하기 위해 만들어졌습니다. 아래는 `KeyTransform` 클래스의 `as_mysql()` 메소드가 정의된 부분입니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/14.png)

MySQL에서 사용되는 `JSON_EXTRACT()` 함수의 사용 예는 아래와 같습니다. 첫번째 인자로 JSON Document를 받고, 두 번째 인자로 Path를 받습니다. 아래 예시처럼 사용하여 JSON Document의 Path에 해당되는 값을 불러올 수 있습니다. 

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221217022516.png)

## 5-2. `KeyTransform.as_oracle()`

Django에서는 MySQL의 `JSON_EXTRACT()` 함수를 다른 DBMS에서도 사용할 수 있도록 하기 위해 아래와 같이 여러 함수를 중첩적으로 사용하여 구현해두었습니다. 아래는 Oracle DB 환경에서 `JSON_EXTRACT()` 함수를 구현해둔 것입니다. 

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/15.png)


## 5-3. `KeyTransform.preprocess_lhs()`

우선 첫번째로 호출하는 `self.preprocess_lhs()`를 분석해볼 필요가 있습니다. `lhs`는 Left-Hand Side의 줄임말로, Django에서는 내부적으로 쿼리를 생성할 때 사용되는 일종의 접미사라고 볼 수 있습니다. 이 메소드의 내용은 아래와 같습니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/16.png)

이 메소드에서는 기존 JSON에서 사용되는 특수문자를 escape 처리하기 위해 `key_transforms` 라는 변수를 반환합니다. 이 변수는 `__init__`에서 만들어진 값이며 클래스 생성 시 전달한 `key_name` 값이 저장되어 있습니다.

## 5-4. `compile_json_path()` 

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/17.png)

다시 `as_oracle()` 메소드로 돌아와서, `key_transforms` 변수를 `compile_json_path()`의 인자로 전달하는 것을 볼 수 있습니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/18.png)

이 `compile_json_path()` 함수는 인자로 받은 `key_trancsforms` 값이 `int()`를 호출할 때 Exception이 난다면 `json.dumps()` 를 통해 변수를 JSON 형식으로 저장해 반환해줍니다. 이때 `json.dumps()`는 백슬래시와 더블쿼터를 escape처리하는데, 싱글쿼터(`'`)는 백슬래시를 통해 처리되지 않기 때문에 SQL Query에 영향을 끼칠 수 있습니다.

## 5-5. BOOM!

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/19.png)

또 다시 `as_oracle()` 메소드로 돌아와서 확인해보면, 싱글쿼터가 그대로 들어갈 수 있는 `json_path` 가 Format String으로 `JSON_QUERY()`, `JSON_VALUE()` 함수 안에 그대로 들어가는 것을 확인할 수 있습니다.

![image](/assets/2022-12-16-analyzing-django-orm-with-1-day/Pasted%20image%2020221217030925.png)

따라서, 어떤 Django Application의 `views.py`에 위와 같은 코드가 있다면 실제 Single Quotes Unescaped Bug를 트리거 할 수 있습니다.


## 5-6. 한계

이 버그는 실제 SQL Injection 공격까지 트리거 할 수 없습니다. ORACLE DBMS에서는 MySQL에서와 다르게 모든 함수의 각 인자를 검증하는 과정이 있기 때문입니다. 이번 SQL Injection 취약점은 `JSON_QUERY()` 함수에서 SQL Injection 취약점이 두번째 문자열 인자에서 트리거되는데, 이때 Oracle DB의 유효성 검증을 우회하지 못합니다. Oracle DB는 MySQL처럼 SQL 구문을 자유자재로 다루기가 힘들기 때문입니다.

<br />

# 6. 끝으로..

대형 오픈소스 프레임워크를 분석해보면 배울 수 있는 점이 많습니다. 이번에 분석해본 Django의 경우에는 훌륭한 객체지향 디자인을 기반으로, Python의 가치를 최대화하여 작성된 프레임워크였던 것 같습니다. Django가 어떻게 구현되었는지 확인해보면서 부족했던 저의 프로그래밍, 소프트웨어 구조화 등 암묵지 실력을 키울 수 있었다고 생각합니다.


하지만 프레임워크라는 것이 프로그래머마다 구현하기 나름이라, 사용하고 있는 Django의 버전에 1-day 취약점이 존재해도 어떻게 구현하느냐에 따라 취약점이 발생하지 않을 수 있습니다. 이것을 보통 generic하지 않다고 표현하기도 하는데, 프레임워크 분석할 때 이 부분이 조금 아쉬운 부분이긴 합니다.


이 글은 Obsidian으로 제텔카스텐 기법을 써서 작성되었습니다. 제텔카스텐을 알려주시고 개인적으로 제게 큰 힘과 용기를 북돋아주신 호정님께 이 글을 빌려 감사인사를 드리고 싶습니다.