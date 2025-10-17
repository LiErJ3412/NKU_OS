# SLUB 分配器设计文档

## 1. 概述

SLUB (Simple List of Unused Blocks) 是一种两层架构的高效内存分配器，本实现参考了 Linux SLUB 分配器的核心思想，针对 ucore 进行了简化。

### 1.1 设计目标

- **两层架构**: 第一层基于页分配，第二层实现任意大小对象分配
- **高性能**: 减少锁竞争，优化缓存命中率
- **低碎片**: 合理组织slab，减少内存浪费
- **简单易用**: 提供类似malloc/free的接口

### 1.2 与SLAB的区别

| 特性 | SLAB | SLUB |
|------|------|------|
| 队列管理 | 复杂（Full/Partial/Empty） | 简单（仅Partial） |
| 数据结构 | 多个队列，开销大 | 简化结构，开销小 |
| 性能 | 较好 | 更优 |
| 代码复杂度 | 高 | 低 |
| 调试难度 | 难 | 易 |

## 2. 核心概念

### 2.1 kmem_cache（对象缓存）

每种大小的对象都有一个专门的缓存：

```c
struct kmem_cache {
    const char *name;           // 缓存名称
    size_t size;                // 对象大小（包含元数据）
    size_t objsize;             // 实际对象大小
    size_t objects;             // 每个slab的对象数
    unsigned int order;         // 每个slab的页数（2^order）
    
    list_entry_t partial;       // 部分使用的slab链表
    void *freelist;             // CPU本地空闲链表
    struct Page *page;          // 当前活动slab
    ...
};
```

**关键特性**:
- 每个缓存管理固定大小的对象
- 维护一个partial slab链表
- CPU本地缓存避免锁竞争

### 2.2 Slab（内存片）

Slab是一组连续的物理页面，被划分成固定数目的对象：

```
+------------------+  ← Page 0 (slab起始)
| Obj 0            |
+------------------+
| Obj 1            |
+------------------+
| ...              |
+------------------+
| Obj N-1          |
+------------------+
```

**元数据存储**:
- 利用Page结构的property字段存储对象总数
- 使用slab_page结构存储freelist、inuse等信息

### 2.3 空闲对象链表

空闲对象本身存储下一个空闲对象的指针：

```
Obj0 -> Obj2 -> Obj5 -> NULL
(free)  (free)  (free)
```

**优点**:
- 无需额外空间存储空闲链表
- 分配/释放都是O(1)操作

## 3. 数据结构设计

### 3.1 kmem_cache 结构

```c
struct kmem_cache {
    // 基本信息
    const char *name;           // 缓存名称，如"kmalloc-128"
    size_t size;                // 对齐后的对象大小
    size_t objsize;             // 实际对象大小
    size_t align;               // 对齐要求（通常8字节）
    unsigned long flags;        // 标志位
    
    // Slab参数
    size_t objects;             // 每个slab的对象数
    unsigned int order;         // 页数order（2^order页）
    
    // 活动slab管理
    void *freelist;             // CPU本地空闲链表
    struct Page *page;          // 当前活动slab
    
    // Partial slab链表
    list_entry_t partial;       // partial链表头
    unsigned long nr_partial;   // partial slab数量
    
    // 统计信息
    unsigned long alloc_count;  // 总分配次数
    unsigned long free_count;   // 总释放次数
    
    // 全局链表
    list_entry_t list;          // 所有cache的链表节点
};
```

### 3.2 slab_page 结构

```c
struct slab_page {
    void *freelist;             // 空闲对象链表
    unsigned int inuse;         // 已使用对象数
    struct kmem_cache *cache;   // 所属缓存
};
```

这个结构复用Page结构的空间，无需额外内存。

### 3.3 通用缓存数组

```c
static struct kmem_cache *kmalloc_caches[13];
```

预创建常用大小的缓存：
- Index 0: 64字节
- Index 1: 128字节
- Index 2: 256字节
- Index 3: 512字节
- Index 4: 1024字节
- Index 5: 2048字节
- Index 6: 4096字节

