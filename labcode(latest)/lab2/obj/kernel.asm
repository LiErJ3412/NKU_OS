
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	3dc50513          	addi	a0,a0,988 # ffffffffc0201428 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	3e650513          	addi	a0,a0,998 # ffffffffc0201448 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	3b858593          	addi	a1,a1,952 # ffffffffc0201426 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	3f250513          	addi	a0,a0,1010 # ffffffffc0201468 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <is_panic>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	3fe50513          	addi	a0,a0,1022 # ffffffffc0201488 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	40a50513          	addi	a0,a0,1034 # ffffffffc02014a8 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	3fc50513          	addi	a0,a0,1020 # ffffffffc02014c8 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <is_panic>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	324010ef          	jal	ra,ffffffffc0201414 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	3fc50513          	addi	a0,a0,1020 # ffffffffc02014f8 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4af000ef          	jal	ra,ffffffffc0200dba <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	6bf000ef          	jal	ra,ffffffffc0200ffe <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	689000ef          	jal	ra,ffffffffc0200ffe <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e5630313          	addi	t1,t1,-426 # ffffffffc0205018 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	32650513          	addi	a0,a0,806 # ffffffffc0201518 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	95850513          	addi	a0,a0,-1704 # ffffffffc0201b60 <etext+0x73a>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	1640106f          	j	ffffffffc0201380 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	31650513          	addi	a0,a0,790 # ffffffffc0201538 <etext+0x112>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	2f850513          	addi	a0,a0,760 # ffffffffc0201548 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	2f250513          	addi	a0,a0,754 # ffffffffc0201558 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	2fa50513          	addi	a0,a0,762 # ffffffffc0201570 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	29090913          	addi	s2,s2,656 # ffffffffc02015c0 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	27a48493          	addi	s1,s1,634 # ffffffffc02015b8 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	2a650513          	addi	a0,a0,678 # ffffffffc0201638 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	2d250513          	addi	a0,a0,722 # ffffffffc0201670 <etext+0x24a>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	1b250513          	addi	a0,a0,434 # ffffffffc0201590 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	7af000ef          	jal	ra,ffffffffc020139a <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	7f5000ef          	jal	ra,ffffffffc02013ee <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	741000ef          	jal	ra,ffffffffc02013d0 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	12450513          	addi	a0,a0,292 # ffffffffc02015c8 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	07650513          	addi	a0,a0,118 # ffffffffc02015e8 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	07c50513          	addi	a0,a0,124 # ffffffffc0201600 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	08a50513          	addi	a0,a0,138 # ffffffffc0201620 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	0ce50513          	addi	a0,a0,206 # ffffffffc0201670 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	a687bb23          	sd	s0,-1418(a5) # ffffffffc0205020 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	a767bb23          	sd	s6,-1418(a5) # ffffffffc0205028 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a6453503          	ld	a0,-1436(a0) # ffffffffc0205020 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	a6253503          	ld	a0,-1438(a0) # ffffffffc0205028 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
}

// 初始化 buddy system
static void
buddy_init(void) {
    buddy_longest = NULL;
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a607b023          	sd	zero,-1440(a5) # ffffffffc0205030 <buddy_longest>
    buddy_size = 0;
ffffffffc02005d8:	00005797          	auipc	a5,0x5
ffffffffc02005dc:	a607a423          	sw	zero,-1432(a5) # ffffffffc0205040 <buddy_size>
    max_pages = 0;
    buddy_page_base = NULL;
ffffffffc02005e0:	00005797          	auipc	a5,0x5
ffffffffc02005e4:	a407bc23          	sd	zero,-1448(a5) # ffffffffc0205038 <buddy_page_base>
}
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <buddy_nr_free_pages>:
/**
 * 返回空闲页面数
 */
static size_t
buddy_nr_free_pages(void) {
    return buddy_longest[0];  // 根节点的值就是最大可分配空间
ffffffffc02005ea:	00005797          	auipc	a5,0x5
ffffffffc02005ee:	a467b783          	ld	a5,-1466(a5) # ffffffffc0205030 <buddy_longest>
}
ffffffffc02005f2:	0007e503          	lwu	a0,0(a5)
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02005f8:	1141                	addi	sp,sp,-16
ffffffffc02005fa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02005fc:	10058f63          	beqz	a1,ffffffffc020071a <buddy_free_pages+0x122>
    assert(base >= buddy_page_base && base < buddy_page_base + buddy_size);
ffffffffc0200600:	00005797          	auipc	a5,0x5
ffffffffc0200604:	a387b783          	ld	a5,-1480(a5) # ffffffffc0205038 <buddy_page_base>
ffffffffc0200608:	0ef56963          	bltu	a0,a5,ffffffffc02006fa <buddy_free_pages+0x102>
ffffffffc020060c:	00005817          	auipc	a6,0x5
ffffffffc0200610:	a3482803          	lw	a6,-1484(a6) # ffffffffc0205040 <buddy_size>
ffffffffc0200614:	02081693          	slli	a3,a6,0x20
ffffffffc0200618:	9281                	srli	a3,a3,0x20
ffffffffc020061a:	00269713          	slli	a4,a3,0x2
ffffffffc020061e:	9736                	add	a4,a4,a3
ffffffffc0200620:	070e                	slli	a4,a4,0x3
ffffffffc0200622:	973e                	add	a4,a4,a5
ffffffffc0200624:	0ce57b63          	bgeu	a0,a4,ffffffffc02006fa <buddy_free_pages+0x102>
    unsigned int size = 1;
