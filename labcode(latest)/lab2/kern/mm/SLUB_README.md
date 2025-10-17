# SLUB 分配器使用说明

## 概述

SLUB (Simple List of Unused Blocks) 是一种高效的内存分配器，专门用于管理小对象的分配。本实现参考了Linux内核的SLUB分配器，并针对ucore进行了简化。

## 特性

✅ **两层架构**：第一层使用Buddy System分配页面，第二层在页面上实现对象分配  
✅ **O(1)性能**：快速路径的分配和释放都是常数时间复杂度  
✅ **低内存开销**：复用Page结构存储元数据，无需额外空间  
✅ **类malloc接口**：提供熟悉的kmalloc/kfree接口  
✅ **多种大小支持**：预创建7个常用大小的缓存（64-4096字节）  
✅ **低碎片率**：内部碎片~15%，外部碎片接近0  

## 文件结构

```
kern/mm/
├── slub.c              # SLUB分配器实现
├── slub.h              # SLUB分配器头文件
├── slub_design.md      # 设计文档
└── SLUB_README.md      # 本文件

report/
└── slub_test_report.md # 测试报告
```

## 快速开始

### 1. 编译和运行

```bash
cd lab2
make clean
make
make qemu
```

### 2. 查看测试输出

启动后会看到以下输出：

```
Initializing SLUB allocator...
SLUB: Initializing SLUB allocator...
SLUB: Created cache 'kmalloc-64', objsize=64, size=64, order=0, objects=64
SLUB: Created cache 'kmalloc-128', objsize=128, size=128, order=0, objects=32
...
SLUB: Initialization complete

Checking SLUB allocator...
SLUB: Starting SLUB allocator tests...
Test 1: Basic allocation and free... Passed!
Test 2: Multiple allocations... Passed!
Test 3: Different sizes... Passed!
Test 4: Cache statistics... Passed!
SLUB: All tests passed!
```

## API 使用指南

### 通用分配接口

#### kmalloc - 分配内存

```c
void *kmalloc(size_t size);
```

**参数**:
- `size`: 需要分配的字节数（1-4096字节）

**返回值**:
- 成功：指向分配内存的指针
- 失败：NULL

**示例**:
```c
// 分配128字节
char *buffer = kmalloc(128);
if (buffer == NULL) {
    cprintf("Allocation failed!\n");
    return;
}

// 使用内存
memset(buffer, 0, 128);
strcpy(buffer, "Hello SLUB!");

// 释放内存
kfree(buffer);
```

#### kfree - 释放内存

```c
void kfree(void *obj);
```

**参数**:
- `obj`: 要释放的对象指针（由kmalloc返回）

**特性**:
- 可以安全地传入NULL
- 自动识别对象大小
- O(1)时间复杂度

**示例**:
```c
void *ptr = kmalloc(256);
// ... 使用内存 ...
kfree(ptr);
ptr = NULL;  // 推荐：防止悬空指针
```

### 专用缓存接口

#### kmem_cache_create - 创建对象缓存

```c
struct kmem_cache *kmem_cache_create(const char *name, size_t size,
                                     size_t align, unsigned long flags);
```

**参数**:
- `name`: 缓存名称（用于调试）
- `size`: 对象大小
- `align`: 对齐要求（0表示使用默认8字节对齐）
- `flags`: 标志位（通常为0）

**返回值**:
- 成功：指向kmem_cache的指针
- 失败：NULL

**示例**:
```c
struct task_struct {
    int pid;
    char name[32];
    // ... 其他字段
};

// 创建task_struct专用缓存
struct kmem_cache *task_cache = 
    kmem_cache_create("task_struct",
                      sizeof(struct task_struct),
                      0,  // 使用默认对齐
                      0); // 无特殊标志

if (task_cache == NULL) {
    panic("Failed to create task cache\n");
}
```

#### kmem_cache_alloc - 从缓存分配对象

```c
void *kmem_cache_alloc(struct kmem_cache *cache);
```

**参数**:
- `cache`: 缓存指针（由kmem_cache_create返回）

**返回值**:
- 成功：指向对象的指针
- 失败：NULL

**示例**:
```c
// 分配一个task_struct对象
struct task_struct *task = kmem_cache_alloc(task_cache);
if (task == NULL) {
    cprintf("Cannot allocate task\n");
    return;
}

// 初始化对象
task->pid = 1;
strcpy(task->name, "init");
```

