# GDB 调试页表翻译流程实验报告

## 1. 实验目标

本实验采用“双 GDB”调试方案观察 RISC-V Sv39 页表翻译的完整流程，目标包括：
- 观察 QEMU 在 TCG/MMU 路径中如何实现虚拟地址到物理地址的翻译
- 理解软件 TLB（Translation Lookaside Buffer）的查询、miss 与填充机制
- 对比 M 态直接映射与 S 态页表翻译（Sv39）的主要差异

## 2. 实验环境

### 2.1 环境配置

- QEMU: qemu-4.1.1（带调试信息版本）
- GDB:
  - x86_64 gdb（调试 QEMU 进程）
  - riscv64-unknown-elf-gdb（调试 ucore 内核）
- OS: ucore Lab2

### 2.2 修改 Makefile 使用带调试信息的 QEMU

```makefile
# 使用带调试信息的 QEMU 以支持双重 GDB 调试
QEMU := /root/Downloads/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64
```

## 3. QEMU 地址翻译核心源码分析

### 3.1 关键源码文件

| 文件 | 作用 |
|------|------|
| `target/riscv/cpu_helper.c` | 页表翻译核心函数 |
| `accel/tcg/cputlb.c` | TLB 管理与填充入口 |
| `include/exec/exec-all.h` / `include/exec/cpu-defs.h` | TLB 相关结构定义 |

### 3.2 `get_physical_address`：页表遍历核心逻辑（摘要）

```c
// target/riscv/cpu_helper.c
// ...existing code...
static int get_physical_address(CPURISCVState *env, hwaddr *physical,
                                int *prot, target_ulong addr,
                                int access_type, int mmu_idx)
{
    int mode = mmu_idx;

    // M 态或 Bare：不进行页表翻译
    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
        *physical = addr;
        *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
        return TRANSLATE_SUCCESS;
    }

    // 从 satp 取得根页表物理基址
    target_ulong base = get_field(env->satp, SATP_PPN) << PGSHIFT;

    // 根据 satp.MODE 决定页表级数（Sv39 为 3 级）
    // ...existing code...

    // 多级页表遍历（Sv39：3 次查表）
    // ...existing code...
}
```

### 3.3 `riscv_cpu_tlb_fill`：TLB miss 时的填充路径（摘要）

```c
// target/riscv/cpu_helper.c
// ...existing code...
bool riscv_cpu_tlb_fill(CPUState *cs, vaddr address, int size,
                        MMUAccessType access_type, int mmu_idx,
                        bool probe, uintptr_t retaddr)
{
    // ...existing code...
    ret = get_physical_address(env, &pa, &prot, address, access_type, mmu_idx);

    if (ret == TRANSLATE_SUCCESS) {
        tlb_set_page(cs, address & TARGET_PAGE_MASK, pa & TARGET_PAGE_MASK,
                     prot, mmu_idx, TARGET_PAGE_SIZE);
        return true;
    } else {
        // ...existing code...
    }
}
```

## 4. 调试过程与结果分析

### 4.1 调试方法

实验采用三终端方式完成“双 GDB”协同调试：

1. 启动 QEMU（带调试选项）
```bash
make debug
```

2. 使用 Host 侧 x86_64 GDB 附加到 QEMU 进程，并在翻译关键函数处设置断点
```bash
gdb -q
(gdb) attach <QEMU_PID>
(gdb) handle SIGPIPE nostop noprint
(gdb) break get_physical_address
(gdb) continue
```

3. 使用 Guest 侧 riscv64 GDB 连接 ucore，让系统继续运行以产生取指/访存事件
```bash
make gdb
(gdb) continue
```

> 说明：Guest 侧 gdb 主要用于驱动 ucore 运行；Host 侧 gdb 用于观察 QEMU 在 TCG/MMU/TLB 路径中的实际执行。需要注意，QEMU gdbstub 在“调试器读内存”等操作下也可能触发翻译，因此应结合调用栈判断样本是否来自 CPU 真实取指/访存路径。

> 补充：`satp.MODE` 位于 `[63:60]`，可用如下形式提取：
> - `satp_mode = (env->satp >> 60) & 0xf`

### 4.2 M 态 / Bare：直接映射分支现象

当 `mmu_idx = 3`（M 态）或 `satp.MODE = 0`（Bare）时，QEMU 在 `get_physical_address()` 内走“直通”分支：虚拟地址直接作为物理地址返回。

