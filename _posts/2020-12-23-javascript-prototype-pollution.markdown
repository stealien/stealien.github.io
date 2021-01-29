---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Javascript Prototype Pollution in REALWORLD
date            : 2020-12-23 16:00:00 +0900
category        : R&D
author          : 윤석찬
author_email    : scyoon@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2020-12-23-javascript-prototype-pollution/blog_profile.png
summary         : Introduce Javascript Prototype Pollution Attack and show CVE example
thumbnail       : /assets/2020-12-23-javascript-prototype-pollution/thumbnail.png
---

# Javascript Prototype Pollution in *REALWORD*




## 개요

 웹해킹을 배우고 나서 가장 첫번째로 슬럼프가 왔을 시기가 `APM(Apache + PHP + MySQL)` 환경을 떠나 새로운 환경에서 해킹해야 했을 때였다. Pure PHP에서는 보안 기술을 프로그래머가 직접 구현해야 하는 게 많아서 XSS와 SQL Injection, Webshell Upload 같은 굵직한 취약점을 쉽게 찾을 수 있었는데, 그에 비해 nodejs의 express나 python의 flask, django 같은 현대적인 웹프레임워크에서는 굵직한 취약점을 찾기 어려웠기 때문이다. SQL Injection의 경우도 Pure PHP에서는 addslashes() 함수를 통해 직접 막았던 반면에, Modern Web Framework에서는 아래와 같은 ` ? ` 인자를 통한 자동 매핑 기술이나 ORM (Object Relational Mapping) 기술의 등장으로 인해 database connection framework 자체의 n-day 취약점이 있는 것이 아니면 쉽게 공략하기 어려워졌다.



```javascript
let rows = await Database.query(
	"SELECT * FROM `user` WHERE username = ?", [ username ]
)
```



 ‘*그러면 SQL Injection은 역사 속으로 사라지는 공격이 되는 것이 아닌가?*’ 라는 생각에 한동안 해킹에 흥미가 떨어져 개발만 공부했던 기억이 있다. 하지만 그렇게 생각할 필요도 없는 것이, 아직도 많은 웹 어플리케이션이 잠재적인 보안 취약점을 갖고 있다는 것이다. 스틸리언에서 여러 Pentesting Projects를 경험해보고나서 결국 Modern Web 환경에서도 취약점은 반드시 나올 수 있다는 생각을 갖게 되었다.

 그래서 이 글에서는 현대 웹 프레임워크에 대한 내 인식을 바뀌게 한 취약점을 소개하려 한다. 이 취약점은 간단하면서도, 프로그래머가 해당 취약점을 의식하지 않고 웹 서비스를 구축하면 충분히 나올 수 있을 법한 취약점이다.



## Javascript에서의 객체지향

 Java, Python 같은 여타 프로그래밍 언어처럼 Javascript도 객체지향 언어다. 하지만 객체지향을 구현하는 방법에서 약간의 차이가 있다. 객체지향을 표방한 다른 프로그래밍 언어에서는 ‘class’ 라는 개념을 볼 수 있는데, Javascript에서는 ‘class’라는 개념이 없다. class가 없다는 뜻은 객체지향에서 가장 중요한 기능 중 하나인 상속 기능을 사용하지 못한다는 뜻이다. 그래서 Javascript에는  `prototype`이라는 Javascript 고유 특성을 이용해 상속 기능을 구현했다. `ECMA6` 표준에서 ‘class’ 라는 키워드가 추가되었지만 궁극적으로 Javascript가 class 기반의 객체지향 언어로 바뀌지는 않았다. 흥미로운 사실은 Javascript의 이러한 특성을 이용한 취약점이 있다는 것이다.



## Javascript Prototype Chain 

 앞에서 언급한 것처럼, 자바스크립트에서는 상속을 Prototype 이라는 객체를 사용해서 구현했다. 사실 우리는 상속이 이미된 객체를 사용하고 있다. 자바스크립트에서 객체의 부모는 `__proto__` 로 접근할 수 있다. 다른 프로그래밍 언어의 상속에서 그렇듯, 자식 객체에서 어떠한 변수를 찾을 수 없으면 부모 객체에서 해당 변수를 찾게되는데, Javascript에서는 이것을 Prototype Chain이라고 부른다. 

```javascript
let user = {
	name: ‘scyoon’,
	age: 20,
}

console.log(user.hasOwnProperty(‘name’)); // true
```

[참고] https://poiemaweb.com/js-prototype 

 user라는 객체에서 `hasOwnProperty()` 메소드를 선언하지 않았음에도 호출할 수 있는 이유는 user 객체가 부모 객체에서 `hasOwnProperty()` 메소드를 상속받았기 때문이다. Object 리터럴 (즉, 중괄호 `{ }` 를 통한) 객체 선언 방식은 내부적으로 `new Object();` 이 실행되며 선언되는데, 이러한 이유로 `Object` 객체를 상속받게 되는 것이다. 



### 간단 코드 설명



```javascript
var a = {
    attr1: 'a1'
}

var b = {
    attr2: 'a2'
}

b.__proto__ = a;

b.attr1 // 'a1'
```

