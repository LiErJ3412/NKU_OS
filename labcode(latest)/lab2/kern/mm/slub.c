/**
 * SLUB 分配器实现
 * 
 * SLUB (Simple List of Unused Blocks) 是一种两层架构的内存分配器：
 * 第一层：基于页面的内存分配（使用底层的页面分配器）
 * 第二层：在页面基础上实现任意大小的对象分配
 * 
 * 核心概念：
 * 1. kmem_cache: 对象缓存，管理特定大小的对象
 * 2. slab: 一个或多个连续的物理页面，被划分成固定大小的对象
 * 3. 每个CPU维护一个活动slab，避免锁竞争
 * 
 * 参考：Linux SLUB分配器
 */

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

// SLUB缓存的标志位
#define SLUB_HWCACHE_ALIGN  0x00000001  // 硬件缓存对齐
#define SLUB_DEBUG          0x00000002  // 启用调试
#define SLUB_RED_ZONE       0x00000004  // 红区检测

// 最小对象大小（字节）
#define MIN_OBJ_SIZE        16
// 最大对象大小（字节）- 超过此大小直接使用页分配器
#define MAX_OBJ_SIZE        PGSIZE

// 对象对齐
#define SLUB_ALIGN          8

// 每个slab的最大对象数
#define MAX_OBJECTS_PER_SLAB 256

/**
 * kmem_cache - 对象缓存描述符
 * 每种大小的对象都有一个对应的kmem_cache
 */
struct kmem_cache {
    const char *name;           // 缓存名称
    size_t size;                // 对象大小（包含元数据）
    size_t objsize;             // 实际对象大小
    size_t align;               // 对齐要求
    unsigned long flags;        // 标志位
    
    // Slab信息
    size_t objects;             // 每个slab的对象数
    unsigned int order;         // 每个slab需要2^order个页面
    
    // 部分使用的slab链表
    list_entry_t partial;       // partial slab链表头
    unsigned long nr_partial;   // partial slab数量
    
    // CPU本地缓存（简化版，只用一个）
    void *freelist;             // 空闲对象链表
    struct Page *page;          // 当前活动的slab页面
    
    // 统计信息
    unsigned long alloc_count;  // 分配计数
    unsigned long free_count;   // 释放计数
    
    // 链表节点
    list_entry_t list;          // 所有缓存的链表
};

/**
 * slab_page - slab页面元数据
 * 存储在每个slab的第一个页面的Page结构中
 */
struct slab_page {
    void *freelist;             // 空闲对象链表
    unsigned int inuse;         // 已使用对象数
    struct kmem_cache *cache;   // 所属缓存
};

// 全局变量
static list_entry_t kmem_cache_list;    // 所有kmem_cache的链表
static struct kmem_cache *kmalloc_caches[13];  // 通用大小的缓存

// 辅助宏
#define ALIGN_UP(size, align) (((size) + (align) - 1) & ~((align) - 1))

/**
 * 计算需要的页面数量
 */
static unsigned int calculate_order(size_t size, size_t objsize) {
    unsigned int order = 0;
    size_t min_objects = 4;  // 每个slab至少4个对象
    
    // 对于大对象，放宽限制
    if (objsize >= PGSIZE / 4) {
        min_objects = 2;
    }
    if (objsize >= PGSIZE / 2) {
        min_objects = 1;
    }
    
    while (order < 10) {  // 最多1024页
        size_t slab_size = PGSIZE << order;
        size_t objects = slab_size / objsize;
        
        if (objects >= min_objects && objects <= MAX_OBJECTS_PER_SLAB) {
            return order;
        }
        order++;
    }
    
    return 0;  // 使用1个页面
}

/**
 * 初始化slab页面
 */
static void init_slab_page(struct Page *page, struct kmem_cache *cache) {
    assert(page != NULL && cache != NULL);
    
    // 计算slab大小和对象数
    size_t slab_size = PGSIZE << cache->order;
    size_t objects = slab_size / cache->size;
    
    // 获取虚拟地址
    extern uint64_t va_pa_offset;
    void *slab_addr = (void *)(page2pa(page) + va_pa_offset);
    
    // 初始化空闲链表
    void *freelist = NULL;
    for (int i = objects - 1; i >= 0; i--) {
        void *obj = slab_addr + i * cache->size;
        *(void **)obj = freelist;
        freelist = obj;
    }
    
    // 设置页面元数据
    page->property = objects;  // 使用property存储对象总数
    SetPageProperty(page);
    
    // 在页面中保存元数据
    struct slab_page *sp = (struct slab_page *)page;
    sp->freelist = freelist;
    sp->inuse = 0;
    sp->cache = cache;
}

/**
 * 分配新的slab
 */
static struct Page *alloc_slab(struct kmem_cache *cache) {
    // 分配页面
    struct Page *page = alloc_pages(1 << cache->order);
    if (page == NULL) {
        return NULL;
    }
    
    // 初始化slab
    init_slab_page(page, cache);
    
    return page;
}

/**
 * 释放slab
 */