示例观测（摘要）：
- `mmu_idx = 3`（M 态）
- 返回 `physical = addr`
- `prot = RWX`

对应关键路径：
```c
if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
    *physical = addr;
    *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
    return TRANSLATE_SUCCESS;
}
```

### 4.3 S 态 Sv39：TLB miss 触发页表 walk（慢路径）

在 S 态（`mmu_idx = 1`）下，TLB miss 时会进入 `tlb_fill → riscv_cpu_tlb_fill → get_physical_address` 的慢路径，完成 Sv39 三级页表遍历后再通过 `tlb_set_page` 将结果写入软件 TLB。


***调试过程**：我们现在想追踪全过程：![2](pic\2.png)

我们先对四个函数都打上断点，可以发现get_physical_addrerss()函数的断点先被触发，但是其他的几个断点反而没有，在答辩时候的backtrace可以看到其实前面几个如果在涉及到真的tlb取址的时候是会触发的（如下图所示）。

![7](pic\7.png)

所以仅仅靠get_physical_address()来看页表翻译流程是不对的。

因此我们要找一个合适的地址，看看什么时候能触发前面几个函数，因此我们继续continue：

![3](pic\3.png)

但这个时候mmu_idx=3，不是我们想要的三级页表那种翻译过程。

![4](pic\4.png)

我们用条件断点让mmu_idx=1来找我们想要的s态的

![5](pic\5.png)

看起来`addr=0xffffffffc02000d8`是个可以考虑的地址，我们多步next跳过，可以看到它确实涉及了三级页表翻译：

![6](pic\6.png)

那么重新来一次，给`get_page_addr_code()`、`tlb_fill()`、`riscv_cpu_tlb_fill()`、`tlb_set_page()`(这个似乎需要vaddr去打，最后就没打了)打上断点.

![9](pic\9.png)

用n指令来步进

![10](pic\10.png)

可以看到，qemu进行地址翻译的时候，也是会走个tlb查询的，如果没有hit的话就去fill写入，所以跟实际的cpu也是比较像的。

继续下去，就是到riscv_cpu_tlb_fill走riscv的模拟过程

![11](pic\11.png)

后面都是一些回填的过程：![12](pic\12.png)

那当我们后面再次触发get_page_addr_code的时候，我们就不会再进入fill过程了，

说明我们这次就hit中了（因为前面填入了tlb），也是符合直觉的。

![13](pic\13.png)



接下来我们具体看一下三级页表翻译的细节：

我们这次只对get_physical_address打断点就行

![14](pic\14.png)

接着就会顺利触发：![15](pic\15.png)

具体而言，代码首先判断当前的特权级模式（Privilege Mode）及 MMU 使能状态；随后读取 mstatus 寄存器以获取 MXR（可执行即可读）和 SUM（允许访问用户态）等权限标志；最后读取 satp 寄存器获取页表基地址和分页模式（如 Sv39），据此设定页表级数、页表项大小等关键参数，为后续的多级页表查询做好准备。

接着就是三级页表的具体流程了：
![16](pic\16.png)

![17](pic\17.png)

![18](pic\18.png)

再补下pte、ppn、vpn的值：![19](pic\19.png)

![20](pic\20.png)

三级页表这边的代码概括地说干了这些事情：

I.**页表遍历（Page Table Walk）**：通过循环结构逐级访问页表。利用虚拟地址中的索引位计算页表项（PTE）的物理地址，并从内存中读取 PTE。
II. **有效性与权限检查**：检查 PTE 的有效位（Valid Bit）及物理内存保护（PMP），若遇到叶子节点（Leaf PTE），则提取物理页号（PPN）。
III.**物理地址合成**：将从 PTE 中提取的物理页号与虚拟地址中的页内偏移量组合，计算出最终的物理地址。
IV.**权限回填**：根据 PTE 中的 R/W/X 位，设置最终的内存访问权限（Read, Write, Execute），并更新 PTE 的访问（Accessed）与脏（Dirty）位。

至此，我们的调试过程结束，总结如下：

一次取指翻译样本（用于全链路展示）：

- `addr = 0xffffffffc02000d8`
- `access_type = INST_FETCH`
- `mmu_idx = 1`

典型调用栈（摘要）：
```
#0  get_physical_address(...)
#1  riscv_cpu_tlb_fill(...)
#2  tlb_fill(...)
```

### 4.4 真实调试记录整理：TLB 流程与页表 walk 证据