[출처] https://meetup.toast.com/posts/104



  `b`에서 부모 객체인 `a`의 attr에 접근할 수 있다. `a`가 부모객체가 된 것이고, `b`가 자식객체가 된 것이다.

 객체 리터럴을 통해 선언한 객체의 부모는 `Object.prototype` 이기 때문에, 객체에서 `undefined`인 속성에 접근할 때 `Object.prototype`에도 해당 속성이 있는지 확인한다. 아래는 이해를 돕기 위한 코드이다.



```javascript
Object.prototype.hi = true;
let foo = {bar: 1};
console.log(foo.hi); // true
console.log(hi); // true
```



`foo`는 객체 리터럴로 생성된 객체이다. 따라서 `foo.__proto__` 는 `Object.prototype`이다. 



## What is Javascript Prototype Pollution ?

 Prototype Pollution이란 Javascript 내부에서 객체지향의 핵심 기술인 상속을 Prototype Chain으로 구현한 점을 이용해, 특정 로직을 우회하거나 코드가 해커가 원하는 방향으로 실행되도록 만드는 공격이다. 위의 내용을 이해했다면 취약점의 원리는 아래의 코드를 보면서 쉽게 이해할 수 있다.



```javascript
let foo = {bar: 1};
let user = {
	name: 'ch4n3.yoon',
	age: 20,
}

foo.__proto__.isAdmin = true;	// exploit

if (user.isAdmin) {
    console.log(`${user.name} is admin`);  // console.log() will be executed
}
```



블랙박스 테스팅보다 npm 처럼 소스코드가 공개되어 있는 프로젝트에서 유용하게 사용할 수 있는 공격이 될 것 같다.



## Javascript Prototype Pollution in *REAL WORLD*

 이 글에서 설명할 CVE는 [CVE-2020-8116](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8116) 이다. `dot-prop`이라는 javascript 패키지에서 발생한 취약점이며, 해당 패키지에 대한 설명은 아래 코드로 대체하겠다.



```javascript
const dotProp = require('dot-prop');
 
// Getter
dotProp.get({foo: {bar: 'unicorn'}}, 'foo.bar');
//=> 'unicorn'
 
dotProp.get({foo: {bar: 'a'}}, 'foo.notDefined.deep');
//=> undefined
 
dotProp.get({foo: {bar: 'a'}}, 'foo.notDefined.deep', 'default value');
//=> 'default value'
 
dotProp.get({foo: {'dot.dot': 'unicorn'}}, 'foo.dot\\.dot');
//=> 'unicorn'
 
// Setter
const object = {foo: {bar: 'a'}};
dotProp.set(object, 'foo.bar', 'b');
console.log(object);
//=> {foo: {bar: 'b'}}
 
const foo = dotProp.set({}, 'foo.bar', 'c');
console.log(foo);
//=> {foo: {bar: 'c'}}
 
dotProp.set(object, 'foo.baz', 'x');
console.log(object);
//=> {foo: {bar: 'b', baz: 'x'}}
 
// Has
dotProp.has({foo: {bar: 'unicorn'}}, 'foo.bar');
//=> true
 
// Deleter
const object = {foo: {bar: 'a'}};
dotProp.delete(object, 'foo.bar');
console.log(object);
//=> {foo: {}}
 
object.foo.bar = {x: 'y', y: 'x'};
dotProp.delete(object, 'foo.bar.x');
console.log(object);
//=> {foo: {bar: {y: 'x'}}}
```





  `CVE-2020-8116`은 `CVSS SCORE`로 6.3 점을 받았을 만큼 무시할 수만은 없는 취약점이다. 하지만 취약점의 위험도에 비해 그 원리는 너무나 단순하다.  이 취약점의 PoC이다. 



```javascript
const dotProp = require("dot-prop")
const object = {};
console.log("Before " + object.b); //Undefined
dotProp.set(object, '__proto__.b', true);
console.log("After " + {}.b); //true
```



 객체 리터럴이 Object.prototype을 참조하는데, Object.prototype에 b가 `true`로 지정되어 있기 때문에 제일 마지막 console.log 에서는 `undefined`가 아닌 `true`가 출력된다. Prototype Pollution이 발생한 것이다. 내부 코드를 보면 더욱 별거 아니다.



```javascript
set(object, path, value) {
	if (!isObj(object) || typeof path !== 'string') {
		return object;
	}

	const root = object;
	const pathArray = getPathSegments(path);

	for (let i = 0; i < pathArray.length; i++) {
		const p = pathArray[i];

		if (!isObj(object[p])) {
			object[p] = {};
		}

		if (i === pathArray.length - 1) {
			object[p] = value;	// exploitable !
		}

		object = object[p];
	}

	return root;
}
```



 `set()` 메소드를 실행 시, `__proto__`에 대한 검증을 하지 않았기 때문에 취약점이 발생했다. 해당 취약점을 막기 위해 `dot-prop` 패키지에서는 `disallowedKeys` 변수를 exploitable한 부분에서 검증하는 로직을 추가했다.



```javascript
const disallowedKeys = new Set([
	'__proto__',
	'prototype',
	'constructor'
]);
```



 [이 링크](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=prototype+pollution )에 방문하면 `dot-prop` 모듈 이외에 생각보다 많은 모듈이 Prototype Pollution에 취약했음을 알 수 있다. 



## 결론

 어떤 소프트웨어라도 취약점이 존재할 수 있다. 이것을 발견할 수 있는 가장 중요한 요인 중 하나는 해커의 마음가짐이라고 생각한다. 





special thx to @munsiwoo