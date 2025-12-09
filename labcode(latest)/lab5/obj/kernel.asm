
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000b2517          	auipc	a0,0xb2
ffffffffc020004e:	28e50513          	addi	a0,a0,654 # ffffffffc02b22d8 <buf>
ffffffffc0200052:	000b6617          	auipc	a2,0xb6
ffffffffc0200056:	72a60613          	addi	a2,a2,1834 # ffffffffc02b677c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	0ef050ef          	jal	ra,ffffffffc0205950 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	91258593          	addi	a1,a1,-1774 # ffffffffc0205980 <etext+0x6>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	92a50513          	addi	a0,a0,-1750 # ffffffffc02059a0 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	744020ef          	jal	ra,ffffffffc02027ca <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	24d030ef          	jal	ra,ffffffffc0203ade <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	00c050ef          	jal	ra,ffffffffc02050a2 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	198050ef          	jal	ra,ffffffffc020523a <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	8ec50513          	addi	a0,a0,-1812 # ffffffffc02059a8 <etext+0x2e>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000b2b97          	auipc	s7,0xb2
ffffffffc02000d6:	206b8b93          	addi	s7,s7,518 # ffffffffc02b22d8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000b2517          	auipc	a0,0xb2
ffffffffc0200132:	1aa50513          	addi	a0,a0,426 # ffffffffc02b22d8 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	3a4050ef          	jal	ra,ffffffffc020552c <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	36e050ef          	jal	ra,ffffffffc020552c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	79250513          	addi	a0,a0,1938 # ffffffffc02059b0 <etext+0x36>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	79c50513          	addi	a0,a0,1948 # ffffffffc02059d0 <etext+0x56>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	73a58593          	addi	a1,a1,1850 # ffffffffc020597a <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	7a850513          	addi	a0,a0,1960 # ffffffffc02059f0 <etext+0x76>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000b2597          	auipc	a1,0xb2
ffffffffc0200258:	08458593          	addi	a1,a1,132 # ffffffffc02b22d8 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	7b450513          	addi	a0,a0,1972 # ffffffffc0205a10 <etext+0x96>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000b6597          	auipc	a1,0xb6
ffffffffc020026c:	51458593          	addi	a1,a1,1300 # ffffffffc02b677c <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	7c050513          	addi	a0,a0,1984 # ffffffffc0205a30 <etext+0xb6>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000b7597          	auipc	a1,0xb7
ffffffffc0200280:	8ff58593          	addi	a1,a1,-1793 # ffffffffc02b6b7b <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	7b250513          	addi	a0,a0,1970 # ffffffffc0205a50 <etext+0xd6>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	7d460613          	addi	a2,a2,2004 # ffffffffc0205a80 <etext+0x106>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	7e050513          	addi	a0,a0,2016 # ffffffffc0205a98 <etext+0x11e>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	7e860613          	addi	a2,a2,2024 # ffffffffc0205ab0 <etext+0x136>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	80058593          	addi	a1,a1,-2048 # ffffffffc0205ad0 <etext+0x156>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	80050513          	addi	a0,a0,-2048 # ffffffffc0205ad8 <etext+0x15e>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	80260613          	addi	a2,a2,-2046 # ffffffffc0205ae8 <etext+0x16e>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	82258593          	addi	a1,a1,-2014 # ffffffffc0205b10 <etext+0x196>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	7e250513          	addi	a0,a0,2018 # ffffffffc0205ad8 <etext+0x15e>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	81e60613          	addi	a2,a2,-2018 # ffffffffc0205b20 <etext+0x1a6>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	83658593          	addi	a1,a1,-1994 # ffffffffc0205b40 <etext+0x1c6>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	7c650513          	addi	a0,a0,1990 # ffffffffc0205ad8 <etext+0x15e>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00006517          	auipc	a0,0x6
ffffffffc0200350:	80450513          	addi	a0,a0,-2044 # ffffffffc0205b50 <etext+0x1d6>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00006517          	auipc	a0,0x6
ffffffffc0200372:	80a50513          	addi	a0,a0,-2038 # ffffffffc0205b78 <etext+0x1fe>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	864c0c13          	addi	s8,s8,-1948 # ffffffffc0205be8 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	81490913          	addi	s2,s2,-2028 # ffffffffc0205ba0 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	81448493          	addi	s1,s1,-2028 # ffffffffc0205ba8 <etext+0x22e>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	812b0b13          	addi	s6,s6,-2030 # ffffffffc0205bb0 <etext+0x236>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	72aa0a13          	addi	s4,s4,1834 # ffffffffc0205ad0 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00006d17          	auipc	s10,0x6
ffffffffc02003cc:	820d0d13          	addi	s10,s10,-2016 # ffffffffc0205be8 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	520050ef          	jal	ra,ffffffffc02058f6 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	50c050ef          	jal	ra,ffffffffc02058f6 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	512050ef          	jal	ra,ffffffffc020593a <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	4d4050ef          	jal	ra,ffffffffc020593a <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	75050513          	addi	a0,a0,1872 # ffffffffc0205bd0 <etext+0x256>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000b6317          	auipc	t1,0xb6
ffffffffc0200492:	27230313          	addi	t1,t1,626 # ffffffffc02b6700 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	77450513          	addi	a0,a0,1908 # ffffffffc0205c30 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00007517          	auipc	a0,0x7
ffffffffc02004d6:	89e50513          	addi	a0,a0,-1890 # ffffffffc0206d70 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	74a50513          	addi	a0,a0,1866 # ffffffffc0205c50 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00007517          	auipc	a0,0x7
ffffffffc020052a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0206d70 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_cowtest_out_size+0xc720>
ffffffffc0200540:	000b6717          	auipc	a4,0xb6
ffffffffc0200544:	1cf73823          	sd	a5,464(a4) # ffffffffc02b6710 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	71050513          	addi	a0,a0,1808 # ffffffffc0205c70 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000b6797          	auipc	a5,0xb6
ffffffffc020056c:	1a07b023          	sd	zero,416(a5) # ffffffffc02b6708 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000b6797          	auipc	a5,0xb6
ffffffffc020057a:	19a7b783          	ld	a5,410(a5) # ffffffffc02b6710 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	69050513          	addi	a0,a0,1680 # ffffffffc0205c90 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	67250513          	addi	a0,a0,1650 # ffffffffc0205ca0 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	66c50513          	addi	a0,a0,1644 # ffffffffc0205cb0 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	67450513          	addi	a0,a0,1652 # ffffffffc0205cc8 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe29771>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	60a90913          	addi	s2,s2,1546 # ffffffffc0205d18 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	5f448493          	addi	s1,s1,1524 # ffffffffc0205d10 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	62050513          	addi	a0,a0,1568 # ffffffffc0205d90 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	64c50513          	addi	a0,a0,1612 # ffffffffc0205dc8 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	52c50513          	addi	a0,a0,1324 # ffffffffc0205ce8 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	0e4050ef          	jal	ra,ffffffffc02058ae <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	13c050ef          	jal	ra,ffffffffc0205914 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	088050ef          	jal	ra,ffffffffc02058f6 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	49e50513          	addi	a0,a0,1182 # ffffffffc0205d20 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	3f050513          	addi	a0,a0,1008 # ffffffffc0205d40 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	3f650513          	addi	a0,a0,1014 # ffffffffc0205d58 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	40450513          	addi	a0,a0,1028 # ffffffffc0205d78 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	44850513          	addi	a0,a0,1096 # ffffffffc0205dc8 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000b6797          	auipc	a5,0xb6
ffffffffc020098c:	d887b823          	sd	s0,-624(a5) # ffffffffc02b6718 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000b6797          	auipc	a5,0xb6
ffffffffc0200994:	d967b823          	sd	s6,-624(a5) # ffffffffc02b6720 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000b6517          	auipc	a0,0xb6
ffffffffc020099e:	d7e53503          	ld	a0,-642(a0) # ffffffffc02b6718 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000b6517          	auipc	a0,0xb6
ffffffffc02009a8:	d7c53503          	ld	a0,-644(a0) # ffffffffc02b6720 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	53878793          	addi	a5,a5,1336 # ffffffffc0200ef8 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	40250513          	addi	a0,a0,1026 # ffffffffc0205de0 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	40a50513          	addi	a0,a0,1034 # ffffffffc0205df8 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	41450513          	addi	a0,a0,1044 # ffffffffc0205e10 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	41e50513          	addi	a0,a0,1054 # ffffffffc0205e28 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	42850513          	addi	a0,a0,1064 # ffffffffc0205e40 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	43250513          	addi	a0,a0,1074 # ffffffffc0205e58 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	43c50513          	addi	a0,a0,1084 # ffffffffc0205e70 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	44650513          	addi	a0,a0,1094 # ffffffffc0205e88 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	45050513          	addi	a0,a0,1104 # ffffffffc0205ea0 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	45a50513          	addi	a0,a0,1114 # ffffffffc0205eb8 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	46450513          	addi	a0,a0,1124 # ffffffffc0205ed0 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	46e50513          	addi	a0,a0,1134 # ffffffffc0205ee8 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	47850513          	addi	a0,a0,1144 # ffffffffc0205f00 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	48250513          	addi	a0,a0,1154 # ffffffffc0205f18 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	48c50513          	addi	a0,a0,1164 # ffffffffc0205f30 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	49650513          	addi	a0,a0,1174 # ffffffffc0205f48 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	4a050513          	addi	a0,a0,1184 # ffffffffc0205f60 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	4aa50513          	addi	a0,a0,1194 # ffffffffc0205f78 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	4b450513          	addi	a0,a0,1204 # ffffffffc0205f90 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	4be50513          	addi	a0,a0,1214 # ffffffffc0205fa8 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	4c850513          	addi	a0,a0,1224 # ffffffffc0205fc0 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fd8 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205ff0 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	4e650513          	addi	a0,a0,1254 # ffffffffc0206008 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	4f050513          	addi	a0,a0,1264 # ffffffffc0206020 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	4fa50513          	addi	a0,a0,1274 # ffffffffc0206038 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	50450513          	addi	a0,a0,1284 # ffffffffc0206050 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	50e50513          	addi	a0,a0,1294 # ffffffffc0206068 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	51850513          	addi	a0,a0,1304 # ffffffffc0206080 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	52250513          	addi	a0,a0,1314 # ffffffffc0206098 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	52c50513          	addi	a0,a0,1324 # ffffffffc02060b0 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	53250513          	addi	a0,a0,1330 # ffffffffc02060c8 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	53450513          	addi	a0,a0,1332 # ffffffffc02060e0 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	53450513          	addi	a0,a0,1332 # ffffffffc02060f8 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	53c50513          	addi	a0,a0,1340 # ffffffffc0206110 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	54450513          	addi	a0,a0,1348 # ffffffffc0206128 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	54050513          	addi	a0,a0,1344 # ffffffffc0206138 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	06f76c63          	bltu	a4,a5,ffffffffc0200c88 <interrupt_handler+0x82>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	5ec70713          	addi	a4,a4,1516 # ffffffffc0206200 <commands+0x618>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	58a50513          	addi	a0,a0,1418 # ffffffffc02061b0 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	55e50513          	addi	a0,a0,1374 # ffffffffc0206190 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	51250513          	addi	a0,a0,1298 # ffffffffc0206150 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	52650513          	addi	a0,a0,1318 # ffffffffc0206170 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200c5e:	000b6697          	auipc	a3,0xb6
ffffffffc0200c62:	aaa68693          	addi	a3,a3,-1366 # ffffffffc02b6708 <ticks>
ffffffffc0200c66:	629c                	ld	a5,0(a3)
ffffffffc0200c68:	06400713          	li	a4,100
ffffffffc0200c6c:	0785                	addi	a5,a5,1
ffffffffc0200c6e:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c72:	e29c                	sd	a5,0(a3)
ffffffffc0200c74:	cb19                	beqz	a4,ffffffffc0200c8a <interrupt_handler+0x84>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c76:	60a2                	ld	ra,8(sp)
ffffffffc0200c78:	0141                	addi	sp,sp,16
ffffffffc0200c7a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c7c:	00005517          	auipc	a0,0x5
ffffffffc0200c80:	56450513          	addi	a0,a0,1380 # ffffffffc02061e0 <commands+0x5f8>
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c88:	bf31                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c8a:	06400593          	li	a1,100
ffffffffc0200c8e:	00005517          	auipc	a0,0x5
ffffffffc0200c92:	54250513          	addi	a0,a0,1346 # ffffffffc02061d0 <commands+0x5e8>
ffffffffc0200c96:	cfeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            current->need_resched = 1;
ffffffffc0200c9a:	000b6797          	auipc	a5,0xb6
ffffffffc0200c9e:	ac67b783          	ld	a5,-1338(a5) # ffffffffc02b6760 <current>
ffffffffc0200ca2:	4705                	li	a4,1
ffffffffc0200ca4:	ef98                	sd	a4,24(a5)
ffffffffc0200ca6:	bfc1                	j	ffffffffc0200c76 <interrupt_handler+0x70>

ffffffffc0200ca8 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ca8:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cac:	1101                	addi	sp,sp,-32
ffffffffc0200cae:	e822                	sd	s0,16(sp)
ffffffffc0200cb0:	ec06                	sd	ra,24(sp)
ffffffffc0200cb2:	e426                	sd	s1,8(sp)
ffffffffc0200cb4:	473d                	li	a4,15
ffffffffc0200cb6:	842a                	mv	s0,a0
ffffffffc0200cb8:	14f76563          	bltu	a4,a5,ffffffffc0200e02 <exception_handler+0x15a>
ffffffffc0200cbc:	00005717          	auipc	a4,0x5
ffffffffc0200cc0:	73870713          	addi	a4,a4,1848 # ffffffffc02063f4 <commands+0x80c>
ffffffffc0200cc4:	078a                	slli	a5,a5,0x2
ffffffffc0200cc6:	97ba                	add	a5,a5,a4
ffffffffc0200cc8:	439c                	lw	a5,0(a5)
ffffffffc0200cca:	97ba                	add	a5,a5,a4
ffffffffc0200ccc:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cce:	00005517          	auipc	a0,0x5
ffffffffc0200cd2:	64a50513          	addi	a0,a0,1610 # ffffffffc0206318 <commands+0x730>
ffffffffc0200cd6:	cbeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cda:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cde:	60e2                	ld	ra,24(sp)
ffffffffc0200ce0:	64a2                	ld	s1,8(sp)
        tf->epc += 4;
ffffffffc0200ce2:	0791                	addi	a5,a5,4
ffffffffc0200ce4:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ce8:	6442                	ld	s0,16(sp)
ffffffffc0200cea:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200cec:	73e0406f          	j	ffffffffc020542a <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	64850513          	addi	a0,a0,1608 # ffffffffc0206338 <commands+0x750>
}
ffffffffc0200cf8:	6442                	ld	s0,16(sp)
ffffffffc0200cfa:	60e2                	ld	ra,24(sp)
ffffffffc0200cfc:	64a2                	ld	s1,8(sp)
ffffffffc0200cfe:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200d00:	c94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	65450513          	addi	a0,a0,1620 # ffffffffc0206358 <commands+0x770>
ffffffffc0200d0c:	b7f5                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Instruction page fault\n");
ffffffffc0200d0e:	00005517          	auipc	a0,0x5
ffffffffc0200d12:	66a50513          	addi	a0,a0,1642 # ffffffffc0206378 <commands+0x790>
ffffffffc0200d16:	b7cd                	j	ffffffffc0200cf8 <exception_handler+0x50>
        if (current->mm != NULL)
ffffffffc0200d18:	000b6497          	auipc	s1,0xb6
ffffffffc0200d1c:	a4848493          	addi	s1,s1,-1464 # ffffffffc02b6760 <current>
ffffffffc0200d20:	609c                	ld	a5,0(s1)
            ret = do_pgfault(current->mm, 0, tf->tval);
ffffffffc0200d22:	11053603          	ld	a2,272(a0)
        if (current->mm != NULL)
ffffffffc0200d26:	7788                	ld	a0,40(a5)
ffffffffc0200d28:	c519                	beqz	a0,ffffffffc0200d36 <exception_handler+0x8e>
            ret = do_pgfault(current->mm, 0, tf->tval);
ffffffffc0200d2a:	4581                	li	a1,0
ffffffffc0200d2c:	16a030ef          	jal	ra,ffffffffc0203e96 <do_pgfault>
            if (ret == 0)
ffffffffc0200d30:	c54d                	beqz	a0,ffffffffc0200dda <exception_handler+0x132>
        cprintf("Load page fault at 0x%x\n", tf->tval);
ffffffffc0200d32:	11043603          	ld	a2,272(s0)
ffffffffc0200d36:	85b2                	mv	a1,a2
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	65850513          	addi	a0,a0,1624 # ffffffffc0206390 <commands+0x7a8>
ffffffffc0200d40:	c54ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current->mm == NULL)
ffffffffc0200d44:	609c                	ld	a5,0(s1)
ffffffffc0200d46:	779c                	ld	a5,40(a5)
ffffffffc0200d48:	eba9                	bnez	a5,ffffffffc0200d9a <exception_handler+0xf2>
            print_trapframe(tf);
ffffffffc0200d4a:	8522                	mv	a0,s0
ffffffffc0200d4c:	e59ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("无法处理内核态的页面错误");
ffffffffc0200d50:	00005617          	auipc	a2,0x5
ffffffffc0200d54:	66060613          	addi	a2,a2,1632 # ffffffffc02063b0 <commands+0x7c8>
ffffffffc0200d58:	0e700593          	li	a1,231
ffffffffc0200d5c:	00005517          	auipc	a0,0x5
ffffffffc0200d60:	58c50513          	addi	a0,a0,1420 # ffffffffc02062e8 <commands+0x700>
ffffffffc0200d64:	f2aff0ef          	jal	ra,ffffffffc020048e <__panic>
        if (current->mm != NULL)
ffffffffc0200d68:	000b6497          	auipc	s1,0xb6
ffffffffc0200d6c:	9f848493          	addi	s1,s1,-1544 # ffffffffc02b6760 <current>
ffffffffc0200d70:	609c                	ld	a5,0(s1)
            ret = do_pgfault(current->mm, 0, tf->tval);
ffffffffc0200d72:	11053603          	ld	a2,272(a0)
        if (current->mm != NULL)
ffffffffc0200d76:	7788                	ld	a0,40(a5)
ffffffffc0200d78:	c519                	beqz	a0,ffffffffc0200d86 <exception_handler+0xde>
            ret = do_pgfault(current->mm, 1, tf->tval);
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	11a030ef          	jal	ra,ffffffffc0203e96 <do_pgfault>
            if (ret == 0)
ffffffffc0200d80:	cd29                	beqz	a0,ffffffffc0200dda <exception_handler+0x132>
        cprintf("Store page fault at 0x%x\n", tf->tval);
ffffffffc0200d82:	11043603          	ld	a2,272(s0)
ffffffffc0200d86:	85b2                	mv	a1,a2
ffffffffc0200d88:	00005517          	auipc	a0,0x5
ffffffffc0200d8c:	65050513          	addi	a0,a0,1616 # ffffffffc02063d8 <commands+0x7f0>
ffffffffc0200d90:	c04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current->mm == NULL)
ffffffffc0200d94:	609c                	ld	a5,0(s1)
ffffffffc0200d96:	779c                	ld	a5,40(a5)
ffffffffc0200d98:	cbdd                	beqz	a5,ffffffffc0200e4e <exception_handler+0x1a6>
}
ffffffffc0200d9a:	6442                	ld	s0,16(sp)
ffffffffc0200d9c:	60e2                	ld	ra,24(sp)
ffffffffc0200d9e:	64a2                	ld	s1,8(sp)
        do_exit(-E_KILLED);
ffffffffc0200da0:	555d                	li	a0,-9
}
ffffffffc0200da2:	6105                	addi	sp,sp,32
        do_exit(-E_KILLED);
ffffffffc0200da4:	0e10306f          	j	ffffffffc0204684 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200da8:	00005517          	auipc	a0,0x5
ffffffffc0200dac:	48850513          	addi	a0,a0,1160 # ffffffffc0206230 <commands+0x648>
ffffffffc0200db0:	b7a1                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Instruction access fault\n");
ffffffffc0200db2:	00005517          	auipc	a0,0x5
ffffffffc0200db6:	49e50513          	addi	a0,a0,1182 # ffffffffc0206250 <commands+0x668>
ffffffffc0200dba:	bf3d                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Illegal instruction\n");
ffffffffc0200dbc:	00005517          	auipc	a0,0x5
ffffffffc0200dc0:	4b450513          	addi	a0,a0,1204 # ffffffffc0206270 <commands+0x688>
ffffffffc0200dc4:	bf15                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Breakpoint\n");
ffffffffc0200dc6:	00005517          	auipc	a0,0x5
ffffffffc0200dca:	4c250513          	addi	a0,a0,1218 # ffffffffc0206288 <commands+0x6a0>
ffffffffc0200dce:	bc6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200dd2:	6458                	ld	a4,136(s0)
ffffffffc0200dd4:	47a9                	li	a5,10
ffffffffc0200dd6:	04f70863          	beq	a4,a5,ffffffffc0200e26 <exception_handler+0x17e>
}
ffffffffc0200dda:	60e2                	ld	ra,24(sp)
ffffffffc0200ddc:	6442                	ld	s0,16(sp)
ffffffffc0200dde:	64a2                	ld	s1,8(sp)
ffffffffc0200de0:	6105                	addi	sp,sp,32
ffffffffc0200de2:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200de4:	00005517          	auipc	a0,0x5
ffffffffc0200de8:	4b450513          	addi	a0,a0,1204 # ffffffffc0206298 <commands+0x6b0>
ffffffffc0200dec:	b731                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Load access fault\n");
ffffffffc0200dee:	00005517          	auipc	a0,0x5
ffffffffc0200df2:	4ca50513          	addi	a0,a0,1226 # ffffffffc02062b8 <commands+0x6d0>
ffffffffc0200df6:	b709                	j	ffffffffc0200cf8 <exception_handler+0x50>
        cprintf("Store/AMO access fault\n");
ffffffffc0200df8:	00005517          	auipc	a0,0x5
ffffffffc0200dfc:	50850513          	addi	a0,a0,1288 # ffffffffc0206300 <commands+0x718>
ffffffffc0200e00:	bde5                	j	ffffffffc0200cf8 <exception_handler+0x50>
        print_trapframe(tf);
ffffffffc0200e02:	8522                	mv	a0,s0
}
ffffffffc0200e04:	6442                	ld	s0,16(sp)
ffffffffc0200e06:	60e2                	ld	ra,24(sp)
ffffffffc0200e08:	64a2                	ld	s1,8(sp)
ffffffffc0200e0a:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200e0c:	bb61                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e0e:	00005617          	auipc	a2,0x5
ffffffffc0200e12:	4c260613          	addi	a2,a2,1218 # ffffffffc02062d0 <commands+0x6e8>
ffffffffc0200e16:	0c000593          	li	a1,192
ffffffffc0200e1a:	00005517          	auipc	a0,0x5
ffffffffc0200e1e:	4ce50513          	addi	a0,a0,1230 # ffffffffc02062e8 <commands+0x700>
ffffffffc0200e22:	e6cff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200e26:	10843783          	ld	a5,264(s0)
ffffffffc0200e2a:	0791                	addi	a5,a5,4
ffffffffc0200e2c:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200e30:	5fa040ef          	jal	ra,ffffffffc020542a <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e34:	000b6797          	auipc	a5,0xb6
ffffffffc0200e38:	92c7b783          	ld	a5,-1748(a5) # ffffffffc02b6760 <current>
ffffffffc0200e3c:	6b9c                	ld	a5,16(a5)
ffffffffc0200e3e:	8522                	mv	a0,s0
}
ffffffffc0200e40:	6442                	ld	s0,16(sp)
ffffffffc0200e42:	60e2                	ld	ra,24(sp)
ffffffffc0200e44:	64a2                	ld	s1,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e46:	6589                	lui	a1,0x2
ffffffffc0200e48:	95be                	add	a1,a1,a5
}
ffffffffc0200e4a:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e4c:	aaad                	j	ffffffffc0200fc6 <kernel_execve_ret>
            print_trapframe(tf);
ffffffffc0200e4e:	8522                	mv	a0,s0
ffffffffc0200e50:	d55ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("无法处理内核态的页面错误");
ffffffffc0200e54:	00005617          	auipc	a2,0x5
ffffffffc0200e58:	55c60613          	addi	a2,a2,1372 # ffffffffc02063b0 <commands+0x7c8>
ffffffffc0200e5c:	0fa00593          	li	a1,250
ffffffffc0200e60:	00005517          	auipc	a0,0x5
ffffffffc0200e64:	48850513          	addi	a0,a0,1160 # ffffffffc02062e8 <commands+0x700>
ffffffffc0200e68:	e26ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e6c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e6c:	1101                	addi	sp,sp,-32
ffffffffc0200e6e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e70:	000b6417          	auipc	s0,0xb6
ffffffffc0200e74:	8f040413          	addi	s0,s0,-1808 # ffffffffc02b6760 <current>
ffffffffc0200e78:	6018                	ld	a4,0(s0)
{
ffffffffc0200e7a:	ec06                	sd	ra,24(sp)
ffffffffc0200e7c:	e426                	sd	s1,8(sp)
ffffffffc0200e7e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e80:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e84:	cf1d                	beqz	a4,ffffffffc0200ec2 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e86:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e8a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e8e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e90:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e94:	0206c463          	bltz	a3,ffffffffc0200ebc <trap+0x50>
        exception_handler(tf);
ffffffffc0200e98:	e11ff0ef          	jal	ra,ffffffffc0200ca8 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e9c:	601c                	ld	a5,0(s0)
ffffffffc0200e9e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200ea2:	e499                	bnez	s1,ffffffffc0200eb0 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200ea4:	0b07a703          	lw	a4,176(a5)
ffffffffc0200ea8:	8b05                	andi	a4,a4,1
ffffffffc0200eaa:	e329                	bnez	a4,ffffffffc0200eec <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200eac:	6f9c                	ld	a5,24(a5)
ffffffffc0200eae:	eb85                	bnez	a5,ffffffffc0200ede <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200eb0:	60e2                	ld	ra,24(sp)
ffffffffc0200eb2:	6442                	ld	s0,16(sp)
ffffffffc0200eb4:	64a2                	ld	s1,8(sp)
ffffffffc0200eb6:	6902                	ld	s2,0(sp)
ffffffffc0200eb8:	6105                	addi	sp,sp,32
ffffffffc0200eba:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ebc:	d4bff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200ec0:	bff1                	j	ffffffffc0200e9c <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ec2:	0006c863          	bltz	a3,ffffffffc0200ed2 <trap+0x66>
}
ffffffffc0200ec6:	6442                	ld	s0,16(sp)
ffffffffc0200ec8:	60e2                	ld	ra,24(sp)
ffffffffc0200eca:	64a2                	ld	s1,8(sp)
ffffffffc0200ecc:	6902                	ld	s2,0(sp)
ffffffffc0200ece:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200ed0:	bbe1                	j	ffffffffc0200ca8 <exception_handler>
}
ffffffffc0200ed2:	6442                	ld	s0,16(sp)
ffffffffc0200ed4:	60e2                	ld	ra,24(sp)
ffffffffc0200ed6:	64a2                	ld	s1,8(sp)
ffffffffc0200ed8:	6902                	ld	s2,0(sp)
ffffffffc0200eda:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200edc:	b32d                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200ede:	6442                	ld	s0,16(sp)
ffffffffc0200ee0:	60e2                	ld	ra,24(sp)
ffffffffc0200ee2:	64a2                	ld	s1,8(sp)
ffffffffc0200ee4:	6902                	ld	s2,0(sp)
ffffffffc0200ee6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200ee8:	4560406f          	j	ffffffffc020533e <schedule>
                do_exit(-E_KILLED);
ffffffffc0200eec:	555d                	li	a0,-9
ffffffffc0200eee:	796030ef          	jal	ra,ffffffffc0204684 <do_exit>
            if (current->need_resched)
ffffffffc0200ef2:	601c                	ld	a5,0(s0)
ffffffffc0200ef4:	bf65                	j	ffffffffc0200eac <trap+0x40>
	...

ffffffffc0200ef8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ef8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200efc:	00011463          	bnez	sp,ffffffffc0200f04 <__alltraps+0xc>
ffffffffc0200f00:	14002173          	csrr	sp,sscratch
ffffffffc0200f04:	712d                	addi	sp,sp,-288
ffffffffc0200f06:	e002                	sd	zero,0(sp)
ffffffffc0200f08:	e406                	sd	ra,8(sp)
ffffffffc0200f0a:	ec0e                	sd	gp,24(sp)
ffffffffc0200f0c:	f012                	sd	tp,32(sp)
ffffffffc0200f0e:	f416                	sd	t0,40(sp)
ffffffffc0200f10:	f81a                	sd	t1,48(sp)
ffffffffc0200f12:	fc1e                	sd	t2,56(sp)
ffffffffc0200f14:	e0a2                	sd	s0,64(sp)
ffffffffc0200f16:	e4a6                	sd	s1,72(sp)
ffffffffc0200f18:	e8aa                	sd	a0,80(sp)
ffffffffc0200f1a:	ecae                	sd	a1,88(sp)
ffffffffc0200f1c:	f0b2                	sd	a2,96(sp)
ffffffffc0200f1e:	f4b6                	sd	a3,104(sp)
ffffffffc0200f20:	f8ba                	sd	a4,112(sp)
ffffffffc0200f22:	fcbe                	sd	a5,120(sp)
ffffffffc0200f24:	e142                	sd	a6,128(sp)
ffffffffc0200f26:	e546                	sd	a7,136(sp)
ffffffffc0200f28:	e94a                	sd	s2,144(sp)
ffffffffc0200f2a:	ed4e                	sd	s3,152(sp)
ffffffffc0200f2c:	f152                	sd	s4,160(sp)
ffffffffc0200f2e:	f556                	sd	s5,168(sp)
ffffffffc0200f30:	f95a                	sd	s6,176(sp)
ffffffffc0200f32:	fd5e                	sd	s7,184(sp)
ffffffffc0200f34:	e1e2                	sd	s8,192(sp)
ffffffffc0200f36:	e5e6                	sd	s9,200(sp)
ffffffffc0200f38:	e9ea                	sd	s10,208(sp)
ffffffffc0200f3a:	edee                	sd	s11,216(sp)
ffffffffc0200f3c:	f1f2                	sd	t3,224(sp)
ffffffffc0200f3e:	f5f6                	sd	t4,232(sp)
ffffffffc0200f40:	f9fa                	sd	t5,240(sp)
ffffffffc0200f42:	fdfe                	sd	t6,248(sp)
ffffffffc0200f44:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f48:	100024f3          	csrr	s1,sstatus
ffffffffc0200f4c:	14102973          	csrr	s2,sepc
ffffffffc0200f50:	143029f3          	csrr	s3,stval
ffffffffc0200f54:	14202a73          	csrr	s4,scause
ffffffffc0200f58:	e822                	sd	s0,16(sp)
ffffffffc0200f5a:	e226                	sd	s1,256(sp)
ffffffffc0200f5c:	e64a                	sd	s2,264(sp)
ffffffffc0200f5e:	ea4e                	sd	s3,272(sp)
ffffffffc0200f60:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f62:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f64:	f09ff0ef          	jal	ra,ffffffffc0200e6c <trap>

ffffffffc0200f68 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f68:	6492                	ld	s1,256(sp)
ffffffffc0200f6a:	6932                	ld	s2,264(sp)
ffffffffc0200f6c:	1004f413          	andi	s0,s1,256
ffffffffc0200f70:	e401                	bnez	s0,ffffffffc0200f78 <__trapret+0x10>
ffffffffc0200f72:	1200                	addi	s0,sp,288
ffffffffc0200f74:	14041073          	csrw	sscratch,s0
ffffffffc0200f78:	10049073          	csrw	sstatus,s1
ffffffffc0200f7c:	14191073          	csrw	sepc,s2
ffffffffc0200f80:	60a2                	ld	ra,8(sp)
ffffffffc0200f82:	61e2                	ld	gp,24(sp)
ffffffffc0200f84:	7202                	ld	tp,32(sp)
ffffffffc0200f86:	72a2                	ld	t0,40(sp)
ffffffffc0200f88:	7342                	ld	t1,48(sp)
ffffffffc0200f8a:	73e2                	ld	t2,56(sp)
ffffffffc0200f8c:	6406                	ld	s0,64(sp)
ffffffffc0200f8e:	64a6                	ld	s1,72(sp)
ffffffffc0200f90:	6546                	ld	a0,80(sp)
ffffffffc0200f92:	65e6                	ld	a1,88(sp)
ffffffffc0200f94:	7606                	ld	a2,96(sp)
ffffffffc0200f96:	76a6                	ld	a3,104(sp)
ffffffffc0200f98:	7746                	ld	a4,112(sp)
ffffffffc0200f9a:	77e6                	ld	a5,120(sp)
ffffffffc0200f9c:	680a                	ld	a6,128(sp)
ffffffffc0200f9e:	68aa                	ld	a7,136(sp)
ffffffffc0200fa0:	694a                	ld	s2,144(sp)
ffffffffc0200fa2:	69ea                	ld	s3,152(sp)
ffffffffc0200fa4:	7a0a                	ld	s4,160(sp)
ffffffffc0200fa6:	7aaa                	ld	s5,168(sp)
ffffffffc0200fa8:	7b4a                	ld	s6,176(sp)
ffffffffc0200faa:	7bea                	ld	s7,184(sp)
ffffffffc0200fac:	6c0e                	ld	s8,192(sp)
ffffffffc0200fae:	6cae                	ld	s9,200(sp)
ffffffffc0200fb0:	6d4e                	ld	s10,208(sp)
ffffffffc0200fb2:	6dee                	ld	s11,216(sp)
ffffffffc0200fb4:	7e0e                	ld	t3,224(sp)
ffffffffc0200fb6:	7eae                	ld	t4,232(sp)
ffffffffc0200fb8:	7f4e                	ld	t5,240(sp)
ffffffffc0200fba:	7fee                	ld	t6,248(sp)
ffffffffc0200fbc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fbe:	10200073          	sret

ffffffffc0200fc2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fc2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200fc4:	b755                	j	ffffffffc0200f68 <__trapret>

ffffffffc0200fc6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200fc6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200fca:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200fce:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200fd2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200fd6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200fda:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200fde:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200fe2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200fe6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200fea:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200fec:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200fee:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ff0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200ff2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ff4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200ff6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200ff8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200ffa:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ffc:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200ffe:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201000:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201002:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201004:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201006:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201008:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020100a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc020100c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020100e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201010:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201012:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201014:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201016:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201018:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020101a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020101c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020101e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201020:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201022:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201024:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201026:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201028:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020102a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020102c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020102e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201030:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201032:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201034:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201036:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201038:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020103a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020103c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020103e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201040:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201042:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201044:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201046:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201048:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020104a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020104c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020104e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201050:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201052:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201054:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201056:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201058:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020105a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020105c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020105e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201060:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201062:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201064:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201066:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201068:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020106a:	812e                	mv	sp,a1
ffffffffc020106c:	bdf5                	j	ffffffffc0200f68 <__trapret>

ffffffffc020106e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020106e:	000b1797          	auipc	a5,0xb1
ffffffffc0201072:	66a78793          	addi	a5,a5,1642 # ffffffffc02b26d8 <free_area>
ffffffffc0201076:	e79c                	sd	a5,8(a5)
ffffffffc0201078:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020107a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020107e:	8082                	ret

ffffffffc0201080 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201080:	000b1517          	auipc	a0,0xb1
ffffffffc0201084:	66856503          	lwu	a0,1640(a0) # ffffffffc02b26e8 <free_area+0x10>
ffffffffc0201088:	8082                	ret

ffffffffc020108a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020108a:	715d                	addi	sp,sp,-80
ffffffffc020108c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020108e:	000b1417          	auipc	s0,0xb1
ffffffffc0201092:	64a40413          	addi	s0,s0,1610 # ffffffffc02b26d8 <free_area>
ffffffffc0201096:	641c                	ld	a5,8(s0)
ffffffffc0201098:	e486                	sd	ra,72(sp)
ffffffffc020109a:	fc26                	sd	s1,56(sp)
ffffffffc020109c:	f84a                	sd	s2,48(sp)
ffffffffc020109e:	f44e                	sd	s3,40(sp)
ffffffffc02010a0:	f052                	sd	s4,32(sp)
ffffffffc02010a2:	ec56                	sd	s5,24(sp)
ffffffffc02010a4:	e85a                	sd	s6,16(sp)
ffffffffc02010a6:	e45e                	sd	s7,8(sp)
ffffffffc02010a8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02010aa:	2a878d63          	beq	a5,s0,ffffffffc0201364 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02010ae:	4481                	li	s1,0
ffffffffc02010b0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010b2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02010b6:	8b09                	andi	a4,a4,2
ffffffffc02010b8:	2a070a63          	beqz	a4,ffffffffc020136c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02010bc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010c0:	679c                	ld	a5,8(a5)
ffffffffc02010c2:	2905                	addiw	s2,s2,1
ffffffffc02010c4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010c6:	fe8796e3          	bne	a5,s0,ffffffffc02010b2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010ca:	89a6                	mv	s3,s1
ffffffffc02010cc:	6df000ef          	jal	ra,ffffffffc0201faa <nr_free_pages>
ffffffffc02010d0:	6f351e63          	bne	a0,s3,ffffffffc02017cc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d4:	4505                	li	a0,1
ffffffffc02010d6:	657000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02010da:	8aaa                	mv	s5,a0
ffffffffc02010dc:	42050863          	beqz	a0,ffffffffc020150c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010e0:	4505                	li	a0,1
ffffffffc02010e2:	64b000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02010e6:	89aa                	mv	s3,a0
ffffffffc02010e8:	70050263          	beqz	a0,ffffffffc02017ec <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010ec:	4505                	li	a0,1
ffffffffc02010ee:	63f000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02010f2:	8a2a                	mv	s4,a0
ffffffffc02010f4:	48050c63          	beqz	a0,ffffffffc020158c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010f8:	293a8a63          	beq	s5,s3,ffffffffc020138c <default_check+0x302>
ffffffffc02010fc:	28aa8863          	beq	s5,a0,ffffffffc020138c <default_check+0x302>
ffffffffc0201100:	28a98663          	beq	s3,a0,ffffffffc020138c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201104:	000aa783          	lw	a5,0(s5)
ffffffffc0201108:	2a079263          	bnez	a5,ffffffffc02013ac <default_check+0x322>
ffffffffc020110c:	0009a783          	lw	a5,0(s3)
ffffffffc0201110:	28079e63          	bnez	a5,ffffffffc02013ac <default_check+0x322>
ffffffffc0201114:	411c                	lw	a5,0(a0)
ffffffffc0201116:	28079b63          	bnez	a5,ffffffffc02013ac <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020111a:	000b5797          	auipc	a5,0xb5
ffffffffc020111e:	62e7b783          	ld	a5,1582(a5) # ffffffffc02b6748 <pages>
ffffffffc0201122:	40fa8733          	sub	a4,s5,a5
ffffffffc0201126:	00007617          	auipc	a2,0x7
ffffffffc020112a:	ada63603          	ld	a2,-1318(a2) # ffffffffc0207c00 <nbase>
ffffffffc020112e:	8719                	srai	a4,a4,0x6
ffffffffc0201130:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201132:	000b5697          	auipc	a3,0xb5
ffffffffc0201136:	60e6b683          	ld	a3,1550(a3) # ffffffffc02b6740 <npage>
ffffffffc020113a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020113c:	0732                	slli	a4,a4,0xc
ffffffffc020113e:	28d77763          	bgeu	a4,a3,ffffffffc02013cc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201142:	40f98733          	sub	a4,s3,a5
ffffffffc0201146:	8719                	srai	a4,a4,0x6
ffffffffc0201148:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020114a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020114c:	4cd77063          	bgeu	a4,a3,ffffffffc020160c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201150:	40f507b3          	sub	a5,a0,a5
ffffffffc0201154:	8799                	srai	a5,a5,0x6
ffffffffc0201156:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201158:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020115a:	30d7f963          	bgeu	a5,a3,ffffffffc020146c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020115e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201160:	00043c03          	ld	s8,0(s0)
ffffffffc0201164:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201168:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020116c:	e400                	sd	s0,8(s0)
ffffffffc020116e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201170:	000b1797          	auipc	a5,0xb1
ffffffffc0201174:	5607ac23          	sw	zero,1400(a5) # ffffffffc02b26e8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201178:	5b5000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc020117c:	2c051863          	bnez	a0,ffffffffc020144c <default_check+0x3c2>
    free_page(p0);
ffffffffc0201180:	4585                	li	a1,1
ffffffffc0201182:	8556                	mv	a0,s5
ffffffffc0201184:	5e7000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_page(p1);
ffffffffc0201188:	4585                	li	a1,1
ffffffffc020118a:	854e                	mv	a0,s3
ffffffffc020118c:	5df000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_page(p2);
ffffffffc0201190:	4585                	li	a1,1
ffffffffc0201192:	8552                	mv	a0,s4
ffffffffc0201194:	5d7000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    assert(nr_free == 3);
ffffffffc0201198:	4818                	lw	a4,16(s0)
ffffffffc020119a:	478d                	li	a5,3
ffffffffc020119c:	28f71863          	bne	a4,a5,ffffffffc020142c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011a0:	4505                	li	a0,1
ffffffffc02011a2:	58b000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011a6:	89aa                	mv	s3,a0
ffffffffc02011a8:	26050263          	beqz	a0,ffffffffc020140c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011ac:	4505                	li	a0,1
ffffffffc02011ae:	57f000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011b2:	8aaa                	mv	s5,a0
ffffffffc02011b4:	3a050c63          	beqz	a0,ffffffffc020156c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011b8:	4505                	li	a0,1
ffffffffc02011ba:	573000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011be:	8a2a                	mv	s4,a0
ffffffffc02011c0:	38050663          	beqz	a0,ffffffffc020154c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02011c4:	4505                	li	a0,1
ffffffffc02011c6:	567000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011ca:	36051163          	bnez	a0,ffffffffc020152c <default_check+0x4a2>
    free_page(p0);
ffffffffc02011ce:	4585                	li	a1,1
ffffffffc02011d0:	854e                	mv	a0,s3
ffffffffc02011d2:	599000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011d6:	641c                	ld	a5,8(s0)
ffffffffc02011d8:	20878a63          	beq	a5,s0,ffffffffc02013ec <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02011dc:	4505                	li	a0,1
ffffffffc02011de:	54f000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011e2:	30a99563          	bne	s3,a0,ffffffffc02014ec <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02011e6:	4505                	li	a0,1
ffffffffc02011e8:	545000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02011ec:	2e051063          	bnez	a0,ffffffffc02014cc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02011f0:	481c                	lw	a5,16(s0)
ffffffffc02011f2:	2a079d63          	bnez	a5,ffffffffc02014ac <default_check+0x422>
    free_page(p);
ffffffffc02011f6:	854e                	mv	a0,s3
ffffffffc02011f8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011fa:	01843023          	sd	s8,0(s0)
ffffffffc02011fe:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201202:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201206:	565000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_page(p1);
ffffffffc020120a:	4585                	li	a1,1
ffffffffc020120c:	8556                	mv	a0,s5
ffffffffc020120e:	55d000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_page(p2);
ffffffffc0201212:	4585                	li	a1,1
ffffffffc0201214:	8552                	mv	a0,s4
ffffffffc0201216:	555000ef          	jal	ra,ffffffffc0201f6a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020121a:	4515                	li	a0,5
ffffffffc020121c:	511000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201220:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201222:	26050563          	beqz	a0,ffffffffc020148c <default_check+0x402>
ffffffffc0201226:	651c                	ld	a5,8(a0)
ffffffffc0201228:	8385                	srli	a5,a5,0x1
ffffffffc020122a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020122c:	54079063          	bnez	a5,ffffffffc020176c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201230:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201232:	00043b03          	ld	s6,0(s0)
ffffffffc0201236:	00843a83          	ld	s5,8(s0)
ffffffffc020123a:	e000                	sd	s0,0(s0)
ffffffffc020123c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020123e:	4ef000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201242:	50051563          	bnez	a0,ffffffffc020174c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201246:	08098a13          	addi	s4,s3,128
ffffffffc020124a:	8552                	mv	a0,s4
ffffffffc020124c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020124e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201252:	000b1797          	auipc	a5,0xb1
ffffffffc0201256:	4807ab23          	sw	zero,1174(a5) # ffffffffc02b26e8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020125a:	511000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020125e:	4511                	li	a0,4
ffffffffc0201260:	4cd000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201264:	4c051463          	bnez	a0,ffffffffc020172c <default_check+0x6a2>
ffffffffc0201268:	0889b783          	ld	a5,136(s3)
ffffffffc020126c:	8385                	srli	a5,a5,0x1
ffffffffc020126e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201270:	48078e63          	beqz	a5,ffffffffc020170c <default_check+0x682>
ffffffffc0201274:	0909a703          	lw	a4,144(s3)
ffffffffc0201278:	478d                	li	a5,3
ffffffffc020127a:	48f71963          	bne	a4,a5,ffffffffc020170c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020127e:	450d                	li	a0,3
ffffffffc0201280:	4ad000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201284:	8c2a                	mv	s8,a0
ffffffffc0201286:	46050363          	beqz	a0,ffffffffc02016ec <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020128a:	4505                	li	a0,1
ffffffffc020128c:	4a1000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201290:	42051e63          	bnez	a0,ffffffffc02016cc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201294:	418a1c63          	bne	s4,s8,ffffffffc02016ac <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201298:	4585                	li	a1,1
ffffffffc020129a:	854e                	mv	a0,s3
ffffffffc020129c:	4cf000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_pages(p1, 3);
ffffffffc02012a0:	458d                	li	a1,3
ffffffffc02012a2:	8552                	mv	a0,s4
ffffffffc02012a4:	4c7000ef          	jal	ra,ffffffffc0201f6a <free_pages>
ffffffffc02012a8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02012ac:	04098c13          	addi	s8,s3,64
ffffffffc02012b0:	8385                	srli	a5,a5,0x1
ffffffffc02012b2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012b4:	3c078c63          	beqz	a5,ffffffffc020168c <default_check+0x602>
ffffffffc02012b8:	0109a703          	lw	a4,16(s3)
ffffffffc02012bc:	4785                	li	a5,1
ffffffffc02012be:	3cf71763          	bne	a4,a5,ffffffffc020168c <default_check+0x602>
ffffffffc02012c2:	008a3783          	ld	a5,8(s4)
ffffffffc02012c6:	8385                	srli	a5,a5,0x1
ffffffffc02012c8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012ca:	3a078163          	beqz	a5,ffffffffc020166c <default_check+0x5e2>
ffffffffc02012ce:	010a2703          	lw	a4,16(s4)
ffffffffc02012d2:	478d                	li	a5,3
ffffffffc02012d4:	38f71c63          	bne	a4,a5,ffffffffc020166c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012d8:	4505                	li	a0,1
ffffffffc02012da:	453000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02012de:	36a99763          	bne	s3,a0,ffffffffc020164c <default_check+0x5c2>
    free_page(p0);
ffffffffc02012e2:	4585                	li	a1,1
ffffffffc02012e4:	487000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012e8:	4509                	li	a0,2
ffffffffc02012ea:	443000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02012ee:	32aa1f63          	bne	s4,a0,ffffffffc020162c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02012f2:	4589                	li	a1,2
ffffffffc02012f4:	477000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    free_page(p2);
ffffffffc02012f8:	4585                	li	a1,1
ffffffffc02012fa:	8562                	mv	a0,s8
ffffffffc02012fc:	46f000ef          	jal	ra,ffffffffc0201f6a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201300:	4515                	li	a0,5
ffffffffc0201302:	42b000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201306:	89aa                	mv	s3,a0
ffffffffc0201308:	48050263          	beqz	a0,ffffffffc020178c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020130c:	4505                	li	a0,1
ffffffffc020130e:	41f000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0201312:	2c051d63          	bnez	a0,ffffffffc02015ec <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201316:	481c                	lw	a5,16(s0)
ffffffffc0201318:	2a079a63          	bnez	a5,ffffffffc02015cc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020131c:	4595                	li	a1,5
ffffffffc020131e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201320:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201324:	01643023          	sd	s6,0(s0)
ffffffffc0201328:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020132c:	43f000ef          	jal	ra,ffffffffc0201f6a <free_pages>
    return listelm->next;
ffffffffc0201330:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201332:	00878963          	beq	a5,s0,ffffffffc0201344 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201336:	ff87a703          	lw	a4,-8(a5)
ffffffffc020133a:	679c                	ld	a5,8(a5)
ffffffffc020133c:	397d                	addiw	s2,s2,-1
ffffffffc020133e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201340:	fe879be3          	bne	a5,s0,ffffffffc0201336 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201344:	26091463          	bnez	s2,ffffffffc02015ac <default_check+0x522>
    assert(total == 0);
ffffffffc0201348:	46049263          	bnez	s1,ffffffffc02017ac <default_check+0x722>
}
ffffffffc020134c:	60a6                	ld	ra,72(sp)
ffffffffc020134e:	6406                	ld	s0,64(sp)
ffffffffc0201350:	74e2                	ld	s1,56(sp)
ffffffffc0201352:	7942                	ld	s2,48(sp)
ffffffffc0201354:	79a2                	ld	s3,40(sp)
ffffffffc0201356:	7a02                	ld	s4,32(sp)
ffffffffc0201358:	6ae2                	ld	s5,24(sp)
ffffffffc020135a:	6b42                	ld	s6,16(sp)
ffffffffc020135c:	6ba2                	ld	s7,8(sp)
ffffffffc020135e:	6c02                	ld	s8,0(sp)
ffffffffc0201360:	6161                	addi	sp,sp,80
ffffffffc0201362:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201364:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201366:	4481                	li	s1,0
ffffffffc0201368:	4901                	li	s2,0
ffffffffc020136a:	b38d                	j	ffffffffc02010cc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	0cc68693          	addi	a3,a3,204 # ffffffffc0206438 <commands+0x850>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	0d460613          	addi	a2,a2,212 # ffffffffc0206448 <commands+0x860>
ffffffffc020137c:	11000593          	li	a1,272
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	0e050513          	addi	a0,a0,224 # ffffffffc0206460 <commands+0x878>
ffffffffc0201388:	906ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	16c68693          	addi	a3,a3,364 # ffffffffc02064f8 <commands+0x910>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	0b460613          	addi	a2,a2,180 # ffffffffc0206448 <commands+0x860>
ffffffffc020139c:	0db00593          	li	a1,219
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	0c050513          	addi	a0,a0,192 # ffffffffc0206460 <commands+0x878>
ffffffffc02013a8:	8e6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	17468693          	addi	a3,a3,372 # ffffffffc0206520 <commands+0x938>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	09460613          	addi	a2,a2,148 # ffffffffc0206448 <commands+0x860>
ffffffffc02013bc:	0dc00593          	li	a1,220
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	0a050513          	addi	a0,a0,160 # ffffffffc0206460 <commands+0x878>
ffffffffc02013c8:	8c6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	19468693          	addi	a3,a3,404 # ffffffffc0206560 <commands+0x978>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	07460613          	addi	a2,a2,116 # ffffffffc0206448 <commands+0x860>
ffffffffc02013dc:	0de00593          	li	a1,222
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	08050513          	addi	a0,a0,128 # ffffffffc0206460 <commands+0x878>
ffffffffc02013e8:	8a6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	1fc68693          	addi	a3,a3,508 # ffffffffc02065e8 <commands+0xa00>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	05460613          	addi	a2,a2,84 # ffffffffc0206448 <commands+0x860>
ffffffffc02013fc:	0f700593          	li	a1,247
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	06050513          	addi	a0,a0,96 # ffffffffc0206460 <commands+0x878>
ffffffffc0201408:	886ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	08c68693          	addi	a3,a3,140 # ffffffffc0206498 <commands+0x8b0>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	03460613          	addi	a2,a2,52 # ffffffffc0206448 <commands+0x860>
ffffffffc020141c:	0f000593          	li	a1,240
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	04050513          	addi	a0,a0,64 # ffffffffc0206460 <commands+0x878>
ffffffffc0201428:	866ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	1ac68693          	addi	a3,a3,428 # ffffffffc02065d8 <commands+0x9f0>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	01460613          	addi	a2,a2,20 # ffffffffc0206448 <commands+0x860>
ffffffffc020143c:	0ee00593          	li	a1,238
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	02050513          	addi	a0,a0,32 # ffffffffc0206460 <commands+0x878>
ffffffffc0201448:	846ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	17468693          	addi	a3,a3,372 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	ff460613          	addi	a2,a2,-12 # ffffffffc0206448 <commands+0x860>
ffffffffc020145c:	0e900593          	li	a1,233
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	00050513          	mv	a0,a0
ffffffffc0201468:	826ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	13468693          	addi	a3,a3,308 # ffffffffc02065a0 <commands+0x9b8>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	fd460613          	addi	a2,a2,-44 # ffffffffc0206448 <commands+0x860>
ffffffffc020147c:	0e000593          	li	a1,224
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	fe050513          	addi	a0,a0,-32 # ffffffffc0206460 <commands+0x878>
ffffffffc0201488:	806ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	1a468693          	addi	a3,a3,420 # ffffffffc0206630 <commands+0xa48>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	fb460613          	addi	a2,a2,-76 # ffffffffc0206448 <commands+0x860>
ffffffffc020149c:	11800593          	li	a1,280
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	fc050513          	addi	a0,a0,-64 # ffffffffc0206460 <commands+0x878>
ffffffffc02014a8:	fe7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	17468693          	addi	a3,a3,372 # ffffffffc0206620 <commands+0xa38>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	f9460613          	addi	a2,a2,-108 # ffffffffc0206448 <commands+0x860>
ffffffffc02014bc:	0fd00593          	li	a1,253
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	fa050513          	addi	a0,a0,-96 # ffffffffc0206460 <commands+0x878>
ffffffffc02014c8:	fc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	0f468693          	addi	a3,a3,244 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	f7460613          	addi	a2,a2,-140 # ffffffffc0206448 <commands+0x860>
ffffffffc02014dc:	0fb00593          	li	a1,251
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	f8050513          	addi	a0,a0,-128 # ffffffffc0206460 <commands+0x878>
ffffffffc02014e8:	fa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	11468693          	addi	a3,a3,276 # ffffffffc0206600 <commands+0xa18>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	f5460613          	addi	a2,a2,-172 # ffffffffc0206448 <commands+0x860>
ffffffffc02014fc:	0fa00593          	li	a1,250
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	f6050513          	addi	a0,a0,-160 # ffffffffc0206460 <commands+0x878>
ffffffffc0201508:	f87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	f8c68693          	addi	a3,a3,-116 # ffffffffc0206498 <commands+0x8b0>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	f3460613          	addi	a2,a2,-204 # ffffffffc0206448 <commands+0x860>
ffffffffc020151c:	0d700593          	li	a1,215
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	f4050513          	addi	a0,a0,-192 # ffffffffc0206460 <commands+0x878>
ffffffffc0201528:	f67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	09468693          	addi	a3,a3,148 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	f1460613          	addi	a2,a2,-236 # ffffffffc0206448 <commands+0x860>
ffffffffc020153c:	0f400593          	li	a1,244
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	f2050513          	addi	a0,a0,-224 # ffffffffc0206460 <commands+0x878>
ffffffffc0201548:	f47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	f8c68693          	addi	a3,a3,-116 # ffffffffc02064d8 <commands+0x8f0>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	ef460613          	addi	a2,a2,-268 # ffffffffc0206448 <commands+0x860>
ffffffffc020155c:	0f200593          	li	a1,242
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	f0050513          	addi	a0,a0,-256 # ffffffffc0206460 <commands+0x878>
ffffffffc0201568:	f27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	f4c68693          	addi	a3,a3,-180 # ffffffffc02064b8 <commands+0x8d0>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	ed460613          	addi	a2,a2,-300 # ffffffffc0206448 <commands+0x860>
ffffffffc020157c:	0f100593          	li	a1,241
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	ee050513          	addi	a0,a0,-288 # ffffffffc0206460 <commands+0x878>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	f4c68693          	addi	a3,a3,-180 # ffffffffc02064d8 <commands+0x8f0>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	eb460613          	addi	a2,a2,-332 # ffffffffc0206448 <commands+0x860>
ffffffffc020159c:	0d900593          	li	a1,217
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	ec050513          	addi	a0,a0,-320 # ffffffffc0206460 <commands+0x878>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	1d468693          	addi	a3,a3,468 # ffffffffc0206780 <commands+0xb98>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	e9460613          	addi	a2,a2,-364 # ffffffffc0206448 <commands+0x860>
ffffffffc02015bc:	14600593          	li	a1,326
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	ea050513          	addi	a0,a0,-352 # ffffffffc0206460 <commands+0x878>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	05468693          	addi	a3,a3,84 # ffffffffc0206620 <commands+0xa38>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	e7460613          	addi	a2,a2,-396 # ffffffffc0206448 <commands+0x860>
ffffffffc02015dc:	13a00593          	li	a1,314
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	e8050513          	addi	a0,a0,-384 # ffffffffc0206460 <commands+0x878>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	fd468693          	addi	a3,a3,-44 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	e5460613          	addi	a2,a2,-428 # ffffffffc0206448 <commands+0x860>
ffffffffc02015fc:	13800593          	li	a1,312
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	e6050513          	addi	a0,a0,-416 # ffffffffc0206460 <commands+0x878>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	f7468693          	addi	a3,a3,-140 # ffffffffc0206580 <commands+0x998>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	e3460613          	addi	a2,a2,-460 # ffffffffc0206448 <commands+0x860>
ffffffffc020161c:	0df00593          	li	a1,223
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	e4050513          	addi	a0,a0,-448 # ffffffffc0206460 <commands+0x878>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	11468693          	addi	a3,a3,276 # ffffffffc0206740 <commands+0xb58>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	e1460613          	addi	a2,a2,-492 # ffffffffc0206448 <commands+0x860>
ffffffffc020163c:	13200593          	li	a1,306
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	e2050513          	addi	a0,a0,-480 # ffffffffc0206460 <commands+0x878>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	0d468693          	addi	a3,a3,212 # ffffffffc0206720 <commands+0xb38>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	df460613          	addi	a2,a2,-524 # ffffffffc0206448 <commands+0x860>
ffffffffc020165c:	13000593          	li	a1,304
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	e0050513          	addi	a0,a0,-512 # ffffffffc0206460 <commands+0x878>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	08c68693          	addi	a3,a3,140 # ffffffffc02066f8 <commands+0xb10>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	dd460613          	addi	a2,a2,-556 # ffffffffc0206448 <commands+0x860>
ffffffffc020167c:	12e00593          	li	a1,302
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	de050513          	addi	a0,a0,-544 # ffffffffc0206460 <commands+0x878>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	04468693          	addi	a3,a3,68 # ffffffffc02066d0 <commands+0xae8>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	db460613          	addi	a2,a2,-588 # ffffffffc0206448 <commands+0x860>
ffffffffc020169c:	12d00593          	li	a1,301
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	dc050513          	addi	a0,a0,-576 # ffffffffc0206460 <commands+0x878>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	01468693          	addi	a3,a3,20 # ffffffffc02066c0 <commands+0xad8>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	d9460613          	addi	a2,a2,-620 # ffffffffc0206448 <commands+0x860>
ffffffffc02016bc:	12800593          	li	a1,296
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	da050513          	addi	a0,a0,-608 # ffffffffc0206460 <commands+0x878>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	ef468693          	addi	a3,a3,-268 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	d7460613          	addi	a2,a2,-652 # ffffffffc0206448 <commands+0x860>
ffffffffc02016dc:	12700593          	li	a1,295
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	d8050513          	addi	a0,a0,-640 # ffffffffc0206460 <commands+0x878>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	fb468693          	addi	a3,a3,-76 # ffffffffc02066a0 <commands+0xab8>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	d5460613          	addi	a2,a2,-684 # ffffffffc0206448 <commands+0x860>
ffffffffc02016fc:	12600593          	li	a1,294
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	d6050513          	addi	a0,a0,-672 # ffffffffc0206460 <commands+0x878>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	f6468693          	addi	a3,a3,-156 # ffffffffc0206670 <commands+0xa88>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	d3460613          	addi	a2,a2,-716 # ffffffffc0206448 <commands+0x860>
ffffffffc020171c:	12500593          	li	a1,293
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	d4050513          	addi	a0,a0,-704 # ffffffffc0206460 <commands+0x878>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	f2c68693          	addi	a3,a3,-212 # ffffffffc0206658 <commands+0xa70>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	d1460613          	addi	a2,a2,-748 # ffffffffc0206448 <commands+0x860>
ffffffffc020173c:	12400593          	li	a1,292
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	d2050513          	addi	a0,a0,-736 # ffffffffc0206460 <commands+0x878>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	e7468693          	addi	a3,a3,-396 # ffffffffc02065c0 <commands+0x9d8>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	cf460613          	addi	a2,a2,-780 # ffffffffc0206448 <commands+0x860>
ffffffffc020175c:	11e00593          	li	a1,286
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	d0050513          	addi	a0,a0,-768 # ffffffffc0206460 <commands+0x878>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	ed468693          	addi	a3,a3,-300 # ffffffffc0206640 <commands+0xa58>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	cd460613          	addi	a2,a2,-812 # ffffffffc0206448 <commands+0x860>
ffffffffc020177c:	11900593          	li	a1,281
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	ce050513          	addi	a0,a0,-800 # ffffffffc0206460 <commands+0x878>
ffffffffc0201788:	d07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	fd468693          	addi	a3,a3,-44 # ffffffffc0206760 <commands+0xb78>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	cb460613          	addi	a2,a2,-844 # ffffffffc0206448 <commands+0x860>
ffffffffc020179c:	13700593          	li	a1,311
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	cc050513          	addi	a0,a0,-832 # ffffffffc0206460 <commands+0x878>
ffffffffc02017a8:	ce7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	fe468693          	addi	a3,a3,-28 # ffffffffc0206790 <commands+0xba8>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	c9460613          	addi	a2,a2,-876 # ffffffffc0206448 <commands+0x860>
ffffffffc02017bc:	14700593          	li	a1,327
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	ca050513          	addi	a0,a0,-864 # ffffffffc0206460 <commands+0x878>
ffffffffc02017c8:	cc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02017cc:	00005697          	auipc	a3,0x5
ffffffffc02017d0:	cac68693          	addi	a3,a3,-852 # ffffffffc0206478 <commands+0x890>
ffffffffc02017d4:	00005617          	auipc	a2,0x5
ffffffffc02017d8:	c7460613          	addi	a2,a2,-908 # ffffffffc0206448 <commands+0x860>
ffffffffc02017dc:	11300593          	li	a1,275
ffffffffc02017e0:	00005517          	auipc	a0,0x5
ffffffffc02017e4:	c8050513          	addi	a0,a0,-896 # ffffffffc0206460 <commands+0x878>
ffffffffc02017e8:	ca7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02017ec:	00005697          	auipc	a3,0x5
ffffffffc02017f0:	ccc68693          	addi	a3,a3,-820 # ffffffffc02064b8 <commands+0x8d0>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	c5460613          	addi	a2,a2,-940 # ffffffffc0206448 <commands+0x860>
ffffffffc02017fc:	0d800593          	li	a1,216
ffffffffc0201800:	00005517          	auipc	a0,0x5
ffffffffc0201804:	c6050513          	addi	a0,a0,-928 # ffffffffc0206460 <commands+0x878>
ffffffffc0201808:	c87fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020180c <default_free_pages>:
{
ffffffffc020180c:	1141                	addi	sp,sp,-16
ffffffffc020180e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201810:	14058463          	beqz	a1,ffffffffc0201958 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201814:	00659693          	slli	a3,a1,0x6
ffffffffc0201818:	96aa                	add	a3,a3,a0
ffffffffc020181a:	87aa                	mv	a5,a0
ffffffffc020181c:	02d50263          	beq	a0,a3,ffffffffc0201840 <default_free_pages+0x34>
ffffffffc0201820:	6798                	ld	a4,8(a5)
ffffffffc0201822:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201824:	10071a63          	bnez	a4,ffffffffc0201938 <default_free_pages+0x12c>
ffffffffc0201828:	6798                	ld	a4,8(a5)
ffffffffc020182a:	8b09                	andi	a4,a4,2
ffffffffc020182c:	10071663          	bnez	a4,ffffffffc0201938 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201830:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201834:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201838:	04078793          	addi	a5,a5,64
ffffffffc020183c:	fed792e3          	bne	a5,a3,ffffffffc0201820 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201840:	2581                	sext.w	a1,a1
ffffffffc0201842:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201844:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201848:	4789                	li	a5,2
ffffffffc020184a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020184e:	000b1697          	auipc	a3,0xb1
ffffffffc0201852:	e8a68693          	addi	a3,a3,-374 # ffffffffc02b26d8 <free_area>
ffffffffc0201856:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201858:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020185a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020185e:	9db9                	addw	a1,a1,a4
ffffffffc0201860:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201862:	0ad78463          	beq	a5,a3,ffffffffc020190a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201866:	fe878713          	addi	a4,a5,-24
ffffffffc020186a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020186e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201870:	00e56a63          	bltu	a0,a4,ffffffffc0201884 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201874:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201876:	04d70c63          	beq	a4,a3,ffffffffc02018ce <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020187a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020187c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201880:	fee57ae3          	bgeu	a0,a4,ffffffffc0201874 <default_free_pages+0x68>
ffffffffc0201884:	c199                	beqz	a1,ffffffffc020188a <default_free_pages+0x7e>
ffffffffc0201886:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020188a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020188c:	e390                	sd	a2,0(a5)
ffffffffc020188e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201890:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201892:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201894:	00d70d63          	beq	a4,a3,ffffffffc02018ae <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201898:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020189c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02018a0:	02059813          	slli	a6,a1,0x20
ffffffffc02018a4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02018a8:	97b2                	add	a5,a5,a2
ffffffffc02018aa:	02f50c63          	beq	a0,a5,ffffffffc02018e2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02018ae:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02018b0:	00d78c63          	beq	a5,a3,ffffffffc02018c8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02018b4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02018b6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02018ba:	02061593          	slli	a1,a2,0x20
ffffffffc02018be:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02018c2:	972a                	add	a4,a4,a0
ffffffffc02018c4:	04e68a63          	beq	a3,a4,ffffffffc0201918 <default_free_pages+0x10c>
}
ffffffffc02018c8:	60a2                	ld	ra,8(sp)
ffffffffc02018ca:	0141                	addi	sp,sp,16
ffffffffc02018cc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018d0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018d2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018d4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018d6:	02d70763          	beq	a4,a3,ffffffffc0201904 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02018da:	8832                	mv	a6,a2
ffffffffc02018dc:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018de:	87ba                	mv	a5,a4
ffffffffc02018e0:	bf71                	j	ffffffffc020187c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02018e2:	491c                	lw	a5,16(a0)
ffffffffc02018e4:	9dbd                	addw	a1,a1,a5
ffffffffc02018e6:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018ea:	57f5                	li	a5,-3
ffffffffc02018ec:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018f0:	01853803          	ld	a6,24(a0)
ffffffffc02018f4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02018f6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02018f8:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02018fc:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018fe:	0105b023          	sd	a6,0(a1)
ffffffffc0201902:	b77d                	j	ffffffffc02018b0 <default_free_pages+0xa4>
ffffffffc0201904:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201906:	873e                	mv	a4,a5
ffffffffc0201908:	bf41                	j	ffffffffc0201898 <default_free_pages+0x8c>
}
ffffffffc020190a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020190c:	e390                	sd	a2,0(a5)
ffffffffc020190e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201910:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201912:	ed1c                	sd	a5,24(a0)
ffffffffc0201914:	0141                	addi	sp,sp,16
ffffffffc0201916:	8082                	ret
            base->property += p->property;
ffffffffc0201918:	ff87a703          	lw	a4,-8(a5)
ffffffffc020191c:	ff078693          	addi	a3,a5,-16
ffffffffc0201920:	9e39                	addw	a2,a2,a4
ffffffffc0201922:	c910                	sw	a2,16(a0)
ffffffffc0201924:	5775                	li	a4,-3
ffffffffc0201926:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020192a:	6398                	ld	a4,0(a5)
ffffffffc020192c:	679c                	ld	a5,8(a5)
}
ffffffffc020192e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201930:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201932:	e398                	sd	a4,0(a5)
ffffffffc0201934:	0141                	addi	sp,sp,16
ffffffffc0201936:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201938:	00005697          	auipc	a3,0x5
ffffffffc020193c:	e7068693          	addi	a3,a3,-400 # ffffffffc02067a8 <commands+0xbc0>
ffffffffc0201940:	00005617          	auipc	a2,0x5
ffffffffc0201944:	b0860613          	addi	a2,a2,-1272 # ffffffffc0206448 <commands+0x860>
ffffffffc0201948:	09400593          	li	a1,148
ffffffffc020194c:	00005517          	auipc	a0,0x5
ffffffffc0201950:	b1450513          	addi	a0,a0,-1260 # ffffffffc0206460 <commands+0x878>
ffffffffc0201954:	b3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201958:	00005697          	auipc	a3,0x5
ffffffffc020195c:	e4868693          	addi	a3,a3,-440 # ffffffffc02067a0 <commands+0xbb8>
ffffffffc0201960:	00005617          	auipc	a2,0x5
ffffffffc0201964:	ae860613          	addi	a2,a2,-1304 # ffffffffc0206448 <commands+0x860>
ffffffffc0201968:	09000593          	li	a1,144
ffffffffc020196c:	00005517          	auipc	a0,0x5
ffffffffc0201970:	af450513          	addi	a0,a0,-1292 # ffffffffc0206460 <commands+0x878>
ffffffffc0201974:	b1bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201978 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201978:	c941                	beqz	a0,ffffffffc0201a08 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020197a:	000b1597          	auipc	a1,0xb1
ffffffffc020197e:	d5e58593          	addi	a1,a1,-674 # ffffffffc02b26d8 <free_area>
ffffffffc0201982:	0105a803          	lw	a6,16(a1)
ffffffffc0201986:	872a                	mv	a4,a0
ffffffffc0201988:	02081793          	slli	a5,a6,0x20
ffffffffc020198c:	9381                	srli	a5,a5,0x20
ffffffffc020198e:	00a7ee63          	bltu	a5,a0,ffffffffc02019aa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201992:	87ae                	mv	a5,a1
ffffffffc0201994:	a801                	j	ffffffffc02019a4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201996:	ff87a683          	lw	a3,-8(a5)
ffffffffc020199a:	02069613          	slli	a2,a3,0x20
ffffffffc020199e:	9201                	srli	a2,a2,0x20
ffffffffc02019a0:	00e67763          	bgeu	a2,a4,ffffffffc02019ae <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02019a4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02019a6:	feb798e3          	bne	a5,a1,ffffffffc0201996 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02019aa:	4501                	li	a0,0
}
ffffffffc02019ac:	8082                	ret
    return listelm->prev;
ffffffffc02019ae:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019b2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02019b6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02019ba:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02019be:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02019c2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02019c6:	02c77863          	bgeu	a4,a2,ffffffffc02019f6 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02019ca:	071a                	slli	a4,a4,0x6
ffffffffc02019cc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02019ce:	41c686bb          	subw	a3,a3,t3
ffffffffc02019d2:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019d4:	00870613          	addi	a2,a4,8
ffffffffc02019d8:	4689                	li	a3,2
ffffffffc02019da:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02019de:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02019e2:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02019e6:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02019ea:	e290                	sd	a2,0(a3)
ffffffffc02019ec:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02019f0:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02019f2:	01173c23          	sd	a7,24(a4)
ffffffffc02019f6:	41c8083b          	subw	a6,a6,t3
ffffffffc02019fa:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019fe:	5775                	li	a4,-3
ffffffffc0201a00:	17c1                	addi	a5,a5,-16
ffffffffc0201a02:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201a06:	8082                	ret
{
ffffffffc0201a08:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201a0a:	00005697          	auipc	a3,0x5
ffffffffc0201a0e:	d9668693          	addi	a3,a3,-618 # ffffffffc02067a0 <commands+0xbb8>
ffffffffc0201a12:	00005617          	auipc	a2,0x5
ffffffffc0201a16:	a3660613          	addi	a2,a2,-1482 # ffffffffc0206448 <commands+0x860>
ffffffffc0201a1a:	06c00593          	li	a1,108
ffffffffc0201a1e:	00005517          	auipc	a0,0x5
ffffffffc0201a22:	a4250513          	addi	a0,a0,-1470 # ffffffffc0206460 <commands+0x878>
{
ffffffffc0201a26:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a28:	a67fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a2c <default_init_memmap>:
{
ffffffffc0201a2c:	1141                	addi	sp,sp,-16
ffffffffc0201a2e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a30:	c5f1                	beqz	a1,ffffffffc0201afc <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201a32:	00659693          	slli	a3,a1,0x6
ffffffffc0201a36:	96aa                	add	a3,a3,a0
ffffffffc0201a38:	87aa                	mv	a5,a0
ffffffffc0201a3a:	00d50f63          	beq	a0,a3,ffffffffc0201a58 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201a3e:	6798                	ld	a4,8(a5)
ffffffffc0201a40:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201a42:	cf49                	beqz	a4,ffffffffc0201adc <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201a44:	0007a823          	sw	zero,16(a5)
ffffffffc0201a48:	0007b423          	sd	zero,8(a5)
ffffffffc0201a4c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a50:	04078793          	addi	a5,a5,64
ffffffffc0201a54:	fed795e3          	bne	a5,a3,ffffffffc0201a3e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a58:	2581                	sext.w	a1,a1
ffffffffc0201a5a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a5c:	4789                	li	a5,2
ffffffffc0201a5e:	00850713          	addi	a4,a0,8
ffffffffc0201a62:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a66:	000b1697          	auipc	a3,0xb1
ffffffffc0201a6a:	c7268693          	addi	a3,a3,-910 # ffffffffc02b26d8 <free_area>
ffffffffc0201a6e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a70:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a72:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a76:	9db9                	addw	a1,a1,a4
ffffffffc0201a78:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a7a:	04d78a63          	beq	a5,a3,ffffffffc0201ace <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a7e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a82:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a86:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a88:	00e56a63          	bltu	a0,a4,ffffffffc0201a9c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a8c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a8e:	02d70263          	beq	a4,a3,ffffffffc0201ab2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a92:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a94:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a98:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a8c <default_init_memmap+0x60>
ffffffffc0201a9c:	c199                	beqz	a1,ffffffffc0201aa2 <default_init_memmap+0x76>
ffffffffc0201a9e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201aa2:	6398                	ld	a4,0(a5)
}
ffffffffc0201aa4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201aa6:	e390                	sd	a2,0(a5)
ffffffffc0201aa8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201aaa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201aac:	ed18                	sd	a4,24(a0)
ffffffffc0201aae:	0141                	addi	sp,sp,16
ffffffffc0201ab0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ab2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ab4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201ab6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201ab8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201aba:	00d70663          	beq	a4,a3,ffffffffc0201ac6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201abe:	8832                	mv	a6,a2
ffffffffc0201ac0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ac2:	87ba                	mv	a5,a4
ffffffffc0201ac4:	bfc1                	j	ffffffffc0201a94 <default_init_memmap+0x68>
}
ffffffffc0201ac6:	60a2                	ld	ra,8(sp)
ffffffffc0201ac8:	e290                	sd	a2,0(a3)
ffffffffc0201aca:	0141                	addi	sp,sp,16
ffffffffc0201acc:	8082                	ret
ffffffffc0201ace:	60a2                	ld	ra,8(sp)
ffffffffc0201ad0:	e390                	sd	a2,0(a5)
ffffffffc0201ad2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ad4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201ad6:	ed1c                	sd	a5,24(a0)
ffffffffc0201ad8:	0141                	addi	sp,sp,16
ffffffffc0201ada:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201adc:	00005697          	auipc	a3,0x5
ffffffffc0201ae0:	cf468693          	addi	a3,a3,-780 # ffffffffc02067d0 <commands+0xbe8>
ffffffffc0201ae4:	00005617          	auipc	a2,0x5
ffffffffc0201ae8:	96460613          	addi	a2,a2,-1692 # ffffffffc0206448 <commands+0x860>
ffffffffc0201aec:	04b00593          	li	a1,75
ffffffffc0201af0:	00005517          	auipc	a0,0x5
ffffffffc0201af4:	97050513          	addi	a0,a0,-1680 # ffffffffc0206460 <commands+0x878>
ffffffffc0201af8:	997fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201afc:	00005697          	auipc	a3,0x5
ffffffffc0201b00:	ca468693          	addi	a3,a3,-860 # ffffffffc02067a0 <commands+0xbb8>
ffffffffc0201b04:	00005617          	auipc	a2,0x5
ffffffffc0201b08:	94460613          	addi	a2,a2,-1724 # ffffffffc0206448 <commands+0x860>
ffffffffc0201b0c:	04700593          	li	a1,71
ffffffffc0201b10:	00005517          	auipc	a0,0x5
ffffffffc0201b14:	95050513          	addi	a0,a0,-1712 # ffffffffc0206460 <commands+0x878>
ffffffffc0201b18:	977fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b1c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201b1c:	c94d                	beqz	a0,ffffffffc0201bce <slob_free+0xb2>
{
ffffffffc0201b1e:	1141                	addi	sp,sp,-16
ffffffffc0201b20:	e022                	sd	s0,0(sp)
ffffffffc0201b22:	e406                	sd	ra,8(sp)
ffffffffc0201b24:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201b26:	e9c1                	bnez	a1,ffffffffc0201bb6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b28:	100027f3          	csrr	a5,sstatus
ffffffffc0201b2c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b2e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b30:	ebd9                	bnez	a5,ffffffffc0201bc6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b32:	000b0617          	auipc	a2,0xb0
ffffffffc0201b36:	79660613          	addi	a2,a2,1942 # ffffffffc02b22c8 <slobfree>
ffffffffc0201b3a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b3c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b3e:	679c                	ld	a5,8(a5)
ffffffffc0201b40:	02877a63          	bgeu	a4,s0,ffffffffc0201b74 <slob_free+0x58>
ffffffffc0201b44:	00f46463          	bltu	s0,a5,ffffffffc0201b4c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b48:	fef76ae3          	bltu	a4,a5,ffffffffc0201b3c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b4c:	400c                	lw	a1,0(s0)
ffffffffc0201b4e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b52:	96a2                	add	a3,a3,s0
ffffffffc0201b54:	02d78a63          	beq	a5,a3,ffffffffc0201b88 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b58:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b5a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b5c:	00469793          	slli	a5,a3,0x4
ffffffffc0201b60:	97ba                	add	a5,a5,a4
ffffffffc0201b62:	02f40e63          	beq	s0,a5,ffffffffc0201b9e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b66:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b68:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b6a:	e129                	bnez	a0,ffffffffc0201bac <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b6c:	60a2                	ld	ra,8(sp)
ffffffffc0201b6e:	6402                	ld	s0,0(sp)
ffffffffc0201b70:	0141                	addi	sp,sp,16
ffffffffc0201b72:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b74:	fcf764e3          	bltu	a4,a5,ffffffffc0201b3c <slob_free+0x20>
ffffffffc0201b78:	fcf472e3          	bgeu	s0,a5,ffffffffc0201b3c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b7c:	400c                	lw	a1,0(s0)
ffffffffc0201b7e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b82:	96a2                	add	a3,a3,s0
ffffffffc0201b84:	fcd79ae3          	bne	a5,a3,ffffffffc0201b58 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b88:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b8a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b8c:	9db5                	addw	a1,a1,a3
ffffffffc0201b8e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b90:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b92:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b94:	00469793          	slli	a5,a3,0x4
ffffffffc0201b98:	97ba                	add	a5,a5,a4
ffffffffc0201b9a:	fcf416e3          	bne	s0,a5,ffffffffc0201b66 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b9e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201ba0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201ba2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201ba4:	9ebd                	addw	a3,a3,a5
ffffffffc0201ba6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201ba8:	e70c                	sd	a1,8(a4)
ffffffffc0201baa:	d169                	beqz	a0,ffffffffc0201b6c <slob_free+0x50>
}
ffffffffc0201bac:	6402                	ld	s0,0(sp)
ffffffffc0201bae:	60a2                	ld	ra,8(sp)
ffffffffc0201bb0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201bb2:	dfdfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201bb6:	25bd                	addiw	a1,a1,15
ffffffffc0201bb8:	8191                	srli	a1,a1,0x4
ffffffffc0201bba:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201bc0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bc2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bc4:	d7bd                	beqz	a5,ffffffffc0201b32 <slob_free+0x16>
        intr_disable();
ffffffffc0201bc6:	deffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201bca:	4505                	li	a0,1
ffffffffc0201bcc:	b79d                	j	ffffffffc0201b32 <slob_free+0x16>
ffffffffc0201bce:	8082                	ret

ffffffffc0201bd0 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bd0:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bd2:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bd4:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bd8:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bda:	352000ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
	if (!page)
ffffffffc0201bde:	c91d                	beqz	a0,ffffffffc0201c14 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201be0:	000b5697          	auipc	a3,0xb5
ffffffffc0201be4:	b686b683          	ld	a3,-1176(a3) # ffffffffc02b6748 <pages>
ffffffffc0201be8:	8d15                	sub	a0,a0,a3
ffffffffc0201bea:	8519                	srai	a0,a0,0x6
ffffffffc0201bec:	00006697          	auipc	a3,0x6
ffffffffc0201bf0:	0146b683          	ld	a3,20(a3) # ffffffffc0207c00 <nbase>
ffffffffc0201bf4:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201bf6:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bfa:	83b1                	srli	a5,a5,0xc
ffffffffc0201bfc:	000b5717          	auipc	a4,0xb5
ffffffffc0201c00:	b4473703          	ld	a4,-1212(a4) # ffffffffc02b6740 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c04:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c06:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c1a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c0a:	000b5697          	auipc	a3,0xb5
ffffffffc0201c0e:	b4e6b683          	ld	a3,-1202(a3) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0201c12:	9536                	add	a0,a0,a3
}
ffffffffc0201c14:	60a2                	ld	ra,8(sp)
ffffffffc0201c16:	0141                	addi	sp,sp,16
ffffffffc0201c18:	8082                	ret
ffffffffc0201c1a:	86aa                	mv	a3,a0
ffffffffc0201c1c:	00005617          	auipc	a2,0x5
ffffffffc0201c20:	c1460613          	addi	a2,a2,-1004 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc0201c24:	07100593          	li	a1,113
ffffffffc0201c28:	00005517          	auipc	a0,0x5
ffffffffc0201c2c:	c3050513          	addi	a0,a0,-976 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0201c30:	85ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c34 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c34:	1101                	addi	sp,sp,-32
ffffffffc0201c36:	ec06                	sd	ra,24(sp)
ffffffffc0201c38:	e822                	sd	s0,16(sp)
ffffffffc0201c3a:	e426                	sd	s1,8(sp)
ffffffffc0201c3c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c3e:	01050713          	addi	a4,a0,16
ffffffffc0201c42:	6785                	lui	a5,0x1
ffffffffc0201c44:	0cf77363          	bgeu	a4,a5,ffffffffc0201d0a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c48:	00f50493          	addi	s1,a0,15
ffffffffc0201c4c:	8091                	srli	s1,s1,0x4
ffffffffc0201c4e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c50:	10002673          	csrr	a2,sstatus
ffffffffc0201c54:	8a09                	andi	a2,a2,2
ffffffffc0201c56:	e25d                	bnez	a2,ffffffffc0201cfc <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c58:	000b0917          	auipc	s2,0xb0
ffffffffc0201c5c:	67090913          	addi	s2,s2,1648 # ffffffffc02b22c8 <slobfree>
ffffffffc0201c60:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c64:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c66:	4398                	lw	a4,0(a5)
ffffffffc0201c68:	08975e63          	bge	a4,s1,ffffffffc0201d04 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c6c:	00f68b63          	beq	a3,a5,ffffffffc0201c82 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c70:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c72:	4018                	lw	a4,0(s0)
ffffffffc0201c74:	02975a63          	bge	a4,s1,ffffffffc0201ca8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c78:	00093683          	ld	a3,0(s2)
ffffffffc0201c7c:	87a2                	mv	a5,s0
ffffffffc0201c7e:	fef699e3          	bne	a3,a5,ffffffffc0201c70 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c82:	ee31                	bnez	a2,ffffffffc0201cde <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c84:	4501                	li	a0,0
ffffffffc0201c86:	f4bff0ef          	jal	ra,ffffffffc0201bd0 <__slob_get_free_pages.constprop.0>
ffffffffc0201c8a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c8c:	cd05                	beqz	a0,ffffffffc0201cc4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c8e:	6585                	lui	a1,0x1
ffffffffc0201c90:	e8dff0ef          	jal	ra,ffffffffc0201b1c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c94:	10002673          	csrr	a2,sstatus
ffffffffc0201c98:	8a09                	andi	a2,a2,2
ffffffffc0201c9a:	ee05                	bnez	a2,ffffffffc0201cd2 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c9c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ca0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ca2:	4018                	lw	a4,0(s0)
ffffffffc0201ca4:	fc974ae3          	blt	a4,s1,ffffffffc0201c78 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201ca8:	04e48763          	beq	s1,a4,ffffffffc0201cf6 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201cac:	00449693          	slli	a3,s1,0x4
ffffffffc0201cb0:	96a2                	add	a3,a3,s0
ffffffffc0201cb2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201cb4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201cb6:	9f05                	subw	a4,a4,s1
ffffffffc0201cb8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201cba:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201cbc:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201cbe:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201cc2:	e20d                	bnez	a2,ffffffffc0201ce4 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201cc4:	60e2                	ld	ra,24(sp)
ffffffffc0201cc6:	8522                	mv	a0,s0
ffffffffc0201cc8:	6442                	ld	s0,16(sp)
ffffffffc0201cca:	64a2                	ld	s1,8(sp)
ffffffffc0201ccc:	6902                	ld	s2,0(sp)
ffffffffc0201cce:	6105                	addi	sp,sp,32
ffffffffc0201cd0:	8082                	ret
        intr_disable();
ffffffffc0201cd2:	ce3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201cd6:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201cda:	4605                	li	a2,1
ffffffffc0201cdc:	b7d1                	j	ffffffffc0201ca0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201cde:	cd1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ce2:	b74d                	j	ffffffffc0201c84 <slob_alloc.constprop.0+0x50>
ffffffffc0201ce4:	ccbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201ce8:	60e2                	ld	ra,24(sp)
ffffffffc0201cea:	8522                	mv	a0,s0
ffffffffc0201cec:	6442                	ld	s0,16(sp)
ffffffffc0201cee:	64a2                	ld	s1,8(sp)
ffffffffc0201cf0:	6902                	ld	s2,0(sp)
ffffffffc0201cf2:	6105                	addi	sp,sp,32
ffffffffc0201cf4:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201cf6:	6418                	ld	a4,8(s0)
ffffffffc0201cf8:	e798                	sd	a4,8(a5)
ffffffffc0201cfa:	b7d1                	j	ffffffffc0201cbe <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201cfc:	cb9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d00:	4605                	li	a2,1
ffffffffc0201d02:	bf99                	j	ffffffffc0201c58 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201d04:	843e                	mv	s0,a5
ffffffffc0201d06:	87b6                	mv	a5,a3
ffffffffc0201d08:	b745                	j	ffffffffc0201ca8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d0a:	00005697          	auipc	a3,0x5
ffffffffc0201d0e:	b5e68693          	addi	a3,a3,-1186 # ffffffffc0206868 <default_pmm_manager+0x70>
ffffffffc0201d12:	00004617          	auipc	a2,0x4
ffffffffc0201d16:	73660613          	addi	a2,a2,1846 # ffffffffc0206448 <commands+0x860>
ffffffffc0201d1a:	06300593          	li	a1,99
ffffffffc0201d1e:	00005517          	auipc	a0,0x5
ffffffffc0201d22:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0206888 <default_pmm_manager+0x90>
ffffffffc0201d26:	f68fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d2a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d2a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d2c:	00005517          	auipc	a0,0x5
ffffffffc0201d30:	b7450513          	addi	a0,a0,-1164 # ffffffffc02068a0 <default_pmm_manager+0xa8>
{
ffffffffc0201d34:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d36:	c5efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d3a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d3c:	00005517          	auipc	a0,0x5
ffffffffc0201d40:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02068b8 <default_pmm_manager+0xc0>
}
ffffffffc0201d44:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d46:	c4efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d4a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d4a:	4501                	li	a0,0
ffffffffc0201d4c:	8082                	ret

ffffffffc0201d4e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d4e:	1101                	addi	sp,sp,-32
ffffffffc0201d50:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d52:	6905                	lui	s2,0x1
{
ffffffffc0201d54:	e822                	sd	s0,16(sp)
ffffffffc0201d56:	ec06                	sd	ra,24(sp)
ffffffffc0201d58:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d5a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0201d5e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d60:	04a7f963          	bgeu	a5,a0,ffffffffc0201db2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d64:	4561                	li	a0,24
ffffffffc0201d66:	ecfff0ef          	jal	ra,ffffffffc0201c34 <slob_alloc.constprop.0>
ffffffffc0201d6a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d6c:	c929                	beqz	a0,ffffffffc0201dbe <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d6e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d72:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d74:	00f95763          	bge	s2,a5,ffffffffc0201d82 <kmalloc+0x34>
ffffffffc0201d78:	6705                	lui	a4,0x1
ffffffffc0201d7a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d7c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d7e:	fef74ee3          	blt	a4,a5,ffffffffc0201d7a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d82:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d84:	e4dff0ef          	jal	ra,ffffffffc0201bd0 <__slob_get_free_pages.constprop.0>
ffffffffc0201d88:	e488                	sd	a0,8(s1)
ffffffffc0201d8a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d8c:	c525                	beqz	a0,ffffffffc0201df4 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d92:	8b89                	andi	a5,a5,2
ffffffffc0201d94:	ef8d                	bnez	a5,ffffffffc0201dce <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d96:	000b5797          	auipc	a5,0xb5
ffffffffc0201d9a:	99278793          	addi	a5,a5,-1646 # ffffffffc02b6728 <bigblocks>
ffffffffc0201d9e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201da0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201da2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201da4:	60e2                	ld	ra,24(sp)
ffffffffc0201da6:	8522                	mv	a0,s0
ffffffffc0201da8:	6442                	ld	s0,16(sp)
ffffffffc0201daa:	64a2                	ld	s1,8(sp)
ffffffffc0201dac:	6902                	ld	s2,0(sp)
ffffffffc0201dae:	6105                	addi	sp,sp,32
ffffffffc0201db0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201db2:	0541                	addi	a0,a0,16
ffffffffc0201db4:	e81ff0ef          	jal	ra,ffffffffc0201c34 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201db8:	01050413          	addi	s0,a0,16
ffffffffc0201dbc:	f565                	bnez	a0,ffffffffc0201da4 <kmalloc+0x56>
ffffffffc0201dbe:	4401                	li	s0,0
}
ffffffffc0201dc0:	60e2                	ld	ra,24(sp)
ffffffffc0201dc2:	8522                	mv	a0,s0
ffffffffc0201dc4:	6442                	ld	s0,16(sp)
ffffffffc0201dc6:	64a2                	ld	s1,8(sp)
ffffffffc0201dc8:	6902                	ld	s2,0(sp)
ffffffffc0201dca:	6105                	addi	sp,sp,32
ffffffffc0201dcc:	8082                	ret
        intr_disable();
ffffffffc0201dce:	be7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201dd2:	000b5797          	auipc	a5,0xb5
ffffffffc0201dd6:	95678793          	addi	a5,a5,-1706 # ffffffffc02b6728 <bigblocks>
ffffffffc0201dda:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ddc:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201dde:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201de0:	bcffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201de4:	6480                	ld	s0,8(s1)
}
ffffffffc0201de6:	60e2                	ld	ra,24(sp)
ffffffffc0201de8:	64a2                	ld	s1,8(sp)
ffffffffc0201dea:	8522                	mv	a0,s0
ffffffffc0201dec:	6442                	ld	s0,16(sp)
ffffffffc0201dee:	6902                	ld	s2,0(sp)
ffffffffc0201df0:	6105                	addi	sp,sp,32
ffffffffc0201df2:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201df4:	45e1                	li	a1,24
ffffffffc0201df6:	8526                	mv	a0,s1
ffffffffc0201df8:	d25ff0ef          	jal	ra,ffffffffc0201b1c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201dfc:	b765                	j	ffffffffc0201da4 <kmalloc+0x56>

ffffffffc0201dfe <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201dfe:	c169                	beqz	a0,ffffffffc0201ec0 <kfree+0xc2>
{
ffffffffc0201e00:	1101                	addi	sp,sp,-32
ffffffffc0201e02:	e822                	sd	s0,16(sp)
ffffffffc0201e04:	ec06                	sd	ra,24(sp)
ffffffffc0201e06:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201e08:	03451793          	slli	a5,a0,0x34
ffffffffc0201e0c:	842a                	mv	s0,a0
ffffffffc0201e0e:	e3d9                	bnez	a5,ffffffffc0201e94 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e10:	100027f3          	csrr	a5,sstatus
ffffffffc0201e14:	8b89                	andi	a5,a5,2
ffffffffc0201e16:	e7d9                	bnez	a5,ffffffffc0201ea4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e18:	000b5797          	auipc	a5,0xb5
ffffffffc0201e1c:	9107b783          	ld	a5,-1776(a5) # ffffffffc02b6728 <bigblocks>
    return 0;
ffffffffc0201e20:	4601                	li	a2,0
ffffffffc0201e22:	cbad                	beqz	a5,ffffffffc0201e94 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e24:	000b5697          	auipc	a3,0xb5
ffffffffc0201e28:	90468693          	addi	a3,a3,-1788 # ffffffffc02b6728 <bigblocks>
ffffffffc0201e2c:	a021                	j	ffffffffc0201e34 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e2e:	01048693          	addi	a3,s1,16
ffffffffc0201e32:	c3a5                	beqz	a5,ffffffffc0201e92 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201e34:	6798                	ld	a4,8(a5)
ffffffffc0201e36:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201e38:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e3a:	fe871ae3          	bne	a4,s0,ffffffffc0201e2e <kfree+0x30>
				*last = bb->next;
ffffffffc0201e3e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201e40:	ee2d                	bnez	a2,ffffffffc0201eba <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201e42:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201e46:	4098                	lw	a4,0(s1)
ffffffffc0201e48:	08f46963          	bltu	s0,a5,ffffffffc0201eda <kfree+0xdc>
ffffffffc0201e4c:	000b5697          	auipc	a3,0xb5
ffffffffc0201e50:	90c6b683          	ld	a3,-1780(a3) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0201e54:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e56:	8031                	srli	s0,s0,0xc
ffffffffc0201e58:	000b5797          	auipc	a5,0xb5
ffffffffc0201e5c:	8e87b783          	ld	a5,-1816(a5) # ffffffffc02b6740 <npage>
ffffffffc0201e60:	06f47163          	bgeu	s0,a5,ffffffffc0201ec2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e64:	00006517          	auipc	a0,0x6
ffffffffc0201e68:	d9c53503          	ld	a0,-612(a0) # ffffffffc0207c00 <nbase>
ffffffffc0201e6c:	8c09                	sub	s0,s0,a0
ffffffffc0201e6e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201e70:	000b5517          	auipc	a0,0xb5
ffffffffc0201e74:	8d853503          	ld	a0,-1832(a0) # ffffffffc02b6748 <pages>
ffffffffc0201e78:	4585                	li	a1,1
ffffffffc0201e7a:	9522                	add	a0,a0,s0
ffffffffc0201e7c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e80:	0ea000ef          	jal	ra,ffffffffc0201f6a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e84:	6442                	ld	s0,16(sp)
ffffffffc0201e86:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e88:	8526                	mv	a0,s1
}
ffffffffc0201e8a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e8c:	45e1                	li	a1,24
}
ffffffffc0201e8e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e90:	b171                	j	ffffffffc0201b1c <slob_free>
ffffffffc0201e92:	e20d                	bnez	a2,ffffffffc0201eb4 <kfree+0xb6>
ffffffffc0201e94:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e98:	6442                	ld	s0,16(sp)
ffffffffc0201e9a:	60e2                	ld	ra,24(sp)
ffffffffc0201e9c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e9e:	4581                	li	a1,0
}
ffffffffc0201ea0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ea2:	b9ad                	j	ffffffffc0201b1c <slob_free>
        intr_disable();
ffffffffc0201ea4:	b11fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ea8:	000b5797          	auipc	a5,0xb5
ffffffffc0201eac:	8807b783          	ld	a5,-1920(a5) # ffffffffc02b6728 <bigblocks>
        return 1;
ffffffffc0201eb0:	4605                	li	a2,1
ffffffffc0201eb2:	fbad                	bnez	a5,ffffffffc0201e24 <kfree+0x26>
        intr_enable();
ffffffffc0201eb4:	afbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201eb8:	bff1                	j	ffffffffc0201e94 <kfree+0x96>
ffffffffc0201eba:	af5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ebe:	b751                	j	ffffffffc0201e42 <kfree+0x44>
ffffffffc0201ec0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ec2:	00005617          	auipc	a2,0x5
ffffffffc0201ec6:	a3e60613          	addi	a2,a2,-1474 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc0201eca:	06900593          	li	a1,105
ffffffffc0201ece:	00005517          	auipc	a0,0x5
ffffffffc0201ed2:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0201ed6:	db8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201eda:	86a2                	mv	a3,s0
ffffffffc0201edc:	00005617          	auipc	a2,0x5
ffffffffc0201ee0:	9fc60613          	addi	a2,a2,-1540 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc0201ee4:	07700593          	li	a1,119
ffffffffc0201ee8:	00005517          	auipc	a0,0x5
ffffffffc0201eec:	97050513          	addi	a0,a0,-1680 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0201ef0:	d9efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ef4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ef4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ef6:	00005617          	auipc	a2,0x5
ffffffffc0201efa:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc0201efe:	06900593          	li	a1,105
ffffffffc0201f02:	00005517          	auipc	a0,0x5
ffffffffc0201f06:	95650513          	addi	a0,a0,-1706 # ffffffffc0206858 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201f0a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201f0c:	d82fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f10 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201f10:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201f12:	00005617          	auipc	a2,0x5
ffffffffc0201f16:	a0e60613          	addi	a2,a2,-1522 # ffffffffc0206920 <default_pmm_manager+0x128>
ffffffffc0201f1a:	07f00593          	li	a1,127
ffffffffc0201f1e:	00005517          	auipc	a0,0x5
ffffffffc0201f22:	93a50513          	addi	a0,a0,-1734 # ffffffffc0206858 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201f26:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201f28:	d66fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f2c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f2c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f30:	8b89                	andi	a5,a5,2
ffffffffc0201f32:	e799                	bnez	a5,ffffffffc0201f40 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f34:	000b5797          	auipc	a5,0xb5
ffffffffc0201f38:	81c7b783          	ld	a5,-2020(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201f3c:	6f9c                	ld	a5,24(a5)
ffffffffc0201f3e:	8782                	jr	a5
{
ffffffffc0201f40:	1141                	addi	sp,sp,-16
ffffffffc0201f42:	e406                	sd	ra,8(sp)
ffffffffc0201f44:	e022                	sd	s0,0(sp)
ffffffffc0201f46:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f48:	a6dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f4c:	000b5797          	auipc	a5,0xb5
ffffffffc0201f50:	8047b783          	ld	a5,-2044(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201f54:	6f9c                	ld	a5,24(a5)
ffffffffc0201f56:	8522                	mv	a0,s0
ffffffffc0201f58:	9782                	jalr	a5
ffffffffc0201f5a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f5c:	a53fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f60:	60a2                	ld	ra,8(sp)
ffffffffc0201f62:	8522                	mv	a0,s0
ffffffffc0201f64:	6402                	ld	s0,0(sp)
ffffffffc0201f66:	0141                	addi	sp,sp,16
ffffffffc0201f68:	8082                	ret

ffffffffc0201f6a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6e:	8b89                	andi	a5,a5,2
ffffffffc0201f70:	e799                	bnez	a5,ffffffffc0201f7e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f72:	000b4797          	auipc	a5,0xb4
ffffffffc0201f76:	7de7b783          	ld	a5,2014(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201f7a:	739c                	ld	a5,32(a5)
ffffffffc0201f7c:	8782                	jr	a5
{
ffffffffc0201f7e:	1101                	addi	sp,sp,-32
ffffffffc0201f80:	ec06                	sd	ra,24(sp)
ffffffffc0201f82:	e822                	sd	s0,16(sp)
ffffffffc0201f84:	e426                	sd	s1,8(sp)
ffffffffc0201f86:	842a                	mv	s0,a0
ffffffffc0201f88:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f8a:	a2bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f8e:	000b4797          	auipc	a5,0xb4
ffffffffc0201f92:	7c27b783          	ld	a5,1986(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201f96:	739c                	ld	a5,32(a5)
ffffffffc0201f98:	85a6                	mv	a1,s1
ffffffffc0201f9a:	8522                	mv	a0,s0
ffffffffc0201f9c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f9e:	6442                	ld	s0,16(sp)
ffffffffc0201fa0:	60e2                	ld	ra,24(sp)
ffffffffc0201fa2:	64a2                	ld	s1,8(sp)
ffffffffc0201fa4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201fa6:	a09fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201faa <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201faa:	100027f3          	csrr	a5,sstatus
ffffffffc0201fae:	8b89                	andi	a5,a5,2
ffffffffc0201fb0:	e799                	bnez	a5,ffffffffc0201fbe <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fb2:	000b4797          	auipc	a5,0xb4
ffffffffc0201fb6:	79e7b783          	ld	a5,1950(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201fba:	779c                	ld	a5,40(a5)
ffffffffc0201fbc:	8782                	jr	a5
{
ffffffffc0201fbe:	1141                	addi	sp,sp,-16
ffffffffc0201fc0:	e406                	sd	ra,8(sp)
ffffffffc0201fc2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201fc4:	9f1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fc8:	000b4797          	auipc	a5,0xb4
ffffffffc0201fcc:	7887b783          	ld	a5,1928(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0201fd0:	779c                	ld	a5,40(a5)
ffffffffc0201fd2:	9782                	jalr	a5
ffffffffc0201fd4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fd6:	9d9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201fda:	60a2                	ld	ra,8(sp)
ffffffffc0201fdc:	8522                	mv	a0,s0
ffffffffc0201fde:	6402                	ld	s0,0(sp)
ffffffffc0201fe0:	0141                	addi	sp,sp,16
ffffffffc0201fe2:	8082                	ret

ffffffffc0201fe4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fe4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201fe8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201fec:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fee:	078e                	slli	a5,a5,0x3
{
ffffffffc0201ff0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ff2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201ff6:	6094                	ld	a3,0(s1)
{
ffffffffc0201ff8:	f04a                	sd	s2,32(sp)
ffffffffc0201ffa:	ec4e                	sd	s3,24(sp)
ffffffffc0201ffc:	e852                	sd	s4,16(sp)
ffffffffc0201ffe:	fc06                	sd	ra,56(sp)
ffffffffc0202000:	f822                	sd	s0,48(sp)
ffffffffc0202002:	e456                	sd	s5,8(sp)
ffffffffc0202004:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202006:	0016f793          	andi	a5,a3,1
{
ffffffffc020200a:	892e                	mv	s2,a1
ffffffffc020200c:	8a32                	mv	s4,a2
ffffffffc020200e:	000b4997          	auipc	s3,0xb4
ffffffffc0202012:	73298993          	addi	s3,s3,1842 # ffffffffc02b6740 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202016:	efbd                	bnez	a5,ffffffffc0202094 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202018:	14060c63          	beqz	a2,ffffffffc0202170 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020201c:	100027f3          	csrr	a5,sstatus
ffffffffc0202020:	8b89                	andi	a5,a5,2
ffffffffc0202022:	14079963          	bnez	a5,ffffffffc0202174 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202026:	000b4797          	auipc	a5,0xb4
ffffffffc020202a:	72a7b783          	ld	a5,1834(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc020202e:	6f9c                	ld	a5,24(a5)
ffffffffc0202030:	4505                	li	a0,1
ffffffffc0202032:	9782                	jalr	a5
ffffffffc0202034:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202036:	12040d63          	beqz	s0,ffffffffc0202170 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020203a:	000b4b17          	auipc	s6,0xb4
ffffffffc020203e:	70eb0b13          	addi	s6,s6,1806 # ffffffffc02b6748 <pages>
ffffffffc0202042:	000b3503          	ld	a0,0(s6)
ffffffffc0202046:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020204a:	000b4997          	auipc	s3,0xb4
ffffffffc020204e:	6f698993          	addi	s3,s3,1782 # ffffffffc02b6740 <npage>
ffffffffc0202052:	40a40533          	sub	a0,s0,a0
ffffffffc0202056:	8519                	srai	a0,a0,0x6
ffffffffc0202058:	9556                	add	a0,a0,s5
ffffffffc020205a:	0009b703          	ld	a4,0(s3)
ffffffffc020205e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202062:	4685                	li	a3,1
ffffffffc0202064:	c014                	sw	a3,0(s0)
ffffffffc0202066:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202068:	0532                	slli	a0,a0,0xc
ffffffffc020206a:	16e7f763          	bgeu	a5,a4,ffffffffc02021d8 <get_pte+0x1f4>
ffffffffc020206e:	000b4797          	auipc	a5,0xb4
ffffffffc0202072:	6ea7b783          	ld	a5,1770(a5) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0202076:	6605                	lui	a2,0x1
ffffffffc0202078:	4581                	li	a1,0
ffffffffc020207a:	953e                	add	a0,a0,a5
ffffffffc020207c:	0d5030ef          	jal	ra,ffffffffc0205950 <memset>
    return page - pages + nbase;
ffffffffc0202080:	000b3683          	ld	a3,0(s6)
ffffffffc0202084:	40d406b3          	sub	a3,s0,a3
ffffffffc0202088:	8699                	srai	a3,a3,0x6
ffffffffc020208a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020208c:	06aa                	slli	a3,a3,0xa
ffffffffc020208e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202092:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202094:	77fd                	lui	a5,0xfffff
ffffffffc0202096:	068a                	slli	a3,a3,0x2
ffffffffc0202098:	0009b703          	ld	a4,0(s3)
ffffffffc020209c:	8efd                	and	a3,a3,a5
ffffffffc020209e:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020a2:	10e7ff63          	bgeu	a5,a4,ffffffffc02021c0 <get_pte+0x1dc>
ffffffffc02020a6:	000b4a97          	auipc	s5,0xb4
ffffffffc02020aa:	6b2a8a93          	addi	s5,s5,1714 # ffffffffc02b6758 <va_pa_offset>
ffffffffc02020ae:	000ab403          	ld	s0,0(s5)
ffffffffc02020b2:	01595793          	srli	a5,s2,0x15
ffffffffc02020b6:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ba:	96a2                	add	a3,a3,s0
ffffffffc02020bc:	00379413          	slli	s0,a5,0x3
ffffffffc02020c0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020c2:	6014                	ld	a3,0(s0)
ffffffffc02020c4:	0016f793          	andi	a5,a3,1
ffffffffc02020c8:	ebad                	bnez	a5,ffffffffc020213a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020ca:	0a0a0363          	beqz	s4,ffffffffc0202170 <get_pte+0x18c>
ffffffffc02020ce:	100027f3          	csrr	a5,sstatus
ffffffffc02020d2:	8b89                	andi	a5,a5,2
ffffffffc02020d4:	efcd                	bnez	a5,ffffffffc020218e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020d6:	000b4797          	auipc	a5,0xb4
ffffffffc02020da:	67a7b783          	ld	a5,1658(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc02020de:	6f9c                	ld	a5,24(a5)
ffffffffc02020e0:	4505                	li	a0,1
ffffffffc02020e2:	9782                	jalr	a5
ffffffffc02020e4:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020e6:	c4c9                	beqz	s1,ffffffffc0202170 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020e8:	000b4b17          	auipc	s6,0xb4
ffffffffc02020ec:	660b0b13          	addi	s6,s6,1632 # ffffffffc02b6748 <pages>
ffffffffc02020f0:	000b3503          	ld	a0,0(s6)
ffffffffc02020f4:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020f8:	0009b703          	ld	a4,0(s3)
ffffffffc02020fc:	40a48533          	sub	a0,s1,a0
ffffffffc0202100:	8519                	srai	a0,a0,0x6
ffffffffc0202102:	9552                	add	a0,a0,s4
ffffffffc0202104:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202108:	4685                	li	a3,1
ffffffffc020210a:	c094                	sw	a3,0(s1)
ffffffffc020210c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020210e:	0532                	slli	a0,a0,0xc
ffffffffc0202110:	0ee7f163          	bgeu	a5,a4,ffffffffc02021f2 <get_pte+0x20e>
ffffffffc0202114:	000ab783          	ld	a5,0(s5)
ffffffffc0202118:	6605                	lui	a2,0x1
ffffffffc020211a:	4581                	li	a1,0
ffffffffc020211c:	953e                	add	a0,a0,a5
ffffffffc020211e:	033030ef          	jal	ra,ffffffffc0205950 <memset>
    return page - pages + nbase;
ffffffffc0202122:	000b3683          	ld	a3,0(s6)
ffffffffc0202126:	40d486b3          	sub	a3,s1,a3
ffffffffc020212a:	8699                	srai	a3,a3,0x6
ffffffffc020212c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020212e:	06aa                	slli	a3,a3,0xa
ffffffffc0202130:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202134:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202136:	0009b703          	ld	a4,0(s3)
ffffffffc020213a:	068a                	slli	a3,a3,0x2
ffffffffc020213c:	757d                	lui	a0,0xfffff
ffffffffc020213e:	8ee9                	and	a3,a3,a0
ffffffffc0202140:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202144:	06e7f263          	bgeu	a5,a4,ffffffffc02021a8 <get_pte+0x1c4>
ffffffffc0202148:	000ab503          	ld	a0,0(s5)
ffffffffc020214c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202150:	1ff97913          	andi	s2,s2,511
ffffffffc0202154:	96aa                	add	a3,a3,a0
ffffffffc0202156:	00391513          	slli	a0,s2,0x3
ffffffffc020215a:	9536                	add	a0,a0,a3
}
ffffffffc020215c:	70e2                	ld	ra,56(sp)
ffffffffc020215e:	7442                	ld	s0,48(sp)
ffffffffc0202160:	74a2                	ld	s1,40(sp)
ffffffffc0202162:	7902                	ld	s2,32(sp)
ffffffffc0202164:	69e2                	ld	s3,24(sp)
ffffffffc0202166:	6a42                	ld	s4,16(sp)
ffffffffc0202168:	6aa2                	ld	s5,8(sp)
ffffffffc020216a:	6b02                	ld	s6,0(sp)
ffffffffc020216c:	6121                	addi	sp,sp,64
ffffffffc020216e:	8082                	ret
            return NULL;
ffffffffc0202170:	4501                	li	a0,0
ffffffffc0202172:	b7ed                	j	ffffffffc020215c <get_pte+0x178>
        intr_disable();
ffffffffc0202174:	841fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202178:	000b4797          	auipc	a5,0xb4
ffffffffc020217c:	5d87b783          	ld	a5,1496(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc0202180:	6f9c                	ld	a5,24(a5)
ffffffffc0202182:	4505                	li	a0,1
ffffffffc0202184:	9782                	jalr	a5
ffffffffc0202186:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202188:	827fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020218c:	b56d                	j	ffffffffc0202036 <get_pte+0x52>
        intr_disable();
ffffffffc020218e:	827fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202192:	000b4797          	auipc	a5,0xb4
ffffffffc0202196:	5be7b783          	ld	a5,1470(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc020219a:	6f9c                	ld	a5,24(a5)
ffffffffc020219c:	4505                	li	a0,1
ffffffffc020219e:	9782                	jalr	a5
ffffffffc02021a0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02021a2:	80dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021a6:	b781                	j	ffffffffc02020e6 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021a8:	00004617          	auipc	a2,0x4
ffffffffc02021ac:	68860613          	addi	a2,a2,1672 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02021b0:	0fa00593          	li	a1,250
ffffffffc02021b4:	00004517          	auipc	a0,0x4
ffffffffc02021b8:	79450513          	addi	a0,a0,1940 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02021bc:	ad2fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021c0:	00004617          	auipc	a2,0x4
ffffffffc02021c4:	67060613          	addi	a2,a2,1648 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02021c8:	0ed00593          	li	a1,237
ffffffffc02021cc:	00004517          	auipc	a0,0x4
ffffffffc02021d0:	77c50513          	addi	a0,a0,1916 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02021d4:	abafe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021d8:	86aa                	mv	a3,a0
ffffffffc02021da:	00004617          	auipc	a2,0x4
ffffffffc02021de:	65660613          	addi	a2,a2,1622 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02021e2:	0e900593          	li	a1,233
ffffffffc02021e6:	00004517          	auipc	a0,0x4
ffffffffc02021ea:	76250513          	addi	a0,a0,1890 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02021ee:	aa0fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021f2:	86aa                	mv	a3,a0
ffffffffc02021f4:	00004617          	auipc	a2,0x4
ffffffffc02021f8:	63c60613          	addi	a2,a2,1596 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02021fc:	0f700593          	li	a1,247
ffffffffc0202200:	00004517          	auipc	a0,0x4
ffffffffc0202204:	74850513          	addi	a0,a0,1864 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202208:	a86fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020220c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020220c:	1141                	addi	sp,sp,-16
ffffffffc020220e:	e022                	sd	s0,0(sp)
ffffffffc0202210:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202212:	4601                	li	a2,0
{
ffffffffc0202214:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202216:	dcfff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
    if (ptep_store != NULL)
ffffffffc020221a:	c011                	beqz	s0,ffffffffc020221e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020221c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020221e:	c511                	beqz	a0,ffffffffc020222a <get_page+0x1e>
ffffffffc0202220:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202222:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202224:	0017f713          	andi	a4,a5,1
ffffffffc0202228:	e709                	bnez	a4,ffffffffc0202232 <get_page+0x26>
}
ffffffffc020222a:	60a2                	ld	ra,8(sp)
ffffffffc020222c:	6402                	ld	s0,0(sp)
ffffffffc020222e:	0141                	addi	sp,sp,16
ffffffffc0202230:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202232:	078a                	slli	a5,a5,0x2
ffffffffc0202234:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202236:	000b4717          	auipc	a4,0xb4
ffffffffc020223a:	50a73703          	ld	a4,1290(a4) # ffffffffc02b6740 <npage>
ffffffffc020223e:	00e7ff63          	bgeu	a5,a4,ffffffffc020225c <get_page+0x50>
ffffffffc0202242:	60a2                	ld	ra,8(sp)
ffffffffc0202244:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202246:	fff80537          	lui	a0,0xfff80
ffffffffc020224a:	97aa                	add	a5,a5,a0
ffffffffc020224c:	079a                	slli	a5,a5,0x6
ffffffffc020224e:	000b4517          	auipc	a0,0xb4
ffffffffc0202252:	4fa53503          	ld	a0,1274(a0) # ffffffffc02b6748 <pages>
ffffffffc0202256:	953e                	add	a0,a0,a5
ffffffffc0202258:	0141                	addi	sp,sp,16
ffffffffc020225a:	8082                	ret
ffffffffc020225c:	c99ff0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>

ffffffffc0202260 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202260:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202262:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202266:	f486                	sd	ra,104(sp)
ffffffffc0202268:	f0a2                	sd	s0,96(sp)
ffffffffc020226a:	eca6                	sd	s1,88(sp)
ffffffffc020226c:	e8ca                	sd	s2,80(sp)
ffffffffc020226e:	e4ce                	sd	s3,72(sp)
ffffffffc0202270:	e0d2                	sd	s4,64(sp)
ffffffffc0202272:	fc56                	sd	s5,56(sp)
ffffffffc0202274:	f85a                	sd	s6,48(sp)
ffffffffc0202276:	f45e                	sd	s7,40(sp)
ffffffffc0202278:	f062                	sd	s8,32(sp)
ffffffffc020227a:	ec66                	sd	s9,24(sp)
ffffffffc020227c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020227e:	17d2                	slli	a5,a5,0x34
ffffffffc0202280:	e3ed                	bnez	a5,ffffffffc0202362 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202282:	002007b7          	lui	a5,0x200
ffffffffc0202286:	842e                	mv	s0,a1
ffffffffc0202288:	0ef5ed63          	bltu	a1,a5,ffffffffc0202382 <unmap_range+0x122>
ffffffffc020228c:	8932                	mv	s2,a2
ffffffffc020228e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202382 <unmap_range+0x122>
ffffffffc0202292:	4785                	li	a5,1
ffffffffc0202294:	07fe                	slli	a5,a5,0x1f
ffffffffc0202296:	0ec7e663          	bltu	a5,a2,ffffffffc0202382 <unmap_range+0x122>
ffffffffc020229a:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020229c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020229e:	000b4c97          	auipc	s9,0xb4
ffffffffc02022a2:	4a2c8c93          	addi	s9,s9,1186 # ffffffffc02b6740 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02022a6:	000b4c17          	auipc	s8,0xb4
ffffffffc02022aa:	4a2c0c13          	addi	s8,s8,1186 # ffffffffc02b6748 <pages>
ffffffffc02022ae:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02022b2:	000b4d17          	auipc	s10,0xb4
ffffffffc02022b6:	49ed0d13          	addi	s10,s10,1182 # ffffffffc02b6750 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022ba:	00200b37          	lui	s6,0x200
ffffffffc02022be:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022c2:	4601                	li	a2,0
ffffffffc02022c4:	85a2                	mv	a1,s0
ffffffffc02022c6:	854e                	mv	a0,s3
ffffffffc02022c8:	d1dff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc02022cc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02022ce:	cd29                	beqz	a0,ffffffffc0202328 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02022d0:	611c                	ld	a5,0(a0)
ffffffffc02022d2:	e395                	bnez	a5,ffffffffc02022f6 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02022d4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022d6:	ff2466e3          	bltu	s0,s2,ffffffffc02022c2 <unmap_range+0x62>
}
ffffffffc02022da:	70a6                	ld	ra,104(sp)
ffffffffc02022dc:	7406                	ld	s0,96(sp)
ffffffffc02022de:	64e6                	ld	s1,88(sp)
ffffffffc02022e0:	6946                	ld	s2,80(sp)
ffffffffc02022e2:	69a6                	ld	s3,72(sp)
ffffffffc02022e4:	6a06                	ld	s4,64(sp)
ffffffffc02022e6:	7ae2                	ld	s5,56(sp)
ffffffffc02022e8:	7b42                	ld	s6,48(sp)
ffffffffc02022ea:	7ba2                	ld	s7,40(sp)
ffffffffc02022ec:	7c02                	ld	s8,32(sp)
ffffffffc02022ee:	6ce2                	ld	s9,24(sp)
ffffffffc02022f0:	6d42                	ld	s10,16(sp)
ffffffffc02022f2:	6165                	addi	sp,sp,112
ffffffffc02022f4:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022f6:	0017f713          	andi	a4,a5,1
ffffffffc02022fa:	df69                	beqz	a4,ffffffffc02022d4 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02022fc:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202300:	078a                	slli	a5,a5,0x2
ffffffffc0202302:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202304:	08e7ff63          	bgeu	a5,a4,ffffffffc02023a2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202308:	000c3503          	ld	a0,0(s8)
ffffffffc020230c:	97de                	add	a5,a5,s7
ffffffffc020230e:	079a                	slli	a5,a5,0x6
ffffffffc0202310:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202312:	411c                	lw	a5,0(a0)
ffffffffc0202314:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202318:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020231a:	cf11                	beqz	a4,ffffffffc0202336 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020231c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202320:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202324:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202326:	bf45                	j	ffffffffc02022d6 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202328:	945a                	add	s0,s0,s6
ffffffffc020232a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020232e:	d455                	beqz	s0,ffffffffc02022da <unmap_range+0x7a>
ffffffffc0202330:	f92469e3          	bltu	s0,s2,ffffffffc02022c2 <unmap_range+0x62>
ffffffffc0202334:	b75d                	j	ffffffffc02022da <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202336:	100027f3          	csrr	a5,sstatus
ffffffffc020233a:	8b89                	andi	a5,a5,2
ffffffffc020233c:	e799                	bnez	a5,ffffffffc020234a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020233e:	000d3783          	ld	a5,0(s10)
ffffffffc0202342:	4585                	li	a1,1
ffffffffc0202344:	739c                	ld	a5,32(a5)
ffffffffc0202346:	9782                	jalr	a5
    if (flag)
ffffffffc0202348:	bfd1                	j	ffffffffc020231c <unmap_range+0xbc>
ffffffffc020234a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020234c:	e68fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202350:	000d3783          	ld	a5,0(s10)
ffffffffc0202354:	6522                	ld	a0,8(sp)
ffffffffc0202356:	4585                	li	a1,1
ffffffffc0202358:	739c                	ld	a5,32(a5)
ffffffffc020235a:	9782                	jalr	a5
        intr_enable();
ffffffffc020235c:	e52fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202360:	bf75                	j	ffffffffc020231c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202362:	00004697          	auipc	a3,0x4
ffffffffc0202366:	5f668693          	addi	a3,a3,1526 # ffffffffc0206958 <default_pmm_manager+0x160>
ffffffffc020236a:	00004617          	auipc	a2,0x4
ffffffffc020236e:	0de60613          	addi	a2,a2,222 # ffffffffc0206448 <commands+0x860>
ffffffffc0202372:	12000593          	li	a1,288
ffffffffc0202376:	00004517          	auipc	a0,0x4
ffffffffc020237a:	5d250513          	addi	a0,a0,1490 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020237e:	910fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202382:	00004697          	auipc	a3,0x4
ffffffffc0202386:	60668693          	addi	a3,a3,1542 # ffffffffc0206988 <default_pmm_manager+0x190>
ffffffffc020238a:	00004617          	auipc	a2,0x4
ffffffffc020238e:	0be60613          	addi	a2,a2,190 # ffffffffc0206448 <commands+0x860>
ffffffffc0202392:	12100593          	li	a1,289
ffffffffc0202396:	00004517          	auipc	a0,0x4
ffffffffc020239a:	5b250513          	addi	a0,a0,1458 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020239e:	8f0fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02023a2:	b53ff0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>

ffffffffc02023a6 <exit_range>:
{
ffffffffc02023a6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023a8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023ac:	fc86                	sd	ra,120(sp)
ffffffffc02023ae:	f8a2                	sd	s0,112(sp)
ffffffffc02023b0:	f4a6                	sd	s1,104(sp)
ffffffffc02023b2:	f0ca                	sd	s2,96(sp)
ffffffffc02023b4:	ecce                	sd	s3,88(sp)
ffffffffc02023b6:	e8d2                	sd	s4,80(sp)
ffffffffc02023b8:	e4d6                	sd	s5,72(sp)
ffffffffc02023ba:	e0da                	sd	s6,64(sp)
ffffffffc02023bc:	fc5e                	sd	s7,56(sp)
ffffffffc02023be:	f862                	sd	s8,48(sp)
ffffffffc02023c0:	f466                	sd	s9,40(sp)
ffffffffc02023c2:	f06a                	sd	s10,32(sp)
ffffffffc02023c4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023c6:	17d2                	slli	a5,a5,0x34
ffffffffc02023c8:	20079a63          	bnez	a5,ffffffffc02025dc <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02023cc:	002007b7          	lui	a5,0x200
ffffffffc02023d0:	24f5e463          	bltu	a1,a5,ffffffffc0202618 <exit_range+0x272>
ffffffffc02023d4:	8ab2                	mv	s5,a2
ffffffffc02023d6:	24c5f163          	bgeu	a1,a2,ffffffffc0202618 <exit_range+0x272>
ffffffffc02023da:	4785                	li	a5,1
ffffffffc02023dc:	07fe                	slli	a5,a5,0x1f
ffffffffc02023de:	22c7ed63          	bltu	a5,a2,ffffffffc0202618 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023e2:	c00009b7          	lui	s3,0xc0000
ffffffffc02023e6:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023ea:	ffe00937          	lui	s2,0xffe00
ffffffffc02023ee:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02023f2:	5cfd                	li	s9,-1
ffffffffc02023f4:	8c2a                	mv	s8,a0
ffffffffc02023f6:	0125f933          	and	s2,a1,s2
ffffffffc02023fa:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02023fc:	000b4d17          	auipc	s10,0xb4
ffffffffc0202400:	344d0d13          	addi	s10,s10,836 # ffffffffc02b6740 <npage>
    return KADDR(page2pa(page));
ffffffffc0202404:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202408:	000b4717          	auipc	a4,0xb4
ffffffffc020240c:	34070713          	addi	a4,a4,832 # ffffffffc02b6748 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202410:	000b4d97          	auipc	s11,0xb4
ffffffffc0202414:	340d8d93          	addi	s11,s11,832 # ffffffffc02b6750 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202418:	c0000437          	lui	s0,0xc0000
ffffffffc020241c:	944e                	add	s0,s0,s3
ffffffffc020241e:	8079                	srli	s0,s0,0x1e
ffffffffc0202420:	1ff47413          	andi	s0,s0,511
ffffffffc0202424:	040e                	slli	s0,s0,0x3
ffffffffc0202426:	9462                	add	s0,s0,s8
ffffffffc0202428:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff4080>
        if (pde1 & PTE_V)
ffffffffc020242c:	001a7793          	andi	a5,s4,1
ffffffffc0202430:	eb99                	bnez	a5,ffffffffc0202446 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202432:	12098463          	beqz	s3,ffffffffc020255a <exit_range+0x1b4>
ffffffffc0202436:	400007b7          	lui	a5,0x40000
ffffffffc020243a:	97ce                	add	a5,a5,s3
ffffffffc020243c:	894e                	mv	s2,s3
ffffffffc020243e:	1159fe63          	bgeu	s3,s5,ffffffffc020255a <exit_range+0x1b4>
ffffffffc0202442:	89be                	mv	s3,a5
ffffffffc0202444:	bfd1                	j	ffffffffc0202418 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202446:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020244a:	0a0a                	slli	s4,s4,0x2
ffffffffc020244c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202450:	1cfa7263          	bgeu	s4,a5,ffffffffc0202614 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202454:	fff80637          	lui	a2,0xfff80
ffffffffc0202458:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020245a:	000806b7          	lui	a3,0x80
ffffffffc020245e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202460:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202464:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202466:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202468:	18f5fa63          	bgeu	a1,a5,ffffffffc02025fc <exit_range+0x256>
ffffffffc020246c:	000b4817          	auipc	a6,0xb4
ffffffffc0202470:	2ec80813          	addi	a6,a6,748 # ffffffffc02b6758 <va_pa_offset>
ffffffffc0202474:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202478:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020247a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020247e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202480:	00080337          	lui	t1,0x80
ffffffffc0202484:	6885                	lui	a7,0x1
ffffffffc0202486:	a819                	j	ffffffffc020249c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202488:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020248a:	002007b7          	lui	a5,0x200
ffffffffc020248e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202490:	08090c63          	beqz	s2,ffffffffc0202528 <exit_range+0x182>
ffffffffc0202494:	09397a63          	bgeu	s2,s3,ffffffffc0202528 <exit_range+0x182>
ffffffffc0202498:	0f597063          	bgeu	s2,s5,ffffffffc0202578 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020249c:	01595493          	srli	s1,s2,0x15
ffffffffc02024a0:	1ff4f493          	andi	s1,s1,511
ffffffffc02024a4:	048e                	slli	s1,s1,0x3
ffffffffc02024a6:	94da                	add	s1,s1,s6
ffffffffc02024a8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02024aa:	0017f693          	andi	a3,a5,1
ffffffffc02024ae:	dee9                	beqz	a3,ffffffffc0202488 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02024b0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024b4:	078a                	slli	a5,a5,0x2
ffffffffc02024b6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202614 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024bc:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02024be:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02024c2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024c6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024cc:	12bef863          	bgeu	t4,a1,ffffffffc02025fc <exit_range+0x256>
ffffffffc02024d0:	00083783          	ld	a5,0(a6)
ffffffffc02024d4:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024d6:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02024da:	629c                	ld	a5,0(a3)
ffffffffc02024dc:	8b85                	andi	a5,a5,1
ffffffffc02024de:	f7d5                	bnez	a5,ffffffffc020248a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024e0:	06a1                	addi	a3,a3,8
ffffffffc02024e2:	fed59ce3          	bne	a1,a3,ffffffffc02024da <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e6:	631c                	ld	a5,0(a4)
ffffffffc02024e8:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024ea:	100027f3          	csrr	a5,sstatus
ffffffffc02024ee:	8b89                	andi	a5,a5,2
ffffffffc02024f0:	e7d9                	bnez	a5,ffffffffc020257e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02024f2:	000db783          	ld	a5,0(s11)
ffffffffc02024f6:	4585                	li	a1,1
ffffffffc02024f8:	e032                	sd	a2,0(sp)
ffffffffc02024fa:	739c                	ld	a5,32(a5)
ffffffffc02024fc:	9782                	jalr	a5
    if (flag)
ffffffffc02024fe:	6602                	ld	a2,0(sp)
ffffffffc0202500:	000b4817          	auipc	a6,0xb4
ffffffffc0202504:	25880813          	addi	a6,a6,600 # ffffffffc02b6758 <va_pa_offset>
ffffffffc0202508:	fff80e37          	lui	t3,0xfff80
ffffffffc020250c:	00080337          	lui	t1,0x80
ffffffffc0202510:	6885                	lui	a7,0x1
ffffffffc0202512:	000b4717          	auipc	a4,0xb4
ffffffffc0202516:	23670713          	addi	a4,a4,566 # ffffffffc02b6748 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020251a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020251e:	002007b7          	lui	a5,0x200
ffffffffc0202522:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202524:	f60918e3          	bnez	s2,ffffffffc0202494 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202528:	f00b85e3          	beqz	s7,ffffffffc0202432 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020252c:	000d3783          	ld	a5,0(s10)
ffffffffc0202530:	0efa7263          	bgeu	s4,a5,ffffffffc0202614 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202534:	6308                	ld	a0,0(a4)
ffffffffc0202536:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202538:	100027f3          	csrr	a5,sstatus
ffffffffc020253c:	8b89                	andi	a5,a5,2
ffffffffc020253e:	efad                	bnez	a5,ffffffffc02025b8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202540:	000db783          	ld	a5,0(s11)
ffffffffc0202544:	4585                	li	a1,1
ffffffffc0202546:	739c                	ld	a5,32(a5)
ffffffffc0202548:	9782                	jalr	a5
ffffffffc020254a:	000b4717          	auipc	a4,0xb4
ffffffffc020254e:	1fe70713          	addi	a4,a4,510 # ffffffffc02b6748 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202552:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202556:	ee0990e3          	bnez	s3,ffffffffc0202436 <exit_range+0x90>
}
ffffffffc020255a:	70e6                	ld	ra,120(sp)
ffffffffc020255c:	7446                	ld	s0,112(sp)
ffffffffc020255e:	74a6                	ld	s1,104(sp)
ffffffffc0202560:	7906                	ld	s2,96(sp)
ffffffffc0202562:	69e6                	ld	s3,88(sp)
ffffffffc0202564:	6a46                	ld	s4,80(sp)
ffffffffc0202566:	6aa6                	ld	s5,72(sp)
ffffffffc0202568:	6b06                	ld	s6,64(sp)
ffffffffc020256a:	7be2                	ld	s7,56(sp)
ffffffffc020256c:	7c42                	ld	s8,48(sp)
ffffffffc020256e:	7ca2                	ld	s9,40(sp)
ffffffffc0202570:	7d02                	ld	s10,32(sp)
ffffffffc0202572:	6de2                	ld	s11,24(sp)
ffffffffc0202574:	6109                	addi	sp,sp,128
ffffffffc0202576:	8082                	ret
            if (free_pd0)
ffffffffc0202578:	ea0b8fe3          	beqz	s7,ffffffffc0202436 <exit_range+0x90>
ffffffffc020257c:	bf45                	j	ffffffffc020252c <exit_range+0x186>
ffffffffc020257e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202580:	e42a                	sd	a0,8(sp)
ffffffffc0202582:	c32fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202586:	000db783          	ld	a5,0(s11)
ffffffffc020258a:	6522                	ld	a0,8(sp)
ffffffffc020258c:	4585                	li	a1,1
ffffffffc020258e:	739c                	ld	a5,32(a5)
ffffffffc0202590:	9782                	jalr	a5
        intr_enable();
ffffffffc0202592:	c1cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202596:	6602                	ld	a2,0(sp)
ffffffffc0202598:	000b4717          	auipc	a4,0xb4
ffffffffc020259c:	1b070713          	addi	a4,a4,432 # ffffffffc02b6748 <pages>
ffffffffc02025a0:	6885                	lui	a7,0x1
ffffffffc02025a2:	00080337          	lui	t1,0x80
ffffffffc02025a6:	fff80e37          	lui	t3,0xfff80
ffffffffc02025aa:	000b4817          	auipc	a6,0xb4
ffffffffc02025ae:	1ae80813          	addi	a6,a6,430 # ffffffffc02b6758 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025b2:	0004b023          	sd	zero,0(s1)
ffffffffc02025b6:	b7a5                	j	ffffffffc020251e <exit_range+0x178>
ffffffffc02025b8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02025ba:	bfafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025be:	000db783          	ld	a5,0(s11)
ffffffffc02025c2:	6502                	ld	a0,0(sp)
ffffffffc02025c4:	4585                	li	a1,1
ffffffffc02025c6:	739c                	ld	a5,32(a5)
ffffffffc02025c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02025ca:	be4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025ce:	000b4717          	auipc	a4,0xb4
ffffffffc02025d2:	17a70713          	addi	a4,a4,378 # ffffffffc02b6748 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025d6:	00043023          	sd	zero,0(s0)
ffffffffc02025da:	bfb5                	j	ffffffffc0202556 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025dc:	00004697          	auipc	a3,0x4
ffffffffc02025e0:	37c68693          	addi	a3,a3,892 # ffffffffc0206958 <default_pmm_manager+0x160>
ffffffffc02025e4:	00004617          	auipc	a2,0x4
ffffffffc02025e8:	e6460613          	addi	a2,a2,-412 # ffffffffc0206448 <commands+0x860>
ffffffffc02025ec:	13500593          	li	a1,309
ffffffffc02025f0:	00004517          	auipc	a0,0x4
ffffffffc02025f4:	35850513          	addi	a0,a0,856 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02025f8:	e97fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025fc:	00004617          	auipc	a2,0x4
ffffffffc0202600:	23460613          	addi	a2,a2,564 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc0202604:	07100593          	li	a1,113
ffffffffc0202608:	00004517          	auipc	a0,0x4
ffffffffc020260c:	25050513          	addi	a0,a0,592 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0202610:	e7ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202614:	8e1ff0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202618:	00004697          	auipc	a3,0x4
ffffffffc020261c:	37068693          	addi	a3,a3,880 # ffffffffc0206988 <default_pmm_manager+0x190>
ffffffffc0202620:	00004617          	auipc	a2,0x4
ffffffffc0202624:	e2860613          	addi	a2,a2,-472 # ffffffffc0206448 <commands+0x860>
ffffffffc0202628:	13600593          	li	a1,310
ffffffffc020262c:	00004517          	auipc	a0,0x4
ffffffffc0202630:	31c50513          	addi	a0,a0,796 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202634:	e5bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202638 <page_remove>:
{
ffffffffc0202638:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020263a:	4601                	li	a2,0
{
ffffffffc020263c:	ec26                	sd	s1,24(sp)
ffffffffc020263e:	f406                	sd	ra,40(sp)
ffffffffc0202640:	f022                	sd	s0,32(sp)
ffffffffc0202642:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202644:	9a1ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
    if (ptep != NULL)
ffffffffc0202648:	c511                	beqz	a0,ffffffffc0202654 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020264a:	611c                	ld	a5,0(a0)
ffffffffc020264c:	842a                	mv	s0,a0
ffffffffc020264e:	0017f713          	andi	a4,a5,1
ffffffffc0202652:	e711                	bnez	a4,ffffffffc020265e <page_remove+0x26>
}
ffffffffc0202654:	70a2                	ld	ra,40(sp)
ffffffffc0202656:	7402                	ld	s0,32(sp)
ffffffffc0202658:	64e2                	ld	s1,24(sp)
ffffffffc020265a:	6145                	addi	sp,sp,48
ffffffffc020265c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020265e:	078a                	slli	a5,a5,0x2
ffffffffc0202660:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202662:	000b4717          	auipc	a4,0xb4
ffffffffc0202666:	0de73703          	ld	a4,222(a4) # ffffffffc02b6740 <npage>
ffffffffc020266a:	06e7f363          	bgeu	a5,a4,ffffffffc02026d0 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020266e:	fff80537          	lui	a0,0xfff80
ffffffffc0202672:	97aa                	add	a5,a5,a0
ffffffffc0202674:	079a                	slli	a5,a5,0x6
ffffffffc0202676:	000b4517          	auipc	a0,0xb4
ffffffffc020267a:	0d253503          	ld	a0,210(a0) # ffffffffc02b6748 <pages>
ffffffffc020267e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202680:	411c                	lw	a5,0(a0)
ffffffffc0202682:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202686:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202688:	cb11                	beqz	a4,ffffffffc020269c <page_remove+0x64>
        *ptep = 0;
ffffffffc020268a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020268e:	12048073          	sfence.vma	s1
}
ffffffffc0202692:	70a2                	ld	ra,40(sp)
ffffffffc0202694:	7402                	ld	s0,32(sp)
ffffffffc0202696:	64e2                	ld	s1,24(sp)
ffffffffc0202698:	6145                	addi	sp,sp,48
ffffffffc020269a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020269c:	100027f3          	csrr	a5,sstatus
ffffffffc02026a0:	8b89                	andi	a5,a5,2
ffffffffc02026a2:	eb89                	bnez	a5,ffffffffc02026b4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02026a4:	000b4797          	auipc	a5,0xb4
ffffffffc02026a8:	0ac7b783          	ld	a5,172(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc02026ac:	739c                	ld	a5,32(a5)
ffffffffc02026ae:	4585                	li	a1,1
ffffffffc02026b0:	9782                	jalr	a5
    if (flag)
ffffffffc02026b2:	bfe1                	j	ffffffffc020268a <page_remove+0x52>
        intr_disable();
ffffffffc02026b4:	e42a                	sd	a0,8(sp)
ffffffffc02026b6:	afefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02026ba:	000b4797          	auipc	a5,0xb4
ffffffffc02026be:	0967b783          	ld	a5,150(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc02026c2:	739c                	ld	a5,32(a5)
ffffffffc02026c4:	6522                	ld	a0,8(sp)
ffffffffc02026c6:	4585                	li	a1,1
ffffffffc02026c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02026ca:	ae4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026ce:	bf75                	j	ffffffffc020268a <page_remove+0x52>
ffffffffc02026d0:	825ff0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>

ffffffffc02026d4 <page_insert>:
{
ffffffffc02026d4:	7139                	addi	sp,sp,-64
ffffffffc02026d6:	e852                	sd	s4,16(sp)
ffffffffc02026d8:	8a32                	mv	s4,a2
ffffffffc02026da:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026dc:	4605                	li	a2,1
{
ffffffffc02026de:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026e0:	85d2                	mv	a1,s4
{
ffffffffc02026e2:	f426                	sd	s1,40(sp)
ffffffffc02026e4:	fc06                	sd	ra,56(sp)
ffffffffc02026e6:	f04a                	sd	s2,32(sp)
ffffffffc02026e8:	ec4e                	sd	s3,24(sp)
ffffffffc02026ea:	e456                	sd	s5,8(sp)
ffffffffc02026ec:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026ee:	8f7ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
    if (ptep == NULL)
ffffffffc02026f2:	c961                	beqz	a0,ffffffffc02027c2 <page_insert+0xee>
    page->ref += 1;
ffffffffc02026f4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026f6:	611c                	ld	a5,0(a0)
ffffffffc02026f8:	89aa                	mv	s3,a0
ffffffffc02026fa:	0016871b          	addiw	a4,a3,1
ffffffffc02026fe:	c018                	sw	a4,0(s0)
ffffffffc0202700:	0017f713          	andi	a4,a5,1
ffffffffc0202704:	ef05                	bnez	a4,ffffffffc020273c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202706:	000b4717          	auipc	a4,0xb4
ffffffffc020270a:	04273703          	ld	a4,66(a4) # ffffffffc02b6748 <pages>
ffffffffc020270e:	8c19                	sub	s0,s0,a4
ffffffffc0202710:	000807b7          	lui	a5,0x80
ffffffffc0202714:	8419                	srai	s0,s0,0x6
ffffffffc0202716:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202718:	042a                	slli	s0,s0,0xa
ffffffffc020271a:	8cc1                	or	s1,s1,s0
ffffffffc020271c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202720:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff4080>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202724:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202728:	4501                	li	a0,0
}
ffffffffc020272a:	70e2                	ld	ra,56(sp)
ffffffffc020272c:	7442                	ld	s0,48(sp)
ffffffffc020272e:	74a2                	ld	s1,40(sp)
ffffffffc0202730:	7902                	ld	s2,32(sp)
ffffffffc0202732:	69e2                	ld	s3,24(sp)
ffffffffc0202734:	6a42                	ld	s4,16(sp)
ffffffffc0202736:	6aa2                	ld	s5,8(sp)
ffffffffc0202738:	6121                	addi	sp,sp,64
ffffffffc020273a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020273c:	078a                	slli	a5,a5,0x2
ffffffffc020273e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202740:	000b4717          	auipc	a4,0xb4
ffffffffc0202744:	00073703          	ld	a4,0(a4) # ffffffffc02b6740 <npage>
ffffffffc0202748:	06e7ff63          	bgeu	a5,a4,ffffffffc02027c6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020274c:	000b4a97          	auipc	s5,0xb4
ffffffffc0202750:	ffca8a93          	addi	s5,s5,-4 # ffffffffc02b6748 <pages>
ffffffffc0202754:	000ab703          	ld	a4,0(s5)
ffffffffc0202758:	fff80937          	lui	s2,0xfff80
ffffffffc020275c:	993e                	add	s2,s2,a5
ffffffffc020275e:	091a                	slli	s2,s2,0x6
ffffffffc0202760:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202762:	01240c63          	beq	s0,s2,ffffffffc020277a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202766:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcc9884>
ffffffffc020276a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020276e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202772:	c691                	beqz	a3,ffffffffc020277e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202774:	120a0073          	sfence.vma	s4
}
ffffffffc0202778:	bf59                	j	ffffffffc020270e <page_insert+0x3a>
ffffffffc020277a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020277c:	bf49                	j	ffffffffc020270e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020277e:	100027f3          	csrr	a5,sstatus
ffffffffc0202782:	8b89                	andi	a5,a5,2
ffffffffc0202784:	ef91                	bnez	a5,ffffffffc02027a0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202786:	000b4797          	auipc	a5,0xb4
ffffffffc020278a:	fca7b783          	ld	a5,-54(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc020278e:	739c                	ld	a5,32(a5)
ffffffffc0202790:	4585                	li	a1,1
ffffffffc0202792:	854a                	mv	a0,s2
ffffffffc0202794:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202796:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020279a:	120a0073          	sfence.vma	s4
ffffffffc020279e:	bf85                	j	ffffffffc020270e <page_insert+0x3a>
        intr_disable();
ffffffffc02027a0:	a14fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027a4:	000b4797          	auipc	a5,0xb4
ffffffffc02027a8:	fac7b783          	ld	a5,-84(a5) # ffffffffc02b6750 <pmm_manager>
ffffffffc02027ac:	739c                	ld	a5,32(a5)
ffffffffc02027ae:	4585                	li	a1,1
ffffffffc02027b0:	854a                	mv	a0,s2
ffffffffc02027b2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027b4:	9fafe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027b8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027bc:	120a0073          	sfence.vma	s4
ffffffffc02027c0:	b7b9                	j	ffffffffc020270e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02027c2:	5571                	li	a0,-4
ffffffffc02027c4:	b79d                	j	ffffffffc020272a <page_insert+0x56>
ffffffffc02027c6:	f2eff0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>

ffffffffc02027ca <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027ca:	00004797          	auipc	a5,0x4
ffffffffc02027ce:	02e78793          	addi	a5,a5,46 # ffffffffc02067f8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027d2:	638c                	ld	a1,0(a5)
{
ffffffffc02027d4:	7159                	addi	sp,sp,-112
ffffffffc02027d6:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027d8:	00004517          	auipc	a0,0x4
ffffffffc02027dc:	1c850513          	addi	a0,a0,456 # ffffffffc02069a0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027e0:	000b4b17          	auipc	s6,0xb4
ffffffffc02027e4:	f70b0b13          	addi	s6,s6,-144 # ffffffffc02b6750 <pmm_manager>
{
ffffffffc02027e8:	f486                	sd	ra,104(sp)
ffffffffc02027ea:	e8ca                	sd	s2,80(sp)
ffffffffc02027ec:	e4ce                	sd	s3,72(sp)
ffffffffc02027ee:	f0a2                	sd	s0,96(sp)
ffffffffc02027f0:	eca6                	sd	s1,88(sp)
ffffffffc02027f2:	e0d2                	sd	s4,64(sp)
ffffffffc02027f4:	fc56                	sd	s5,56(sp)
ffffffffc02027f6:	f45e                	sd	s7,40(sp)
ffffffffc02027f8:	f062                	sd	s8,32(sp)
ffffffffc02027fa:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027fc:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202800:	995fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202808:	000b4997          	auipc	s3,0xb4
ffffffffc020280c:	f5098993          	addi	s3,s3,-176 # ffffffffc02b6758 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202810:	679c                	ld	a5,8(a5)
ffffffffc0202812:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202814:	57f5                	li	a5,-3
ffffffffc0202816:	07fa                	slli	a5,a5,0x1e
ffffffffc0202818:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020281c:	97efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202820:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202822:	982fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202826:	200505e3          	beqz	a0,ffffffffc0203230 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020282a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020282c:	00004517          	auipc	a0,0x4
ffffffffc0202830:	1ac50513          	addi	a0,a0,428 # ffffffffc02069d8 <default_pmm_manager+0x1e0>
ffffffffc0202834:	961fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202838:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020283c:	fff40693          	addi	a3,s0,-1
ffffffffc0202840:	864a                	mv	a2,s2
ffffffffc0202842:	85a6                	mv	a1,s1
ffffffffc0202844:	00004517          	auipc	a0,0x4
ffffffffc0202848:	1ac50513          	addi	a0,a0,428 # ffffffffc02069f0 <default_pmm_manager+0x1f8>
ffffffffc020284c:	949fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202850:	c8000737          	lui	a4,0xc8000
ffffffffc0202854:	87a2                	mv	a5,s0
ffffffffc0202856:	54876163          	bltu	a4,s0,ffffffffc0202d98 <pmm_init+0x5ce>
ffffffffc020285a:	757d                	lui	a0,0xfffff
ffffffffc020285c:	000b5617          	auipc	a2,0xb5
ffffffffc0202860:	f1f60613          	addi	a2,a2,-225 # ffffffffc02b777b <end+0xfff>
ffffffffc0202864:	8e69                	and	a2,a2,a0
ffffffffc0202866:	000b4497          	auipc	s1,0xb4
ffffffffc020286a:	eda48493          	addi	s1,s1,-294 # ffffffffc02b6740 <npage>
ffffffffc020286e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202872:	000b4b97          	auipc	s7,0xb4
ffffffffc0202876:	ed6b8b93          	addi	s7,s7,-298 # ffffffffc02b6748 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020287a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020287c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202880:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202884:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202886:	02f50863          	beq	a0,a5,ffffffffc02028b6 <pmm_init+0xec>
ffffffffc020288a:	4781                	li	a5,0
ffffffffc020288c:	4585                	li	a1,1
ffffffffc020288e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202892:	00679513          	slli	a0,a5,0x6
ffffffffc0202896:	9532                	add	a0,a0,a2
ffffffffc0202898:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd4888c>
ffffffffc020289c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028a0:	6088                	ld	a0,0(s1)
ffffffffc02028a2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02028a4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028a8:	00d50733          	add	a4,a0,a3
ffffffffc02028ac:	fee7e3e3          	bltu	a5,a4,ffffffffc0202892 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028b0:	071a                	slli	a4,a4,0x6
ffffffffc02028b2:	00e606b3          	add	a3,a2,a4
ffffffffc02028b6:	c02007b7          	lui	a5,0xc0200
ffffffffc02028ba:	2ef6ece3          	bltu	a3,a5,ffffffffc02033b2 <pmm_init+0xbe8>
ffffffffc02028be:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028c2:	77fd                	lui	a5,0xfffff
ffffffffc02028c4:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028c6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028c8:	5086eb63          	bltu	a3,s0,ffffffffc0202dde <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028cc:	00004517          	auipc	a0,0x4
ffffffffc02028d0:	14c50513          	addi	a0,a0,332 # ffffffffc0206a18 <default_pmm_manager+0x220>
ffffffffc02028d4:	8c1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028d8:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028dc:	000b4917          	auipc	s2,0xb4
ffffffffc02028e0:	e5c90913          	addi	s2,s2,-420 # ffffffffc02b6738 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028e4:	7b9c                	ld	a5,48(a5)
ffffffffc02028e6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028e8:	00004517          	auipc	a0,0x4
ffffffffc02028ec:	14850513          	addi	a0,a0,328 # ffffffffc0206a30 <default_pmm_manager+0x238>
ffffffffc02028f0:	8a5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028f4:	00007697          	auipc	a3,0x7
ffffffffc02028f8:	70c68693          	addi	a3,a3,1804 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028fc:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202900:	c02007b7          	lui	a5,0xc0200
ffffffffc0202904:	28f6ebe3          	bltu	a3,a5,ffffffffc020339a <pmm_init+0xbd0>
ffffffffc0202908:	0009b783          	ld	a5,0(s3)
ffffffffc020290c:	8e9d                	sub	a3,a3,a5
ffffffffc020290e:	000b4797          	auipc	a5,0xb4
ffffffffc0202912:	e2d7b123          	sd	a3,-478(a5) # ffffffffc02b6730 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202916:	100027f3          	csrr	a5,sstatus
ffffffffc020291a:	8b89                	andi	a5,a5,2
ffffffffc020291c:	4a079763          	bnez	a5,ffffffffc0202dca <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202920:	000b3783          	ld	a5,0(s6)
ffffffffc0202924:	779c                	ld	a5,40(a5)
ffffffffc0202926:	9782                	jalr	a5
ffffffffc0202928:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020292a:	6098                	ld	a4,0(s1)
ffffffffc020292c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202930:	83b1                	srli	a5,a5,0xc
ffffffffc0202932:	66e7e363          	bltu	a5,a4,ffffffffc0202f98 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202936:	00093503          	ld	a0,0(s2)
ffffffffc020293a:	62050f63          	beqz	a0,ffffffffc0202f78 <pmm_init+0x7ae>
ffffffffc020293e:	03451793          	slli	a5,a0,0x34
ffffffffc0202942:	62079b63          	bnez	a5,ffffffffc0202f78 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202946:	4601                	li	a2,0
ffffffffc0202948:	4581                	li	a1,0
ffffffffc020294a:	8c3ff0ef          	jal	ra,ffffffffc020220c <get_page>
ffffffffc020294e:	60051563          	bnez	a0,ffffffffc0202f58 <pmm_init+0x78e>
ffffffffc0202952:	100027f3          	csrr	a5,sstatus
ffffffffc0202956:	8b89                	andi	a5,a5,2
ffffffffc0202958:	44079e63          	bnez	a5,ffffffffc0202db4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020295c:	000b3783          	ld	a5,0(s6)
ffffffffc0202960:	4505                	li	a0,1
ffffffffc0202962:	6f9c                	ld	a5,24(a5)
ffffffffc0202964:	9782                	jalr	a5
ffffffffc0202966:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202968:	00093503          	ld	a0,0(s2)
ffffffffc020296c:	4681                	li	a3,0
ffffffffc020296e:	4601                	li	a2,0
ffffffffc0202970:	85d2                	mv	a1,s4
ffffffffc0202972:	d63ff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0202976:	26051ae3          	bnez	a0,ffffffffc02033ea <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020297a:	00093503          	ld	a0,0(s2)
ffffffffc020297e:	4601                	li	a2,0
ffffffffc0202980:	4581                	li	a1,0
ffffffffc0202982:	e62ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc0202986:	240502e3          	beqz	a0,ffffffffc02033ca <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020298a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020298c:	0017f713          	andi	a4,a5,1
ffffffffc0202990:	5a070263          	beqz	a4,ffffffffc0202f34 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202994:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202996:	078a                	slli	a5,a5,0x2
ffffffffc0202998:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020299a:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020299e:	000bb683          	ld	a3,0(s7)
ffffffffc02029a2:	fff80637          	lui	a2,0xfff80
ffffffffc02029a6:	97b2                	add	a5,a5,a2
ffffffffc02029a8:	079a                	slli	a5,a5,0x6
ffffffffc02029aa:	97b6                	add	a5,a5,a3
ffffffffc02029ac:	14fa17e3          	bne	s4,a5,ffffffffc02032fa <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02029b0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc02029b4:	4785                	li	a5,1
ffffffffc02029b6:	12f692e3          	bne	a3,a5,ffffffffc02032da <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029ba:	00093503          	ld	a0,0(s2)
ffffffffc02029be:	77fd                	lui	a5,0xfffff
ffffffffc02029c0:	6114                	ld	a3,0(a0)
ffffffffc02029c2:	068a                	slli	a3,a3,0x2
ffffffffc02029c4:	8efd                	and	a3,a3,a5
ffffffffc02029c6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029ca:	0ee67ce3          	bgeu	a2,a4,ffffffffc02032c2 <pmm_init+0xaf8>
ffffffffc02029ce:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029d2:	96e2                	add	a3,a3,s8
ffffffffc02029d4:	0006ba83          	ld	s5,0(a3)
ffffffffc02029d8:	0a8a                	slli	s5,s5,0x2
ffffffffc02029da:	00fafab3          	and	s5,s5,a5
ffffffffc02029de:	00cad793          	srli	a5,s5,0xc
ffffffffc02029e2:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02032a8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e6:	4601                	li	a2,0
ffffffffc02029e8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ea:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029ec:	df8ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029f0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029f2:	55551363          	bne	a0,s5,ffffffffc0202f38 <pmm_init+0x76e>
ffffffffc02029f6:	100027f3          	csrr	a5,sstatus
ffffffffc02029fa:	8b89                	andi	a5,a5,2
ffffffffc02029fc:	3a079163          	bnez	a5,ffffffffc0202d9e <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a00:	000b3783          	ld	a5,0(s6)
ffffffffc0202a04:	4505                	li	a0,1
ffffffffc0202a06:	6f9c                	ld	a5,24(a5)
ffffffffc0202a08:	9782                	jalr	a5
ffffffffc0202a0a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a0c:	00093503          	ld	a0,0(s2)
ffffffffc0202a10:	46d1                	li	a3,20
ffffffffc0202a12:	6605                	lui	a2,0x1
ffffffffc0202a14:	85e2                	mv	a1,s8
ffffffffc0202a16:	cbfff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0202a1a:	060517e3          	bnez	a0,ffffffffc0203288 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a1e:	00093503          	ld	a0,0(s2)
ffffffffc0202a22:	4601                	li	a2,0
ffffffffc0202a24:	6585                	lui	a1,0x1
ffffffffc0202a26:	dbeff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc0202a2a:	02050fe3          	beqz	a0,ffffffffc0203268 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a2e:	611c                	ld	a5,0(a0)
ffffffffc0202a30:	0107f713          	andi	a4,a5,16
ffffffffc0202a34:	7c070e63          	beqz	a4,ffffffffc0203210 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a38:	8b91                	andi	a5,a5,4
ffffffffc0202a3a:	7a078b63          	beqz	a5,ffffffffc02031f0 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a3e:	00093503          	ld	a0,0(s2)
ffffffffc0202a42:	611c                	ld	a5,0(a0)
ffffffffc0202a44:	8bc1                	andi	a5,a5,16
ffffffffc0202a46:	78078563          	beqz	a5,ffffffffc02031d0 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a4a:	000c2703          	lw	a4,0(s8)
ffffffffc0202a4e:	4785                	li	a5,1
ffffffffc0202a50:	76f71063          	bne	a4,a5,ffffffffc02031b0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a54:	4681                	li	a3,0
ffffffffc0202a56:	6605                	lui	a2,0x1
ffffffffc0202a58:	85d2                	mv	a1,s4
ffffffffc0202a5a:	c7bff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0202a5e:	72051963          	bnez	a0,ffffffffc0203190 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a62:	000a2703          	lw	a4,0(s4)
ffffffffc0202a66:	4789                	li	a5,2
ffffffffc0202a68:	70f71463          	bne	a4,a5,ffffffffc0203170 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a6c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a70:	6e079063          	bnez	a5,ffffffffc0203150 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a74:	00093503          	ld	a0,0(s2)
ffffffffc0202a78:	4601                	li	a2,0
ffffffffc0202a7a:	6585                	lui	a1,0x1
ffffffffc0202a7c:	d68ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc0202a80:	6a050863          	beqz	a0,ffffffffc0203130 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a84:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a86:	00177793          	andi	a5,a4,1
ffffffffc0202a8a:	4a078563          	beqz	a5,ffffffffc0202f34 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a8e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a90:	00271793          	slli	a5,a4,0x2
ffffffffc0202a94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a96:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a9e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202aa2:	97d6                	add	a5,a5,s5
ffffffffc0202aa4:	079a                	slli	a5,a5,0x6
ffffffffc0202aa6:	97b6                	add	a5,a5,a3
ffffffffc0202aa8:	66fa1463          	bne	s4,a5,ffffffffc0203110 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202aac:	8b41                	andi	a4,a4,16
ffffffffc0202aae:	64071163          	bnez	a4,ffffffffc02030f0 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202ab2:	00093503          	ld	a0,0(s2)
ffffffffc0202ab6:	4581                	li	a1,0
ffffffffc0202ab8:	b81ff0ef          	jal	ra,ffffffffc0202638 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202abc:	000a2c83          	lw	s9,0(s4)
ffffffffc0202ac0:	4785                	li	a5,1
ffffffffc0202ac2:	60fc9763          	bne	s9,a5,ffffffffc02030d0 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202ac6:	000c2783          	lw	a5,0(s8)
ffffffffc0202aca:	5e079363          	bnez	a5,ffffffffc02030b0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202ace:	00093503          	ld	a0,0(s2)
ffffffffc0202ad2:	6585                	lui	a1,0x1
ffffffffc0202ad4:	b65ff0ef          	jal	ra,ffffffffc0202638 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202ad8:	000a2783          	lw	a5,0(s4)
ffffffffc0202adc:	52079a63          	bnez	a5,ffffffffc0203010 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202ae0:	000c2783          	lw	a5,0(s8)
ffffffffc0202ae4:	50079663          	bnez	a5,ffffffffc0202ff0 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202ae8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202aec:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aee:	000a3683          	ld	a3,0(s4)
ffffffffc0202af2:	068a                	slli	a3,a3,0x2
ffffffffc0202af4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202af6:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202afa:	000bb503          	ld	a0,0(s7)
ffffffffc0202afe:	96d6                	add	a3,a3,s5
ffffffffc0202b00:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202b02:	00d507b3          	add	a5,a0,a3
ffffffffc0202b06:	439c                	lw	a5,0(a5)
ffffffffc0202b08:	4d979463          	bne	a5,s9,ffffffffc0202fd0 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202b0c:	8699                	srai	a3,a3,0x6
ffffffffc0202b0e:	00080637          	lui	a2,0x80
ffffffffc0202b12:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202b14:	00c69713          	slli	a4,a3,0xc
ffffffffc0202b18:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b1a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b1c:	48b77e63          	bgeu	a4,a1,ffffffffc0202fb8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b20:	0009b703          	ld	a4,0(s3)
ffffffffc0202b24:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b26:	629c                	ld	a5,0(a3)
ffffffffc0202b28:	078a                	slli	a5,a5,0x2
ffffffffc0202b2a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b2c:	40b7f263          	bgeu	a5,a1,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b30:	8f91                	sub	a5,a5,a2
ffffffffc0202b32:	079a                	slli	a5,a5,0x6
ffffffffc0202b34:	953e                	add	a0,a0,a5
ffffffffc0202b36:	100027f3          	csrr	a5,sstatus
ffffffffc0202b3a:	8b89                	andi	a5,a5,2
ffffffffc0202b3c:	30079963          	bnez	a5,ffffffffc0202e4e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b40:	000b3783          	ld	a5,0(s6)
ffffffffc0202b44:	4585                	li	a1,1
ffffffffc0202b46:	739c                	ld	a5,32(a5)
ffffffffc0202b48:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b4a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b4e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b50:	078a                	slli	a5,a5,0x2
ffffffffc0202b52:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b54:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b58:	000bb503          	ld	a0,0(s7)
ffffffffc0202b5c:	fff80737          	lui	a4,0xfff80
ffffffffc0202b60:	97ba                	add	a5,a5,a4
ffffffffc0202b62:	079a                	slli	a5,a5,0x6
ffffffffc0202b64:	953e                	add	a0,a0,a5
ffffffffc0202b66:	100027f3          	csrr	a5,sstatus
ffffffffc0202b6a:	8b89                	andi	a5,a5,2
ffffffffc0202b6c:	2c079563          	bnez	a5,ffffffffc0202e36 <pmm_init+0x66c>
ffffffffc0202b70:	000b3783          	ld	a5,0(s6)
ffffffffc0202b74:	4585                	li	a1,1
ffffffffc0202b76:	739c                	ld	a5,32(a5)
ffffffffc0202b78:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b7a:	00093783          	ld	a5,0(s2)
ffffffffc0202b7e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd48884>
    asm volatile("sfence.vma");
ffffffffc0202b82:	12000073          	sfence.vma
ffffffffc0202b86:	100027f3          	csrr	a5,sstatus
ffffffffc0202b8a:	8b89                	andi	a5,a5,2
ffffffffc0202b8c:	28079b63          	bnez	a5,ffffffffc0202e22 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b90:	000b3783          	ld	a5,0(s6)
ffffffffc0202b94:	779c                	ld	a5,40(a5)
ffffffffc0202b96:	9782                	jalr	a5
ffffffffc0202b98:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b9a:	4b441b63          	bne	s0,s4,ffffffffc0203050 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b9e:	00004517          	auipc	a0,0x4
ffffffffc0202ba2:	1ba50513          	addi	a0,a0,442 # ffffffffc0206d58 <default_pmm_manager+0x560>
ffffffffc0202ba6:	deefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202baa:	100027f3          	csrr	a5,sstatus
ffffffffc0202bae:	8b89                	andi	a5,a5,2
ffffffffc0202bb0:	24079f63          	bnez	a5,ffffffffc0202e0e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb8:	779c                	ld	a5,40(a5)
ffffffffc0202bba:	9782                	jalr	a5
ffffffffc0202bbc:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bbe:	6098                	ld	a4,0(s1)
ffffffffc0202bc0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bc4:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bc6:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bca:	6a05                	lui	s4,0x1
ffffffffc0202bcc:	02f47c63          	bgeu	s0,a5,ffffffffc0202c04 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bd0:	00c45793          	srli	a5,s0,0xc
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202ed6 <pmm_init+0x70c>
ffffffffc0202bdc:	0009b583          	ld	a1,0(s3)
ffffffffc0202be0:	4601                	li	a2,0
ffffffffc0202be2:	95a2                	add	a1,a1,s0
ffffffffc0202be4:	c00ff0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc0202be8:	32050463          	beqz	a0,ffffffffc0202f10 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bec:	611c                	ld	a5,0(a0)
ffffffffc0202bee:	078a                	slli	a5,a5,0x2
ffffffffc0202bf0:	0157f7b3          	and	a5,a5,s5
ffffffffc0202bf4:	2e879e63          	bne	a5,s0,ffffffffc0202ef0 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bf8:	6098                	ld	a4,0(s1)
ffffffffc0202bfa:	9452                	add	s0,s0,s4
ffffffffc0202bfc:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c00:	fcf468e3          	bltu	s0,a5,ffffffffc0202bd0 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c04:	00093783          	ld	a5,0(s2)
ffffffffc0202c08:	639c                	ld	a5,0(a5)
ffffffffc0202c0a:	42079363          	bnez	a5,ffffffffc0203030 <pmm_init+0x866>
ffffffffc0202c0e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c12:	8b89                	andi	a5,a5,2
ffffffffc0202c14:	24079963          	bnez	a5,ffffffffc0202e66 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c18:	000b3783          	ld	a5,0(s6)
ffffffffc0202c1c:	4505                	li	a0,1
ffffffffc0202c1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202c20:	9782                	jalr	a5
ffffffffc0202c22:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c24:	00093503          	ld	a0,0(s2)
ffffffffc0202c28:	4699                	li	a3,6
ffffffffc0202c2a:	10000613          	li	a2,256
ffffffffc0202c2e:	85d2                	mv	a1,s4
ffffffffc0202c30:	aa5ff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0202c34:	44051e63          	bnez	a0,ffffffffc0203090 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c38:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202c3c:	4785                	li	a5,1
ffffffffc0202c3e:	42f71963          	bne	a4,a5,ffffffffc0203070 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c42:	00093503          	ld	a0,0(s2)
ffffffffc0202c46:	6405                	lui	s0,0x1
ffffffffc0202c48:	4699                	li	a3,6
ffffffffc0202c4a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc0202c4e:	85d2                	mv	a1,s4
ffffffffc0202c50:	a85ff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0202c54:	72051363          	bnez	a0,ffffffffc020337a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c58:	000a2703          	lw	a4,0(s4)
ffffffffc0202c5c:	4789                	li	a5,2
ffffffffc0202c5e:	6ef71e63          	bne	a4,a5,ffffffffc020335a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c62:	00004597          	auipc	a1,0x4
ffffffffc0202c66:	23e58593          	addi	a1,a1,574 # ffffffffc0206ea0 <default_pmm_manager+0x6a8>
ffffffffc0202c6a:	10000513          	li	a0,256
ffffffffc0202c6e:	477020ef          	jal	ra,ffffffffc02058e4 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c72:	10040593          	addi	a1,s0,256
ffffffffc0202c76:	10000513          	li	a0,256
ffffffffc0202c7a:	47d020ef          	jal	ra,ffffffffc02058f6 <strcmp>
ffffffffc0202c7e:	6a051e63          	bnez	a0,ffffffffc020333a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c82:	000bb683          	ld	a3,0(s7)
ffffffffc0202c86:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c8a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c8c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c90:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c92:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c94:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c96:	8031                	srli	s0,s0,0xc
ffffffffc0202c98:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c9c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c9e:	30f77d63          	bgeu	a4,a5,ffffffffc0202fb8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ca2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202caa:	96be                	add	a3,a3,a5
ffffffffc0202cac:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cb0:	3ff020ef          	jal	ra,ffffffffc02058ae <strlen>
ffffffffc0202cb4:	66051363          	bnez	a0,ffffffffc020331a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cb8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cbc:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cbe:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd48884>
ffffffffc0202cc2:	068a                	slli	a3,a3,0x2
ffffffffc0202cc4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cc6:	26f6f563          	bgeu	a3,a5,ffffffffc0202f30 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202cca:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ccc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cce:	2ef47563          	bgeu	s0,a5,ffffffffc0202fb8 <pmm_init+0x7ee>
ffffffffc0202cd2:	0009b403          	ld	s0,0(s3)
ffffffffc0202cd6:	9436                	add	s0,s0,a3
ffffffffc0202cd8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cdc:	8b89                	andi	a5,a5,2
ffffffffc0202cde:	1e079163          	bnez	a5,ffffffffc0202ec0 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202ce2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce6:	4585                	li	a1,1
ffffffffc0202ce8:	8552                	mv	a0,s4
ffffffffc0202cea:	739c                	ld	a5,32(a5)
ffffffffc0202cec:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cee:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202cf0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cf2:	078a                	slli	a5,a5,0x2
ffffffffc0202cf4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cf6:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cfa:	000bb503          	ld	a0,0(s7)
ffffffffc0202cfe:	fff80737          	lui	a4,0xfff80
ffffffffc0202d02:	97ba                	add	a5,a5,a4
ffffffffc0202d04:	079a                	slli	a5,a5,0x6
ffffffffc0202d06:	953e                	add	a0,a0,a5
ffffffffc0202d08:	100027f3          	csrr	a5,sstatus
ffffffffc0202d0c:	8b89                	andi	a5,a5,2
ffffffffc0202d0e:	18079d63          	bnez	a5,ffffffffc0202ea8 <pmm_init+0x6de>
ffffffffc0202d12:	000b3783          	ld	a5,0(s6)
ffffffffc0202d16:	4585                	li	a1,1
ffffffffc0202d18:	739c                	ld	a5,32(a5)
ffffffffc0202d1a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d1c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202d20:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d22:	078a                	slli	a5,a5,0x2
ffffffffc0202d24:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d26:	20e7f563          	bgeu	a5,a4,ffffffffc0202f30 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d2a:	000bb503          	ld	a0,0(s7)
ffffffffc0202d2e:	fff80737          	lui	a4,0xfff80
ffffffffc0202d32:	97ba                	add	a5,a5,a4
ffffffffc0202d34:	079a                	slli	a5,a5,0x6
ffffffffc0202d36:	953e                	add	a0,a0,a5
ffffffffc0202d38:	100027f3          	csrr	a5,sstatus
ffffffffc0202d3c:	8b89                	andi	a5,a5,2
ffffffffc0202d3e:	14079963          	bnez	a5,ffffffffc0202e90 <pmm_init+0x6c6>
ffffffffc0202d42:	000b3783          	ld	a5,0(s6)
ffffffffc0202d46:	4585                	li	a1,1
ffffffffc0202d48:	739c                	ld	a5,32(a5)
ffffffffc0202d4a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d4c:	00093783          	ld	a5,0(s2)
ffffffffc0202d50:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d54:	12000073          	sfence.vma
ffffffffc0202d58:	100027f3          	csrr	a5,sstatus
ffffffffc0202d5c:	8b89                	andi	a5,a5,2
ffffffffc0202d5e:	10079f63          	bnez	a5,ffffffffc0202e7c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d62:	000b3783          	ld	a5,0(s6)
ffffffffc0202d66:	779c                	ld	a5,40(a5)
ffffffffc0202d68:	9782                	jalr	a5
ffffffffc0202d6a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d6c:	4c8c1e63          	bne	s8,s0,ffffffffc0203248 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d70:	00004517          	auipc	a0,0x4
ffffffffc0202d74:	1a850513          	addi	a0,a0,424 # ffffffffc0206f18 <default_pmm_manager+0x720>
ffffffffc0202d78:	c1cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d7c:	7406                	ld	s0,96(sp)
ffffffffc0202d7e:	70a6                	ld	ra,104(sp)
ffffffffc0202d80:	64e6                	ld	s1,88(sp)
ffffffffc0202d82:	6946                	ld	s2,80(sp)
ffffffffc0202d84:	69a6                	ld	s3,72(sp)
ffffffffc0202d86:	6a06                	ld	s4,64(sp)
ffffffffc0202d88:	7ae2                	ld	s5,56(sp)
ffffffffc0202d8a:	7b42                	ld	s6,48(sp)
ffffffffc0202d8c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d8e:	7c02                	ld	s8,32(sp)
ffffffffc0202d90:	6ce2                	ld	s9,24(sp)
ffffffffc0202d92:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d94:	f97fe06f          	j	ffffffffc0201d2a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d98:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d9c:	bc7d                	j	ffffffffc020285a <pmm_init+0x90>
        intr_disable();
ffffffffc0202d9e:	c17fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202da2:	000b3783          	ld	a5,0(s6)
ffffffffc0202da6:	4505                	li	a0,1
ffffffffc0202da8:	6f9c                	ld	a5,24(a5)
ffffffffc0202daa:	9782                	jalr	a5
ffffffffc0202dac:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dae:	c01fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202db2:	b9a9                	j	ffffffffc0202a0c <pmm_init+0x242>
        intr_disable();
ffffffffc0202db4:	c01fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202db8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dbc:	4505                	li	a0,1
ffffffffc0202dbe:	6f9c                	ld	a5,24(a5)
ffffffffc0202dc0:	9782                	jalr	a5
ffffffffc0202dc2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc4:	bebfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc8:	b645                	j	ffffffffc0202968 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202dca:	bebfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dce:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd2:	779c                	ld	a5,40(a5)
ffffffffc0202dd4:	9782                	jalr	a5
ffffffffc0202dd6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dd8:	bd7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ddc:	b6b9                	j	ffffffffc020292a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dde:	6705                	lui	a4,0x1
ffffffffc0202de0:	177d                	addi	a4,a4,-1
ffffffffc0202de2:	96ba                	add	a3,a3,a4
ffffffffc0202de4:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202de6:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dea:	14a77363          	bgeu	a4,a0,ffffffffc0202f30 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dee:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202df2:	fff80537          	lui	a0,0xfff80
ffffffffc0202df6:	972a                	add	a4,a4,a0
ffffffffc0202df8:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202dfa:	8c1d                	sub	s0,s0,a5
ffffffffc0202dfc:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202e00:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e04:	9532                	add	a0,a0,a2
ffffffffc0202e06:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e08:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e0c:	b4c1                	j	ffffffffc02028cc <pmm_init+0x102>
        intr_disable();
ffffffffc0202e0e:	ba7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e12:	000b3783          	ld	a5,0(s6)
ffffffffc0202e16:	779c                	ld	a5,40(a5)
ffffffffc0202e18:	9782                	jalr	a5
ffffffffc0202e1a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e1c:	b93fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e20:	bb79                	j	ffffffffc0202bbe <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e22:	b93fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e26:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2a:	779c                	ld	a5,40(a5)
ffffffffc0202e2c:	9782                	jalr	a5
ffffffffc0202e2e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e30:	b7ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e34:	b39d                	j	ffffffffc0202b9a <pmm_init+0x3d0>
ffffffffc0202e36:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e38:	b7dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e3c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e40:	6522                	ld	a0,8(sp)
ffffffffc0202e42:	4585                	li	a1,1
ffffffffc0202e44:	739c                	ld	a5,32(a5)
ffffffffc0202e46:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e48:	b67fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e4c:	b33d                	j	ffffffffc0202b7a <pmm_init+0x3b0>
ffffffffc0202e4e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e50:	b65fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e54:	000b3783          	ld	a5,0(s6)
ffffffffc0202e58:	6522                	ld	a0,8(sp)
ffffffffc0202e5a:	4585                	li	a1,1
ffffffffc0202e5c:	739c                	ld	a5,32(a5)
ffffffffc0202e5e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e60:	b4ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e64:	b1dd                	j	ffffffffc0202b4a <pmm_init+0x380>
        intr_disable();
ffffffffc0202e66:	b4ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e6e:	4505                	li	a0,1
ffffffffc0202e70:	6f9c                	ld	a5,24(a5)
ffffffffc0202e72:	9782                	jalr	a5
ffffffffc0202e74:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e76:	b39fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e7a:	b36d                	j	ffffffffc0202c24 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e7c:	b39fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e80:	000b3783          	ld	a5,0(s6)
ffffffffc0202e84:	779c                	ld	a5,40(a5)
ffffffffc0202e86:	9782                	jalr	a5
ffffffffc0202e88:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e8a:	b25fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e8e:	bdf9                	j	ffffffffc0202d6c <pmm_init+0x5a2>
ffffffffc0202e90:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e92:	b23fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e96:	000b3783          	ld	a5,0(s6)
ffffffffc0202e9a:	6522                	ld	a0,8(sp)
ffffffffc0202e9c:	4585                	li	a1,1
ffffffffc0202e9e:	739c                	ld	a5,32(a5)
ffffffffc0202ea0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ea2:	b0dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ea6:	b55d                	j	ffffffffc0202d4c <pmm_init+0x582>
ffffffffc0202ea8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202eaa:	b0bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202eae:	000b3783          	ld	a5,0(s6)
ffffffffc0202eb2:	6522                	ld	a0,8(sp)
ffffffffc0202eb4:	4585                	li	a1,1
ffffffffc0202eb6:	739c                	ld	a5,32(a5)
ffffffffc0202eb8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eba:	af5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ebe:	bdb9                	j	ffffffffc0202d1c <pmm_init+0x552>
        intr_disable();
ffffffffc0202ec0:	af5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ec4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec8:	4585                	li	a1,1
ffffffffc0202eca:	8552                	mv	a0,s4
ffffffffc0202ecc:	739c                	ld	a5,32(a5)
ffffffffc0202ece:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ed0:	adffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ed4:	bd29                	j	ffffffffc0202cee <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ed6:	86a2                	mv	a3,s0
ffffffffc0202ed8:	00004617          	auipc	a2,0x4
ffffffffc0202edc:	95860613          	addi	a2,a2,-1704 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc0202ee0:	24900593          	li	a1,585
ffffffffc0202ee4:	00004517          	auipc	a0,0x4
ffffffffc0202ee8:	a6450513          	addi	a0,a0,-1436 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202eec:	da2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ef0:	00004697          	auipc	a3,0x4
ffffffffc0202ef4:	ec868693          	addi	a3,a3,-312 # ffffffffc0206db8 <default_pmm_manager+0x5c0>
ffffffffc0202ef8:	00003617          	auipc	a2,0x3
ffffffffc0202efc:	55060613          	addi	a2,a2,1360 # ffffffffc0206448 <commands+0x860>
ffffffffc0202f00:	24a00593          	li	a1,586
ffffffffc0202f04:	00004517          	auipc	a0,0x4
ffffffffc0202f08:	a4450513          	addi	a0,a0,-1468 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202f0c:	d82fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f10:	00004697          	auipc	a3,0x4
ffffffffc0202f14:	e6868693          	addi	a3,a3,-408 # ffffffffc0206d78 <default_pmm_manager+0x580>
ffffffffc0202f18:	00003617          	auipc	a2,0x3
ffffffffc0202f1c:	53060613          	addi	a2,a2,1328 # ffffffffc0206448 <commands+0x860>
ffffffffc0202f20:	24900593          	li	a1,585
ffffffffc0202f24:	00004517          	auipc	a0,0x4
ffffffffc0202f28:	a2450513          	addi	a0,a0,-1500 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202f2c:	d62fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202f30:	fc5fe0ef          	jal	ra,ffffffffc0201ef4 <pa2page.part.0>
ffffffffc0202f34:	fddfe0ef          	jal	ra,ffffffffc0201f10 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f38:	00004697          	auipc	a3,0x4
ffffffffc0202f3c:	c3868693          	addi	a3,a3,-968 # ffffffffc0206b70 <default_pmm_manager+0x378>
ffffffffc0202f40:	00003617          	auipc	a2,0x3
ffffffffc0202f44:	50860613          	addi	a2,a2,1288 # ffffffffc0206448 <commands+0x860>
ffffffffc0202f48:	21900593          	li	a1,537
ffffffffc0202f4c:	00004517          	auipc	a0,0x4
ffffffffc0202f50:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202f54:	d3afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f58:	00004697          	auipc	a3,0x4
ffffffffc0202f5c:	b5868693          	addi	a3,a3,-1192 # ffffffffc0206ab0 <default_pmm_manager+0x2b8>
ffffffffc0202f60:	00003617          	auipc	a2,0x3
ffffffffc0202f64:	4e860613          	addi	a2,a2,1256 # ffffffffc0206448 <commands+0x860>
ffffffffc0202f68:	20c00593          	li	a1,524
ffffffffc0202f6c:	00004517          	auipc	a0,0x4
ffffffffc0202f70:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202f74:	d1afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f78:	00004697          	auipc	a3,0x4
ffffffffc0202f7c:	af868693          	addi	a3,a3,-1288 # ffffffffc0206a70 <default_pmm_manager+0x278>
ffffffffc0202f80:	00003617          	auipc	a2,0x3
ffffffffc0202f84:	4c860613          	addi	a2,a2,1224 # ffffffffc0206448 <commands+0x860>
ffffffffc0202f88:	20b00593          	li	a1,523
ffffffffc0202f8c:	00004517          	auipc	a0,0x4
ffffffffc0202f90:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202f94:	cfafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f98:	00004697          	auipc	a3,0x4
ffffffffc0202f9c:	ab868693          	addi	a3,a3,-1352 # ffffffffc0206a50 <default_pmm_manager+0x258>
ffffffffc0202fa0:	00003617          	auipc	a2,0x3
ffffffffc0202fa4:	4a860613          	addi	a2,a2,1192 # ffffffffc0206448 <commands+0x860>
ffffffffc0202fa8:	20a00593          	li	a1,522
ffffffffc0202fac:	00004517          	auipc	a0,0x4
ffffffffc0202fb0:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202fb4:	cdafd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fb8:	00004617          	auipc	a2,0x4
ffffffffc0202fbc:	87860613          	addi	a2,a2,-1928 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc0202fc0:	07100593          	li	a1,113
ffffffffc0202fc4:	00004517          	auipc	a0,0x4
ffffffffc0202fc8:	89450513          	addi	a0,a0,-1900 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0202fcc:	cc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fd0:	00004697          	auipc	a3,0x4
ffffffffc0202fd4:	d3068693          	addi	a3,a3,-720 # ffffffffc0206d00 <default_pmm_manager+0x508>
ffffffffc0202fd8:	00003617          	auipc	a2,0x3
ffffffffc0202fdc:	47060613          	addi	a2,a2,1136 # ffffffffc0206448 <commands+0x860>
ffffffffc0202fe0:	23200593          	li	a1,562
ffffffffc0202fe4:	00004517          	auipc	a0,0x4
ffffffffc0202fe8:	96450513          	addi	a0,a0,-1692 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0202fec:	ca2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ff0:	00004697          	auipc	a3,0x4
ffffffffc0202ff4:	cc868693          	addi	a3,a3,-824 # ffffffffc0206cb8 <default_pmm_manager+0x4c0>
ffffffffc0202ff8:	00003617          	auipc	a2,0x3
ffffffffc0202ffc:	45060613          	addi	a2,a2,1104 # ffffffffc0206448 <commands+0x860>
ffffffffc0203000:	23000593          	li	a1,560
ffffffffc0203004:	00004517          	auipc	a0,0x4
ffffffffc0203008:	94450513          	addi	a0,a0,-1724 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020300c:	c82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203010:	00004697          	auipc	a3,0x4
ffffffffc0203014:	cd868693          	addi	a3,a3,-808 # ffffffffc0206ce8 <default_pmm_manager+0x4f0>
ffffffffc0203018:	00003617          	auipc	a2,0x3
ffffffffc020301c:	43060613          	addi	a2,a2,1072 # ffffffffc0206448 <commands+0x860>
ffffffffc0203020:	22f00593          	li	a1,559
ffffffffc0203024:	00004517          	auipc	a0,0x4
ffffffffc0203028:	92450513          	addi	a0,a0,-1756 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020302c:	c62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203030:	00004697          	auipc	a3,0x4
ffffffffc0203034:	da068693          	addi	a3,a3,-608 # ffffffffc0206dd0 <default_pmm_manager+0x5d8>
ffffffffc0203038:	00003617          	auipc	a2,0x3
ffffffffc020303c:	41060613          	addi	a2,a2,1040 # ffffffffc0206448 <commands+0x860>
ffffffffc0203040:	24d00593          	li	a1,589
ffffffffc0203044:	00004517          	auipc	a0,0x4
ffffffffc0203048:	90450513          	addi	a0,a0,-1788 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020304c:	c42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203050:	00004697          	auipc	a3,0x4
ffffffffc0203054:	ce068693          	addi	a3,a3,-800 # ffffffffc0206d30 <default_pmm_manager+0x538>
ffffffffc0203058:	00003617          	auipc	a2,0x3
ffffffffc020305c:	3f060613          	addi	a2,a2,1008 # ffffffffc0206448 <commands+0x860>
ffffffffc0203060:	23a00593          	li	a1,570
ffffffffc0203064:	00004517          	auipc	a0,0x4
ffffffffc0203068:	8e450513          	addi	a0,a0,-1820 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020306c:	c22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203070:	00004697          	auipc	a3,0x4
ffffffffc0203074:	db868693          	addi	a3,a3,-584 # ffffffffc0206e28 <default_pmm_manager+0x630>
ffffffffc0203078:	00003617          	auipc	a2,0x3
ffffffffc020307c:	3d060613          	addi	a2,a2,976 # ffffffffc0206448 <commands+0x860>
ffffffffc0203080:	25200593          	li	a1,594
ffffffffc0203084:	00004517          	auipc	a0,0x4
ffffffffc0203088:	8c450513          	addi	a0,a0,-1852 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020308c:	c02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203090:	00004697          	auipc	a3,0x4
ffffffffc0203094:	d5868693          	addi	a3,a3,-680 # ffffffffc0206de8 <default_pmm_manager+0x5f0>
ffffffffc0203098:	00003617          	auipc	a2,0x3
ffffffffc020309c:	3b060613          	addi	a2,a2,944 # ffffffffc0206448 <commands+0x860>
ffffffffc02030a0:	25100593          	li	a1,593
ffffffffc02030a4:	00004517          	auipc	a0,0x4
ffffffffc02030a8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02030ac:	be2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030b0:	00004697          	auipc	a3,0x4
ffffffffc02030b4:	c0868693          	addi	a3,a3,-1016 # ffffffffc0206cb8 <default_pmm_manager+0x4c0>
ffffffffc02030b8:	00003617          	auipc	a2,0x3
ffffffffc02030bc:	39060613          	addi	a2,a2,912 # ffffffffc0206448 <commands+0x860>
ffffffffc02030c0:	22c00593          	li	a1,556
ffffffffc02030c4:	00004517          	auipc	a0,0x4
ffffffffc02030c8:	88450513          	addi	a0,a0,-1916 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02030cc:	bc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030d0:	00004697          	auipc	a3,0x4
ffffffffc02030d4:	a8868693          	addi	a3,a3,-1400 # ffffffffc0206b58 <default_pmm_manager+0x360>
ffffffffc02030d8:	00003617          	auipc	a2,0x3
ffffffffc02030dc:	37060613          	addi	a2,a2,880 # ffffffffc0206448 <commands+0x860>
ffffffffc02030e0:	22b00593          	li	a1,555
ffffffffc02030e4:	00004517          	auipc	a0,0x4
ffffffffc02030e8:	86450513          	addi	a0,a0,-1948 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02030ec:	ba2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030f0:	00004697          	auipc	a3,0x4
ffffffffc02030f4:	be068693          	addi	a3,a3,-1056 # ffffffffc0206cd0 <default_pmm_manager+0x4d8>
ffffffffc02030f8:	00003617          	auipc	a2,0x3
ffffffffc02030fc:	35060613          	addi	a2,a2,848 # ffffffffc0206448 <commands+0x860>
ffffffffc0203100:	22800593          	li	a1,552
ffffffffc0203104:	00004517          	auipc	a0,0x4
ffffffffc0203108:	84450513          	addi	a0,a0,-1980 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020310c:	b82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203110:	00004697          	auipc	a3,0x4
ffffffffc0203114:	a3068693          	addi	a3,a3,-1488 # ffffffffc0206b40 <default_pmm_manager+0x348>
ffffffffc0203118:	00003617          	auipc	a2,0x3
ffffffffc020311c:	33060613          	addi	a2,a2,816 # ffffffffc0206448 <commands+0x860>
ffffffffc0203120:	22700593          	li	a1,551
ffffffffc0203124:	00004517          	auipc	a0,0x4
ffffffffc0203128:	82450513          	addi	a0,a0,-2012 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020312c:	b62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203130:	00004697          	auipc	a3,0x4
ffffffffc0203134:	ab068693          	addi	a3,a3,-1360 # ffffffffc0206be0 <default_pmm_manager+0x3e8>
ffffffffc0203138:	00003617          	auipc	a2,0x3
ffffffffc020313c:	31060613          	addi	a2,a2,784 # ffffffffc0206448 <commands+0x860>
ffffffffc0203140:	22600593          	li	a1,550
ffffffffc0203144:	00004517          	auipc	a0,0x4
ffffffffc0203148:	80450513          	addi	a0,a0,-2044 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020314c:	b42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203150:	00004697          	auipc	a3,0x4
ffffffffc0203154:	b6868693          	addi	a3,a3,-1176 # ffffffffc0206cb8 <default_pmm_manager+0x4c0>
ffffffffc0203158:	00003617          	auipc	a2,0x3
ffffffffc020315c:	2f060613          	addi	a2,a2,752 # ffffffffc0206448 <commands+0x860>
ffffffffc0203160:	22500593          	li	a1,549
ffffffffc0203164:	00003517          	auipc	a0,0x3
ffffffffc0203168:	7e450513          	addi	a0,a0,2020 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020316c:	b22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203170:	00004697          	auipc	a3,0x4
ffffffffc0203174:	b3068693          	addi	a3,a3,-1232 # ffffffffc0206ca0 <default_pmm_manager+0x4a8>
ffffffffc0203178:	00003617          	auipc	a2,0x3
ffffffffc020317c:	2d060613          	addi	a2,a2,720 # ffffffffc0206448 <commands+0x860>
ffffffffc0203180:	22400593          	li	a1,548
ffffffffc0203184:	00003517          	auipc	a0,0x3
ffffffffc0203188:	7c450513          	addi	a0,a0,1988 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020318c:	b02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203190:	00004697          	auipc	a3,0x4
ffffffffc0203194:	ae068693          	addi	a3,a3,-1312 # ffffffffc0206c70 <default_pmm_manager+0x478>
ffffffffc0203198:	00003617          	auipc	a2,0x3
ffffffffc020319c:	2b060613          	addi	a2,a2,688 # ffffffffc0206448 <commands+0x860>
ffffffffc02031a0:	22300593          	li	a1,547
ffffffffc02031a4:	00003517          	auipc	a0,0x3
ffffffffc02031a8:	7a450513          	addi	a0,a0,1956 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02031ac:	ae2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031b0:	00004697          	auipc	a3,0x4
ffffffffc02031b4:	aa868693          	addi	a3,a3,-1368 # ffffffffc0206c58 <default_pmm_manager+0x460>
ffffffffc02031b8:	00003617          	auipc	a2,0x3
ffffffffc02031bc:	29060613          	addi	a2,a2,656 # ffffffffc0206448 <commands+0x860>
ffffffffc02031c0:	22100593          	li	a1,545
ffffffffc02031c4:	00003517          	auipc	a0,0x3
ffffffffc02031c8:	78450513          	addi	a0,a0,1924 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02031cc:	ac2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031d0:	00004697          	auipc	a3,0x4
ffffffffc02031d4:	a6868693          	addi	a3,a3,-1432 # ffffffffc0206c38 <default_pmm_manager+0x440>
ffffffffc02031d8:	00003617          	auipc	a2,0x3
ffffffffc02031dc:	27060613          	addi	a2,a2,624 # ffffffffc0206448 <commands+0x860>
ffffffffc02031e0:	22000593          	li	a1,544
ffffffffc02031e4:	00003517          	auipc	a0,0x3
ffffffffc02031e8:	76450513          	addi	a0,a0,1892 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02031ec:	aa2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031f0:	00004697          	auipc	a3,0x4
ffffffffc02031f4:	a3868693          	addi	a3,a3,-1480 # ffffffffc0206c28 <default_pmm_manager+0x430>
ffffffffc02031f8:	00003617          	auipc	a2,0x3
ffffffffc02031fc:	25060613          	addi	a2,a2,592 # ffffffffc0206448 <commands+0x860>
ffffffffc0203200:	21f00593          	li	a1,543
ffffffffc0203204:	00003517          	auipc	a0,0x3
ffffffffc0203208:	74450513          	addi	a0,a0,1860 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020320c:	a82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203210:	00004697          	auipc	a3,0x4
ffffffffc0203214:	a0868693          	addi	a3,a3,-1528 # ffffffffc0206c18 <default_pmm_manager+0x420>
ffffffffc0203218:	00003617          	auipc	a2,0x3
ffffffffc020321c:	23060613          	addi	a2,a2,560 # ffffffffc0206448 <commands+0x860>
ffffffffc0203220:	21e00593          	li	a1,542
ffffffffc0203224:	00003517          	auipc	a0,0x3
ffffffffc0203228:	72450513          	addi	a0,a0,1828 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020322c:	a62fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203230:	00003617          	auipc	a2,0x3
ffffffffc0203234:	78860613          	addi	a2,a2,1928 # ffffffffc02069b8 <default_pmm_manager+0x1c0>
ffffffffc0203238:	06500593          	li	a1,101
ffffffffc020323c:	00003517          	auipc	a0,0x3
ffffffffc0203240:	70c50513          	addi	a0,a0,1804 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203244:	a4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203248:	00004697          	auipc	a3,0x4
ffffffffc020324c:	ae868693          	addi	a3,a3,-1304 # ffffffffc0206d30 <default_pmm_manager+0x538>
ffffffffc0203250:	00003617          	auipc	a2,0x3
ffffffffc0203254:	1f860613          	addi	a2,a2,504 # ffffffffc0206448 <commands+0x860>
ffffffffc0203258:	26400593          	li	a1,612
ffffffffc020325c:	00003517          	auipc	a0,0x3
ffffffffc0203260:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203264:	a2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203268:	00004697          	auipc	a3,0x4
ffffffffc020326c:	97868693          	addi	a3,a3,-1672 # ffffffffc0206be0 <default_pmm_manager+0x3e8>
ffffffffc0203270:	00003617          	auipc	a2,0x3
ffffffffc0203274:	1d860613          	addi	a2,a2,472 # ffffffffc0206448 <commands+0x860>
ffffffffc0203278:	21d00593          	li	a1,541
ffffffffc020327c:	00003517          	auipc	a0,0x3
ffffffffc0203280:	6cc50513          	addi	a0,a0,1740 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203284:	a0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203288:	00004697          	auipc	a3,0x4
ffffffffc020328c:	91868693          	addi	a3,a3,-1768 # ffffffffc0206ba0 <default_pmm_manager+0x3a8>
ffffffffc0203290:	00003617          	auipc	a2,0x3
ffffffffc0203294:	1b860613          	addi	a2,a2,440 # ffffffffc0206448 <commands+0x860>
ffffffffc0203298:	21c00593          	li	a1,540
ffffffffc020329c:	00003517          	auipc	a0,0x3
ffffffffc02032a0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02032a4:	9eafd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032a8:	86d6                	mv	a3,s5
ffffffffc02032aa:	00003617          	auipc	a2,0x3
ffffffffc02032ae:	58660613          	addi	a2,a2,1414 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02032b2:	21800593          	li	a1,536
ffffffffc02032b6:	00003517          	auipc	a0,0x3
ffffffffc02032ba:	69250513          	addi	a0,a0,1682 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02032be:	9d0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032c2:	00003617          	auipc	a2,0x3
ffffffffc02032c6:	56e60613          	addi	a2,a2,1390 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02032ca:	21700593          	li	a1,535
ffffffffc02032ce:	00003517          	auipc	a0,0x3
ffffffffc02032d2:	67a50513          	addi	a0,a0,1658 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02032d6:	9b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032da:	00004697          	auipc	a3,0x4
ffffffffc02032de:	87e68693          	addi	a3,a3,-1922 # ffffffffc0206b58 <default_pmm_manager+0x360>
ffffffffc02032e2:	00003617          	auipc	a2,0x3
ffffffffc02032e6:	16660613          	addi	a2,a2,358 # ffffffffc0206448 <commands+0x860>
ffffffffc02032ea:	21500593          	li	a1,533
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	65a50513          	addi	a0,a0,1626 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02032f6:	998fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032fa:	00004697          	auipc	a3,0x4
ffffffffc02032fe:	84668693          	addi	a3,a3,-1978 # ffffffffc0206b40 <default_pmm_manager+0x348>
ffffffffc0203302:	00003617          	auipc	a2,0x3
ffffffffc0203306:	14660613          	addi	a2,a2,326 # ffffffffc0206448 <commands+0x860>
ffffffffc020330a:	21400593          	li	a1,532
ffffffffc020330e:	00003517          	auipc	a0,0x3
ffffffffc0203312:	63a50513          	addi	a0,a0,1594 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203316:	978fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020331a:	00004697          	auipc	a3,0x4
ffffffffc020331e:	bd668693          	addi	a3,a3,-1066 # ffffffffc0206ef0 <default_pmm_manager+0x6f8>
ffffffffc0203322:	00003617          	auipc	a2,0x3
ffffffffc0203326:	12660613          	addi	a2,a2,294 # ffffffffc0206448 <commands+0x860>
ffffffffc020332a:	25b00593          	li	a1,603
ffffffffc020332e:	00003517          	auipc	a0,0x3
ffffffffc0203332:	61a50513          	addi	a0,a0,1562 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203336:	958fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020333a:	00004697          	auipc	a3,0x4
ffffffffc020333e:	b7e68693          	addi	a3,a3,-1154 # ffffffffc0206eb8 <default_pmm_manager+0x6c0>
ffffffffc0203342:	00003617          	auipc	a2,0x3
ffffffffc0203346:	10660613          	addi	a2,a2,262 # ffffffffc0206448 <commands+0x860>
ffffffffc020334a:	25800593          	li	a1,600
ffffffffc020334e:	00003517          	auipc	a0,0x3
ffffffffc0203352:	5fa50513          	addi	a0,a0,1530 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203356:	938fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020335a:	00004697          	auipc	a3,0x4
ffffffffc020335e:	b2e68693          	addi	a3,a3,-1234 # ffffffffc0206e88 <default_pmm_manager+0x690>
ffffffffc0203362:	00003617          	auipc	a2,0x3
ffffffffc0203366:	0e660613          	addi	a2,a2,230 # ffffffffc0206448 <commands+0x860>
ffffffffc020336a:	25400593          	li	a1,596
ffffffffc020336e:	00003517          	auipc	a0,0x3
ffffffffc0203372:	5da50513          	addi	a0,a0,1498 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203376:	918fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020337a:	00004697          	auipc	a3,0x4
ffffffffc020337e:	ac668693          	addi	a3,a3,-1338 # ffffffffc0206e40 <default_pmm_manager+0x648>
ffffffffc0203382:	00003617          	auipc	a2,0x3
ffffffffc0203386:	0c660613          	addi	a2,a2,198 # ffffffffc0206448 <commands+0x860>
ffffffffc020338a:	25300593          	li	a1,595
ffffffffc020338e:	00003517          	auipc	a0,0x3
ffffffffc0203392:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203396:	8f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020339a:	00003617          	auipc	a2,0x3
ffffffffc020339e:	53e60613          	addi	a2,a2,1342 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc02033a2:	0c900593          	li	a1,201
ffffffffc02033a6:	00003517          	auipc	a0,0x3
ffffffffc02033aa:	5a250513          	addi	a0,a0,1442 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02033ae:	8e0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02033b2:	00003617          	auipc	a2,0x3
ffffffffc02033b6:	52660613          	addi	a2,a2,1318 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc02033ba:	08100593          	li	a1,129
ffffffffc02033be:	00003517          	auipc	a0,0x3
ffffffffc02033c2:	58a50513          	addi	a0,a0,1418 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02033c6:	8c8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033ca:	00003697          	auipc	a3,0x3
ffffffffc02033ce:	74668693          	addi	a3,a3,1862 # ffffffffc0206b10 <default_pmm_manager+0x318>
ffffffffc02033d2:	00003617          	auipc	a2,0x3
ffffffffc02033d6:	07660613          	addi	a2,a2,118 # ffffffffc0206448 <commands+0x860>
ffffffffc02033da:	21300593          	li	a1,531
ffffffffc02033de:	00003517          	auipc	a0,0x3
ffffffffc02033e2:	56a50513          	addi	a0,a0,1386 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc02033e6:	8a8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033ea:	00003697          	auipc	a3,0x3
ffffffffc02033ee:	6f668693          	addi	a3,a3,1782 # ffffffffc0206ae0 <default_pmm_manager+0x2e8>
ffffffffc02033f2:	00003617          	auipc	a2,0x3
ffffffffc02033f6:	05660613          	addi	a2,a2,86 # ffffffffc0206448 <commands+0x860>
ffffffffc02033fa:	21000593          	li	a1,528
ffffffffc02033fe:	00003517          	auipc	a0,0x3
ffffffffc0203402:	54a50513          	addi	a0,a0,1354 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203406:	888fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020340a <copy_range>:
{
ffffffffc020340a:	7119                	addi	sp,sp,-128
ffffffffc020340c:	f8a2                	sd	s0,112(sp)
ffffffffc020340e:	8436                	mv	s0,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203410:	8ed1                	or	a3,a3,a2
{
ffffffffc0203412:	fc86                	sd	ra,120(sp)
ffffffffc0203414:	f4a6                	sd	s1,104(sp)
ffffffffc0203416:	f0ca                	sd	s2,96(sp)
ffffffffc0203418:	ecce                	sd	s3,88(sp)
ffffffffc020341a:	e8d2                	sd	s4,80(sp)
ffffffffc020341c:	e4d6                	sd	s5,72(sp)
ffffffffc020341e:	e0da                	sd	s6,64(sp)
ffffffffc0203420:	fc5e                	sd	s7,56(sp)
ffffffffc0203422:	f862                	sd	s8,48(sp)
ffffffffc0203424:	f466                	sd	s9,40(sp)
ffffffffc0203426:	f06a                	sd	s10,32(sp)
ffffffffc0203428:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020342a:	16d2                	slli	a3,a3,0x34
{
ffffffffc020342c:	e03a                	sd	a4,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020342e:	24069963          	bnez	a3,ffffffffc0203680 <copy_range+0x276>
    assert(USER_ACCESS(start, end));
ffffffffc0203432:	00200737          	lui	a4,0x200
ffffffffc0203436:	8db2                	mv	s11,a2
ffffffffc0203438:	1ee66863          	bltu	a2,a4,ffffffffc0203628 <copy_range+0x21e>
ffffffffc020343c:	1e867663          	bgeu	a2,s0,ffffffffc0203628 <copy_range+0x21e>
ffffffffc0203440:	4705                	li	a4,1
ffffffffc0203442:	077e                	slli	a4,a4,0x1f
ffffffffc0203444:	1e876263          	bltu	a4,s0,ffffffffc0203628 <copy_range+0x21e>
ffffffffc0203448:	5bfd                	li	s7,-1
ffffffffc020344a:	8a2a                	mv	s4,a0
ffffffffc020344c:	84ae                	mv	s1,a1
        start += PGSIZE;
ffffffffc020344e:	6905                	lui	s2,0x1
    if (PPN(pa) >= npage)
ffffffffc0203450:	000b3b17          	auipc	s6,0xb3
ffffffffc0203454:	2f0b0b13          	addi	s6,s6,752 # ffffffffc02b6740 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203458:	000b3a97          	auipc	s5,0xb3
ffffffffc020345c:	2f0a8a93          	addi	s5,s5,752 # ffffffffc02b6748 <pages>
ffffffffc0203460:	fff80cb7          	lui	s9,0xfff80
    return KADDR(page2pa(page));
ffffffffc0203464:	00cbdb93          	srli	s7,s7,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203468:	000b3d17          	auipc	s10,0xb3
ffffffffc020346c:	2e8d0d13          	addi	s10,s10,744 # ffffffffc02b6750 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203470:	4601                	li	a2,0
ffffffffc0203472:	85ee                	mv	a1,s11
ffffffffc0203474:	8526                	mv	a0,s1
ffffffffc0203476:	b6ffe0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc020347a:	8c2a                	mv	s8,a0
        if (ptep == NULL)
ffffffffc020347c:	c55d                	beqz	a0,ffffffffc020352a <copy_range+0x120>
        if (*ptep & PTE_V)
ffffffffc020347e:	6114                	ld	a3,0(a0)
ffffffffc0203480:	8a85                	andi	a3,a3,1
ffffffffc0203482:	e685                	bnez	a3,ffffffffc02034aa <copy_range+0xa0>
        start += PGSIZE;
ffffffffc0203484:	9dca                	add	s11,s11,s2
    } while (start != 0 && start < end);
ffffffffc0203486:	fe8de5e3          	bltu	s11,s0,ffffffffc0203470 <copy_range+0x66>
    return 0;
ffffffffc020348a:	4501                	li	a0,0
}
ffffffffc020348c:	70e6                	ld	ra,120(sp)
ffffffffc020348e:	7446                	ld	s0,112(sp)
ffffffffc0203490:	74a6                	ld	s1,104(sp)
ffffffffc0203492:	7906                	ld	s2,96(sp)
ffffffffc0203494:	69e6                	ld	s3,88(sp)
ffffffffc0203496:	6a46                	ld	s4,80(sp)
ffffffffc0203498:	6aa6                	ld	s5,72(sp)
ffffffffc020349a:	6b06                	ld	s6,64(sp)
ffffffffc020349c:	7be2                	ld	s7,56(sp)
ffffffffc020349e:	7c42                	ld	s8,48(sp)
ffffffffc02034a0:	7ca2                	ld	s9,40(sp)
ffffffffc02034a2:	7d02                	ld	s10,32(sp)
ffffffffc02034a4:	6de2                	ld	s11,24(sp)
ffffffffc02034a6:	6109                	addi	sp,sp,128
ffffffffc02034a8:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034aa:	4605                	li	a2,1
ffffffffc02034ac:	85ee                	mv	a1,s11
ffffffffc02034ae:	8552                	mv	a0,s4
ffffffffc02034b0:	b35fe0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc02034b4:	10050f63          	beqz	a0,ffffffffc02035d2 <copy_range+0x1c8>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034b8:	000c3603          	ld	a2,0(s8)
    if (!(pte & PTE_V))
ffffffffc02034bc:	00167693          	andi	a3,a2,1
ffffffffc02034c0:	0006099b          	sext.w	s3,a2
ffffffffc02034c4:	10068963          	beqz	a3,ffffffffc02035d6 <copy_range+0x1cc>
    if (PPN(pa) >= npage)
ffffffffc02034c8:	000b3583          	ld	a1,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034cc:	00261693          	slli	a3,a2,0x2
ffffffffc02034d0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02034d2:	16b6fb63          	bgeu	a3,a1,ffffffffc0203648 <copy_range+0x23e>
    return &pages[PPN(pa) - nbase];
ffffffffc02034d6:	000ab583          	ld	a1,0(s5)
ffffffffc02034da:	96e6                	add	a3,a3,s9
ffffffffc02034dc:	069a                	slli	a3,a3,0x6
ffffffffc02034de:	95b6                	add	a1,a1,a3
            assert(page != NULL);
ffffffffc02034e0:	18058063          	beqz	a1,ffffffffc0203660 <copy_range+0x256>
            if (share)
ffffffffc02034e4:	6782                	ld	a5,0(sp)
ffffffffc02034e6:	cfb9                	beqz	a5,ffffffffc0203544 <copy_range+0x13a>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02034e8:	efb67613          	andi	a2,a2,-261
ffffffffc02034ec:	10066613          	ori	a2,a2,256
                perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc02034f0:	01b9f693          	andi	a3,s3,27
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02034f4:	00cc3023          	sd	a2,0(s8)
                ret = page_insert(to, page, start, perm);
ffffffffc02034f8:	1006e693          	ori	a3,a3,256
ffffffffc02034fc:	866e                	mv	a2,s11
ffffffffc02034fe:	8552                	mv	a0,s4
ffffffffc0203500:	9d4ff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203504:	120d8073          	sfence.vma	s11
            assert(ret == 0);
ffffffffc0203508:	dd35                	beqz	a0,ffffffffc0203484 <copy_range+0x7a>
ffffffffc020350a:	00004697          	auipc	a3,0x4
ffffffffc020350e:	a4e68693          	addi	a3,a3,-1458 # ffffffffc0206f58 <default_pmm_manager+0x760>
ffffffffc0203512:	00003617          	auipc	a2,0x3
ffffffffc0203516:	f3660613          	addi	a2,a2,-202 # ffffffffc0206448 <commands+0x860>
ffffffffc020351a:	1a800593          	li	a1,424
ffffffffc020351e:	00003517          	auipc	a0,0x3
ffffffffc0203522:	42a50513          	addi	a0,a0,1066 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203526:	f69fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020352a:	00200637          	lui	a2,0x200
ffffffffc020352e:	00cd87b3          	add	a5,s11,a2
ffffffffc0203532:	ffe00637          	lui	a2,0xffe00
ffffffffc0203536:	00c7fdb3          	and	s11,a5,a2
    } while (start != 0 && start < end);
ffffffffc020353a:	f40d88e3          	beqz	s11,ffffffffc020348a <copy_range+0x80>
ffffffffc020353e:	f28de9e3          	bltu	s11,s0,ffffffffc0203470 <copy_range+0x66>
ffffffffc0203542:	b7a1                	j	ffffffffc020348a <copy_range+0x80>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203544:	10002773          	csrr	a4,sstatus
ffffffffc0203548:	8b09                	andi	a4,a4,2
ffffffffc020354a:	e42e                	sd	a1,8(sp)
ffffffffc020354c:	e73d                	bnez	a4,ffffffffc02035ba <copy_range+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc020354e:	000d3703          	ld	a4,0(s10)
ffffffffc0203552:	4505                	li	a0,1
ffffffffc0203554:	6f18                	ld	a4,24(a4)
ffffffffc0203556:	9702                	jalr	a4
ffffffffc0203558:	65a2                	ld	a1,8(sp)
ffffffffc020355a:	8c2a                	mv	s8,a0
                assert(npage != NULL);
ffffffffc020355c:	0a0c0663          	beqz	s8,ffffffffc0203608 <copy_range+0x1fe>
    return page - pages + nbase;
ffffffffc0203560:	000ab603          	ld	a2,0(s5)
ffffffffc0203564:	00080337          	lui	t1,0x80
    return KADDR(page2pa(page));
ffffffffc0203568:	000b3883          	ld	a7,0(s6)
    return page - pages + nbase;
ffffffffc020356c:	40c586b3          	sub	a3,a1,a2
ffffffffc0203570:	8699                	srai	a3,a3,0x6
ffffffffc0203572:	969a                	add	a3,a3,t1
    return KADDR(page2pa(page));
ffffffffc0203574:	0176f733          	and	a4,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0203578:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020357a:	07177b63          	bgeu	a4,a7,ffffffffc02035f0 <copy_range+0x1e6>
    return page - pages + nbase;
ffffffffc020357e:	40cc0733          	sub	a4,s8,a2
    return KADDR(page2pa(page));
ffffffffc0203582:	000b3797          	auipc	a5,0xb3
ffffffffc0203586:	1d678793          	addi	a5,a5,470 # ffffffffc02b6758 <va_pa_offset>
ffffffffc020358a:	6388                	ld	a0,0(a5)
    return page - pages + nbase;
ffffffffc020358c:	8719                	srai	a4,a4,0x6
ffffffffc020358e:	971a                	add	a4,a4,t1
    return KADDR(page2pa(page));
ffffffffc0203590:	01777633          	and	a2,a4,s7
ffffffffc0203594:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203598:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc020359a:	05167a63          	bgeu	a2,a7,ffffffffc02035ee <copy_range+0x1e4>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020359e:	6605                	lui	a2,0x1
ffffffffc02035a0:	953a                	add	a0,a0,a4
ffffffffc02035a2:	3c0020ef          	jal	ra,ffffffffc0205962 <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc02035a6:	01f9f693          	andi	a3,s3,31
ffffffffc02035aa:	866e                	mv	a2,s11
ffffffffc02035ac:	85e2                	mv	a1,s8
ffffffffc02035ae:	8552                	mv	a0,s4
ffffffffc02035b0:	924ff0ef          	jal	ra,ffffffffc02026d4 <page_insert>
            assert(ret == 0);
ffffffffc02035b4:	ec0508e3          	beqz	a0,ffffffffc0203484 <copy_range+0x7a>
ffffffffc02035b8:	bf89                	j	ffffffffc020350a <copy_range+0x100>
        intr_disable();
ffffffffc02035ba:	bfafd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035be:	000d3703          	ld	a4,0(s10)
ffffffffc02035c2:	4505                	li	a0,1
ffffffffc02035c4:	6f18                	ld	a4,24(a4)
ffffffffc02035c6:	9702                	jalr	a4
ffffffffc02035c8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02035ca:	be4fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035ce:	65a2                	ld	a1,8(sp)
ffffffffc02035d0:	b771                	j	ffffffffc020355c <copy_range+0x152>
                return -E_NO_MEM;
ffffffffc02035d2:	5571                	li	a0,-4
ffffffffc02035d4:	bd65                	j	ffffffffc020348c <copy_range+0x82>
        panic("pte2page called with invalid pte");
ffffffffc02035d6:	00003617          	auipc	a2,0x3
ffffffffc02035da:	34a60613          	addi	a2,a2,842 # ffffffffc0206920 <default_pmm_manager+0x128>
ffffffffc02035de:	07f00593          	li	a1,127
ffffffffc02035e2:	00003517          	auipc	a0,0x3
ffffffffc02035e6:	27650513          	addi	a0,a0,630 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02035ea:	ea5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02035ee:	86ba                	mv	a3,a4
ffffffffc02035f0:	00003617          	auipc	a2,0x3
ffffffffc02035f4:	24060613          	addi	a2,a2,576 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02035f8:	07100593          	li	a1,113
ffffffffc02035fc:	00003517          	auipc	a0,0x3
ffffffffc0203600:	25c50513          	addi	a0,a0,604 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0203604:	e8bfc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(npage != NULL);
ffffffffc0203608:	00004697          	auipc	a3,0x4
ffffffffc020360c:	94068693          	addi	a3,a3,-1728 # ffffffffc0206f48 <default_pmm_manager+0x750>
ffffffffc0203610:	00003617          	auipc	a2,0x3
ffffffffc0203614:	e3860613          	addi	a2,a2,-456 # ffffffffc0206448 <commands+0x860>
ffffffffc0203618:	1a200593          	li	a1,418
ffffffffc020361c:	00003517          	auipc	a0,0x3
ffffffffc0203620:	32c50513          	addi	a0,a0,812 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203624:	e6bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203628:	00003697          	auipc	a3,0x3
ffffffffc020362c:	36068693          	addi	a3,a3,864 # ffffffffc0206988 <default_pmm_manager+0x190>
ffffffffc0203630:	00003617          	auipc	a2,0x3
ffffffffc0203634:	e1860613          	addi	a2,a2,-488 # ffffffffc0206448 <commands+0x860>
ffffffffc0203638:	17a00593          	li	a1,378
ffffffffc020363c:	00003517          	auipc	a0,0x3
ffffffffc0203640:	30c50513          	addi	a0,a0,780 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203644:	e4bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203648:	00003617          	auipc	a2,0x3
ffffffffc020364c:	2b860613          	addi	a2,a2,696 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc0203650:	06900593          	li	a1,105
ffffffffc0203654:	00003517          	auipc	a0,0x3
ffffffffc0203658:	20450513          	addi	a0,a0,516 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc020365c:	e33fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203660:	00004697          	auipc	a3,0x4
ffffffffc0203664:	8d868693          	addi	a3,a3,-1832 # ffffffffc0206f38 <default_pmm_manager+0x740>
ffffffffc0203668:	00003617          	auipc	a2,0x3
ffffffffc020366c:	de060613          	addi	a2,a2,-544 # ffffffffc0206448 <commands+0x860>
ffffffffc0203670:	18f00593          	li	a1,399
ffffffffc0203674:	00003517          	auipc	a0,0x3
ffffffffc0203678:	2d450513          	addi	a0,a0,724 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020367c:	e13fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203680:	00003697          	auipc	a3,0x3
ffffffffc0203684:	2d868693          	addi	a3,a3,728 # ffffffffc0206958 <default_pmm_manager+0x160>
ffffffffc0203688:	00003617          	auipc	a2,0x3
ffffffffc020368c:	dc060613          	addi	a2,a2,-576 # ffffffffc0206448 <commands+0x860>
ffffffffc0203690:	17900593          	li	a1,377
ffffffffc0203694:	00003517          	auipc	a0,0x3
ffffffffc0203698:	2b450513          	addi	a0,a0,692 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc020369c:	df3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036a0 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02036a0:	12058073          	sfence.vma	a1
}
ffffffffc02036a4:	8082                	ret

ffffffffc02036a6 <pgdir_alloc_page>:
{
ffffffffc02036a6:	7179                	addi	sp,sp,-48
ffffffffc02036a8:	ec26                	sd	s1,24(sp)
ffffffffc02036aa:	e84a                	sd	s2,16(sp)
ffffffffc02036ac:	e052                	sd	s4,0(sp)
ffffffffc02036ae:	f406                	sd	ra,40(sp)
ffffffffc02036b0:	f022                	sd	s0,32(sp)
ffffffffc02036b2:	e44e                	sd	s3,8(sp)
ffffffffc02036b4:	8a2a                	mv	s4,a0
ffffffffc02036b6:	84ae                	mv	s1,a1
ffffffffc02036b8:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02036ba:	100027f3          	csrr	a5,sstatus
ffffffffc02036be:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02036c0:	000b3997          	auipc	s3,0xb3
ffffffffc02036c4:	09098993          	addi	s3,s3,144 # ffffffffc02b6750 <pmm_manager>
ffffffffc02036c8:	ef8d                	bnez	a5,ffffffffc0203702 <pgdir_alloc_page+0x5c>
ffffffffc02036ca:	0009b783          	ld	a5,0(s3)
ffffffffc02036ce:	4505                	li	a0,1
ffffffffc02036d0:	6f9c                	ld	a5,24(a5)
ffffffffc02036d2:	9782                	jalr	a5
ffffffffc02036d4:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02036d6:	cc09                	beqz	s0,ffffffffc02036f0 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036d8:	86ca                	mv	a3,s2
ffffffffc02036da:	8626                	mv	a2,s1
ffffffffc02036dc:	85a2                	mv	a1,s0
ffffffffc02036de:	8552                	mv	a0,s4
ffffffffc02036e0:	ff5fe0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc02036e4:	e915                	bnez	a0,ffffffffc0203718 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02036e6:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02036e8:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02036ea:	4785                	li	a5,1
ffffffffc02036ec:	04f71e63          	bne	a4,a5,ffffffffc0203748 <pgdir_alloc_page+0xa2>
}
ffffffffc02036f0:	70a2                	ld	ra,40(sp)
ffffffffc02036f2:	8522                	mv	a0,s0
ffffffffc02036f4:	7402                	ld	s0,32(sp)
ffffffffc02036f6:	64e2                	ld	s1,24(sp)
ffffffffc02036f8:	6942                	ld	s2,16(sp)
ffffffffc02036fa:	69a2                	ld	s3,8(sp)
ffffffffc02036fc:	6a02                	ld	s4,0(sp)
ffffffffc02036fe:	6145                	addi	sp,sp,48
ffffffffc0203700:	8082                	ret
        intr_disable();
ffffffffc0203702:	ab2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203706:	0009b783          	ld	a5,0(s3)
ffffffffc020370a:	4505                	li	a0,1
ffffffffc020370c:	6f9c                	ld	a5,24(a5)
ffffffffc020370e:	9782                	jalr	a5
ffffffffc0203710:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203712:	a9cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203716:	b7c1                	j	ffffffffc02036d6 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203718:	100027f3          	csrr	a5,sstatus
ffffffffc020371c:	8b89                	andi	a5,a5,2
ffffffffc020371e:	eb89                	bnez	a5,ffffffffc0203730 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203720:	0009b783          	ld	a5,0(s3)
ffffffffc0203724:	8522                	mv	a0,s0
ffffffffc0203726:	4585                	li	a1,1
ffffffffc0203728:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020372a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020372c:	9782                	jalr	a5
    if (flag)
ffffffffc020372e:	b7c9                	j	ffffffffc02036f0 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203730:	a84fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203734:	0009b783          	ld	a5,0(s3)
ffffffffc0203738:	8522                	mv	a0,s0
ffffffffc020373a:	4585                	li	a1,1
ffffffffc020373c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020373e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203740:	9782                	jalr	a5
        intr_enable();
ffffffffc0203742:	a6cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203746:	b76d                	j	ffffffffc02036f0 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203748:	00004697          	auipc	a3,0x4
ffffffffc020374c:	82068693          	addi	a3,a3,-2016 # ffffffffc0206f68 <default_pmm_manager+0x770>
ffffffffc0203750:	00003617          	auipc	a2,0x3
ffffffffc0203754:	cf860613          	addi	a2,a2,-776 # ffffffffc0206448 <commands+0x860>
ffffffffc0203758:	1f100593          	li	a1,497
ffffffffc020375c:	00003517          	auipc	a0,0x3
ffffffffc0203760:	1ec50513          	addi	a0,a0,492 # ffffffffc0206948 <default_pmm_manager+0x150>
ffffffffc0203764:	d2bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203768 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203768:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020376a:	00004697          	auipc	a3,0x4
ffffffffc020376e:	81668693          	addi	a3,a3,-2026 # ffffffffc0206f80 <default_pmm_manager+0x788>
ffffffffc0203772:	00003617          	auipc	a2,0x3
ffffffffc0203776:	cd660613          	addi	a2,a2,-810 # ffffffffc0206448 <commands+0x860>
ffffffffc020377a:	07400593          	li	a1,116
ffffffffc020377e:	00004517          	auipc	a0,0x4
ffffffffc0203782:	82250513          	addi	a0,a0,-2014 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203786:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203788:	d07fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020378c <mm_create>:
{
ffffffffc020378c:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020378e:	04000513          	li	a0,64
{
ffffffffc0203792:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203794:	dbafe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
    if (mm != NULL)
ffffffffc0203798:	cd19                	beqz	a0,ffffffffc02037b6 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020379a:	e508                	sd	a0,8(a0)
ffffffffc020379c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020379e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02037a2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02037a6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02037aa:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02037ae:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02037b2:	02053c23          	sd	zero,56(a0)
}
ffffffffc02037b6:	60a2                	ld	ra,8(sp)
ffffffffc02037b8:	0141                	addi	sp,sp,16
ffffffffc02037ba:	8082                	ret

ffffffffc02037bc <find_vma>:
{
ffffffffc02037bc:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02037be:	c505                	beqz	a0,ffffffffc02037e6 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02037c0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037c2:	c501                	beqz	a0,ffffffffc02037ca <find_vma+0xe>
ffffffffc02037c4:	651c                	ld	a5,8(a0)
ffffffffc02037c6:	02f5f263          	bgeu	a1,a5,ffffffffc02037ea <find_vma+0x2e>
    return listelm->next;
ffffffffc02037ca:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02037cc:	00f68d63          	beq	a3,a5,ffffffffc02037e6 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037d0:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037d4:	00e5e663          	bltu	a1,a4,ffffffffc02037e0 <find_vma+0x24>
ffffffffc02037d8:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037dc:	00e5ec63          	bltu	a1,a4,ffffffffc02037f4 <find_vma+0x38>
ffffffffc02037e0:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037e2:	fef697e3          	bne	a3,a5,ffffffffc02037d0 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02037e6:	4501                	li	a0,0
}
ffffffffc02037e8:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037ea:	691c                	ld	a5,16(a0)
ffffffffc02037ec:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02037ca <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02037f0:	ea88                	sd	a0,16(a3)
ffffffffc02037f2:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037f4:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037f8:	ea88                	sd	a0,16(a3)
ffffffffc02037fa:	8082                	ret

ffffffffc02037fc <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037fc:	6590                	ld	a2,8(a1)
ffffffffc02037fe:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203802:	1141                	addi	sp,sp,-16
ffffffffc0203804:	e406                	sd	ra,8(sp)
ffffffffc0203806:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203808:	01066763          	bltu	a2,a6,ffffffffc0203816 <insert_vma_struct+0x1a>
ffffffffc020380c:	a085                	j	ffffffffc020386c <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020380e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203812:	04e66863          	bltu	a2,a4,ffffffffc0203862 <insert_vma_struct+0x66>
ffffffffc0203816:	86be                	mv	a3,a5
ffffffffc0203818:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020381a:	fef51ae3          	bne	a0,a5,ffffffffc020380e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020381e:	02a68463          	beq	a3,a0,ffffffffc0203846 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203822:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203826:	fe86b883          	ld	a7,-24(a3)
ffffffffc020382a:	08e8f163          	bgeu	a7,a4,ffffffffc02038ac <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020382e:	04e66f63          	bltu	a2,a4,ffffffffc020388c <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203832:	00f50a63          	beq	a0,a5,ffffffffc0203846 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203836:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020383a:	05076963          	bltu	a4,a6,ffffffffc020388c <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020383e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203842:	02c77363          	bgeu	a4,a2,ffffffffc0203868 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203846:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203848:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020384a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020384e:	e390                	sd	a2,0(a5)
ffffffffc0203850:	e690                	sd	a2,8(a3)
}
ffffffffc0203852:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203854:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203856:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203858:	0017079b          	addiw	a5,a4,1
ffffffffc020385c:	d11c                	sw	a5,32(a0)
}
ffffffffc020385e:	0141                	addi	sp,sp,16
ffffffffc0203860:	8082                	ret
    if (le_prev != list)
ffffffffc0203862:	fca690e3          	bne	a3,a0,ffffffffc0203822 <insert_vma_struct+0x26>
ffffffffc0203866:	bfd1                	j	ffffffffc020383a <insert_vma_struct+0x3e>
ffffffffc0203868:	f01ff0ef          	jal	ra,ffffffffc0203768 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020386c:	00003697          	auipc	a3,0x3
ffffffffc0203870:	74468693          	addi	a3,a3,1860 # ffffffffc0206fb0 <default_pmm_manager+0x7b8>
ffffffffc0203874:	00003617          	auipc	a2,0x3
ffffffffc0203878:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206448 <commands+0x860>
ffffffffc020387c:	07a00593          	li	a1,122
ffffffffc0203880:	00003517          	auipc	a0,0x3
ffffffffc0203884:	72050513          	addi	a0,a0,1824 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203888:	c07fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020388c:	00003697          	auipc	a3,0x3
ffffffffc0203890:	76468693          	addi	a3,a3,1892 # ffffffffc0206ff0 <default_pmm_manager+0x7f8>
ffffffffc0203894:	00003617          	auipc	a2,0x3
ffffffffc0203898:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206448 <commands+0x860>
ffffffffc020389c:	07300593          	li	a1,115
ffffffffc02038a0:	00003517          	auipc	a0,0x3
ffffffffc02038a4:	70050513          	addi	a0,a0,1792 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc02038a8:	be7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038ac:	00003697          	auipc	a3,0x3
ffffffffc02038b0:	72468693          	addi	a3,a3,1828 # ffffffffc0206fd0 <default_pmm_manager+0x7d8>
ffffffffc02038b4:	00003617          	auipc	a2,0x3
ffffffffc02038b8:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206448 <commands+0x860>
ffffffffc02038bc:	07200593          	li	a1,114
ffffffffc02038c0:	00003517          	auipc	a0,0x3
ffffffffc02038c4:	6e050513          	addi	a0,a0,1760 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc02038c8:	bc7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038cc <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02038cc:	591c                	lw	a5,48(a0)
{
ffffffffc02038ce:	1141                	addi	sp,sp,-16
ffffffffc02038d0:	e406                	sd	ra,8(sp)
ffffffffc02038d2:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02038d4:	e78d                	bnez	a5,ffffffffc02038fe <mm_destroy+0x32>
ffffffffc02038d6:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02038d8:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02038da:	00a40c63          	beq	s0,a0,ffffffffc02038f2 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038de:	6118                	ld	a4,0(a0)
ffffffffc02038e0:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02038e2:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02038e4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038e6:	e398                	sd	a4,0(a5)
ffffffffc02038e8:	d16fe0ef          	jal	ra,ffffffffc0201dfe <kfree>
    return listelm->next;
ffffffffc02038ec:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038ee:	fea418e3          	bne	s0,a0,ffffffffc02038de <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038f2:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038f4:	6402                	ld	s0,0(sp)
ffffffffc02038f6:	60a2                	ld	ra,8(sp)
ffffffffc02038f8:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038fa:	d04fe06f          	j	ffffffffc0201dfe <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038fe:	00003697          	auipc	a3,0x3
ffffffffc0203902:	71268693          	addi	a3,a3,1810 # ffffffffc0207010 <default_pmm_manager+0x818>
ffffffffc0203906:	00003617          	auipc	a2,0x3
ffffffffc020390a:	b4260613          	addi	a2,a2,-1214 # ffffffffc0206448 <commands+0x860>
ffffffffc020390e:	09e00593          	li	a1,158
ffffffffc0203912:	00003517          	auipc	a0,0x3
ffffffffc0203916:	68e50513          	addi	a0,a0,1678 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc020391a:	b75fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020391e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020391e:	7139                	addi	sp,sp,-64
ffffffffc0203920:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203922:	6405                	lui	s0,0x1
ffffffffc0203924:	147d                	addi	s0,s0,-1
ffffffffc0203926:	77fd                	lui	a5,0xfffff
ffffffffc0203928:	9622                	add	a2,a2,s0
ffffffffc020392a:	962e                	add	a2,a2,a1
{
ffffffffc020392c:	f426                	sd	s1,40(sp)
ffffffffc020392e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203930:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203934:	f04a                	sd	s2,32(sp)
ffffffffc0203936:	ec4e                	sd	s3,24(sp)
ffffffffc0203938:	e852                	sd	s4,16(sp)
ffffffffc020393a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020393c:	002005b7          	lui	a1,0x200
ffffffffc0203940:	00f67433          	and	s0,a2,a5
ffffffffc0203944:	06b4e363          	bltu	s1,a1,ffffffffc02039aa <mm_map+0x8c>
ffffffffc0203948:	0684f163          	bgeu	s1,s0,ffffffffc02039aa <mm_map+0x8c>
ffffffffc020394c:	4785                	li	a5,1
ffffffffc020394e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203950:	0487ed63          	bltu	a5,s0,ffffffffc02039aa <mm_map+0x8c>
ffffffffc0203954:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203956:	cd21                	beqz	a0,ffffffffc02039ae <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203958:	85a6                	mv	a1,s1
ffffffffc020395a:	8ab6                	mv	s5,a3
ffffffffc020395c:	8a3a                	mv	s4,a4
ffffffffc020395e:	e5fff0ef          	jal	ra,ffffffffc02037bc <find_vma>
ffffffffc0203962:	c501                	beqz	a0,ffffffffc020396a <mm_map+0x4c>
ffffffffc0203964:	651c                	ld	a5,8(a0)
ffffffffc0203966:	0487e263          	bltu	a5,s0,ffffffffc02039aa <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020396a:	03000513          	li	a0,48
ffffffffc020396e:	be0fe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
ffffffffc0203972:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203974:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203976:	02090163          	beqz	s2,ffffffffc0203998 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020397a:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020397c:	00993423          	sd	s1,8(s2) # 1008 <_binary_obj___user_faultread_out_size-0x8bb0>
        vma->vm_end = vm_end;
ffffffffc0203980:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203984:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203988:	85ca                	mv	a1,s2
ffffffffc020398a:	e73ff0ef          	jal	ra,ffffffffc02037fc <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc020398e:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203990:	000a0463          	beqz	s4,ffffffffc0203998 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203994:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203998:	70e2                	ld	ra,56(sp)
ffffffffc020399a:	7442                	ld	s0,48(sp)
ffffffffc020399c:	74a2                	ld	s1,40(sp)
ffffffffc020399e:	7902                	ld	s2,32(sp)
ffffffffc02039a0:	69e2                	ld	s3,24(sp)
ffffffffc02039a2:	6a42                	ld	s4,16(sp)
ffffffffc02039a4:	6aa2                	ld	s5,8(sp)
ffffffffc02039a6:	6121                	addi	sp,sp,64
ffffffffc02039a8:	8082                	ret
        return -E_INVAL;
ffffffffc02039aa:	5575                	li	a0,-3
ffffffffc02039ac:	b7f5                	j	ffffffffc0203998 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02039ae:	00003697          	auipc	a3,0x3
ffffffffc02039b2:	67a68693          	addi	a3,a3,1658 # ffffffffc0207028 <default_pmm_manager+0x830>
ffffffffc02039b6:	00003617          	auipc	a2,0x3
ffffffffc02039ba:	a9260613          	addi	a2,a2,-1390 # ffffffffc0206448 <commands+0x860>
ffffffffc02039be:	0b300593          	li	a1,179
ffffffffc02039c2:	00003517          	auipc	a0,0x3
ffffffffc02039c6:	5de50513          	addi	a0,a0,1502 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc02039ca:	ac5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039ce <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039ce:	7139                	addi	sp,sp,-64
ffffffffc02039d0:	fc06                	sd	ra,56(sp)
ffffffffc02039d2:	f822                	sd	s0,48(sp)
ffffffffc02039d4:	f426                	sd	s1,40(sp)
ffffffffc02039d6:	f04a                	sd	s2,32(sp)
ffffffffc02039d8:	ec4e                	sd	s3,24(sp)
ffffffffc02039da:	e852                	sd	s4,16(sp)
ffffffffc02039dc:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039de:	c52d                	beqz	a0,ffffffffc0203a48 <dup_mmap+0x7a>
ffffffffc02039e0:	892a                	mv	s2,a0
ffffffffc02039e2:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039e4:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039e6:	e595                	bnez	a1,ffffffffc0203a12 <dup_mmap+0x44>
ffffffffc02039e8:	a085                	j	ffffffffc0203a48 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039ea:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02039ec:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_cowtest_out_size+0x1f4088>
        vma->vm_end = vm_end;
ffffffffc02039f0:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02039f4:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02039f8:	e05ff0ef          	jal	ra,ffffffffc02037fc <insert_vma_struct>

        // LAB5 COW: 启用写时复制机制
        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039fc:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0203a00:	fe843603          	ld	a2,-24(s0)
ffffffffc0203a04:	6c8c                	ld	a1,24(s1)
ffffffffc0203a06:	01893503          	ld	a0,24(s2)
ffffffffc0203a0a:	4705                	li	a4,1
ffffffffc0203a0c:	9ffff0ef          	jal	ra,ffffffffc020340a <copy_range>
ffffffffc0203a10:	e105                	bnez	a0,ffffffffc0203a30 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203a12:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203a14:	02848863          	beq	s1,s0,ffffffffc0203a44 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a18:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203a1c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203a20:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203a24:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a28:	b26fe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
ffffffffc0203a2c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203a2e:	fd55                	bnez	a0,ffffffffc02039ea <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203a30:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a32:	70e2                	ld	ra,56(sp)
ffffffffc0203a34:	7442                	ld	s0,48(sp)
ffffffffc0203a36:	74a2                	ld	s1,40(sp)
ffffffffc0203a38:	7902                	ld	s2,32(sp)
ffffffffc0203a3a:	69e2                	ld	s3,24(sp)
ffffffffc0203a3c:	6a42                	ld	s4,16(sp)
ffffffffc0203a3e:	6aa2                	ld	s5,8(sp)
ffffffffc0203a40:	6121                	addi	sp,sp,64
ffffffffc0203a42:	8082                	ret
    return 0;
ffffffffc0203a44:	4501                	li	a0,0
ffffffffc0203a46:	b7f5                	j	ffffffffc0203a32 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203a48:	00003697          	auipc	a3,0x3
ffffffffc0203a4c:	5f068693          	addi	a3,a3,1520 # ffffffffc0207038 <default_pmm_manager+0x840>
ffffffffc0203a50:	00003617          	auipc	a2,0x3
ffffffffc0203a54:	9f860613          	addi	a2,a2,-1544 # ffffffffc0206448 <commands+0x860>
ffffffffc0203a58:	0cf00593          	li	a1,207
ffffffffc0203a5c:	00003517          	auipc	a0,0x3
ffffffffc0203a60:	54450513          	addi	a0,a0,1348 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203a64:	a2bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a68 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a68:	1101                	addi	sp,sp,-32
ffffffffc0203a6a:	ec06                	sd	ra,24(sp)
ffffffffc0203a6c:	e822                	sd	s0,16(sp)
ffffffffc0203a6e:	e426                	sd	s1,8(sp)
ffffffffc0203a70:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a72:	c531                	beqz	a0,ffffffffc0203abe <exit_mmap+0x56>
ffffffffc0203a74:	591c                	lw	a5,48(a0)
ffffffffc0203a76:	84aa                	mv	s1,a0
ffffffffc0203a78:	e3b9                	bnez	a5,ffffffffc0203abe <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a7a:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a7c:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a80:	02850663          	beq	a0,s0,ffffffffc0203aac <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a84:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a88:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a8c:	854a                	mv	a0,s2
ffffffffc0203a8e:	fd2fe0ef          	jal	ra,ffffffffc0202260 <unmap_range>
ffffffffc0203a92:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a94:	fe8498e3          	bne	s1,s0,ffffffffc0203a84 <exit_mmap+0x1c>
ffffffffc0203a98:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a9a:	00848c63          	beq	s1,s0,ffffffffc0203ab2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a9e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203aa2:	fe843583          	ld	a1,-24(s0)
ffffffffc0203aa6:	854a                	mv	a0,s2
ffffffffc0203aa8:	8fffe0ef          	jal	ra,ffffffffc02023a6 <exit_range>
ffffffffc0203aac:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203aae:	fe8498e3          	bne	s1,s0,ffffffffc0203a9e <exit_mmap+0x36>
    }
}
ffffffffc0203ab2:	60e2                	ld	ra,24(sp)
ffffffffc0203ab4:	6442                	ld	s0,16(sp)
ffffffffc0203ab6:	64a2                	ld	s1,8(sp)
ffffffffc0203ab8:	6902                	ld	s2,0(sp)
ffffffffc0203aba:	6105                	addi	sp,sp,32
ffffffffc0203abc:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203abe:	00003697          	auipc	a3,0x3
ffffffffc0203ac2:	59a68693          	addi	a3,a3,1434 # ffffffffc0207058 <default_pmm_manager+0x860>
ffffffffc0203ac6:	00003617          	auipc	a2,0x3
ffffffffc0203aca:	98260613          	addi	a2,a2,-1662 # ffffffffc0206448 <commands+0x860>
ffffffffc0203ace:	0e900593          	li	a1,233
ffffffffc0203ad2:	00003517          	auipc	a0,0x3
ffffffffc0203ad6:	4ce50513          	addi	a0,a0,1230 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203ada:	9b5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ade <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ade:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ae0:	04000513          	li	a0,64
{
ffffffffc0203ae4:	fc06                	sd	ra,56(sp)
ffffffffc0203ae6:	f822                	sd	s0,48(sp)
ffffffffc0203ae8:	f426                	sd	s1,40(sp)
ffffffffc0203aea:	f04a                	sd	s2,32(sp)
ffffffffc0203aec:	ec4e                	sd	s3,24(sp)
ffffffffc0203aee:	e852                	sd	s4,16(sp)
ffffffffc0203af0:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203af2:	a5cfe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
    if (mm != NULL)
ffffffffc0203af6:	2e050663          	beqz	a0,ffffffffc0203de2 <vmm_init+0x304>
ffffffffc0203afa:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203afc:	e508                	sd	a0,8(a0)
ffffffffc0203afe:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203b00:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203b04:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203b08:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203b0c:	02053423          	sd	zero,40(a0)
ffffffffc0203b10:	02052823          	sw	zero,48(a0)
ffffffffc0203b14:	02053c23          	sd	zero,56(a0)
ffffffffc0203b18:	03200413          	li	s0,50
ffffffffc0203b1c:	a811                	j	ffffffffc0203b30 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203b1e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b20:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b22:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203b26:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b28:	8526                	mv	a0,s1
ffffffffc0203b2a:	cd3ff0ef          	jal	ra,ffffffffc02037fc <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b2e:	c80d                	beqz	s0,ffffffffc0203b60 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b30:	03000513          	li	a0,48
ffffffffc0203b34:	a1afe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
ffffffffc0203b38:	85aa                	mv	a1,a0
ffffffffc0203b3a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b3e:	f165                	bnez	a0,ffffffffc0203b1e <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203b40:	00003697          	auipc	a3,0x3
ffffffffc0203b44:	6b068693          	addi	a3,a3,1712 # ffffffffc02071f0 <default_pmm_manager+0x9f8>
ffffffffc0203b48:	00003617          	auipc	a2,0x3
ffffffffc0203b4c:	90060613          	addi	a2,a2,-1792 # ffffffffc0206448 <commands+0x860>
ffffffffc0203b50:	12d00593          	li	a1,301
ffffffffc0203b54:	00003517          	auipc	a0,0x3
ffffffffc0203b58:	44c50513          	addi	a0,a0,1100 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203b5c:	933fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203b60:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b64:	1f900913          	li	s2,505
ffffffffc0203b68:	a819                	j	ffffffffc0203b7e <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203b6a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b6c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b6e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b72:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b74:	8526                	mv	a0,s1
ffffffffc0203b76:	c87ff0ef          	jal	ra,ffffffffc02037fc <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b7a:	03240a63          	beq	s0,s2,ffffffffc0203bae <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b7e:	03000513          	li	a0,48
ffffffffc0203b82:	9ccfe0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
ffffffffc0203b86:	85aa                	mv	a1,a0
ffffffffc0203b88:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b8c:	fd79                	bnez	a0,ffffffffc0203b6a <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203b8e:	00003697          	auipc	a3,0x3
ffffffffc0203b92:	66268693          	addi	a3,a3,1634 # ffffffffc02071f0 <default_pmm_manager+0x9f8>
ffffffffc0203b96:	00003617          	auipc	a2,0x3
ffffffffc0203b9a:	8b260613          	addi	a2,a2,-1870 # ffffffffc0206448 <commands+0x860>
ffffffffc0203b9e:	13400593          	li	a1,308
ffffffffc0203ba2:	00003517          	auipc	a0,0x3
ffffffffc0203ba6:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203baa:	8e5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203bae:	649c                	ld	a5,8(s1)
ffffffffc0203bb0:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203bb2:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203bb6:	16f48663          	beq	s1,a5,ffffffffc0203d22 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bba:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd4886c>
ffffffffc0203bbe:	ffe70693          	addi	a3,a4,-2 # 1ffffe <_binary_obj___user_cowtest_out_size+0x1f407e>
ffffffffc0203bc2:	10d61063          	bne	a2,a3,ffffffffc0203cc2 <vmm_init+0x1e4>
ffffffffc0203bc6:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203bca:	0ed71c63          	bne	a4,a3,ffffffffc0203cc2 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203bce:	0715                	addi	a4,a4,5
ffffffffc0203bd0:	679c                	ld	a5,8(a5)
ffffffffc0203bd2:	feb712e3          	bne	a4,a1,ffffffffc0203bb6 <vmm_init+0xd8>
ffffffffc0203bd6:	4a1d                	li	s4,7
ffffffffc0203bd8:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bda:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203bde:	85a2                	mv	a1,s0
ffffffffc0203be0:	8526                	mv	a0,s1
ffffffffc0203be2:	bdbff0ef          	jal	ra,ffffffffc02037bc <find_vma>
ffffffffc0203be6:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203be8:	16050d63          	beqz	a0,ffffffffc0203d62 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203bec:	00140593          	addi	a1,s0,1
ffffffffc0203bf0:	8526                	mv	a0,s1
ffffffffc0203bf2:	bcbff0ef          	jal	ra,ffffffffc02037bc <find_vma>
ffffffffc0203bf6:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203bf8:	14050563          	beqz	a0,ffffffffc0203d42 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203bfc:	85d2                	mv	a1,s4
ffffffffc0203bfe:	8526                	mv	a0,s1
ffffffffc0203c00:	bbdff0ef          	jal	ra,ffffffffc02037bc <find_vma>
        assert(vma3 == NULL);
ffffffffc0203c04:	16051f63          	bnez	a0,ffffffffc0203d82 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203c08:	00340593          	addi	a1,s0,3
ffffffffc0203c0c:	8526                	mv	a0,s1
ffffffffc0203c0e:	bafff0ef          	jal	ra,ffffffffc02037bc <find_vma>
        assert(vma4 == NULL);
ffffffffc0203c12:	1a051863          	bnez	a0,ffffffffc0203dc2 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203c16:	00440593          	addi	a1,s0,4
ffffffffc0203c1a:	8526                	mv	a0,s1
ffffffffc0203c1c:	ba1ff0ef          	jal	ra,ffffffffc02037bc <find_vma>
        assert(vma5 == NULL);
ffffffffc0203c20:	18051163          	bnez	a0,ffffffffc0203da2 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c24:	00893783          	ld	a5,8(s2)
ffffffffc0203c28:	0a879d63          	bne	a5,s0,ffffffffc0203ce2 <vmm_init+0x204>
ffffffffc0203c2c:	01093783          	ld	a5,16(s2)
ffffffffc0203c30:	0b479963          	bne	a5,s4,ffffffffc0203ce2 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c34:	0089b783          	ld	a5,8(s3)
ffffffffc0203c38:	0c879563          	bne	a5,s0,ffffffffc0203d02 <vmm_init+0x224>
ffffffffc0203c3c:	0109b783          	ld	a5,16(s3)
ffffffffc0203c40:	0d479163          	bne	a5,s4,ffffffffc0203d02 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203c44:	0415                	addi	s0,s0,5
ffffffffc0203c46:	0a15                	addi	s4,s4,5
ffffffffc0203c48:	f9541be3          	bne	s0,s5,ffffffffc0203bde <vmm_init+0x100>
ffffffffc0203c4c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203c4e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203c50:	85a2                	mv	a1,s0
ffffffffc0203c52:	8526                	mv	a0,s1
ffffffffc0203c54:	b69ff0ef          	jal	ra,ffffffffc02037bc <find_vma>
ffffffffc0203c58:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203c5c:	c90d                	beqz	a0,ffffffffc0203c8e <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c5e:	6914                	ld	a3,16(a0)
ffffffffc0203c60:	6510                	ld	a2,8(a0)
ffffffffc0203c62:	00003517          	auipc	a0,0x3
ffffffffc0203c66:	51650513          	addi	a0,a0,1302 # ffffffffc0207178 <default_pmm_manager+0x980>
ffffffffc0203c6a:	d2afc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203c6e:	00003697          	auipc	a3,0x3
ffffffffc0203c72:	53268693          	addi	a3,a3,1330 # ffffffffc02071a0 <default_pmm_manager+0x9a8>
ffffffffc0203c76:	00002617          	auipc	a2,0x2
ffffffffc0203c7a:	7d260613          	addi	a2,a2,2002 # ffffffffc0206448 <commands+0x860>
ffffffffc0203c7e:	15a00593          	li	a1,346
ffffffffc0203c82:	00003517          	auipc	a0,0x3
ffffffffc0203c86:	31e50513          	addi	a0,a0,798 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203c8a:	805fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203c8e:	147d                	addi	s0,s0,-1
ffffffffc0203c90:	fd2410e3          	bne	s0,s2,ffffffffc0203c50 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203c94:	8526                	mv	a0,s1
ffffffffc0203c96:	c37ff0ef          	jal	ra,ffffffffc02038cc <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c9a:	00003517          	auipc	a0,0x3
ffffffffc0203c9e:	51e50513          	addi	a0,a0,1310 # ffffffffc02071b8 <default_pmm_manager+0x9c0>
ffffffffc0203ca2:	cf2fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203ca6:	7442                	ld	s0,48(sp)
ffffffffc0203ca8:	70e2                	ld	ra,56(sp)
ffffffffc0203caa:	74a2                	ld	s1,40(sp)
ffffffffc0203cac:	7902                	ld	s2,32(sp)
ffffffffc0203cae:	69e2                	ld	s3,24(sp)
ffffffffc0203cb0:	6a42                	ld	s4,16(sp)
ffffffffc0203cb2:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203cb4:	00003517          	auipc	a0,0x3
ffffffffc0203cb8:	52450513          	addi	a0,a0,1316 # ffffffffc02071d8 <default_pmm_manager+0x9e0>
}
ffffffffc0203cbc:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203cbe:	cd6fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203cc2:	00003697          	auipc	a3,0x3
ffffffffc0203cc6:	3ce68693          	addi	a3,a3,974 # ffffffffc0207090 <default_pmm_manager+0x898>
ffffffffc0203cca:	00002617          	auipc	a2,0x2
ffffffffc0203cce:	77e60613          	addi	a2,a2,1918 # ffffffffc0206448 <commands+0x860>
ffffffffc0203cd2:	13e00593          	li	a1,318
ffffffffc0203cd6:	00003517          	auipc	a0,0x3
ffffffffc0203cda:	2ca50513          	addi	a0,a0,714 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203cde:	fb0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203ce2:	00003697          	auipc	a3,0x3
ffffffffc0203ce6:	43668693          	addi	a3,a3,1078 # ffffffffc0207118 <default_pmm_manager+0x920>
ffffffffc0203cea:	00002617          	auipc	a2,0x2
ffffffffc0203cee:	75e60613          	addi	a2,a2,1886 # ffffffffc0206448 <commands+0x860>
ffffffffc0203cf2:	14f00593          	li	a1,335
ffffffffc0203cf6:	00003517          	auipc	a0,0x3
ffffffffc0203cfa:	2aa50513          	addi	a0,a0,682 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203cfe:	f90fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203d02:	00003697          	auipc	a3,0x3
ffffffffc0203d06:	44668693          	addi	a3,a3,1094 # ffffffffc0207148 <default_pmm_manager+0x950>
ffffffffc0203d0a:	00002617          	auipc	a2,0x2
ffffffffc0203d0e:	73e60613          	addi	a2,a2,1854 # ffffffffc0206448 <commands+0x860>
ffffffffc0203d12:	15000593          	li	a1,336
ffffffffc0203d16:	00003517          	auipc	a0,0x3
ffffffffc0203d1a:	28a50513          	addi	a0,a0,650 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203d1e:	f70fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d22:	00003697          	auipc	a3,0x3
ffffffffc0203d26:	35668693          	addi	a3,a3,854 # ffffffffc0207078 <default_pmm_manager+0x880>
ffffffffc0203d2a:	00002617          	auipc	a2,0x2
ffffffffc0203d2e:	71e60613          	addi	a2,a2,1822 # ffffffffc0206448 <commands+0x860>
ffffffffc0203d32:	13c00593          	li	a1,316
ffffffffc0203d36:	00003517          	auipc	a0,0x3
ffffffffc0203d3a:	26a50513          	addi	a0,a0,618 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203d3e:	f50fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203d42:	00003697          	auipc	a3,0x3
ffffffffc0203d46:	39668693          	addi	a3,a3,918 # ffffffffc02070d8 <default_pmm_manager+0x8e0>
ffffffffc0203d4a:	00002617          	auipc	a2,0x2
ffffffffc0203d4e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0206448 <commands+0x860>
ffffffffc0203d52:	14700593          	li	a1,327
ffffffffc0203d56:	00003517          	auipc	a0,0x3
ffffffffc0203d5a:	24a50513          	addi	a0,a0,586 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203d5e:	f30fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203d62:	00003697          	auipc	a3,0x3
ffffffffc0203d66:	36668693          	addi	a3,a3,870 # ffffffffc02070c8 <default_pmm_manager+0x8d0>
ffffffffc0203d6a:	00002617          	auipc	a2,0x2
ffffffffc0203d6e:	6de60613          	addi	a2,a2,1758 # ffffffffc0206448 <commands+0x860>
ffffffffc0203d72:	14500593          	li	a1,325
ffffffffc0203d76:	00003517          	auipc	a0,0x3
ffffffffc0203d7a:	22a50513          	addi	a0,a0,554 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203d7e:	f10fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203d82:	00003697          	auipc	a3,0x3
ffffffffc0203d86:	36668693          	addi	a3,a3,870 # ffffffffc02070e8 <default_pmm_manager+0x8f0>
ffffffffc0203d8a:	00002617          	auipc	a2,0x2
ffffffffc0203d8e:	6be60613          	addi	a2,a2,1726 # ffffffffc0206448 <commands+0x860>
ffffffffc0203d92:	14900593          	li	a1,329
ffffffffc0203d96:	00003517          	auipc	a0,0x3
ffffffffc0203d9a:	20a50513          	addi	a0,a0,522 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203d9e:	ef0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203da2:	00003697          	auipc	a3,0x3
ffffffffc0203da6:	36668693          	addi	a3,a3,870 # ffffffffc0207108 <default_pmm_manager+0x910>
ffffffffc0203daa:	00002617          	auipc	a2,0x2
ffffffffc0203dae:	69e60613          	addi	a2,a2,1694 # ffffffffc0206448 <commands+0x860>
ffffffffc0203db2:	14d00593          	li	a1,333
ffffffffc0203db6:	00003517          	auipc	a0,0x3
ffffffffc0203dba:	1ea50513          	addi	a0,a0,490 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203dbe:	ed0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203dc2:	00003697          	auipc	a3,0x3
ffffffffc0203dc6:	33668693          	addi	a3,a3,822 # ffffffffc02070f8 <default_pmm_manager+0x900>
ffffffffc0203dca:	00002617          	auipc	a2,0x2
ffffffffc0203dce:	67e60613          	addi	a2,a2,1662 # ffffffffc0206448 <commands+0x860>
ffffffffc0203dd2:	14b00593          	li	a1,331
ffffffffc0203dd6:	00003517          	auipc	a0,0x3
ffffffffc0203dda:	1ca50513          	addi	a0,a0,458 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203dde:	eb0fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203de2:	00003697          	auipc	a3,0x3
ffffffffc0203de6:	24668693          	addi	a3,a3,582 # ffffffffc0207028 <default_pmm_manager+0x830>
ffffffffc0203dea:	00002617          	auipc	a2,0x2
ffffffffc0203dee:	65e60613          	addi	a2,a2,1630 # ffffffffc0206448 <commands+0x860>
ffffffffc0203df2:	12500593          	li	a1,293
ffffffffc0203df6:	00003517          	auipc	a0,0x3
ffffffffc0203dfa:	1aa50513          	addi	a0,a0,426 # ffffffffc0206fa0 <default_pmm_manager+0x7a8>
ffffffffc0203dfe:	e90fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203e02 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203e02:	7179                	addi	sp,sp,-48
ffffffffc0203e04:	f022                	sd	s0,32(sp)
ffffffffc0203e06:	f406                	sd	ra,40(sp)
ffffffffc0203e08:	ec26                	sd	s1,24(sp)
ffffffffc0203e0a:	e84a                	sd	s2,16(sp)
ffffffffc0203e0c:	e44e                	sd	s3,8(sp)
ffffffffc0203e0e:	e052                	sd	s4,0(sp)
ffffffffc0203e10:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203e12:	c135                	beqz	a0,ffffffffc0203e76 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203e14:	002007b7          	lui	a5,0x200
ffffffffc0203e18:	04f5e663          	bltu	a1,a5,ffffffffc0203e64 <user_mem_check+0x62>
ffffffffc0203e1c:	00c584b3          	add	s1,a1,a2
ffffffffc0203e20:	0495f263          	bgeu	a1,s1,ffffffffc0203e64 <user_mem_check+0x62>
ffffffffc0203e24:	4785                	li	a5,1
ffffffffc0203e26:	07fe                	slli	a5,a5,0x1f
ffffffffc0203e28:	0297ee63          	bltu	a5,s1,ffffffffc0203e64 <user_mem_check+0x62>
ffffffffc0203e2c:	892a                	mv	s2,a0
ffffffffc0203e2e:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e30:	6a05                	lui	s4,0x1
ffffffffc0203e32:	a821                	j	ffffffffc0203e4a <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e34:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e38:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e3a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e3c:	c685                	beqz	a3,ffffffffc0203e64 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e3e:	c399                	beqz	a5,ffffffffc0203e44 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e40:	02e46263          	bltu	s0,a4,ffffffffc0203e64 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e44:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e46:	04947663          	bgeu	s0,s1,ffffffffc0203e92 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e4a:	85a2                	mv	a1,s0
ffffffffc0203e4c:	854a                	mv	a0,s2
ffffffffc0203e4e:	96fff0ef          	jal	ra,ffffffffc02037bc <find_vma>
ffffffffc0203e52:	c909                	beqz	a0,ffffffffc0203e64 <user_mem_check+0x62>
ffffffffc0203e54:	6518                	ld	a4,8(a0)
ffffffffc0203e56:	00e46763          	bltu	s0,a4,ffffffffc0203e64 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e5a:	4d1c                	lw	a5,24(a0)
ffffffffc0203e5c:	fc099ce3          	bnez	s3,ffffffffc0203e34 <user_mem_check+0x32>
ffffffffc0203e60:	8b85                	andi	a5,a5,1
ffffffffc0203e62:	f3ed                	bnez	a5,ffffffffc0203e44 <user_mem_check+0x42>
            return 0;
ffffffffc0203e64:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203e66:	70a2                	ld	ra,40(sp)
ffffffffc0203e68:	7402                	ld	s0,32(sp)
ffffffffc0203e6a:	64e2                	ld	s1,24(sp)
ffffffffc0203e6c:	6942                	ld	s2,16(sp)
ffffffffc0203e6e:	69a2                	ld	s3,8(sp)
ffffffffc0203e70:	6a02                	ld	s4,0(sp)
ffffffffc0203e72:	6145                	addi	sp,sp,48
ffffffffc0203e74:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e76:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e7a:	4501                	li	a0,0
ffffffffc0203e7c:	fef5e5e3          	bltu	a1,a5,ffffffffc0203e66 <user_mem_check+0x64>
ffffffffc0203e80:	962e                	add	a2,a2,a1
ffffffffc0203e82:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203e66 <user_mem_check+0x64>
ffffffffc0203e86:	c8000537          	lui	a0,0xc8000
ffffffffc0203e8a:	0505                	addi	a0,a0,1
ffffffffc0203e8c:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e90:	bfd9                	j	ffffffffc0203e66 <user_mem_check+0x64>
        return 1;
ffffffffc0203e92:	4505                	li	a0,1
ffffffffc0203e94:	bfc9                	j	ffffffffc0203e66 <user_mem_check+0x64>

ffffffffc0203e96 <do_pgfault>:
 * 该函数主要处理两种情况:
 * 1. 页面不存在 - 需要分配新页面
 * 2. COW页面写入 - 需要复制页面实现写时复制
 */
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
ffffffffc0203e96:	715d                	addi	sp,sp,-80
    // 查找包含该地址的vma
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203e98:	85b2                	mv	a1,a2
{
ffffffffc0203e9a:	fc26                	sd	s1,56(sp)
ffffffffc0203e9c:	f84a                	sd	s2,48(sp)
ffffffffc0203e9e:	e486                	sd	ra,72(sp)
ffffffffc0203ea0:	e0a2                	sd	s0,64(sp)
ffffffffc0203ea2:	f44e                	sd	s3,40(sp)
ffffffffc0203ea4:	f052                	sd	s4,32(sp)
ffffffffc0203ea6:	ec56                	sd	s5,24(sp)
ffffffffc0203ea8:	e85a                	sd	s6,16(sp)
ffffffffc0203eaa:	e45e                	sd	s7,8(sp)
ffffffffc0203eac:	84b2                	mv	s1,a2
ffffffffc0203eae:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203eb0:	90dff0ef          	jal	ra,ffffffffc02037bc <find_vma>
    if (vma == NULL || vma->vm_start > addr)
ffffffffc0203eb4:	12050f63          	beqz	a0,ffffffffc0203ff2 <do_pgfault+0x15c>
ffffffffc0203eb8:	651c                	ld	a5,8(a0)
ffffffffc0203eba:	12f4ec63          	bltu	s1,a5,ffffffffc0203ff2 <do_pgfault+0x15c>
        cprintf("do_pgfault: 地址 0x%x 不在有效的vma范围内\n", addr);
        return -E_INVAL;
    }

    // 获取页表项
    pte_t *ptep = get_pte(mm->pgdir, addr, 1);
ffffffffc0203ebe:	01893503          	ld	a0,24(s2)
ffffffffc0203ec2:	4605                	li	a2,1
ffffffffc0203ec4:	85a6                	mv	a1,s1
ffffffffc0203ec6:	91efe0ef          	jal	ra,ffffffffc0201fe4 <get_pte>
ffffffffc0203eca:	89aa                	mv	s3,a0
    if (ptep == NULL)
ffffffffc0203ecc:	14050463          	beqz	a0,ffffffffc0204014 <do_pgfault+0x17e>
        cprintf("do_pgfault: 获取页表项失败\n");
        return -E_NO_MEM;
    }

    // 情况1: 页面不存在，需要分配新页面
    if (!(*ptep & PTE_V))
ffffffffc0203ed0:	6110                	ld	a2,0(a0)
ffffffffc0203ed2:	00167793          	andi	a5,a2,1
ffffffffc0203ed6:	c3f9                	beqz	a5,ffffffffc0203f9c <do_pgfault+0x106>
        }
        return 0;
    }

    // 情况2: COW页面写入 - 页面有效但是只读且带有COW标志
    if ((*ptep & PTE_COW) && !(*ptep & PTE_W))
ffffffffc0203ed8:	10467793          	andi	a5,a2,260
ffffffffc0203edc:	10000713          	li	a4,256
ffffffffc0203ee0:	10e79063          	bne	a5,a4,ffffffffc0203fe0 <do_pgfault+0x14a>
    if (PPN(pa) >= npage)
ffffffffc0203ee4:	000b3b17          	auipc	s6,0xb3
ffffffffc0203ee8:	85cb0b13          	addi	s6,s6,-1956 # ffffffffc02b6740 <npage>
ffffffffc0203eec:	000b3783          	ld	a5,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203ef0:	00261713          	slli	a4,a2,0x2
ffffffffc0203ef4:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203ef6:	14f77463          	bgeu	a4,a5,ffffffffc020403e <do_pgfault+0x1a8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203efa:	000b3b97          	auipc	s7,0xb3
ffffffffc0203efe:	84eb8b93          	addi	s7,s7,-1970 # ffffffffc02b6748 <pages>
ffffffffc0203f02:	000bb403          	ld	s0,0(s7)
ffffffffc0203f06:	00004a97          	auipc	s5,0x4
ffffffffc0203f0a:	cfaaba83          	ld	s5,-774(s5) # ffffffffc0207c00 <nbase>
ffffffffc0203f0e:	41570733          	sub	a4,a4,s5
ffffffffc0203f12:	071a                	slli	a4,a4,0x6
ffffffffc0203f14:	943a                	add	s0,s0,a4
    {
        // 这是一个COW页面，需要进行写时复制
        struct Page *old_page = pte2page(*ptep);

        // 检查引用计数
        if (page_ref(old_page) == 1)
ffffffffc0203f16:	4018                	lw	a4,0(s0)
ffffffffc0203f18:	4785                	li	a5,1
ffffffffc0203f1a:	0af70163          	beq	a4,a5,ffffffffc0203fbc <do_pgfault+0x126>
            tlb_invalidate(mm->pgdir, addr);
            return 0;
        }

        // 多个进程共享此页面，需要复制
        struct Page *new_page = alloc_page();
ffffffffc0203f1e:	4505                	li	a0,1
ffffffffc0203f20:	80cfe0ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0203f24:	8a2a                	mv	s4,a0
        if (new_page == NULL)
ffffffffc0203f26:	cd79                	beqz	a0,ffffffffc0204004 <do_pgfault+0x16e>
    return page - pages + nbase;
ffffffffc0203f28:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203f2c:	567d                	li	a2,-1
ffffffffc0203f2e:	000b3803          	ld	a6,0(s6)
    return page - pages + nbase;
ffffffffc0203f32:	40e406b3          	sub	a3,s0,a4
ffffffffc0203f36:	8699                	srai	a3,a3,0x6
ffffffffc0203f38:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203f3a:	8231                	srli	a2,a2,0xc
ffffffffc0203f3c:	00c6f7b3          	and	a5,a3,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f40:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203f42:	0f07f263          	bgeu	a5,a6,ffffffffc0204026 <do_pgfault+0x190>
    return page - pages + nbase;
ffffffffc0203f46:	40e507b3          	sub	a5,a0,a4
ffffffffc0203f4a:	8799                	srai	a5,a5,0x6
ffffffffc0203f4c:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203f4e:	000b3517          	auipc	a0,0xb3
ffffffffc0203f52:	80a53503          	ld	a0,-2038(a0) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0203f56:	8e7d                	and	a2,a2,a5
ffffffffc0203f58:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f5c:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203f5e:	0d067363          	bgeu	a2,a6,ffffffffc0204024 <do_pgfault+0x18e>
        }

        // 复制页面内容
        void *src = page2kva(old_page);
        void *dst = page2kva(new_page);
        memcpy(dst, src, PGSIZE);
ffffffffc0203f62:	6605                	lui	a2,0x1
ffffffffc0203f64:	953e                	add	a0,a0,a5
ffffffffc0203f66:	1fd010ef          	jal	ra,ffffffffc0205962 <memcpy>

        // 获取原来的权限（去掉COW标志，加上写权限）
        uint32_t perm = (*ptep & PTE_USER & ~PTE_COW) | PTE_W;
ffffffffc0203f6a:	0009b683          	ld	a3,0(s3)

        // 建立新的映射
        if (page_insert(mm->pgdir, new_page, ROUNDDOWN(addr, PGSIZE), perm) != 0)
ffffffffc0203f6e:	01893503          	ld	a0,24(s2)
ffffffffc0203f72:	767d                	lui	a2,0xfffff
        uint32_t perm = (*ptep & PTE_USER & ~PTE_COW) | PTE_W;
ffffffffc0203f74:	8aed                	andi	a3,a3,27
        if (page_insert(mm->pgdir, new_page, ROUNDDOWN(addr, PGSIZE), perm) != 0)
ffffffffc0203f76:	0046e693          	ori	a3,a3,4
ffffffffc0203f7a:	8e65                	and	a2,a2,s1
ffffffffc0203f7c:	85d2                	mv	a1,s4
ffffffffc0203f7e:	f56fe0ef          	jal	ra,ffffffffc02026d4 <page_insert>
ffffffffc0203f82:	e929                	bnez	a0,ffffffffc0203fd4 <do_pgfault+0x13e>
            return 0;
ffffffffc0203f84:	4501                	li	a0,0
    }

    // 其他情况：真正的页面错误
    cprintf("do_pgfault: 未处理的页面错误，地址=0x%x, pte=0x%x\n", addr, *ptep);
    return -E_INVAL;
ffffffffc0203f86:	60a6                	ld	ra,72(sp)
ffffffffc0203f88:	6406                	ld	s0,64(sp)
ffffffffc0203f8a:	74e2                	ld	s1,56(sp)
ffffffffc0203f8c:	7942                	ld	s2,48(sp)
ffffffffc0203f8e:	79a2                	ld	s3,40(sp)
ffffffffc0203f90:	7a02                	ld	s4,32(sp)
ffffffffc0203f92:	6ae2                	ld	s5,24(sp)
ffffffffc0203f94:	6b42                	ld	s6,16(sp)
ffffffffc0203f96:	6ba2                	ld	s7,8(sp)
ffffffffc0203f98:	6161                	addi	sp,sp,80
ffffffffc0203f9a:	8082                	ret
        struct Page *page = pgdir_alloc_page(mm->pgdir, ROUNDDOWN(addr, PGSIZE),
ffffffffc0203f9c:	01893503          	ld	a0,24(s2)
ffffffffc0203fa0:	75fd                	lui	a1,0xfffff
ffffffffc0203fa2:	4659                	li	a2,22
ffffffffc0203fa4:	8de5                	and	a1,a1,s1
ffffffffc0203fa6:	f00ff0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
        if (page == NULL)
ffffffffc0203faa:	fd69                	bnez	a0,ffffffffc0203f84 <do_pgfault+0xee>
            cprintf("do_pgfault: 分配页面失败\n");
ffffffffc0203fac:	00003517          	auipc	a0,0x3
ffffffffc0203fb0:	2b450513          	addi	a0,a0,692 # ffffffffc0207260 <default_pmm_manager+0xa68>
ffffffffc0203fb4:	9e0fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
            return -E_NO_MEM;
ffffffffc0203fb8:	5571                	li	a0,-4
ffffffffc0203fba:	b7f1                	j	ffffffffc0203f86 <do_pgfault+0xf0>
            tlb_invalidate(mm->pgdir, addr);
ffffffffc0203fbc:	01893503          	ld	a0,24(s2)
            *ptep = (*ptep & ~PTE_COW) | PTE_W;
ffffffffc0203fc0:	efb67613          	andi	a2,a2,-261
ffffffffc0203fc4:	00466613          	ori	a2,a2,4
ffffffffc0203fc8:	00c9b023          	sd	a2,0(s3)
            tlb_invalidate(mm->pgdir, addr);
ffffffffc0203fcc:	85a6                	mv	a1,s1
ffffffffc0203fce:	ed2ff0ef          	jal	ra,ffffffffc02036a0 <tlb_invalidate>
ffffffffc0203fd2:	bf4d                	j	ffffffffc0203f84 <do_pgfault+0xee>
            free_page(new_page);
ffffffffc0203fd4:	8552                	mv	a0,s4
ffffffffc0203fd6:	4585                	li	a1,1
ffffffffc0203fd8:	f93fd0ef          	jal	ra,ffffffffc0201f6a <free_pages>
            return -E_NO_MEM;
ffffffffc0203fdc:	5571                	li	a0,-4
ffffffffc0203fde:	b765                	j	ffffffffc0203f86 <do_pgfault+0xf0>
    cprintf("do_pgfault: 未处理的页面错误，地址=0x%x, pte=0x%x\n", addr, *ptep);
ffffffffc0203fe0:	85a6                	mv	a1,s1
ffffffffc0203fe2:	00003517          	auipc	a0,0x3
ffffffffc0203fe6:	2c650513          	addi	a0,a0,710 # ffffffffc02072a8 <default_pmm_manager+0xab0>
ffffffffc0203fea:	9aafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return -E_INVAL;
ffffffffc0203fee:	5575                	li	a0,-3
ffffffffc0203ff0:	bf59                	j	ffffffffc0203f86 <do_pgfault+0xf0>
        cprintf("do_pgfault: 地址 0x%x 不在有效的vma范围内\n", addr);
ffffffffc0203ff2:	85a6                	mv	a1,s1
ffffffffc0203ff4:	00003517          	auipc	a0,0x3
ffffffffc0203ff8:	20c50513          	addi	a0,a0,524 # ffffffffc0207200 <default_pmm_manager+0xa08>
ffffffffc0203ffc:	998fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_INVAL;
ffffffffc0204000:	5575                	li	a0,-3
ffffffffc0204002:	b751                	j	ffffffffc0203f86 <do_pgfault+0xf0>
            cprintf("do_pgfault: COW分配页面失败\n");
ffffffffc0204004:	00003517          	auipc	a0,0x3
ffffffffc0204008:	27c50513          	addi	a0,a0,636 # ffffffffc0207280 <default_pmm_manager+0xa88>
ffffffffc020400c:	988fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
            return -E_NO_MEM;
ffffffffc0204010:	5571                	li	a0,-4
ffffffffc0204012:	bf95                	j	ffffffffc0203f86 <do_pgfault+0xf0>
        cprintf("do_pgfault: 获取页表项失败\n");
ffffffffc0204014:	00003517          	auipc	a0,0x3
ffffffffc0204018:	22450513          	addi	a0,a0,548 # ffffffffc0207238 <default_pmm_manager+0xa40>
ffffffffc020401c:	978fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_NO_MEM;
ffffffffc0204020:	5571                	li	a0,-4
ffffffffc0204022:	b795                	j	ffffffffc0203f86 <do_pgfault+0xf0>
ffffffffc0204024:	86be                	mv	a3,a5
ffffffffc0204026:	00003617          	auipc	a2,0x3
ffffffffc020402a:	80a60613          	addi	a2,a2,-2038 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc020402e:	07100593          	li	a1,113
ffffffffc0204032:	00003517          	auipc	a0,0x3
ffffffffc0204036:	82650513          	addi	a0,a0,-2010 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc020403a:	c54fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020403e:	00003617          	auipc	a2,0x3
ffffffffc0204042:	8c260613          	addi	a2,a2,-1854 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc0204046:	06900593          	li	a1,105
ffffffffc020404a:	00003517          	auipc	a0,0x3
ffffffffc020404e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0204052:	c3cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204056 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204056:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204058:	9402                	jalr	s0

	jal do_exit
ffffffffc020405a:	62a000ef          	jal	ra,ffffffffc0204684 <do_exit>

ffffffffc020405e <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020405e:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204060:	10800513          	li	a0,264
{
ffffffffc0204064:	e022                	sd	s0,0(sp)
ffffffffc0204066:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204068:	ce7fd0ef          	jal	ra,ffffffffc0201d4e <kmalloc>
ffffffffc020406c:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020406e:	c525                	beqz	a0,ffffffffc02040d6 <alloc_proc+0x78>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0204070:	57fd                	li	a5,-1
ffffffffc0204072:	1782                	slli	a5,a5,0x20
ffffffffc0204074:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204076:	07000613          	li	a2,112
ffffffffc020407a:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc020407c:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204080:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204084:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204088:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc020408c:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204090:	03050513          	addi	a0,a0,48
ffffffffc0204094:	0bd010ef          	jal	ra,ffffffffc0205950 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0204098:	000b2797          	auipc	a5,0xb2
ffffffffc020409c:	6987b783          	ld	a5,1688(a5) # ffffffffc02b6730 <boot_pgdir_pa>
ffffffffc02040a0:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc02040a2:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc02040a6:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc02040aa:	4641                	li	a2,16
ffffffffc02040ac:	4581                	li	a1,0
ffffffffc02040ae:	0b440513          	addi	a0,s0,180
ffffffffc02040b2:	09f010ef          	jal	ra,ffffffffc0205950 <memset>
        list_init(&(proc->list_link));
ffffffffc02040b6:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc02040ba:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc02040be:	e878                	sd	a4,208(s0)
ffffffffc02040c0:	e478                	sd	a4,200(s0)
ffffffffc02040c2:	f07c                	sd	a5,224(s0)
ffffffffc02040c4:	ec7c                	sd	a5,216(s0)
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc02040c6:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;
ffffffffc02040ca:	0e043c23          	sd	zero,248(s0)
ffffffffc02040ce:	10043023          	sd	zero,256(s0)
ffffffffc02040d2:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc02040d6:	60a2                	ld	ra,8(sp)
ffffffffc02040d8:	8522                	mv	a0,s0
ffffffffc02040da:	6402                	ld	s0,0(sp)
ffffffffc02040dc:	0141                	addi	sp,sp,16
ffffffffc02040de:	8082                	ret

ffffffffc02040e0 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02040e0:	000b2797          	auipc	a5,0xb2
ffffffffc02040e4:	6807b783          	ld	a5,1664(a5) # ffffffffc02b6760 <current>
ffffffffc02040e8:	73c8                	ld	a0,160(a5)
ffffffffc02040ea:	ed9fc06f          	j	ffffffffc0200fc2 <forkrets>

ffffffffc02040ee <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02040ee:	000b2797          	auipc	a5,0xb2
ffffffffc02040f2:	6727b783          	ld	a5,1650(a5) # ffffffffc02b6760 <current>
ffffffffc02040f6:	43cc                	lw	a1,4(a5)
{
ffffffffc02040f8:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02040fa:	00003617          	auipc	a2,0x3
ffffffffc02040fe:	1ee60613          	addi	a2,a2,494 # ffffffffc02072e8 <default_pmm_manager+0xaf0>
ffffffffc0204102:	00003517          	auipc	a0,0x3
ffffffffc0204106:	1ee50513          	addi	a0,a0,494 # ffffffffc02072f0 <default_pmm_manager+0xaf8>
{
ffffffffc020410a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020410c:	888fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204110:	3fe08797          	auipc	a5,0x3fe08
ffffffffc0204114:	e7078793          	addi	a5,a5,-400 # bf80 <_binary_obj___user_cowtest_out_size>
ffffffffc0204118:	e43e                	sd	a5,8(sp)
ffffffffc020411a:	00003517          	auipc	a0,0x3
ffffffffc020411e:	1ce50513          	addi	a0,a0,462 # ffffffffc02072e8 <default_pmm_manager+0xaf0>
ffffffffc0204122:	0001c797          	auipc	a5,0x1c
ffffffffc0204126:	e7678793          	addi	a5,a5,-394 # ffffffffc021ff98 <_binary_obj___user_cowtest_out_start>
ffffffffc020412a:	f03e                	sd	a5,32(sp)
ffffffffc020412c:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc020412e:	e802                	sd	zero,16(sp)
ffffffffc0204130:	77e010ef          	jal	ra,ffffffffc02058ae <strlen>
ffffffffc0204134:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204136:	4511                	li	a0,4
ffffffffc0204138:	55a2                	lw	a1,40(sp)
ffffffffc020413a:	4662                	lw	a2,24(sp)
ffffffffc020413c:	5682                	lw	a3,32(sp)
ffffffffc020413e:	4722                	lw	a4,8(sp)
ffffffffc0204140:	48a9                	li	a7,10
ffffffffc0204142:	9002                	ebreak
ffffffffc0204144:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204146:	65c2                	ld	a1,16(sp)
ffffffffc0204148:	00003517          	auipc	a0,0x3
ffffffffc020414c:	1d050513          	addi	a0,a0,464 # ffffffffc0207318 <default_pmm_manager+0xb20>
ffffffffc0204150:	844fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204154:	00003617          	auipc	a2,0x3
ffffffffc0204158:	1d460613          	addi	a2,a2,468 # ffffffffc0207328 <default_pmm_manager+0xb30>
ffffffffc020415c:	3b000593          	li	a1,944
ffffffffc0204160:	00003517          	auipc	a0,0x3
ffffffffc0204164:	1e850513          	addi	a0,a0,488 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204168:	b26fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020416c <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc020416c:	6d14                	ld	a3,24(a0)
{
ffffffffc020416e:	1141                	addi	sp,sp,-16
ffffffffc0204170:	e406                	sd	ra,8(sp)
ffffffffc0204172:	c02007b7          	lui	a5,0xc0200
ffffffffc0204176:	02f6ee63          	bltu	a3,a5,ffffffffc02041b2 <put_pgdir+0x46>
ffffffffc020417a:	000b2517          	auipc	a0,0xb2
ffffffffc020417e:	5de53503          	ld	a0,1502(a0) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0204182:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204184:	82b1                	srli	a3,a3,0xc
ffffffffc0204186:	000b2797          	auipc	a5,0xb2
ffffffffc020418a:	5ba7b783          	ld	a5,1466(a5) # ffffffffc02b6740 <npage>
ffffffffc020418e:	02f6fe63          	bgeu	a3,a5,ffffffffc02041ca <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204192:	00004517          	auipc	a0,0x4
ffffffffc0204196:	a6e53503          	ld	a0,-1426(a0) # ffffffffc0207c00 <nbase>
}
ffffffffc020419a:	60a2                	ld	ra,8(sp)
ffffffffc020419c:	8e89                	sub	a3,a3,a0
ffffffffc020419e:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc02041a0:	000b2517          	auipc	a0,0xb2
ffffffffc02041a4:	5a853503          	ld	a0,1448(a0) # ffffffffc02b6748 <pages>
ffffffffc02041a8:	4585                	li	a1,1
ffffffffc02041aa:	9536                	add	a0,a0,a3
}
ffffffffc02041ac:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02041ae:	dbdfd06f          	j	ffffffffc0201f6a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02041b2:	00002617          	auipc	a2,0x2
ffffffffc02041b6:	72660613          	addi	a2,a2,1830 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc02041ba:	07700593          	li	a1,119
ffffffffc02041be:	00002517          	auipc	a0,0x2
ffffffffc02041c2:	69a50513          	addi	a0,a0,1690 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02041c6:	ac8fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02041ca:	00002617          	auipc	a2,0x2
ffffffffc02041ce:	73660613          	addi	a2,a2,1846 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc02041d2:	06900593          	li	a1,105
ffffffffc02041d6:	00002517          	auipc	a0,0x2
ffffffffc02041da:	68250513          	addi	a0,a0,1666 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02041de:	ab0fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02041e2 <proc_run>:
{
ffffffffc02041e2:	7179                	addi	sp,sp,-48
ffffffffc02041e4:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02041e6:	000b2917          	auipc	s2,0xb2
ffffffffc02041ea:	57a90913          	addi	s2,s2,1402 # ffffffffc02b6760 <current>
{
ffffffffc02041ee:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02041f0:	00093483          	ld	s1,0(s2)
{
ffffffffc02041f4:	f406                	sd	ra,40(sp)
ffffffffc02041f6:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc02041f8:	02a48863          	beq	s1,a0,ffffffffc0204228 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041fc:	100027f3          	csrr	a5,sstatus
ffffffffc0204200:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204202:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204204:	ef9d                	bnez	a5,ffffffffc0204242 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204206:	755c                	ld	a5,168(a0)
ffffffffc0204208:	577d                	li	a4,-1
ffffffffc020420a:	177e                	slli	a4,a4,0x3f
ffffffffc020420c:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc020420e:	00a93023          	sd	a0,0(s2)
ffffffffc0204212:	8fd9                	or	a5,a5,a4
ffffffffc0204214:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0204218:	03050593          	addi	a1,a0,48
ffffffffc020421c:	03048513          	addi	a0,s1,48
ffffffffc0204220:	034010ef          	jal	ra,ffffffffc0205254 <switch_to>
    if (flag)
ffffffffc0204224:	00099863          	bnez	s3,ffffffffc0204234 <proc_run+0x52>
}
ffffffffc0204228:	70a2                	ld	ra,40(sp)
ffffffffc020422a:	7482                	ld	s1,32(sp)
ffffffffc020422c:	6962                	ld	s2,24(sp)
ffffffffc020422e:	69c2                	ld	s3,16(sp)
ffffffffc0204230:	6145                	addi	sp,sp,48
ffffffffc0204232:	8082                	ret
ffffffffc0204234:	70a2                	ld	ra,40(sp)
ffffffffc0204236:	7482                	ld	s1,32(sp)
ffffffffc0204238:	6962                	ld	s2,24(sp)
ffffffffc020423a:	69c2                	ld	s3,16(sp)
ffffffffc020423c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020423e:	f70fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204242:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204244:	f70fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204248:	6522                	ld	a0,8(sp)
ffffffffc020424a:	4985                	li	s3,1
ffffffffc020424c:	bf6d                	j	ffffffffc0204206 <proc_run+0x24>

ffffffffc020424e <do_fork>:
{
ffffffffc020424e:	7119                	addi	sp,sp,-128
ffffffffc0204250:	f4a6                	sd	s1,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204252:	000b2497          	auipc	s1,0xb2
ffffffffc0204256:	52648493          	addi	s1,s1,1318 # ffffffffc02b6778 <nr_process>
ffffffffc020425a:	4098                	lw	a4,0(s1)
{
ffffffffc020425c:	fc86                	sd	ra,120(sp)
ffffffffc020425e:	f8a2                	sd	s0,112(sp)
ffffffffc0204260:	f0ca                	sd	s2,96(sp)
ffffffffc0204262:	ecce                	sd	s3,88(sp)
ffffffffc0204264:	e8d2                	sd	s4,80(sp)
ffffffffc0204266:	e4d6                	sd	s5,72(sp)
ffffffffc0204268:	e0da                	sd	s6,64(sp)
ffffffffc020426a:	fc5e                	sd	s7,56(sp)
ffffffffc020426c:	f862                	sd	s8,48(sp)
ffffffffc020426e:	f466                	sd	s9,40(sp)
ffffffffc0204270:	f06a                	sd	s10,32(sp)
ffffffffc0204272:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204274:	6785                	lui	a5,0x1
ffffffffc0204276:	30f75463          	bge	a4,a5,ffffffffc020457e <do_fork+0x330>
ffffffffc020427a:	8a2a                	mv	s4,a0
ffffffffc020427c:	892e                	mv	s2,a1
ffffffffc020427e:	89b2                	mv	s3,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc0204280:	ddfff0ef          	jal	ra,ffffffffc020405e <alloc_proc>
ffffffffc0204284:	842a                	mv	s0,a0
ffffffffc0204286:	30050363          	beqz	a0,ffffffffc020458c <do_fork+0x33e>
    proc->parent = current;
ffffffffc020428a:	000b2b97          	auipc	s7,0xb2
ffffffffc020428e:	4d6b8b93          	addi	s7,s7,1238 # ffffffffc02b6760 <current>
ffffffffc0204292:	000bb783          	ld	a5,0(s7)
    assert(current->wait_state == 0);
ffffffffc0204296:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8acc>
    proc->parent = current;
ffffffffc020429a:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc020429c:	2e071f63          	bnez	a4,ffffffffc020459a <do_fork+0x34c>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02042a0:	4509                	li	a0,2
ffffffffc02042a2:	c8bfd0ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
    if (page != NULL)
ffffffffc02042a6:	2c050a63          	beqz	a0,ffffffffc020457a <do_fork+0x32c>
    return page - pages + nbase;
ffffffffc02042aa:	000b2c97          	auipc	s9,0xb2
ffffffffc02042ae:	49ec8c93          	addi	s9,s9,1182 # ffffffffc02b6748 <pages>
ffffffffc02042b2:	000cb683          	ld	a3,0(s9)
ffffffffc02042b6:	00004a97          	auipc	s5,0x4
ffffffffc02042ba:	94aa8a93          	addi	s5,s5,-1718 # ffffffffc0207c00 <nbase>
ffffffffc02042be:	000ab703          	ld	a4,0(s5)
ffffffffc02042c2:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02042c6:	000b2d17          	auipc	s10,0xb2
ffffffffc02042ca:	47ad0d13          	addi	s10,s10,1146 # ffffffffc02b6740 <npage>
    return page - pages + nbase;
ffffffffc02042ce:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02042d0:	5b7d                	li	s6,-1
ffffffffc02042d2:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc02042d6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02042d8:	00cb5b13          	srli	s6,s6,0xc
ffffffffc02042dc:	0166f633          	and	a2,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02042e0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02042e2:	2cf67c63          	bgeu	a2,a5,ffffffffc02045ba <do_fork+0x36c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02042e6:	000bb603          	ld	a2,0(s7)
ffffffffc02042ea:	000b2d97          	auipc	s11,0xb2
ffffffffc02042ee:	46ed8d93          	addi	s11,s11,1134 # ffffffffc02b6758 <va_pa_offset>
ffffffffc02042f2:	000db783          	ld	a5,0(s11)
ffffffffc02042f6:	02863b83          	ld	s7,40(a2)
ffffffffc02042fa:	e43a                	sd	a4,8(sp)
ffffffffc02042fc:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02042fe:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204300:	020b8863          	beqz	s7,ffffffffc0204330 <do_fork+0xe2>
    if (clone_flags & CLONE_VM)
ffffffffc0204304:	100a7a13          	andi	s4,s4,256
ffffffffc0204308:	180a0963          	beqz	s4,ffffffffc020449a <do_fork+0x24c>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020430c:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204310:	018bb783          	ld	a5,24(s7)
ffffffffc0204314:	c02006b7          	lui	a3,0xc0200
ffffffffc0204318:	2705                	addiw	a4,a4,1
ffffffffc020431a:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc020431e:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204322:	2ed7ec63          	bltu	a5,a3,ffffffffc020461a <do_fork+0x3cc>
ffffffffc0204326:	000db703          	ld	a4,0(s11)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020432a:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020432c:	8f99                	sub	a5,a5,a4
ffffffffc020432e:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204330:	6789                	lui	a5,0x2
ffffffffc0204332:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc0204336:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204338:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020433a:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020433c:	87b6                	mv	a5,a3
ffffffffc020433e:	12098893          	addi	a7,s3,288
ffffffffc0204342:	00063803          	ld	a6,0(a2)
ffffffffc0204346:	6608                	ld	a0,8(a2)
ffffffffc0204348:	6a0c                	ld	a1,16(a2)
ffffffffc020434a:	6e18                	ld	a4,24(a2)
ffffffffc020434c:	0107b023          	sd	a6,0(a5)
ffffffffc0204350:	e788                	sd	a0,8(a5)
ffffffffc0204352:	eb8c                	sd	a1,16(a5)
ffffffffc0204354:	ef98                	sd	a4,24(a5)
ffffffffc0204356:	02060613          	addi	a2,a2,32
ffffffffc020435a:	02078793          	addi	a5,a5,32
ffffffffc020435e:	ff1612e3          	bne	a2,a7,ffffffffc0204342 <do_fork+0xf4>
    proc->tf->gpr.a0 = 0;
ffffffffc0204362:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204366:	1c090463          	beqz	s2,ffffffffc020452e <do_fork+0x2e0>
    if (++last_pid >= MAX_PID)
ffffffffc020436a:	000ae817          	auipc	a6,0xae
ffffffffc020436e:	f6680813          	addi	a6,a6,-154 # ffffffffc02b22d0 <last_pid.1>
ffffffffc0204372:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204376:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020437a:	00000717          	auipc	a4,0x0
ffffffffc020437e:	d6670713          	addi	a4,a4,-666 # ffffffffc02040e0 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0204382:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204386:	f818                	sd	a4,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204388:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc020438a:	00a82023          	sw	a0,0(a6)
ffffffffc020438e:	6789                	lui	a5,0x2
ffffffffc0204390:	08f55e63          	bge	a0,a5,ffffffffc020442c <do_fork+0x1de>
    if (last_pid >= next_safe)
ffffffffc0204394:	000ae317          	auipc	t1,0xae
ffffffffc0204398:	f4030313          	addi	t1,t1,-192 # ffffffffc02b22d4 <next_safe.0>
ffffffffc020439c:	00032783          	lw	a5,0(t1)
ffffffffc02043a0:	000b2917          	auipc	s2,0xb2
ffffffffc02043a4:	35090913          	addi	s2,s2,848 # ffffffffc02b66f0 <proc_list>
ffffffffc02043a8:	08f55a63          	bge	a0,a5,ffffffffc020443c <do_fork+0x1ee>
    proc->pid = get_pid();
ffffffffc02043ac:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02043ae:	45a9                	li	a1,10
ffffffffc02043b0:	2501                	sext.w	a0,a0
ffffffffc02043b2:	0f8010ef          	jal	ra,ffffffffc02054aa <hash32>
ffffffffc02043b6:	02051793          	slli	a5,a0,0x20
ffffffffc02043ba:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02043be:	000ae797          	auipc	a5,0xae
ffffffffc02043c2:	33278793          	addi	a5,a5,818 # ffffffffc02b26f0 <hash_list>
ffffffffc02043c6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02043c8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02043ca:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02043cc:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc02043d0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02043d2:	00893603          	ld	a2,8(s2)
    prev->next = next->prev = elm;
ffffffffc02043d6:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02043d8:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02043da:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc02043de:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc02043e0:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02043e2:	e21c                	sd	a5,0(a2)
ffffffffc02043e4:	00f93423          	sd	a5,8(s2)
    elm->next = next;
ffffffffc02043e8:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02043ea:	0d243423          	sd	s2,200(s0)
    proc->yptr = NULL;
ffffffffc02043ee:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02043f2:	10e43023          	sd	a4,256(s0)
ffffffffc02043f6:	c311                	beqz	a4,ffffffffc02043fa <do_fork+0x1ac>
        proc->optr->yptr = proc;
ffffffffc02043f8:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc02043fa:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc02043fc:	fae0                	sd	s0,240(a3)
    wakeup_proc(proc);
ffffffffc02043fe:	8522                	mv	a0,s0
    nr_process++;
ffffffffc0204400:	2785                	addiw	a5,a5,1
ffffffffc0204402:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);
ffffffffc0204404:	6bb000ef          	jal	ra,ffffffffc02052be <wakeup_proc>
    ret = proc->pid;
ffffffffc0204408:	00442a03          	lw	s4,4(s0)
}
ffffffffc020440c:	70e6                	ld	ra,120(sp)
ffffffffc020440e:	7446                	ld	s0,112(sp)
ffffffffc0204410:	74a6                	ld	s1,104(sp)
ffffffffc0204412:	7906                	ld	s2,96(sp)
ffffffffc0204414:	69e6                	ld	s3,88(sp)
ffffffffc0204416:	6aa6                	ld	s5,72(sp)
ffffffffc0204418:	6b06                	ld	s6,64(sp)
ffffffffc020441a:	7be2                	ld	s7,56(sp)
ffffffffc020441c:	7c42                	ld	s8,48(sp)
ffffffffc020441e:	7ca2                	ld	s9,40(sp)
ffffffffc0204420:	7d02                	ld	s10,32(sp)
ffffffffc0204422:	6de2                	ld	s11,24(sp)
ffffffffc0204424:	8552                	mv	a0,s4
ffffffffc0204426:	6a46                	ld	s4,80(sp)
ffffffffc0204428:	6109                	addi	sp,sp,128
ffffffffc020442a:	8082                	ret
        last_pid = 1;
ffffffffc020442c:	4785                	li	a5,1
ffffffffc020442e:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204432:	4505                	li	a0,1
ffffffffc0204434:	000ae317          	auipc	t1,0xae
ffffffffc0204438:	ea030313          	addi	t1,t1,-352 # ffffffffc02b22d4 <next_safe.0>
    return listelm->next;
ffffffffc020443c:	000b2917          	auipc	s2,0xb2
ffffffffc0204440:	2b490913          	addi	s2,s2,692 # ffffffffc02b66f0 <proc_list>
ffffffffc0204444:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc0204448:	6789                	lui	a5,0x2
ffffffffc020444a:	00f32023          	sw	a5,0(t1)
ffffffffc020444e:	86aa                	mv	a3,a0
ffffffffc0204450:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204452:	6e89                	lui	t4,0x2
ffffffffc0204454:	132e0763          	beq	t3,s2,ffffffffc0204582 <do_fork+0x334>
ffffffffc0204458:	88ae                	mv	a7,a1
ffffffffc020445a:	87f2                	mv	a5,t3
ffffffffc020445c:	6609                	lui	a2,0x2
ffffffffc020445e:	a811                	j	ffffffffc0204472 <do_fork+0x224>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204460:	00e6d663          	bge	a3,a4,ffffffffc020446c <do_fork+0x21e>
ffffffffc0204464:	00c75463          	bge	a4,a2,ffffffffc020446c <do_fork+0x21e>
ffffffffc0204468:	863a                	mv	a2,a4
ffffffffc020446a:	4885                	li	a7,1
ffffffffc020446c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020446e:	01278d63          	beq	a5,s2,ffffffffc0204488 <do_fork+0x23a>
            if (proc->pid == last_pid)
ffffffffc0204472:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0204476:	fed715e3          	bne	a4,a3,ffffffffc0204460 <do_fork+0x212>
                if (++last_pid >= next_safe)
ffffffffc020447a:	2685                	addiw	a3,a3,1
ffffffffc020447c:	0ec6da63          	bge	a3,a2,ffffffffc0204570 <do_fork+0x322>
ffffffffc0204480:	679c                	ld	a5,8(a5)
ffffffffc0204482:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204484:	ff2797e3          	bne	a5,s2,ffffffffc0204472 <do_fork+0x224>
ffffffffc0204488:	c581                	beqz	a1,ffffffffc0204490 <do_fork+0x242>
ffffffffc020448a:	00d82023          	sw	a3,0(a6)
ffffffffc020448e:	8536                	mv	a0,a3
ffffffffc0204490:	f0088ee3          	beqz	a7,ffffffffc02043ac <do_fork+0x15e>
ffffffffc0204494:	00c32023          	sw	a2,0(t1)
ffffffffc0204498:	bf11                	j	ffffffffc02043ac <do_fork+0x15e>
    if ((mm = mm_create()) == NULL)
ffffffffc020449a:	af2ff0ef          	jal	ra,ffffffffc020378c <mm_create>
ffffffffc020449e:	8c2a                	mv	s8,a0
ffffffffc02044a0:	0e050b63          	beqz	a0,ffffffffc0204596 <do_fork+0x348>
    if ((page = alloc_page()) == NULL)
ffffffffc02044a4:	4505                	li	a0,1
ffffffffc02044a6:	a87fd0ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc02044aa:	c541                	beqz	a0,ffffffffc0204532 <do_fork+0x2e4>
    return page - pages + nbase;
ffffffffc02044ac:	000cb683          	ld	a3,0(s9)
ffffffffc02044b0:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02044b2:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc02044b6:	40d506b3          	sub	a3,a0,a3
ffffffffc02044ba:	8699                	srai	a3,a3,0x6
ffffffffc02044bc:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02044be:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02044c2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02044c4:	0efb7b63          	bgeu	s6,a5,ffffffffc02045ba <do_fork+0x36c>
ffffffffc02044c8:	000dba03          	ld	s4,0(s11)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02044cc:	6605                	lui	a2,0x1
ffffffffc02044ce:	000b2597          	auipc	a1,0xb2
ffffffffc02044d2:	26a5b583          	ld	a1,618(a1) # ffffffffc02b6738 <boot_pgdir_va>
ffffffffc02044d6:	9a36                	add	s4,s4,a3
ffffffffc02044d8:	8552                	mv	a0,s4
ffffffffc02044da:	488010ef          	jal	ra,ffffffffc0205962 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02044de:	038b8b13          	addi	s6,s7,56
    mm->pgdir = pgdir;
ffffffffc02044e2:	014c3c23          	sd	s4,24(s8)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02044e6:	4785                	li	a5,1
ffffffffc02044e8:	40fb37af          	amoor.d	a5,a5,(s6)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02044ec:	8b85                	andi	a5,a5,1
ffffffffc02044ee:	4a05                	li	s4,1
ffffffffc02044f0:	c799                	beqz	a5,ffffffffc02044fe <do_fork+0x2b0>
    {
        schedule();
ffffffffc02044f2:	64d000ef          	jal	ra,ffffffffc020533e <schedule>
ffffffffc02044f6:	414b37af          	amoor.d	a5,s4,(s6)
    while (!try_lock(lock))
ffffffffc02044fa:	8b85                	andi	a5,a5,1
ffffffffc02044fc:	fbfd                	bnez	a5,ffffffffc02044f2 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02044fe:	85de                	mv	a1,s7
ffffffffc0204500:	8562                	mv	a0,s8
ffffffffc0204502:	cccff0ef          	jal	ra,ffffffffc02039ce <dup_mmap>
ffffffffc0204506:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204508:	57f9                	li	a5,-2
ffffffffc020450a:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc020450e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204510:	0e078963          	beqz	a5,ffffffffc0204602 <do_fork+0x3b4>
good_mm:
ffffffffc0204514:	8be2                	mv	s7,s8
    if (ret != 0)
ffffffffc0204516:	de050be3          	beqz	a0,ffffffffc020430c <do_fork+0xbe>
    exit_mmap(mm);
ffffffffc020451a:	8562                	mv	a0,s8
ffffffffc020451c:	d4cff0ef          	jal	ra,ffffffffc0203a68 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204520:	8562                	mv	a0,s8
ffffffffc0204522:	c4bff0ef          	jal	ra,ffffffffc020416c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204526:	8562                	mv	a0,s8
ffffffffc0204528:	ba4ff0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
ffffffffc020452c:	a039                	j	ffffffffc020453a <do_fork+0x2ec>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020452e:	8936                	mv	s2,a3
ffffffffc0204530:	bd2d                	j	ffffffffc020436a <do_fork+0x11c>
    mm_destroy(mm);
ffffffffc0204532:	8562                	mv	a0,s8
ffffffffc0204534:	b98ff0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0204538:	5a71                	li	s4,-4
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020453a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020453c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204540:	0af6e563          	bltu	a3,a5,ffffffffc02045ea <do_fork+0x39c>
ffffffffc0204544:	000db703          	ld	a4,0(s11)
    if (PPN(pa) >= npage)
ffffffffc0204548:	000d3783          	ld	a5,0(s10)
    return pa2page(PADDR(kva));
ffffffffc020454c:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc020454e:	82b1                	srli	a3,a3,0xc
ffffffffc0204550:	08f6f163          	bgeu	a3,a5,ffffffffc02045d2 <do_fork+0x384>
    return &pages[PPN(pa) - nbase];
ffffffffc0204554:	000ab783          	ld	a5,0(s5)
ffffffffc0204558:	000cb503          	ld	a0,0(s9)
ffffffffc020455c:	4589                	li	a1,2
ffffffffc020455e:	8e9d                	sub	a3,a3,a5
ffffffffc0204560:	069a                	slli	a3,a3,0x6
ffffffffc0204562:	9536                	add	a0,a0,a3
ffffffffc0204564:	a07fd0ef          	jal	ra,ffffffffc0201f6a <free_pages>
    kfree(proc);
ffffffffc0204568:	8522                	mv	a0,s0
ffffffffc020456a:	895fd0ef          	jal	ra,ffffffffc0201dfe <kfree>
    return ret;
ffffffffc020456e:	bd79                	j	ffffffffc020440c <do_fork+0x1be>
                    if (last_pid >= MAX_PID)
ffffffffc0204570:	01d6c363          	blt	a3,t4,ffffffffc0204576 <do_fork+0x328>
                        last_pid = 1;
ffffffffc0204574:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204576:	4585                	li	a1,1
ffffffffc0204578:	bdf1                	j	ffffffffc0204454 <do_fork+0x206>
    return -E_NO_MEM;
ffffffffc020457a:	5a71                	li	s4,-4
ffffffffc020457c:	b7f5                	j	ffffffffc0204568 <do_fork+0x31a>
    int ret = -E_NO_FREE_PROC;
ffffffffc020457e:	5a6d                	li	s4,-5
ffffffffc0204580:	b571                	j	ffffffffc020440c <do_fork+0x1be>
ffffffffc0204582:	c599                	beqz	a1,ffffffffc0204590 <do_fork+0x342>
ffffffffc0204584:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204588:	8536                	mv	a0,a3
ffffffffc020458a:	b50d                	j	ffffffffc02043ac <do_fork+0x15e>
    ret = -E_NO_MEM;
ffffffffc020458c:	5a71                	li	s4,-4
ffffffffc020458e:	bdbd                	j	ffffffffc020440c <do_fork+0x1be>
    return last_pid;
ffffffffc0204590:	00082503          	lw	a0,0(a6)
ffffffffc0204594:	bd21                	j	ffffffffc02043ac <do_fork+0x15e>
    int ret = -E_NO_MEM;
ffffffffc0204596:	5a71                	li	s4,-4
ffffffffc0204598:	b74d                	j	ffffffffc020453a <do_fork+0x2ec>
    assert(current->wait_state == 0);
ffffffffc020459a:	00003697          	auipc	a3,0x3
ffffffffc020459e:	dc668693          	addi	a3,a3,-570 # ffffffffc0207360 <default_pmm_manager+0xb68>
ffffffffc02045a2:	00002617          	auipc	a2,0x2
ffffffffc02045a6:	ea660613          	addi	a2,a2,-346 # ffffffffc0206448 <commands+0x860>
ffffffffc02045aa:	1dc00593          	li	a1,476
ffffffffc02045ae:	00003517          	auipc	a0,0x3
ffffffffc02045b2:	d9a50513          	addi	a0,a0,-614 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc02045b6:	ed9fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02045ba:	00002617          	auipc	a2,0x2
ffffffffc02045be:	27660613          	addi	a2,a2,630 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc02045c2:	07100593          	li	a1,113
ffffffffc02045c6:	00002517          	auipc	a0,0x2
ffffffffc02045ca:	29250513          	addi	a0,a0,658 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02045ce:	ec1fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02045d2:	00002617          	auipc	a2,0x2
ffffffffc02045d6:	32e60613          	addi	a2,a2,814 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc02045da:	06900593          	li	a1,105
ffffffffc02045de:	00002517          	auipc	a0,0x2
ffffffffc02045e2:	27a50513          	addi	a0,a0,634 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02045e6:	ea9fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02045ea:	00002617          	auipc	a2,0x2
ffffffffc02045ee:	2ee60613          	addi	a2,a2,750 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc02045f2:	07700593          	li	a1,119
ffffffffc02045f6:	00002517          	auipc	a0,0x2
ffffffffc02045fa:	26250513          	addi	a0,a0,610 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc02045fe:	e91fb0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204602:	00003617          	auipc	a2,0x3
ffffffffc0204606:	d7e60613          	addi	a2,a2,-642 # ffffffffc0207380 <default_pmm_manager+0xb88>
ffffffffc020460a:	03f00593          	li	a1,63
ffffffffc020460e:	00003517          	auipc	a0,0x3
ffffffffc0204612:	d8250513          	addi	a0,a0,-638 # ffffffffc0207390 <default_pmm_manager+0xb98>
ffffffffc0204616:	e79fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020461a:	86be                	mv	a3,a5
ffffffffc020461c:	00002617          	auipc	a2,0x2
ffffffffc0204620:	2bc60613          	addi	a2,a2,700 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc0204624:	18b00593          	li	a1,395
ffffffffc0204628:	00003517          	auipc	a0,0x3
ffffffffc020462c:	d2050513          	addi	a0,a0,-736 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204630:	e5ffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204634 <kernel_thread>:
{
ffffffffc0204634:	7129                	addi	sp,sp,-320
ffffffffc0204636:	fa22                	sd	s0,304(sp)
ffffffffc0204638:	f626                	sd	s1,296(sp)
ffffffffc020463a:	f24a                	sd	s2,288(sp)
ffffffffc020463c:	84ae                	mv	s1,a1
ffffffffc020463e:	892a                	mv	s2,a0
ffffffffc0204640:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204642:	4581                	li	a1,0
ffffffffc0204644:	12000613          	li	a2,288
ffffffffc0204648:	850a                	mv	a0,sp
{
ffffffffc020464a:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020464c:	304010ef          	jal	ra,ffffffffc0205950 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204650:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204652:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204654:	100027f3          	csrr	a5,sstatus
ffffffffc0204658:	edd7f793          	andi	a5,a5,-291
ffffffffc020465c:	1207e793          	ori	a5,a5,288
ffffffffc0204660:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204662:	860a                	mv	a2,sp
ffffffffc0204664:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204668:	00000797          	auipc	a5,0x0
ffffffffc020466c:	9ee78793          	addi	a5,a5,-1554 # ffffffffc0204056 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204670:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204672:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204674:	bdbff0ef          	jal	ra,ffffffffc020424e <do_fork>
}
ffffffffc0204678:	70f2                	ld	ra,312(sp)
ffffffffc020467a:	7452                	ld	s0,304(sp)
ffffffffc020467c:	74b2                	ld	s1,296(sp)
ffffffffc020467e:	7912                	ld	s2,288(sp)
ffffffffc0204680:	6131                	addi	sp,sp,320
ffffffffc0204682:	8082                	ret

ffffffffc0204684 <do_exit>:
{
ffffffffc0204684:	7179                	addi	sp,sp,-48
ffffffffc0204686:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204688:	000b2417          	auipc	s0,0xb2
ffffffffc020468c:	0d840413          	addi	s0,s0,216 # ffffffffc02b6760 <current>
ffffffffc0204690:	601c                	ld	a5,0(s0)
{
ffffffffc0204692:	f406                	sd	ra,40(sp)
ffffffffc0204694:	ec26                	sd	s1,24(sp)
ffffffffc0204696:	e84a                	sd	s2,16(sp)
ffffffffc0204698:	e44e                	sd	s3,8(sp)
ffffffffc020469a:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020469c:	000b2717          	auipc	a4,0xb2
ffffffffc02046a0:	0cc73703          	ld	a4,204(a4) # ffffffffc02b6768 <idleproc>
ffffffffc02046a4:	0ce78c63          	beq	a5,a4,ffffffffc020477c <do_exit+0xf8>
    if (current == initproc)
ffffffffc02046a8:	000b2497          	auipc	s1,0xb2
ffffffffc02046ac:	0c848493          	addi	s1,s1,200 # ffffffffc02b6770 <initproc>
ffffffffc02046b0:	6098                	ld	a4,0(s1)
ffffffffc02046b2:	0ee78b63          	beq	a5,a4,ffffffffc02047a8 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02046b6:	0287b983          	ld	s3,40(a5)
ffffffffc02046ba:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02046bc:	02098663          	beqz	s3,ffffffffc02046e8 <do_exit+0x64>
ffffffffc02046c0:	000b2797          	auipc	a5,0xb2
ffffffffc02046c4:	0707b783          	ld	a5,112(a5) # ffffffffc02b6730 <boot_pgdir_pa>
ffffffffc02046c8:	577d                	li	a4,-1
ffffffffc02046ca:	177e                	slli	a4,a4,0x3f
ffffffffc02046cc:	83b1                	srli	a5,a5,0xc
ffffffffc02046ce:	8fd9                	or	a5,a5,a4
ffffffffc02046d0:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02046d4:	0309a783          	lw	a5,48(s3)
ffffffffc02046d8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02046dc:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02046e0:	cb55                	beqz	a4,ffffffffc0204794 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02046e2:	601c                	ld	a5,0(s0)
ffffffffc02046e4:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02046e8:	601c                	ld	a5,0(s0)
ffffffffc02046ea:	470d                	li	a4,3
ffffffffc02046ec:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02046ee:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046f2:	100027f3          	csrr	a5,sstatus
ffffffffc02046f6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02046f8:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046fa:	e3f9                	bnez	a5,ffffffffc02047c0 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02046fc:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02046fe:	800007b7          	lui	a5,0x80000
ffffffffc0204702:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204704:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204706:	0ec52703          	lw	a4,236(a0)
ffffffffc020470a:	0af70f63          	beq	a4,a5,ffffffffc02047c8 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc020470e:	6018                	ld	a4,0(s0)
ffffffffc0204710:	7b7c                	ld	a5,240(a4)
ffffffffc0204712:	c3a1                	beqz	a5,ffffffffc0204752 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204714:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204718:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc020471a:	0985                	addi	s3,s3,1
ffffffffc020471c:	a021                	j	ffffffffc0204724 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020471e:	6018                	ld	a4,0(s0)
ffffffffc0204720:	7b7c                	ld	a5,240(a4)
ffffffffc0204722:	cb85                	beqz	a5,ffffffffc0204752 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204724:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_cowtest_out_size+0xffffffff7fff4180>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204728:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020472a:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020472c:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020472e:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204732:	10e7b023          	sd	a4,256(a5)
ffffffffc0204736:	c311                	beqz	a4,ffffffffc020473a <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204738:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020473a:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020473c:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020473e:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204740:	fd271fe3          	bne	a4,s2,ffffffffc020471e <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204744:	0ec52783          	lw	a5,236(a0)
ffffffffc0204748:	fd379be3          	bne	a5,s3,ffffffffc020471e <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020474c:	373000ef          	jal	ra,ffffffffc02052be <wakeup_proc>
ffffffffc0204750:	b7f9                	j	ffffffffc020471e <do_exit+0x9a>
    if (flag)
ffffffffc0204752:	020a1263          	bnez	s4,ffffffffc0204776 <do_exit+0xf2>
    schedule();
ffffffffc0204756:	3e9000ef          	jal	ra,ffffffffc020533e <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020475a:	601c                	ld	a5,0(s0)
ffffffffc020475c:	00003617          	auipc	a2,0x3
ffffffffc0204760:	c6c60613          	addi	a2,a2,-916 # ffffffffc02073c8 <default_pmm_manager+0xbd0>
ffffffffc0204764:	23600593          	li	a1,566
ffffffffc0204768:	43d4                	lw	a3,4(a5)
ffffffffc020476a:	00003517          	auipc	a0,0x3
ffffffffc020476e:	bde50513          	addi	a0,a0,-1058 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204772:	d1dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204776:	a38fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020477a:	bff1                	j	ffffffffc0204756 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020477c:	00003617          	auipc	a2,0x3
ffffffffc0204780:	c2c60613          	addi	a2,a2,-980 # ffffffffc02073a8 <default_pmm_manager+0xbb0>
ffffffffc0204784:	20200593          	li	a1,514
ffffffffc0204788:	00003517          	auipc	a0,0x3
ffffffffc020478c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204790:	cfffb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204794:	854e                	mv	a0,s3
ffffffffc0204796:	ad2ff0ef          	jal	ra,ffffffffc0203a68 <exit_mmap>
            put_pgdir(mm);
ffffffffc020479a:	854e                	mv	a0,s3
ffffffffc020479c:	9d1ff0ef          	jal	ra,ffffffffc020416c <put_pgdir>
            mm_destroy(mm);
ffffffffc02047a0:	854e                	mv	a0,s3
ffffffffc02047a2:	92aff0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
ffffffffc02047a6:	bf35                	j	ffffffffc02046e2 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02047a8:	00003617          	auipc	a2,0x3
ffffffffc02047ac:	c1060613          	addi	a2,a2,-1008 # ffffffffc02073b8 <default_pmm_manager+0xbc0>
ffffffffc02047b0:	20600593          	li	a1,518
ffffffffc02047b4:	00003517          	auipc	a0,0x3
ffffffffc02047b8:	b9450513          	addi	a0,a0,-1132 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc02047bc:	cd3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02047c0:	9f4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02047c4:	4a05                	li	s4,1
ffffffffc02047c6:	bf1d                	j	ffffffffc02046fc <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02047c8:	2f7000ef          	jal	ra,ffffffffc02052be <wakeup_proc>
ffffffffc02047cc:	b789                	j	ffffffffc020470e <do_exit+0x8a>

ffffffffc02047ce <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02047ce:	715d                	addi	sp,sp,-80
ffffffffc02047d0:	f84a                	sd	s2,48(sp)
ffffffffc02047d2:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02047d4:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02047d8:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02047da:	fc26                	sd	s1,56(sp)
ffffffffc02047dc:	f052                	sd	s4,32(sp)
ffffffffc02047de:	ec56                	sd	s5,24(sp)
ffffffffc02047e0:	e85a                	sd	s6,16(sp)
ffffffffc02047e2:	e45e                	sd	s7,8(sp)
ffffffffc02047e4:	e486                	sd	ra,72(sp)
ffffffffc02047e6:	e0a2                	sd	s0,64(sp)
ffffffffc02047e8:	84aa                	mv	s1,a0
ffffffffc02047ea:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02047ec:	000b2b97          	auipc	s7,0xb2
ffffffffc02047f0:	f74b8b93          	addi	s7,s7,-140 # ffffffffc02b6760 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02047f4:	00050b1b          	sext.w	s6,a0
ffffffffc02047f8:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02047fc:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02047fe:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204800:	ccbd                	beqz	s1,ffffffffc020487e <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204802:	0359e863          	bltu	s3,s5,ffffffffc0204832 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204806:	45a9                	li	a1,10
ffffffffc0204808:	855a                	mv	a0,s6
ffffffffc020480a:	4a1000ef          	jal	ra,ffffffffc02054aa <hash32>
ffffffffc020480e:	02051793          	slli	a5,a0,0x20
ffffffffc0204812:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204816:	000ae797          	auipc	a5,0xae
ffffffffc020481a:	eda78793          	addi	a5,a5,-294 # ffffffffc02b26f0 <hash_list>
ffffffffc020481e:	953e                	add	a0,a0,a5
ffffffffc0204820:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204822:	a029                	j	ffffffffc020482c <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204824:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204828:	02978163          	beq	a5,s1,ffffffffc020484a <do_wait.part.0+0x7c>
ffffffffc020482c:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020482e:	fe851be3          	bne	a0,s0,ffffffffc0204824 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204832:	5579                	li	a0,-2
}
ffffffffc0204834:	60a6                	ld	ra,72(sp)
ffffffffc0204836:	6406                	ld	s0,64(sp)
ffffffffc0204838:	74e2                	ld	s1,56(sp)
ffffffffc020483a:	7942                	ld	s2,48(sp)
ffffffffc020483c:	79a2                	ld	s3,40(sp)
ffffffffc020483e:	7a02                	ld	s4,32(sp)
ffffffffc0204840:	6ae2                	ld	s5,24(sp)
ffffffffc0204842:	6b42                	ld	s6,16(sp)
ffffffffc0204844:	6ba2                	ld	s7,8(sp)
ffffffffc0204846:	6161                	addi	sp,sp,80
ffffffffc0204848:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020484a:	000bb683          	ld	a3,0(s7)
ffffffffc020484e:	f4843783          	ld	a5,-184(s0)
ffffffffc0204852:	fed790e3          	bne	a5,a3,ffffffffc0204832 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204856:	f2842703          	lw	a4,-216(s0)
ffffffffc020485a:	478d                	li	a5,3
ffffffffc020485c:	0ef70b63          	beq	a4,a5,ffffffffc0204952 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204860:	4785                	li	a5,1
ffffffffc0204862:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204864:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204868:	2d7000ef          	jal	ra,ffffffffc020533e <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020486c:	000bb783          	ld	a5,0(s7)
ffffffffc0204870:	0b07a783          	lw	a5,176(a5)
ffffffffc0204874:	8b85                	andi	a5,a5,1
ffffffffc0204876:	d7c9                	beqz	a5,ffffffffc0204800 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204878:	555d                	li	a0,-9
ffffffffc020487a:	e0bff0ef          	jal	ra,ffffffffc0204684 <do_exit>
        proc = current->cptr;
ffffffffc020487e:	000bb683          	ld	a3,0(s7)
ffffffffc0204882:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204884:	d45d                	beqz	s0,ffffffffc0204832 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204886:	470d                	li	a4,3
ffffffffc0204888:	a021                	j	ffffffffc0204890 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020488a:	10043403          	ld	s0,256(s0)
ffffffffc020488e:	d869                	beqz	s0,ffffffffc0204860 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204890:	401c                	lw	a5,0(s0)
ffffffffc0204892:	fee79ce3          	bne	a5,a4,ffffffffc020488a <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204896:	000b2797          	auipc	a5,0xb2
ffffffffc020489a:	ed27b783          	ld	a5,-302(a5) # ffffffffc02b6768 <idleproc>
ffffffffc020489e:	0c878963          	beq	a5,s0,ffffffffc0204970 <do_wait.part.0+0x1a2>
ffffffffc02048a2:	000b2797          	auipc	a5,0xb2
ffffffffc02048a6:	ece7b783          	ld	a5,-306(a5) # ffffffffc02b6770 <initproc>
ffffffffc02048aa:	0cf40363          	beq	s0,a5,ffffffffc0204970 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02048ae:	000a0663          	beqz	s4,ffffffffc02048ba <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02048b2:	0e842783          	lw	a5,232(s0)
ffffffffc02048b6:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02048ba:	100027f3          	csrr	a5,sstatus
ffffffffc02048be:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02048c0:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02048c2:	e7c1                	bnez	a5,ffffffffc020494a <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02048c4:	6c70                	ld	a2,216(s0)
ffffffffc02048c6:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02048c8:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02048cc:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02048ce:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02048d0:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02048d2:	6470                	ld	a2,200(s0)
ffffffffc02048d4:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02048d6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02048d8:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02048da:	c319                	beqz	a4,ffffffffc02048e0 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02048dc:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02048de:	7c7c                	ld	a5,248(s0)
ffffffffc02048e0:	c3b5                	beqz	a5,ffffffffc0204944 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02048e2:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02048e6:	000b2717          	auipc	a4,0xb2
ffffffffc02048ea:	e9270713          	addi	a4,a4,-366 # ffffffffc02b6778 <nr_process>
ffffffffc02048ee:	431c                	lw	a5,0(a4)
ffffffffc02048f0:	37fd                	addiw	a5,a5,-1
ffffffffc02048f2:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02048f4:	e5a9                	bnez	a1,ffffffffc020493e <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02048f6:	6814                	ld	a3,16(s0)
ffffffffc02048f8:	c02007b7          	lui	a5,0xc0200
ffffffffc02048fc:	04f6ee63          	bltu	a3,a5,ffffffffc0204958 <do_wait.part.0+0x18a>
ffffffffc0204900:	000b2797          	auipc	a5,0xb2
ffffffffc0204904:	e587b783          	ld	a5,-424(a5) # ffffffffc02b6758 <va_pa_offset>
ffffffffc0204908:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020490a:	82b1                	srli	a3,a3,0xc
ffffffffc020490c:	000b2797          	auipc	a5,0xb2
ffffffffc0204910:	e347b783          	ld	a5,-460(a5) # ffffffffc02b6740 <npage>
ffffffffc0204914:	06f6fa63          	bgeu	a3,a5,ffffffffc0204988 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204918:	00003517          	auipc	a0,0x3
ffffffffc020491c:	2e853503          	ld	a0,744(a0) # ffffffffc0207c00 <nbase>
ffffffffc0204920:	8e89                	sub	a3,a3,a0
ffffffffc0204922:	069a                	slli	a3,a3,0x6
ffffffffc0204924:	000b2517          	auipc	a0,0xb2
ffffffffc0204928:	e2453503          	ld	a0,-476(a0) # ffffffffc02b6748 <pages>
ffffffffc020492c:	9536                	add	a0,a0,a3
ffffffffc020492e:	4589                	li	a1,2
ffffffffc0204930:	e3afd0ef          	jal	ra,ffffffffc0201f6a <free_pages>
    kfree(proc);
ffffffffc0204934:	8522                	mv	a0,s0
ffffffffc0204936:	cc8fd0ef          	jal	ra,ffffffffc0201dfe <kfree>
    return 0;
ffffffffc020493a:	4501                	li	a0,0
ffffffffc020493c:	bde5                	j	ffffffffc0204834 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020493e:	870fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204942:	bf55                	j	ffffffffc02048f6 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204944:	701c                	ld	a5,32(s0)
ffffffffc0204946:	fbf8                	sd	a4,240(a5)
ffffffffc0204948:	bf79                	j	ffffffffc02048e6 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020494a:	86afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020494e:	4585                	li	a1,1
ffffffffc0204950:	bf95                	j	ffffffffc02048c4 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204952:	f2840413          	addi	s0,s0,-216
ffffffffc0204956:	b781                	j	ffffffffc0204896 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204958:	00002617          	auipc	a2,0x2
ffffffffc020495c:	f8060613          	addi	a2,a2,-128 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc0204960:	07700593          	li	a1,119
ffffffffc0204964:	00002517          	auipc	a0,0x2
ffffffffc0204968:	ef450513          	addi	a0,a0,-268 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc020496c:	b23fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204970:	00003617          	auipc	a2,0x3
ffffffffc0204974:	a7860613          	addi	a2,a2,-1416 # ffffffffc02073e8 <default_pmm_manager+0xbf0>
ffffffffc0204978:	35800593          	li	a1,856
ffffffffc020497c:	00003517          	auipc	a0,0x3
ffffffffc0204980:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204984:	b0bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204988:	00002617          	auipc	a2,0x2
ffffffffc020498c:	f7860613          	addi	a2,a2,-136 # ffffffffc0206900 <default_pmm_manager+0x108>
ffffffffc0204990:	06900593          	li	a1,105
ffffffffc0204994:	00002517          	auipc	a0,0x2
ffffffffc0204998:	ec450513          	addi	a0,a0,-316 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc020499c:	af3fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049a0 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02049a0:	1141                	addi	sp,sp,-16
ffffffffc02049a2:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02049a4:	e06fd0ef          	jal	ra,ffffffffc0201faa <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02049a8:	ba2fd0ef          	jal	ra,ffffffffc0201d4a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02049ac:	4601                	li	a2,0
ffffffffc02049ae:	4581                	li	a1,0
ffffffffc02049b0:	fffff517          	auipc	a0,0xfffff
ffffffffc02049b4:	73e50513          	addi	a0,a0,1854 # ffffffffc02040ee <user_main>
ffffffffc02049b8:	c7dff0ef          	jal	ra,ffffffffc0204634 <kernel_thread>
    if (pid <= 0)
ffffffffc02049bc:	00a04563          	bgtz	a0,ffffffffc02049c6 <init_main+0x26>
ffffffffc02049c0:	a071                	j	ffffffffc0204a4c <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02049c2:	17d000ef          	jal	ra,ffffffffc020533e <schedule>
    if (code_store != NULL)
ffffffffc02049c6:	4581                	li	a1,0
ffffffffc02049c8:	4501                	li	a0,0
ffffffffc02049ca:	e05ff0ef          	jal	ra,ffffffffc02047ce <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02049ce:	d975                	beqz	a0,ffffffffc02049c2 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02049d0:	00003517          	auipc	a0,0x3
ffffffffc02049d4:	a5850513          	addi	a0,a0,-1448 # ffffffffc0207428 <default_pmm_manager+0xc30>
ffffffffc02049d8:	fbcfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02049dc:	000b2797          	auipc	a5,0xb2
ffffffffc02049e0:	d947b783          	ld	a5,-620(a5) # ffffffffc02b6770 <initproc>
ffffffffc02049e4:	7bf8                	ld	a4,240(a5)
ffffffffc02049e6:	e339                	bnez	a4,ffffffffc0204a2c <init_main+0x8c>
ffffffffc02049e8:	7ff8                	ld	a4,248(a5)
ffffffffc02049ea:	e329                	bnez	a4,ffffffffc0204a2c <init_main+0x8c>
ffffffffc02049ec:	1007b703          	ld	a4,256(a5)
ffffffffc02049f0:	ef15                	bnez	a4,ffffffffc0204a2c <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02049f2:	000b2697          	auipc	a3,0xb2
ffffffffc02049f6:	d866a683          	lw	a3,-634(a3) # ffffffffc02b6778 <nr_process>
ffffffffc02049fa:	4709                	li	a4,2
ffffffffc02049fc:	0ae69463          	bne	a3,a4,ffffffffc0204aa4 <init_main+0x104>
    return listelm->next;
ffffffffc0204a00:	000b2697          	auipc	a3,0xb2
ffffffffc0204a04:	cf068693          	addi	a3,a3,-784 # ffffffffc02b66f0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204a08:	6698                	ld	a4,8(a3)
ffffffffc0204a0a:	0c878793          	addi	a5,a5,200
ffffffffc0204a0e:	06f71b63          	bne	a4,a5,ffffffffc0204a84 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204a12:	629c                	ld	a5,0(a3)
ffffffffc0204a14:	04f71863          	bne	a4,a5,ffffffffc0204a64 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204a18:	00003517          	auipc	a0,0x3
ffffffffc0204a1c:	af850513          	addi	a0,a0,-1288 # ffffffffc0207510 <default_pmm_manager+0xd18>
ffffffffc0204a20:	f74fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204a24:	60a2                	ld	ra,8(sp)
ffffffffc0204a26:	4501                	li	a0,0
ffffffffc0204a28:	0141                	addi	sp,sp,16
ffffffffc0204a2a:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204a2c:	00003697          	auipc	a3,0x3
ffffffffc0204a30:	a2468693          	addi	a3,a3,-1500 # ffffffffc0207450 <default_pmm_manager+0xc58>
ffffffffc0204a34:	00002617          	auipc	a2,0x2
ffffffffc0204a38:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206448 <commands+0x860>
ffffffffc0204a3c:	3c600593          	li	a1,966
ffffffffc0204a40:	00003517          	auipc	a0,0x3
ffffffffc0204a44:	90850513          	addi	a0,a0,-1784 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204a48:	a47fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204a4c:	00003617          	auipc	a2,0x3
ffffffffc0204a50:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0207408 <default_pmm_manager+0xc10>
ffffffffc0204a54:	3bd00593          	li	a1,957
ffffffffc0204a58:	00003517          	auipc	a0,0x3
ffffffffc0204a5c:	8f050513          	addi	a0,a0,-1808 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204a60:	a2ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204a64:	00003697          	auipc	a3,0x3
ffffffffc0204a68:	a7c68693          	addi	a3,a3,-1412 # ffffffffc02074e0 <default_pmm_manager+0xce8>
ffffffffc0204a6c:	00002617          	auipc	a2,0x2
ffffffffc0204a70:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0206448 <commands+0x860>
ffffffffc0204a74:	3c900593          	li	a1,969
ffffffffc0204a78:	00003517          	auipc	a0,0x3
ffffffffc0204a7c:	8d050513          	addi	a0,a0,-1840 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204a80:	a0ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204a84:	00003697          	auipc	a3,0x3
ffffffffc0204a88:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02074b0 <default_pmm_manager+0xcb8>
ffffffffc0204a8c:	00002617          	auipc	a2,0x2
ffffffffc0204a90:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0206448 <commands+0x860>
ffffffffc0204a94:	3c800593          	li	a1,968
ffffffffc0204a98:	00003517          	auipc	a0,0x3
ffffffffc0204a9c:	8b050513          	addi	a0,a0,-1872 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204aa0:	9effb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204aa4:	00003697          	auipc	a3,0x3
ffffffffc0204aa8:	9fc68693          	addi	a3,a3,-1540 # ffffffffc02074a0 <default_pmm_manager+0xca8>
ffffffffc0204aac:	00002617          	auipc	a2,0x2
ffffffffc0204ab0:	99c60613          	addi	a2,a2,-1636 # ffffffffc0206448 <commands+0x860>
ffffffffc0204ab4:	3c700593          	li	a1,967
ffffffffc0204ab8:	00003517          	auipc	a0,0x3
ffffffffc0204abc:	89050513          	addi	a0,a0,-1904 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204ac0:	9cffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ac4 <do_execve>:
{
ffffffffc0204ac4:	7171                	addi	sp,sp,-176
ffffffffc0204ac6:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204ac8:	000b2d97          	auipc	s11,0xb2
ffffffffc0204acc:	c98d8d93          	addi	s11,s11,-872 # ffffffffc02b6760 <current>
ffffffffc0204ad0:	000db783          	ld	a5,0(s11)
{
ffffffffc0204ad4:	e54e                	sd	s3,136(sp)
ffffffffc0204ad6:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204ad8:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204adc:	e94a                	sd	s2,144(sp)
ffffffffc0204ade:	f4de                	sd	s7,104(sp)
ffffffffc0204ae0:	892a                	mv	s2,a0
ffffffffc0204ae2:	8bb2                	mv	s7,a2
ffffffffc0204ae4:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204ae6:	862e                	mv	a2,a1
ffffffffc0204ae8:	4681                	li	a3,0
ffffffffc0204aea:	85aa                	mv	a1,a0
ffffffffc0204aec:	854e                	mv	a0,s3
{
ffffffffc0204aee:	f506                	sd	ra,168(sp)
ffffffffc0204af0:	f122                	sd	s0,160(sp)
ffffffffc0204af2:	e152                	sd	s4,128(sp)
ffffffffc0204af4:	fcd6                	sd	s5,120(sp)
ffffffffc0204af6:	f8da                	sd	s6,112(sp)
ffffffffc0204af8:	f0e2                	sd	s8,96(sp)
ffffffffc0204afa:	ece6                	sd	s9,88(sp)
ffffffffc0204afc:	e8ea                	sd	s10,80(sp)
ffffffffc0204afe:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204b00:	b02ff0ef          	jal	ra,ffffffffc0203e02 <user_mem_check>
ffffffffc0204b04:	40050a63          	beqz	a0,ffffffffc0204f18 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204b08:	4641                	li	a2,16
ffffffffc0204b0a:	4581                	li	a1,0
ffffffffc0204b0c:	1808                	addi	a0,sp,48
ffffffffc0204b0e:	643000ef          	jal	ra,ffffffffc0205950 <memset>
    memcpy(local_name, name, len);
ffffffffc0204b12:	47bd                	li	a5,15
ffffffffc0204b14:	8626                	mv	a2,s1
ffffffffc0204b16:	1e97e263          	bltu	a5,s1,ffffffffc0204cfa <do_execve+0x236>
ffffffffc0204b1a:	85ca                	mv	a1,s2
ffffffffc0204b1c:	1808                	addi	a0,sp,48
ffffffffc0204b1e:	645000ef          	jal	ra,ffffffffc0205962 <memcpy>
    if (mm != NULL)
ffffffffc0204b22:	1e098363          	beqz	s3,ffffffffc0204d08 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204b26:	00002517          	auipc	a0,0x2
ffffffffc0204b2a:	50250513          	addi	a0,a0,1282 # ffffffffc0207028 <default_pmm_manager+0x830>
ffffffffc0204b2e:	e9efb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204b32:	000b2797          	auipc	a5,0xb2
ffffffffc0204b36:	bfe7b783          	ld	a5,-1026(a5) # ffffffffc02b6730 <boot_pgdir_pa>
ffffffffc0204b3a:	577d                	li	a4,-1
ffffffffc0204b3c:	177e                	slli	a4,a4,0x3f
ffffffffc0204b3e:	83b1                	srli	a5,a5,0xc
ffffffffc0204b40:	8fd9                	or	a5,a5,a4
ffffffffc0204b42:	18079073          	csrw	satp,a5
ffffffffc0204b46:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc0204b4a:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204b4e:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204b52:	2c070463          	beqz	a4,ffffffffc0204e1a <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204b56:	000db783          	ld	a5,0(s11)
ffffffffc0204b5a:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204b5e:	c2ffe0ef          	jal	ra,ffffffffc020378c <mm_create>
ffffffffc0204b62:	84aa                	mv	s1,a0
ffffffffc0204b64:	1c050d63          	beqz	a0,ffffffffc0204d3e <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204b68:	4505                	li	a0,1
ffffffffc0204b6a:	bc2fd0ef          	jal	ra,ffffffffc0201f2c <alloc_pages>
ffffffffc0204b6e:	3a050963          	beqz	a0,ffffffffc0204f20 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204b72:	000b2c97          	auipc	s9,0xb2
ffffffffc0204b76:	bd6c8c93          	addi	s9,s9,-1066 # ffffffffc02b6748 <pages>
ffffffffc0204b7a:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204b7e:	000b2c17          	auipc	s8,0xb2
ffffffffc0204b82:	bc2c0c13          	addi	s8,s8,-1086 # ffffffffc02b6740 <npage>
    return page - pages + nbase;
ffffffffc0204b86:	00003717          	auipc	a4,0x3
ffffffffc0204b8a:	07a73703          	ld	a4,122(a4) # ffffffffc0207c00 <nbase>
ffffffffc0204b8e:	40d506b3          	sub	a3,a0,a3
ffffffffc0204b92:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204b94:	5afd                	li	s5,-1
ffffffffc0204b96:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204b9a:	96ba                	add	a3,a3,a4
ffffffffc0204b9c:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b9e:	00cad713          	srli	a4,s5,0xc
ffffffffc0204ba2:	ec3a                	sd	a4,24(sp)
ffffffffc0204ba4:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ba6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ba8:	38f77063          	bgeu	a4,a5,ffffffffc0204f28 <do_execve+0x464>
ffffffffc0204bac:	000b2b17          	auipc	s6,0xb2
ffffffffc0204bb0:	bacb0b13          	addi	s6,s6,-1108 # ffffffffc02b6758 <va_pa_offset>
ffffffffc0204bb4:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204bb8:	6605                	lui	a2,0x1
ffffffffc0204bba:	000b2597          	auipc	a1,0xb2
ffffffffc0204bbe:	b7e5b583          	ld	a1,-1154(a1) # ffffffffc02b6738 <boot_pgdir_va>
ffffffffc0204bc2:	9936                	add	s2,s2,a3
ffffffffc0204bc4:	854a                	mv	a0,s2
ffffffffc0204bc6:	59d000ef          	jal	ra,ffffffffc0205962 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204bca:	7782                	ld	a5,32(sp)
ffffffffc0204bcc:	4398                	lw	a4,0(a5)
ffffffffc0204bce:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204bd2:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204bd6:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_cowtest_out_size+0x464b85ff>
ffffffffc0204bda:	14f71863          	bne	a4,a5,ffffffffc0204d2a <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204bde:	7682                	ld	a3,32(sp)
ffffffffc0204be0:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204be4:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204be8:	00371793          	slli	a5,a4,0x3
ffffffffc0204bec:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204bee:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204bf0:	078e                	slli	a5,a5,0x3
ffffffffc0204bf2:	97ce                	add	a5,a5,s3
ffffffffc0204bf4:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204bf6:	00f9fc63          	bgeu	s3,a5,ffffffffc0204c0e <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204bfa:	0009a783          	lw	a5,0(s3)
ffffffffc0204bfe:	4705                	li	a4,1
ffffffffc0204c00:	14e78163          	beq	a5,a4,ffffffffc0204d42 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204c04:	77a2                	ld	a5,40(sp)
ffffffffc0204c06:	03898993          	addi	s3,s3,56
ffffffffc0204c0a:	fef9e8e3          	bltu	s3,a5,ffffffffc0204bfa <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204c0e:	4701                	li	a4,0
ffffffffc0204c10:	46ad                	li	a3,11
ffffffffc0204c12:	00100637          	lui	a2,0x100
ffffffffc0204c16:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204c1a:	8526                	mv	a0,s1
ffffffffc0204c1c:	d03fe0ef          	jal	ra,ffffffffc020391e <mm_map>
ffffffffc0204c20:	892a                	mv	s2,a0
ffffffffc0204c22:	1e051263          	bnez	a0,ffffffffc0204e06 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c26:	6c88                	ld	a0,24(s1)
ffffffffc0204c28:	467d                	li	a2,31
ffffffffc0204c2a:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204c2e:	a79fe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204c32:	38050363          	beqz	a0,ffffffffc0204fb8 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c36:	6c88                	ld	a0,24(s1)
ffffffffc0204c38:	467d                	li	a2,31
ffffffffc0204c3a:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204c3e:	a69fe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204c42:	34050b63          	beqz	a0,ffffffffc0204f98 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c46:	6c88                	ld	a0,24(s1)
ffffffffc0204c48:	467d                	li	a2,31
ffffffffc0204c4a:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204c4e:	a59fe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204c52:	32050363          	beqz	a0,ffffffffc0204f78 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c56:	6c88                	ld	a0,24(s1)
ffffffffc0204c58:	467d                	li	a2,31
ffffffffc0204c5a:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204c5e:	a49fe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204c62:	2e050b63          	beqz	a0,ffffffffc0204f58 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204c66:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204c68:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c6c:	6c94                	ld	a3,24(s1)
ffffffffc0204c6e:	2785                	addiw	a5,a5,1
ffffffffc0204c70:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204c72:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c74:	c02007b7          	lui	a5,0xc0200
ffffffffc0204c78:	2cf6e463          	bltu	a3,a5,ffffffffc0204f40 <do_execve+0x47c>
ffffffffc0204c7c:	000b3783          	ld	a5,0(s6)
ffffffffc0204c80:	577d                	li	a4,-1
ffffffffc0204c82:	177e                	slli	a4,a4,0x3f
ffffffffc0204c84:	8e9d                	sub	a3,a3,a5
ffffffffc0204c86:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204c8a:	f654                	sd	a3,168(a2)
ffffffffc0204c8c:	8fd9                	or	a5,a5,a4
ffffffffc0204c8e:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204c92:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204c94:	4581                	li	a1,0
ffffffffc0204c96:	12000613          	li	a2,288
ffffffffc0204c9a:	8526                	mv	a0,s1
ffffffffc0204c9c:	4b5000ef          	jal	ra,ffffffffc0205950 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204ca0:	7782                	ld	a5,32(sp)
ffffffffc0204ca2:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204ca4:	4785                	li	a5,1
ffffffffc0204ca6:	07fe                	slli	a5,a5,0x1f
ffffffffc0204ca8:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc0204caa:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204cae:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204cb2:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204cb6:	edf7f793          	andi	a5,a5,-289
ffffffffc0204cba:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204cbe:	0b440413          	addi	s0,s0,180
ffffffffc0204cc2:	4641                	li	a2,16
ffffffffc0204cc4:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204cc6:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204cca:	8522                	mv	a0,s0
ffffffffc0204ccc:	485000ef          	jal	ra,ffffffffc0205950 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204cd0:	463d                	li	a2,15
ffffffffc0204cd2:	180c                	addi	a1,sp,48
ffffffffc0204cd4:	8522                	mv	a0,s0
ffffffffc0204cd6:	48d000ef          	jal	ra,ffffffffc0205962 <memcpy>
}
ffffffffc0204cda:	70aa                	ld	ra,168(sp)
ffffffffc0204cdc:	740a                	ld	s0,160(sp)
ffffffffc0204cde:	64ea                	ld	s1,152(sp)
ffffffffc0204ce0:	69aa                	ld	s3,136(sp)
ffffffffc0204ce2:	6a0a                	ld	s4,128(sp)
ffffffffc0204ce4:	7ae6                	ld	s5,120(sp)
ffffffffc0204ce6:	7b46                	ld	s6,112(sp)
ffffffffc0204ce8:	7ba6                	ld	s7,104(sp)
ffffffffc0204cea:	7c06                	ld	s8,96(sp)
ffffffffc0204cec:	6ce6                	ld	s9,88(sp)
ffffffffc0204cee:	6d46                	ld	s10,80(sp)
ffffffffc0204cf0:	6da6                	ld	s11,72(sp)
ffffffffc0204cf2:	854a                	mv	a0,s2
ffffffffc0204cf4:	694a                	ld	s2,144(sp)
ffffffffc0204cf6:	614d                	addi	sp,sp,176
ffffffffc0204cf8:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204cfa:	463d                	li	a2,15
ffffffffc0204cfc:	85ca                	mv	a1,s2
ffffffffc0204cfe:	1808                	addi	a0,sp,48
ffffffffc0204d00:	463000ef          	jal	ra,ffffffffc0205962 <memcpy>
    if (mm != NULL)
ffffffffc0204d04:	e20991e3          	bnez	s3,ffffffffc0204b26 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204d08:	000db783          	ld	a5,0(s11)
ffffffffc0204d0c:	779c                	ld	a5,40(a5)
ffffffffc0204d0e:	e40788e3          	beqz	a5,ffffffffc0204b5e <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204d12:	00003617          	auipc	a2,0x3
ffffffffc0204d16:	81e60613          	addi	a2,a2,-2018 # ffffffffc0207530 <default_pmm_manager+0xd38>
ffffffffc0204d1a:	24200593          	li	a1,578
ffffffffc0204d1e:	00002517          	auipc	a0,0x2
ffffffffc0204d22:	62a50513          	addi	a0,a0,1578 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204d26:	f68fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204d2a:	8526                	mv	a0,s1
ffffffffc0204d2c:	c40ff0ef          	jal	ra,ffffffffc020416c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d30:	8526                	mv	a0,s1
ffffffffc0204d32:	b9bfe0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204d36:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0204d38:	854a                	mv	a0,s2
ffffffffc0204d3a:	94bff0ef          	jal	ra,ffffffffc0204684 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204d3e:	5971                	li	s2,-4
ffffffffc0204d40:	bfe5                	j	ffffffffc0204d38 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204d42:	0289b603          	ld	a2,40(s3)
ffffffffc0204d46:	0209b783          	ld	a5,32(s3)
ffffffffc0204d4a:	1cf66d63          	bltu	a2,a5,ffffffffc0204f24 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204d4e:	0049a783          	lw	a5,4(s3)
ffffffffc0204d52:	0017f693          	andi	a3,a5,1
ffffffffc0204d56:	c291                	beqz	a3,ffffffffc0204d5a <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204d58:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204d5a:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d5e:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204d60:	e779                	bnez	a4,ffffffffc0204e2e <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d62:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d64:	c781                	beqz	a5,ffffffffc0204d6c <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204d66:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204d6a:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204d6c:	0026f793          	andi	a5,a3,2
ffffffffc0204d70:	e3f1                	bnez	a5,ffffffffc0204e34 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204d72:	0046f793          	andi	a5,a3,4
ffffffffc0204d76:	c399                	beqz	a5,ffffffffc0204d7c <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204d78:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204d7c:	0109b583          	ld	a1,16(s3)
ffffffffc0204d80:	4701                	li	a4,0
ffffffffc0204d82:	8526                	mv	a0,s1
ffffffffc0204d84:	b9bfe0ef          	jal	ra,ffffffffc020391e <mm_map>
ffffffffc0204d88:	892a                	mv	s2,a0
ffffffffc0204d8a:	ed35                	bnez	a0,ffffffffc0204e06 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d8c:	0109bb83          	ld	s7,16(s3)
ffffffffc0204d90:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204d92:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204d96:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d9a:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204d9e:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204da0:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204da2:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204da4:	054be963          	bltu	s7,s4,ffffffffc0204df6 <do_execve+0x332>
ffffffffc0204da8:	aa95                	j	ffffffffc0204f1c <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204daa:	6785                	lui	a5,0x1
ffffffffc0204dac:	415b8533          	sub	a0,s7,s5
ffffffffc0204db0:	9abe                	add	s5,s5,a5
ffffffffc0204db2:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204db6:	015a7463          	bgeu	s4,s5,ffffffffc0204dbe <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204dba:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204dbe:	000cb683          	ld	a3,0(s9)
ffffffffc0204dc2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204dc4:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204dc8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204dcc:	8699                	srai	a3,a3,0x6
ffffffffc0204dce:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204dd0:	67e2                	ld	a5,24(sp)
ffffffffc0204dd2:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dd6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dd8:	14b87863          	bgeu	a6,a1,ffffffffc0204f28 <do_execve+0x464>
ffffffffc0204ddc:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204de0:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204de2:	9bb2                	add	s7,s7,a2
ffffffffc0204de4:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204de6:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204de8:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204dea:	379000ef          	jal	ra,ffffffffc0205962 <memcpy>
            start += size, from += size;
ffffffffc0204dee:	6622                	ld	a2,8(sp)
ffffffffc0204df0:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204df2:	054bf363          	bgeu	s7,s4,ffffffffc0204e38 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204df6:	6c88                	ld	a0,24(s1)
ffffffffc0204df8:	866a                	mv	a2,s10
ffffffffc0204dfa:	85d6                	mv	a1,s5
ffffffffc0204dfc:	8abfe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204e00:	842a                	mv	s0,a0
ffffffffc0204e02:	f545                	bnez	a0,ffffffffc0204daa <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204e04:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0204e06:	8526                	mv	a0,s1
ffffffffc0204e08:	c61fe0ef          	jal	ra,ffffffffc0203a68 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204e0c:	8526                	mv	a0,s1
ffffffffc0204e0e:	b5eff0ef          	jal	ra,ffffffffc020416c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204e12:	8526                	mv	a0,s1
ffffffffc0204e14:	ab9fe0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
    return ret;
ffffffffc0204e18:	b705                	j	ffffffffc0204d38 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204e1a:	854e                	mv	a0,s3
ffffffffc0204e1c:	c4dfe0ef          	jal	ra,ffffffffc0203a68 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204e20:	854e                	mv	a0,s3
ffffffffc0204e22:	b4aff0ef          	jal	ra,ffffffffc020416c <put_pgdir>
            mm_destroy(mm);
ffffffffc0204e26:	854e                	mv	a0,s3
ffffffffc0204e28:	aa5fe0ef          	jal	ra,ffffffffc02038cc <mm_destroy>
ffffffffc0204e2c:	b32d                	j	ffffffffc0204b56 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204e2e:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e32:	fb95                	bnez	a5,ffffffffc0204d66 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204e34:	4d5d                	li	s10,23
ffffffffc0204e36:	bf35                	j	ffffffffc0204d72 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204e38:	0109b683          	ld	a3,16(s3)
ffffffffc0204e3c:	0289b903          	ld	s2,40(s3)
ffffffffc0204e40:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204e42:	075bfd63          	bgeu	s7,s5,ffffffffc0204ebc <do_execve+0x3f8>
            if (start == end)
ffffffffc0204e46:	db790fe3          	beq	s2,s7,ffffffffc0204c04 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e4a:	6785                	lui	a5,0x1
ffffffffc0204e4c:	00fb8533          	add	a0,s7,a5
ffffffffc0204e50:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204e54:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204e58:	0b597d63          	bgeu	s2,s5,ffffffffc0204f12 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204e5c:	000cb683          	ld	a3,0(s9)
ffffffffc0204e60:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e62:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204e66:	40d406b3          	sub	a3,s0,a3
ffffffffc0204e6a:	8699                	srai	a3,a3,0x6
ffffffffc0204e6c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e6e:	67e2                	ld	a5,24(sp)
ffffffffc0204e70:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e74:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e76:	0ac5f963          	bgeu	a1,a2,ffffffffc0204f28 <do_execve+0x464>
ffffffffc0204e7a:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e7e:	8652                	mv	a2,s4
ffffffffc0204e80:	4581                	li	a1,0
ffffffffc0204e82:	96c2                	add	a3,a3,a6
ffffffffc0204e84:	9536                	add	a0,a0,a3
ffffffffc0204e86:	2cb000ef          	jal	ra,ffffffffc0205950 <memset>
            start += size;
ffffffffc0204e8a:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204e8e:	03597463          	bgeu	s2,s5,ffffffffc0204eb6 <do_execve+0x3f2>
ffffffffc0204e92:	d6e909e3          	beq	s2,a4,ffffffffc0204c04 <do_execve+0x140>
ffffffffc0204e96:	00002697          	auipc	a3,0x2
ffffffffc0204e9a:	6c268693          	addi	a3,a3,1730 # ffffffffc0207558 <default_pmm_manager+0xd60>
ffffffffc0204e9e:	00001617          	auipc	a2,0x1
ffffffffc0204ea2:	5aa60613          	addi	a2,a2,1450 # ffffffffc0206448 <commands+0x860>
ffffffffc0204ea6:	2ab00593          	li	a1,683
ffffffffc0204eaa:	00002517          	auipc	a0,0x2
ffffffffc0204eae:	49e50513          	addi	a0,a0,1182 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204eb2:	ddcfb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204eb6:	ff5710e3          	bne	a4,s5,ffffffffc0204e96 <do_execve+0x3d2>
ffffffffc0204eba:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204ebc:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204c04 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ec0:	6c88                	ld	a0,24(s1)
ffffffffc0204ec2:	866a                	mv	a2,s10
ffffffffc0204ec4:	85d6                	mv	a1,s5
ffffffffc0204ec6:	fe0fe0ef          	jal	ra,ffffffffc02036a6 <pgdir_alloc_page>
ffffffffc0204eca:	842a                	mv	s0,a0
ffffffffc0204ecc:	dd05                	beqz	a0,ffffffffc0204e04 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204ece:	6785                	lui	a5,0x1
ffffffffc0204ed0:	415b8533          	sub	a0,s7,s5
ffffffffc0204ed4:	9abe                	add	s5,s5,a5
ffffffffc0204ed6:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204eda:	01597463          	bgeu	s2,s5,ffffffffc0204ee2 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204ede:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204ee2:	000cb683          	ld	a3,0(s9)
ffffffffc0204ee6:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ee8:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204eec:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ef0:	8699                	srai	a3,a3,0x6
ffffffffc0204ef2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ef4:	67e2                	ld	a5,24(sp)
ffffffffc0204ef6:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204efa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204efc:	02b87663          	bgeu	a6,a1,ffffffffc0204f28 <do_execve+0x464>
ffffffffc0204f00:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204f04:	4581                	li	a1,0
            start += size;
ffffffffc0204f06:	9bb2                	add	s7,s7,a2
ffffffffc0204f08:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204f0a:	9536                	add	a0,a0,a3
ffffffffc0204f0c:	245000ef          	jal	ra,ffffffffc0205950 <memset>
ffffffffc0204f10:	b775                	j	ffffffffc0204ebc <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204f12:	417a8a33          	sub	s4,s5,s7
ffffffffc0204f16:	b799                	j	ffffffffc0204e5c <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204f18:	5975                	li	s2,-3
ffffffffc0204f1a:	b3c1                	j	ffffffffc0204cda <do_execve+0x216>
        while (start < end)
ffffffffc0204f1c:	86de                	mv	a3,s7
ffffffffc0204f1e:	bf39                	j	ffffffffc0204e3c <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204f20:	5971                	li	s2,-4
ffffffffc0204f22:	bdc5                	j	ffffffffc0204e12 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204f24:	5961                	li	s2,-8
ffffffffc0204f26:	b5c5                	j	ffffffffc0204e06 <do_execve+0x342>
ffffffffc0204f28:	00002617          	auipc	a2,0x2
ffffffffc0204f2c:	90860613          	addi	a2,a2,-1784 # ffffffffc0206830 <default_pmm_manager+0x38>
ffffffffc0204f30:	07100593          	li	a1,113
ffffffffc0204f34:	00002517          	auipc	a0,0x2
ffffffffc0204f38:	92450513          	addi	a0,a0,-1756 # ffffffffc0206858 <default_pmm_manager+0x60>
ffffffffc0204f3c:	d52fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204f40:	00002617          	auipc	a2,0x2
ffffffffc0204f44:	99860613          	addi	a2,a2,-1640 # ffffffffc02068d8 <default_pmm_manager+0xe0>
ffffffffc0204f48:	2ca00593          	li	a1,714
ffffffffc0204f4c:	00002517          	auipc	a0,0x2
ffffffffc0204f50:	3fc50513          	addi	a0,a0,1020 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204f54:	d3afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f58:	00002697          	auipc	a3,0x2
ffffffffc0204f5c:	71868693          	addi	a3,a3,1816 # ffffffffc0207670 <default_pmm_manager+0xe78>
ffffffffc0204f60:	00001617          	auipc	a2,0x1
ffffffffc0204f64:	4e860613          	addi	a2,a2,1256 # ffffffffc0206448 <commands+0x860>
ffffffffc0204f68:	2c500593          	li	a1,709
ffffffffc0204f6c:	00002517          	auipc	a0,0x2
ffffffffc0204f70:	3dc50513          	addi	a0,a0,988 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204f74:	d1afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f78:	00002697          	auipc	a3,0x2
ffffffffc0204f7c:	6b068693          	addi	a3,a3,1712 # ffffffffc0207628 <default_pmm_manager+0xe30>
ffffffffc0204f80:	00001617          	auipc	a2,0x1
ffffffffc0204f84:	4c860613          	addi	a2,a2,1224 # ffffffffc0206448 <commands+0x860>
ffffffffc0204f88:	2c400593          	li	a1,708
ffffffffc0204f8c:	00002517          	auipc	a0,0x2
ffffffffc0204f90:	3bc50513          	addi	a0,a0,956 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204f94:	cfafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f98:	00002697          	auipc	a3,0x2
ffffffffc0204f9c:	64868693          	addi	a3,a3,1608 # ffffffffc02075e0 <default_pmm_manager+0xde8>
ffffffffc0204fa0:	00001617          	auipc	a2,0x1
ffffffffc0204fa4:	4a860613          	addi	a2,a2,1192 # ffffffffc0206448 <commands+0x860>
ffffffffc0204fa8:	2c300593          	li	a1,707
ffffffffc0204fac:	00002517          	auipc	a0,0x2
ffffffffc0204fb0:	39c50513          	addi	a0,a0,924 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204fb4:	cdafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204fb8:	00002697          	auipc	a3,0x2
ffffffffc0204fbc:	5e068693          	addi	a3,a3,1504 # ffffffffc0207598 <default_pmm_manager+0xda0>
ffffffffc0204fc0:	00001617          	auipc	a2,0x1
ffffffffc0204fc4:	48860613          	addi	a2,a2,1160 # ffffffffc0206448 <commands+0x860>
ffffffffc0204fc8:	2c200593          	li	a1,706
ffffffffc0204fcc:	00002517          	auipc	a0,0x2
ffffffffc0204fd0:	37c50513          	addi	a0,a0,892 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0204fd4:	cbafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204fd8 <do_yield>:
    current->need_resched = 1;
ffffffffc0204fd8:	000b1797          	auipc	a5,0xb1
ffffffffc0204fdc:	7887b783          	ld	a5,1928(a5) # ffffffffc02b6760 <current>
ffffffffc0204fe0:	4705                	li	a4,1
ffffffffc0204fe2:	ef98                	sd	a4,24(a5)
}
ffffffffc0204fe4:	4501                	li	a0,0
ffffffffc0204fe6:	8082                	ret

ffffffffc0204fe8 <do_wait>:
{
ffffffffc0204fe8:	1101                	addi	sp,sp,-32
ffffffffc0204fea:	e822                	sd	s0,16(sp)
ffffffffc0204fec:	e426                	sd	s1,8(sp)
ffffffffc0204fee:	ec06                	sd	ra,24(sp)
ffffffffc0204ff0:	842e                	mv	s0,a1
ffffffffc0204ff2:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204ff4:	c999                	beqz	a1,ffffffffc020500a <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204ff6:	000b1797          	auipc	a5,0xb1
ffffffffc0204ffa:	76a7b783          	ld	a5,1898(a5) # ffffffffc02b6760 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ffe:	7788                	ld	a0,40(a5)
ffffffffc0205000:	4685                	li	a3,1
ffffffffc0205002:	4611                	li	a2,4
ffffffffc0205004:	dfffe0ef          	jal	ra,ffffffffc0203e02 <user_mem_check>
ffffffffc0205008:	c909                	beqz	a0,ffffffffc020501a <do_wait+0x32>
ffffffffc020500a:	85a2                	mv	a1,s0
}
ffffffffc020500c:	6442                	ld	s0,16(sp)
ffffffffc020500e:	60e2                	ld	ra,24(sp)
ffffffffc0205010:	8526                	mv	a0,s1
ffffffffc0205012:	64a2                	ld	s1,8(sp)
ffffffffc0205014:	6105                	addi	sp,sp,32
ffffffffc0205016:	fb8ff06f          	j	ffffffffc02047ce <do_wait.part.0>
ffffffffc020501a:	60e2                	ld	ra,24(sp)
ffffffffc020501c:	6442                	ld	s0,16(sp)
ffffffffc020501e:	64a2                	ld	s1,8(sp)
ffffffffc0205020:	5575                	li	a0,-3
ffffffffc0205022:	6105                	addi	sp,sp,32
ffffffffc0205024:	8082                	ret

ffffffffc0205026 <do_kill>:
{
ffffffffc0205026:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205028:	6789                	lui	a5,0x2
{
ffffffffc020502a:	e406                	sd	ra,8(sp)
ffffffffc020502c:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc020502e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205032:	17f9                	addi	a5,a5,-2
ffffffffc0205034:	02e7e963          	bltu	a5,a4,ffffffffc0205066 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205038:	842a                	mv	s0,a0
ffffffffc020503a:	45a9                	li	a1,10
ffffffffc020503c:	2501                	sext.w	a0,a0
ffffffffc020503e:	46c000ef          	jal	ra,ffffffffc02054aa <hash32>
ffffffffc0205042:	02051793          	slli	a5,a0,0x20
ffffffffc0205046:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020504a:	000ad797          	auipc	a5,0xad
ffffffffc020504e:	6a678793          	addi	a5,a5,1702 # ffffffffc02b26f0 <hash_list>
ffffffffc0205052:	953e                	add	a0,a0,a5
ffffffffc0205054:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205056:	a029                	j	ffffffffc0205060 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205058:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020505c:	00870b63          	beq	a4,s0,ffffffffc0205072 <do_kill+0x4c>
ffffffffc0205060:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205062:	fef51be3          	bne	a0,a5,ffffffffc0205058 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205066:	5475                	li	s0,-3
}
ffffffffc0205068:	60a2                	ld	ra,8(sp)
ffffffffc020506a:	8522                	mv	a0,s0
ffffffffc020506c:	6402                	ld	s0,0(sp)
ffffffffc020506e:	0141                	addi	sp,sp,16
ffffffffc0205070:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0205072:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205076:	00177693          	andi	a3,a4,1
ffffffffc020507a:	e295                	bnez	a3,ffffffffc020509e <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc020507c:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc020507e:	00176713          	ori	a4,a4,1
ffffffffc0205082:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205086:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205088:	fe06d0e3          	bgez	a3,ffffffffc0205068 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc020508c:	f2878513          	addi	a0,a5,-216
ffffffffc0205090:	22e000ef          	jal	ra,ffffffffc02052be <wakeup_proc>
}
ffffffffc0205094:	60a2                	ld	ra,8(sp)
ffffffffc0205096:	8522                	mv	a0,s0
ffffffffc0205098:	6402                	ld	s0,0(sp)
ffffffffc020509a:	0141                	addi	sp,sp,16
ffffffffc020509c:	8082                	ret
        return -E_KILLED;
ffffffffc020509e:	545d                	li	s0,-9
ffffffffc02050a0:	b7e1                	j	ffffffffc0205068 <do_kill+0x42>

ffffffffc02050a2 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02050a2:	1101                	addi	sp,sp,-32
ffffffffc02050a4:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050a6:	000b1797          	auipc	a5,0xb1
ffffffffc02050aa:	64a78793          	addi	a5,a5,1610 # ffffffffc02b66f0 <proc_list>
ffffffffc02050ae:	ec06                	sd	ra,24(sp)
ffffffffc02050b0:	e822                	sd	s0,16(sp)
ffffffffc02050b2:	e04a                	sd	s2,0(sp)
ffffffffc02050b4:	000ad497          	auipc	s1,0xad
ffffffffc02050b8:	63c48493          	addi	s1,s1,1596 # ffffffffc02b26f0 <hash_list>
ffffffffc02050bc:	e79c                	sd	a5,8(a5)
ffffffffc02050be:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02050c0:	000b1717          	auipc	a4,0xb1
ffffffffc02050c4:	63070713          	addi	a4,a4,1584 # ffffffffc02b66f0 <proc_list>
ffffffffc02050c8:	87a6                	mv	a5,s1
ffffffffc02050ca:	e79c                	sd	a5,8(a5)
ffffffffc02050cc:	e39c                	sd	a5,0(a5)
ffffffffc02050ce:	07c1                	addi	a5,a5,16
ffffffffc02050d0:	fef71de3          	bne	a4,a5,ffffffffc02050ca <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02050d4:	f8bfe0ef          	jal	ra,ffffffffc020405e <alloc_proc>
ffffffffc02050d8:	000b1917          	auipc	s2,0xb1
ffffffffc02050dc:	69090913          	addi	s2,s2,1680 # ffffffffc02b6768 <idleproc>
ffffffffc02050e0:	00a93023          	sd	a0,0(s2)
ffffffffc02050e4:	0e050f63          	beqz	a0,ffffffffc02051e2 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02050e8:	4789                	li	a5,2
ffffffffc02050ea:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02050ec:	00003797          	auipc	a5,0x3
ffffffffc02050f0:	f1478793          	addi	a5,a5,-236 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050f4:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02050f8:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc02050fa:	4785                	li	a5,1
ffffffffc02050fc:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050fe:	4641                	li	a2,16
ffffffffc0205100:	4581                	li	a1,0
ffffffffc0205102:	8522                	mv	a0,s0
ffffffffc0205104:	04d000ef          	jal	ra,ffffffffc0205950 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205108:	463d                	li	a2,15
ffffffffc020510a:	00002597          	auipc	a1,0x2
ffffffffc020510e:	5c658593          	addi	a1,a1,1478 # ffffffffc02076d0 <default_pmm_manager+0xed8>
ffffffffc0205112:	8522                	mv	a0,s0
ffffffffc0205114:	04f000ef          	jal	ra,ffffffffc0205962 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205118:	000b1717          	auipc	a4,0xb1
ffffffffc020511c:	66070713          	addi	a4,a4,1632 # ffffffffc02b6778 <nr_process>
ffffffffc0205120:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205122:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205126:	4601                	li	a2,0
    nr_process++;
ffffffffc0205128:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020512a:	4581                	li	a1,0
ffffffffc020512c:	00000517          	auipc	a0,0x0
ffffffffc0205130:	87450513          	addi	a0,a0,-1932 # ffffffffc02049a0 <init_main>
    nr_process++;
ffffffffc0205134:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205136:	000b1797          	auipc	a5,0xb1
ffffffffc020513a:	62d7b523          	sd	a3,1578(a5) # ffffffffc02b6760 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020513e:	cf6ff0ef          	jal	ra,ffffffffc0204634 <kernel_thread>
ffffffffc0205142:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205144:	08a05363          	blez	a0,ffffffffc02051ca <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205148:	6789                	lui	a5,0x2
ffffffffc020514a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020514e:	17f9                	addi	a5,a5,-2
ffffffffc0205150:	2501                	sext.w	a0,a0
ffffffffc0205152:	02e7e363          	bltu	a5,a4,ffffffffc0205178 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205156:	45a9                	li	a1,10
ffffffffc0205158:	352000ef          	jal	ra,ffffffffc02054aa <hash32>
ffffffffc020515c:	02051793          	slli	a5,a0,0x20
ffffffffc0205160:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205164:	96a6                	add	a3,a3,s1
ffffffffc0205166:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205168:	a029                	j	ffffffffc0205172 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc020516a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc020516e:	04870b63          	beq	a4,s0,ffffffffc02051c4 <proc_init+0x122>
    return listelm->next;
ffffffffc0205172:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205174:	fef69be3          	bne	a3,a5,ffffffffc020516a <proc_init+0xc8>
    return NULL;
ffffffffc0205178:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020517a:	0b478493          	addi	s1,a5,180
ffffffffc020517e:	4641                	li	a2,16
ffffffffc0205180:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205182:	000b1417          	auipc	s0,0xb1
ffffffffc0205186:	5ee40413          	addi	s0,s0,1518 # ffffffffc02b6770 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020518a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020518c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020518e:	7c2000ef          	jal	ra,ffffffffc0205950 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205192:	463d                	li	a2,15
ffffffffc0205194:	00002597          	auipc	a1,0x2
ffffffffc0205198:	56458593          	addi	a1,a1,1380 # ffffffffc02076f8 <default_pmm_manager+0xf00>
ffffffffc020519c:	8526                	mv	a0,s1
ffffffffc020519e:	7c4000ef          	jal	ra,ffffffffc0205962 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02051a2:	00093783          	ld	a5,0(s2)
ffffffffc02051a6:	cbb5                	beqz	a5,ffffffffc020521a <proc_init+0x178>
ffffffffc02051a8:	43dc                	lw	a5,4(a5)
ffffffffc02051aa:	eba5                	bnez	a5,ffffffffc020521a <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02051ac:	601c                	ld	a5,0(s0)
ffffffffc02051ae:	c7b1                	beqz	a5,ffffffffc02051fa <proc_init+0x158>
ffffffffc02051b0:	43d8                	lw	a4,4(a5)
ffffffffc02051b2:	4785                	li	a5,1
ffffffffc02051b4:	04f71363          	bne	a4,a5,ffffffffc02051fa <proc_init+0x158>
}
ffffffffc02051b8:	60e2                	ld	ra,24(sp)
ffffffffc02051ba:	6442                	ld	s0,16(sp)
ffffffffc02051bc:	64a2                	ld	s1,8(sp)
ffffffffc02051be:	6902                	ld	s2,0(sp)
ffffffffc02051c0:	6105                	addi	sp,sp,32
ffffffffc02051c2:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02051c4:	f2878793          	addi	a5,a5,-216
ffffffffc02051c8:	bf4d                	j	ffffffffc020517a <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02051ca:	00002617          	auipc	a2,0x2
ffffffffc02051ce:	50e60613          	addi	a2,a2,1294 # ffffffffc02076d8 <default_pmm_manager+0xee0>
ffffffffc02051d2:	3ec00593          	li	a1,1004
ffffffffc02051d6:	00002517          	auipc	a0,0x2
ffffffffc02051da:	17250513          	addi	a0,a0,370 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc02051de:	ab0fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02051e2:	00002617          	auipc	a2,0x2
ffffffffc02051e6:	4d660613          	addi	a2,a2,1238 # ffffffffc02076b8 <default_pmm_manager+0xec0>
ffffffffc02051ea:	3dd00593          	li	a1,989
ffffffffc02051ee:	00002517          	auipc	a0,0x2
ffffffffc02051f2:	15a50513          	addi	a0,a0,346 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc02051f6:	a98fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02051fa:	00002697          	auipc	a3,0x2
ffffffffc02051fe:	52e68693          	addi	a3,a3,1326 # ffffffffc0207728 <default_pmm_manager+0xf30>
ffffffffc0205202:	00001617          	auipc	a2,0x1
ffffffffc0205206:	24660613          	addi	a2,a2,582 # ffffffffc0206448 <commands+0x860>
ffffffffc020520a:	3f300593          	li	a1,1011
ffffffffc020520e:	00002517          	auipc	a0,0x2
ffffffffc0205212:	13a50513          	addi	a0,a0,314 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0205216:	a78fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020521a:	00002697          	auipc	a3,0x2
ffffffffc020521e:	4e668693          	addi	a3,a3,1254 # ffffffffc0207700 <default_pmm_manager+0xf08>
ffffffffc0205222:	00001617          	auipc	a2,0x1
ffffffffc0205226:	22660613          	addi	a2,a2,550 # ffffffffc0206448 <commands+0x860>
ffffffffc020522a:	3f200593          	li	a1,1010
ffffffffc020522e:	00002517          	auipc	a0,0x2
ffffffffc0205232:	11a50513          	addi	a0,a0,282 # ffffffffc0207348 <default_pmm_manager+0xb50>
ffffffffc0205236:	a58fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020523a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020523a:	1141                	addi	sp,sp,-16
ffffffffc020523c:	e022                	sd	s0,0(sp)
ffffffffc020523e:	e406                	sd	ra,8(sp)
ffffffffc0205240:	000b1417          	auipc	s0,0xb1
ffffffffc0205244:	52040413          	addi	s0,s0,1312 # ffffffffc02b6760 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205248:	6018                	ld	a4,0(s0)
ffffffffc020524a:	6f1c                	ld	a5,24(a4)
ffffffffc020524c:	dffd                	beqz	a5,ffffffffc020524a <cpu_idle+0x10>
        {
            schedule();
ffffffffc020524e:	0f0000ef          	jal	ra,ffffffffc020533e <schedule>
ffffffffc0205252:	bfdd                	j	ffffffffc0205248 <cpu_idle+0xe>

ffffffffc0205254 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205254:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205258:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020525c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020525e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205260:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205264:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205268:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020526c:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205270:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205274:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205278:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020527c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205280:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205284:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205288:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020528c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205290:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205292:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205294:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205298:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020529c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02052a0:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02052a4:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02052a8:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02052ac:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02052b0:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02052b4:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02052b8:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02052bc:	8082                	ret

ffffffffc02052be <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02052be:	4118                	lw	a4,0(a0)
{
ffffffffc02052c0:	1101                	addi	sp,sp,-32
ffffffffc02052c2:	ec06                	sd	ra,24(sp)
ffffffffc02052c4:	e822                	sd	s0,16(sp)
ffffffffc02052c6:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02052c8:	478d                	li	a5,3
ffffffffc02052ca:	04f70b63          	beq	a4,a5,ffffffffc0205320 <wakeup_proc+0x62>
ffffffffc02052ce:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02052d0:	100027f3          	csrr	a5,sstatus
ffffffffc02052d4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02052d6:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02052d8:	ef9d                	bnez	a5,ffffffffc0205316 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02052da:	4789                	li	a5,2
ffffffffc02052dc:	02f70163          	beq	a4,a5,ffffffffc02052fe <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02052e0:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02052e2:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02052e6:	e491                	bnez	s1,ffffffffc02052f2 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052e8:	60e2                	ld	ra,24(sp)
ffffffffc02052ea:	6442                	ld	s0,16(sp)
ffffffffc02052ec:	64a2                	ld	s1,8(sp)
ffffffffc02052ee:	6105                	addi	sp,sp,32
ffffffffc02052f0:	8082                	ret
ffffffffc02052f2:	6442                	ld	s0,16(sp)
ffffffffc02052f4:	60e2                	ld	ra,24(sp)
ffffffffc02052f6:	64a2                	ld	s1,8(sp)
ffffffffc02052f8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02052fa:	eb4fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02052fe:	00002617          	auipc	a2,0x2
ffffffffc0205302:	48a60613          	addi	a2,a2,1162 # ffffffffc0207788 <default_pmm_manager+0xf90>
ffffffffc0205306:	45d1                	li	a1,20
ffffffffc0205308:	00002517          	auipc	a0,0x2
ffffffffc020530c:	46850513          	addi	a0,a0,1128 # ffffffffc0207770 <default_pmm_manager+0xf78>
ffffffffc0205310:	9e6fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205314:	bfc9                	j	ffffffffc02052e6 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205316:	e9efb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020531a:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020531c:	4485                	li	s1,1
ffffffffc020531e:	bf75                	j	ffffffffc02052da <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205320:	00002697          	auipc	a3,0x2
ffffffffc0205324:	43068693          	addi	a3,a3,1072 # ffffffffc0207750 <default_pmm_manager+0xf58>
ffffffffc0205328:	00001617          	auipc	a2,0x1
ffffffffc020532c:	12060613          	addi	a2,a2,288 # ffffffffc0206448 <commands+0x860>
ffffffffc0205330:	45a5                	li	a1,9
ffffffffc0205332:	00002517          	auipc	a0,0x2
ffffffffc0205336:	43e50513          	addi	a0,a0,1086 # ffffffffc0207770 <default_pmm_manager+0xf78>
ffffffffc020533a:	954fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020533e <schedule>:

void schedule(void)
{
ffffffffc020533e:	1141                	addi	sp,sp,-16
ffffffffc0205340:	e406                	sd	ra,8(sp)
ffffffffc0205342:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205344:	100027f3          	csrr	a5,sstatus
ffffffffc0205348:	8b89                	andi	a5,a5,2
ffffffffc020534a:	4401                	li	s0,0
ffffffffc020534c:	efbd                	bnez	a5,ffffffffc02053ca <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020534e:	000b1897          	auipc	a7,0xb1
ffffffffc0205352:	4128b883          	ld	a7,1042(a7) # ffffffffc02b6760 <current>
ffffffffc0205356:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020535a:	000b1517          	auipc	a0,0xb1
ffffffffc020535e:	40e53503          	ld	a0,1038(a0) # ffffffffc02b6768 <idleproc>
ffffffffc0205362:	04a88e63          	beq	a7,a0,ffffffffc02053be <schedule+0x80>
ffffffffc0205366:	0c888693          	addi	a3,a7,200
ffffffffc020536a:	000b1617          	auipc	a2,0xb1
ffffffffc020536e:	38660613          	addi	a2,a2,902 # ffffffffc02b66f0 <proc_list>
        le = last;
ffffffffc0205372:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205374:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205376:	4809                	li	a6,2
ffffffffc0205378:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020537a:	00c78863          	beq	a5,a2,ffffffffc020538a <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc020537e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205382:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205386:	03070163          	beq	a4,a6,ffffffffc02053a8 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020538a:	fef697e3          	bne	a3,a5,ffffffffc0205378 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020538e:	ed89                	bnez	a1,ffffffffc02053a8 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205390:	451c                	lw	a5,8(a0)
ffffffffc0205392:	2785                	addiw	a5,a5,1
ffffffffc0205394:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205396:	00a88463          	beq	a7,a0,ffffffffc020539e <schedule+0x60>
        {
            proc_run(next);
ffffffffc020539a:	e49fe0ef          	jal	ra,ffffffffc02041e2 <proc_run>
    if (flag)
ffffffffc020539e:	e819                	bnez	s0,ffffffffc02053b4 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02053a0:	60a2                	ld	ra,8(sp)
ffffffffc02053a2:	6402                	ld	s0,0(sp)
ffffffffc02053a4:	0141                	addi	sp,sp,16
ffffffffc02053a6:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02053a8:	4198                	lw	a4,0(a1)
ffffffffc02053aa:	4789                	li	a5,2
ffffffffc02053ac:	fef712e3          	bne	a4,a5,ffffffffc0205390 <schedule+0x52>
ffffffffc02053b0:	852e                	mv	a0,a1
ffffffffc02053b2:	bff9                	j	ffffffffc0205390 <schedule+0x52>
}
ffffffffc02053b4:	6402                	ld	s0,0(sp)
ffffffffc02053b6:	60a2                	ld	ra,8(sp)
ffffffffc02053b8:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02053ba:	df4fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02053be:	000b1617          	auipc	a2,0xb1
ffffffffc02053c2:	33260613          	addi	a2,a2,818 # ffffffffc02b66f0 <proc_list>
ffffffffc02053c6:	86b2                	mv	a3,a2
ffffffffc02053c8:	b76d                	j	ffffffffc0205372 <schedule+0x34>
        intr_disable();
ffffffffc02053ca:	deafb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02053ce:	4405                	li	s0,1
ffffffffc02053d0:	bfbd                	j	ffffffffc020534e <schedule+0x10>

ffffffffc02053d2 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02053d2:	000b1797          	auipc	a5,0xb1
ffffffffc02053d6:	38e7b783          	ld	a5,910(a5) # ffffffffc02b6760 <current>
}
ffffffffc02053da:	43c8                	lw	a0,4(a5)
ffffffffc02053dc:	8082                	ret

ffffffffc02053de <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02053de:	4501                	li	a0,0
ffffffffc02053e0:	8082                	ret

ffffffffc02053e2 <sys_putc>:
    cputchar(c);
ffffffffc02053e2:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02053e4:	1141                	addi	sp,sp,-16
ffffffffc02053e6:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02053e8:	de3fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02053ec:	60a2                	ld	ra,8(sp)
ffffffffc02053ee:	4501                	li	a0,0
ffffffffc02053f0:	0141                	addi	sp,sp,16
ffffffffc02053f2:	8082                	ret

ffffffffc02053f4 <sys_kill>:
    return do_kill(pid);
ffffffffc02053f4:	4108                	lw	a0,0(a0)
ffffffffc02053f6:	c31ff06f          	j	ffffffffc0205026 <do_kill>

ffffffffc02053fa <sys_yield>:
    return do_yield();
ffffffffc02053fa:	bdfff06f          	j	ffffffffc0204fd8 <do_yield>

ffffffffc02053fe <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02053fe:	6d14                	ld	a3,24(a0)
ffffffffc0205400:	6910                	ld	a2,16(a0)
ffffffffc0205402:	650c                	ld	a1,8(a0)
ffffffffc0205404:	6108                	ld	a0,0(a0)
ffffffffc0205406:	ebeff06f          	j	ffffffffc0204ac4 <do_execve>

ffffffffc020540a <sys_wait>:
    return do_wait(pid, store);
ffffffffc020540a:	650c                	ld	a1,8(a0)
ffffffffc020540c:	4108                	lw	a0,0(a0)
ffffffffc020540e:	bdbff06f          	j	ffffffffc0204fe8 <do_wait>

ffffffffc0205412 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205412:	000b1797          	auipc	a5,0xb1
ffffffffc0205416:	34e7b783          	ld	a5,846(a5) # ffffffffc02b6760 <current>
ffffffffc020541a:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020541c:	4501                	li	a0,0
ffffffffc020541e:	6a0c                	ld	a1,16(a2)
ffffffffc0205420:	e2ffe06f          	j	ffffffffc020424e <do_fork>

ffffffffc0205424 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205424:	4108                	lw	a0,0(a0)
ffffffffc0205426:	a5eff06f          	j	ffffffffc0204684 <do_exit>

ffffffffc020542a <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020542a:	715d                	addi	sp,sp,-80
ffffffffc020542c:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020542e:	000b1497          	auipc	s1,0xb1
ffffffffc0205432:	33248493          	addi	s1,s1,818 # ffffffffc02b6760 <current>
ffffffffc0205436:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205438:	e0a2                	sd	s0,64(sp)
ffffffffc020543a:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020543c:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020543e:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205440:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205442:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205446:	0327ee63          	bltu	a5,s2,ffffffffc0205482 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020544a:	00391713          	slli	a4,s2,0x3
ffffffffc020544e:	00002797          	auipc	a5,0x2
ffffffffc0205452:	3a278793          	addi	a5,a5,930 # ffffffffc02077f0 <syscalls>
ffffffffc0205456:	97ba                	add	a5,a5,a4
ffffffffc0205458:	639c                	ld	a5,0(a5)
ffffffffc020545a:	c785                	beqz	a5,ffffffffc0205482 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020545c:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020545e:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205460:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205462:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205464:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205466:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205468:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020546a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020546c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020546e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205470:	0028                	addi	a0,sp,8
ffffffffc0205472:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205474:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205476:	e828                	sd	a0,80(s0)
}
ffffffffc0205478:	6406                	ld	s0,64(sp)
ffffffffc020547a:	74e2                	ld	s1,56(sp)
ffffffffc020547c:	7942                	ld	s2,48(sp)
ffffffffc020547e:	6161                	addi	sp,sp,80
ffffffffc0205480:	8082                	ret
    print_trapframe(tf);
ffffffffc0205482:	8522                	mv	a0,s0
ffffffffc0205484:	f20fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205488:	609c                	ld	a5,0(s1)
ffffffffc020548a:	86ca                	mv	a3,s2
ffffffffc020548c:	00002617          	auipc	a2,0x2
ffffffffc0205490:	31c60613          	addi	a2,a2,796 # ffffffffc02077a8 <default_pmm_manager+0xfb0>
ffffffffc0205494:	43d8                	lw	a4,4(a5)
ffffffffc0205496:	06200593          	li	a1,98
ffffffffc020549a:	0b478793          	addi	a5,a5,180
ffffffffc020549e:	00002517          	auipc	a0,0x2
ffffffffc02054a2:	33a50513          	addi	a0,a0,826 # ffffffffc02077d8 <default_pmm_manager+0xfe0>
ffffffffc02054a6:	fe9fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02054aa <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02054aa:	9e3707b7          	lui	a5,0x9e370
ffffffffc02054ae:	2785                	addiw	a5,a5,1
ffffffffc02054b0:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02054b4:	02000793          	li	a5,32
ffffffffc02054b8:	9f8d                	subw	a5,a5,a1
}
ffffffffc02054ba:	00f5553b          	srlw	a0,a0,a5
ffffffffc02054be:	8082                	ret

ffffffffc02054c0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02054c0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054c4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02054c6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054ca:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02054cc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02054d0:	f022                	sd	s0,32(sp)
ffffffffc02054d2:	ec26                	sd	s1,24(sp)
ffffffffc02054d4:	e84a                	sd	s2,16(sp)
ffffffffc02054d6:	f406                	sd	ra,40(sp)
ffffffffc02054d8:	e44e                	sd	s3,8(sp)
ffffffffc02054da:	84aa                	mv	s1,a0
ffffffffc02054dc:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02054de:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02054e2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02054e4:	03067e63          	bgeu	a2,a6,ffffffffc0205520 <printnum+0x60>
ffffffffc02054e8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02054ea:	00805763          	blez	s0,ffffffffc02054f8 <printnum+0x38>
ffffffffc02054ee:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02054f0:	85ca                	mv	a1,s2
ffffffffc02054f2:	854e                	mv	a0,s3
ffffffffc02054f4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02054f6:	fc65                	bnez	s0,ffffffffc02054ee <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02054f8:	1a02                	slli	s4,s4,0x20
ffffffffc02054fa:	00002797          	auipc	a5,0x2
ffffffffc02054fe:	3f678793          	addi	a5,a5,1014 # ffffffffc02078f0 <syscalls+0x100>
ffffffffc0205502:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205506:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205508:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020550a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020550e:	70a2                	ld	ra,40(sp)
ffffffffc0205510:	69a2                	ld	s3,8(sp)
ffffffffc0205512:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205514:	85ca                	mv	a1,s2
ffffffffc0205516:	87a6                	mv	a5,s1
}
ffffffffc0205518:	6942                	ld	s2,16(sp)
ffffffffc020551a:	64e2                	ld	s1,24(sp)
ffffffffc020551c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020551e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205520:	03065633          	divu	a2,a2,a6
ffffffffc0205524:	8722                	mv	a4,s0
ffffffffc0205526:	f9bff0ef          	jal	ra,ffffffffc02054c0 <printnum>
ffffffffc020552a:	b7f9                	j	ffffffffc02054f8 <printnum+0x38>

ffffffffc020552c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020552c:	7119                	addi	sp,sp,-128
ffffffffc020552e:	f4a6                	sd	s1,104(sp)
ffffffffc0205530:	f0ca                	sd	s2,96(sp)
ffffffffc0205532:	ecce                	sd	s3,88(sp)
ffffffffc0205534:	e8d2                	sd	s4,80(sp)
ffffffffc0205536:	e4d6                	sd	s5,72(sp)
ffffffffc0205538:	e0da                	sd	s6,64(sp)
ffffffffc020553a:	fc5e                	sd	s7,56(sp)
ffffffffc020553c:	f06a                	sd	s10,32(sp)
ffffffffc020553e:	fc86                	sd	ra,120(sp)
ffffffffc0205540:	f8a2                	sd	s0,112(sp)
ffffffffc0205542:	f862                	sd	s8,48(sp)
ffffffffc0205544:	f466                	sd	s9,40(sp)
ffffffffc0205546:	ec6e                	sd	s11,24(sp)
ffffffffc0205548:	892a                	mv	s2,a0
ffffffffc020554a:	84ae                	mv	s1,a1
ffffffffc020554c:	8d32                	mv	s10,a2
ffffffffc020554e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205550:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205554:	5b7d                	li	s6,-1
ffffffffc0205556:	00002a97          	auipc	s5,0x2
ffffffffc020555a:	3c6a8a93          	addi	s5,s5,966 # ffffffffc020791c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020555e:	00002b97          	auipc	s7,0x2
ffffffffc0205562:	5dab8b93          	addi	s7,s7,1498 # ffffffffc0207b38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205566:	000d4503          	lbu	a0,0(s10)
ffffffffc020556a:	001d0413          	addi	s0,s10,1
ffffffffc020556e:	01350a63          	beq	a0,s3,ffffffffc0205582 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205572:	c121                	beqz	a0,ffffffffc02055b2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205574:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205576:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205578:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020557a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020557e:	ff351ae3          	bne	a0,s3,ffffffffc0205572 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205582:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205586:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020558a:	4c81                	li	s9,0
ffffffffc020558c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020558e:	5c7d                	li	s8,-1
ffffffffc0205590:	5dfd                	li	s11,-1
ffffffffc0205592:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205596:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205598:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020559c:	0ff5f593          	zext.b	a1,a1
ffffffffc02055a0:	00140d13          	addi	s10,s0,1
ffffffffc02055a4:	04b56263          	bltu	a0,a1,ffffffffc02055e8 <vprintfmt+0xbc>
ffffffffc02055a8:	058a                	slli	a1,a1,0x2
ffffffffc02055aa:	95d6                	add	a1,a1,s5
ffffffffc02055ac:	4194                	lw	a3,0(a1)
ffffffffc02055ae:	96d6                	add	a3,a3,s5
ffffffffc02055b0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02055b2:	70e6                	ld	ra,120(sp)
ffffffffc02055b4:	7446                	ld	s0,112(sp)
ffffffffc02055b6:	74a6                	ld	s1,104(sp)
ffffffffc02055b8:	7906                	ld	s2,96(sp)
ffffffffc02055ba:	69e6                	ld	s3,88(sp)
ffffffffc02055bc:	6a46                	ld	s4,80(sp)
ffffffffc02055be:	6aa6                	ld	s5,72(sp)
ffffffffc02055c0:	6b06                	ld	s6,64(sp)
ffffffffc02055c2:	7be2                	ld	s7,56(sp)
ffffffffc02055c4:	7c42                	ld	s8,48(sp)
ffffffffc02055c6:	7ca2                	ld	s9,40(sp)
ffffffffc02055c8:	7d02                	ld	s10,32(sp)
ffffffffc02055ca:	6de2                	ld	s11,24(sp)
ffffffffc02055cc:	6109                	addi	sp,sp,128
ffffffffc02055ce:	8082                	ret
            padc = '0';
ffffffffc02055d0:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02055d2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055d6:	846a                	mv	s0,s10
ffffffffc02055d8:	00140d13          	addi	s10,s0,1
ffffffffc02055dc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02055e0:	0ff5f593          	zext.b	a1,a1
ffffffffc02055e4:	fcb572e3          	bgeu	a0,a1,ffffffffc02055a8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02055e8:	85a6                	mv	a1,s1
ffffffffc02055ea:	02500513          	li	a0,37
ffffffffc02055ee:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02055f0:	fff44783          	lbu	a5,-1(s0)
ffffffffc02055f4:	8d22                	mv	s10,s0
ffffffffc02055f6:	f73788e3          	beq	a5,s3,ffffffffc0205566 <vprintfmt+0x3a>
ffffffffc02055fa:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02055fe:	1d7d                	addi	s10,s10,-1
ffffffffc0205600:	ff379de3          	bne	a5,s3,ffffffffc02055fa <vprintfmt+0xce>
ffffffffc0205604:	b78d                	j	ffffffffc0205566 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205606:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020560a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020560e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205610:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205614:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205618:	02d86463          	bltu	a6,a3,ffffffffc0205640 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020561c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205620:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205624:	0186873b          	addw	a4,a3,s8
ffffffffc0205628:	0017171b          	slliw	a4,a4,0x1
ffffffffc020562c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020562e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205632:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205634:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205638:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020563c:	fed870e3          	bgeu	a6,a3,ffffffffc020561c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205640:	f40ddce3          	bgez	s11,ffffffffc0205598 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205644:	8de2                	mv	s11,s8
ffffffffc0205646:	5c7d                	li	s8,-1
ffffffffc0205648:	bf81                	j	ffffffffc0205598 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020564a:	fffdc693          	not	a3,s11
ffffffffc020564e:	96fd                	srai	a3,a3,0x3f
ffffffffc0205650:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205654:	00144603          	lbu	a2,1(s0)
ffffffffc0205658:	2d81                	sext.w	s11,s11
ffffffffc020565a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020565c:	bf35                	j	ffffffffc0205598 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020565e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205662:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205666:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205668:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020566a:	bfd9                	j	ffffffffc0205640 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020566c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020566e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205672:	01174463          	blt	a4,a7,ffffffffc020567a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205676:	1a088e63          	beqz	a7,ffffffffc0205832 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020567a:	000a3603          	ld	a2,0(s4)
ffffffffc020567e:	46c1                	li	a3,16
ffffffffc0205680:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205682:	2781                	sext.w	a5,a5
ffffffffc0205684:	876e                	mv	a4,s11
ffffffffc0205686:	85a6                	mv	a1,s1
ffffffffc0205688:	854a                	mv	a0,s2
ffffffffc020568a:	e37ff0ef          	jal	ra,ffffffffc02054c0 <printnum>
            break;
ffffffffc020568e:	bde1                	j	ffffffffc0205566 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205690:	000a2503          	lw	a0,0(s4)
ffffffffc0205694:	85a6                	mv	a1,s1
ffffffffc0205696:	0a21                	addi	s4,s4,8
ffffffffc0205698:	9902                	jalr	s2
            break;
ffffffffc020569a:	b5f1                	j	ffffffffc0205566 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020569c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020569e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056a2:	01174463          	blt	a4,a7,ffffffffc02056aa <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02056a6:	18088163          	beqz	a7,ffffffffc0205828 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02056aa:	000a3603          	ld	a2,0(s4)
ffffffffc02056ae:	46a9                	li	a3,10
ffffffffc02056b0:	8a2e                	mv	s4,a1
ffffffffc02056b2:	bfc1                	j	ffffffffc0205682 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056b4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02056b8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056ba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02056bc:	bdf1                	j	ffffffffc0205598 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02056be:	85a6                	mv	a1,s1
ffffffffc02056c0:	02500513          	li	a0,37
ffffffffc02056c4:	9902                	jalr	s2
            break;
ffffffffc02056c6:	b545                	j	ffffffffc0205566 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056c8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02056cc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056ce:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02056d0:	b5e1                	j	ffffffffc0205598 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02056d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056d4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056d8:	01174463          	blt	a4,a7,ffffffffc02056e0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02056dc:	14088163          	beqz	a7,ffffffffc020581e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02056e0:	000a3603          	ld	a2,0(s4)
ffffffffc02056e4:	46a1                	li	a3,8
ffffffffc02056e6:	8a2e                	mv	s4,a1
ffffffffc02056e8:	bf69                	j	ffffffffc0205682 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02056ea:	03000513          	li	a0,48
ffffffffc02056ee:	85a6                	mv	a1,s1
ffffffffc02056f0:	e03e                	sd	a5,0(sp)
ffffffffc02056f2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02056f4:	85a6                	mv	a1,s1
ffffffffc02056f6:	07800513          	li	a0,120
ffffffffc02056fa:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02056fc:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02056fe:	6782                	ld	a5,0(sp)
ffffffffc0205700:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205702:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205706:	bfb5                	j	ffffffffc0205682 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205708:	000a3403          	ld	s0,0(s4)
ffffffffc020570c:	008a0713          	addi	a4,s4,8
ffffffffc0205710:	e03a                	sd	a4,0(sp)
ffffffffc0205712:	14040263          	beqz	s0,ffffffffc0205856 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205716:	0fb05763          	blez	s11,ffffffffc0205804 <vprintfmt+0x2d8>
ffffffffc020571a:	02d00693          	li	a3,45
ffffffffc020571e:	0cd79163          	bne	a5,a3,ffffffffc02057e0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205722:	00044783          	lbu	a5,0(s0)
ffffffffc0205726:	0007851b          	sext.w	a0,a5
ffffffffc020572a:	cf85                	beqz	a5,ffffffffc0205762 <vprintfmt+0x236>
ffffffffc020572c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205730:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205734:	000c4563          	bltz	s8,ffffffffc020573e <vprintfmt+0x212>
ffffffffc0205738:	3c7d                	addiw	s8,s8,-1
ffffffffc020573a:	036c0263          	beq	s8,s6,ffffffffc020575e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020573e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205740:	0e0c8e63          	beqz	s9,ffffffffc020583c <vprintfmt+0x310>
ffffffffc0205744:	3781                	addiw	a5,a5,-32
ffffffffc0205746:	0ef47b63          	bgeu	s0,a5,ffffffffc020583c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020574a:	03f00513          	li	a0,63
ffffffffc020574e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205750:	000a4783          	lbu	a5,0(s4)
ffffffffc0205754:	3dfd                	addiw	s11,s11,-1
ffffffffc0205756:	0a05                	addi	s4,s4,1
ffffffffc0205758:	0007851b          	sext.w	a0,a5
ffffffffc020575c:	ffe1                	bnez	a5,ffffffffc0205734 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020575e:	01b05963          	blez	s11,ffffffffc0205770 <vprintfmt+0x244>
ffffffffc0205762:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205764:	85a6                	mv	a1,s1
ffffffffc0205766:	02000513          	li	a0,32
ffffffffc020576a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020576c:	fe0d9be3          	bnez	s11,ffffffffc0205762 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205770:	6a02                	ld	s4,0(sp)
ffffffffc0205772:	bbd5                	j	ffffffffc0205566 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205774:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205776:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020577a:	01174463          	blt	a4,a7,ffffffffc0205782 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020577e:	08088d63          	beqz	a7,ffffffffc0205818 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205782:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205786:	0a044d63          	bltz	s0,ffffffffc0205840 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020578a:	8622                	mv	a2,s0
ffffffffc020578c:	8a66                	mv	s4,s9
ffffffffc020578e:	46a9                	li	a3,10
ffffffffc0205790:	bdcd                	j	ffffffffc0205682 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205792:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205796:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205798:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020579a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020579e:	8fb5                	xor	a5,a5,a3
ffffffffc02057a0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02057a4:	02d74163          	blt	a4,a3,ffffffffc02057c6 <vprintfmt+0x29a>
ffffffffc02057a8:	00369793          	slli	a5,a3,0x3
ffffffffc02057ac:	97de                	add	a5,a5,s7
ffffffffc02057ae:	639c                	ld	a5,0(a5)
ffffffffc02057b0:	cb99                	beqz	a5,ffffffffc02057c6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02057b2:	86be                	mv	a3,a5
ffffffffc02057b4:	00000617          	auipc	a2,0x0
ffffffffc02057b8:	1f460613          	addi	a2,a2,500 # ffffffffc02059a8 <etext+0x2e>
ffffffffc02057bc:	85a6                	mv	a1,s1
ffffffffc02057be:	854a                	mv	a0,s2
ffffffffc02057c0:	0ce000ef          	jal	ra,ffffffffc020588e <printfmt>
ffffffffc02057c4:	b34d                	j	ffffffffc0205566 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02057c6:	00002617          	auipc	a2,0x2
ffffffffc02057ca:	14a60613          	addi	a2,a2,330 # ffffffffc0207910 <syscalls+0x120>
ffffffffc02057ce:	85a6                	mv	a1,s1
ffffffffc02057d0:	854a                	mv	a0,s2
ffffffffc02057d2:	0bc000ef          	jal	ra,ffffffffc020588e <printfmt>
ffffffffc02057d6:	bb41                	j	ffffffffc0205566 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02057d8:	00002417          	auipc	s0,0x2
ffffffffc02057dc:	13040413          	addi	s0,s0,304 # ffffffffc0207908 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057e0:	85e2                	mv	a1,s8
ffffffffc02057e2:	8522                	mv	a0,s0
ffffffffc02057e4:	e43e                	sd	a5,8(sp)
ffffffffc02057e6:	0e2000ef          	jal	ra,ffffffffc02058c8 <strnlen>
ffffffffc02057ea:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02057ee:	01b05b63          	blez	s11,ffffffffc0205804 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02057f2:	67a2                	ld	a5,8(sp)
ffffffffc02057f4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057f8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02057fa:	85a6                	mv	a1,s1
ffffffffc02057fc:	8552                	mv	a0,s4
ffffffffc02057fe:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205800:	fe0d9ce3          	bnez	s11,ffffffffc02057f8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205804:	00044783          	lbu	a5,0(s0)
ffffffffc0205808:	00140a13          	addi	s4,s0,1
ffffffffc020580c:	0007851b          	sext.w	a0,a5
ffffffffc0205810:	d3a5                	beqz	a5,ffffffffc0205770 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205812:	05e00413          	li	s0,94
ffffffffc0205816:	bf39                	j	ffffffffc0205734 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205818:	000a2403          	lw	s0,0(s4)
ffffffffc020581c:	b7ad                	j	ffffffffc0205786 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020581e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205822:	46a1                	li	a3,8
ffffffffc0205824:	8a2e                	mv	s4,a1
ffffffffc0205826:	bdb1                	j	ffffffffc0205682 <vprintfmt+0x156>
ffffffffc0205828:	000a6603          	lwu	a2,0(s4)
ffffffffc020582c:	46a9                	li	a3,10
ffffffffc020582e:	8a2e                	mv	s4,a1
ffffffffc0205830:	bd89                	j	ffffffffc0205682 <vprintfmt+0x156>
ffffffffc0205832:	000a6603          	lwu	a2,0(s4)
ffffffffc0205836:	46c1                	li	a3,16
ffffffffc0205838:	8a2e                	mv	s4,a1
ffffffffc020583a:	b5a1                	j	ffffffffc0205682 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020583c:	9902                	jalr	s2
ffffffffc020583e:	bf09                	j	ffffffffc0205750 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205840:	85a6                	mv	a1,s1
ffffffffc0205842:	02d00513          	li	a0,45
ffffffffc0205846:	e03e                	sd	a5,0(sp)
ffffffffc0205848:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020584a:	6782                	ld	a5,0(sp)
ffffffffc020584c:	8a66                	mv	s4,s9
ffffffffc020584e:	40800633          	neg	a2,s0
ffffffffc0205852:	46a9                	li	a3,10
ffffffffc0205854:	b53d                	j	ffffffffc0205682 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205856:	03b05163          	blez	s11,ffffffffc0205878 <vprintfmt+0x34c>
ffffffffc020585a:	02d00693          	li	a3,45
ffffffffc020585e:	f6d79de3          	bne	a5,a3,ffffffffc02057d8 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205862:	00002417          	auipc	s0,0x2
ffffffffc0205866:	0a640413          	addi	s0,s0,166 # ffffffffc0207908 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020586a:	02800793          	li	a5,40
ffffffffc020586e:	02800513          	li	a0,40
ffffffffc0205872:	00140a13          	addi	s4,s0,1
ffffffffc0205876:	bd6d                	j	ffffffffc0205730 <vprintfmt+0x204>
ffffffffc0205878:	00002a17          	auipc	s4,0x2
ffffffffc020587c:	091a0a13          	addi	s4,s4,145 # ffffffffc0207909 <syscalls+0x119>
ffffffffc0205880:	02800513          	li	a0,40
ffffffffc0205884:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205888:	05e00413          	li	s0,94
ffffffffc020588c:	b565                	j	ffffffffc0205734 <vprintfmt+0x208>

ffffffffc020588e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020588e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205890:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205894:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205896:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205898:	ec06                	sd	ra,24(sp)
ffffffffc020589a:	f83a                	sd	a4,48(sp)
ffffffffc020589c:	fc3e                	sd	a5,56(sp)
ffffffffc020589e:	e0c2                	sd	a6,64(sp)
ffffffffc02058a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02058a2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02058a4:	c89ff0ef          	jal	ra,ffffffffc020552c <vprintfmt>
}
ffffffffc02058a8:	60e2                	ld	ra,24(sp)
ffffffffc02058aa:	6161                	addi	sp,sp,80
ffffffffc02058ac:	8082                	ret

ffffffffc02058ae <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02058ae:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02058b2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02058b4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02058b6:	cb81                	beqz	a5,ffffffffc02058c6 <strlen+0x18>
        cnt ++;
ffffffffc02058b8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02058ba:	00a707b3          	add	a5,a4,a0
ffffffffc02058be:	0007c783          	lbu	a5,0(a5)
ffffffffc02058c2:	fbfd                	bnez	a5,ffffffffc02058b8 <strlen+0xa>
ffffffffc02058c4:	8082                	ret
    }
    return cnt;
}
ffffffffc02058c6:	8082                	ret

ffffffffc02058c8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02058c8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02058ca:	e589                	bnez	a1,ffffffffc02058d4 <strnlen+0xc>
ffffffffc02058cc:	a811                	j	ffffffffc02058e0 <strnlen+0x18>
        cnt ++;
ffffffffc02058ce:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02058d0:	00f58863          	beq	a1,a5,ffffffffc02058e0 <strnlen+0x18>
ffffffffc02058d4:	00f50733          	add	a4,a0,a5
ffffffffc02058d8:	00074703          	lbu	a4,0(a4)
ffffffffc02058dc:	fb6d                	bnez	a4,ffffffffc02058ce <strnlen+0x6>
ffffffffc02058de:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02058e0:	852e                	mv	a0,a1
ffffffffc02058e2:	8082                	ret

ffffffffc02058e4 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02058e4:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02058e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02058ea:	0785                	addi	a5,a5,1
ffffffffc02058ec:	0585                	addi	a1,a1,1
ffffffffc02058ee:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02058f2:	fb75                	bnez	a4,ffffffffc02058e6 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02058f4:	8082                	ret

ffffffffc02058f6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02058f6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02058fa:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02058fe:	cb89                	beqz	a5,ffffffffc0205910 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205900:	0505                	addi	a0,a0,1
ffffffffc0205902:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205904:	fee789e3          	beq	a5,a4,ffffffffc02058f6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205908:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020590c:	9d19                	subw	a0,a0,a4
ffffffffc020590e:	8082                	ret
ffffffffc0205910:	4501                	li	a0,0
ffffffffc0205912:	bfed                	j	ffffffffc020590c <strcmp+0x16>

ffffffffc0205914 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205914:	c20d                	beqz	a2,ffffffffc0205936 <strncmp+0x22>
ffffffffc0205916:	962e                	add	a2,a2,a1
ffffffffc0205918:	a031                	j	ffffffffc0205924 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020591a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020591c:	00e79a63          	bne	a5,a4,ffffffffc0205930 <strncmp+0x1c>
ffffffffc0205920:	00b60b63          	beq	a2,a1,ffffffffc0205936 <strncmp+0x22>
ffffffffc0205924:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205928:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020592a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020592e:	f7f5                	bnez	a5,ffffffffc020591a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205930:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205934:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205936:	4501                	li	a0,0
ffffffffc0205938:	8082                	ret

ffffffffc020593a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020593a:	00054783          	lbu	a5,0(a0)
ffffffffc020593e:	c799                	beqz	a5,ffffffffc020594c <strchr+0x12>
        if (*s == c) {
ffffffffc0205940:	00f58763          	beq	a1,a5,ffffffffc020594e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205944:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205948:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020594a:	fbfd                	bnez	a5,ffffffffc0205940 <strchr+0x6>
    }
    return NULL;
ffffffffc020594c:	4501                	li	a0,0
}
ffffffffc020594e:	8082                	ret

ffffffffc0205950 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205950:	ca01                	beqz	a2,ffffffffc0205960 <memset+0x10>
ffffffffc0205952:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205954:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205956:	0785                	addi	a5,a5,1
ffffffffc0205958:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020595c:	fec79de3          	bne	a5,a2,ffffffffc0205956 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205960:	8082                	ret

ffffffffc0205962 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205962:	ca19                	beqz	a2,ffffffffc0205978 <memcpy+0x16>
ffffffffc0205964:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205966:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205968:	0005c703          	lbu	a4,0(a1)
ffffffffc020596c:	0585                	addi	a1,a1,1
ffffffffc020596e:	0785                	addi	a5,a5,1
ffffffffc0205970:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205974:	fec59ae3          	bne	a1,a2,ffffffffc0205968 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205978:	8082                	ret
