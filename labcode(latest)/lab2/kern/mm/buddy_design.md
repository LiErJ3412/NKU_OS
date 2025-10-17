# Buddy System (伙伴系统) 设计文档

## 1. 概述

本文档描述了在 ucore 操作系统中实现的 Buddy System（伙伴系统）内存分配算法。

### 1.1 什么是 Buddy System?

Buddy System 是一种经典的内存分配算法，广泛应用于 Linux 等操作系统的底层内存管理。其核心思想是：
- 将内存按 2 的幂次方进行划分
- 分配时从大块中分裂出小块
- 释放时将相邻的小块合并成大块

### 1.2 算法优势

1. **快速分配和释放**: 时间复杂度 O(log N)
2. **低外部碎片**: 采用最佳适配策略
3. **高效合并**: 自动合并相邻空闲块

### 1.3 算法劣势

1. **内部碎片**: 按 2 的幂分配，如需要 5 页会分配 8 页
2. **内存开销**: 需要额外的数据结构维护空闲信息

## 2. 数据结构设计

### 2.1 核心数据结构

```c
struct buddy2 {
    unsigned int size;          // 管理的总页面数（必须是2的幂）
    unsigned int *longest;      // 二叉树节点数组
};
```

### 2.2 完全二叉树

使用数组表示的完全二叉树来管理内存：

```
示例：管理 16 个单元的内存

                  [0](16)
                /          \
           [1](8)          [2](8)
          /      \        /      \
      [3](4)   [4](4)  [5](4)  [6](4)
      /  \     /  \    /  \    /  \
    [7][8] [9][10][11][12][13][14]
    (2)(2) (2)(2) (2)(2) (2) (2)
    ...（最底层每个节点代表1个单元）
```

- 节点数组下标表示节点位置
- 节点值 `longest[i]` 表示该节点对应的最大连续空闲块大小
- 根节点 `longest[0]` 表示整个内存的最大空闲块

### 2.3 关键宏定义

```c
#define IS_POWER_OF_2(x) (!((x)&((x)-1)))      // 判断是否为2的幂
#define LEFT_LEAF(index) ((index) * 2 + 1)     // 左子节点
#define RIGHT_LEAF(index) ((index) * 2 + 2)    // 右子节点
#define PARENT(index) (((index) + 1) / 2 - 1)  // 父节点
```

## 3. 算法实现

### 3.1 初始化 (buddy_init_memmap)

**步骤**：
1. 将管理的页面数调整为 2 的幂（向上取整）
2. 计算完全二叉树的节点数：`2 * size - 1`
3. 初始化二叉树，每个节点的 `longest` 值设为其管理的内存大小
4. 初始化所有页面，清除标志位

**时间复杂度**: O(N)

**示例**：
```
管理 32 页，二叉树有 63 个节点
第1层（下标0）:   longest = 32
第2层（下标1-2）: longest = 16
第3层（下标3-6）: longest = 8
...
```

### 3.2 分配页面 (buddy_alloc_pages)

**算法流程**：

```
输入: n 个页面
输出: 分配的起始页面指针

1. 将 n 向上取整到最近的 2 的幂，得到 size
2. 从根节点开始向下搜索：
   a. 如果当前节点的 longest < size，分配失败
   b. 如果当前节点大小 == size，找到目标
   c. 否则，优先选择左子树（如果够大），否则选右子树
3. 将目标节点的 longest 设为 0（标记为已分配）
4. 计算页面偏移量：offset = (index + 1) * node_size - total_size
5. 向上回溯，更新父节点的 longest 为左右子树的最大值
6. 返回 base + offset
```

**时间复杂度**: O(log N)

**示例**：
```
分配 5 页（实际分配 8 页）：

初始状态:
        [0](32)
       /       \
    [1](16)   [2](16)

搜索到下标[1]，分配8页后:
        [0](16)  <- 更新为右子树的值
       /       \
    [1](0)    [2](16)  <- 左子树已分配
   /    \
[3](8) [4](0)  <- [4]被分配
```

### 3.3 释放页面 (buddy_free_pages)

**算法流程**：

```
输入: base 页面指针, n 个页面

1. 将 n 向上取整到 2 的幂
2. 根据 base 计算偏移量 offset = base - buddy_page_base
3. 根据 offset 计算节点索引
4. 向上查找 longest 为 0 的节点（即当初分配的节点）
5. 恢复该节点的 longest 值
6. 向上回溯，尝试合并：
   a. 如果左右子树的 longest 之和 == 父节点满状态大小，则合并
   b. 否则，父节点 longest = max(左子树, 右子树)
```

**时间复杂度**: O(log N)

**合并示例**：
```
释放 [4] 的 8 页后:

        [0](32)  <- 左右子树合并，恢复满状态
       /       \
    [1](16)   [2](16)  <- 左子树 [3][4] 合并
   /    \
[3](8) [4](8)  <- [4]已释放，与[3]合并
```

### 3.4 查询空闲页面数 (buddy_nr_free_pages)

