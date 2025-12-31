#include <stdio.h>
#include <proc.h>
#include <sem.h>
#include <monitor.h>
#include <assert.h>

#define N 5 /* 哲学家数目 */
#define LEFT (i-1+N)%N /* i的左邻号码 */
#define RIGHT (i+1)%N /* i的右邻号码 */
#define THINKING 0 /* 哲学家正在思考 */
#define HUNGRY 1 /* 哲学家想取得叉子 */
#define EATING 2 /* 哲学家正在吃面 */
#define TIMES  4 /* 吃4次饭 */
#define SLEEP_TIME 10

//-----------------philosopher problem using monitor ------------
/*PSEUDO CODE :philosopher problem using semaphore
system DINING_PHILOSOPHERS

VAR
me:    semaphore, initially 1;                    # for mutual exclusion 
s[5]:  semaphore s[5], initially 0;               # for synchronization 
pflag[5]: {THINK, HUNGRY, EAT}, initially THINK;  # philosopher flag 

# As before, each philosopher is an endless cycle of thinking and eating.

procedure philosopher(i)
  {
    while TRUE do
     {
       THINKING;
       take_chopsticks(i);
       EATING;
       drop_chopsticks(i);
     }
  }

# The take_chopsticks procedure involves checking the status of neighboring 
# philosophers and then declaring one's own intention to eat. This is a two-phase 
# protocol; first declaring the status HUNGRY, then going on to EAT.

procedure take_chopsticks(i)
  {
    DOWN(me);               # critical section 
    pflag[i] := HUNGRY;
    test[i];
    UP(me);                 # end critical section 
    DOWN(s[i])              # Eat if enabled 
   }

void test(i)                # Let phil[i] eat, if waiting 
  {
    if ( pflag[i] == HUNGRY
      && pflag[i-1] != EAT
      && pflag[i+1] != EAT)
       then
        {
          pflag[i] := EAT;
          UP(s[i])
         }
    }


# Once a philosopher finishes eating, all that remains is to relinquish the 
# resources---its two chopsticks---and thereby release waiting neighbors.

void drop_chopsticks(int i)
  {
    DOWN(me);                # critical section 
    test(i-1);               # Let phil. on left eat if possible 
    test(i+1);               # Let phil. on rght eat if possible 
    UP(me);                  # up critical section 
   }

*/
//---------- philosophers problem using semaphore ----------------------
int state_sema[N]; /* 记录每个人状态的数组 */
/* 信号量是一个特殊的整型变量 */
semaphore_t mutex; /* 临界区互斥 */
semaphore_t s[N]; /* 每个哲学家一个信号量 */

struct proc_struct *philosopher_proc_sema[N];

void phi_test_sema(int i) /* i：哲学家号码从0到N-1 */
{ 
    if(state_sema[i]==HUNGRY&&state_sema[LEFT]!=EATING
            &&state_sema[RIGHT]!=EATING)
    {
        state_sema[i]=EATING;
        up(&s[i]);
    }
}

void phi_take_forks_sema(int i) /* i：哲学家号码从0到N-1 */
{ 
        down(&mutex); /* 进入临界区 */
        state_sema[i]=HUNGRY; /* 记录下哲学家i饥饿的事实 */
        phi_test_sema(i); /* 试图得到两只叉子 */
        up(&mutex); /* 离开临界区 */
        down(&s[i]); /* 如果得不到叉子就阻塞 */
}

void phi_put_forks_sema(int i) /* i：哲学家号码从0到N-1 */
{ 
        down(&mutex); /* 进入临界区 */
        state_sema[i]=THINKING; /* 哲学家进餐结束 */
        phi_test_sema(LEFT); /* 看一下左邻居现在是否能进餐 */
        phi_test_sema(RIGHT); /* 看一下右邻居现在是否能进餐 */
        up(&mutex); /* 离开临界区 */
}

int philosopher_using_semaphore(void * arg) /* i：哲学家号码，从0到N-1 */
{
    int i, iter=0;
    i=(int)arg;
    cprintf("I am No.%d philosopher_sema\n",i);
    while(iter++<TIMES)
    { /* 无限循环 */
        cprintf("Iter %d, No.%d philosopher_sema is thinking\n",iter,i); /* 哲学家正在思考 */
        do_sleep(SLEEP_TIME);
        phi_take_forks_sema(i); 
        /* 需要两只叉子，或者阻塞 */
        cprintf("Iter %d, No.%d philosopher_sema is eating\n",iter,i); /* 进餐 */
        do_sleep(SLEEP_TIME);
        phi_put_forks_sema(i); 
        /* 把两把叉子同时放回桌子 */
    }
    cprintf("No.%d philosopher_sema quit\n",i);
    return 0;    
}

//-----------------philosopher problem using monitor ------------
/*PSEUDO CODE :philosopher problem using monitor
 * monitor dp
 * {
 *  enum {thinking, hungry, eating} state[5];
 *  condition self[5];
 *
 *  void pickup(int i) {
 *      state[i] = hungry;
 *      if ((state[(i+4)%5] != eating) && (state[(i+1)%5] != eating)) {
 *        state[i] = eating;
 *      else
 *         self[i].wait();
 *   }
 *
 *   void putdown(int i) {
 *      state[i] = thinking;
 *      if ((state[(i+4)%5] == hungry) && (state[(i+3)%5] != eating)) {
 *          state[(i+4)%5] = eating;
 *          self[(i+4)%5].signal();
 *      }
 *      if ((state[(i+1)%5] == hungry) && (state[(i+2)%5] != eating)) {
 *          state[(i+1)%5] = eating;
 *          self[(i+1)%5].signal();
 *      }
 *   }
 *
 *   void init() {
 *      for (int i = 0; i < 5; i++)
 *         state[i] = thinking;
 *   }
 * }
 */

