# Lab8 文件系统实验报告

## 小组成员
- 2311990 郭佳成
- 2312300 曲恒睿
- 2311024 李佳琦

---

## 实验目的

1. 理解文件系统的基本概念和实现原理
2. 掌握Simple File System (SFS) 的设计与实现
3. 理解VFS抽象层的作用
4. 实现基于文件系统的程序加载机制
5. 理解进程间通信机制（管道）的设计

---

## 练习0：填写已有实验

本实验依赖实验2/3/4/5/6/7。由于跳过了lab7，需要额外补充条件变量的实现。

### 主要填写内容概览

| 文件 | 函数 | 修改内容 |
|------|------|----------|
| kern/process/proc.c | alloc_proc | 初始化filesp字段 |
| kern/process/proc.c | do_fork | 添加copy_files调用 |
| kern/process/proc.c | proc_run | 添加flush_tlb调用 |
| kern/mm/pmm.c | copy_range | 实现页面复制 |
| kern/sync/monitor.c | cond_signal | 条件变量signal |
| kern/sync/monitor.c | cond_wait | 条件变量wait |
| kern/sync/check_sync.c | phi_take_forks_condvar | 哲学家拿叉子 |
| kern/sync/check_sync.c | phi_put_forks_condvar | 哲学家放叉子 |

### 1. alloc_proc (kern/process/proc.c)

在进程控制块初始化时，需要初始化lab8新增的文件系统相关字段：

```c
static struct proc_struct *alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        // ... 之前lab的初始化代码 ...

        // lab8新增：初始化文件结构指针
        // filesp指向files_struct，管理进程打开的所有文件
        proc->filesp = NULL;
    }
    return proc;
}
```

**设计思路**：每个进程都有自己的文件描述符表，通过filesp字段访问。初始为NULL，在进程创建时由copy_files或files_create分配。

### 2. do_fork (kern/process/proc.c)

fork时需要复制父进程的文件描述符表：

```c
// 在setup_kstack之后，copy_mm之前添加
if ((ret = copy_files(clone_flags, proc)) != 0) {
    goto bad_fork_cleanup_kstack;
}
```

**设计思路**：
- 如果设置了CLONE_FS标志，子进程共享父进程的文件描述符表
- 否则复制一份独立的文件描述符表
- 这样子进程可以独立地打开、关闭文件

### 3. copy_range (kern/mm/pmm.c)

**这是本次实验最关键的修复！** 之前这个函数是空的，导致fork后子进程没有正确的页面映射。

```c
/*
 * copy_range的作用：fork时复制父进程的页面到子进程
 *
 * 为什么不能直接让子进程共享父进程的页面？
 * 因为fork后父子进程的内存空间是独立的，一个进程修改不应影响另一个
 */

// (1) 获取父进程页面的内核虚拟地址
void *src_kvaddr = page2kva(page);

// (2) 获取子进程新分配页面的内核虚拟地址
void *dst_kvaddr = page2kva(npage);

// (3) 复制整个页面的内容（4KB）
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);

// (4) 在子进程的页表中建立映射
ret = page_insert(to, npage, start, perm);
```

**设计思路**：
- `page2kva`: 将物理页面转换为内核虚拟地址，这样内核代码可以访问
- `memcpy`: 复制整个4KB页面的内容
- `page_insert`: 在子进程页表中建立虚拟地址到新物理页的映射

### 4. LAB7 管程相关代码

由于跳过了lab7，需要补充条件变量的实现。

#### cond_signal函数 (kern/sync/monitor.c)

```c
void cond_signal(condvar_t *cvp) {
    /*
     * Hansen管程语义：signal后让出控制权给被唤醒的线程
     */
    if (cvp->count > 0) {        // 有线程在等待
        monitor_t* const mtp = cvp->owner;
        mtp->next_count++;       // 我要等待了
        up(&(cvp->sem));         // 唤醒等待的线程
        down(&(mtp->next));      // 自己睡眠
        mtp->next_count--;       // 被唤醒了
    }
}
```

#### cond_wait函数 (kern/sync/monitor.c)

```c
void cond_wait(condvar_t *cvp) {
    cvp->count++;                // 等待计数+1
    monitor_t* const mtp = cvp->owner;

    // 释放锁让其他线程执行
    if (mtp->next_count > 0) {
        up(&(mtp->next));        // 唤醒signal等待的线程
    } else {
        up(&(mtp->mutex));       // 释放管程互斥锁
    }

    down(&(cvp->sem));           // 在条件变量上等待
    cvp->count--;                // 被唤醒了
}
```

**设计思路**：使用Hansen管程语义，signal后立即让出控制权。通过next信号量和next_count实现signal线程的等待和唤醒。

---

## 练习1：完成读文件操作的实现

### 1.1 问题分析

`sfs_io_nolock`函数需要实现文件的读写操作。主要挑战在于处理非对齐的情况：

```
假设要读取offset=1000, len=5000的数据，块大小为4096:

   块0         块1         块2
[0...1000...4096...8192...9096]
      ^                    ^
   offset              endpos

   - 第一块: 从1000读到4096 (读3096字节，不完整块)
   - 第二块: 从4096读到8192 (读4096字节，完整块)
   - 第三块: 从8192读到6000 (读904字节，不完整块)
```

### 1.2 代码实现

```c
static int
sfs_io_nolock(struct sfs_fs *sfs, struct sfs_inode *sin, void *buf,
              off_t offset, size_t *alenp, bool write) {
    // ... 前置检查代码 ...

    // 选择读或写的操作函数
    int (*sfs_buf_op)(struct sfs_fs *sfs, void *buf, size_t len,
                      uint32_t blkno, off_t offset);
    int (*sfs_block_op)(struct sfs_fs *sfs, void *buf, uint32_t blkno,
                        uint32_t nblks);
    if (write) {
        sfs_buf_op = sfs_wbuf, sfs_block_op = sfs_wblock;
    } else {
        sfs_buf_op = sfs_rbuf, sfs_block_op = sfs_rblock;
    }

    // (1) 处理起始位置未对齐的情况
    blkoff = offset % SFS_BLKSIZE;
    if (blkoff != 0) {
        size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);

        // sfs_bmap_load_nolock: 逻辑块号 -> 物理块号
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        // sfs_buf_op: 读写块内的部分数据
        if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
            goto out;
        }
        alen += size;
        buf += size;
        if (nblks == 0) goto out;
        blkno++;
        nblks--;
    }

    // (2) 处理中间对齐的完整块
    while (nblks > 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        // sfs_block_op: 读写整块，效率最高
        if ((ret = sfs_block_op(sfs, buf, ino, 1)) != 0) {
            goto out;
        }
        alen += SFS_BLKSIZE;
        buf += SFS_BLKSIZE;
        blkno++;
        nblks--;
    }

    // (3) 处理末尾未对齐的部分
    size = endpos % SFS_BLKSIZE;
    if (size != 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
            goto out;
        }
        alen += size;
    }
    // ...
}
```

### 1.3 关键函数说明

| 函数 | 作用 |
|------|------|
| `sfs_bmap_load_nolock` | 将逻辑块号转换为物理块号 |
| `sfs_rbuf/sfs_wbuf` | 读写块内的部分数据 |
| `sfs_rblock/sfs_wblock` | 读写整块数据 |

### 1.4 UNIX的PIPE机制设计方案

管道是UNIX系统中最基本的进程间通信机制。

#### 数据结构设计

```c
#define PIPE_BUF_SIZE 4096

struct pipe_struct {
    char buffer[PIPE_BUF_SIZE];     // 环形缓冲区
    uint32_t read_pos;               // 读位置
    uint32_t write_pos;              // 写位置
    uint32_t data_size;              // 当前数据量

    semaphore_t mutex;               // 互斥信号量
    semaphore_t read_sem;            // 读信号量（用于阻塞）
    semaphore_t write_sem;           // 写信号量（用于阻塞）

    int read_open;                   // 读端是否打开
    int write_open;                  // 写端是否打开
    int ref_count;                   // 引用计数
};
```

#### 接口设计

```c
// 创建管道，fd[0]为读端，fd[1]为写端
int pipe(int fd[2]);

// 从管道读取数据
ssize_t pipe_read(struct pipe_struct *pipe, void *buf, size_t len);

// 向管道写入数据
ssize_t pipe_write(struct pipe_struct *pipe, const void *buf, size_t len);
```

#### 同步机制

1. **互斥访问**：使用mutex信号量保护缓冲区
2. **读阻塞**：缓冲区为空时，读者等待read_sem
3. **写阻塞**：缓冲区满时，写者等待write_sem
4. **EOF处理**：写端关闭后，读者读完剩余数据返回0

---

## 练习2：完成基于文件系统的执行程序机制

### 2.1 问题分析

`load_icode`函数需要从文件系统加载ELF可执行文件。与lab5相比：
- lab5：程序在内存中，直接memcpy
- lab8：程序在文件系统中，需要通过文件接口读取

### 2.2 实现流程

```
1. 创建mm结构体
      │
      ▼
2. 创建页目录表
      │
      ▼
3. 读取ELF头 ─────────────────┐
      │                       │
      ▼                       │ 循环处理每个段
4. 遍历程序头表 ◄─────────────┘
      │
      ├── 设置VMA权限
      ├── 分配物理页
      └── 从文件读取内容
      │
      ▼
5. 设置用户栈
      │
      ▼
6. 设置argc/argv
      │
      ▼
7. 设置trapframe
```

### 2.3 用户栈布局

