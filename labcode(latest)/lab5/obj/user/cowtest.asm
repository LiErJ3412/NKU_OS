
obj/__user_cowtest.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  800020:	0ce000ef          	jal	ra,8000ee <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800026:	1141                	addi	sp,sp,-16
  800028:	e022                	sd	s0,0(sp)
  80002a:	e406                	sd	ra,8(sp)
  80002c:	842e                	mv	s0,a1
    sys_putc(c);
  80002e:	09c000ef          	jal	ra,8000ca <sys_putc>
    (*cnt) ++;
  800032:	401c                	lw	a5,0(s0)
}
  800034:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800036:	2785                	addiw	a5,a5,1
  800038:	c01c                	sw	a5,0(s0)
}
  80003a:	6402                	ld	s0,0(sp)
  80003c:	0141                	addi	sp,sp,16
  80003e:	8082                	ret

0000000000800040 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  800040:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  800042:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  800046:	8e2a                	mv	t3,a0
  800048:	f42e                	sd	a1,40(sp)
  80004a:	f832                	sd	a2,48(sp)
  80004c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80004e:	00000517          	auipc	a0,0x0
  800052:	fd850513          	addi	a0,a0,-40 # 800026 <cputch>
  800056:	004c                	addi	a1,sp,4
  800058:	869a                	mv	a3,t1
  80005a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  80005c:	ec06                	sd	ra,24(sp)
  80005e:	e0ba                	sd	a4,64(sp)
  800060:	e4be                	sd	a5,72(sp)
  800062:	e8c2                	sd	a6,80(sp)
  800064:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  800066:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  800068:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80006a:	0fc000ef          	jal	ra,800166 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  80006e:	60e2                	ld	ra,24(sp)
  800070:	4512                	lw	a0,4(sp)
  800072:	6125                	addi	sp,sp,96
  800074:	8082                	ret

0000000000800076 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800076:	7175                	addi	sp,sp,-144
  800078:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  80007a:	e0ba                	sd	a4,64(sp)
  80007c:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  80007e:	e42a                	sd	a0,8(sp)
  800080:	ecae                	sd	a1,88(sp)
  800082:	f0b2                	sd	a2,96(sp)
  800084:	f4b6                	sd	a3,104(sp)
  800086:	fcbe                	sd	a5,120(sp)
  800088:	e142                	sd	a6,128(sp)
  80008a:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  80008c:	f42e                	sd	a1,40(sp)
  80008e:	f832                	sd	a2,48(sp)
  800090:	fc36                	sd	a3,56(sp)
  800092:	f03a                	sd	a4,32(sp)
  800094:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);

    asm volatile (
  800096:	6522                	ld	a0,8(sp)
  800098:	75a2                	ld	a1,40(sp)
  80009a:	7642                	ld	a2,48(sp)
  80009c:	76e2                	ld	a3,56(sp)
  80009e:	6706                	ld	a4,64(sp)
  8000a0:	67a6                	ld	a5,72(sp)
  8000a2:	00000073          	ecall
  8000a6:	00a13e23          	sd	a0,28(sp)
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}
  8000aa:	4572                	lw	a0,28(sp)
  8000ac:	6149                	addi	sp,sp,144
  8000ae:	8082                	ret

00000000008000b0 <sys_exit>:

int
sys_exit(int64_t error_code) {
  8000b0:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  8000b2:	4505                	li	a0,1
  8000b4:	b7c9                	j	800076 <syscall>

00000000008000b6 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  8000b6:	4509                	li	a0,2
  8000b8:	bf7d                	j	800076 <syscall>

00000000008000ba <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  8000ba:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  8000bc:	85aa                	mv	a1,a0
  8000be:	450d                	li	a0,3
  8000c0:	bf5d                	j	800076 <syscall>

00000000008000c2 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000c2:	4529                	li	a0,10
  8000c4:	bf4d                	j	800076 <syscall>

00000000008000c6 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000c6:	4549                	li	a0,18
  8000c8:	b77d                	j	800076 <syscall>

00000000008000ca <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000ca:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000cc:	4579                	li	a0,30
  8000ce:	b765                	j	800076 <syscall>

00000000008000d0 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000d0:	1141                	addi	sp,sp,-16
  8000d2:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000d4:	fddff0ef          	jal	ra,8000b0 <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000d8:	00000517          	auipc	a0,0x0
  8000dc:	6a050513          	addi	a0,a0,1696 # 800778 <main+0x274>
  8000e0:	f61ff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000e4:	a001                	j	8000e4 <exit+0x14>

00000000008000e6 <fork>:
}

int
fork(void) {
    return sys_fork();
  8000e6:	bfc1                	j	8000b6 <sys_fork>

00000000008000e8 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  8000e8:	bfc9                	j	8000ba <sys_wait>

00000000008000ea <yield>:
}