static void free_slab(struct kmem_cache *cache, struct Page *page) {
    ClearPageProperty(page);
    free_pages(page, 1 << cache->order);
}

/**
 * 创建kmem_cache
 */
struct kmem_cache *kmem_cache_create(const char *name, size_t size, 
                                     size_t align, unsigned long flags) {
    // 参数检查
    if (size == 0 || size > MAX_OBJ_SIZE) {
        return NULL;
    }
    
    // 分配kmem_cache结构 - 使用页分配器避免循环依赖
    static struct kmem_cache cache_pool[20];  // 静态池，足够用
    static int cache_count = 0;
    
    if (cache_count >= 20) {
        return NULL;
    }
    
    struct kmem_cache *cache = &cache_pool[cache_count++];
    
    // 初始化
    memset(cache, 0, sizeof(struct kmem_cache));
    cache->name = name;
    cache->objsize = size;
    cache->align = align > 0 ? align : SLUB_ALIGN;
    cache->size = ALIGN_UP(size, cache->align);
    cache->flags = flags;
    
    // 计算slab参数
    cache->order = calculate_order(cache->size, cache->size);
    size_t slab_size = PGSIZE << cache->order;
    cache->objects = slab_size / cache->size;
    
    // 初始化链表
    list_init(&cache->partial);
    cache->nr_partial = 0;
    cache->freelist = NULL;
    cache->page = NULL;
    
    // 统计信息
    cache->alloc_count = 0;
    cache->free_count = 0;
    
    // 添加到全局链表
    list_add(&kmem_cache_list, &cache->list);
    
    cprintf("SLUB: Created cache '%s', objsize=%d, size=%d, order=%d, objects=%d\n",
            name, cache->objsize, cache->size, cache->order, cache->objects);
    
    return cache;
}

/**
 * 从缓存中分配对象
 */
void *kmem_cache_alloc(struct kmem_cache *cache) {
    if (cache == NULL) {
        return NULL;
    }
    
    void *obj = NULL;
    
    // 1. 尝试从CPU本地缓存分配
    if (cache->freelist != NULL) {
        obj = cache->freelist;
        cache->freelist = *(void **)obj;
        cache->alloc_count++;
        return obj;
    }
    
    // 2. 尝试从partial链表获取slab
    if (!list_empty(&cache->partial)) {
        list_entry_t *le = list_next(&cache->partial);
        struct Page *page = le2page(le, page_link);
        struct slab_page *sp = (struct slab_page *)page;
        
        // 从slab分配对象
        if (sp->freelist != NULL) {
            obj = sp->freelist;
            sp->freelist = *(void **)obj;
            sp->inuse++;
            
            // 如果slab满了，从partial移除
            if (sp->freelist == NULL) {
                list_del(&page->page_link);
                cache->nr_partial--;
            }
            
            cache->alloc_count++;
            return obj;
        }
    }
    
    // 3. 分配新的slab
    struct Page *new_page = alloc_slab(cache);
    if (new_page == NULL) {
        return NULL;
    }
    
    struct slab_page *sp = (struct slab_page *)new_page;
    
    // 从新slab分配第一个对象
    obj = sp->freelist;
    sp->freelist = *(void **)obj;
    sp->inuse++;
    
    // 将slab设置为CPU本地缓存
    cache->freelist = sp->freelist;
    cache->page = new_page;
    
    // 添加到partial链表
    list_add(&cache->partial, &new_page->page_link);
    cache->nr_partial++;
    
    cache->alloc_count++;
    return obj;
}

/**
 * 释放对象到缓存
 */
void kmem_cache_free(struct kmem_cache *cache, void *obj) {
    if (cache == NULL || obj == NULL) {
        return;
    }
    
    // 查找对象所属的页面
    extern uint64_t va_pa_offset;
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
    struct Page *page = pa2page(page_addr - va_pa_offset);
    
    struct slab_page *sp = (struct slab_page *)page;
    
    // 将对象添加回空闲链表
    *(void **)obj = sp->freelist;
    sp->freelist = obj;
    sp->inuse--;
    
    cache->free_count++;
    
    // 如果slab完全空闲，考虑释放
    if (sp->inuse == 0) {
        // 从partial链表移除
        list_del(&page->page_link);
        cache->nr_partial--;
        
        // 释放slab（保留至少一个空slab）
        if (cache->nr_partial > 1) {
            free_slab(cache, page);
        } else {
            // 重新加回partial链表
            list_add(&cache->partial, &page->page_link);
            cache->nr_partial++;
        }
    } else if (sp->inuse == cache->objects - 1) {
        // slab从满变为partial，添加到链表
        list_add(&cache->partial, &page->page_link);
        cache->nr_partial++;
    }
}

/**
 * 销毁kmem_cache
 */
