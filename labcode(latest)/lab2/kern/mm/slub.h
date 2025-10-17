#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

// SLUB分配器接口

// 缓存管理
struct kmem_cache;

/**
 * 创建一个对象缓存
 * @param name 缓存名称
 * @param size 对象大小
 * @param align 对齐要求
 * @param flags 标志位
 * @return 缓存描述符，失败返回NULL
 */
struct kmem_cache *kmem_cache_create(const char *name, size_t size, 
                                     size_t align, unsigned long flags);

/**
 * 从缓存中分配一个对象
 * @param cache 缓存描述符
 * @return 对象指针，失败返回NULL
 */
void *kmem_cache_alloc(struct kmem_cache *cache);

/**
 * 释放对象到缓存
 * @param cache 缓存描述符
 * @param obj 对象指针
 */
void kmem_cache_free(struct kmem_cache *cache, void *obj);

/**
 * 销毁缓存
 * @param cache 缓存描述符
 */
void kmem_cache_destroy(struct kmem_cache *cache);

// 通用内存分配接口

/**
 * 分配任意大小的内存
 * @param size 字节数
 * @return 内存指针，失败返回NULL
 */
void *kmalloc(size_t size);

/**
 * 释放通过kmalloc分配的内存
 * @param obj 内存指针
 */
void kfree(void *obj);

// 初始化和测试

/**
 * 初始化SLUB分配器
 */
void slub_init(void);

/**
 * 测试SLUB分配器
 */
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */
