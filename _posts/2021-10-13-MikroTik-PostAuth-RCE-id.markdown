---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: "MikroTik Post-Auth execve() call."
date		: 2021-10-13 19:00:00 +0900
category	: R&D
author		: 김도현
author_email: dhkim@stealien.com
background	: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary		: MikroTik Post-Auth execve() call.
thumbnail	:  /assets/posts/thumbnails/20200619.jpg
lang        : id
permalink   : /2021-10-13/MikroTik-PostAuth-RCE
---

# MikroTik panggilan sewenang-wenang execve() (Post Authentication)
- Mempengaruhi versi: 6.48.3 hingga 6.48.? (tidak diperiksa. maaf.)
- Dampak : Rendah
- Kesulitan: Rendah

## Laporan
Kerentanan ini...

- Ditemukan di MikroTik RouterOS 6.48.3.
- Terjadi terlepas dari pengaturan perangkat.
- Terjadi di komponen /nova/bin/mepty.
- Kerentanan ada di fungsi sub_804B2BC().
- Terakhir, pengguna jahat dapat membuat proses melalui arbitrary execve().

### Analisis Root Cause
```c++
int sub_804B2BC()
{
    ...

    v52 = nv::message::get<nv::u32_id>(a2, 8);
    v12 = (const string *)nv::message::get<nv::string_id>(a2, 9);
    string::string(&v60, v12); // [1]

    ...

    if ( v59 )
        setenv("TERM", (const char *)(v59 + 4), 1);
    v30 = s // [2]

    ...

    switch (...)
    {
        ...
        case 4:
            snprintf(s, 0x50u, "%s", (const char *)(v60 + 4));
            execl("/nova/bin/telser", "telser", s, 0);
            *(_DWORD *)s = "/nova/bin/telnet";
            argv = "/nova/bin/telnet" + 10;
            v31 = "-4";
            if ( v15 )
                v31 = "-6";
            v71 = v31;
            v30 = (char *)&v72;
            break;
        default:
            break; // [3]
        ...
    }

    ...

    *(_DWORD *)v30 = v60 + 4; // [4]
    *((_DWORD *)v30 + 1) = 0;
    string::string((string *)&v56, *(const char **)s); // [5]
    nv::findFile((nv *)&v55, (const string *)&v56, 0); // [6]
    execv((const char *)(v55 + 4), &argv); // [7]

    ...
}
```

1. Tetapkan string argumen 9 ke `v60`. (`s9` dalam kode eksploit)
2. Pengganti s untuk `v30`.
3. Dalam pernyataan `default`, **tidak ada tindakan yang tepat yang diambil, seperti menginisialisasi variabel yang dialokasikan atau menghentikan fungsi.**
4. Ganti `v60+4` (alamat string yang sebenarnya) untuk *v30.
5. Tetapkan s ke `v56`. Di sini, `s` berisi nilai (`s9`) yang dimasukkan pada langkah 4.
6. Anda dapat menelurkan proses apa pun yang Anda inginkan melalui `execve()`.

### Mengeksploitasi
- Anda dapat memanfaatkan kerentanan ini untuk mendapatkan hak administrator di perangkat.

### Membatasi
- Anda akhirnya dapat memperoleh izin hanya dengan memberikan izin eksekusi ke biner yang diunggah secara sewenang-wenang dan menjalankannya.
- Kerentanan tersedia setelah otentikasi (login).

## Kode serangan
- https://github.com/d0now/vulnerabilities/MikroTik_RouterOS/2021-10-13-post-auth-execve/exploit.py