void
yield(void) {
    sys_yield();
  8000ea:	bfe1                	j	8000c2 <sys_yield>

00000000008000ec <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000ec:	bfe9                	j	8000c6 <sys_getpid>

00000000008000ee <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000ee:	1141                	addi	sp,sp,-16
  8000f0:	e406                	sd	ra,8(sp)
    int ret = main();
  8000f2:	412000ef          	jal	ra,800504 <main>
    exit(ret);
  8000f6:	fdbff0ef          	jal	ra,8000d0 <exit>

00000000008000fa <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000fa:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000fe:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800100:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800104:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800106:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80010a:	f022                	sd	s0,32(sp)
  80010c:	ec26                	sd	s1,24(sp)
  80010e:	e84a                	sd	s2,16(sp)
  800110:	f406                	sd	ra,40(sp)
  800112:	e44e                	sd	s3,8(sp)
  800114:	84aa                	mv	s1,a0
  800116:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800118:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80011c:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80011e:	03067e63          	bgeu	a2,a6,80015a <printnum+0x60>
  800122:	89be                	mv	s3,a5
        while (-- width > 0)
  800124:	00805763          	blez	s0,800132 <printnum+0x38>
  800128:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80012a:	85ca                	mv	a1,s2
  80012c:	854e                	mv	a0,s3
  80012e:	9482                	jalr	s1
        while (-- width > 0)
  800130:	fc65                	bnez	s0,800128 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800132:	1a02                	slli	s4,s4,0x20
  800134:	00000797          	auipc	a5,0x0
  800138:	65c78793          	addi	a5,a5,1628 # 800790 <main+0x28c>
  80013c:	020a5a13          	srli	s4,s4,0x20
  800140:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800142:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800144:	000a4503          	lbu	a0,0(s4)
}
  800148:	70a2                	ld	ra,40(sp)
  80014a:	69a2                	ld	s3,8(sp)
  80014c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80014e:	85ca                	mv	a1,s2
  800150:	87a6                	mv	a5,s1
}
  800152:	6942                	ld	s2,16(sp)
  800154:	64e2                	ld	s1,24(sp)
  800156:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800158:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80015a:	03065633          	divu	a2,a2,a6
  80015e:	8722                	mv	a4,s0
  800160:	f9bff0ef          	jal	ra,8000fa <printnum>
  800164:	b7f9                	j	800132 <printnum+0x38>

