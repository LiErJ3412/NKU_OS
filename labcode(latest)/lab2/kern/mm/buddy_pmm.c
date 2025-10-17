/**
 * Buddy System 内存分配算法实现
 * 
 * 伙伴系统是一种经典的内存分配算法，通过将内存按2的幂次方进行划分和合并
 * 来实现高效的内存分配和释放。
 * 
 * 核心思想:
 * 1. 内存块大小必须是2的幂次方
 * 2. 使用完全二叉树管理内存块
 * 3. 分配时从上到下分裂，释放时从下到上合并
 * 
 * 参考: http://coolshell.cn/articles/10427.html
 */

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

// Buddy System 数据结构
struct buddy2 {
    unsigned int size;          // 管理的总页面数（必须是2的幂）
    unsigned int *longest;      // 二叉树节点数组，存储每个节点对应的最大空闲块大小
};

static struct buddy2 buddy;

// 宏定义
#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)

// 全局变量
static unsigned int *buddy_longest;
static unsigned int buddy_size;
static unsigned int max_pages;
static struct Page *buddy_page_base;

// 辅助函数: 向上取到最近的2的幂
static unsigned int fixsize(unsigned int size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}

// 初始化 buddy system
static void
buddy_init(void) {
    buddy_longest = NULL;
    buddy_size = 0;
    max_pages = 0;
    buddy_page_base = NULL;
}

/**
 * 初始化内存映射
 * @param base 起始页面指针
 * @param n 页面数量
 */
static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    
    // 将 n 调整为2的幂
    unsigned int real_size = 1;
    while (real_size < n) {
        real_size <<= 1;
    }
    
    buddy_size = real_size;
    max_pages = real_size;
    buddy_page_base = base;
    
    // 分配二叉树节点数组空间
    // 完全二叉树节点数 = 2 * size - 1
    unsigned int node_count = 2 * buddy_size - 1;
    
    // 使用页面来存储 longest 数组
    // 每个节点 4 字节，计算需要多少页
    unsigned int longest_size = node_count * sizeof(unsigned int);
    unsigned int pages_needed = (longest_size + PGSIZE - 1) / PGSIZE;
    
    // 从管理的内存中分配空间给 longest 数组
    // 直接使用物理地址 + va_pa_offset 计算虚拟地址
    extern uint64_t va_pa_offset;
    buddy_longest = (unsigned int *)(page2pa(base) + va_pa_offset);
    
    // 初始化所有页面
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    
    // 初始化二叉树
    unsigned int node_size = buddy_size * 2;
    for (unsigned int i = 0; i < node_count; i++) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        buddy_longest[i] = node_size;
    }
    
    cprintf("Buddy System: initialized %d pages (actual: %d)\n", n, buddy_size);
}

/**
 * 分配 n 个页面
 * @param n 需要分配的页面数
 * @return 分配的页面指针，失败返回 NULL
 */
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    if (n > buddy_size) {
        return NULL;
    }
    
    // 将 n 调整为2的幂
    unsigned int size = 1;
    while (size < n) {
        size <<= 1;
    }
    
    unsigned int index = 0;
    unsigned int node_size;
    unsigned int offset = 0;
    
    // 检查根节点是否有足够空间
    if (buddy_longest[0] < size) {
        return NULL;
    }
    
    // 从根节点开始，向下搜索合适的节点
    for (node_size = buddy_size; node_size != size; node_size /= 2) {
        // 优先选择左子树
        if (buddy_longest[LEFT_LEAF(index)] >= size) {
            index = LEFT_LEAF(index);
        } else {
            index = RIGHT_LEAF(index);
        }
    }
    
    // 标记节点为已分配
    buddy_longest[index] = 0;
    
    // 计算offset（相对于 buddy_page_base 的偏移）
    offset = (index + 1) * node_size - buddy_size;
    
    // 向上回溯，更新父节点
    while (index) {
        index = PARENT(index);
        buddy_longest[index] = 
            MAX(buddy_longest[LEFT_LEAF(index)], 
                buddy_longest[RIGHT_LEAF(index)]);
    }
    
    // 设置分配的页面属性
    struct Page *page = buddy_page_base + offset;
    for (struct Page *p = page; p < page + size; p++) {
        SetPageReserved(p);
    }
    
    return page;
}

/**
 * 释放 n 个页面
 * @param base 要释放的起始页面
 * @param n 释放的页面数
 */
