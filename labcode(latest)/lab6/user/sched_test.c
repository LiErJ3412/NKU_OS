#include <stdio.h>
#include <ulib.h>
#include <stdlib.h>

#define MAX_TIME 100000000
#define TOTAL_PROCS 5

void spin(int ticks) {
    volatile int i;
    for (i = 0; i < ticks; i++) {
        ;
    }
}

int main(void) {
    int i, pid;
    int priorities[TOTAL_PROCS] = {5, 2, 4, 1, 3}; // 优先级/作业长度
    // 5: Longest, 1: Shortest
    
    cprintf("Starting quantitative analysis with %d processes\n", TOTAL_PROCS);
    unsigned int start_time = gettime_msec();

    for (i = 0; i < TOTAL_PROCS; i++) {
        // Set parent priority so child inherits it (crucial for SJF)
        lab6_setpriority(priorities[i]);

        if ((pid = fork()) == 0) {
            // Child
            unsigned int t_start = gettime_msec();
            cprintf("Child %d (pid %d, prio %d) started at %d\n", i, getpid(), priorities[i], t_start);
            
            // Simulate CPU burst proportional to priority (for SJF test)
            // Priority 1 (Short) -> 1x time
            // Priority 5 (Long)  -> 5x time
            spin(MAX_TIME * priorities[i]);
            
            unsigned int t_end = gettime_msec();
            cprintf("Child %d (pid %d, prio %d) finished at %d. RunTime: %d\n", 
                    i, getpid(), priorities[i], t_end, t_end - t_start);
            exit(0);
        }
        // No sleep here to let them enter ready queue almost simultaneously
    }

    for (i = 0; i < TOTAL_PROCS; i++) {
        wait();
    }

    unsigned int end_time = gettime_msec();
    cprintf("All children finished at %d. Total time: %d\n", end_time, end_time - start_time);
    return 0;
}