0000000000800166 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800166:	7119                	addi	sp,sp,-128
  800168:	f4a6                	sd	s1,104(sp)
  80016a:	f0ca                	sd	s2,96(sp)
  80016c:	ecce                	sd	s3,88(sp)
  80016e:	e8d2                	sd	s4,80(sp)
  800170:	e4d6                	sd	s5,72(sp)
  800172:	e0da                	sd	s6,64(sp)
  800174:	fc5e                	sd	s7,56(sp)
  800176:	f06a                	sd	s10,32(sp)
  800178:	fc86                	sd	ra,120(sp)
  80017a:	f8a2                	sd	s0,112(sp)
  80017c:	f862                	sd	s8,48(sp)
  80017e:	f466                	sd	s9,40(sp)
  800180:	ec6e                	sd	s11,24(sp)
  800182:	892a                	mv	s2,a0
  800184:	84ae                	mv	s1,a1
  800186:	8d32                	mv	s10,a2
  800188:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80018a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  80018e:	5b7d                	li	s6,-1
  800190:	00000a97          	auipc	s5,0x0
  800194:	634a8a93          	addi	s5,s5,1588 # 8007c4 <main+0x2c0>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800198:	00001b97          	auipc	s7,0x1
  80019c:	848b8b93          	addi	s7,s7,-1976 # 8009e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a0:	000d4503          	lbu	a0,0(s10)
  8001a4:	001d0413          	addi	s0,s10,1
  8001a8:	01350a63          	beq	a0,s3,8001bc <vprintfmt+0x56>
            if (ch == '\0') {
  8001ac:	c121                	beqz	a0,8001ec <vprintfmt+0x86>
            putch(ch, putdat);
  8001ae:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001b2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b4:	fff44503          	lbu	a0,-1(s0)
  8001b8:	ff351ae3          	bne	a0,s3,8001ac <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001bc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001c0:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001c4:	4c81                	li	s9,0
  8001c6:	4881                	li	a7,0
        width = precision = -1;
  8001c8:	5c7d                	li	s8,-1
  8001ca:	5dfd                	li	s11,-1
  8001cc:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001d0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001d2:	fdd6059b          	addiw	a1,a2,-35
  8001d6:	0ff5f593          	zext.b	a1,a1
  8001da:	00140d13          	addi	s10,s0,1
  8001de:	04b56263          	bltu	a0,a1,800222 <vprintfmt+0xbc>
  8001e2:	058a                	slli	a1,a1,0x2
  8001e4:	95d6                	add	a1,a1,s5
  8001e6:	4194                	lw	a3,0(a1)
  8001e8:	96d6                	add	a3,a3,s5
  8001ea:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001ec:	70e6                	ld	ra,120(sp)
  8001ee:	7446                	ld	s0,112(sp)
  8001f0:	74a6                	ld	s1,104(sp)
  8001f2:	7906                	ld	s2,96(sp)
  8001f4:	69e6                	ld	s3,88(sp)
  8001f6:	6a46                	ld	s4,80(sp)
  8001f8:	6aa6                	ld	s5,72(sp)
  8001fa:	6b06                	ld	s6,64(sp)
  8001fc:	7be2                	ld	s7,56(sp)
  8001fe:	7c42                	ld	s8,48(sp)
  800200:	7ca2                	ld	s9,40(sp)
  800202:	7d02                	ld	s10,32(sp)
  800204:	6de2                	ld	s11,24(sp)
  800206:	6109                	addi	sp,sp,128
  800208:	8082                	ret
            padc = '0';
  80020a:	87b2                	mv	a5,a2
            goto reswitch;
  80020c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800210:	846a                	mv	s0,s10
  800212:	00140d13          	addi	s10,s0,1
  800216:	fdd6059b          	addiw	a1,a2,-35
  80021a:	0ff5f593          	zext.b	a1,a1
  80021e:	fcb572e3          	bgeu	a0,a1,8001e2 <vprintfmt+0x7c>
            putch('%', putdat);
  800222:	85a6                	mv	a1,s1
  800224:	02500513          	li	a0,37
  800228:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80022a:	fff44783          	lbu	a5,-1(s0)
  80022e:	8d22                	mv	s10,s0
  800230:	f73788e3          	beq	a5,s3,8001a0 <vprintfmt+0x3a>
  800234:	ffed4783          	lbu	a5,-2(s10)
  800238:	1d7d                	addi	s10,s10,-1
  80023a:	ff379de3          	bne	a5,s3,800234 <vprintfmt+0xce>
  80023e:	b78d                	j	8001a0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800240:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800244:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800248:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80024a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80024e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800252:	02d86463          	bltu	a6,a3,80027a <vprintfmt+0x114>
                ch = *fmt;
  800256:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80025a:	002c169b          	slliw	a3,s8,0x2
  80025e:	0186873b          	addw	a4,a3,s8
  800262:	0017171b          	slliw	a4,a4,0x1
  800266:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800268:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80026c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80026e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800272:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800276:	fed870e3          	bgeu	a6,a3,800256 <vprintfmt+0xf0>
            if (width < 0)
  80027a:	f40ddce3          	bgez	s11,8001d2 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80027e:	8de2                	mv	s11,s8
  800280:	5c7d                	li	s8,-1
  800282:	bf81                	j	8001d2 <vprintfmt+0x6c>
            if (width < 0)
  800284:	fffdc693          	not	a3,s11
  800288:	96fd                	srai	a3,a3,0x3f
  80028a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  80028e:	00144603          	lbu	a2,1(s0)
  800292:	2d81                	sext.w	s11,s11
  800294:	846a                	mv	s0,s10
            goto reswitch;
  800296:	bf35                	j	8001d2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  800298:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  80029c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002a0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002a2:	846a                	mv	s0,s10
            goto process_precision;
  8002a4:	bfd9                	j	80027a <vprintfmt+0x114>
    if (lflag >= 2) {
  8002a6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002a8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ac:	01174463          	blt	a4,a7,8002b4 <vprintfmt+0x14e>
    else if (lflag) {
  8002b0:	1a088e63          	beqz	a7,80046c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002b4:	000a3603          	ld	a2,0(s4)
  8002b8:	46c1                	li	a3,16
  8002ba:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002bc:	2781                	sext.w	a5,a5
  8002be:	876e                	mv	a4,s11
  8002c0:	85a6                	mv	a1,s1
  8002c2:	854a                	mv	a0,s2
  8002c4:	e37ff0ef          	jal	ra,8000fa <printnum>
            break;
  8002c8:	bde1                	j	8001a0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002ca:	000a2503          	lw	a0,0(s4)
  8002ce:	85a6                	mv	a1,s1
  8002d0:	0a21                	addi	s4,s4,8
  8002d2:	9902                	jalr	s2
            break;
  8002d4:	b5f1                	j	8001a0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002d6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002dc:	01174463          	blt	a4,a7,8002e4 <vprintfmt+0x17e>
    else if (lflag) {
  8002e0:	18088163          	beqz	a7,800462 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002e4:	000a3603          	ld	a2,0(s4)
  8002e8:	46a9                	li	a3,10
  8002ea:	8a2e                	mv	s4,a1
  8002ec:	bfc1                	j	8002bc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002ee:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002f2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002f4:	846a                	mv	s0,s10
            goto reswitch;
  8002f6:	bdf1                	j	8001d2 <vprintfmt+0x6c>
            putch(ch, putdat);
  8002f8:	85a6                	mv	a1,s1
  8002fa:	02500513          	li	a0,37
  8002fe:	9902                	jalr	s2
            break;
  800300:	b545                	j	8001a0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800306:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800308:	846a                	mv	s0,s10
            goto reswitch;
  80030a:	b5e1                	j	8001d2 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80030c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80030e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800312:	01174463          	blt	a4,a7,80031a <vprintfmt+0x1b4>
    else if (lflag) {
  800316:	14088163          	beqz	a7,800458 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80031a:	000a3603          	ld	a2,0(s4)
  80031e:	46a1                	li	a3,8
  800320:	8a2e                	mv	s4,a1
  800322:	bf69                	j	8002bc <vprintfmt+0x156>
            putch('0', putdat);
  800324:	03000513          	li	a0,48
  800328:	85a6                	mv	a1,s1
  80032a:	e03e                	sd	a5,0(sp)
  80032c:	9902                	jalr	s2
            putch('x', putdat);
  80032e:	85a6                	mv	a1,s1
  800330:	07800513          	li	a0,120
  800334:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800336:	0a21                	addi	s4,s4,8
            goto number;
  800338:	6782                	ld	a5,0(sp)
  80033a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80033c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800340:	bfb5                	j	8002bc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800342:	000a3403          	ld	s0,0(s4)
  800346:	008a0713          	addi	a4,s4,8
  80034a:	e03a                	sd	a4,0(sp)
  80034c:	14040263          	beqz	s0,800490 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800350:	0fb05763          	blez	s11,80043e <vprintfmt+0x2d8>
  800354:	02d00693          	li	a3,45
  800358:	0cd79163          	bne	a5,a3,80041a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80035c:	00044783          	lbu	a5,0(s0)
  800360:	0007851b          	sext.w	a0,a5
  800364:	cf85                	beqz	a5,80039c <vprintfmt+0x236>
  800366:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  80036a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036e:	000c4563          	bltz	s8,800378 <vprintfmt+0x212>
  800372:	3c7d                	addiw	s8,s8,-1
  800374:	036c0263          	beq	s8,s6,800398 <vprintfmt+0x232>
                    putch('?', putdat);
  800378:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  80037a:	0e0c8e63          	beqz	s9,800476 <vprintfmt+0x310>
  80037e:	3781                	addiw	a5,a5,-32
  800380:	0ef47b63          	bgeu	s0,a5,800476 <vprintfmt+0x310>
                    putch('?', putdat);
  800384:	03f00513          	li	a0,63
  800388:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80038a:	000a4783          	lbu	a5,0(s4)
  80038e:	3dfd                	addiw	s11,s11,-1
  800390:	0a05                	addi	s4,s4,1
  800392:	0007851b          	sext.w	a0,a5
  800396:	ffe1                	bnez	a5,80036e <vprintfmt+0x208>
            for (; width > 0; width --) {
  800398:	01b05963          	blez	s11,8003aa <vprintfmt+0x244>
  80039c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  80039e:	85a6                	mv	a1,s1
  8003a0:	02000513          	li	a0,32
  8003a4:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003a6:	fe0d9be3          	bnez	s11,80039c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003aa:	6a02                	ld	s4,0(sp)
  8003ac:	bbd5                	j	8001a0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003b0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003b4:	01174463          	blt	a4,a7,8003bc <vprintfmt+0x256>
    else if (lflag) {
  8003b8:	08088d63          	beqz	a7,800452 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003bc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003c0:	0a044d63          	bltz	s0,80047a <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003c4:	8622                	mv	a2,s0
  8003c6:	8a66                	mv	s4,s9
  8003c8:	46a9                	li	a3,10
  8003ca:	bdcd                	j	8002bc <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003cc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003d0:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003d2:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003d4:	41f7d69b          	sraiw	a3,a5,0x1f
  8003d8:	8fb5                	xor	a5,a5,a3
  8003da:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003de:	02d74163          	blt	a4,a3,800400 <vprintfmt+0x29a>
  8003e2:	00369793          	slli	a5,a3,0x3
  8003e6:	97de                	add	a5,a5,s7
  8003e8:	639c                	ld	a5,0(a5)
  8003ea:	cb99                	beqz	a5,800400 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003ec:	86be                	mv	a3,a5
  8003ee:	00000617          	auipc	a2,0x0
  8003f2:	3d260613          	addi	a2,a2,978 # 8007c0 <main+0x2bc>
  8003f6:	85a6                	mv	a1,s1
  8003f8:	854a                	mv	a0,s2
  8003fa:	0ce000ef          	jal	ra,8004c8 <printfmt>
  8003fe:	b34d                	j	8001a0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800400:	00000617          	auipc	a2,0x0
  800404:	3b060613          	addi	a2,a2,944 # 8007b0 <main+0x2ac>
  800408:	85a6                	mv	a1,s1
  80040a:	854a                	mv	a0,s2
  80040c:	0bc000ef          	jal	ra,8004c8 <printfmt>
  800410:	bb41                	j	8001a0 <vprintfmt+0x3a>
                p = "(null)";
  800412:	00000417          	auipc	s0,0x0
  800416:	39640413          	addi	s0,s0,918 # 8007a8 <main+0x2a4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80041a:	85e2                	mv	a1,s8
  80041c:	8522                	mv	a0,s0
  80041e:	e43e                	sd	a5,8(sp)
  800420:	0c8000ef          	jal	ra,8004e8 <strnlen>
  800424:	40ad8dbb          	subw	s11,s11,a0
  800428:	01b05b63          	blez	s11,80043e <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80042c:	67a2                	ld	a5,8(sp)
  80042e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800432:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800434:	85a6                	mv	a1,s1
  800436:	8552                	mv	a0,s4
  800438:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80043a:	fe0d9ce3          	bnez	s11,800432 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80043e:	00044783          	lbu	a5,0(s0)
  800442:	00140a13          	addi	s4,s0,1
  800446:	0007851b          	sext.w	a0,a5
  80044a:	d3a5                	beqz	a5,8003aa <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80044c:	05e00413          	li	s0,94
  800450:	bf39                	j	80036e <vprintfmt+0x208>
        return va_arg(*ap, int);
  800452:	000a2403          	lw	s0,0(s4)
  800456:	b7ad                	j	8003c0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800458:	000a6603          	lwu	a2,0(s4)
  80045c:	46a1                	li	a3,8
  80045e:	8a2e                	mv	s4,a1
  800460:	bdb1                	j	8002bc <vprintfmt+0x156>
  800462:	000a6603          	lwu	a2,0(s4)
  800466:	46a9                	li	a3,10
  800468:	8a2e                	mv	s4,a1
  80046a:	bd89                	j	8002bc <vprintfmt+0x156>
  80046c:	000a6603          	lwu	a2,0(s4)
  800470:	46c1                	li	a3,16
  800472:	8a2e                	mv	s4,a1
  800474:	b5a1                	j	8002bc <vprintfmt+0x156>
                    putch(ch, putdat);
  800476:	9902                	jalr	s2
  800478:	bf09                	j	80038a <vprintfmt+0x224>
                putch('-', putdat);
  80047a:	85a6                	mv	a1,s1
  80047c:	02d00513          	li	a0,45
  800480:	e03e                	sd	a5,0(sp)
  800482:	9902                	jalr	s2
                num = -(long long)num;
  800484:	6782                	ld	a5,0(sp)
  800486:	8a66                	mv	s4,s9
  800488:	40800633          	neg	a2,s0
  80048c:	46a9                	li	a3,10
  80048e:	b53d                	j	8002bc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  800490:	03b05163          	blez	s11,8004b2 <vprintfmt+0x34c>
  800494:	02d00693          	li	a3,45
  800498:	f6d79de3          	bne	a5,a3,800412 <vprintfmt+0x2ac>
                p = "(null)";
  80049c:	00000417          	auipc	s0,0x0
  8004a0:	30c40413          	addi	s0,s0,780 # 8007a8 <main+0x2a4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a4:	02800793          	li	a5,40
  8004a8:	02800513          	li	a0,40
  8004ac:	00140a13          	addi	s4,s0,1
  8004b0:	bd6d                	j	80036a <vprintfmt+0x204>
  8004b2:	00000a17          	auipc	s4,0x0
  8004b6:	2f7a0a13          	addi	s4,s4,759 # 8007a9 <main+0x2a5>
  8004ba:	02800513          	li	a0,40
  8004be:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004c2:	05e00413          	li	s0,94
  8004c6:	b565                	j	80036e <vprintfmt+0x208>

00000000008004c8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004c8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004ca:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004ce:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004d0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d2:	ec06                	sd	ra,24(sp)
  8004d4:	f83a                	sd	a4,48(sp)
  8004d6:	fc3e                	sd	a5,56(sp)
  8004d8:	e0c2                	sd	a6,64(sp)
  8004da:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004dc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004de:	c89ff0ef          	jal	ra,800166 <vprintfmt>
}
  8004e2:	60e2                	ld	ra,24(sp)
  8004e4:	6161                	addi	sp,sp,80
  8004e6:	8082                	ret

00000000008004e8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004e8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004ea:	e589                	bnez	a1,8004f4 <strnlen+0xc>
  8004ec:	a811                	j	800500 <strnlen+0x18>
        cnt ++;
  8004ee:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004f0:	00f58863          	beq	a1,a5,800500 <strnlen+0x18>
  8004f4:	00f50733          	add	a4,a0,a5
  8004f8:	00074703          	lbu	a4,0(a4)
  8004fc:	fb6d                	bnez	a4,8004ee <strnlen+0x6>
  8004fe:	85be                	mv	a1,a5
    }
    return cnt;
}
  800500:	852e                	mv	a0,a1
  800502:	8082                	ret

0000000000800504 <main>:
// 大数组，确保跨越多个页面
#define ARRAY_SIZE 1024
int big_array[ARRAY_SIZE];

int main(void)
{
  800504:	715d                	addi	sp,sp,-80
    int pid, i;
    int local_var = 200;

    cprintf("COW Test: 开始测试写时复制机制\n");
  800506:	00000517          	auipc	a0,0x0
  80050a:	5a250513          	addi	a0,a0,1442 # 800aa8 <error_string+0xc8>
{
  80050e:	e486                	sd	ra,72(sp)
  800510:	e0a2                	sd	s0,64(sp)
  800512:	fc26                	sd	s1,56(sp)
  800514:	f84a                	sd	s2,48(sp)
  800516:	f44e                	sd	s3,40(sp)
  800518:	f052                	sd	s4,32(sp)
  80051a:	ec56                	sd	s5,24(sp)
    cprintf("COW Test: 初始值 global_var = %d, local_var = %d\n", global_var, local_var);
  80051c:	00002497          	auipc	s1,0x2
  800520:	ae448493          	addi	s1,s1,-1308 # 802000 <global_var>
    cprintf("COW Test: 开始测试写时复制机制\n");
  800524:	b1dff0ef          	jal	ra,800040 <cprintf>
    cprintf("COW Test: 初始值 global_var = %d, local_var = %d\n", global_var, local_var);
  800528:	408c                	lw	a1,0(s1)
  80052a:	0c800613          	li	a2,200
  80052e:	00000517          	auipc	a0,0x0
  800532:	5aa50513          	addi	a0,a0,1450 # 800ad8 <error_string+0xf8>
  800536:	b0bff0ef          	jal	ra,800040 <cprintf>

    // 初始化大数组
    for (i = 0; i < ARRAY_SIZE; i++)
  80053a:	00002417          	auipc	s0,0x2
  80053e:	ace40413          	addi	s0,s0,-1330 # 802008 <big_array>
  800542:	8722                	mv	a4,s0
  800544:	4781                	li	a5,0
  800546:	40000693          	li	a3,1024
    {
        big_array[i] = i;
  80054a:	c31c                	sw	a5,0(a4)
    for (i = 0; i < ARRAY_SIZE; i++)
  80054c:	2785                	addiw	a5,a5,1
  80054e:	0711                	addi	a4,a4,4
  800550:	fed79de3          	bne	a5,a3,80054a <main+0x46>
    }
    cprintf("COW Test: 大数组已初始化, big_array[0] = %d, big_array[1023] = %d\n",
  800554:	00003997          	auipc	s3,0x3
  800558:	ab498993          	addi	s3,s3,-1356 # 803008 <big_array+0x1000>
  80055c:	ffc9a603          	lw	a2,-4(s3)
  800560:	400c                	lw	a1,0(s0)
  800562:	00000517          	auipc	a0,0x0
  800566:	5ae50513          	addi	a0,a0,1454 # 800b10 <error_string+0x130>
  80056a:	ad7ff0ef          	jal	ra,800040 <cprintf>
            big_array[0], big_array[1023]);

    // fork创建子进程
    pid = fork();
  80056e:	b79ff0ef          	jal	ra,8000e6 <fork>
  800572:	892a                	mv	s2,a0

    if (pid == 0)
  800574:	12050b63          	beqz	a0,8006aa <main+0x1a6>
        exit(0);
    }
    else
    {
        // 父进程
        cprintf("\n[父进程] 已创建子进程, 子进程PID = %d\n", pid);
  800578:	85aa                	mv	a1,a0
  80057a:	00000517          	auipc	a0,0x0
  80057e:	7ae50513          	addi	a0,a0,1966 # 800d28 <error_string+0x348>
  800582:	abfff0ef          	jal	ra,800040 <cprintf>

        // 让子进程先运行并修改变量
        yield();
  800586:	b65ff0ef          	jal	ra,8000ea <yield>
        yield();
  80058a:	b61ff0ef          	jal	ra,8000ea <yield>
        yield();
  80058e:	b5dff0ef          	jal	ra,8000ea <yield>

        // 父进程读取变量 - 应该仍然是原始值
        cprintf("[父进程] 子进程修改后读取: global_var = %d (应为100)\n", global_var);
  800592:	408c                	lw	a1,0(s1)
  800594:	00000517          	auipc	a0,0x0
  800598:	7cc50513          	addi	a0,a0,1996 # 800d60 <error_string+0x380>
        cprintf("[父进程] 子进程修改后读取: big_array[0] = %d (应为0)\n", big_array[0]);
        cprintf("[父进程] 子进程修改后读取: big_array[1023] = %d (应为1023)\n", big_array[1023]);

        // 父进程也修改变量
        cprintf("[父进程] 正在修改变量...\n");
        global_var = 111;
  80059c:	06f00a13          	li	s4,111
        cprintf("[父进程] 子进程修改后读取: global_var = %d (应为100)\n", global_var);
  8005a0:	aa1ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[父进程] 子进程修改后读取: local_var = %d (应为200)\n", local_var);
  8005a4:	0c800593          	li	a1,200
  8005a8:	00001517          	auipc	a0,0x1
  8005ac:	80050513          	addi	a0,a0,-2048 # 800da8 <error_string+0x3c8>
  8005b0:	a91ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[父进程] 子进程修改后读取: big_array[0] = %d (应为0)\n", big_array[0]);
  8005b4:	400c                	lw	a1,0(s0)
  8005b6:	00001517          	auipc	a0,0x1
  8005ba:	83a50513          	addi	a0,a0,-1990 # 800df0 <error_string+0x410>
  8005be:	a83ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[父进程] 子进程修改后读取: big_array[1023] = %d (应为1023)\n", big_array[1023]);
  8005c2:	ffc9a583          	lw	a1,-4(s3)
  8005c6:	00001517          	auipc	a0,0x1
  8005ca:	87250513          	addi	a0,a0,-1934 # 800e38 <error_string+0x458>
  8005ce:	a73ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[父进程] 正在修改变量...\n");
  8005d2:	00001517          	auipc	a0,0x1
  8005d6:	8b650513          	addi	a0,a0,-1866 # 800e88 <error_string+0x4a8>
  8005da:	a67ff0ef          	jal	ra,800040 <cprintf>
        big_array[500] = 77777;
  8005de:	664d                	lui	a2,0x13
  8005e0:	fd160613          	addi	a2,a2,-47 # 12fd1 <_start-0x7ed04f>

        cprintf("[父进程] 修改后: global_var = %d, big_array[500] = %d\n",
  8005e4:	06f00593          	li	a1,111
  8005e8:	00001517          	auipc	a0,0x1
  8005ec:	8c850513          	addi	a0,a0,-1848 # 800eb0 <error_string+0x4d0>
        global_var = 111;
  8005f0:	0144a023          	sw	s4,0(s1)
        big_array[500] = 77777;
  8005f4:	7cc42823          	sw	a2,2000(s0)
        cprintf("[父进程] 修改后: global_var = %d, big_array[500] = %d\n",
  8005f8:	a49ff0ef          	jal	ra,800040 <cprintf>
                global_var, big_array[500]);

        // 验证父进程的值
        if (global_var == 111 && local_var == 200 &&
  8005fc:	409c                	lw	a5,0(s1)
  8005fe:	01479463          	bne	a5,s4,800606 <main+0x102>
  800602:	401c                	lw	a5,0(s0)
  800604:	c7d1                	beqz	a5,800690 <main+0x18c>
        {
            cprintf("[父进程] COW测试通过!\n");
        }
        else
        {
            cprintf("[父进程] COW测试失败!\n");
  800606:	00001517          	auipc	a0,0x1
  80060a:	90a50513          	addi	a0,a0,-1782 # 800f10 <error_string+0x530>
  80060e:	a33ff0ef          	jal	ra,800040 <cprintf>
            cprintf("  global_var = %d (期望111)\n", global_var);
  800612:	408c                	lw	a1,0(s1)
  800614:	00001517          	auipc	a0,0x1
  800618:	91c50513          	addi	a0,a0,-1764 # 800f30 <error_string+0x550>
  80061c:	a25ff0ef          	jal	ra,800040 <cprintf>
            cprintf("  local_var = %d (期望200)\n", local_var);
  800620:	0c800593          	li	a1,200
  800624:	00001517          	auipc	a0,0x1
  800628:	92c50513          	addi	a0,a0,-1748 # 800f50 <error_string+0x570>
  80062c:	a15ff0ef          	jal	ra,800040 <cprintf>
            cprintf("  big_array[0] = %d (期望0)\n", big_array[0]);
  800630:	400c                	lw	a1,0(s0)
  800632:	00001517          	auipc	a0,0x1
  800636:	93e50513          	addi	a0,a0,-1730 # 800f70 <error_string+0x590>
  80063a:	a07ff0ef          	jal	ra,800040 <cprintf>
            cprintf("  big_array[1023] = %d (期望1023)\n", big_array[1023]);
  80063e:	ffc9a583          	lw	a1,-4(s3)
  800642:	00001517          	auipc	a0,0x1
  800646:	94e50513          	addi	a0,a0,-1714 # 800f90 <error_string+0x5b0>
  80064a:	9f7ff0ef          	jal	ra,800040 <cprintf>
        }

        // 等待子进程结束
        int exit_code;
        waitpid(pid, &exit_code);
  80064e:	006c                	addi	a1,sp,12
  800650:	854a                	mv	a0,s2
  800652:	a97ff0ef          	jal	ra,8000e8 <waitpid>
        cprintf("[父进程] 子进程已退出, 退出码 = %d\n", exit_code);
  800656:	45b2                	lw	a1,12(sp)
  800658:	00001517          	auipc	a0,0x1
  80065c:	96050513          	addi	a0,a0,-1696 # 800fb8 <error_string+0x5d8>
  800660:	9e1ff0ef          	jal	ra,800040 <cprintf>
    }

    cprintf("\nCOW Test: 测试完成!\n");
  800664:	00001517          	auipc	a0,0x1
  800668:	98450513          	addi	a0,a0,-1660 # 800fe8 <error_string+0x608>
  80066c:	9d5ff0ef          	jal	ra,800040 <cprintf>
    cprintf("cowtest pass.\n");
  800670:	00001517          	auipc	a0,0x1
  800674:	99850513          	addi	a0,a0,-1640 # 801008 <error_string+0x628>
  800678:	9c9ff0ef          	jal	ra,800040 <cprintf>
    return 0;
}
  80067c:	60a6                	ld	ra,72(sp)
  80067e:	6406                	ld	s0,64(sp)
  800680:	74e2                	ld	s1,56(sp)
  800682:	7942                	ld	s2,48(sp)
  800684:	79a2                	ld	s3,40(sp)
  800686:	7a02                	ld	s4,32(sp)
  800688:	6ae2                	ld	s5,24(sp)
  80068a:	4501                	li	a0,0
  80068c:	6161                	addi	sp,sp,80
  80068e:	8082                	ret
            big_array[0] == 0 && big_array[1023] == 1023)
  800690:	ffc9a703          	lw	a4,-4(s3)
  800694:	3ff00793          	li	a5,1023
  800698:	f6f717e3          	bne	a4,a5,800606 <main+0x102>
            cprintf("[父进程] COW测试通过!\n");
  80069c:	00001517          	auipc	a0,0x1
  8006a0:	85450513          	addi	a0,a0,-1964 # 800ef0 <error_string+0x510>
  8006a4:	99dff0ef          	jal	ra,800040 <cprintf>
  8006a8:	b75d                	j	80064e <main+0x14a>
        cprintf("\n[子进程] PID = %d\n", getpid());
  8006aa:	a43ff0ef          	jal	ra,8000ec <getpid>
  8006ae:	85aa                	mv	a1,a0
  8006b0:	00000517          	auipc	a0,0x0
  8006b4:	4b050513          	addi	a0,a0,1200 # 800b60 <error_string+0x180>
  8006b8:	989ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] fork后读取: global_var = %d, local_var = %d\n", global_var, local_var);
  8006bc:	408c                	lw	a1,0(s1)
  8006be:	0c800613          	li	a2,200
  8006c2:	00000517          	auipc	a0,0x0
  8006c6:	4b650513          	addi	a0,a0,1206 # 800b78 <error_string+0x198>
  8006ca:	977ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] fork后读取: big_array[0] = %d, big_array[1023] = %d\n",
  8006ce:	ffc9a603          	lw	a2,-4(s3)
  8006d2:	400c                	lw	a1,0(s0)
  8006d4:	00000517          	auipc	a0,0x0
  8006d8:	4e450513          	addi	a0,a0,1252 # 800bb8 <error_string+0x1d8>
        big_array[0] = 12345;
  8006dc:	6a0d                	lui	s4,0x3
        cprintf("[子进程] fork后读取: big_array[0] = %d, big_array[1023] = %d\n",
  8006de:	963ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 正在修改变量 (应触发COW)...\n");
  8006e2:	00000517          	auipc	a0,0x0
  8006e6:	51e50513          	addi	a0,a0,1310 # 800c00 <error_string+0x220>
  8006ea:	957ff0ef          	jal	ra,800040 <cprintf>
        big_array[1023] = 54321;
  8006ee:	6935                	lui	s2,0xd
        cprintf("[子进程] 修改后: global_var = %d, local_var = %d\n", global_var, local_var);
  8006f0:	37800613          	li	a2,888
  8006f4:	3e700593          	li	a1,999
        global_var = 999;
  8006f8:	3e700a93          	li	s5,999
        big_array[0] = 12345;
  8006fc:	039a0a13          	addi	s4,s4,57 # 3039 <_start-0x7fcfe7>
        big_array[1023] = 54321;
  800700:	43190913          	addi	s2,s2,1073 # d431 <_start-0x7f2bef>
        cprintf("[子进程] 修改后: global_var = %d, local_var = %d\n", global_var, local_var);
  800704:	00000517          	auipc	a0,0x0
  800708:	53450513          	addi	a0,a0,1332 # 800c38 <error_string+0x258>
        global_var = 999;
  80070c:	0154a023          	sw	s5,0(s1)
        big_array[0] = 12345;
  800710:	01442023          	sw	s4,0(s0)
        big_array[1023] = 54321;
  800714:	ff29ae23          	sw	s2,-4(s3)
        cprintf("[子进程] 修改后: global_var = %d, local_var = %d\n", global_var, local_var);
  800718:	929ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 修改后: big_array[0] = %d, big_array[1023] = %d\n",
  80071c:	ffc9a603          	lw	a2,-4(s3)
  800720:	400c                	lw	a1,0(s0)
  800722:	00000517          	auipc	a0,0x0
  800726:	54e50513          	addi	a0,a0,1358 # 800c70 <error_string+0x290>
  80072a:	917ff0ef          	jal	ra,800040 <cprintf>
        yield();
  80072e:	9bdff0ef          	jal	ra,8000ea <yield>
        yield();
  800732:	9b9ff0ef          	jal	ra,8000ea <yield>
        cprintf("[子进程] 最终验证: global_var = %d (应为999)\n", global_var);
  800736:	408c                	lw	a1,0(s1)
  800738:	00000517          	auipc	a0,0x0
  80073c:	57850513          	addi	a0,a0,1400 # 800cb0 <error_string+0x2d0>
  800740:	901ff0ef          	jal	ra,800040 <cprintf>
        if (global_var == 999 && local_var == 888 &&
  800744:	409c                	lw	a5,0(s1)
  800746:	01579563          	bne	a5,s5,800750 <main+0x24c>
  80074a:	401c                	lw	a5,0(s0)
  80074c:	01478b63          	beq	a5,s4,800762 <main+0x25e>
            cprintf("[子进程] COW测试失败!\n");
  800750:	00000517          	auipc	a0,0x0
  800754:	5b850513          	addi	a0,a0,1464 # 800d08 <error_string+0x328>
  800758:	8e9ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  80075c:	4501                	li	a0,0
  80075e:	973ff0ef          	jal	ra,8000d0 <exit>
            big_array[0] == 12345 && big_array[1023] == 54321)
  800762:	ffc9a783          	lw	a5,-4(s3)
  800766:	ff2795e3          	bne	a5,s2,800750 <main+0x24c>
            cprintf("[子进程] COW测试通过!\n");
  80076a:	00000517          	auipc	a0,0x0
  80076e:	57e50513          	addi	a0,a0,1406 # 800ce8 <error_string+0x308>
  800772:	8cfff0ef          	jal	ra,800040 <cprintf>
  800776:	b7dd                	j	80075c <main+0x258>