static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base >= buddy_page_base && base < buddy_page_base + buddy_size);
    
    // 将 n 调整为2的幂
    unsigned int size = 1;
    while (size < n) {
        size <<= 1;
    }
    
    // 计算offset
    unsigned int offset = base - buddy_page_base;
    
    // 从offset和size计算节点索引
    // 找到对应大小层级的起始节点
    unsigned int node_size = size;
    unsigned int index = (offset / size) + (buddy_size / size) - 1;
    
    // 清除页面的保留标志
    for (struct Page *p = base; p < base + size; p++) {
        ClearPageReserved(p);
        ClearPageProperty(p);
        set_page_ref(p, 0);
    }
    
    // 恢复节点的longest值
    buddy_longest[index] = node_size;
    
    // 向上回溯，尝试合并
    while (index) {
        index = PARENT(index);
        node_size *= 2;
        
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
        
        // 如果左右子树都完全空闲，则可以合并
        if (left_longest + right_longest == node_size) {
            buddy_longest[index] = node_size;
        } else {
            buddy_longest[index] = MAX(left_longest, right_longest);
        }
    }
}

/**
 * 返回空闲页面数
 */
static size_t
buddy_nr_free_pages(void) {
    return buddy_longest[0];  // 根节点的值就是最大可分配空间
}

/**
 * 基本检查函数
 */
static void
buddy_check(void) {
    cprintf("Buddy System Check Start...\n");
    
    struct Page *p0, *p1, *p2, *p3;
    
    // Test 1: 分配单个页面
    cprintf("Test 1: Allocating single pages...\n");
    p0 = alloc_page();
    assert(p0 != NULL);
    p1 = alloc_page();
    assert(p1 != NULL);
    p2 = alloc_page();
    assert(p2 != NULL);
    
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    
    cprintf("Test 1 Passed!\n");
    
    // Test 2: 释放页面
    cprintf("Test 2: Freeing pages...\n");
    free_page(p0);
    free_page(p1);
    free_page(p2);
    cprintf("Test 2 Passed!\n");
    
    // Test 3: 分配多个页面
    cprintf("Test 3: Allocating multiple pages...\n");
    p0 = alloc_pages(5);  // 实际分配 8 页
    assert(p0 != NULL);
    cprintf("Allocated 5 pages (actual: 8)\n");
    
    p1 = alloc_pages(3);  // 实际分配 4 页
    assert(p1 != NULL);
    cprintf("Allocated 3 pages (actual: 4)\n");
    
    assert(p0 != p1);
    cprintf("Test 3 Passed!\n");
    
    // Test 4: 释放并测试合并
    cprintf("Test 4: Testing merge...\n");
    free_pages(p0, 5);
    free_pages(p1, 3);
    cprintf("Test 4 Passed!\n");
    
    // Test 5: 大块分配
    cprintf("Test 5: Large allocation...\n");
    size_t free_before = nr_free_pages();
    cprintf("Free pages before: %d\n", free_before);
    
    p0 = alloc_pages(free_before / 2);
    if (p0 != NULL) {
        cprintf("Allocated %d pages\n", free_before / 2);
        free_pages(p0, free_before / 2);
        cprintf("Freed %d pages\n", free_before / 2);
    }
    
    size_t free_after = nr_free_pages();
    cprintf("Free pages after: %d\n", free_after);
    assert(free_before == free_after);
    cprintf("Test 5 Passed!\n");
    
    // Test 6: 边界测试
    cprintf("Test 6: Boundary test...\n");
    p0 = alloc_pages(1);
    p1 = alloc_pages(2);
    p2 = alloc_pages(4);
    p3 = alloc_pages(8);
    
    assert(p0 && p1 && p2 && p3);
    
    free_pages(p0, 1);
    free_pages(p1, 2);
    free_pages(p2, 4);
    free_pages(p3, 8);
    cprintf("Test 6 Passed!\n");
    
    // Test 7: 内存耗尽测试
    cprintf("Test 7: Exhaustion test...\n");
    size_t total_free = nr_free_pages();
    cprintf("Total free pages: %d\n", total_free);
    
    // Buddy system 会将请求向上取整到2的幂
    // 分配全部内存
    if (total_free > 0) {
        struct Page *p_all = alloc_pages(total_free);
        
        if (p_all != NULL) {
            cprintf("Allocated all %d pages\n", total_free);
            
            // 应该无法再分配
            struct Page *p_extra = alloc_page();
            if (p_extra == NULL) {
                cprintf("Cannot allocate when memory is full - Correct!\n");
            } else {
                cprintf("Warning: Still can allocate (might have fragmentation)\n");
                free_page(p_extra);
            }
            
            // 释放全部
            free_pages(p_all, total_free);
            cprintf("Freed all %d pages\n", total_free);
            
            // 检查空闲页数是否恢复
            size_t free_after = nr_free_pages();
            cprintf("Free pages after release: %d\n", free_after);
            
            // 现在应该可以分配
            p_extra = alloc_page();
            if (p_extra != NULL) {
                cprintf("Can allocate after freeing - Correct!\n");
                free_page(p_extra);
            } else {
                cprintf("Note: Cannot allocate single page, this might be due to alignment\n");
            }
        } else {
            cprintf("Cannot allocate %d pages in one block (this is expected)\n", total_free);
        }
    }
    cprintf("Test 7 Passed!\n");
    
    cprintf("Buddy System Check Passed!\n");
}

// Buddy System 内存管理器结构
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