ffffffffc0200628:	4685                	li	a3,1
    while (size < n) {
ffffffffc020062a:	0cd58563          	beq	a1,a3,ffffffffc02006f4 <buddy_free_pages+0xfc>
        size <<= 1;
ffffffffc020062e:	0016969b          	slliw	a3,a3,0x1
    while (size < n) {
ffffffffc0200632:	02069713          	slli	a4,a3,0x20
ffffffffc0200636:	9301                	srli	a4,a4,0x20
ffffffffc0200638:	feb76be3          	bltu	a4,a1,ffffffffc020062e <buddy_free_pages+0x36>
    unsigned int index = (offset / size) + (buddy_size / size) - 1;
ffffffffc020063c:	02d8583b          	divuw	a6,a6,a3
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200640:	00271593          	slli	a1,a4,0x2
ffffffffc0200644:	95ba                	add	a1,a1,a4
ffffffffc0200646:	058e                	slli	a1,a1,0x3
    unsigned int offset = base - buddy_page_base;
ffffffffc0200648:	40f50633          	sub	a2,a0,a5
ffffffffc020064c:	860d                	srai	a2,a2,0x3
ffffffffc020064e:	00002797          	auipc	a5,0x2
ffffffffc0200652:	9727b783          	ld	a5,-1678(a5) # ffffffffc0201fc0 <error_string+0x38>
    unsigned int index = (offset / size) + (buddy_size / size) - 1;
ffffffffc0200656:	387d                	addiw	a6,a6,-1
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200658:	95aa                	add	a1,a1,a0
    unsigned int offset = base - buddy_page_base;
ffffffffc020065a:	02f60633          	mul	a2,a2,a5
    unsigned int index = (offset / size) + (buddy_size / size) - 1;
ffffffffc020065e:	02d6563b          	divuw	a2,a2,a3
ffffffffc0200662:	0106063b          	addw	a2,a2,a6
ffffffffc0200666:	0006079b          	sext.w	a5,a2
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc020066a:	00b57c63          	bgeu	a0,a1,ffffffffc0200682 <buddy_free_pages+0x8a>
        ClearPageProperty(p);
ffffffffc020066e:	6518                	ld	a4,8(a0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200670:	00052023          	sw	zero,0(a0)
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200674:	02850513          	addi	a0,a0,40
        ClearPageProperty(p);
ffffffffc0200678:	9b71                	andi	a4,a4,-4
ffffffffc020067a:	fee53023          	sd	a4,-32(a0)
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc020067e:	feb568e3          	bltu	a0,a1,ffffffffc020066e <buddy_free_pages+0x76>
    buddy_longest[index] = node_size;
ffffffffc0200682:	02061713          	slli	a4,a2,0x20
ffffffffc0200686:	00005517          	auipc	a0,0x5
ffffffffc020068a:	9aa53503          	ld	a0,-1622(a0) # ffffffffc0205030 <buddy_longest>
ffffffffc020068e:	01e75613          	srli	a2,a4,0x1e
ffffffffc0200692:	962a                	add	a2,a2,a0
ffffffffc0200694:	c214                	sw	a3,0(a2)
    while (index) {
ffffffffc0200696:	cba9                	beqz	a5,ffffffffc02006e8 <buddy_free_pages+0xf0>
        index = PARENT(index);
ffffffffc0200698:	2785                	addiw	a5,a5,1
ffffffffc020069a:	0017d59b          	srliw	a1,a5,0x1
ffffffffc020069e:	35fd                	addiw	a1,a1,-1
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
ffffffffc02006a0:	ffe7f713          	andi	a4,a5,-2
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
ffffffffc02006a4:	0015961b          	slliw	a2,a1,0x1
ffffffffc02006a8:	2605                	addiw	a2,a2,1
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
ffffffffc02006aa:	1702                	slli	a4,a4,0x20
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
ffffffffc02006ac:	02061793          	slli	a5,a2,0x20
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
ffffffffc02006b0:	9301                	srli	a4,a4,0x20
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
ffffffffc02006b2:	01e7d613          	srli	a2,a5,0x1e
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
ffffffffc02006b6:	070a                	slli	a4,a4,0x2
ffffffffc02006b8:	972a                	add	a4,a4,a0
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
ffffffffc02006ba:	962a                	add	a2,a2,a0
        unsigned int right_longest = buddy_longest[RIGHT_LEAF(index)];
ffffffffc02006bc:	00072803          	lw	a6,0(a4)
        unsigned int left_longest = buddy_longest[LEFT_LEAF(index)];
ffffffffc02006c0:	4210                	lw	a2,0(a2)
            buddy_longest[index] = node_size;
ffffffffc02006c2:	02059793          	slli	a5,a1,0x20
ffffffffc02006c6:	01e7d713          	srli	a4,a5,0x1e
        node_size *= 2;
ffffffffc02006ca:	0016969b          	slliw	a3,a3,0x1
        if (left_longest + right_longest == node_size) {
ffffffffc02006ce:	0106033b          	addw	t1,a2,a6
        index = PARENT(index);
ffffffffc02006d2:	0005879b          	sext.w	a5,a1
            buddy_longest[index] = node_size;
ffffffffc02006d6:	972a                	add	a4,a4,a0
        if (left_longest + right_longest == node_size) {
ffffffffc02006d8:	00d30b63          	beq	t1,a3,ffffffffc02006ee <buddy_free_pages+0xf6>
            buddy_longest[index] = MAX(left_longest, right_longest);
ffffffffc02006dc:	85b2                	mv	a1,a2
ffffffffc02006de:	01067363          	bgeu	a2,a6,ffffffffc02006e4 <buddy_free_pages+0xec>
ffffffffc02006e2:	85c2                	mv	a1,a6
ffffffffc02006e4:	c30c                	sw	a1,0(a4)
    while (index) {
ffffffffc02006e6:	fbcd                	bnez	a5,ffffffffc0200698 <buddy_free_pages+0xa0>
}
ffffffffc02006e8:	60a2                	ld	ra,8(sp)
ffffffffc02006ea:	0141                	addi	sp,sp,16
ffffffffc02006ec:	8082                	ret
            buddy_longest[index] = node_size;
ffffffffc02006ee:	c314                	sw	a3,0(a4)
    while (index) {
ffffffffc02006f0:	f7c5                	bnez	a5,ffffffffc0200698 <buddy_free_pages+0xa0>
ffffffffc02006f2:	bfdd                	j	ffffffffc02006e8 <buddy_free_pages+0xf0>
    while (size < n) {
ffffffffc02006f4:	02800593          	li	a1,40
ffffffffc02006f8:	bf81                	j	ffffffffc0200648 <buddy_free_pages+0x50>
    assert(base >= buddy_page_base && base < buddy_page_base + buddy_size);
ffffffffc02006fa:	00001697          	auipc	a3,0x1
ffffffffc02006fe:	fc668693          	addi	a3,a3,-58 # ffffffffc02016c0 <etext+0x29a>
ffffffffc0200702:	00001617          	auipc	a2,0x1
ffffffffc0200706:	f8e60613          	addi	a2,a2,-114 # ffffffffc0201690 <etext+0x26a>
ffffffffc020070a:	0b800593          	li	a1,184
ffffffffc020070e:	00001517          	auipc	a0,0x1
ffffffffc0200712:	f9a50513          	addi	a0,a0,-102 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200716:	aadff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc020071a:	00001697          	auipc	a3,0x1
ffffffffc020071e:	f6e68693          	addi	a3,a3,-146 # ffffffffc0201688 <etext+0x262>
ffffffffc0200722:	00001617          	auipc	a2,0x1
ffffffffc0200726:	f6e60613          	addi	a2,a2,-146 # ffffffffc0201690 <etext+0x26a>
ffffffffc020072a:	0b700593          	li	a1,183
ffffffffc020072e:	00001517          	auipc	a0,0x1
ffffffffc0200732:	f7a50513          	addi	a0,a0,-134 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200736:	a8dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020073a <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc020073a:	10050c63          	beqz	a0,ffffffffc0200852 <buddy_alloc_pages+0x118>
    if (n > buddy_size) {
ffffffffc020073e:	00005897          	auipc	a7,0x5
ffffffffc0200742:	9028a883          	lw	a7,-1790(a7) # ffffffffc0205040 <buddy_size>
ffffffffc0200746:	02089793          	slli	a5,a7,0x20
ffffffffc020074a:	9381                	srli	a5,a5,0x20
ffffffffc020074c:	0ea7ea63          	bltu	a5,a0,ffffffffc0200840 <buddy_alloc_pages+0x106>
    while (size < n) {
ffffffffc0200750:	4785                	li	a5,1
ffffffffc0200752:	0ef50963          	beq	a0,a5,ffffffffc0200844 <buddy_alloc_pages+0x10a>
    unsigned int size = 1;
ffffffffc0200756:	4705                	li	a4,1
        size <<= 1;
ffffffffc0200758:	0017171b          	slliw	a4,a4,0x1
    while (size < n) {
ffffffffc020075c:	02071813          	slli	a6,a4,0x20
ffffffffc0200760:	02085813          	srli	a6,a6,0x20
ffffffffc0200764:	fea86ae3          	bltu	a6,a0,ffffffffc0200758 <buddy_alloc_pages+0x1e>
    if (buddy_longest[0] < size) {
ffffffffc0200768:	00005617          	auipc	a2,0x5
ffffffffc020076c:	8c863603          	ld	a2,-1848(a2) # ffffffffc0205030 <buddy_longest>
ffffffffc0200770:	421c                	lw	a5,0(a2)
ffffffffc0200772:	0ce7e763          	bltu	a5,a4,ffffffffc0200840 <buddy_alloc_pages+0x106>
    for (node_size = buddy_size; node_size != size; node_size /= 2) {
ffffffffc0200776:	0ce88a63          	beq	a7,a4,ffffffffc020084a <buddy_alloc_pages+0x110>
ffffffffc020077a:	85c6                	mv	a1,a7
    unsigned int index = 0;
ffffffffc020077c:	4781                	li	a5,0
        if (buddy_longest[LEFT_LEAF(index)] >= size) {
ffffffffc020077e:	0017951b          	slliw	a0,a5,0x1
ffffffffc0200782:	0015079b          	addiw	a5,a0,1
ffffffffc0200786:	02079313          	slli	t1,a5,0x20
ffffffffc020078a:	01e35693          	srli	a3,t1,0x1e
ffffffffc020078e:	96b2                	add	a3,a3,a2
ffffffffc0200790:	4294                	lw	a3,0(a3)
ffffffffc0200792:	00e6f463          	bgeu	a3,a4,ffffffffc020079a <buddy_alloc_pages+0x60>
            index = RIGHT_LEAF(index);
ffffffffc0200796:	0025079b          	addiw	a5,a0,2
    for (node_size = buddy_size; node_size != size; node_size /= 2) {
ffffffffc020079a:	0015d59b          	srliw	a1,a1,0x1
ffffffffc020079e:	fee590e3          	bne	a1,a4,ffffffffc020077e <buddy_alloc_pages+0x44>
    offset = (index + 1) * node_size - buddy_size;
ffffffffc02007a2:	0017871b          	addiw	a4,a5,1
ffffffffc02007a6:	02b705bb          	mulw	a1,a4,a1
    buddy_longest[index] = 0;
ffffffffc02007aa:	02079513          	slli	a0,a5,0x20
ffffffffc02007ae:	01e55693          	srli	a3,a0,0x1e
ffffffffc02007b2:	96b2                	add	a3,a3,a2
ffffffffc02007b4:	0006a023          	sw	zero,0(a3)
    offset = (index + 1) * node_size - buddy_size;
ffffffffc02007b8:	411585bb          	subw	a1,a1,a7
    struct Page *page = buddy_page_base + offset;
ffffffffc02007bc:	1582                	slli	a1,a1,0x20
ffffffffc02007be:	9181                	srli	a1,a1,0x20
ffffffffc02007c0:	00259513          	slli	a0,a1,0x2
ffffffffc02007c4:	95aa                	add	a1,a1,a0
ffffffffc02007c6:	058e                	slli	a1,a1,0x3
    while (index) {
ffffffffc02007c8:	e781                	bnez	a5,ffffffffc02007d0 <buddy_alloc_pages+0x96>
ffffffffc02007ca:	a0a1                	j	ffffffffc0200812 <buddy_alloc_pages+0xd8>
ffffffffc02007cc:	0017871b          	addiw	a4,a5,1
        index = PARENT(index);
ffffffffc02007d0:	0017579b          	srliw	a5,a4,0x1
ffffffffc02007d4:	37fd                	addiw	a5,a5,-1
            MAX(buddy_longest[LEFT_LEAF(index)], 
ffffffffc02007d6:	0017969b          	slliw	a3,a5,0x1
ffffffffc02007da:	9b79                	andi	a4,a4,-2
ffffffffc02007dc:	2685                	addiw	a3,a3,1
ffffffffc02007de:	1702                	slli	a4,a4,0x20
ffffffffc02007e0:	02069513          	slli	a0,a3,0x20
ffffffffc02007e4:	9301                	srli	a4,a4,0x20
ffffffffc02007e6:	01e55693          	srli	a3,a0,0x1e
ffffffffc02007ea:	070a                	slli	a4,a4,0x2
ffffffffc02007ec:	9732                	add	a4,a4,a2
ffffffffc02007ee:	96b2                	add	a3,a3,a2
ffffffffc02007f0:	00072883          	lw	a7,0(a4)
ffffffffc02007f4:	4294                	lw	a3,0(a3)
        buddy_longest[index] = 
ffffffffc02007f6:	02079513          	slli	a0,a5,0x20
ffffffffc02007fa:	01e55713          	srli	a4,a0,0x1e
            MAX(buddy_longest[LEFT_LEAF(index)], 
ffffffffc02007fe:	0008831b          	sext.w	t1,a7
ffffffffc0200802:	00068e1b          	sext.w	t3,a3
        buddy_longest[index] = 
ffffffffc0200806:	9732                	add	a4,a4,a2
            MAX(buddy_longest[LEFT_LEAF(index)], 
ffffffffc0200808:	006e7363          	bgeu	t3,t1,ffffffffc020080e <buddy_alloc_pages+0xd4>
ffffffffc020080c:	86c6                	mv	a3,a7
        buddy_longest[index] = 
ffffffffc020080e:	c314                	sw	a3,0(a4)
    while (index) {
ffffffffc0200810:	ffd5                	bnez	a5,ffffffffc02007cc <buddy_alloc_pages+0x92>
    for (struct Page *p = page; p < page + size; p++) {
ffffffffc0200812:	00281793          	slli	a5,a6,0x2
ffffffffc0200816:	983e                	add	a6,a6,a5
    struct Page *page = buddy_page_base + offset;
ffffffffc0200818:	00005517          	auipc	a0,0x5
ffffffffc020081c:	82053503          	ld	a0,-2016(a0) # ffffffffc0205038 <buddy_page_base>
ffffffffc0200820:	952e                	add	a0,a0,a1
    for (struct Page *p = page; p < page + size; p++) {
ffffffffc0200822:	080e                	slli	a6,a6,0x3
ffffffffc0200824:	982a                	add	a6,a6,a0
ffffffffc0200826:	01057e63          	bgeu	a0,a6,ffffffffc0200842 <buddy_alloc_pages+0x108>
ffffffffc020082a:	87aa                	mv	a5,a0
        SetPageReserved(p);
ffffffffc020082c:	6798                	ld	a4,8(a5)
    for (struct Page *p = page; p < page + size; p++) {
ffffffffc020082e:	02878793          	addi	a5,a5,40
        SetPageReserved(p);
ffffffffc0200832:	00176713          	ori	a4,a4,1
ffffffffc0200836:	fee7b023          	sd	a4,-32(a5)
    for (struct Page *p = page; p < page + size; p++) {
ffffffffc020083a:	ff07e9e3          	bltu	a5,a6,ffffffffc020082c <buddy_alloc_pages+0xf2>
ffffffffc020083e:	8082                	ret
        return NULL;
ffffffffc0200840:	4501                	li	a0,0
}
ffffffffc0200842:	8082                	ret
    while (size < n) {
ffffffffc0200844:	4805                	li	a6,1
    unsigned int size = 1;
ffffffffc0200846:	4705                	li	a4,1
ffffffffc0200848:	b705                	j	ffffffffc0200768 <buddy_alloc_pages+0x2e>
    buddy_longest[index] = 0;
ffffffffc020084a:	00062023          	sw	zero,0(a2)
ffffffffc020084e:	4581                	li	a1,0
ffffffffc0200850:	b7c9                	j	ffffffffc0200812 <buddy_alloc_pages+0xd8>
buddy_alloc_pages(size_t n) {
ffffffffc0200852:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200854:	00001697          	auipc	a3,0x1
ffffffffc0200858:	e3468693          	addi	a3,a3,-460 # ffffffffc0201688 <etext+0x262>
ffffffffc020085c:	00001617          	auipc	a2,0x1
ffffffffc0200860:	e3460613          	addi	a2,a2,-460 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200864:	07a00593          	li	a1,122
ffffffffc0200868:	00001517          	auipc	a0,0x1
ffffffffc020086c:	e4050513          	addi	a0,a0,-448 # ffffffffc02016a8 <etext+0x282>
buddy_alloc_pages(size_t n) {
ffffffffc0200870:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200872:	951ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200876 <buddy_check>:

/**
 * 基本检查函数
 */
static void
buddy_check(void) {
ffffffffc0200876:	7179                	addi	sp,sp,-48
    cprintf("Buddy System Check Start...\n");
ffffffffc0200878:	00001517          	auipc	a0,0x1
ffffffffc020087c:	e8850513          	addi	a0,a0,-376 # ffffffffc0201700 <etext+0x2da>
buddy_check(void) {
ffffffffc0200880:	f406                	sd	ra,40(sp)
ffffffffc0200882:	f022                	sd	s0,32(sp)
ffffffffc0200884:	ec26                	sd	s1,24(sp)
ffffffffc0200886:	e84a                	sd	s2,16(sp)
ffffffffc0200888:	e44e                	sd	s3,8(sp)
    cprintf("Buddy System Check Start...\n");
ffffffffc020088a:	8c3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    struct Page *p0, *p1, *p2, *p3;
    
    // Test 1: 分配单个页面
    cprintf("Test 1: Allocating single pages...\n");
ffffffffc020088e:	00001517          	auipc	a0,0x1
ffffffffc0200892:	e9250513          	addi	a0,a0,-366 # ffffffffc0201720 <etext+0x2fa>
ffffffffc0200896:	8b7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = alloc_page();
ffffffffc020089a:	4505                	li	a0,1
ffffffffc020089c:	4fa000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
    assert(p0 != NULL);
ffffffffc02008a0:	36050c63          	beqz	a0,ffffffffc0200c18 <buddy_check+0x3a2>
ffffffffc02008a4:	842a                	mv	s0,a0
    p1 = alloc_page();
ffffffffc02008a6:	4505                	li	a0,1
ffffffffc02008a8:	4ee000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc02008ac:	84aa                	mv	s1,a0
    assert(p1 != NULL);
ffffffffc02008ae:	30050563          	beqz	a0,ffffffffc0200bb8 <buddy_check+0x342>
    p2 = alloc_page();
ffffffffc02008b2:	4505                	li	a0,1
ffffffffc02008b4:	4e2000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc02008b8:	892a                	mv	s2,a0
    assert(p2 != NULL);
ffffffffc02008ba:	32050f63          	beqz	a0,ffffffffc0200bf8 <buddy_check+0x382>
    
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02008be:	2a940d63          	beq	s0,s1,ffffffffc0200b78 <buddy_check+0x302>
ffffffffc02008c2:	2aa40b63          	beq	s0,a0,ffffffffc0200b78 <buddy_check+0x302>
ffffffffc02008c6:	2aa48963          	beq	s1,a0,ffffffffc0200b78 <buddy_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02008ca:	401c                	lw	a5,0(s0)
ffffffffc02008cc:	2c079663          	bnez	a5,ffffffffc0200b98 <buddy_check+0x322>
ffffffffc02008d0:	409c                	lw	a5,0(s1)
ffffffffc02008d2:	2c079363          	bnez	a5,ffffffffc0200b98 <buddy_check+0x322>
ffffffffc02008d6:	411c                	lw	a5,0(a0)
ffffffffc02008d8:	2c079063          	bnez	a5,ffffffffc0200b98 <buddy_check+0x322>
    
    cprintf("Test 1 Passed!\n");
ffffffffc02008dc:	00001517          	auipc	a0,0x1
ffffffffc02008e0:	f0450513          	addi	a0,a0,-252 # ffffffffc02017e0 <etext+0x3ba>
ffffffffc02008e4:	869ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 2: 释放页面
    cprintf("Test 2: Freeing pages...\n");
ffffffffc02008e8:	00001517          	auipc	a0,0x1
ffffffffc02008ec:	f0850513          	addi	a0,a0,-248 # ffffffffc02017f0 <etext+0x3ca>
ffffffffc02008f0:	85dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    free_page(p0);
ffffffffc02008f4:	4585                	li	a1,1
ffffffffc02008f6:	8522                	mv	a0,s0
ffffffffc02008f8:	4aa000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_page(p1);
ffffffffc02008fc:	8526                	mv	a0,s1
ffffffffc02008fe:	4585                	li	a1,1
ffffffffc0200900:	4a2000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_page(p2);
ffffffffc0200904:	4585                	li	a1,1
ffffffffc0200906:	854a                	mv	a0,s2
ffffffffc0200908:	49a000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    cprintf("Test 2 Passed!\n");
ffffffffc020090c:	00001517          	auipc	a0,0x1
ffffffffc0200910:	f0450513          	addi	a0,a0,-252 # ffffffffc0201810 <etext+0x3ea>
ffffffffc0200914:	839ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 3: 分配多个页面
    cprintf("Test 3: Allocating multiple pages...\n");
ffffffffc0200918:	00001517          	auipc	a0,0x1
ffffffffc020091c:	f0850513          	addi	a0,a0,-248 # ffffffffc0201820 <etext+0x3fa>
ffffffffc0200920:	82dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = alloc_pages(5);  // 实际分配 8 页
ffffffffc0200924:	4515                	li	a0,5
ffffffffc0200926:	470000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc020092a:	84aa                	mv	s1,a0
    assert(p0 != NULL);
ffffffffc020092c:	32050663          	beqz	a0,ffffffffc0200c58 <buddy_check+0x3e2>
    cprintf("Allocated 5 pages (actual: 8)\n");
ffffffffc0200930:	00001517          	auipc	a0,0x1
ffffffffc0200934:	f1850513          	addi	a0,a0,-232 # ffffffffc0201848 <etext+0x422>
ffffffffc0200938:	815ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p1 = alloc_pages(3);  // 实际分配 4 页
ffffffffc020093c:	450d                	li	a0,3
ffffffffc020093e:	458000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200942:	842a                	mv	s0,a0
    assert(p1 != NULL);
ffffffffc0200944:	28050a63          	beqz	a0,ffffffffc0200bd8 <buddy_check+0x362>
    cprintf("Allocated 3 pages (actual: 4)\n");
ffffffffc0200948:	00001517          	auipc	a0,0x1
ffffffffc020094c:	f2050513          	addi	a0,a0,-224 # ffffffffc0201868 <etext+0x442>
ffffffffc0200950:	ffcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    assert(p0 != p1);
ffffffffc0200954:	32848263          	beq	s1,s0,ffffffffc0200c78 <buddy_check+0x402>
    cprintf("Test 3 Passed!\n");
ffffffffc0200958:	00001517          	auipc	a0,0x1
ffffffffc020095c:	f4050513          	addi	a0,a0,-192 # ffffffffc0201898 <etext+0x472>
ffffffffc0200960:	fecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 4: 释放并测试合并
    cprintf("Test 4: Testing merge...\n");
ffffffffc0200964:	00001517          	auipc	a0,0x1
ffffffffc0200968:	f4450513          	addi	a0,a0,-188 # ffffffffc02018a8 <etext+0x482>
ffffffffc020096c:	fe0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    free_pages(p0, 5);
ffffffffc0200970:	8526                	mv	a0,s1
ffffffffc0200972:	4595                	li	a1,5
ffffffffc0200974:	42e000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_pages(p1, 3);
ffffffffc0200978:	458d                	li	a1,3
ffffffffc020097a:	8522                	mv	a0,s0
ffffffffc020097c:	426000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    cprintf("Test 4 Passed!\n");
ffffffffc0200980:	00001517          	auipc	a0,0x1
ffffffffc0200984:	f4850513          	addi	a0,a0,-184 # ffffffffc02018c8 <etext+0x4a2>
ffffffffc0200988:	fc4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 5: 大块分配
    cprintf("Test 5: Large allocation...\n");
ffffffffc020098c:	00001517          	auipc	a0,0x1
ffffffffc0200990:	f4c50513          	addi	a0,a0,-180 # ffffffffc02018d8 <etext+0x4b2>
ffffffffc0200994:	fb8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t free_before = nr_free_pages();
ffffffffc0200998:	416000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
    cprintf("Free pages before: %d\n", free_before);
ffffffffc020099c:	85aa                	mv	a1,a0
    size_t free_before = nr_free_pages();
ffffffffc020099e:	842a                	mv	s0,a0
    cprintf("Free pages before: %d\n", free_before);
ffffffffc02009a0:	00001517          	auipc	a0,0x1
ffffffffc02009a4:	f5850513          	addi	a0,a0,-168 # ffffffffc02018f8 <etext+0x4d2>
ffffffffc02009a8:	fa4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p0 = alloc_pages(free_before / 2);
ffffffffc02009ac:	00145913          	srli	s2,s0,0x1
ffffffffc02009b0:	854a                	mv	a0,s2
ffffffffc02009b2:	3e4000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc02009b6:	84aa                	mv	s1,a0
    if (p0 != NULL) {
ffffffffc02009b8:	c11d                	beqz	a0,ffffffffc02009de <buddy_check+0x168>
        cprintf("Allocated %d pages\n", free_before / 2);
ffffffffc02009ba:	85ca                	mv	a1,s2
ffffffffc02009bc:	00001517          	auipc	a0,0x1
ffffffffc02009c0:	f5450513          	addi	a0,a0,-172 # ffffffffc0201910 <etext+0x4ea>
ffffffffc02009c4:	f88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(p0, free_before / 2);
ffffffffc02009c8:	85ca                	mv	a1,s2
ffffffffc02009ca:	8526                	mv	a0,s1
ffffffffc02009cc:	3d6000ef          	jal	ra,ffffffffc0200da2 <free_pages>
        cprintf("Freed %d pages\n", free_before / 2);
ffffffffc02009d0:	85ca                	mv	a1,s2
ffffffffc02009d2:	00001517          	auipc	a0,0x1
ffffffffc02009d6:	f5650513          	addi	a0,a0,-170 # ffffffffc0201928 <etext+0x502>
ffffffffc02009da:	f72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    
    size_t free_after = nr_free_pages();
ffffffffc02009de:	3d0000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc02009e2:	84aa                	mv	s1,a0
    cprintf("Free pages after: %d\n", free_after);
ffffffffc02009e4:	85aa                	mv	a1,a0
ffffffffc02009e6:	00001517          	auipc	a0,0x1
ffffffffc02009ea:	f5250513          	addi	a0,a0,-174 # ffffffffc0201938 <etext+0x512>
ffffffffc02009ee:	f5eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(free_before == free_after);
ffffffffc02009f2:	24941363          	bne	s0,s1,ffffffffc0200c38 <buddy_check+0x3c2>
    cprintf("Test 5 Passed!\n");
ffffffffc02009f6:	00001517          	auipc	a0,0x1
ffffffffc02009fa:	f7a50513          	addi	a0,a0,-134 # ffffffffc0201970 <etext+0x54a>
ffffffffc02009fe:	f4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 6: 边界测试
    cprintf("Test 6: Boundary test...\n");
ffffffffc0200a02:	00001517          	auipc	a0,0x1
ffffffffc0200a06:	f7e50513          	addi	a0,a0,-130 # ffffffffc0201980 <etext+0x55a>
ffffffffc0200a0a:	f42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = alloc_pages(1);
ffffffffc0200a0e:	4505                	li	a0,1
ffffffffc0200a10:	386000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200a14:	892a                	mv	s2,a0
    p1 = alloc_pages(2);
ffffffffc0200a16:	4509                	li	a0,2
ffffffffc0200a18:	37e000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200a1c:	84aa                	mv	s1,a0
    p2 = alloc_pages(4);
ffffffffc0200a1e:	4511                	li	a0,4
ffffffffc0200a20:	376000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200a24:	842a                	mv	s0,a0
    p3 = alloc_pages(8);
ffffffffc0200a26:	4521                	li	a0,8
ffffffffc0200a28:	36e000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200a2c:	89aa                	mv	s3,a0
    
    assert(p0 && p1 && p2 && p3);
ffffffffc0200a2e:	12090563          	beqz	s2,ffffffffc0200b58 <buddy_check+0x2e2>
ffffffffc0200a32:	12048363          	beqz	s1,ffffffffc0200b58 <buddy_check+0x2e2>
ffffffffc0200a36:	12040163          	beqz	s0,ffffffffc0200b58 <buddy_check+0x2e2>
ffffffffc0200a3a:	10050f63          	beqz	a0,ffffffffc0200b58 <buddy_check+0x2e2>
    
    free_pages(p0, 1);
ffffffffc0200a3e:	4585                	li	a1,1
ffffffffc0200a40:	854a                	mv	a0,s2
ffffffffc0200a42:	360000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_pages(p1, 2);
ffffffffc0200a46:	4589                	li	a1,2
ffffffffc0200a48:	8526                	mv	a0,s1
ffffffffc0200a4a:	358000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_pages(p2, 4);
ffffffffc0200a4e:	8522                	mv	a0,s0
ffffffffc0200a50:	4591                	li	a1,4
ffffffffc0200a52:	350000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    free_pages(p3, 8);
ffffffffc0200a56:	45a1                	li	a1,8
ffffffffc0200a58:	854e                	mv	a0,s3
ffffffffc0200a5a:	348000ef          	jal	ra,ffffffffc0200da2 <free_pages>
    cprintf("Test 6 Passed!\n");
ffffffffc0200a5e:	00001517          	auipc	a0,0x1
ffffffffc0200a62:	f5a50513          	addi	a0,a0,-166 # ffffffffc02019b8 <etext+0x592>
ffffffffc0200a66:	ee6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 7: 内存耗尽测试
    cprintf("Test 7: Exhaustion test...\n");
ffffffffc0200a6a:	00001517          	auipc	a0,0x1
ffffffffc0200a6e:	f5e50513          	addi	a0,a0,-162 # ffffffffc02019c8 <etext+0x5a2>
ffffffffc0200a72:	edaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t total_free = nr_free_pages();
ffffffffc0200a76:	338000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc0200a7a:	842a                	mv	s0,a0
    cprintf("Total free pages: %d\n", total_free);
ffffffffc0200a7c:	85aa                	mv	a1,a0
ffffffffc0200a7e:	00001517          	auipc	a0,0x1
ffffffffc0200a82:	f6a50513          	addi	a0,a0,-150 # ffffffffc02019e8 <etext+0x5c2>
ffffffffc0200a86:	ec6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Buddy system 会将请求向上取整到2的幂
    // 分配全部内存
    if (total_free > 0) {
ffffffffc0200a8a:	e01d                	bnez	s0,ffffffffc0200ab0 <buddy_check+0x23a>
            }
        } else {
            cprintf("Cannot allocate %d pages in one block (this is expected)\n", total_free);
        }
    }
    cprintf("Test 7 Passed!\n");
ffffffffc0200a8c:	00001517          	auipc	a0,0x1
ffffffffc0200a90:	0dc50513          	addi	a0,a0,220 # ffffffffc0201b68 <etext+0x742>
ffffffffc0200a94:	eb8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    cprintf("Buddy System Check Passed!\n");
}
ffffffffc0200a98:	7402                	ld	s0,32(sp)
ffffffffc0200a9a:	70a2                	ld	ra,40(sp)
ffffffffc0200a9c:	64e2                	ld	s1,24(sp)
ffffffffc0200a9e:	6942                	ld	s2,16(sp)
ffffffffc0200aa0:	69a2                	ld	s3,8(sp)
    cprintf("Buddy System Check Passed!\n");
ffffffffc0200aa2:	00001517          	auipc	a0,0x1
ffffffffc0200aa6:	0d650513          	addi	a0,a0,214 # ffffffffc0201b78 <etext+0x752>
}
ffffffffc0200aaa:	6145                	addi	sp,sp,48
    cprintf("Buddy System Check Passed!\n");
ffffffffc0200aac:	ea0ff06f          	j	ffffffffc020014c <cprintf>
        struct Page *p_all = alloc_pages(total_free);
ffffffffc0200ab0:	8522                	mv	a0,s0
ffffffffc0200ab2:	2e4000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200ab6:	84aa                	mv	s1,a0
            cprintf("Allocated all %d pages\n", total_free);
ffffffffc0200ab8:	85a2                	mv	a1,s0
        if (p_all != NULL) {
ffffffffc0200aba:	c149                	beqz	a0,ffffffffc0200b3c <buddy_check+0x2c6>
            cprintf("Allocated all %d pages\n", total_free);
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	f4450513          	addi	a0,a0,-188 # ffffffffc0201a00 <etext+0x5da>
ffffffffc0200ac4:	e88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            struct Page *p_extra = alloc_page();
ffffffffc0200ac8:	4505                	li	a0,1
ffffffffc0200aca:	2cc000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200ace:	892a                	mv	s2,a0
            if (p_extra == NULL) {
ffffffffc0200ad0:	cd39                	beqz	a0,ffffffffc0200b2e <buddy_check+0x2b8>
                cprintf("Warning: Still can allocate (might have fragmentation)\n");
ffffffffc0200ad2:	00001517          	auipc	a0,0x1
ffffffffc0200ad6:	f7650513          	addi	a0,a0,-138 # ffffffffc0201a48 <etext+0x622>
ffffffffc0200ada:	e72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
                free_page(p_extra);
ffffffffc0200ade:	4585                	li	a1,1
ffffffffc0200ae0:	854a                	mv	a0,s2
ffffffffc0200ae2:	2c0000ef          	jal	ra,ffffffffc0200da2 <free_pages>
            free_pages(p_all, total_free);
ffffffffc0200ae6:	85a2                	mv	a1,s0
ffffffffc0200ae8:	8526                	mv	a0,s1
ffffffffc0200aea:	2b8000ef          	jal	ra,ffffffffc0200da2 <free_pages>
            cprintf("Freed all %d pages\n", total_free);
ffffffffc0200aee:	85a2                	mv	a1,s0
ffffffffc0200af0:	00001517          	auipc	a0,0x1
ffffffffc0200af4:	f9050513          	addi	a0,a0,-112 # ffffffffc0201a80 <etext+0x65a>
ffffffffc0200af8:	e54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            size_t free_after = nr_free_pages();
ffffffffc0200afc:	2b2000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc0200b00:	85aa                	mv	a1,a0
            cprintf("Free pages after release: %d\n", free_after);
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	f9650513          	addi	a0,a0,-106 # ffffffffc0201a98 <etext+0x672>
ffffffffc0200b0a:	e42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            p_extra = alloc_page();
ffffffffc0200b0e:	4505                	li	a0,1
ffffffffc0200b10:	286000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200b14:	842a                	mv	s0,a0
            if (p_extra != NULL) {
ffffffffc0200b16:	c915                	beqz	a0,ffffffffc0200b4a <buddy_check+0x2d4>
                cprintf("Can allocate after freeing - Correct!\n");
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	fa050513          	addi	a0,a0,-96 # ffffffffc0201ab8 <etext+0x692>
ffffffffc0200b20:	e2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
                free_page(p_extra);
ffffffffc0200b24:	4585                	li	a1,1
ffffffffc0200b26:	8522                	mv	a0,s0
ffffffffc0200b28:	27a000ef          	jal	ra,ffffffffc0200da2 <free_pages>
ffffffffc0200b2c:	b785                	j	ffffffffc0200a8c <buddy_check+0x216>
                cprintf("Cannot allocate when memory is full - Correct!\n");
ffffffffc0200b2e:	00001517          	auipc	a0,0x1
ffffffffc0200b32:	eea50513          	addi	a0,a0,-278 # ffffffffc0201a18 <etext+0x5f2>
ffffffffc0200b36:	e16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b3a:	b775                	j	ffffffffc0200ae6 <buddy_check+0x270>
            cprintf("Cannot allocate %d pages in one block (this is expected)\n", total_free);
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	fec50513          	addi	a0,a0,-20 # ffffffffc0201b28 <etext+0x702>
ffffffffc0200b44:	e08ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b48:	b791                	j	ffffffffc0200a8c <buddy_check+0x216>
                cprintf("Note: Cannot allocate single page, this might be due to alignment\n");
ffffffffc0200b4a:	00001517          	auipc	a0,0x1
ffffffffc0200b4e:	f9650513          	addi	a0,a0,-106 # ffffffffc0201ae0 <etext+0x6ba>
ffffffffc0200b52:	dfaff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b56:	bf1d                	j	ffffffffc0200a8c <buddy_check+0x216>
    assert(p0 && p1 && p2 && p3);
ffffffffc0200b58:	00001697          	auipc	a3,0x1
ffffffffc0200b5c:	e4868693          	addi	a3,a3,-440 # ffffffffc02019a0 <etext+0x57a>
ffffffffc0200b60:	00001617          	auipc	a2,0x1
ffffffffc0200b64:	b3060613          	addi	a2,a2,-1232 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200b68:	13400593          	li	a1,308
ffffffffc0200b6c:	00001517          	auipc	a0,0x1
ffffffffc0200b70:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200b74:	e4eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b78:	00001697          	auipc	a3,0x1
ffffffffc0200b7c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0201778 <etext+0x352>
ffffffffc0200b80:	00001617          	auipc	a2,0x1
ffffffffc0200b84:	b1060613          	addi	a2,a2,-1264 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200b88:	0fd00593          	li	a1,253
ffffffffc0200b8c:	00001517          	auipc	a0,0x1
ffffffffc0200b90:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200b94:	e2eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b98:	00001697          	auipc	a3,0x1
ffffffffc0200b9c:	c0868693          	addi	a3,a3,-1016 # ffffffffc02017a0 <etext+0x37a>
ffffffffc0200ba0:	00001617          	auipc	a2,0x1
ffffffffc0200ba4:	af060613          	addi	a2,a2,-1296 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200ba8:	0fe00593          	li	a1,254
ffffffffc0200bac:	00001517          	auipc	a0,0x1
ffffffffc0200bb0:	afc50513          	addi	a0,a0,-1284 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200bb4:	e0eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0200bb8:	00001697          	auipc	a3,0x1
ffffffffc0200bbc:	ba068693          	addi	a3,a3,-1120 # ffffffffc0201758 <etext+0x332>
ffffffffc0200bc0:	00001617          	auipc	a2,0x1
ffffffffc0200bc4:	ad060613          	addi	a2,a2,-1328 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200bc8:	0f900593          	li	a1,249
ffffffffc0200bcc:	00001517          	auipc	a0,0x1
ffffffffc0200bd0:	adc50513          	addi	a0,a0,-1316 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200bd4:	deeff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0200bd8:	00001697          	auipc	a3,0x1
ffffffffc0200bdc:	b8068693          	addi	a3,a3,-1152 # ffffffffc0201758 <etext+0x332>
ffffffffc0200be0:	00001617          	auipc	a2,0x1
ffffffffc0200be4:	ab060613          	addi	a2,a2,-1360 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200be8:	11000593          	li	a1,272
ffffffffc0200bec:	00001517          	auipc	a0,0x1
ffffffffc0200bf0:	abc50513          	addi	a0,a0,-1348 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200bf4:	dceff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc0200bf8:	00001697          	auipc	a3,0x1
ffffffffc0200bfc:	b7068693          	addi	a3,a3,-1168 # ffffffffc0201768 <etext+0x342>
ffffffffc0200c00:	00001617          	auipc	a2,0x1
ffffffffc0200c04:	a9060613          	addi	a2,a2,-1392 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200c08:	0fb00593          	li	a1,251
ffffffffc0200c0c:	00001517          	auipc	a0,0x1
ffffffffc0200c10:	a9c50513          	addi	a0,a0,-1380 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200c14:	daeff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200c18:	00001697          	auipc	a3,0x1
ffffffffc0200c1c:	b3068693          	addi	a3,a3,-1232 # ffffffffc0201748 <etext+0x322>
ffffffffc0200c20:	00001617          	auipc	a2,0x1
ffffffffc0200c24:	a7060613          	addi	a2,a2,-1424 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200c28:	0f700593          	li	a1,247
ffffffffc0200c2c:	00001517          	auipc	a0,0x1
ffffffffc0200c30:	a7c50513          	addi	a0,a0,-1412 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200c34:	d8eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_before == free_after);
ffffffffc0200c38:	00001697          	auipc	a3,0x1
ffffffffc0200c3c:	d1868693          	addi	a3,a3,-744 # ffffffffc0201950 <etext+0x52a>
ffffffffc0200c40:	00001617          	auipc	a2,0x1
ffffffffc0200c44:	a5060613          	addi	a2,a2,-1456 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200c48:	12a00593          	li	a1,298
ffffffffc0200c4c:	00001517          	auipc	a0,0x1
ffffffffc0200c50:	a5c50513          	addi	a0,a0,-1444 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200c54:	d6eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200c58:	00001697          	auipc	a3,0x1
ffffffffc0200c5c:	af068693          	addi	a3,a3,-1296 # ffffffffc0201748 <etext+0x322>
ffffffffc0200c60:	00001617          	auipc	a2,0x1
ffffffffc0200c64:	a3060613          	addi	a2,a2,-1488 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200c68:	10c00593          	li	a1,268
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	a3c50513          	addi	a0,a0,-1476 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200c74:	d4eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1);
ffffffffc0200c78:	00001697          	auipc	a3,0x1
ffffffffc0200c7c:	c1068693          	addi	a3,a3,-1008 # ffffffffc0201888 <etext+0x462>
ffffffffc0200c80:	00001617          	auipc	a2,0x1
ffffffffc0200c84:	a1060613          	addi	a2,a2,-1520 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200c88:	11300593          	li	a1,275
ffffffffc0200c8c:	00001517          	auipc	a0,0x1
ffffffffc0200c90:	a1c50513          	addi	a0,a0,-1508 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200c94:	d2eff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200c98 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200c98:	1141                	addi	sp,sp,-16
ffffffffc0200c9a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c9c:	cde9                	beqz	a1,ffffffffc0200d76 <buddy_init_memmap+0xde>
    unsigned int real_size = 1;
ffffffffc0200c9e:	4605                	li	a2,1
    while (real_size < n) {
ffffffffc0200ca0:	4885                	li	a7,1
ffffffffc0200ca2:	4809                	li	a6,2
ffffffffc0200ca4:	00c58d63          	beq	a1,a2,ffffffffc0200cbe <buddy_init_memmap+0x26>
        real_size <<= 1;
ffffffffc0200ca8:	0016161b          	slliw	a2,a2,0x1
    while (real_size < n) {
ffffffffc0200cac:	02061793          	slli	a5,a2,0x20
ffffffffc0200cb0:	9381                	srli	a5,a5,0x20
ffffffffc0200cb2:	feb7ebe3          	bltu	a5,a1,ffffffffc0200ca8 <buddy_init_memmap+0x10>
    unsigned int node_count = 2 * buddy_size - 1;
ffffffffc0200cb6:	0016181b          	slliw	a6,a2,0x1
ffffffffc0200cba:	fff8089b          	addiw	a7,a6,-1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cbe:	00004697          	auipc	a3,0x4
ffffffffc0200cc2:	3926b683          	ld	a3,914(a3) # ffffffffc0205050 <pages>
ffffffffc0200cc6:	40d506b3          	sub	a3,a0,a3
ffffffffc0200cca:	00001797          	auipc	a5,0x1
ffffffffc0200cce:	2f67b783          	ld	a5,758(a5) # ffffffffc0201fc0 <error_string+0x38>
ffffffffc0200cd2:	868d                	srai	a3,a3,0x3
ffffffffc0200cd4:	02f686b3          	mul	a3,a3,a5
    buddy_size = real_size;
ffffffffc0200cd8:	00004797          	auipc	a5,0x4
ffffffffc0200cdc:	36c7a423          	sw	a2,872(a5) # ffffffffc0205040 <buddy_size>
    buddy_page_base = base;
ffffffffc0200ce0:	00004797          	auipc	a5,0x4
ffffffffc0200ce4:	34a7bc23          	sd	a0,856(a5) # ffffffffc0205038 <buddy_page_base>
ffffffffc0200ce8:	00001797          	auipc	a5,0x1
ffffffffc0200cec:	2e07b783          	ld	a5,736(a5) # ffffffffc0201fc8 <nbase>
    for (; p != base + n; p++) {
ffffffffc0200cf0:	00259713          	slli	a4,a1,0x2
ffffffffc0200cf4:	972e                	add	a4,a4,a1
ffffffffc0200cf6:	070e                	slli	a4,a4,0x3
ffffffffc0200cf8:	972a                	add	a4,a4,a0
ffffffffc0200cfa:	96be                	add	a3,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cfc:	06b2                	slli	a3,a3,0xc
    buddy_longest = (unsigned int *)(page2pa(base) + va_pa_offset);
ffffffffc0200cfe:	00004797          	auipc	a5,0x4
ffffffffc0200d02:	3727b783          	ld	a5,882(a5) # ffffffffc0205070 <va_pa_offset>
ffffffffc0200d06:	96be                	add	a3,a3,a5
ffffffffc0200d08:	00004797          	auipc	a5,0x4
ffffffffc0200d0c:	32d7b423          	sd	a3,808(a5) # ffffffffc0205030 <buddy_longest>
        assert(PageReserved(p));
ffffffffc0200d10:	651c                	ld	a5,8(a0)
ffffffffc0200d12:	8b85                	andi	a5,a5,1
ffffffffc0200d14:	c3a9                	beqz	a5,ffffffffc0200d56 <buddy_init_memmap+0xbe>
        p->flags = 0;
ffffffffc0200d16:	00053423          	sd	zero,8(a0)
        p->property = 0;
ffffffffc0200d1a:	00052823          	sw	zero,16(a0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d1e:	00052023          	sw	zero,0(a0)
    for (; p != base + n; p++) {
ffffffffc0200d22:	02850513          	addi	a0,a0,40
ffffffffc0200d26:	fea715e3          	bne	a4,a0,ffffffffc0200d10 <buddy_init_memmap+0x78>
    for (unsigned int i = 0; i < node_count; i++) {
ffffffffc0200d2a:	4781                	li	a5,0
        if (IS_POWER_OF_2(i + 1)) {
ffffffffc0200d2c:	0007871b          	sext.w	a4,a5
ffffffffc0200d30:	2785                	addiw	a5,a5,1
ffffffffc0200d32:	8f7d                	and	a4,a4,a5
ffffffffc0200d34:	2701                	sext.w	a4,a4
ffffffffc0200d36:	e319                	bnez	a4,ffffffffc0200d3c <buddy_init_memmap+0xa4>
            node_size /= 2;
ffffffffc0200d38:	0018581b          	srliw	a6,a6,0x1
        buddy_longest[i] = node_size;
ffffffffc0200d3c:	0106a023          	sw	a6,0(a3)
    for (unsigned int i = 0; i < node_count; i++) {
ffffffffc0200d40:	0691                	addi	a3,a3,4
ffffffffc0200d42:	ff17e5e3          	bltu	a5,a7,ffffffffc0200d2c <buddy_init_memmap+0x94>
}
ffffffffc0200d46:	60a2                	ld	ra,8(sp)
    cprintf("Buddy System: initialized %d pages (actual: %d)\n", n, buddy_size);
ffffffffc0200d48:	00001517          	auipc	a0,0x1
ffffffffc0200d4c:	e6050513          	addi	a0,a0,-416 # ffffffffc0201ba8 <etext+0x782>
}
ffffffffc0200d50:	0141                	addi	sp,sp,16
    cprintf("Buddy System: initialized %d pages (actual: %d)\n", n, buddy_size);
ffffffffc0200d52:	bfaff06f          	j	ffffffffc020014c <cprintf>
        assert(PageReserved(p));
ffffffffc0200d56:	00001697          	auipc	a3,0x1
ffffffffc0200d5a:	e4268693          	addi	a3,a3,-446 # ffffffffc0201b98 <etext+0x772>
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	93260613          	addi	a2,a2,-1742 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200d66:	06100593          	li	a1,97
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	93e50513          	addi	a0,a0,-1730 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200d72:	c50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200d76:	00001697          	auipc	a3,0x1
ffffffffc0200d7a:	91268693          	addi	a3,a3,-1774 # ffffffffc0201688 <etext+0x262>
ffffffffc0200d7e:	00001617          	auipc	a2,0x1
ffffffffc0200d82:	91260613          	addi	a2,a2,-1774 # ffffffffc0201690 <etext+0x26a>
ffffffffc0200d86:	04400593          	li	a1,68
ffffffffc0200d8a:	00001517          	auipc	a0,0x1
ffffffffc0200d8e:	91e50513          	addi	a0,a0,-1762 # ffffffffc02016a8 <etext+0x282>
ffffffffc0200d92:	c30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d96 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200d96:	00004797          	auipc	a5,0x4
ffffffffc0200d9a:	2c27b783          	ld	a5,706(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200d9e:	6f9c                	ld	a5,24(a5)
ffffffffc0200da0:	8782                	jr	a5

ffffffffc0200da2 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200da2:	00004797          	auipc	a5,0x4
ffffffffc0200da6:	2b67b783          	ld	a5,694(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200daa:	739c                	ld	a5,32(a5)
ffffffffc0200dac:	8782                	jr	a5

ffffffffc0200dae <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200dae:	00004797          	auipc	a5,0x4
ffffffffc0200db2:	2aa7b783          	ld	a5,682(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200db6:	779c                	ld	a5,40(a5)
ffffffffc0200db8:	8782                	jr	a5

ffffffffc0200dba <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dba:	00001797          	auipc	a5,0x1
ffffffffc0200dbe:	e3e78793          	addi	a5,a5,-450 # ffffffffc0201bf8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dc2:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200dc4:	7179                	addi	sp,sp,-48
ffffffffc0200dc6:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dc8:	00001517          	auipc	a0,0x1
ffffffffc0200dcc:	e6850513          	addi	a0,a0,-408 # ffffffffc0201c30 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dd0:	00004417          	auipc	s0,0x4
ffffffffc0200dd4:	28840413          	addi	s0,s0,648 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200dd8:	f406                	sd	ra,40(sp)
ffffffffc0200dda:	ec26                	sd	s1,24(sp)
ffffffffc0200ddc:	e44e                	sd	s3,8(sp)
ffffffffc0200dde:	e84a                	sd	s2,16(sp)
ffffffffc0200de0:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200de2:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200de4:	b68ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200de8:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200dea:	00004497          	auipc	s1,0x4
ffffffffc0200dee:	28648493          	addi	s1,s1,646 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200df2:	679c                	ld	a5,8(a5)
ffffffffc0200df4:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200df6:	57f5                	li	a5,-3
ffffffffc0200df8:	07fa                	slli	a5,a5,0x1e
ffffffffc0200dfa:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200dfc:	fc0ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200e00:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200e02:	fc4ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200e06:	14050d63          	beqz	a0,ffffffffc0200f60 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e0a:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200e0c:	00001517          	auipc	a0,0x1
ffffffffc0200e10:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201c78 <buddy_pmm_manager+0x80>
ffffffffc0200e14:	b38ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e18:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e1c:	864e                	mv	a2,s3
ffffffffc0200e1e:	fffa0693          	addi	a3,s4,-1
ffffffffc0200e22:	85ca                	mv	a1,s2
ffffffffc0200e24:	00001517          	auipc	a0,0x1
ffffffffc0200e28:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201c90 <buddy_pmm_manager+0x98>
ffffffffc0200e2c:	b20ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e30:	c80007b7          	lui	a5,0xc8000
ffffffffc0200e34:	8652                	mv	a2,s4
ffffffffc0200e36:	0d47e463          	bltu	a5,s4,ffffffffc0200efe <pmm_init+0x144>
ffffffffc0200e3a:	00005797          	auipc	a5,0x5
ffffffffc0200e3e:	23d78793          	addi	a5,a5,573 # ffffffffc0206077 <end+0xfff>
ffffffffc0200e42:	757d                	lui	a0,0xfffff
ffffffffc0200e44:	8d7d                	and	a0,a0,a5
ffffffffc0200e46:	8231                	srli	a2,a2,0xc
ffffffffc0200e48:	00004797          	auipc	a5,0x4
ffffffffc0200e4c:	20c7b023          	sd	a2,512(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e50:	00004797          	auipc	a5,0x4
ffffffffc0200e54:	20a7b023          	sd	a0,512(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e58:	000807b7          	lui	a5,0x80
ffffffffc0200e5c:	002005b7          	lui	a1,0x200
ffffffffc0200e60:	02f60563          	beq	a2,a5,ffffffffc0200e8a <pmm_init+0xd0>
ffffffffc0200e64:	00261593          	slli	a1,a2,0x2
ffffffffc0200e68:	00c586b3          	add	a3,a1,a2
ffffffffc0200e6c:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e70:	97aa                	add	a5,a5,a0
ffffffffc0200e72:	068e                	slli	a3,a3,0x3
ffffffffc0200e74:	96be                	add	a3,a3,a5
ffffffffc0200e76:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200e78:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e7a:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc0200e7e:	00176713          	ori	a4,a4,1
ffffffffc0200e82:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e86:	fef699e3          	bne	a3,a5,ffffffffc0200e78 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e8a:	95b2                	add	a1,a1,a2
ffffffffc0200e8c:	fec006b7          	lui	a3,0xfec00
ffffffffc0200e90:	96aa                	add	a3,a3,a0
ffffffffc0200e92:	058e                	slli	a1,a1,0x3
ffffffffc0200e94:	96ae                	add	a3,a3,a1
ffffffffc0200e96:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e9a:	0af6e763          	bltu	a3,a5,ffffffffc0200f48 <pmm_init+0x18e>
ffffffffc0200e9e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200ea0:	77fd                	lui	a5,0xfffff
ffffffffc0200ea2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ea6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200ea8:	04b6ee63          	bltu	a3,a1,ffffffffc0200f04 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200eac:	601c                	ld	a5,0(s0)
ffffffffc0200eae:	7b9c                	ld	a5,48(a5)
ffffffffc0200eb0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200eb2:	00001517          	auipc	a0,0x1
ffffffffc0200eb6:	e6650513          	addi	a0,a0,-410 # ffffffffc0201d18 <buddy_pmm_manager+0x120>
ffffffffc0200eba:	a92ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200ebe:	00003597          	auipc	a1,0x3
ffffffffc0200ec2:	14258593          	addi	a1,a1,322 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200ec6:	00004797          	auipc	a5,0x4
ffffffffc0200eca:	1ab7b123          	sd	a1,418(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ece:	c02007b7          	lui	a5,0xc0200
ffffffffc0200ed2:	0af5e363          	bltu	a1,a5,ffffffffc0200f78 <pmm_init+0x1be>
ffffffffc0200ed6:	6090                	ld	a2,0(s1)
}
ffffffffc0200ed8:	7402                	ld	s0,32(sp)
ffffffffc0200eda:	70a2                	ld	ra,40(sp)
ffffffffc0200edc:	64e2                	ld	s1,24(sp)
ffffffffc0200ede:	6942                	ld	s2,16(sp)
ffffffffc0200ee0:	69a2                	ld	s3,8(sp)
ffffffffc0200ee2:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ee4:	40c58633          	sub	a2,a1,a2
ffffffffc0200ee8:	00004797          	auipc	a5,0x4
ffffffffc0200eec:	16c7bc23          	sd	a2,376(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200ef0:	00001517          	auipc	a0,0x1
ffffffffc0200ef4:	e4850513          	addi	a0,a0,-440 # ffffffffc0201d38 <buddy_pmm_manager+0x140>
}
ffffffffc0200ef8:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200efa:	a52ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200efe:	c8000637          	lui	a2,0xc8000
ffffffffc0200f02:	bf25                	j	ffffffffc0200e3a <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200f04:	6705                	lui	a4,0x1
ffffffffc0200f06:	177d                	addi	a4,a4,-1
ffffffffc0200f08:	96ba                	add	a3,a3,a4
ffffffffc0200f0a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200f0c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f10:	02c7f063          	bgeu	a5,a2,ffffffffc0200f30 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200f14:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200f16:	fff80737          	lui	a4,0xfff80
ffffffffc0200f1a:	973e                	add	a4,a4,a5
ffffffffc0200f1c:	00271793          	slli	a5,a4,0x2
ffffffffc0200f20:	97ba                	add	a5,a5,a4
ffffffffc0200f22:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200f24:	8d95                	sub	a1,a1,a3
ffffffffc0200f26:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200f28:	81b1                	srli	a1,a1,0xc
ffffffffc0200f2a:	953e                	add	a0,a0,a5
ffffffffc0200f2c:	9702                	jalr	a4
}
ffffffffc0200f2e:	bfbd                	j	ffffffffc0200eac <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200f30:	00001617          	auipc	a2,0x1
ffffffffc0200f34:	db860613          	addi	a2,a2,-584 # ffffffffc0201ce8 <buddy_pmm_manager+0xf0>
ffffffffc0200f38:	06a00593          	li	a1,106
ffffffffc0200f3c:	00001517          	auipc	a0,0x1
ffffffffc0200f40:	dcc50513          	addi	a0,a0,-564 # ffffffffc0201d08 <buddy_pmm_manager+0x110>
ffffffffc0200f44:	a7eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f48:	00001617          	auipc	a2,0x1
ffffffffc0200f4c:	d7860613          	addi	a2,a2,-648 # ffffffffc0201cc0 <buddy_pmm_manager+0xc8>
ffffffffc0200f50:	06100593          	li	a1,97
ffffffffc0200f54:	00001517          	auipc	a0,0x1
ffffffffc0200f58:	d1450513          	addi	a0,a0,-748 # ffffffffc0201c68 <buddy_pmm_manager+0x70>
ffffffffc0200f5c:	a66ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200f60:	00001617          	auipc	a2,0x1
ffffffffc0200f64:	ce860613          	addi	a2,a2,-792 # ffffffffc0201c48 <buddy_pmm_manager+0x50>
ffffffffc0200f68:	04900593          	li	a1,73
ffffffffc0200f6c:	00001517          	auipc	a0,0x1
ffffffffc0200f70:	cfc50513          	addi	a0,a0,-772 # ffffffffc0201c68 <buddy_pmm_manager+0x70>
ffffffffc0200f74:	a4eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f78:	86ae                	mv	a3,a1
ffffffffc0200f7a:	00001617          	auipc	a2,0x1
ffffffffc0200f7e:	d4660613          	addi	a2,a2,-698 # ffffffffc0201cc0 <buddy_pmm_manager+0xc8>
ffffffffc0200f82:	07c00593          	li	a1,124
ffffffffc0200f86:	00001517          	auipc	a0,0x1
ffffffffc0200f8a:	ce250513          	addi	a0,a0,-798 # ffffffffc0201c68 <buddy_pmm_manager+0x70>
ffffffffc0200f8e:	a34ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f92 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200f92:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200f96:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0200f98:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200f9c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200f9e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200fa2:	f022                	sd	s0,32(sp)
ffffffffc0200fa4:	ec26                	sd	s1,24(sp)
ffffffffc0200fa6:	e84a                	sd	s2,16(sp)
ffffffffc0200fa8:	f406                	sd	ra,40(sp)
ffffffffc0200faa:	e44e                	sd	s3,8(sp)
ffffffffc0200fac:	84aa                	mv	s1,a0
ffffffffc0200fae:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200fb0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0200fb4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0200fb6:	03067e63          	bgeu	a2,a6,ffffffffc0200ff2 <printnum+0x60>
ffffffffc0200fba:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200fbc:	00805763          	blez	s0,ffffffffc0200fca <printnum+0x38>
ffffffffc0200fc0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200fc2:	85ca                	mv	a1,s2
ffffffffc0200fc4:	854e                	mv	a0,s3
ffffffffc0200fc6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200fc8:	fc65                	bnez	s0,ffffffffc0200fc0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fca:	1a02                	slli	s4,s4,0x20
ffffffffc0200fcc:	00001797          	auipc	a5,0x1
ffffffffc0200fd0:	dac78793          	addi	a5,a5,-596 # ffffffffc0201d78 <buddy_pmm_manager+0x180>
ffffffffc0200fd4:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200fd8:	9a3e                	add	s4,s4,a5
}
ffffffffc0200fda:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fdc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0200fe0:	70a2                	ld	ra,40(sp)
ffffffffc0200fe2:	69a2                	ld	s3,8(sp)
ffffffffc0200fe4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fe6:	85ca                	mv	a1,s2
ffffffffc0200fe8:	87a6                	mv	a5,s1
}
ffffffffc0200fea:	6942                	ld	s2,16(sp)
ffffffffc0200fec:	64e2                	ld	s1,24(sp)
ffffffffc0200fee:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200ff0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200ff2:	03065633          	divu	a2,a2,a6
ffffffffc0200ff6:	8722                	mv	a4,s0
ffffffffc0200ff8:	f9bff0ef          	jal	ra,ffffffffc0200f92 <printnum>
ffffffffc0200ffc:	b7f9                	j	ffffffffc0200fca <printnum+0x38>

ffffffffc0200ffe <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200ffe:	7119                	addi	sp,sp,-128
ffffffffc0201000:	f4a6                	sd	s1,104(sp)
ffffffffc0201002:	f0ca                	sd	s2,96(sp)
ffffffffc0201004:	ecce                	sd	s3,88(sp)
ffffffffc0201006:	e8d2                	sd	s4,80(sp)
ffffffffc0201008:	e4d6                	sd	s5,72(sp)
ffffffffc020100a:	e0da                	sd	s6,64(sp)
ffffffffc020100c:	fc5e                	sd	s7,56(sp)
ffffffffc020100e:	f06a                	sd	s10,32(sp)
ffffffffc0201010:	fc86                	sd	ra,120(sp)
ffffffffc0201012:	f8a2                	sd	s0,112(sp)
ffffffffc0201014:	f862                	sd	s8,48(sp)
ffffffffc0201016:	f466                	sd	s9,40(sp)
ffffffffc0201018:	ec6e                	sd	s11,24(sp)
ffffffffc020101a:	892a                	mv	s2,a0
ffffffffc020101c:	84ae                	mv	s1,a1
ffffffffc020101e:	8d32                	mv	s10,a2
ffffffffc0201020:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201022:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201026:	5b7d                	li	s6,-1
ffffffffc0201028:	00001a97          	auipc	s5,0x1
ffffffffc020102c:	d84a8a93          	addi	s5,s5,-636 # ffffffffc0201dac <buddy_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201030:	00001b97          	auipc	s7,0x1
ffffffffc0201034:	f58b8b93          	addi	s7,s7,-168 # ffffffffc0201f88 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201038:	000d4503          	lbu	a0,0(s10)
ffffffffc020103c:	001d0413          	addi	s0,s10,1
ffffffffc0201040:	01350a63          	beq	a0,s3,ffffffffc0201054 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201044:	c121                	beqz	a0,ffffffffc0201084 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201046:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201048:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020104a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020104c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201050:	ff351ae3          	bne	a0,s3,ffffffffc0201044 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201054:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201058:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020105c:	4c81                	li	s9,0
ffffffffc020105e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201060:	5c7d                	li	s8,-1
ffffffffc0201062:	5dfd                	li	s11,-1
ffffffffc0201064:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201068:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020106a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020106e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201072:	00140d13          	addi	s10,s0,1
ffffffffc0201076:	04b56263          	bltu	a0,a1,ffffffffc02010ba <vprintfmt+0xbc>
ffffffffc020107a:	058a                	slli	a1,a1,0x2
ffffffffc020107c:	95d6                	add	a1,a1,s5
ffffffffc020107e:	4194                	lw	a3,0(a1)
ffffffffc0201080:	96d6                	add	a3,a3,s5
ffffffffc0201082:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201084:	70e6                	ld	ra,120(sp)
ffffffffc0201086:	7446                	ld	s0,112(sp)
ffffffffc0201088:	74a6                	ld	s1,104(sp)
ffffffffc020108a:	7906                	ld	s2,96(sp)
ffffffffc020108c:	69e6                	ld	s3,88(sp)
ffffffffc020108e:	6a46                	ld	s4,80(sp)
ffffffffc0201090:	6aa6                	ld	s5,72(sp)
ffffffffc0201092:	6b06                	ld	s6,64(sp)
ffffffffc0201094:	7be2                	ld	s7,56(sp)
ffffffffc0201096:	7c42                	ld	s8,48(sp)
ffffffffc0201098:	7ca2                	ld	s9,40(sp)
ffffffffc020109a:	7d02                	ld	s10,32(sp)
ffffffffc020109c:	6de2                	ld	s11,24(sp)
ffffffffc020109e:	6109                	addi	sp,sp,128
ffffffffc02010a0:	8082                	ret
            padc = '0';
ffffffffc02010a2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02010a4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02010a8:	846a                	mv	s0,s10
ffffffffc02010aa:	00140d13          	addi	s10,s0,1
ffffffffc02010ae:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02010b2:	0ff5f593          	zext.b	a1,a1
ffffffffc02010b6:	fcb572e3          	bgeu	a0,a1,ffffffffc020107a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02010ba:	85a6                	mv	a1,s1
ffffffffc02010bc:	02500513          	li	a0,37
ffffffffc02010c0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02010c2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02010c6:	8d22                	mv	s10,s0
ffffffffc02010c8:	f73788e3          	beq	a5,s3,ffffffffc0201038 <vprintfmt+0x3a>
ffffffffc02010cc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02010d0:	1d7d                	addi	s10,s10,-1
ffffffffc02010d2:	ff379de3          	bne	a5,s3,ffffffffc02010cc <vprintfmt+0xce>
ffffffffc02010d6:	b78d                	j	ffffffffc0201038 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02010d8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02010dc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02010e0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02010e2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02010e6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02010ea:	02d86463          	bltu	a6,a3,ffffffffc0201112 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02010ee:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02010f2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02010f6:	0186873b          	addw	a4,a3,s8
ffffffffc02010fa:	0017171b          	slliw	a4,a4,0x1
ffffffffc02010fe:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201100:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201104:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201106:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020110a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020110e:	fed870e3          	bgeu	a6,a3,ffffffffc02010ee <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201112:	f40ddce3          	bgez	s11,ffffffffc020106a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201116:	8de2                	mv	s11,s8
ffffffffc0201118:	5c7d                	li	s8,-1
ffffffffc020111a:	bf81                	j	ffffffffc020106a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020111c:	fffdc693          	not	a3,s11
ffffffffc0201120:	96fd                	srai	a3,a3,0x3f
ffffffffc0201122:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201126:	00144603          	lbu	a2,1(s0)
ffffffffc020112a:	2d81                	sext.w	s11,s11
ffffffffc020112c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020112e:	bf35                	j	ffffffffc020106a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201130:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201134:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201138:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020113a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020113c:	bfd9                	j	ffffffffc0201112 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020113e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201140:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201144:	01174463          	blt	a4,a7,ffffffffc020114c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201148:	1a088e63          	beqz	a7,ffffffffc0201304 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020114c:	000a3603          	ld	a2,0(s4)
ffffffffc0201150:	46c1                	li	a3,16
ffffffffc0201152:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201154:	2781                	sext.w	a5,a5
ffffffffc0201156:	876e                	mv	a4,s11
ffffffffc0201158:	85a6                	mv	a1,s1
ffffffffc020115a:	854a                	mv	a0,s2
ffffffffc020115c:	e37ff0ef          	jal	ra,ffffffffc0200f92 <printnum>
            break;
ffffffffc0201160:	bde1                	j	ffffffffc0201038 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201162:	000a2503          	lw	a0,0(s4)
ffffffffc0201166:	85a6                	mv	a1,s1
ffffffffc0201168:	0a21                	addi	s4,s4,8
ffffffffc020116a:	9902                	jalr	s2
            break;
ffffffffc020116c:	b5f1                	j	ffffffffc0201038 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020116e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201170:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201174:	01174463          	blt	a4,a7,ffffffffc020117c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201178:	18088163          	beqz	a7,ffffffffc02012fa <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020117c:	000a3603          	ld	a2,0(s4)
ffffffffc0201180:	46a9                	li	a3,10
ffffffffc0201182:	8a2e                	mv	s4,a1
ffffffffc0201184:	bfc1                	j	ffffffffc0201154 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201186:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020118a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020118c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020118e:	bdf1                	j	ffffffffc020106a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201190:	85a6                	mv	a1,s1
ffffffffc0201192:	02500513          	li	a0,37
ffffffffc0201196:	9902                	jalr	s2
            break;
ffffffffc0201198:	b545                	j	ffffffffc0201038 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020119a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020119e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011a0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02011a2:	b5e1                	j	ffffffffc020106a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02011a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02011a6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02011aa:	01174463          	blt	a4,a7,ffffffffc02011b2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02011ae:	14088163          	beqz	a7,ffffffffc02012f0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02011b2:	000a3603          	ld	a2,0(s4)
ffffffffc02011b6:	46a1                	li	a3,8
ffffffffc02011b8:	8a2e                	mv	s4,a1
ffffffffc02011ba:	bf69                	j	ffffffffc0201154 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02011bc:	03000513          	li	a0,48
ffffffffc02011c0:	85a6                	mv	a1,s1
ffffffffc02011c2:	e03e                	sd	a5,0(sp)
ffffffffc02011c4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02011c6:	85a6                	mv	a1,s1
ffffffffc02011c8:	07800513          	li	a0,120
ffffffffc02011cc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02011ce:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02011d0:	6782                	ld	a5,0(sp)
ffffffffc02011d2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02011d4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02011d8:	bfb5                	j	ffffffffc0201154 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02011da:	000a3403          	ld	s0,0(s4)
ffffffffc02011de:	008a0713          	addi	a4,s4,8
ffffffffc02011e2:	e03a                	sd	a4,0(sp)
ffffffffc02011e4:	14040263          	beqz	s0,ffffffffc0201328 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02011e8:	0fb05763          	blez	s11,ffffffffc02012d6 <vprintfmt+0x2d8>
ffffffffc02011ec:	02d00693          	li	a3,45
ffffffffc02011f0:	0cd79163          	bne	a5,a3,ffffffffc02012b2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02011f4:	00044783          	lbu	a5,0(s0)
ffffffffc02011f8:	0007851b          	sext.w	a0,a5
ffffffffc02011fc:	cf85                	beqz	a5,ffffffffc0201234 <vprintfmt+0x236>
ffffffffc02011fe:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201202:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201206:	000c4563          	bltz	s8,ffffffffc0201210 <vprintfmt+0x212>
ffffffffc020120a:	3c7d                	addiw	s8,s8,-1
ffffffffc020120c:	036c0263          	beq	s8,s6,ffffffffc0201230 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201210:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201212:	0e0c8e63          	beqz	s9,ffffffffc020130e <vprintfmt+0x310>
ffffffffc0201216:	3781                	addiw	a5,a5,-32
ffffffffc0201218:	0ef47b63          	bgeu	s0,a5,ffffffffc020130e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020121c:	03f00513          	li	a0,63
ffffffffc0201220:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201222:	000a4783          	lbu	a5,0(s4)
ffffffffc0201226:	3dfd                	addiw	s11,s11,-1
ffffffffc0201228:	0a05                	addi	s4,s4,1
ffffffffc020122a:	0007851b          	sext.w	a0,a5
ffffffffc020122e:	ffe1                	bnez	a5,ffffffffc0201206 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201230:	01b05963          	blez	s11,ffffffffc0201242 <vprintfmt+0x244>
ffffffffc0201234:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201236:	85a6                	mv	a1,s1
ffffffffc0201238:	02000513          	li	a0,32
ffffffffc020123c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020123e:	fe0d9be3          	bnez	s11,ffffffffc0201234 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201242:	6a02                	ld	s4,0(sp)
ffffffffc0201244:	bbd5                	j	ffffffffc0201038 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201246:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201248:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020124c:	01174463          	blt	a4,a7,ffffffffc0201254 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201250:	08088d63          	beqz	a7,ffffffffc02012ea <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201254:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201258:	0a044d63          	bltz	s0,ffffffffc0201312 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020125c:	8622                	mv	a2,s0
ffffffffc020125e:	8a66                	mv	s4,s9
ffffffffc0201260:	46a9                	li	a3,10
ffffffffc0201262:	bdcd                	j	ffffffffc0201154 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201264:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201268:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020126a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020126c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201270:	8fb5                	xor	a5,a5,a3
ffffffffc0201272:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201276:	02d74163          	blt	a4,a3,ffffffffc0201298 <vprintfmt+0x29a>
ffffffffc020127a:	00369793          	slli	a5,a3,0x3
ffffffffc020127e:	97de                	add	a5,a5,s7
ffffffffc0201280:	639c                	ld	a5,0(a5)
ffffffffc0201282:	cb99                	beqz	a5,ffffffffc0201298 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201284:	86be                	mv	a3,a5
ffffffffc0201286:	00001617          	auipc	a2,0x1
ffffffffc020128a:	b2260613          	addi	a2,a2,-1246 # ffffffffc0201da8 <buddy_pmm_manager+0x1b0>
ffffffffc020128e:	85a6                	mv	a1,s1
ffffffffc0201290:	854a                	mv	a0,s2
ffffffffc0201292:	0ce000ef          	jal	ra,ffffffffc0201360 <printfmt>
ffffffffc0201296:	b34d                	j	ffffffffc0201038 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	b0060613          	addi	a2,a2,-1280 # ffffffffc0201d98 <buddy_pmm_manager+0x1a0>
ffffffffc02012a0:	85a6                	mv	a1,s1
ffffffffc02012a2:	854a                	mv	a0,s2
ffffffffc02012a4:	0bc000ef          	jal	ra,ffffffffc0201360 <printfmt>
ffffffffc02012a8:	bb41                	j	ffffffffc0201038 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02012aa:	00001417          	auipc	s0,0x1
ffffffffc02012ae:	ae640413          	addi	s0,s0,-1306 # ffffffffc0201d90 <buddy_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012b2:	85e2                	mv	a1,s8
ffffffffc02012b4:	8522                	mv	a0,s0
ffffffffc02012b6:	e43e                	sd	a5,8(sp)
ffffffffc02012b8:	0fc000ef          	jal	ra,ffffffffc02013b4 <strnlen>
ffffffffc02012bc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02012c0:	01b05b63          	blez	s11,ffffffffc02012d6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02012c4:	67a2                	ld	a5,8(sp)
ffffffffc02012c6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012ca:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02012cc:	85a6                	mv	a1,s1
ffffffffc02012ce:	8552                	mv	a0,s4
ffffffffc02012d0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012d2:	fe0d9ce3          	bnez	s11,ffffffffc02012ca <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012d6:	00044783          	lbu	a5,0(s0)
ffffffffc02012da:	00140a13          	addi	s4,s0,1
ffffffffc02012de:	0007851b          	sext.w	a0,a5
ffffffffc02012e2:	d3a5                	beqz	a5,ffffffffc0201242 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012e4:	05e00413          	li	s0,94
ffffffffc02012e8:	bf39                	j	ffffffffc0201206 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02012ea:	000a2403          	lw	s0,0(s4)
ffffffffc02012ee:	b7ad                	j	ffffffffc0201258 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02012f0:	000a6603          	lwu	a2,0(s4)
ffffffffc02012f4:	46a1                	li	a3,8
ffffffffc02012f6:	8a2e                	mv	s4,a1
ffffffffc02012f8:	bdb1                	j	ffffffffc0201154 <vprintfmt+0x156>
ffffffffc02012fa:	000a6603          	lwu	a2,0(s4)
ffffffffc02012fe:	46a9                	li	a3,10
ffffffffc0201300:	8a2e                	mv	s4,a1
ffffffffc0201302:	bd89                	j	ffffffffc0201154 <vprintfmt+0x156>
ffffffffc0201304:	000a6603          	lwu	a2,0(s4)
ffffffffc0201308:	46c1                	li	a3,16
ffffffffc020130a:	8a2e                	mv	s4,a1
ffffffffc020130c:	b5a1                	j	ffffffffc0201154 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020130e:	9902                	jalr	s2
ffffffffc0201310:	bf09                	j	ffffffffc0201222 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201312:	85a6                	mv	a1,s1
ffffffffc0201314:	02d00513          	li	a0,45
ffffffffc0201318:	e03e                	sd	a5,0(sp)
ffffffffc020131a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020131c:	6782                	ld	a5,0(sp)
ffffffffc020131e:	8a66                	mv	s4,s9
ffffffffc0201320:	40800633          	neg	a2,s0
ffffffffc0201324:	46a9                	li	a3,10
ffffffffc0201326:	b53d                	j	ffffffffc0201154 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201328:	03b05163          	blez	s11,ffffffffc020134a <vprintfmt+0x34c>
ffffffffc020132c:	02d00693          	li	a3,45
ffffffffc0201330:	f6d79de3          	bne	a5,a3,ffffffffc02012aa <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201334:	00001417          	auipc	s0,0x1
ffffffffc0201338:	a5c40413          	addi	s0,s0,-1444 # ffffffffc0201d90 <buddy_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020133c:	02800793          	li	a5,40
ffffffffc0201340:	02800513          	li	a0,40
ffffffffc0201344:	00140a13          	addi	s4,s0,1
ffffffffc0201348:	bd6d                	j	ffffffffc0201202 <vprintfmt+0x204>
ffffffffc020134a:	00001a17          	auipc	s4,0x1
ffffffffc020134e:	a47a0a13          	addi	s4,s4,-1465 # ffffffffc0201d91 <buddy_pmm_manager+0x199>
ffffffffc0201352:	02800513          	li	a0,40
ffffffffc0201356:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020135a:	05e00413          	li	s0,94
ffffffffc020135e:	b565                	j	ffffffffc0201206 <vprintfmt+0x208>

ffffffffc0201360 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201360:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201362:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201366:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201368:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020136a:	ec06                	sd	ra,24(sp)
ffffffffc020136c:	f83a                	sd	a4,48(sp)
ffffffffc020136e:	fc3e                	sd	a5,56(sp)
ffffffffc0201370:	e0c2                	sd	a6,64(sp)
ffffffffc0201372:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201374:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201376:	c89ff0ef          	jal	ra,ffffffffc0200ffe <vprintfmt>
}
ffffffffc020137a:	60e2                	ld	ra,24(sp)
ffffffffc020137c:	6161                	addi	sp,sp,80
ffffffffc020137e:	8082                	ret

ffffffffc0201380 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201380:	4781                	li	a5,0
ffffffffc0201382:	00004717          	auipc	a4,0x4
ffffffffc0201386:	c8e73703          	ld	a4,-882(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc020138a:	88ba                	mv	a7,a4
ffffffffc020138c:	852a                	mv	a0,a0
ffffffffc020138e:	85be                	mv	a1,a5
ffffffffc0201390:	863e                	mv	a2,a5
ffffffffc0201392:	00000073          	ecall
ffffffffc0201396:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201398:	8082                	ret

ffffffffc020139a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020139a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020139e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02013a0:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02013a2:	cb81                	beqz	a5,ffffffffc02013b2 <strlen+0x18>
        cnt ++;
ffffffffc02013a4:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02013a6:	00a707b3          	add	a5,a4,a0
ffffffffc02013aa:	0007c783          	lbu	a5,0(a5)
ffffffffc02013ae:	fbfd                	bnez	a5,ffffffffc02013a4 <strlen+0xa>
ffffffffc02013b0:	8082                	ret
    }
    return cnt;
}
ffffffffc02013b2:	8082                	ret

ffffffffc02013b4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02013b4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02013b6:	e589                	bnez	a1,ffffffffc02013c0 <strnlen+0xc>
ffffffffc02013b8:	a811                	j	ffffffffc02013cc <strnlen+0x18>
        cnt ++;
ffffffffc02013ba:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02013bc:	00f58863          	beq	a1,a5,ffffffffc02013cc <strnlen+0x18>
ffffffffc02013c0:	00f50733          	add	a4,a0,a5
ffffffffc02013c4:	00074703          	lbu	a4,0(a4)
ffffffffc02013c8:	fb6d                	bnez	a4,ffffffffc02013ba <strnlen+0x6>
ffffffffc02013ca:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02013cc:	852e                	mv	a0,a1
ffffffffc02013ce:	8082                	ret

ffffffffc02013d0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013d0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02013d4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013d8:	cb89                	beqz	a5,ffffffffc02013ea <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02013da:	0505                	addi	a0,a0,1
ffffffffc02013dc:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013de:	fee789e3          	beq	a5,a4,ffffffffc02013d0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02013e2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02013e6:	9d19                	subw	a0,a0,a4
ffffffffc02013e8:	8082                	ret
ffffffffc02013ea:	4501                	li	a0,0
ffffffffc02013ec:	bfed                	j	ffffffffc02013e6 <strcmp+0x16>

ffffffffc02013ee <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02013ee:	c20d                	beqz	a2,ffffffffc0201410 <strncmp+0x22>
ffffffffc02013f0:	962e                	add	a2,a2,a1
ffffffffc02013f2:	a031                	j	ffffffffc02013fe <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02013f4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02013f6:	00e79a63          	bne	a5,a4,ffffffffc020140a <strncmp+0x1c>
ffffffffc02013fa:	00b60b63          	beq	a2,a1,ffffffffc0201410 <strncmp+0x22>
ffffffffc02013fe:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201402:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201404:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201408:	f7f5                	bnez	a5,ffffffffc02013f4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020140a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020140e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201410:	4501                	li	a0,0
ffffffffc0201412:	8082                	ret

ffffffffc0201414 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201414:	ca01                	beqz	a2,ffffffffc0201424 <memset+0x10>
ffffffffc0201416:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201418:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020141a:	0785                	addi	a5,a5,1
ffffffffc020141c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201420:	fec79de3          	bne	a5,a2,ffffffffc020141a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201424:	8082                	ret