void kmem_cache_destroy(struct kmem_cache *cache) {
    if (cache == NULL) {
        return;
    }
    
    // 释放所有partial slab
    while (!list_empty(&cache->partial)) {
        list_entry_t *le = list_next(&cache->partial);
        struct Page *page = le2page(le, page_link);
        list_del(le);
        free_slab(cache, page);
    }
    
    // 释放CPU本地slab
    if (cache->page != NULL) {
        free_slab(cache, cache->page);
    }
    
    // 从全局链表移除
    list_del(&cache->list);
    
    // 释放cache结构本身
    kfree(cache);
}

/**
 * 通用内存分配 - kmalloc
 */
void *kmalloc(size_t size) {
    if (size == 0) {
        return NULL;
    }
    
    // 大对象直接用页分配器
    if (size > MAX_OBJ_SIZE) {
        unsigned int order = 0;
        size_t pages = (size + PGSIZE - 1) / PGSIZE;
        while ((1U << order) < pages) {
            order++;
        }
        
        struct Page *page = alloc_pages(1 << order);
        if (page == NULL) {
            return NULL;
        }
        
        extern uint64_t va_pa_offset;
        return (void *)(page2pa(page) + va_pa_offset);
    }
    
    // 选择合适的缓存
    int index = 0;
    if (size <= 64) index = 0;
    else if (size <= 128) index = 1;
    else if (size <= 256) index = 2;
    else if (size <= 512) index = 3;
    else if (size <= 1024) index = 4;
    else if (size <= 2048) index = 5;
    else index = 6;
    
    if (kmalloc_caches[index] == NULL) {
        return NULL;
    }
    
    return kmem_cache_alloc(kmalloc_caches[index]);
}

/**
 * 通用内存释放 - kfree
 */
void kfree(void *obj) {
    if (obj == NULL) {
        return;
    }
    
    // 查找对象所属的页面
    extern uint64_t va_pa_offset;
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
    struct Page *page = pa2page(page_addr - va_pa_offset);
    
    // 检查是否是slab对象
    if (PageProperty(page)) {
        struct slab_page *sp = (struct slab_page *)page;
        kmem_cache_free(sp->cache, obj);
    } else {
        // 大对象，直接释放页面
        free_pages(page, 1);
    }
}

/**
 * 初始化SLUB分配器
 */
void slub_init(void) {
    cprintf("SLUB: Initializing SLUB allocator...\n");
    
    // 初始化全局链表
    list_init(&kmem_cache_list);
    
    // 创建通用大小的缓存
    const size_t sizes[] = {64, 128, 256, 512, 1024, 2048, 4096};
    const char *names[] = {
        "kmalloc-64", "kmalloc-128", "kmalloc-256", "kmalloc-512",
        "kmalloc-1024", "kmalloc-2048", "kmalloc-4096"
    };
    
    for (int i = 0; i < 7; i++) {
        kmalloc_caches[i] = kmem_cache_create(names[i], sizes[i], 
                                               SLUB_ALIGN, 0);
        if (kmalloc_caches[i] == NULL) {
            panic("SLUB: Failed to create kmalloc cache for size %d\n", sizes[i]);
        }
    }
    
    cprintf("SLUB: Initialization complete\n");
}

/**
 * 测试SLUB分配器
 */
void slub_check(void) {
    cprintf("SLUB: Starting SLUB allocator tests...\n");
    
    // Test 1: 基本分配和释放
    cprintf("Test 1: Basic allocation and free...\n");
    void *p1 = kmalloc(64);
    void *p2 = kmalloc(128);
    void *p3 = kmalloc(256);
    
    assert(p1 != NULL && p2 != NULL && p3 != NULL);
    assert(p1 != p2 && p2 != p3 && p1 != p3);
    
    kfree(p1);
    kfree(p2);
    kfree(p3);
    cprintf("Test 1 Passed!\n");
    
    // Test 2: 重复分配
    cprintf("Test 2: Multiple allocations...\n");
    void *ptrs[10];
    for (int i = 0; i < 10; i++) {
        ptrs[i] = kmalloc(128);
        assert(ptrs[i] != NULL);
    }
    
    for (int i = 0; i < 10; i++) {
        kfree(ptrs[i]);
    }
    cprintf("Test 2 Passed!\n");
    
    // Test 3: 不同大小
    cprintf("Test 3: Different sizes...\n");
    void *p_small = kmalloc(16);
    void *p_medium = kmalloc(512);
    void *p_large = kmalloc(2048);
    
    assert(p_small != NULL && p_medium != NULL && p_large != NULL);
    
    kfree(p_small);
    kfree(p_medium);
    kfree(p_large);
    cprintf("Test 3 Passed!\n");
    
    // Test 4: 缓存统计
    cprintf("Test 4: Cache statistics...\n");
    cprintf("Cache Information:\n");
    list_entry_t *le = &kmem_cache_list;
    while ((le = list_next(le)) != &kmem_cache_list) {
        struct kmem_cache *cache = to_struct(le, struct kmem_cache, list);
        cprintf("  %s: alloc=%lu, free=%lu, partial=%lu\n",
                cache->name, cache->alloc_count, cache->free_count, 
                cache->nr_partial);
    }
    cprintf("Test 4 Passed!\n");
    
    cprintf("SLUB: All tests passed!\n");
}