## 4. 核心算法

### 4.1 对象分配 (kmem_cache_alloc)

```
1. 尝试从CPU本地freelist分配
   ├─ 有空闲对象 → 直接返回（快速路径）
   └─ 无空闲对象 → 继续

2. 尝试从partial链表获取slab
   ├─ partial非空 → 从第一个slab分配
   └─ partial为空 → 继续

3. 分配新slab
   ├─ 分配2^order个页面
   ├─ 初始化为空闲对象链表
   ├─ 分配第一个对象
   └─ 加入partial链表
```

**时间复杂度**: 
- 快速路径: O(1)
- 慢速路径: O(1) + 页分配时间

### 4.2 对象释放 (kmem_cache_free)

```
1. 找到对象所属的slab
   └─ 通过地址计算页面

2. 将对象加回freelist

3. 更新slab状态
   ├─ inuse--
   ├─ 完全空闲？
   │  ├─ Yes → 考虑释放slab
   │  └─ No → 保持在partial
   └─ 从满变partial？
      └─ Yes → 加入partial链表
```

**时间复杂度**: O(1)

### 4.3 kmalloc 实现

```c
void *kmalloc(size_t size) {
    // 1. 大对象：直接用页分配器
    if (size > MAX_OBJ_SIZE) {
        return alloc_pages(...);
    }
    
    // 2. 选择合适的缓存
    int index = size_to_index(size);
    
    // 3. 从缓存分配
    return kmem_cache_alloc(kmalloc_caches[index]);
}
```

### 4.4 kfree 实现

```c
void kfree(void *obj) {
    // 1. 找到对象所属页面
    struct Page *page = addr_to_page(obj);
    
    // 2. 检查是否是slab对象
    if (is_slab_page(page)) {
        // slab对象：找到cache并释放
        struct slab_page *sp = (struct slab_page *)page;
        kmem_cache_free(sp->cache, obj);
    } else {
        // 大对象：直接释放页面
        free_pages(page, ...);
    }
}
```

## 5. 内存布局

### 5.1 Slab布局

```
物理页面布局:
+------------------------------------------+
| Page 0                                   |
|  +-------------------------------------+ |
|  | Object 0 (size bytes)               | |
|  +-------------------------------------+ |
|  | Object 1 (size bytes)               | |
|  +-------------------------------------+ |
|  | ...                                 | |
|  +-------------------------------------+ |
|  | Object N-1 (size bytes)             | |
|  +-------------------------------------+ |
|  | 可能的未使用空间                      | |
+------------------------------------------+
| Page 1 (如果order > 0)                  |
+------------------------------------------+
```

### 5.2 对象内部结构（空闲时）

```
空闲对象:
+------------------+
| Next ptr (8字节) | ← 指向下一个空闲对象
+------------------+
| 未使用空间        |
| (size - 8 字节)  |
+------------------+

已分配对象:
+------------------+
| 用户数据          |
| (完整size字节)    |
+------------------+
```

## 6. 关键优化

### 6.1 CPU本地缓存

每个CPU维护一个活动slab和freelist：
- **优点**: 避免锁竞争，提高并发性能
- **实现**: 简化版只维护一个全局的freelist

### 6.2 延迟释放

完全空闲的slab不立即释放：
- 保留至少一个空slab
- 减少频繁分配/释放slab的开销

### 6.3 对象对齐

所有对象按SLUB_ALIGN（8字节）对齐：
- 提高缓存性能
- 避免false sharing

### 6.4 Slab复用

通过partial链表管理部分使用的slab：
- 优先复用已有slab
- 减少内存碎片

## 7. 使用示例

### 7.1 创建专用缓存

```c
// 创建task_struct缓存
struct kmem_cache *task_cache = 
    kmem_cache_create("task_struct", 
                      sizeof(struct task_struct),
                      8,    // 8字节对齐
                      0);   // 无特殊标志

// 分配对象
struct task_struct *task = kmem_cache_alloc(task_cache);

// 使用对象
task->pid = 1;
...

// 释放对象
kmem_cache_free(task_cache, task);

// 销毁缓存
kmem_cache_destroy(task_cache);
```