```
USTACKTOP  ─────────────────────
           │  "ls\0"             │  ← 参数字符串
           │  "-l\0"             │
           ├─────────────────────┤
           │  argv[0] → "ls"     │  ← argv指针数组
           │  argv[1] → "-l"     │
           ├─────────────────────┤
    sp →   │  (16字节对齐填充)   │
           ─────────────────────
```

### 2.4 关键代码

```c
static int load_icode(int fd, int argc, char **kargv) {
    // (1) 创建mm
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }

    // (2) 创建页目录
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }

    // (3) 读取ELF头
    if ((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0) {
        goto bad_elf_cleanup_pgdir;
    }

    // (3.2) 加载各个程序段
    for (phnum = 0; phnum < elf->e_phnum; phnum++) {
        // 读取程序头
        // 设置VMA和权限
        // 分配页面并从文件读取内容
    }

    // (4) 设置用户栈
    mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL);

    // (5) 切换页表
    current->mm = mm;
    current->pgdir = PADDR(mm->pgdir);
    lsatp(PADDR(mm->pgdir));

    // (6) 设置argc/argv到栈上
    // ... 见代码注释 ...

    // (7) 设置trapframe
    tf->gpr.sp = stacktop;
    tf->epc = elf->e_entry;
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
    tf->gpr.a0 = argc;
    tf->gpr.a1 = (uintptr_t)uargv;
}
```

### 2.5 与Lab5的区别对比

| 方面 | Lab5 | Lab8 |
|------|------|------|
| 程序来源 | 内存中的二进制数据 | 文件系统中的ELF文件 |
| 读取方式 | memcpy | load_icode_read |
| 参数传递 | 无argc/argv | 需要设置argc/argv |
| 文件描述符 | 无 | 需要打开/关闭文件 |
| 复杂度 | 简单 | 需要处理文件系统接口 |

### 2.6 硬链接和软链接设计方案

#### 硬链接

硬链接让多个文件名指向同一个inode：

```c
int sfs_link(struct inode *dir, const char *name, struct inode *target) {
    // 1. 检查不能对目录创建硬链接
    if (sin->din->type == SFS_TYPE_DIR) {
        return -E_ISDIR;
    }

    // 2. 在目录中添加新的目录项
    sfs_dirent_create_inode(sfs, dirsin, name, sin->ino);

    // 3. 增加链接计数
    sin->din->nlinks++;
}
```

#### 软链接

软链接创建一个新的inode，内容是目标路径：

```c
// 扩展inode类型
#define SFS_TYPE_LINK   3

int sfs_symlink(struct inode *dir, const char *name, const char *target) {
    // 1. 分配新的inode
    // 2. 设置类型为SFS_TYPE_LINK
    // 3. 在数据块中存储目标路径
    // 4. 在目录中创建目录项
}
```

---

## 实验中遇到的问题与解决

### 问题1：make grade通过但shell运行ls报错

**现象**：`make grade`显示100分，但在shell中运行`ls`或`hello`时报`Instruction page fault`

**调试过程**：
1. 添加调试输出，发现page fault发生在pid=3的进程
2. 发现load_icode没有被调用（没有打印调试信息）
3. 追溯到fork失败，子进程的页面为空
4. 最终发现copy_range函数完全为空

**解决方案**：实现copy_range函数（见练习0第3部分）

**教训**：make grade通过不代表所有功能正常，需要实际测试shell命令

---

## 实验结果

### 测试命令

```bash
# 编译
make clean && make

# 运行自动测试
make grade

# 手动测试shell
make qemu
```

### 测试结果

```
make grade
-sh execve:                                OK
-user sh :                                 OK
Total Score: 100/100
```

### Shell功能测试

```
$ ls
.              1
..             1
hello          2
spin           2
...

$ hello
Hello world!!.

$ exit
```

---

## 知识点总结

### 与OS原理对应的知识点

| 实验知识点 | OS原理知识点 |
|-----------|-------------|
| SFS文件系统 | 索引节点、目录结构、空闲块管理 |
| VFS抽象层 | 虚拟文件系统设计 |
| 文件描述符 | 进程的文件管理 |
| 设备文件 | 设备驱动抽象 |
| load_icode | 程序加载与ELF格式 |
| 管道机制 | 进程间通信(IPC) |
| 链接机制 | 文件系统元数据管理 |

### 实验中重要但原理课未强调的知识点

1. **ELF文件格式的具体处理**
   - 程序头表的遍历
   - 段的权限设置
   - BSS段的处理

2. **RISC-V相关细节**
   - 页表权限位(PTE_R, PTE_W, PTE_X, PTE_U)
   - 栈指针16字节对齐要求
   - 系统调用参数传递约定(a0-a5)

3. **用户栈的argc/argv布局**
   - 字符串的存放位置
   - 指针数组的构建
   - 对齐要求
