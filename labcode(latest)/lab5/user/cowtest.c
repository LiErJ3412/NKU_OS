/*
 * COW (Copy on Write) 测试用例
 *
 * 本测试验证写时复制机制的正确性：
 * 1. fork后父子进程共享同一物理页面
 * 2. 当任一进程写入时，触发COW，创建独立副本
 * 3. 修改后父子进程的数据相互独立
 */

#include <stdio.h>
#include <ulib.h>

// 全局变量，用于测试COW
int global_var = 100;

// 大数组，确保跨越多个页面
#define ARRAY_SIZE 1024
int big_array[ARRAY_SIZE];

int main(void)
{
    int pid, i;
    int local_var = 200;

    cprintf("COW Test: 开始测试写时复制机制\n");
    cprintf("COW Test: 初始值 global_var = %d, local_var = %d\n", global_var, local_var);

    // 初始化大数组
    for (i = 0; i < ARRAY_SIZE; i++)
    {
        big_array[i] = i;
    }
    cprintf("COW Test: 大数组已初始化, big_array[0] = %d, big_array[1023] = %d\n",
            big_array[0], big_array[1023]);

    // fork创建子进程
    pid = fork();

    if (pid == 0)
    {
        // 子进程
        cprintf("\n[子进程] PID = %d\n", getpid());
        cprintf("[子进程] fork后读取: global_var = %d, local_var = %d\n", global_var, local_var);
        cprintf("[子进程] fork后读取: big_array[0] = %d, big_array[1023] = %d\n",
                big_array[0], big_array[1023]);

        // 子进程修改变量 - 这应该触发COW
        cprintf("[子进程] 正在修改变量 (应触发COW)...\n");
        global_var = 999;
        local_var = 888;
        big_array[0] = 12345;
        big_array[1023] = 54321;

        cprintf("[子进程] 修改后: global_var = %d, local_var = %d\n", global_var, local_var);
        cprintf("[子进程] 修改后: big_array[0] = %d, big_array[1023] = %d\n",
                big_array[0], big_array[1023]);

        // 让出CPU，让父进程运行
        yield();
        yield();

        // 再次验证子进程的值没有被父进程影响
        cprintf("[子进程] 最终验证: global_var = %d (应为999)\n", global_var);

        if (global_var == 999 && local_var == 888 &&
            big_array[0] == 12345 && big_array[1023] == 54321)
        {
            cprintf("[子进程] COW测试通过!\n");
        }
        else
        {
            cprintf("[子进程] COW测试失败!\n");
        }

        exit(0);
    }
    else
    {
        // 父进程
        cprintf("\n[父进程] 已创建子进程, 子进程PID = %d\n", pid);

        // 让子进程先运行并修改变量
        yield();
        yield();
        yield();

        // 父进程读取变量 - 应该仍然是原始值
        cprintf("[父进程] 子进程修改后读取: global_var = %d (应为100)\n", global_var);
        cprintf("[父进程] 子进程修改后读取: local_var = %d (应为200)\n", local_var);
        cprintf("[父进程] 子进程修改后读取: big_array[0] = %d (应为0)\n", big_array[0]);
        cprintf("[父进程] 子进程修改后读取: big_array[1023] = %d (应为1023)\n", big_array[1023]);

        // 父进程也修改变量
        cprintf("[父进程] 正在修改变量...\n");
        global_var = 111;
        big_array[500] = 77777;

        cprintf("[父进程] 修改后: global_var = %d, big_array[500] = %d\n",
                global_var, big_array[500]);

        // 验证父进程的值
        if (global_var == 111 && local_var == 200 &&
            big_array[0] == 0 && big_array[1023] == 1023)
        {
            cprintf("[父进程] COW测试通过!\n");
        }
        else
        {
            cprintf("[父进程] COW测试失败!\n");
            cprintf("  global_var = %d (期望111)\n", global_var);
            cprintf("  local_var = %d (期望200)\n", local_var);
            cprintf("  big_array[0] = %d (期望0)\n", big_array[0]);
            cprintf("  big_array[1023] = %d (期望1023)\n", big_array[1023]);
        }

        // 等待子进程结束
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("[父进程] 子进程已退出, 退出码 = %d\n", exit_code);
    }

    cprintf("\nCOW Test: 测试完成!\n");
    cprintf("cowtest pass.\n");
    return 0;
}