#### kmem_cache_free - 释放对象到缓存

```c
void kmem_cache_free(struct kmem_cache *cache, void *obj);
```

**参数**:
- `cache`: 缓存指针
- `obj`: 要释放的对象指针

**示例**:
```c
// 释放task对象
kmem_cache_free(task_cache, task);
```

#### kmem_cache_destroy - 销毁缓存

```c
void kmem_cache_destroy(struct kmem_cache *cache);
```

**参数**:
- `cache`: 要销毁的缓存指针

**注意**: 销毁前应确保所有对象都已释放

**示例**:
```c
// 清理
kmem_cache_destroy(task_cache);
```

## 预创建缓存

SLUB在初始化时自动创建以下通用缓存：

| 缓存名称 | 对象大小 | 每slab对象数 | 页数(order) |
|---------|---------|------------|------------|
| kmalloc-64 | 64 bytes | 64 | 0 (1页) |
| kmalloc-128 | 128 bytes | 32 | 0 (1页) |
| kmalloc-256 | 256 bytes | 16 | 0 (1页) |
| kmalloc-512 | 512 bytes | 8 | 0 (1页) |
| kmalloc-1024 | 1024 bytes | 4 | 0 (1页) |
| kmalloc-2048 | 2048 bytes | 2 | 0 (1页) |
| kmalloc-4096 | 4096 bytes | 1 | 0 (1页) |

**自动选择规则**:
- kmalloc(50) → 使用kmalloc-64
- kmalloc(100) → 使用kmalloc-128
- kmalloc(200) → 使用kmalloc-256
- 以此类推...

## 使用场景

### 场景1：临时缓冲区

```c
void process_data(const char *input) {
    // 分配临时缓冲区
    char *buffer = kmalloc(512);
    if (!buffer) return;
    
    // 处理数据
    memcpy(buffer, input, strlen(input));
    process(buffer);
    
    // 释放
    kfree(buffer);
}
```

### 场景2：动态数据结构

```c
struct node {
    int data;
    struct node *next;
};

struct node *create_node(int value) {
    struct node *n = kmalloc(sizeof(struct node));
    if (n) {
        n->data = value;
        n->next = NULL;
    }
    return n;
}

void free_node(struct node *n) {
    kfree(n);
}
```

### 场景3：对象池（推荐用专用缓存）

```c
// 创建文件描述符缓存
struct kmem_cache *file_cache = 
    kmem_cache_create("file_desc", 
                      sizeof(struct file),
                      8, 0);

// 分配文件描述符
struct file *open_file(const char *path) {
    struct file *f = kmem_cache_alloc(file_cache);
    if (f) {
        // 初始化文件描述符
        f->path = path;
        f->pos = 0;
    }
    return f;
}

// 释放文件描述符
void close_file(struct file *f) {
    kmem_cache_free(file_cache, f);
}
```

## 性能特性

### 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| kmalloc | O(1) | 快速路径，直接从freelist分配 |
| kfree | O(1) | 直接加回freelist |
| kmem_cache_alloc | O(1) | 无锁操作 |
| kmem_cache_free | O(1) | 无锁操作 |

### 空间效率

**内部碎片**: 15-20%（平均）
- 请求50字节 → 分配64字节 → 浪费14字节(21.9%)
- 请求100字节 → 分配128字节 → 浪费28字节(21.9%)
- 请求500字节 → 分配512字节 → 浪费12字节(2.3%)

**外部碎片**: 接近0
- 同一slab内对象大小固定
- slab末尾浪费通常为0

**元数据开销**: 可忽略
- 每个缓存：~104字节
- 每个对象：0字节（复用对象自身存储链表）

## 注意事项

### ⚠️ 使用限制

1. **大小限制**: kmalloc最大支持4096字节
   - 超过4096字节需要直接使用页分配器

2. **对齐**: 所有对象按8字节对齐
   - 如需其他对齐，使用kmem_cache_create指定

3. **非线程安全**: 当前实现未加锁
   - 在单核ucore中可正常工作
   - 多核环境需添加锁保护

### ✅ 最佳实践

1. **及时释放**: 
   ```c
   void *ptr = kmalloc(size);
   // ... 使用 ...
   kfree(ptr);
   ptr = NULL;  // 防止悬空指针
   ```

