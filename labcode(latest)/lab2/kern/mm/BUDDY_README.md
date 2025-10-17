# Buddy System 实现 - README

## 文件列表

1. **buddy_pmm.c** - Buddy System核心实现代码
2. **buddy_pmm.h** - 头文件
3. **buddy_design.md** - 详细设计文档
4. **buddy_test_report.md** - 测试报告
5. **buddy_allocator.md** - 参考文档（来自CoolShell）

## 快速开始

### 1. 编译

```bash
cd /home/lierj/oslab2/NKU_OS/labcode\(latest\)/lab2
make clean
make
```

### 2. 运行

```bash
make qemu
```

### 3. 切换内存管理器

编辑 `kern/mm/pmm.c`，修改第38行：

```c
// 使用 Buddy System
pmm_manager = &buddy_pmm_manager;

// 使用 Best-Fit
// pmm_manager = &best_fit_pmm_manager;

// 使用 First-Fit  
// pmm_manager = &default_pmm_manager;
```

## 核心算法

### 分配算法
```
1. 将请求大小向上取整到2的幂
2. 从根节点开始向下搜索
3. 优先选择左子树（如果足够大）
4. 找到合适节点后标记为已分配
5. 向上回溯更新父节点
```

### 释放算法
```
1. 根据地址和大小计算节点索引
2. 恢复节点的longest值
3. 向上回溯，检查是否可以合并
4. 如果左右子树都空闲则合并
```

## 测试结果

所有7个测试用例全部通过：

- ✅ Test 1: 单页分配
- ✅ Test 2: 单页释放  
- ✅ Test 3: 多页分配
- ✅ Test 4: 页面合并
- ✅ Test 5: 大块分配
- ✅ Test 6: 边界测试
- ✅ Test 7: 内存耗尽

## 性能特点

| 特性 | 值 |
|------|-----|
| 分配时间复杂度 | O(log N) |
| 释放时间复杂度 | O(log N) |
| 空间开销 | 每页约8字节 |
| 外部碎片 | 很少 |
| 内部碎片 | 最多50% |

## 设计亮点

1. **极简设计**: 使用单个`longest`数组同时表示状态和大小
2. **数组实现**: 用数组表示完全二叉树，提高缓存命中率
3. **高效合并**: O(log N)时间自动合并相邻块
4. **精确控制**: 每个节点精确记录可用空间大小

## 参考资料

- [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)
- Wikipedia: Buddy memory allocation
- Linux Kernel Buddy System

## 作者

实验二扩展练习 - Buddy System实现

## 许可

This implementation is part of ucore lab2 exercises.
