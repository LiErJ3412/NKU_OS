#include <stdio.h>
#include <monitor.h>
#include <kmalloc.h>
#include <assert.h>


// Initialize monitor.
void     
monitor_init (monitor_t * mtp, size_t num_cv) {
    int i;
    assert(num_cv>0);
    mtp->next_count = 0;
    mtp->cv = NULL;
    sem_init(&(mtp->mutex), 1); //unlocked
    sem_init(&(mtp->next), 0);
    mtp->cv =(condvar_t *) kmalloc(sizeof(condvar_t)*num_cv);
    assert(mtp->cv!=NULL);
    for(i=0; i<num_cv; i++){
        mtp->cv[i].count=0;
        sem_init(&(mtp->cv[i].sem),0);
        mtp->cv[i].owner=mtp;
    }
}

// Free monitor.
void
monitor_free (monitor_t * mtp, size_t num_cv) {
    kfree(mtp->cv);
}

// Unlock one of threads waiting on the condition variable. 
void
cond_signal (condvar_t *cvp) {
   //LAB7 YOUR CODE 2311024 填写你在lab7中实现的代码
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
  /*
   *      cond_signal(cv) {
   *          if(cv.count>0) {
   *             mt.next_count ++;
   *             signal(cv.sem);
   *             wait(mt.next);
   *             mt.next_count--;
   *          }
   *       }
   */

    /*
     * cond_signal的作用：唤醒一个在条件变量上等待的线程
     *
     * Hansen管程语义：signal后，当前线程让出控制权给被唤醒的线程
     * 被唤醒的线程执行完后，再把控制权还给signal的线程
     *
     * 为什么要next_count++和down(next)？
     * 因为signal线程需要等待被唤醒的线程执行完
     * next_count记录了有多少线程在等待"接力棒"
     */
    if (cvp->count > 0) {   // 有线程在等待这个条件变量
        monitor_t* const mtp = cvp->owner;
        mtp->next_count++;  // 我要等待了，计数+1
        up(&(cvp->sem));    // 唤醒等待的线程
        down(&(mtp->next)); // 自己睡眠，等被唤醒的线程把控制权还给我
        mtp->next_count--;  // 我被唤醒了，计数-1
    }
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
}

// Suspend calling thread on a condition variable waiting for condition Atomically unlocks 
// mutex and suspends calling thread on conditional variable after waking up locks mutex. Notice: mp is mutex semaphore for monitor's procedures
void
cond_wait (condvar_t *cvp) {
    //LAB7 YOUR CODE 2311990 填写你在lab7中实现的代码
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
   /*
    *         cv.count ++;
    *         if(mt.next_count>0)
    *            signal(mt.next)
    *         else
    *            signal(mt.mutex);
    *         wait(cv.sem);
    *         cv.count --;
    */

    /*
     * cond_wait的作用：当前线程在条件变量上等待
     *
     * 为什么要释放锁？
     * 因为当前线程要睡眠了，如果不释放锁，其他线程无法进入管程
     *
     * 为什么要区分up(next)和up(mutex)？
     * - 如果有signal的线程在等待(next_count>0)，优先唤醒它
     * - 否则释放管程的互斥锁，让外面的线程进入
     */
    cvp->count++;   // 等待计数+1
    monitor_t* const mtp = cvp->owner;

    // 释放锁：让其他线程有机会执行
    if (mtp->next_count > 0) {
        // 有signal的线程在等"接力棒"，把控制权给它
        up(&(mtp->next));
    } else {
        // 没有等待的signal线程，释放管程互斥锁
        up(&(mtp->mutex));
    }

    // 在条件变量上睡眠，等待被signal唤醒
    down(&(cvp->sem));
    cvp->count--;   // 被唤醒了，等待计数-1
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
}