直接返回根节点的 `longest[0]`，表示当前最大可分配的连续页面数。

**时间复杂度**: O(1)

## 4. 测试用例

### 4.1 基本功能测试

**Test 1: 单页分配**
- 分配 3 个单独的页面
- 验证页面地址不同且引用计数为 0

**Test 2: 单页释放**
- 释放上述 3 个页面
- 验证内存正确回收

### 4.2 多页分配测试

**Test 3: 多页分配**
- 分配 5 页（实际分配 8 页）
- 分配 3 页（实际分配 4 页）
- 验证地址不重叠

### 4.3 合并测试

**Test 4: 页面合并**
- 释放之前分配的多页块
- 验证相邻块正确合并

### 4.4 大块分配测试

**Test 5: 大块内存**
- 分配一半的可用内存
- 释放后验证空闲页数恢复

### 4.5 边界测试

**Test 6: 不同大小**
- 分配 1, 2, 4, 8 页
- 验证 2 的幂次分配正确
- 全部释放验证恢复

### 4.6 内存耗尽测试

**Test 7: 耗尽测试**
- 分配所有可用内存
- 验证无法继续分配
- 释放后验证可再次分配

## 5. 与 First-Fit 和 Best-Fit 的比较

| 特性 | First-Fit | Best-Fit | Buddy System |
|------|-----------|----------|--------------|
| 时间复杂度 | O(N) | O(N) | O(log N) |
| 外部碎片 | 较多 | 较少 | 很少 |
| 内部碎片 | 无 | 无 | 有（最多50%）|
| 合并效率 | 一般 | 一般 | 高 |
| 实现复杂度 | 低 | 低 | 中等 |

## 6. 优化与改进

### 6.1 已实现的优化

1. **使用数值而非状态机**: 用 `longest` 值同时表示状态和大小
2. **数组实现二叉树**: 避免指针开销，提高缓存命中率
3. **优先左子树**: 保持内存分配的局部性

### 6.2 可能的改进方向

1. **压缩 longest 数组**: 
   - 当前使用 4 字节 `unsigned int`
   - 可改用 `log2(size)` 存储，使用 1 字节 `uint8_t`
   - 内存开销降低 75%

2. **延迟合并**:
   - 释放时不立即合并
   - 积累一定数量后批量合并
   - 减少频繁的合并操作

3. **多级 Buddy System**:
   - 对不同大小范围使用不同的 Buddy System
   - 减少内部碎片

4. **混合策略**:
   - 小内存使用 Slab 分配器
   - 大内存使用 Buddy System
   - 综合两者优势

## 7. 使用方法

### 7.1 在 pmm.c 中启用

修改 `kern/mm/pmm.c`:

```c
#include <buddy_pmm.h>

// 将默认管理器改为 buddy
const struct pmm_manager *pmm_manager = &buddy_pmm_manager;
```

### 7.2 编译和测试

```bash
make clean
make
make qemu
```

在 QEMU 中运行，观察 Buddy System 的检查输出。

## 8. 关键代码片段

### 8.1 向上取2的幂

```c
static unsigned int fixsize(unsigned int size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}
```

### 8.2 分配核心逻辑

```c
// 向下搜索
for (node_size = buddy_size; node_size != size; node_size /= 2) {
    if (buddy_longest[LEFT_LEAF(index)] >= size)
        index = LEFT_LEAF(index);
    else
        index = RIGHT_LEAF(index);
}

// 标记为已分配
buddy_longest[index] = 0;

// 向上更新
while (index) {
    index = PARENT(index);
    buddy_longest[index] = 
        MAX(buddy_longest[LEFT_LEAF(index)], 
            buddy_longest[RIGHT_LEAF(index)]);
}
```

### 8.3 释放与合并

```c
// 恢复节点
buddy_longest[index] = node_size;

// 向上合并
while (index) {
    index = PARENT(index);
    node_size *= 2;
    
    unsigned int left = buddy_longest[LEFT_LEAF(index)];
    unsigned int right = buddy_longest[RIGHT_LEAF(index)];
    
    if (left + right == node_size)  // 可以合并
        buddy_longest[index] = node_size;
    else
        buddy_longest[index] = MAX(left, right);
}
```

## 9. 参考资料

1. [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)
2. [Wikipedia: Buddy memory allocation](https://en.wikipedia.org/wiki/Buddy_memory_allocation)
3. [Linux Kernel Buddy System](https://www.kernel.org/doc/gorman/html/understand/understand009.html)
4. ucore 实验指导书

## 10. 总结

Buddy System 是一种优秀的内存分配算法，在 ucore 中的实现充分体现了其设计的精巧之处：
- 使用完全二叉树实现高效的分裂与合并
- O(log N) 的时间复杂度保证了性能
- 简洁的代码实现体现了"少即是多"的设计哲学

虽然存在内部碎片的问题，但通过与其他算法（如 Slab）结合使用，可以构建高效的内存管理系统。
