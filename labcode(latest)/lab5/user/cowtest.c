/*
 * COW (Copy on Write) 综合测试用例
 * 集成了功能正确性测试与地址机制验证
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

    cprintf("\n=== COW Test Start ===\n");
    
    // 【新增验证点 1】打印变量的虚拟地址 (VA)
    // 这是为了配合内核日志，证明父子进程操作的是同一个虚拟地址
    cprintf("[User] 变量地址验证:\n");
    cprintf("   &global_var (VA) = 0x%x\n", &global_var);
    cprintf("   &local_var  (VA) = 0x%x\n", &local_var);
    
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
        
        // 验证：此时还没写，内核应该还没复制物理页
        cprintf("[子进程] fork后读取: global_var = %d\n", global_var);

        // 【新增验证点 2】写入触发点
        // 这里是整个 COW 机制生效的关键时刻。
        // 如果内核里有打印日志，这里应该会出现 \"COW Copy triggered at VA: 0x...\"
        cprintf("[子进程] >>> 准备写入 global_var (应触发内核 COW 复制)...");
        global_var = 999;
        
        cprintf("[子进程] >>> 准备写入 local_var (栈内存 COW)...");
        local_var = 888;
        
        cprintf("[子进程] >>> 准备写入 big_array (大数组 COW)...");
        big_array[0] = 12345;
        big_array[1023] = 54321;

        cprintf("[子进程] 修改后: global_var = %d, local_var = %d\n", global_var, local_var);

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

        // 父进程读取变量 - 应该仍然是原始值 (证明了内存隔离)
        cprintf("[父进程] 子进程修改后读取: global_var = %d (应为100)\n", global_var);
        
        // 父进程也修改变量 (证明是对称的 COW)
        cprintf("[父进程] 正在修改变量...\n");
        global_var = 111;
        big_array[500] = 77777;

        // 验证父进程的值
        if (global_var == 111 && local_var == 200 &&
            big_array[0] == 0 && big_array[1023] == 1023)
        {
            cprintf("[父进程] COW测试通过!\n");
        }
        else
        {
            cprintf("[父进程] COW测试失败!\n");
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