本节对 Host 侧 GDB 实测信息进行归纳，用于支撑“miss 填表 / hit 快路径 / walk 细节”的结论。

#### 4.4.1 记录 A：一次取指触发的翻译与填表链路

记录显示，TCG 取指在软件 TLB 查询未命中后进入 `tlb_fill()`，随后由 `riscv_cpu_tlb_fill()` 调用 `get_physical_address()` 完成翻译，并在成功后通过 `tlb_set_page()` 写入 TLB 表项。

函数职责（按调用关系）：
- `get_page_addr_code()`：取指快路径入口，优先查询软件 TLB；命中则直接通过 `addr + entry->addend` 计算结果。
- `tlb_fill()`：TLB miss 的统一慢路径入口。
- `riscv_cpu_tlb_fill()`：RISC-V 架构相关的 TLB fill 实现，负责触发翻译与填表。
- `get_physical_address()`：Sv39 页表遍历核心。
- `tlb_set_page()`：以页为粒度缓存翻译结果（VA_page→PA_page + prot）。

> 由“断点命中 `get_physical_address()` 且其上层调用栈包含 `tlb_fill()`”可判定该样本处于 TLB miss 慢路径。

#### 4.4.2 记录 B：单步 Sv39 三重循环并验证 `*physical`

对同一地址样本 `addr=0xffffffffc02000d8`，在 `get_physical_address()` 内单步观察到：
- `vm = SATP_MODE` 进入 `Sv39` 分支
- `levels = 3; ptidxbits = 9; ptesize = 8`
- 循环中逐级计算 `idx`，由 `pte_addr = base + idx * ptesize` 定位页表项并读取 `pte`
- 在读取页表项前出现 PMP 相关检查调用，说明 QEMU 在访问页表项对应物理地址前会进行权限校验

在叶子 PTE 命中后，观测到：
- `pte = 0x200000cf`
- `ppn = 0x80000`
- `*physical` 最终计算为 `0x80200000`（物理页基址）

现象解释（针对单步时“先看到 0、后看到正确值”的情况）：
- GDB 的单步停止点位于“即将执行的源码行”，在赋值语句执行前读取变量可能仍为旧值；继续单步后变量更新生效，因此后续读取显示为最终计算结果。该现象属于调试时点差异，并不表示翻译失败。

### 4.5 TLB miss：从 `tlb_fill` 到 `tlb_set_page` 的断点链路

为复现实验中的 miss→fill→set_page 过程，可使用以下断点集合串联路径：

```gdb
b tlb_fill
b riscv_cpu_tlb_fill
b get_physical_address
b tlb_set_page
```

在 `tlb_set_page()` 处建议记录的关键信息（以 `info args` 为准）：
- 虚拟页（典型为 `address & TARGET_PAGE_MASK`）
- 物理页（典型为 `pa & TARGET_PAGE_MASK`）
- `mmu_idx`
- `prot`（R/W/X）

据此可直接给出“本次 miss 的结果是向软件 TLB 插入了 (VA_page → PA_page, prot)”的实验记录。

### 4.6 TLB hit：软件 TLB 快路径特征

当同一页内地址再次被取指/访存时，软件 TLB 通常命中，表现为：
- 不再进入 `get_physical_address()`（不发生页表 walk）
- 在快路径中通过 `addr + tlb_entry->addend` 快速得到换算结果

可选快路径断点（命中任一即可形成记录）：
```gdb
b get_page_addr_code
b load_helper
b store_helper
```




## 5. Sv39 三级页表翻译机制说明（结合样本）

### 5.1 Sv39 页表结构与 PTE 格式（概述）

- `satp.MODE=8` 表示 Sv39
- 根页表物理基址：`SATP.PPN << 12`
- 虚拟地址拆分为 `VPN[2:0] + page offset`

PTE（64 位）关键位：
- `V/R/W/X/U/G/A/D` 等位决定有效性、权限与访问状态

### 5.2 样本地址的翻译分解

以样本虚拟地址 `0xffffffffc02000d8` 为例：
- `VPN[2] = (VA >> 30) & 0x1FF`
- `VPN[1] = (VA >> 21) & 0x1FF`
- `VPN[0] = (VA >> 12) & 0x1FF`
- `Offset = VA & 0xFFF`

在实验记录中，页表 walk 的关键证据通过 Host GDB 在 `get_physical_address()` 内打印 `base/idx/pte_addr/pte/ppn/*physical` 获得；因此报告不对 `satp.PPN` 等数值作假设，而以实测值描述翻译过程。

## 6. 开启/未开启虚拟地址翻译的差异（实验现象归纳）

### 6.1 M 态（mmu_idx=3）：直接映射

特征：
- 不进行多级页表遍历
- `physical == addr`
- 性能开销最小（仅受 PMP 等影响）

### 6.2 S 态（mmu_idx=1）：Sv39 页表翻译

特征：
- TLB miss 时进行 3 级页表遍历
- 翻译结果以页为粒度写入软件 TLB
- 通过 PTE 权限位实现 R/W/X/U 等访问控制

## 7. QEMU 软件 TLB 实现要点（与本实验相关部分）

### 7.1 TLB 表项结构（摘要）

```c
// include/exec/cpu-defs.h
// ...existing code...
typedef struct CPUTLBEntry {
    target_ulong addr_read;
    target_ulong addr_write;
    target_ulong addr_code;
    uintptr_t addend;          // 通过 addr + addend 形成换算结果
} CPUTLBEntry;
```

### 7.2 命中/未命中行为（概述）

- hit：匹配页号后直接 `addr + addend`
- miss：进入 `tlb_fill()`，完成翻译并调用 `tlb_set_page()` 填表

## 8. 本次实验使用的最小命令集

```bash
# 终端 1：启动 QEMU
make debug

# 终端 2：Host gdb attach QEMU
gdb -q
# (gdb) attach <QEMU_PID>

# 终端 3：Guest gdb 连接并运行
make gdb
```

## 9. 总结

实验通过 Host/Guest 双 GDB 结合断点链路与单步观测，验证了以下结论：
1. QEMU 在 M 态/Bare 下采用直接映射，`get_physical_address()` 早返回，`physical == addr`。
2. 在 S 态 Sv39 下，TLB miss 触发 `tlb_fill → riscv_cpu_tlb_fill → get_physical_address` 的慢路径，并在成功后由 `tlb_set_page()` 将映射写入软件 TLB。
3. 同页再次访问通常 TLB 命中，进入快路径，通过 `addr + tlb_entry->addend` 完成快速换算且不再进行页表遍历。
4. 页表 walk 中读取页表项前会出现权限检查相关调用（如 PMP 检查），与 QEMU 对页表项读访问的安全性策略一致。
最终，该样本汇总为一条可核验结论：

- `get_physical_address` 返回 `TRANSLATE_SUCCESS`
- `p/x *physical` 最终为 `0x80200000`

> 说明：Sv39 的 VA 会被拆成 VPN[2:0] 与 12-bit 页内偏移；本报告重点是“按实际 GDB 单步输出记录翻译行为”，因此不再单独展开通用的脚本/模板。

### 4.5 TLB miss：从 `tlb_fill` 到 `tlb_set_page`

当 TLB 未命中时，调用链如下：

```
┌─────────────────────────────────────────────────────────────────┐
│                     TLB 查找和填充流程                           │
└─────────────────────────────────────────────────────────────────┘

CPU 执行访存指令
       │
       ▼
┌─────────────────┐
│ 软件 TLB 查找    │  (TCG 生成的代码)
└────────┬────────┘
         │ TLB Miss
         ▼
┌─────────────────┐
│   tlb_fill()    │  accel/tcg/cputlb.c:868
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ riscv_cpu_tlb_fill()│  target/riscv/cpu_helper.c:435
└────────┬────────────┘
         │
         ▼
┌─────────────────────────┐
│ get_physical_address()  │  页表遍历
│  - 读取 satp 寄存器      │
│  - 三级页表查找          │
│  - 检查权限位            │
└────────┬────────────────┘
         │ 成功
         ▼
┌─────────────────┐
│ tlb_set_page()  │  填充 TLB 表项
└─────────────────┘
```

对应到 Host GDB 断点，可以直接用这组“链路断点”把 miss 路径串起来：

```gdb
b tlb_fill
b riscv_cpu_tlb_fill
b get_physical_address
b tlb_set_page
```

当断在 `tlb_set_page()` 时，建议把“将要写入 TLB 的映射”打印出来（不同版本参数名略有差异，以 `info args` 为准）：

- guest 虚拟页号（通常是 `address & TARGET_PAGE_MASK`）
- guest 物理页号（通常是 `pa & TARGET_PAGE_MASK`）
- `mmu_idx`
- `prot`（R/W/X）