### 7.2 使用通用分配器

```c
// 分配128字节
char *buffer = kmalloc(128);

// 使用
strcpy(buffer, "Hello SLUB!");

// 释放
kfree(buffer);
```

## 8. 测试用例

### Test 1: 基本分配释放
- 分配不同大小的对象
- 验证地址不重叠
- 释放所有对象

### Test 2: 重复分配
- 连续分配10个相同大小对象
- 验证都能成功分配
- 全部释放

### Test 3: 不同大小混合
- 同时分配小、中、大对象
- 验证正确选择缓存
- 释放验证

### Test 4: 缓存统计
- 检查分配/释放计数
- 验证partial slab数量
- 打印统计信息

## 9. 性能分析

### 9.1 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| kmalloc | O(1) | 快速路径 |
| kfree | O(1) | 直接释放 |
| kmem_cache_alloc | O(1) | 无锁操作 |
| kmem_cache_free | O(1) | 无锁操作 |

### 9.2 空间复杂度

- **元数据开销**: 每个cache约100字节
- **Per-slab开销**: 复用Page结构，无额外开销
- **内部碎片**: 最多(对齐-1)字节/对象
- **外部碎片**: 最多(PGSIZE-1)字节/slab

### 9.3 与其他分配器对比

| 分配器 | 分配时间 | 释放时间 | 碎片 | 并发性 |
|--------|----------|----------|------|--------|
| First-Fit | O(N) | O(N) | 高 | 差 |
| Buddy | O(log N) | O(log N) | 中 | 中 |
| **SLUB** | **O(1)** | **O(1)** | **低** | **优** |

## 10. 改进方向

### 10.1 真正的Per-CPU缓存
当前简化实现只有一个全局freelist，可以改进为：
- 每个CPU独立的freelist
- 使用per-CPU变量避免锁

### 10.2 NUMA支持
- 为每个NUMA节点维护独立的partial链表
- 优先从本地节点分配

### 10.3 调试功能
- 红区检测（检测越界写入）
- 对象跟踪（记录分配/释放历史）
- 统计信息（命中率、碎片率等）

### 10.4 高级特性
- 对象构造/析构函数
- 延迟初始化
- 自动收缩/扩展

## 11. 与Buddy System集成

SLUB工作在Buddy System之上：

```
+------------------------+
|   User Application     |
+------------------------+
         ↓ kmalloc/kfree
+------------------------+
|   SLUB Allocator       |  ← 管理小对象
+------------------------+
         ↓ alloc_pages
+------------------------+
|   Buddy System         |  ← 管理页面
+------------------------+
         ↓
+------------------------+
|   Physical Memory      |
+------------------------+
```

**协作方式**:
1. SLUB通过alloc_pages从Buddy分配页面
2. 在页面上划分成小对象
3. 完全空闲的slab通过free_pages归还给Buddy

## 12. 总结

### 实现特点
✅ 两层架构：页级 + 对象级  
✅ O(1)分配/释放性能  
✅ 低内存碎片  
✅ 简洁的设计  
✅ 完善的测试

### 核心优势
1. **性能优秀**: 无锁快速路径
2. **内存高效**: 复用Page结构，低开销
3. **使用简单**: 类malloc/free接口
4. **可扩展性好**: 易于添加新特性

### 应用场景
- 内核小对象分配（进程、文件描述符等）
- 驱动程序缓冲区管理
- 网络协议栈内存管理
- 任何需要频繁分配固定大小对象的场景

## 参考资料

1. [Linux SLUB分配器详解](https://www.ibm.com/developerworks/cn/linux/l-cn-slub/)
2. Linux内核源码: mm/slub.c
3. [Understanding the Linux Kernel](https://www.oreilly.com/library/view/understanding-the-linux/0596005652/)
4. ucore实验指导书