2. **检查返回值**:
   ```c
   void *ptr = kmalloc(size);
   if (ptr == NULL) {
       // 处理分配失败
       return -ENOMEM;
   }
   ```

3. **使用专用缓存**（频繁分配同一大小）:
   ```c
   // 好的做法
   cache = kmem_cache_create("my_obj", size, 0, 0);
   obj = kmem_cache_alloc(cache);
   
   // 而不是
   obj = kmalloc(size);  // 每次都要查找缓存
   ```

4. **避免内存泄漏**:
   ```c
   void foo() {
       void *p = kmalloc(100);
       if (error_condition) {
           kfree(p);  // 记得在所有返回路径释放
           return;
       }
       // ... 
       kfree(p);
   }
   ```

## 调试

### 查看缓存统计

缓存统计信息在slub_check()中打印：

```
Cache Information:
  kmalloc-64: alloc=2, free=0, partial=1
  kmalloc-128: alloc=11, free=0, partial=1
  ...
```

**字段说明**:
- `alloc`: 总分配次数
- `free`: 总释放次数
- `partial`: 部分使用的slab数量

### 添加调试代码

```c
// 在slub.c中添加
#define SLUB_DEBUG 1

#ifdef SLUB_DEBUG
    cprintf("SLUB: Allocating %d bytes from %s\n", size, cache->name);
#endif
```

## 与其他分配器对比

| 分配器 | 分配速度 | 释放速度 | 碎片率 | 适用场景 |
|--------|---------|---------|--------|---------|
| First-Fit | 慢 O(N) | 慢 O(N) | 高 | 简单场景 |
| Best-Fit | 很慢 O(N) | 慢 O(N) | 中 | 内存紧张 |
| Buddy | 中 O(logN) | 中 O(logN) | 中 | 页级分配 |
| **SLUB** | **快 O(1)** | **快 O(1)** | **低** | **小对象分配** |

## 常见问题

### Q1: kmalloc和页分配器有什么区别？

**A**: 
- 页分配器（如Buddy System）以页（4KB）为单位
- kmalloc可以分配任意大小（1-4096字节）
- kmalloc在页的基础上提供更细粒度的分配

### Q2: 为什么kmalloc(50)会分配64字节？

**A**: 为了性能和简化管理，SLUB使用预定义的大小级别。50字节向上取整到最近的级别64字节。

### Q3: SLUB和malloc有什么区别？

**A**:
- SLUB是内核空间的分配器
- malloc是用户空间的分配器
- 接口相似但实现环境不同

### Q4: 可以分配超过4096字节吗？

**A**: 当前实现限制在4096字节。如需更大内存，应直接使用alloc_pages()。

### Q5: 如何选择kmalloc还是kmem_cache？

**A**:
- **kmalloc**: 一次性分配，大小不定
- **kmem_cache**: 频繁分配相同大小的对象

## 测试

### 运行测试

```bash
make qemu
```

测试包括：
1. ✅ 基本分配释放
2. ✅ 重复分配
3. ✅ 不同大小混合
4. ✅ 缓存统计

### 预期输出

```
SLUB: Starting SLUB allocator tests...
Test 1: Basic allocation and free... Passed!
Test 2: Multiple allocations... Passed!
Test 3: Different sizes... Passed!
Test 4: Cache statistics... Passed!
SLUB: All tests passed!
```

## 参考资料

1. **设计文档**: `kern/mm/slub_design.md`
   - 详细的设计思路和数据结构

2. **测试报告**: `report/slub_test_report.md`
   - 完整的测试用例和性能分析

3. **Linux SLUB**: Documentation/vm/slub.txt
   - Linux内核官方文档

4. **论文**: "The Slab Allocator: An Object-Caching Kernel Memory Allocator"
   - Jeff Bonwick, 1994

## 总结

SLUB分配器提供了：
- ✅ 高性能的小对象分配（O(1)）
- ✅ 简单易用的API（类malloc）
- ✅ 低内存开销和碎片率
- ✅ 良好的测试覆盖率

适用于内核中频繁的小对象分配场景，是ucore内存管理系统的重要组成部分。

---

**作者**: SLUB Implementation Team  
**版本**: 1.0  
**日期**: 2024年