这样报告里就能写清楚：“一次 miss 的结果是往 QEMU 软件 TLB 里插入了 (VA_page → PA_page, prot)”。

### 4.6 TLB hit：`get_page_addr_code/load_helper/store_helper` 的快路径

你之前已经在 QEMU 源码里定位过：TLB 命中时会走 `accel/tcg/cputlb.c` 的查找逻辑，典型现象是 **不会再进入 `get_physical_address()`**。

为了在报告里把 hit 也做成“可复现的调试记录”，建议：

1) 先用一次 miss 填充表项（上面 4.5 已经能做到）
2) 紧接着让 guest 再访问同一页
3) 在 Host 侧对快路径函数下断点，看它直接算出 host/guest 物理地址

可用断点（至少选一个命中即可）：

```gdb
b get_page_addr_code
b load_helper
b store_helper
```

在这些函数命中时，报告里建议记录这三件事：

- 输入的 guest 虚拟地址 `addr`
- 选中的 `tlb_index`（通常是哈希/掩码）
- `tlb_entry->addend`（QEMU 用它做 `addr + addend` 快速得到物理地址）

这部分写成“命中样本”后，你的报告就同时覆盖：

- miss：走页表 + 填 TLB
- hit：直接用 `addend` 做地址变换

## 5. Sv39 三级页表翻译详解

### 5.1 页表结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Sv39 三级页表结构                             │
└─────────────────────────────────────────────────────────────────┘

satp 寄存器
┌──────┬─────────┬────────────────────────────────────┐
│ MODE │  ASID   │              PPN                   │
│ (4)  │  (16)   │             (44)                   │
└──────┴─────────┴────────────────────────────────────┘
  │
  │ MODE=8 表示 Sv39
  │
  └────► 页表物理基地址 = PPN << 12

第一级页表 (根页表)
┌────────────────────────────────────────────────────────┐
│ PTE[0] │ PTE[1] │ ... │ PTE[255] │ PTE[256] │ ... │ PTE[511] │
└────────────────────────────────────────────────────────┘
  │                         │
  │                         └── 内核空间 (VPN[2] = 256-511)
  └── 用户空间 (VPN[2] = 0-255)

页表项 (PTE) 格式 (64位):
┌─────────────────────────────────────────────┬───────────────┐
│              PPN (44 bits)                  │  RSW │D│A│G│U│X│W│R│V│
│                                             │(2bit)│ │ │ │ │ │ │ │ │
└─────────────────────────────────────────────┴───────────────┘
 63                                       10  9    8 7 6 5 4 3 2 1 0

V = Valid (有效位)
R = Readable (可读)
W = Writable (可写)
X = Executable (可执行)
U = User (用户态可访问)
G = Global (全局映射)
A = Accessed (已访问)
D = Dirty (已修改)
```

### 5.2 地址翻译过程

以翻译虚拟地址 `0xffffffffc02000d8` 为例（本次实际断到的取指地址）:

```
步骤 1: 解析虚拟地址
  VA = 0xffffffffc02000d8
  VPN[2] = (VA >> 30) & 0x1FF = 0x100 (256)
  VPN[1] = (VA >> 21) & 0x1FF = 0x001
  VPN[0] = (VA >> 12) & 0x1FF = 0x000
  Offset = VA & 0xFFF = 0x0d8

步骤 2: 第一级页表查找（真实调试以 Host GDB 输出为准）
  这里不再写死 “satp.PPN = 0x80205(假设)” 这类虚构值。
  正确的做法是在 Host GDB 里打印：
    - env->satp
    - base = SATP_PPN<<12
    - idx / pte_addr / pte / ppn
  并把这些真实数值写进报告截图/记录中。

步骤 3: 第二级页表查找
  若当前级读到的 PTE 是“非叶子”（没有设置 R/W/X），则：
    base = ppn << 12
  继续下一轮循环（ptshift 由 18 变成 9）。

步骤 4: 第三级页表查找（或在更高层提前命中大页叶子）
  若读到的 PTE 已经设置了 R/W/X 中任意一个，则它是“叶子 PTE”，页表 walk 到此结束。