struct proc_struct *philosopher_proc_condvar[N]; // N philosopher
int state_condvar[N];                            // the philosopher's state: EATING, HUNGARY, THINKING  
monitor_t mt, *mtp=&mt;                          // monitor

void phi_test_condvar (int i) { 
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
            &&state_condvar[RIGHT]!=EATING) {
        cprintf("phi_test_condvar: state_condvar[%d] will eating\n",i);
        state_condvar[i] = EATING ;
        cprintf("phi_test_condvar: signal self_cv[%d] \n",i);
        cond_signal(&mtp->cv[i]) ;
    }
}


void phi_take_forks_condvar(int i) {
     down(&(mtp->mutex));   // 进入管程，获取互斥锁
//--------into routine in monitor--------------
     // LAB7 YOUR CODE 2312300 填写你在lab7中实现的代码
     // I am hungry
     // try to get fork

    /*
     * 哲学家尝试拿叉子的逻辑：
     * 1. 设置状态为HUNGRY（我饿了）
     * 2. 尝试拿叉子（检查左右邻居是否在吃）
     * 3. 如果拿不到，就在自己的条件变量上等待
     */
    state_condvar[i] = HUNGRY;      // 声明：我饿了！
    phi_test_condvar(i);            // 尝试拿叉子

    // 如果还是HUNGRY，说明没拿到叉子，需要等待
    // 等到邻居吃完放下叉子时会signal唤醒我
    if (state_condvar[i] == HUNGRY) {
        cond_wait(&mtp->cv[i]);     // 等待...
    }
//--------leave routine in monitor--------------
    // 离开管程：把控制权交给等待的signal线程或释放互斥锁
      if(mtp->next_count>0)
         up(&(mtp->next));
      else
         up(&(mtp->mutex));
}

void phi_put_forks_condvar(int i) {
     down(&(mtp->mutex));   // 进入管程

//--------into routine in monitor--------------
     // LAB7 YOUR CODE 2311024 填写你在lab7中实现的代码
     // I ate over
     // test left and right neighbors

    /*
     * 哲学家放下叉子的逻辑：
     * 1. 设置状态为THINKING（我吃完了，开始思考）
     * 2. 检查左邻居能否吃（可能之前在等我的叉子）
     * 3. 检查右邻居能否吃（可能之前在等我的叉子）
     *
     * phi_test_condvar会检查邻居是否满足进餐条件
     * 如果满足，会调用cond_signal唤醒那个邻居
     */
    state_condvar[i] = THINKING;    // 我吃完了
    phi_test_condvar(LEFT);         // 看看左邻居能不能吃
    phi_test_condvar(RIGHT);        // 看看右邻居能不能吃
//--------leave routine in monitor--------------
    // 离开管程
     if(mtp->next_count>0)
        up(&(mtp->next));
     else
        up(&(mtp->mutex));
}

//---------- philosophers using monitor (condition variable) ----------------------
int philosopher_using_condvar(void * arg) { /* arg is the No. of philosopher 0~N-1*/
  
    int i, iter=0;
    i=(int)arg;
    cprintf("I am No.%d philosopher_condvar\n",i);
    while(iter++<TIMES)
    { /* iterate*/
        cprintf("Iter %d, No.%d philosopher_condvar is thinking\n",iter,i); /* thinking*/
        do_sleep(SLEEP_TIME);
        phi_take_forks_condvar(i); 
        /* need two forks, maybe blocked */
        cprintf("Iter %d, No.%d philosopher_condvar is eating\n",iter,i); /* eating*/
        do_sleep(SLEEP_TIME);
        phi_put_forks_condvar(i); 
        /* return two forks back*/
    }
    cprintf("No.%d philosopher_condvar quit\n",i);
    return 0;    
}

void check_sync(void){

    int i, pids[N];

    //check semaphore
    sem_init(&mutex, 1);
    for(i=0;i<N;i++){
        sem_init(&s[i], 0);
        int pid = kernel_thread(philosopher_using_semaphore, (void *)i, 0);
        if (pid <= 0) {
            panic("create No.%d philosopher_using_semaphore failed.\n");
        }
        pids[i] = pid;
        philosopher_proc_sema[i] = find_proc(pid);
        set_proc_name(philosopher_proc_sema[i], "philosopher_sema_proc");
    }
    for (i=0;i<N;i++)
        assert(do_wait(pids[i],NULL) == 0);

    //check condition variable
    monitor_init(&mt, N);
    for(i=0;i<N;i++){
        state_condvar[i]=THINKING;
        int pid = kernel_thread(philosopher_using_condvar, (void *)i, 0);
        if (pid <= 0) {
            panic("create No.%d philosopher_using_condvar failed.\n");
        }
        pids[i] = pid;
        philosopher_proc_condvar[i] = find_proc(pid);
        set_proc_name(philosopher_proc_condvar[i], "philosopher_condvar_proc");
    }
    for (i=0;i<N;i++)
        assert(do_wait(pids[i],NULL) == 0);
    monitor_free(&mt, N);
}