步骤 5: 生成物理地址并复核（引用本次 Host GDB 单步证据）

  在 `cpu_helper.c` 中（qemu-4.1.1），页表 walk 在识别到“叶子 PTE”后，会将 PTE 的 `ppn` 与 VA 的 `vpn` 低位拼接生成物理页号，并左移 `PGSHIFT(=12)` 得到物理地址高位；最后再与页内偏移拼接，得到最终物理地址。

  本次样本的关键观测点包括：

  - `p/x pte = 0x200000cf`
  - `p/x ppn = 0x80000`
  - `p/x vpn = 0xffffffffc0200`
  - `p/x *physical` 最终为 `0x80200000`

  本次我在 `get_physical_address` 内直接打印到 `*physical = 0x80200000`，这对应的是该映射的物理页基址；对本条样本地址 `0xffffffffc02000d8`，其最终物理地址可理解为在该页基址上再加页内偏移。

  该结论来自 `get_physical_address` 函数内对 `*physical` 的直接打印，属于本实验中最可信的“翻译结果证据”。
```

## 6. 开启/未开启虚拟地址的访存差异

### 6.1 M 态 (mmu_idx = 3) - 直接映射

```c
// 代码路径: get_physical_address()
if (mode == PRV_M) {
    *physical = addr;  // 虚拟地址 = 物理地址
    *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
    return TRANSLATE_SUCCESS;
}
```

**特点**:
- 无需页表遍历
- 访问任意物理地址
- 无权限检查 (除 PMP)
- 性能最高

### 6.2 S 态 (mmu_idx = 1) - Sv39 页表翻译

**特点**:
- 需要三级页表遍历
- 每次 TLB miss 需要 3 次内存访问
- 支持权限控制 (R/W/X)
- 支持用户/内核隔离

### 6.3 性能对比

```
┌────────────────────────────────────────────────────────────────┐
│                    访存性能对比                                 │
└────────────────────────────────────────────────────────────────┘

M 态访存:
  CPU ──► 物理内存
  延迟: 1 次内存访问

S 态访存 (TLB Hit):
  CPU ──► TLB ──► 物理内存
  延迟: 1 次内存访问 + TLB 查找

S 态访存 (TLB Miss):
  CPU ──► TLB Miss ──► 页表遍历 (3次内存访问) ──► TLB 填充 ──► 物理内存
  延迟: 4 次内存访问

注: QEMU 使用软件 TLB，实际硬件有硬件 TLB，性能更高
```

## 7. QEMU 软件 TLB 实现

### 7.1 TLB 结构

```c
// include/exec/cpu-defs.h
typedef struct CPUTLBEntry {
    target_ulong addr_read;    // 读地址 (虚拟地址)
    target_ulong addr_write;   // 写地址
    target_ulong addr_code;    // 代码执行地址
    uintptr_t addend;          // 物理地址偏移
} CPUTLBEntry;
```

### 7.2 TLB 查找 (TCG 生成的代码)

```c
// 简化的 TLB 查找逻辑
tlb_entry = &env->tlb_table[mmu_idx][TLB_INDEX(addr)];
if (likely(tlb_entry->addr_read == (addr & TARGET_PAGE_MASK))) {
    // TLB Hit
    physical_addr = addr + tlb_entry->addend;
} else {
    // TLB Miss, 调用 tlb_fill()
    tlb_fill(cpu, addr, size, access_type, mmu_idx, retaddr);
}
```

## 8. 调试命令（本次实际用到的最小集合）

```bash
# 终端 1: 启动 QEMU
make debug

# 终端 2: Host gdb 附加 QEMU
gdb -q
# (gdb) attach <QEMU_PID>

# 终端 3: Guest gdb 连接并让系统继续运行
make gdb
```

## 9. 总结

通过本次 GDB 调试实验，深入理解了:

1. **QEMU 如何实现 Sv39 页表翻译**:
   - `get_physical_address()` 函数实现三级页表遍历
   - M 态直接映射，无需页表
   - S/U 态需要完整的页表遍历

2. **TLB 的工作原理**:
   - 软件 TLB 缓存翻译结果
   - TLB Miss 时调用 `riscv_cpu_tlb_fill()`
   - 翻译成功后通过 `tlb_set_page()` 填充 TLB

3. **虚拟地址与物理地址的映射**:
   - 内核空间: `VA = PA + 0xffffffff40000000`
   - 用户空间: 由页表决定映射关系

4. **权限控制**:
   - PTE 中的 R/W/X/U 位控制访问权限
   - 违反权限触发 Page Fault

这些知识对于理解操作系统的内存管理机制至关重要。
