
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

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
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0201b98 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	b5650513          	addi	a0,a0,-1194 # ffffffffc0201bb8 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	b2858593          	addi	a1,a1,-1240 # ffffffffc0201b96 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	b6250513          	addi	a0,a0,-1182 # ffffffffc0201bd8 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <cache_pool.0>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0201bf8 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	a5e58593          	addi	a1,a1,-1442 # ffffffffc0206af4 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0201c18 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	e4958593          	addi	a1,a1,-439 # ffffffffc0206ef3 <end+0x3ff>
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
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0201c38 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <cache_pool.0>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206af4 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	295010ef          	jal	ra,ffffffffc0201b84 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0201c68 <etext+0xd2>
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
ffffffffc0200140:	62e010ef          	jal	ra,ffffffffc020176e <vprintfmt>
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
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
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
ffffffffc0200176:	5f8010ef          	jal	ra,ffffffffc020176e <vprintfmt>
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
ffffffffc02001c2:	00007317          	auipc	t1,0x7
ffffffffc02001c6:	8ce30313          	addi	t1,t1,-1842 # ffffffffc0206a90 <is_panic>
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
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	a9650513          	addi	a0,a0,-1386 # ffffffffc0201c88 <etext+0xf2>
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
ffffffffc020020c:	0c850513          	addi	a0,a0,200 # ffffffffc02022d0 <etext+0x73a>
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
ffffffffc020021c:	0d50106f          	j	ffffffffc0201af0 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	a8650513          	addi	a0,a0,-1402 # ffffffffc0201ca8 <etext+0x112>
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
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	a6850513          	addi	a0,a0,-1432 # ffffffffc0201cb8 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	a6250513          	addi	a0,a0,-1438 # ffffffffc0201cc8 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0201ce0 <etext+0x14a>
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
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed93f9>
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
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	a0090913          	addi	s2,s2,-1536 # ffffffffc0201d30 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	9ea48493          	addi	s1,s1,-1558 # ffffffffc0201d28 <etext+0x192>
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
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	a1650513          	addi	a0,a0,-1514 # ffffffffc0201da8 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	a4250513          	addi	a0,a0,-1470 # ffffffffc0201de0 <etext+0x24a>
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
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	92250513          	addi	a0,a0,-1758 # ffffffffc0201d00 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	71e010ef          	jal	ra,ffffffffc0201b0a <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	764010ef          	jal	ra,ffffffffc0201b5e <strncmp>
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
ffffffffc0200490:	6b0010ef          	jal	ra,ffffffffc0201b40 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	89450513          	addi	a0,a0,-1900 # ffffffffc0201d38 <etext+0x1a2>
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
ffffffffc0200576:	7e650513          	addi	a0,a0,2022 # ffffffffc0201d58 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	7ec50513          	addi	a0,a0,2028 # ffffffffc0201d70 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0201d90 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	83e50513          	addi	a0,a0,-1986 # ffffffffc0201de0 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	4e87b723          	sd	s0,1262(a5) # ffffffffc0206a98 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	4f67b723          	sd	s6,1262(a5) # ffffffffc0206aa0 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	4dc53503          	ld	a0,1244(a0) # ffffffffc0206a98 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	4da53503          	ld	a0,1242(a0) # ffffffffc0206aa0 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
}

// 初始化 buddy system
static void
buddy_init(void) {
    buddy_longest = NULL;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	4c07bc23          	sd	zero,1240(a5) # ffffffffc0206aa8 <buddy_longest>
    buddy_size = 0;
ffffffffc02005d8:	00006797          	auipc	a5,0x6
ffffffffc02005dc:	4e07a023          	sw	zero,1248(a5) # ffffffffc0206ab8 <buddy_size>
    max_pages = 0;
    buddy_page_base = NULL;
ffffffffc02005e0:	00006797          	auipc	a5,0x6
ffffffffc02005e4:	4c07b823          	sd	zero,1232(a5) # ffffffffc0206ab0 <buddy_page_base>
}
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <buddy_nr_free_pages>:
/**
 * 返回空闲页面数
 */
static size_t
buddy_nr_free_pages(void) {
    return buddy_longest[0];  // 根节点的值就是最大可分配空间
ffffffffc02005ea:	00006797          	auipc	a5,0x6
ffffffffc02005ee:	4be7b783          	ld	a5,1214(a5) # ffffffffc0206aa8 <buddy_longest>
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
ffffffffc0200600:	00006797          	auipc	a5,0x6
ffffffffc0200604:	4b07b783          	ld	a5,1200(a5) # ffffffffc0206ab0 <buddy_page_base>
ffffffffc0200608:	0ef56963          	bltu	a0,a5,ffffffffc02006fa <buddy_free_pages+0x102>
ffffffffc020060c:	00006817          	auipc	a6,0x6
ffffffffc0200610:	4ac82803          	lw	a6,1196(a6) # ffffffffc0206ab8 <buddy_size>
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
ffffffffc0200652:	4ca7b783          	ld	a5,1226(a5) # ffffffffc0202b18 <error_string+0x38>
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
ffffffffc0200686:	00006517          	auipc	a0,0x6
ffffffffc020068a:	42253503          	ld	a0,1058(a0) # ffffffffc0206aa8 <buddy_longest>
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
ffffffffc02006fe:	73668693          	addi	a3,a3,1846 # ffffffffc0201e30 <etext+0x29a>
ffffffffc0200702:	00001617          	auipc	a2,0x1
ffffffffc0200706:	6fe60613          	addi	a2,a2,1790 # ffffffffc0201e00 <etext+0x26a>
ffffffffc020070a:	0b800593          	li	a1,184
ffffffffc020070e:	00001517          	auipc	a0,0x1
ffffffffc0200712:	70a50513          	addi	a0,a0,1802 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200716:	aadff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc020071a:	00001697          	auipc	a3,0x1
ffffffffc020071e:	6de68693          	addi	a3,a3,1758 # ffffffffc0201df8 <etext+0x262>
ffffffffc0200722:	00001617          	auipc	a2,0x1
ffffffffc0200726:	6de60613          	addi	a2,a2,1758 # ffffffffc0201e00 <etext+0x26a>
ffffffffc020072a:	0b700593          	li	a1,183
ffffffffc020072e:	00001517          	auipc	a0,0x1
ffffffffc0200732:	6ea50513          	addi	a0,a0,1770 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200736:	a8dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020073a <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc020073a:	10050c63          	beqz	a0,ffffffffc0200852 <buddy_alloc_pages+0x118>
    if (n > buddy_size) {
ffffffffc020073e:	00006897          	auipc	a7,0x6
ffffffffc0200742:	37a8a883          	lw	a7,890(a7) # ffffffffc0206ab8 <buddy_size>
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
ffffffffc0200768:	00006617          	auipc	a2,0x6
ffffffffc020076c:	34063603          	ld	a2,832(a2) # ffffffffc0206aa8 <buddy_longest>
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
ffffffffc0200818:	00006517          	auipc	a0,0x6
ffffffffc020081c:	29853503          	ld	a0,664(a0) # ffffffffc0206ab0 <buddy_page_base>
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
ffffffffc0200858:	5a468693          	addi	a3,a3,1444 # ffffffffc0201df8 <etext+0x262>
ffffffffc020085c:	00001617          	auipc	a2,0x1
ffffffffc0200860:	5a460613          	addi	a2,a2,1444 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200864:	07a00593          	li	a1,122
ffffffffc0200868:	00001517          	auipc	a0,0x1
ffffffffc020086c:	5b050513          	addi	a0,a0,1456 # ffffffffc0201e18 <etext+0x282>
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
ffffffffc020087c:	5f850513          	addi	a0,a0,1528 # ffffffffc0201e70 <etext+0x2da>
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
ffffffffc0200892:	60250513          	addi	a0,a0,1538 # ffffffffc0201e90 <etext+0x2fa>
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
ffffffffc02008e0:	67450513          	addi	a0,a0,1652 # ffffffffc0201f50 <etext+0x3ba>
ffffffffc02008e4:	869ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 2: 释放页面
    cprintf("Test 2: Freeing pages...\n");
ffffffffc02008e8:	00001517          	auipc	a0,0x1
ffffffffc02008ec:	67850513          	addi	a0,a0,1656 # ffffffffc0201f60 <etext+0x3ca>
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
ffffffffc0200910:	67450513          	addi	a0,a0,1652 # ffffffffc0201f80 <etext+0x3ea>
ffffffffc0200914:	839ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 3: 分配多个页面
    cprintf("Test 3: Allocating multiple pages...\n");
ffffffffc0200918:	00001517          	auipc	a0,0x1
ffffffffc020091c:	67850513          	addi	a0,a0,1656 # ffffffffc0201f90 <etext+0x3fa>
ffffffffc0200920:	82dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = alloc_pages(5);  // 实际分配 8 页
ffffffffc0200924:	4515                	li	a0,5
ffffffffc0200926:	470000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc020092a:	84aa                	mv	s1,a0
    assert(p0 != NULL);
ffffffffc020092c:	32050663          	beqz	a0,ffffffffc0200c58 <buddy_check+0x3e2>
    cprintf("Allocated 5 pages (actual: 8)\n");
ffffffffc0200930:	00001517          	auipc	a0,0x1
ffffffffc0200934:	68850513          	addi	a0,a0,1672 # ffffffffc0201fb8 <etext+0x422>
ffffffffc0200938:	815ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    p1 = alloc_pages(3);  // 实际分配 4 页
ffffffffc020093c:	450d                	li	a0,3
ffffffffc020093e:	458000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200942:	842a                	mv	s0,a0
    assert(p1 != NULL);
ffffffffc0200944:	28050a63          	beqz	a0,ffffffffc0200bd8 <buddy_check+0x362>
    cprintf("Allocated 3 pages (actual: 4)\n");
ffffffffc0200948:	00001517          	auipc	a0,0x1
ffffffffc020094c:	69050513          	addi	a0,a0,1680 # ffffffffc0201fd8 <etext+0x442>
ffffffffc0200950:	ffcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    assert(p0 != p1);
ffffffffc0200954:	32848263          	beq	s1,s0,ffffffffc0200c78 <buddy_check+0x402>
    cprintf("Test 3 Passed!\n");
ffffffffc0200958:	00001517          	auipc	a0,0x1
ffffffffc020095c:	6b050513          	addi	a0,a0,1712 # ffffffffc0202008 <etext+0x472>
ffffffffc0200960:	fecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 4: 释放并测试合并
    cprintf("Test 4: Testing merge...\n");
ffffffffc0200964:	00001517          	auipc	a0,0x1
ffffffffc0200968:	6b450513          	addi	a0,a0,1716 # ffffffffc0202018 <etext+0x482>
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
ffffffffc0200984:	6b850513          	addi	a0,a0,1720 # ffffffffc0202038 <etext+0x4a2>
ffffffffc0200988:	fc4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 5: 大块分配
    cprintf("Test 5: Large allocation...\n");
ffffffffc020098c:	00001517          	auipc	a0,0x1
ffffffffc0200990:	6bc50513          	addi	a0,a0,1724 # ffffffffc0202048 <etext+0x4b2>
ffffffffc0200994:	fb8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t free_before = nr_free_pages();
ffffffffc0200998:	416000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
    cprintf("Free pages before: %d\n", free_before);
ffffffffc020099c:	85aa                	mv	a1,a0
    size_t free_before = nr_free_pages();
ffffffffc020099e:	842a                	mv	s0,a0
    cprintf("Free pages before: %d\n", free_before);
ffffffffc02009a0:	00001517          	auipc	a0,0x1
ffffffffc02009a4:	6c850513          	addi	a0,a0,1736 # ffffffffc0202068 <etext+0x4d2>
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
ffffffffc02009c0:	6c450513          	addi	a0,a0,1732 # ffffffffc0202080 <etext+0x4ea>
ffffffffc02009c4:	f88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(p0, free_before / 2);
ffffffffc02009c8:	85ca                	mv	a1,s2
ffffffffc02009ca:	8526                	mv	a0,s1
ffffffffc02009cc:	3d6000ef          	jal	ra,ffffffffc0200da2 <free_pages>
        cprintf("Freed %d pages\n", free_before / 2);
ffffffffc02009d0:	85ca                	mv	a1,s2
ffffffffc02009d2:	00001517          	auipc	a0,0x1
ffffffffc02009d6:	6c650513          	addi	a0,a0,1734 # ffffffffc0202098 <etext+0x502>
ffffffffc02009da:	f72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    
    size_t free_after = nr_free_pages();
ffffffffc02009de:	3d0000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc02009e2:	84aa                	mv	s1,a0
    cprintf("Free pages after: %d\n", free_after);
ffffffffc02009e4:	85aa                	mv	a1,a0
ffffffffc02009e6:	00001517          	auipc	a0,0x1
ffffffffc02009ea:	6c250513          	addi	a0,a0,1730 # ffffffffc02020a8 <etext+0x512>
ffffffffc02009ee:	f5eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(free_before == free_after);
ffffffffc02009f2:	24941363          	bne	s0,s1,ffffffffc0200c38 <buddy_check+0x3c2>
    cprintf("Test 5 Passed!\n");
ffffffffc02009f6:	00001517          	auipc	a0,0x1
ffffffffc02009fa:	6ea50513          	addi	a0,a0,1770 # ffffffffc02020e0 <etext+0x54a>
ffffffffc02009fe:	f4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 6: 边界测试
    cprintf("Test 6: Boundary test...\n");
ffffffffc0200a02:	00001517          	auipc	a0,0x1
ffffffffc0200a06:	6ee50513          	addi	a0,a0,1774 # ffffffffc02020f0 <etext+0x55a>
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
ffffffffc0200a62:	6ca50513          	addi	a0,a0,1738 # ffffffffc0202128 <etext+0x592>
ffffffffc0200a66:	ee6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 7: 内存耗尽测试
    cprintf("Test 7: Exhaustion test...\n");
ffffffffc0200a6a:	00001517          	auipc	a0,0x1
ffffffffc0200a6e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0202138 <etext+0x5a2>
ffffffffc0200a72:	edaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t total_free = nr_free_pages();
ffffffffc0200a76:	338000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc0200a7a:	842a                	mv	s0,a0
    cprintf("Total free pages: %d\n", total_free);
ffffffffc0200a7c:	85aa                	mv	a1,a0
ffffffffc0200a7e:	00001517          	auipc	a0,0x1
ffffffffc0200a82:	6da50513          	addi	a0,a0,1754 # ffffffffc0202158 <etext+0x5c2>
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
ffffffffc0200a8c:	00002517          	auipc	a0,0x2
ffffffffc0200a90:	84c50513          	addi	a0,a0,-1972 # ffffffffc02022d8 <etext+0x742>
ffffffffc0200a94:	eb8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    cprintf("Buddy System Check Passed!\n");
}
ffffffffc0200a98:	7402                	ld	s0,32(sp)
ffffffffc0200a9a:	70a2                	ld	ra,40(sp)
ffffffffc0200a9c:	64e2                	ld	s1,24(sp)
ffffffffc0200a9e:	6942                	ld	s2,16(sp)
ffffffffc0200aa0:	69a2                	ld	s3,8(sp)
    cprintf("Buddy System Check Passed!\n");
ffffffffc0200aa2:	00002517          	auipc	a0,0x2
ffffffffc0200aa6:	84650513          	addi	a0,a0,-1978 # ffffffffc02022e8 <etext+0x752>
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
ffffffffc0200ac0:	6b450513          	addi	a0,a0,1716 # ffffffffc0202170 <etext+0x5da>
ffffffffc0200ac4:	e88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            struct Page *p_extra = alloc_page();
ffffffffc0200ac8:	4505                	li	a0,1
ffffffffc0200aca:	2cc000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200ace:	892a                	mv	s2,a0
            if (p_extra == NULL) {
ffffffffc0200ad0:	cd39                	beqz	a0,ffffffffc0200b2e <buddy_check+0x2b8>
                cprintf("Warning: Still can allocate (might have fragmentation)\n");
ffffffffc0200ad2:	00001517          	auipc	a0,0x1
ffffffffc0200ad6:	6e650513          	addi	a0,a0,1766 # ffffffffc02021b8 <etext+0x622>
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
ffffffffc0200af4:	70050513          	addi	a0,a0,1792 # ffffffffc02021f0 <etext+0x65a>
ffffffffc0200af8:	e54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            size_t free_after = nr_free_pages();
ffffffffc0200afc:	2b2000ef          	jal	ra,ffffffffc0200dae <nr_free_pages>
ffffffffc0200b00:	85aa                	mv	a1,a0
            cprintf("Free pages after release: %d\n", free_after);
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	70650513          	addi	a0,a0,1798 # ffffffffc0202208 <etext+0x672>
ffffffffc0200b0a:	e42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            p_extra = alloc_page();
ffffffffc0200b0e:	4505                	li	a0,1
ffffffffc0200b10:	286000ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0200b14:	842a                	mv	s0,a0
            if (p_extra != NULL) {
ffffffffc0200b16:	c915                	beqz	a0,ffffffffc0200b4a <buddy_check+0x2d4>
                cprintf("Can allocate after freeing - Correct!\n");
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	71050513          	addi	a0,a0,1808 # ffffffffc0202228 <etext+0x692>
ffffffffc0200b20:	e2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
                free_page(p_extra);
ffffffffc0200b24:	4585                	li	a1,1
ffffffffc0200b26:	8522                	mv	a0,s0
ffffffffc0200b28:	27a000ef          	jal	ra,ffffffffc0200da2 <free_pages>
ffffffffc0200b2c:	b785                	j	ffffffffc0200a8c <buddy_check+0x216>
                cprintf("Cannot allocate when memory is full - Correct!\n");
ffffffffc0200b2e:	00001517          	auipc	a0,0x1
ffffffffc0200b32:	65a50513          	addi	a0,a0,1626 # ffffffffc0202188 <etext+0x5f2>
ffffffffc0200b36:	e16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b3a:	b775                	j	ffffffffc0200ae6 <buddy_check+0x270>
            cprintf("Cannot allocate %d pages in one block (this is expected)\n", total_free);
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	75c50513          	addi	a0,a0,1884 # ffffffffc0202298 <etext+0x702>
ffffffffc0200b44:	e08ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b48:	b791                	j	ffffffffc0200a8c <buddy_check+0x216>
                cprintf("Note: Cannot allocate single page, this might be due to alignment\n");
ffffffffc0200b4a:	00001517          	auipc	a0,0x1
ffffffffc0200b4e:	70650513          	addi	a0,a0,1798 # ffffffffc0202250 <etext+0x6ba>
ffffffffc0200b52:	dfaff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200b56:	bf1d                	j	ffffffffc0200a8c <buddy_check+0x216>
    assert(p0 && p1 && p2 && p3);
ffffffffc0200b58:	00001697          	auipc	a3,0x1
ffffffffc0200b5c:	5b868693          	addi	a3,a3,1464 # ffffffffc0202110 <etext+0x57a>
ffffffffc0200b60:	00001617          	auipc	a2,0x1
ffffffffc0200b64:	2a060613          	addi	a2,a2,672 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200b68:	13400593          	li	a1,308
ffffffffc0200b6c:	00001517          	auipc	a0,0x1
ffffffffc0200b70:	2ac50513          	addi	a0,a0,684 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200b74:	e4eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b78:	00001697          	auipc	a3,0x1
ffffffffc0200b7c:	37068693          	addi	a3,a3,880 # ffffffffc0201ee8 <etext+0x352>
ffffffffc0200b80:	00001617          	auipc	a2,0x1
ffffffffc0200b84:	28060613          	addi	a2,a2,640 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200b88:	0fd00593          	li	a1,253
ffffffffc0200b8c:	00001517          	auipc	a0,0x1
ffffffffc0200b90:	28c50513          	addi	a0,a0,652 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200b94:	e2eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b98:	00001697          	auipc	a3,0x1
ffffffffc0200b9c:	37868693          	addi	a3,a3,888 # ffffffffc0201f10 <etext+0x37a>
ffffffffc0200ba0:	00001617          	auipc	a2,0x1
ffffffffc0200ba4:	26060613          	addi	a2,a2,608 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200ba8:	0fe00593          	li	a1,254
ffffffffc0200bac:	00001517          	auipc	a0,0x1
ffffffffc0200bb0:	26c50513          	addi	a0,a0,620 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200bb4:	e0eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0200bb8:	00001697          	auipc	a3,0x1
ffffffffc0200bbc:	31068693          	addi	a3,a3,784 # ffffffffc0201ec8 <etext+0x332>
ffffffffc0200bc0:	00001617          	auipc	a2,0x1
ffffffffc0200bc4:	24060613          	addi	a2,a2,576 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200bc8:	0f900593          	li	a1,249
ffffffffc0200bcc:	00001517          	auipc	a0,0x1
ffffffffc0200bd0:	24c50513          	addi	a0,a0,588 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200bd4:	deeff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0200bd8:	00001697          	auipc	a3,0x1
ffffffffc0200bdc:	2f068693          	addi	a3,a3,752 # ffffffffc0201ec8 <etext+0x332>
ffffffffc0200be0:	00001617          	auipc	a2,0x1
ffffffffc0200be4:	22060613          	addi	a2,a2,544 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200be8:	11000593          	li	a1,272
ffffffffc0200bec:	00001517          	auipc	a0,0x1
ffffffffc0200bf0:	22c50513          	addi	a0,a0,556 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200bf4:	dceff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc0200bf8:	00001697          	auipc	a3,0x1
ffffffffc0200bfc:	2e068693          	addi	a3,a3,736 # ffffffffc0201ed8 <etext+0x342>
ffffffffc0200c00:	00001617          	auipc	a2,0x1
ffffffffc0200c04:	20060613          	addi	a2,a2,512 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200c08:	0fb00593          	li	a1,251
ffffffffc0200c0c:	00001517          	auipc	a0,0x1
ffffffffc0200c10:	20c50513          	addi	a0,a0,524 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200c14:	daeff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200c18:	00001697          	auipc	a3,0x1
ffffffffc0200c1c:	2a068693          	addi	a3,a3,672 # ffffffffc0201eb8 <etext+0x322>
ffffffffc0200c20:	00001617          	auipc	a2,0x1
ffffffffc0200c24:	1e060613          	addi	a2,a2,480 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200c28:	0f700593          	li	a1,247
ffffffffc0200c2c:	00001517          	auipc	a0,0x1
ffffffffc0200c30:	1ec50513          	addi	a0,a0,492 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200c34:	d8eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_before == free_after);
ffffffffc0200c38:	00001697          	auipc	a3,0x1
ffffffffc0200c3c:	48868693          	addi	a3,a3,1160 # ffffffffc02020c0 <etext+0x52a>
ffffffffc0200c40:	00001617          	auipc	a2,0x1
ffffffffc0200c44:	1c060613          	addi	a2,a2,448 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200c48:	12a00593          	li	a1,298
ffffffffc0200c4c:	00001517          	auipc	a0,0x1
ffffffffc0200c50:	1cc50513          	addi	a0,a0,460 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200c54:	d6eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200c58:	00001697          	auipc	a3,0x1
ffffffffc0200c5c:	26068693          	addi	a3,a3,608 # ffffffffc0201eb8 <etext+0x322>
ffffffffc0200c60:	00001617          	auipc	a2,0x1
ffffffffc0200c64:	1a060613          	addi	a2,a2,416 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200c68:	10c00593          	li	a1,268
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	1ac50513          	addi	a0,a0,428 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200c74:	d4eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1);
ffffffffc0200c78:	00001697          	auipc	a3,0x1
ffffffffc0200c7c:	38068693          	addi	a3,a3,896 # ffffffffc0201ff8 <etext+0x462>
ffffffffc0200c80:	00001617          	auipc	a2,0x1
ffffffffc0200c84:	18060613          	addi	a2,a2,384 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200c88:	11300593          	li	a1,275
ffffffffc0200c8c:	00001517          	auipc	a0,0x1
ffffffffc0200c90:	18c50513          	addi	a0,a0,396 # ffffffffc0201e18 <etext+0x282>
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
ffffffffc0200cbe:	00006697          	auipc	a3,0x6
ffffffffc0200cc2:	e0a6b683          	ld	a3,-502(a3) # ffffffffc0206ac8 <pages>
ffffffffc0200cc6:	40d506b3          	sub	a3,a0,a3
ffffffffc0200cca:	00002797          	auipc	a5,0x2
ffffffffc0200cce:	e4e7b783          	ld	a5,-434(a5) # ffffffffc0202b18 <error_string+0x38>
ffffffffc0200cd2:	868d                	srai	a3,a3,0x3
ffffffffc0200cd4:	02f686b3          	mul	a3,a3,a5
    buddy_size = real_size;
ffffffffc0200cd8:	00006797          	auipc	a5,0x6
ffffffffc0200cdc:	dec7a023          	sw	a2,-544(a5) # ffffffffc0206ab8 <buddy_size>
    buddy_page_base = base;
ffffffffc0200ce0:	00006797          	auipc	a5,0x6
ffffffffc0200ce4:	dca7b823          	sd	a0,-560(a5) # ffffffffc0206ab0 <buddy_page_base>
ffffffffc0200ce8:	00002797          	auipc	a5,0x2
ffffffffc0200cec:	e387b783          	ld	a5,-456(a5) # ffffffffc0202b20 <nbase>
    for (; p != base + n; p++) {
ffffffffc0200cf0:	00259713          	slli	a4,a1,0x2
ffffffffc0200cf4:	972e                	add	a4,a4,a1
ffffffffc0200cf6:	070e                	slli	a4,a4,0x3
ffffffffc0200cf8:	972a                	add	a4,a4,a0
ffffffffc0200cfa:	96be                	add	a3,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cfc:	06b2                	slli	a3,a3,0xc
    buddy_longest = (unsigned int *)(page2pa(base) + va_pa_offset);
ffffffffc0200cfe:	00006797          	auipc	a5,0x6
ffffffffc0200d02:	dea7b783          	ld	a5,-534(a5) # ffffffffc0206ae8 <va_pa_offset>
ffffffffc0200d06:	96be                	add	a3,a3,a5
ffffffffc0200d08:	00006797          	auipc	a5,0x6
ffffffffc0200d0c:	dad7b023          	sd	a3,-608(a5) # ffffffffc0206aa8 <buddy_longest>
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
ffffffffc0200d4c:	5d050513          	addi	a0,a0,1488 # ffffffffc0202318 <etext+0x782>
}
ffffffffc0200d50:	0141                	addi	sp,sp,16
    cprintf("Buddy System: initialized %d pages (actual: %d)\n", n, buddy_size);
ffffffffc0200d52:	bfaff06f          	j	ffffffffc020014c <cprintf>
        assert(PageReserved(p));
ffffffffc0200d56:	00001697          	auipc	a3,0x1
ffffffffc0200d5a:	5b268693          	addi	a3,a3,1458 # ffffffffc0202308 <etext+0x772>
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	0a260613          	addi	a2,a2,162 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200d66:	06100593          	li	a1,97
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	0ae50513          	addi	a0,a0,174 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200d72:	c50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200d76:	00001697          	auipc	a3,0x1
ffffffffc0200d7a:	08268693          	addi	a3,a3,130 # ffffffffc0201df8 <etext+0x262>
ffffffffc0200d7e:	00001617          	auipc	a2,0x1
ffffffffc0200d82:	08260613          	addi	a2,a2,130 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0200d86:	04400593          	li	a1,68
ffffffffc0200d8a:	00001517          	auipc	a0,0x1
ffffffffc0200d8e:	08e50513          	addi	a0,a0,142 # ffffffffc0201e18 <etext+0x282>
ffffffffc0200d92:	c30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d96 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200d96:	00006797          	auipc	a5,0x6
ffffffffc0200d9a:	d3a7b783          	ld	a5,-710(a5) # ffffffffc0206ad0 <pmm_manager>
ffffffffc0200d9e:	6f9c                	ld	a5,24(a5)
ffffffffc0200da0:	8782                	jr	a5

ffffffffc0200da2 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200da2:	00006797          	auipc	a5,0x6
ffffffffc0200da6:	d2e7b783          	ld	a5,-722(a5) # ffffffffc0206ad0 <pmm_manager>
ffffffffc0200daa:	739c                	ld	a5,32(a5)
ffffffffc0200dac:	8782                	jr	a5

ffffffffc0200dae <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200dae:	00006797          	auipc	a5,0x6
ffffffffc0200db2:	d227b783          	ld	a5,-734(a5) # ffffffffc0206ad0 <pmm_manager>
ffffffffc0200db6:	779c                	ld	a5,40(a5)
ffffffffc0200db8:	8782                	jr	a5

ffffffffc0200dba <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dba:	00001797          	auipc	a5,0x1
ffffffffc0200dbe:	5ae78793          	addi	a5,a5,1454 # ffffffffc0202368 <buddy_pmm_manager>
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
ffffffffc0200dcc:	5d850513          	addi	a0,a0,1496 # ffffffffc02023a0 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dd0:	00006417          	auipc	s0,0x6
ffffffffc0200dd4:	d0040413          	addi	s0,s0,-768 # ffffffffc0206ad0 <pmm_manager>
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
ffffffffc0200dea:	00006497          	auipc	s1,0x6
ffffffffc0200dee:	cfe48493          	addi	s1,s1,-770 # ffffffffc0206ae8 <va_pa_offset>
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
ffffffffc0200e06:	18050963          	beqz	a0,ffffffffc0200f98 <pmm_init+0x1de>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e0a:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200e0c:	00001517          	auipc	a0,0x1
ffffffffc0200e10:	5dc50513          	addi	a0,a0,1500 # ffffffffc02023e8 <buddy_pmm_manager+0x80>
ffffffffc0200e14:	b38ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e18:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e1c:	864e                	mv	a2,s3
ffffffffc0200e1e:	fffa0693          	addi	a3,s4,-1
ffffffffc0200e22:	85ca                	mv	a1,s2
ffffffffc0200e24:	00001517          	auipc	a0,0x1
ffffffffc0200e28:	5dc50513          	addi	a0,a0,1500 # ffffffffc0202400 <buddy_pmm_manager+0x98>
ffffffffc0200e2c:	b20ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e30:	c80007b7          	lui	a5,0xc8000
ffffffffc0200e34:	8652                	mv	a2,s4
ffffffffc0200e36:	1147e063          	bltu	a5,s4,ffffffffc0200f36 <pmm_init+0x17c>
ffffffffc0200e3a:	00007797          	auipc	a5,0x7
ffffffffc0200e3e:	cb978793          	addi	a5,a5,-839 # ffffffffc0207af3 <end+0xfff>
ffffffffc0200e42:	757d                	lui	a0,0xfffff
ffffffffc0200e44:	8d7d                	and	a0,a0,a5
ffffffffc0200e46:	8231                	srli	a2,a2,0xc
ffffffffc0200e48:	00006797          	auipc	a5,0x6
ffffffffc0200e4c:	c6c7bc23          	sd	a2,-904(a5) # ffffffffc0206ac0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e50:	00006797          	auipc	a5,0x6
ffffffffc0200e54:	c6a7bc23          	sd	a0,-904(a5) # ffffffffc0206ac8 <pages>
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
ffffffffc0200e7a:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9534>
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
ffffffffc0200e9a:	0ef6e363          	bltu	a3,a5,ffffffffc0200f80 <pmm_init+0x1c6>
ffffffffc0200e9e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200ea0:	77fd                	lui	a5,0xfffff
ffffffffc0200ea2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ea6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200ea8:	08b6ea63          	bltu	a3,a1,ffffffffc0200f3c <pmm_init+0x182>
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
ffffffffc0200eb6:	5d650513          	addi	a0,a0,1494 # ffffffffc0202488 <buddy_pmm_manager+0x120>
ffffffffc0200eba:	a92ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initializing SLUB allocator...\n");
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	5ea50513          	addi	a0,a0,1514 # ffffffffc02024a8 <buddy_pmm_manager+0x140>
ffffffffc0200ec6:	a86ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_init();
ffffffffc0200eca:	492000ef          	jal	ra,ffffffffc020135c <slub_init>
    cprintf("SLUB allocator initialized!\n");
ffffffffc0200ece:	00001517          	auipc	a0,0x1
ffffffffc0200ed2:	5fa50513          	addi	a0,a0,1530 # ffffffffc02024c8 <buddy_pmm_manager+0x160>
ffffffffc0200ed6:	a76ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Checking SLUB allocator...\n");
ffffffffc0200eda:	00001517          	auipc	a0,0x1
ffffffffc0200ede:	60e50513          	addi	a0,a0,1550 # ffffffffc02024e8 <buddy_pmm_manager+0x180>
ffffffffc0200ee2:	a6aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_check();
ffffffffc0200ee6:	550000ef          	jal	ra,ffffffffc0201436 <slub_check>
    cprintf("SLUB allocator check passed!\n");
ffffffffc0200eea:	00001517          	auipc	a0,0x1
ffffffffc0200eee:	61e50513          	addi	a0,a0,1566 # ffffffffc0202508 <buddy_pmm_manager+0x1a0>
ffffffffc0200ef2:	a5aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200ef6:	00004597          	auipc	a1,0x4
ffffffffc0200efa:	10a58593          	addi	a1,a1,266 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200efe:	00006797          	auipc	a5,0x6
ffffffffc0200f02:	beb7b123          	sd	a1,-1054(a5) # ffffffffc0206ae0 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f06:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f0a:	0af5e363          	bltu	a1,a5,ffffffffc0200fb0 <pmm_init+0x1f6>
ffffffffc0200f0e:	6090                	ld	a2,0(s1)
}
ffffffffc0200f10:	7402                	ld	s0,32(sp)
ffffffffc0200f12:	70a2                	ld	ra,40(sp)
ffffffffc0200f14:	64e2                	ld	s1,24(sp)
ffffffffc0200f16:	6942                	ld	s2,16(sp)
ffffffffc0200f18:	69a2                	ld	s3,8(sp)
ffffffffc0200f1a:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f1c:	40c58633          	sub	a2,a1,a2
ffffffffc0200f20:	00006797          	auipc	a5,0x6
ffffffffc0200f24:	bac7bc23          	sd	a2,-1096(a5) # ffffffffc0206ad8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200f28:	00001517          	auipc	a0,0x1
ffffffffc0200f2c:	60050513          	addi	a0,a0,1536 # ffffffffc0202528 <buddy_pmm_manager+0x1c0>
}
ffffffffc0200f30:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200f32:	a1aff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200f36:	c8000637          	lui	a2,0xc8000
ffffffffc0200f3a:	b701                	j	ffffffffc0200e3a <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200f3c:	6705                	lui	a4,0x1
ffffffffc0200f3e:	177d                	addi	a4,a4,-1
ffffffffc0200f40:	96ba                	add	a3,a3,a4
ffffffffc0200f42:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200f44:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f48:	02c7f063          	bgeu	a5,a2,ffffffffc0200f68 <pmm_init+0x1ae>
    pmm_manager->init_memmap(base, n);
ffffffffc0200f4c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200f4e:	fff80737          	lui	a4,0xfff80
ffffffffc0200f52:	973e                	add	a4,a4,a5
ffffffffc0200f54:	00271793          	slli	a5,a4,0x2
ffffffffc0200f58:	97ba                	add	a5,a5,a4
ffffffffc0200f5a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200f5c:	8d95                	sub	a1,a1,a3
ffffffffc0200f5e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200f60:	81b1                	srli	a1,a1,0xc
ffffffffc0200f62:	953e                	add	a0,a0,a5
ffffffffc0200f64:	9702                	jalr	a4
}
ffffffffc0200f66:	b799                	j	ffffffffc0200eac <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200f68:	00001617          	auipc	a2,0x1
ffffffffc0200f6c:	4f060613          	addi	a2,a2,1264 # ffffffffc0202458 <buddy_pmm_manager+0xf0>
ffffffffc0200f70:	06a00593          	li	a1,106
ffffffffc0200f74:	00001517          	auipc	a0,0x1
ffffffffc0200f78:	50450513          	addi	a0,a0,1284 # ffffffffc0202478 <buddy_pmm_manager+0x110>
ffffffffc0200f7c:	a46ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f80:	00001617          	auipc	a2,0x1
ffffffffc0200f84:	4b060613          	addi	a2,a2,1200 # ffffffffc0202430 <buddy_pmm_manager+0xc8>
ffffffffc0200f88:	06200593          	li	a1,98
ffffffffc0200f8c:	00001517          	auipc	a0,0x1
ffffffffc0200f90:	44c50513          	addi	a0,a0,1100 # ffffffffc02023d8 <buddy_pmm_manager+0x70>
ffffffffc0200f94:	a2eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200f98:	00001617          	auipc	a2,0x1
ffffffffc0200f9c:	42060613          	addi	a2,a2,1056 # ffffffffc02023b8 <buddy_pmm_manager+0x50>
ffffffffc0200fa0:	04a00593          	li	a1,74
ffffffffc0200fa4:	00001517          	auipc	a0,0x1
ffffffffc0200fa8:	43450513          	addi	a0,a0,1076 # ffffffffc02023d8 <buddy_pmm_manager+0x70>
ffffffffc0200fac:	a16ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200fb0:	86ae                	mv	a3,a1
ffffffffc0200fb2:	00001617          	auipc	a2,0x1
ffffffffc0200fb6:	47e60613          	addi	a2,a2,1150 # ffffffffc0202430 <buddy_pmm_manager+0xc8>
ffffffffc0200fba:	08700593          	li	a1,135
ffffffffc0200fbe:	00001517          	auipc	a0,0x1
ffffffffc0200fc2:	41a50513          	addi	a0,a0,1050 # ffffffffc02023d8 <buddy_pmm_manager+0x70>
ffffffffc0200fc6:	9fcff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200fca <kmem_cache_alloc.part.0>:
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc0200fca:	613c                	ld	a5,64(a0)
}

/**
 * 从缓存中分配对象
 */
void *kmem_cache_alloc(struct kmem_cache *cache) {
ffffffffc0200fcc:	1101                	addi	sp,sp,-32
ffffffffc0200fce:	e822                	sd	s0,16(sp)
ffffffffc0200fd0:	e426                	sd	s1,8(sp)
ffffffffc0200fd2:	ec06                	sd	ra,24(sp)
        cache->alloc_count++;
        return obj;
    }
    
    // 2. 尝试从partial链表获取slab
    if (!list_empty(&cache->partial)) {
ffffffffc0200fd4:	03850493          	addi	s1,a0,56
void *kmem_cache_alloc(struct kmem_cache *cache) {
ffffffffc0200fd8:	842a                	mv	s0,a0
    if (!list_empty(&cache->partial)) {
ffffffffc0200fda:	02f48663          	beq	s1,a5,ffffffffc0201006 <kmem_cache_alloc.part.0+0x3c>
        list_entry_t *le = list_next(&cache->partial);
        struct Page *page = le2page(le, page_link);
        struct slab_page *sp = (struct slab_page *)page;
        
        // 从slab分配对象
        if (sp->freelist != NULL) {
ffffffffc0200fde:	fe87b503          	ld	a0,-24(a5)
ffffffffc0200fe2:	c115                	beqz	a0,ffffffffc0201006 <kmem_cache_alloc.part.0+0x3c>
            obj = sp->freelist;
            sp->freelist = *(void **)obj;
            sp->inuse++;
ffffffffc0200fe4:	ff07a703          	lw	a4,-16(a5)
            sp->freelist = *(void **)obj;
ffffffffc0200fe8:	6114                	ld	a3,0(a0)
            sp->inuse++;
ffffffffc0200fea:	2705                	addiw	a4,a4,1
            sp->freelist = *(void **)obj;
ffffffffc0200fec:	fed7b423          	sd	a3,-24(a5)
            sp->inuse++;
ffffffffc0200ff0:	fee7a823          	sw	a4,-16(a5)
            
            // 如果slab满了，从partial移除
            if (sp->freelist == NULL) {
ffffffffc0200ff4:	cedd                	beqz	a3,ffffffffc02010b2 <kmem_cache_alloc.part.0+0xe8>
                list_del(&page->page_link);
                cache->nr_partial--;
            }
            
            cache->alloc_count++;
ffffffffc0200ff6:	703c                	ld	a5,96(s0)
ffffffffc0200ff8:	0785                	addi	a5,a5,1
ffffffffc0200ffa:	f03c                	sd	a5,96(s0)
    list_add(&cache->partial, &new_page->page_link);
    cache->nr_partial++;
    
    cache->alloc_count++;
    return obj;
}
ffffffffc0200ffc:	60e2                	ld	ra,24(sp)
ffffffffc0200ffe:	6442                	ld	s0,16(sp)
ffffffffc0201000:	64a2                	ld	s1,8(sp)
ffffffffc0201002:	6105                	addi	sp,sp,32
ffffffffc0201004:	8082                	ret
    struct Page *page = alloc_pages(1 << cache->order);
ffffffffc0201006:	581c                	lw	a5,48(s0)
ffffffffc0201008:	4505                	li	a0,1
ffffffffc020100a:	00f5153b          	sllw	a0,a0,a5
ffffffffc020100e:	d89ff0ef          	jal	ra,ffffffffc0200d96 <alloc_pages>
ffffffffc0201012:	86aa                	mv	a3,a0
    if (page == NULL) {
ffffffffc0201014:	cd49                	beqz	a0,ffffffffc02010ae <kmem_cache_alloc.part.0+0xe4>
    size_t slab_size = PGSIZE << cache->order;
ffffffffc0201016:	5818                	lw	a4,48(s0)
    size_t objects = slab_size / cache->size;
ffffffffc0201018:	640c                	ld	a1,8(s0)
    size_t slab_size = PGSIZE << cache->order;
ffffffffc020101a:	6785                	lui	a5,0x1
ffffffffc020101c:	00e797bb          	sllw	a5,a5,a4
    size_t objects = slab_size / cache->size;
ffffffffc0201020:	02b7d7b3          	divu	a5,a5,a1
    SetPageProperty(page);
ffffffffc0201024:	6690                	ld	a2,8(a3)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201026:	00006717          	auipc	a4,0x6
ffffffffc020102a:	aa273703          	ld	a4,-1374(a4) # ffffffffc0206ac8 <pages>
ffffffffc020102e:	40e68733          	sub	a4,a3,a4
ffffffffc0201032:	870d                	srai	a4,a4,0x3
ffffffffc0201034:	00266893          	ori	a7,a2,2
ffffffffc0201038:	00002617          	auipc	a2,0x2
ffffffffc020103c:	ae063603          	ld	a2,-1312(a2) # ffffffffc0202b18 <error_string+0x38>
ffffffffc0201040:	02c70733          	mul	a4,a4,a2
ffffffffc0201044:	00002617          	auipc	a2,0x2
ffffffffc0201048:	adc63603          	ld	a2,-1316(a2) # ffffffffc0202b20 <nbase>
    for (int i = objects - 1; i >= 0; i--) {
ffffffffc020104c:	37fd                	addiw	a5,a5,-1
ffffffffc020104e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201050:	0732                	slli	a4,a4,0xc
    void *slab_addr = (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201052:	00006617          	auipc	a2,0x6
ffffffffc0201056:	a9663603          	ld	a2,-1386(a2) # ffffffffc0206ae8 <va_pa_offset>
ffffffffc020105a:	963a                	add	a2,a2,a4
    for (int i = objects - 1; i >= 0; i--) {
ffffffffc020105c:	0607c363          	bltz	a5,ffffffffc02010c2 <kmem_cache_alloc.part.0+0xf8>
ffffffffc0201060:	02b78733          	mul	a4,a5,a1
    void *freelist = NULL;
ffffffffc0201064:	4501                	li	a0,0
    for (int i = objects - 1; i >= 0; i--) {
ffffffffc0201066:	587d                	li	a6,-1
ffffffffc0201068:	9732                	add	a4,a4,a2
        *(void **)obj = freelist;
ffffffffc020106a:	e308                	sd	a0,0(a4)
    for (int i = objects - 1; i >= 0; i--) {
ffffffffc020106c:	37fd                	addiw	a5,a5,-1
        void *obj = slab_addr + i * cache->size;
ffffffffc020106e:	853a                	mv	a0,a4
    for (int i = objects - 1; i >= 0; i--) {
ffffffffc0201070:	8f0d                	sub	a4,a4,a1
ffffffffc0201072:	ff079ce3          	bne	a5,a6,ffffffffc020106a <kmem_cache_alloc.part.0+0xa0>
    sp->freelist = freelist;
ffffffffc0201076:	e288                	sd	a0,0(a3)
    sp->cache = cache;
ffffffffc0201078:	ea80                	sd	s0,16(a3)
    sp->freelist = *(void **)obj;
ffffffffc020107a:	611c                	ld	a5,0(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc020107c:	6030                	ld	a2,64(s0)
    SetPageProperty(page);
ffffffffc020107e:	0116b423          	sd	a7,8(a3) # fffffffffec00008 <end+0x3e9f9514>
    sp->inuse++;
ffffffffc0201082:	4705                	li	a4,1
    sp->freelist = *(void **)obj;
ffffffffc0201084:	e29c                	sd	a5,0(a3)
    sp->inuse++;
ffffffffc0201086:	c698                	sw	a4,8(a3)
    cache->freelist = sp->freelist;
ffffffffc0201088:	e83c                	sd	a5,80(s0)
    cache->nr_partial++;
ffffffffc020108a:	6438                	ld	a4,72(s0)
    cache->alloc_count++;
ffffffffc020108c:	703c                	ld	a5,96(s0)
    cache->page = new_page;
ffffffffc020108e:	ec34                	sd	a3,88(s0)
    list_add(&cache->partial, &new_page->page_link);
ffffffffc0201090:	01868593          	addi	a1,a3,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201094:	e20c                	sd	a1,0(a2)
ffffffffc0201096:	e02c                	sd	a1,64(s0)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201098:	ee84                	sd	s1,24(a3)
    elm->next = next;
ffffffffc020109a:	f290                	sd	a2,32(a3)
    cache->nr_partial++;
ffffffffc020109c:	0705                	addi	a4,a4,1
    cache->alloc_count++;
ffffffffc020109e:	0785                	addi	a5,a5,1
}
ffffffffc02010a0:	60e2                	ld	ra,24(sp)
    cache->nr_partial++;
ffffffffc02010a2:	e438                	sd	a4,72(s0)
    cache->alloc_count++;
ffffffffc02010a4:	f03c                	sd	a5,96(s0)
}
ffffffffc02010a6:	6442                	ld	s0,16(sp)
ffffffffc02010a8:	64a2                	ld	s1,8(sp)
ffffffffc02010aa:	6105                	addi	sp,sp,32
ffffffffc02010ac:	8082                	ret
        return NULL;
ffffffffc02010ae:	4501                	li	a0,0
ffffffffc02010b0:	b7b1                	j	ffffffffc0200ffc <kmem_cache_alloc.part.0+0x32>
    __list_del(listelm->prev, listelm->next);
ffffffffc02010b2:	6394                	ld	a3,0(a5)
ffffffffc02010b4:	6798                	ld	a4,8(a5)
                cache->nr_partial--;
ffffffffc02010b6:	643c                	ld	a5,72(s0)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02010b8:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02010ba:	e314                	sd	a3,0(a4)
ffffffffc02010bc:	17fd                	addi	a5,a5,-1
ffffffffc02010be:	e43c                	sd	a5,72(s0)
ffffffffc02010c0:	bf1d                	j	ffffffffc0200ff6 <kmem_cache_alloc.part.0+0x2c>
    SetPageProperty(page);
ffffffffc02010c2:	0116b423          	sd	a7,8(a3)
    sp->freelist = freelist;
ffffffffc02010c6:	0006b023          	sd	zero,0(a3)
    sp->cache = cache;
ffffffffc02010ca:	ea80                	sd	s0,16(a3)
    sp->freelist = *(void **)obj;
ffffffffc02010cc:	00003783          	ld	a5,0(zero) # 0 <kern_entry-0xffffffffc0200000>
    sp->inuse = 0;
ffffffffc02010d0:	0006a423          	sw	zero,8(a3)
    sp->freelist = *(void **)obj;
ffffffffc02010d4:	9002                	ebreak

ffffffffc02010d6 <kmem_cache_create>:
                                     size_t align, unsigned long flags) {
ffffffffc02010d6:	715d                	addi	sp,sp,-80
ffffffffc02010d8:	e0a2                	sd	s0,64(sp)
ffffffffc02010da:	e486                	sd	ra,72(sp)
ffffffffc02010dc:	fc26                	sd	s1,56(sp)
ffffffffc02010de:	f84a                	sd	s2,48(sp)
ffffffffc02010e0:	f44e                	sd	s3,40(sp)
ffffffffc02010e2:	f052                	sd	s4,32(sp)
ffffffffc02010e4:	ec56                	sd	s5,24(sp)
ffffffffc02010e6:	e85a                	sd	s6,16(sp)
ffffffffc02010e8:	e45e                	sd	s7,8(sp)
    if (size == 0 || size > MAX_OBJ_SIZE) {
ffffffffc02010ea:	fff58413          	addi	s0,a1,-1
ffffffffc02010ee:	6785                	lui	a5,0x1
ffffffffc02010f0:	12f47563          	bgeu	s0,a5,ffffffffc020121a <kmem_cache_create+0x144>
    if (cache_count >= 20) {
ffffffffc02010f4:	00006717          	auipc	a4,0x6
ffffffffc02010f8:	9fc70713          	addi	a4,a4,-1540 # ffffffffc0206af0 <cache_count.1>
ffffffffc02010fc:	431c                	lw	a5,0(a4)
ffffffffc02010fe:	8bb6                	mv	s7,a3
ffffffffc0201100:	46cd                	li	a3,19
        return NULL;
ffffffffc0201102:	4a81                	li	s5,0
    if (cache_count >= 20) {
ffffffffc0201104:	0ef6c963          	blt	a3,a5,ffffffffc02011f6 <kmem_cache_create+0x120>
ffffffffc0201108:	00779993          	slli	s3,a5,0x7
    struct kmem_cache *cache = &cache_pool[cache_count++];
ffffffffc020110c:	00005917          	auipc	s2,0x5
ffffffffc0201110:	f0c90913          	addi	s2,s2,-244 # ffffffffc0206018 <cache_pool.0>
ffffffffc0201114:	01390ab3          	add	s5,s2,s3
ffffffffc0201118:	8a2e                	mv	s4,a1
ffffffffc020111a:	8b2a                	mv	s6,a0
ffffffffc020111c:	84b2                	mv	s1,a2
ffffffffc020111e:	2785                	addiw	a5,a5,1
    memset(cache, 0, sizeof(struct kmem_cache));
ffffffffc0201120:	08000613          	li	a2,128
ffffffffc0201124:	4581                	li	a1,0
ffffffffc0201126:	8556                	mv	a0,s5
    struct kmem_cache *cache = &cache_pool[cache_count++];
ffffffffc0201128:	c31c                	sw	a5,0(a4)
    memset(cache, 0, sizeof(struct kmem_cache));
ffffffffc020112a:	25b000ef          	jal	ra,ffffffffc0201b84 <memset>
    cache->name = name;
ffffffffc020112e:	016ab023          	sd	s6,0(s5)
    cache->objsize = size;
ffffffffc0201132:	014ab823          	sd	s4,16(s5)
    cache->size = ALIGN_UP(size, cache->align);
ffffffffc0201136:	40900733          	neg	a4,s1
    cache->align = align > 0 ? align : SLUB_ALIGN;
ffffffffc020113a:	e099                	bnez	s1,ffffffffc0201140 <kmem_cache_create+0x6a>
ffffffffc020113c:	5761                	li	a4,-8
ffffffffc020113e:	44a1                	li	s1,8
    cache->size = ALIGN_UP(size, cache->align);
ffffffffc0201140:	00940833          	add	a6,s0,s1
    cache->align = align > 0 ? align : SLUB_ALIGN;
ffffffffc0201144:	013907b3          	add	a5,s2,s3
    cache->size = ALIGN_UP(size, cache->align);
ffffffffc0201148:	00e87833          	and	a6,a6,a4
    cache->align = align > 0 ? align : SLUB_ALIGN;
ffffffffc020114c:	ef84                	sd	s1,24(a5)
    cache->size = ALIGN_UP(size, cache->align);
ffffffffc020114e:	0107b423          	sd	a6,8(a5) # 1008 <kern_entry-0xffffffffc01feff8>
    cache->flags = flags;
ffffffffc0201152:	0377b023          	sd	s7,32(a5)
    if (objsize >= PGSIZE / 4) {
ffffffffc0201156:	3ff00793          	li	a5,1023
    size_t min_objects = 4;  // 每个slab至少4个对象
ffffffffc020115a:	4691                	li	a3,4
    if (objsize >= PGSIZE / 4) {
ffffffffc020115c:	0b07e963          	bltu	a5,a6,ffffffffc020120e <kmem_cache_create+0x138>
    cache->align = align > 0 ? align : SLUB_ALIGN;
ffffffffc0201160:	4701                	li	a4,0
        size_t slab_size = PGSIZE << order;
ffffffffc0201162:	6605                	lui	a2,0x1
        if (objects >= min_objects && objects <= MAX_OBJECTS_PER_SLAB) {
ffffffffc0201164:	10000593          	li	a1,256
    while (order < 10) {  // 最多1024页
ffffffffc0201168:	48a9                	li	a7,10
        size_t slab_size = PGSIZE << order;
ffffffffc020116a:	00e617bb          	sllw	a5,a2,a4
        size_t objects = slab_size / objsize;
ffffffffc020116e:	0307d7b3          	divu	a5,a5,a6
        if (objects >= min_objects && objects <= MAX_OBJECTS_PER_SLAB) {
ffffffffc0201172:	00d7e463          	bltu	a5,a3,ffffffffc020117a <kmem_cache_create+0xa4>
ffffffffc0201176:	00f5f963          	bgeu	a1,a5,ffffffffc0201188 <kmem_cache_create+0xb2>
        order++;
ffffffffc020117a:	2705                	addiw	a4,a4,1
    while (order < 10) {  // 最多1024页
ffffffffc020117c:	ff1717e3          	bne	a4,a7,ffffffffc020116a <kmem_cache_create+0x94>
    cache->objects = slab_size / cache->size;
ffffffffc0201180:	6785                	lui	a5,0x1
ffffffffc0201182:	0307d7b3          	divu	a5,a5,a6
    return 0;  // 使用1个页面
ffffffffc0201186:	4701                	li	a4,0
    __list_add(elm, listelm, listelm->next);
ffffffffc0201188:	00006897          	auipc	a7,0x6
ffffffffc020118c:	8f888893          	addi	a7,a7,-1800 # ffffffffc0206a80 <kmem_cache_list>
ffffffffc0201190:	0088b303          	ld	t1,8(a7)
    list_init(&cache->partial);
ffffffffc0201194:	03898693          	addi	a3,s3,56
    cache->order = calculate_order(cache->size, cache->size);
ffffffffc0201198:	01390833          	add	a6,s2,s3
    list_init(&cache->partial);
ffffffffc020119c:	96ca                	add	a3,a3,s2
    list_add(&kmem_cache_list, &cache->list);
ffffffffc020119e:	07098993          	addi	s3,s3,112
    cache->order = calculate_order(cache->size, cache->size);
ffffffffc02011a2:	02e82823          	sw	a4,48(a6)
    cache->objects = slab_size / cache->size;
ffffffffc02011a6:	02f83423          	sd	a5,40(a6)
    list_add(&kmem_cache_list, &cache->list);
ffffffffc02011aa:	994e                	add	s2,s2,s3
    elm->prev = elm->next = elm;
ffffffffc02011ac:	04d83023          	sd	a3,64(a6)
ffffffffc02011b0:	02d83c23          	sd	a3,56(a6)
    cache->nr_partial = 0;
ffffffffc02011b4:	04083423          	sd	zero,72(a6)
    cache->freelist = NULL;
ffffffffc02011b8:	04083823          	sd	zero,80(a6)
    cache->page = NULL;
ffffffffc02011bc:	04083c23          	sd	zero,88(a6)
    cache->alloc_count = 0;
ffffffffc02011c0:	06083023          	sd	zero,96(a6)
    cache->free_count = 0;
ffffffffc02011c4:	06083423          	sd	zero,104(a6)
    prev->next = next->prev = elm;
ffffffffc02011c8:	01233023          	sd	s2,0(t1)
    cprintf("SLUB: Created cache '%s', objsize=%d, size=%d, order=%d, objects=%d\n",
ffffffffc02011cc:	02883783          	ld	a5,40(a6)
ffffffffc02011d0:	03082703          	lw	a4,48(a6)
ffffffffc02011d4:	00883683          	ld	a3,8(a6)
ffffffffc02011d8:	01083603          	ld	a2,16(a6)
ffffffffc02011dc:	85da                	mv	a1,s6
ffffffffc02011de:	00001517          	auipc	a0,0x1
ffffffffc02011e2:	3fa50513          	addi	a0,a0,1018 # ffffffffc02025d8 <buddy_pmm_manager+0x270>
    elm->next = next;
ffffffffc02011e6:	06683c23          	sd	t1,120(a6)
    elm->prev = prev;
ffffffffc02011ea:	07183823          	sd	a7,112(a6)
    prev->next = next->prev = elm;
ffffffffc02011ee:	0128b423          	sd	s2,8(a7)
ffffffffc02011f2:	f5bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc02011f6:	60a6                	ld	ra,72(sp)
ffffffffc02011f8:	6406                	ld	s0,64(sp)
ffffffffc02011fa:	74e2                	ld	s1,56(sp)
ffffffffc02011fc:	7942                	ld	s2,48(sp)
ffffffffc02011fe:	79a2                	ld	s3,40(sp)
ffffffffc0201200:	7a02                	ld	s4,32(sp)
ffffffffc0201202:	6b42                	ld	s6,16(sp)
ffffffffc0201204:	6ba2                	ld	s7,8(sp)
ffffffffc0201206:	8556                	mv	a0,s5
ffffffffc0201208:	6ae2                	ld	s5,24(sp)
ffffffffc020120a:	6161                	addi	sp,sp,80
ffffffffc020120c:	8082                	ret
    if (objsize >= PGSIZE / 2) {
ffffffffc020120e:	7ff00793          	li	a5,2047
ffffffffc0201212:	0107f663          	bgeu	a5,a6,ffffffffc020121e <kmem_cache_create+0x148>
        min_objects = 1;
ffffffffc0201216:	4685                	li	a3,1
ffffffffc0201218:	b7a1                	j	ffffffffc0201160 <kmem_cache_create+0x8a>
        return NULL;
ffffffffc020121a:	4a81                	li	s5,0
ffffffffc020121c:	bfe9                	j	ffffffffc02011f6 <kmem_cache_create+0x120>
        min_objects = 2;
ffffffffc020121e:	4689                	li	a3,2
ffffffffc0201220:	b781                	j	ffffffffc0201160 <kmem_cache_create+0x8a>

ffffffffc0201222 <kmem_cache_free>:

/**
 * 释放对象到缓存
 */
void kmem_cache_free(struct kmem_cache *cache, void *obj) {
    if (cache == NULL || obj == NULL) {
ffffffffc0201222:	c551                	beqz	a0,ffffffffc02012ae <kmem_cache_free+0x8c>
ffffffffc0201224:	c5c9                	beqz	a1,ffffffffc02012ae <kmem_cache_free+0x8c>
    }
    
    // 查找对象所属的页面
    extern uint64_t va_pa_offset;
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
ffffffffc0201226:	77fd                	lui	a5,0xfffff
    struct Page *page = pa2page(page_addr - va_pa_offset);
ffffffffc0201228:	00006717          	auipc	a4,0x6
ffffffffc020122c:	8c073703          	ld	a4,-1856(a4) # ffffffffc0206ae8 <va_pa_offset>
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
ffffffffc0201230:	8fed                	and	a5,a5,a1
    struct Page *page = pa2page(page_addr - va_pa_offset);
ffffffffc0201232:	8f99                	sub	a5,a5,a4
    if (PPN(pa) >= npage) {
ffffffffc0201234:	83b1                	srli	a5,a5,0xc
ffffffffc0201236:	00006717          	auipc	a4,0x6
ffffffffc020123a:	88a73703          	ld	a4,-1910(a4) # ffffffffc0206ac0 <npage>
ffffffffc020123e:	08e7fe63          	bgeu	a5,a4,ffffffffc02012da <kmem_cache_free+0xb8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201242:	00002717          	auipc	a4,0x2
ffffffffc0201246:	8de73703          	ld	a4,-1826(a4) # ffffffffc0202b20 <nbase>
ffffffffc020124a:	8f99                	sub	a5,a5,a4
ffffffffc020124c:	00279713          	slli	a4,a5,0x2
ffffffffc0201250:	97ba                	add	a5,a5,a4
ffffffffc0201252:	078e                	slli	a5,a5,0x3
ffffffffc0201254:	00006717          	auipc	a4,0x6
ffffffffc0201258:	87473703          	ld	a4,-1932(a4) # ffffffffc0206ac8 <pages>
ffffffffc020125c:	97ba                	add	a5,a5,a4
    
    struct slab_page *sp = (struct slab_page *)page;
    
    // 将对象添加回空闲链表
    *(void **)obj = sp->freelist;
ffffffffc020125e:	6390                	ld	a2,0(a5)
    sp->freelist = obj;
    sp->inuse--;
ffffffffc0201260:	4798                	lw	a4,8(a5)
    
    cache->free_count++;
ffffffffc0201262:	7534                	ld	a3,104(a0)
    *(void **)obj = sp->freelist;
ffffffffc0201264:	e190                	sd	a2,0(a1)
    sp->inuse--;
ffffffffc0201266:	377d                	addiw	a4,a4,-1
    sp->freelist = obj;
ffffffffc0201268:	e38c                	sd	a1,0(a5)
    sp->inuse--;
ffffffffc020126a:	c798                	sw	a4,8(a5)
    cache->free_count++;
ffffffffc020126c:	0685                	addi	a3,a3,1
    sp->inuse--;
ffffffffc020126e:	0007061b          	sext.w	a2,a4
    cache->free_count++;
ffffffffc0201272:	f534                	sd	a3,104(a0)
    
    // 如果slab完全空闲，考虑释放
    if (sp->inuse == 0) {
ffffffffc0201274:	e61d                	bnez	a2,ffffffffc02012a2 <kmem_cache_free+0x80>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201276:	7398                	ld	a4,32(a5)
ffffffffc0201278:	6f94                	ld	a3,24(a5)
        // 从partial链表移除
        list_del(&page->page_link);
        cache->nr_partial--;
ffffffffc020127a:	6530                	ld	a2,72(a0)
        
        // 释放slab（保留至少一个空slab）
        if (cache->nr_partial > 1) {
ffffffffc020127c:	4585                	li	a1,1
    prev->next = next;
ffffffffc020127e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201280:	e314                	sd	a3,0(a4)
        cache->nr_partial--;
ffffffffc0201282:	fff60713          	addi	a4,a2,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201286:	e538                	sd	a4,72(a0)
        if (cache->nr_partial > 1) {
ffffffffc0201288:	02e5e463          	bltu	a1,a4,ffffffffc02012b0 <kmem_cache_free+0x8e>
    __list_add(elm, listelm, listelm->next);
ffffffffc020128c:	6138                	ld	a4,64(a0)
            free_slab(cache, page);
        } else {
            // 重新加回partial链表
            list_add(&cache->partial, &page->page_link);
ffffffffc020128e:	01878693          	addi	a3,a5,24 # fffffffffffff018 <end+0x3fdf8524>
ffffffffc0201292:	03850593          	addi	a1,a0,56
    prev->next = next->prev = elm;
ffffffffc0201296:	e314                	sd	a3,0(a4)
ffffffffc0201298:	e134                	sd	a3,64(a0)
    elm->next = next;
ffffffffc020129a:	f398                	sd	a4,32(a5)
    elm->prev = prev;
ffffffffc020129c:	ef8c                	sd	a1,24(a5)
            cache->nr_partial++;
ffffffffc020129e:	e530                	sd	a2,72(a0)
ffffffffc02012a0:	8082                	ret
        }
    } else if (sp->inuse == cache->objects - 1) {
ffffffffc02012a2:	7514                	ld	a3,40(a0)
ffffffffc02012a4:	1702                	slli	a4,a4,0x20
ffffffffc02012a6:	9301                	srli	a4,a4,0x20
ffffffffc02012a8:	16fd                	addi	a3,a3,-1
ffffffffc02012aa:	00d70b63          	beq	a4,a3,ffffffffc02012c0 <kmem_cache_free+0x9e>
ffffffffc02012ae:	8082                	ret
    ClearPageProperty(page);
ffffffffc02012b0:	6798                	ld	a4,8(a5)
ffffffffc02012b2:	5914                	lw	a3,48(a0)
    free_pages(page, 1 << cache->order);
ffffffffc02012b4:	853e                	mv	a0,a5
    ClearPageProperty(page);
ffffffffc02012b6:	9b75                	andi	a4,a4,-3
ffffffffc02012b8:	e798                	sd	a4,8(a5)
    free_pages(page, 1 << cache->order);
ffffffffc02012ba:	00d595bb          	sllw	a1,a1,a3
ffffffffc02012be:	b4d5                	j	ffffffffc0200da2 <free_pages>
    __list_add(elm, listelm, listelm->next);
ffffffffc02012c0:	6134                	ld	a3,64(a0)
        // slab从满变为partial，添加到链表
        list_add(&cache->partial, &page->page_link);
        cache->nr_partial++;
ffffffffc02012c2:	6538                	ld	a4,72(a0)
        list_add(&cache->partial, &page->page_link);
ffffffffc02012c4:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc02012c8:	e290                	sd	a2,0(a3)
ffffffffc02012ca:	e130                	sd	a2,64(a0)
ffffffffc02012cc:	03850613          	addi	a2,a0,56
    elm->next = next;
ffffffffc02012d0:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02012d2:	ef90                	sd	a2,24(a5)
        cache->nr_partial++;
ffffffffc02012d4:	0705                	addi	a4,a4,1
ffffffffc02012d6:	e538                	sd	a4,72(a0)
ffffffffc02012d8:	8082                	ret
void kmem_cache_free(struct kmem_cache *cache, void *obj) {
ffffffffc02012da:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02012dc:	00001617          	auipc	a2,0x1
ffffffffc02012e0:	17c60613          	addi	a2,a2,380 # ffffffffc0202458 <buddy_pmm_manager+0xf0>
ffffffffc02012e4:	06a00593          	li	a1,106
ffffffffc02012e8:	00001517          	auipc	a0,0x1
ffffffffc02012ec:	19050513          	addi	a0,a0,400 # ffffffffc0202478 <buddy_pmm_manager+0x110>
ffffffffc02012f0:	e406                	sd	ra,8(sp)
ffffffffc02012f2:	ed1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02012f6 <kfree.part.0>:
    }
    
    // 查找对象所属的页面
    extern uint64_t va_pa_offset;
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
ffffffffc02012f6:	77fd                	lui	a5,0xfffff
    struct Page *page = pa2page(page_addr - va_pa_offset);
ffffffffc02012f8:	00005717          	auipc	a4,0x5
ffffffffc02012fc:	7f073703          	ld	a4,2032(a4) # ffffffffc0206ae8 <va_pa_offset>
    uintptr_t page_addr = obj_addr & ~(PGSIZE - 1);
ffffffffc0201300:	8fe9                	and	a5,a5,a0
    struct Page *page = pa2page(page_addr - va_pa_offset);
ffffffffc0201302:	8f99                	sub	a5,a5,a4
    if (PPN(pa) >= npage) {
ffffffffc0201304:	83b1                	srli	a5,a5,0xc
ffffffffc0201306:	00005717          	auipc	a4,0x5
ffffffffc020130a:	7ba73703          	ld	a4,1978(a4) # ffffffffc0206ac0 <npage>
ffffffffc020130e:	02e7f963          	bgeu	a5,a4,ffffffffc0201340 <kfree.part.0+0x4a>
    return &pages[PPN(pa) - nbase];
ffffffffc0201312:	85aa                	mv	a1,a0
ffffffffc0201314:	00002517          	auipc	a0,0x2
ffffffffc0201318:	80c53503          	ld	a0,-2036(a0) # ffffffffc0202b20 <nbase>
ffffffffc020131c:	8f89                	sub	a5,a5,a0
ffffffffc020131e:	00279713          	slli	a4,a5,0x2
ffffffffc0201322:	97ba                	add	a5,a5,a4
ffffffffc0201324:	078e                	slli	a5,a5,0x3
ffffffffc0201326:	00005717          	auipc	a4,0x5
ffffffffc020132a:	7a273703          	ld	a4,1954(a4) # ffffffffc0206ac8 <pages>
ffffffffc020132e:	00f70533          	add	a0,a4,a5
    
    // 检查是否是slab对象
    if (PageProperty(page)) {
ffffffffc0201332:	651c                	ld	a5,8(a0)
ffffffffc0201334:	8b89                	andi	a5,a5,2
ffffffffc0201336:	c399                	beqz	a5,ffffffffc020133c <kfree.part.0+0x46>
        struct slab_page *sp = (struct slab_page *)page;
        kmem_cache_free(sp->cache, obj);
ffffffffc0201338:	6908                	ld	a0,16(a0)
ffffffffc020133a:	b5e5                	j	ffffffffc0201222 <kmem_cache_free>
    } else {
        // 大对象，直接释放页面
        free_pages(page, 1);
ffffffffc020133c:	4585                	li	a1,1
ffffffffc020133e:	b495                	j	ffffffffc0200da2 <free_pages>
void kfree(void *obj) {
ffffffffc0201340:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201342:	00001617          	auipc	a2,0x1
ffffffffc0201346:	11660613          	addi	a2,a2,278 # ffffffffc0202458 <buddy_pmm_manager+0xf0>
ffffffffc020134a:	06a00593          	li	a1,106
ffffffffc020134e:	00001517          	auipc	a0,0x1
ffffffffc0201352:	12a50513          	addi	a0,a0,298 # ffffffffc0202478 <buddy_pmm_manager+0x110>
ffffffffc0201356:	e406                	sd	ra,8(sp)
ffffffffc0201358:	e6bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020135c <slub_init>:
}

/**
 * 初始化SLUB分配器
 */
void slub_init(void) {
ffffffffc020135c:	7135                	addi	sp,sp,-160
    cprintf("SLUB: Initializing SLUB allocator...\n");
ffffffffc020135e:	00001517          	auipc	a0,0x1
ffffffffc0201362:	2c250513          	addi	a0,a0,706 # ffffffffc0202620 <buddy_pmm_manager+0x2b8>
void slub_init(void) {
ffffffffc0201366:	e922                	sd	s0,144(sp)
ffffffffc0201368:	e526                	sd	s1,136(sp)
ffffffffc020136a:	e14a                	sd	s2,128(sp)
ffffffffc020136c:	f8d2                	sd	s4,112(sp)
ffffffffc020136e:	ed06                	sd	ra,152(sp)
ffffffffc0201370:	fcce                	sd	s3,120(sp)
    cprintf("SLUB: Initializing SLUB allocator...\n");
ffffffffc0201372:	ddbfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 初始化全局链表
    list_init(&kmem_cache_list);
    
    // 创建通用大小的缓存
    const size_t sizes[] = {64, 128, 256, 512, 1024, 2048, 4096};
ffffffffc0201376:	00001797          	auipc	a5,0x1
ffffffffc020137a:	4ea78793          	addi	a5,a5,1258 # ffffffffc0202860 <buddy_pmm_manager+0x4f8>
ffffffffc020137e:	0007b383          	ld	t2,0(a5)
ffffffffc0201382:	0087b283          	ld	t0,8(a5)
ffffffffc0201386:	0107bf83          	ld	t6,16(a5)
ffffffffc020138a:	0187bf03          	ld	t5,24(a5)
ffffffffc020138e:	0207be83          	ld	t4,32(a5)
ffffffffc0201392:	0287be03          	ld	t3,40(a5)
ffffffffc0201396:	0307b303          	ld	t1,48(a5)
    const char *names[] = {
ffffffffc020139a:	0387b883          	ld	a7,56(a5)
ffffffffc020139e:	0407b803          	ld	a6,64(a5)
ffffffffc02013a2:	67a8                	ld	a0,72(a5)
ffffffffc02013a4:	6bac                	ld	a1,80(a5)
ffffffffc02013a6:	6fb0                	ld	a2,88(a5)
ffffffffc02013a8:	73b4                	ld	a3,96(a5)
ffffffffc02013aa:	77b8                	ld	a4,104(a5)
    elm->prev = elm->next = elm;
ffffffffc02013ac:	00005797          	auipc	a5,0x5
ffffffffc02013b0:	6d478793          	addi	a5,a5,1748 # ffffffffc0206a80 <kmem_cache_list>
ffffffffc02013b4:	e79c                	sd	a5,8(a5)
ffffffffc02013b6:	e39c                	sd	a5,0(a5)
    const size_t sizes[] = {64, 128, 256, 512, 1024, 2048, 4096};
ffffffffc02013b8:	e01e                	sd	t2,0(sp)
ffffffffc02013ba:	e416                	sd	t0,8(sp)
ffffffffc02013bc:	e87e                	sd	t6,16(sp)
ffffffffc02013be:	ec7a                	sd	t5,24(sp)
ffffffffc02013c0:	f076                	sd	t4,32(sp)
ffffffffc02013c2:	f472                	sd	t3,40(sp)
ffffffffc02013c4:	f81a                	sd	t1,48(sp)
    const char *names[] = {
ffffffffc02013c6:	fc46                	sd	a7,56(sp)
ffffffffc02013c8:	e0c2                	sd	a6,64(sp)
ffffffffc02013ca:	e4aa                	sd	a0,72(sp)
ffffffffc02013cc:	e8ae                	sd	a1,80(sp)
ffffffffc02013ce:	ecb2                	sd	a2,88(sp)
ffffffffc02013d0:	f0b6                	sd	a3,96(sp)
ffffffffc02013d2:	f4ba                	sd	a4,104(sp)
        "kmalloc-64", "kmalloc-128", "kmalloc-256", "kmalloc-512",
        "kmalloc-1024", "kmalloc-2048", "kmalloc-4096"
    };
    
    for (int i = 0; i < 7; i++) {
ffffffffc02013d4:	1820                	addi	s0,sp,56
ffffffffc02013d6:	890a                	mv	s2,sp
ffffffffc02013d8:	00005497          	auipc	s1,0x5
ffffffffc02013dc:	64048493          	addi	s1,s1,1600 # ffffffffc0206a18 <kmalloc_caches>
ffffffffc02013e0:	07010a13          	addi	s4,sp,112
        kmalloc_caches[i] = kmem_cache_create(names[i], sizes[i], 
ffffffffc02013e4:	00093983          	ld	s3,0(s2)
ffffffffc02013e8:	6008                	ld	a0,0(s0)
ffffffffc02013ea:	4681                	li	a3,0
ffffffffc02013ec:	4621                	li	a2,8
ffffffffc02013ee:	85ce                	mv	a1,s3
ffffffffc02013f0:	ce7ff0ef          	jal	ra,ffffffffc02010d6 <kmem_cache_create>
ffffffffc02013f4:	e088                	sd	a0,0(s1)
                                               SLUB_ALIGN, 0);
        if (kmalloc_caches[i] == NULL) {
ffffffffc02013f6:	c11d                	beqz	a0,ffffffffc020141c <slub_init+0xc0>
    for (int i = 0; i < 7; i++) {
ffffffffc02013f8:	0421                	addi	s0,s0,8
ffffffffc02013fa:	0921                	addi	s2,s2,8
ffffffffc02013fc:	04a1                	addi	s1,s1,8
ffffffffc02013fe:	ff4413e3          	bne	s0,s4,ffffffffc02013e4 <slub_init+0x88>
            panic("SLUB: Failed to create kmalloc cache for size %d\n", sizes[i]);
        }
    }
    
    cprintf("SLUB: Initialization complete\n");
}
ffffffffc0201402:	644a                	ld	s0,144(sp)
ffffffffc0201404:	60ea                	ld	ra,152(sp)
ffffffffc0201406:	64aa                	ld	s1,136(sp)
ffffffffc0201408:	690a                	ld	s2,128(sp)
ffffffffc020140a:	79e6                	ld	s3,120(sp)
ffffffffc020140c:	7a46                	ld	s4,112(sp)
    cprintf("SLUB: Initialization complete\n");
ffffffffc020140e:	00001517          	auipc	a0,0x1
ffffffffc0201412:	28250513          	addi	a0,a0,642 # ffffffffc0202690 <buddy_pmm_manager+0x328>
}
ffffffffc0201416:	610d                	addi	sp,sp,160
    cprintf("SLUB: Initialization complete\n");
ffffffffc0201418:	d35fe06f          	j	ffffffffc020014c <cprintf>
            panic("SLUB: Failed to create kmalloc cache for size %d\n", sizes[i]);
ffffffffc020141c:	86ce                	mv	a3,s3
ffffffffc020141e:	00001617          	auipc	a2,0x1
ffffffffc0201422:	22a60613          	addi	a2,a2,554 # ffffffffc0202648 <buddy_pmm_manager+0x2e0>
ffffffffc0201426:	1c200593          	li	a1,450
ffffffffc020142a:	00001517          	auipc	a0,0x1
ffffffffc020142e:	25650513          	addi	a0,a0,598 # ffffffffc0202680 <buddy_pmm_manager+0x318>
ffffffffc0201432:	d91fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201436 <slub_check>:

/**
 * 测试SLUB分配器
 */
void slub_check(void) {
ffffffffc0201436:	7119                	addi	sp,sp,-128
    cprintf("SLUB: Starting SLUB allocator tests...\n");
ffffffffc0201438:	00001517          	auipc	a0,0x1
ffffffffc020143c:	27850513          	addi	a0,a0,632 # ffffffffc02026b0 <buddy_pmm_manager+0x348>
void slub_check(void) {
ffffffffc0201440:	fc86                	sd	ra,120(sp)
ffffffffc0201442:	ecce                	sd	s3,88(sp)
ffffffffc0201444:	f8a2                	sd	s0,112(sp)
ffffffffc0201446:	f4a6                	sd	s1,104(sp)
ffffffffc0201448:	f0ca                	sd	s2,96(sp)
    cprintf("SLUB: Starting SLUB allocator tests...\n");
ffffffffc020144a:	d03fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 1: 基本分配和释放
    cprintf("Test 1: Basic allocation and free...\n");
ffffffffc020144e:	00001517          	auipc	a0,0x1
ffffffffc0201452:	28a50513          	addi	a0,a0,650 # ffffffffc02026d8 <buddy_pmm_manager+0x370>
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201456:	00005997          	auipc	s3,0x5
ffffffffc020145a:	5c298993          	addi	s3,s3,1474 # ffffffffc0206a18 <kmalloc_caches>
    cprintf("Test 1: Basic allocation and free...\n");
ffffffffc020145e:	ceffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201462:	0009b503          	ld	a0,0(s3)
ffffffffc0201466:	26050a63          	beqz	a0,ffffffffc02016da <slub_check+0x2a4>
    if (cache->freelist != NULL) {
ffffffffc020146a:	6924                	ld	s1,80(a0)
ffffffffc020146c:	1c048f63          	beqz	s1,ffffffffc020164a <slub_check+0x214>
        cache->alloc_count++;
ffffffffc0201470:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc0201472:	6098                	ld	a4,0(s1)
        cache->alloc_count++;
ffffffffc0201474:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc0201476:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc0201478:	f13c                	sd	a5,96(a0)
    if (kmalloc_caches[index] == NULL) {
ffffffffc020147a:	0089b503          	ld	a0,8(s3)
ffffffffc020147e:	1c050d63          	beqz	a0,ffffffffc0201658 <slub_check+0x222>
    if (cache->freelist != NULL) {
ffffffffc0201482:	6920                	ld	s0,80(a0)
ffffffffc0201484:	20040363          	beqz	s0,ffffffffc020168a <slub_check+0x254>
        cache->alloc_count++;
ffffffffc0201488:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc020148a:	6018                	ld	a4,0(s0)
        cache->alloc_count++;
ffffffffc020148c:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc020148e:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc0201490:	f13c                	sd	a5,96(a0)
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201492:	0109b503          	ld	a0,16(s3)
ffffffffc0201496:	1c050663          	beqz	a0,ffffffffc0201662 <slub_check+0x22c>
    if (cache->freelist != NULL) {
ffffffffc020149a:	05053903          	ld	s2,80(a0)
ffffffffc020149e:	1e090263          	beqz	s2,ffffffffc0201682 <slub_check+0x24c>
        cache->alloc_count++;
ffffffffc02014a2:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc02014a4:	00093703          	ld	a4,0(s2)
        cache->alloc_count++;
ffffffffc02014a8:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc02014aa:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc02014ac:	f13c                	sd	a5,96(a0)
    void *p1 = kmalloc(64);
    void *p2 = kmalloc(128);
    void *p3 = kmalloc(256);
    
    assert(p1 != NULL && p2 != NULL && p3 != NULL);
ffffffffc02014ae:	1a048a63          	beqz	s1,ffffffffc0201662 <slub_check+0x22c>
ffffffffc02014b2:	1a040863          	beqz	s0,ffffffffc0201662 <slub_check+0x22c>
ffffffffc02014b6:	1a090663          	beqz	s2,ffffffffc0201662 <slub_check+0x22c>
    assert(p1 != p2 && p2 != p3 && p1 != p3);
ffffffffc02014ba:	22848463          	beq	s1,s0,ffffffffc02016e2 <slub_check+0x2ac>
ffffffffc02014be:	22890263          	beq	s2,s0,ffffffffc02016e2 <slub_check+0x2ac>
ffffffffc02014c2:	22990063          	beq	s2,s1,ffffffffc02016e2 <slub_check+0x2ac>
    if (obj == NULL) {
ffffffffc02014c6:	8526                	mv	a0,s1
ffffffffc02014c8:	e2fff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
ffffffffc02014cc:	8522                	mv	a0,s0
ffffffffc02014ce:	e29ff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
ffffffffc02014d2:	854a                	mv	a0,s2
ffffffffc02014d4:	e23ff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
    
    kfree(p1);
    kfree(p2);
    kfree(p3);
    cprintf("Test 1 Passed!\n");
ffffffffc02014d8:	00001517          	auipc	a0,0x1
ffffffffc02014dc:	a7850513          	addi	a0,a0,-1416 # ffffffffc0201f50 <etext+0x3ba>
ffffffffc02014e0:	c6dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 2: 重复分配
    cprintf("Test 2: Multiple allocations...\n");
ffffffffc02014e4:	00001517          	auipc	a0,0x1
ffffffffc02014e8:	26c50513          	addi	a0,a0,620 # ffffffffc0202750 <buddy_pmm_manager+0x3e8>
ffffffffc02014ec:	840a                	mv	s0,sp
ffffffffc02014ee:	c5ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *ptrs[10];
    for (int i = 0; i < 10; i++) {
ffffffffc02014f2:	05010913          	addi	s2,sp,80
    cprintf("Test 2: Multiple allocations...\n");
ffffffffc02014f6:	84a2                	mv	s1,s0
ffffffffc02014f8:	a819                	j	ffffffffc020150e <slub_check+0xd8>
        cache->alloc_count++;
ffffffffc02014fa:	7138                	ld	a4,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc02014fc:	6394                	ld	a3,0(a5)
        ptrs[i] = kmalloc(128);
ffffffffc02014fe:	e09c                	sd	a5,0(s1)
        cache->alloc_count++;
ffffffffc0201500:	00170793          	addi	a5,a4,1
        cache->freelist = *(void **)obj;
ffffffffc0201504:	e934                	sd	a3,80(a0)
        cache->alloc_count++;
ffffffffc0201506:	f13c                	sd	a5,96(a0)
    for (int i = 0; i < 10; i++) {
ffffffffc0201508:	04a1                	addi	s1,s1,8
ffffffffc020150a:	02990b63          	beq	s2,s1,ffffffffc0201540 <slub_check+0x10a>
    if (kmalloc_caches[index] == NULL) {
ffffffffc020150e:	0089b503          	ld	a0,8(s3)
ffffffffc0201512:	c519                	beqz	a0,ffffffffc0201520 <slub_check+0xea>
    if (cache->freelist != NULL) {
ffffffffc0201514:	693c                	ld	a5,80(a0)
ffffffffc0201516:	f3f5                	bnez	a5,ffffffffc02014fa <slub_check+0xc4>
ffffffffc0201518:	ab3ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
        ptrs[i] = kmalloc(128);
ffffffffc020151c:	e088                	sd	a0,0(s1)
        assert(ptrs[i] != NULL);
ffffffffc020151e:	f56d                	bnez	a0,ffffffffc0201508 <slub_check+0xd2>
ffffffffc0201520:	00001697          	auipc	a3,0x1
ffffffffc0201524:	25868693          	addi	a3,a3,600 # ffffffffc0202778 <buddy_pmm_manager+0x410>
ffffffffc0201528:	00001617          	auipc	a2,0x1
ffffffffc020152c:	8d860613          	addi	a2,a2,-1832 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0201530:	1e200593          	li	a1,482
ffffffffc0201534:	00001517          	auipc	a0,0x1
ffffffffc0201538:	14c50513          	addi	a0,a0,332 # ffffffffc0202680 <buddy_pmm_manager+0x318>
ffffffffc020153c:	c87fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    }
    
    for (int i = 0; i < 10; i++) {
        kfree(ptrs[i]);
ffffffffc0201540:	6008                	ld	a0,0(s0)
    if (obj == NULL) {
ffffffffc0201542:	c119                	beqz	a0,ffffffffc0201548 <slub_check+0x112>
ffffffffc0201544:	db3ff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
    for (int i = 0; i < 10; i++) {
ffffffffc0201548:	0421                	addi	s0,s0,8
ffffffffc020154a:	fe891be3          	bne	s2,s0,ffffffffc0201540 <slub_check+0x10a>
    }
    cprintf("Test 2 Passed!\n");
ffffffffc020154e:	00001517          	auipc	a0,0x1
ffffffffc0201552:	a3250513          	addi	a0,a0,-1486 # ffffffffc0201f80 <etext+0x3ea>
ffffffffc0201556:	bf7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 3: 不同大小
    cprintf("Test 3: Different sizes...\n");
ffffffffc020155a:	00001517          	auipc	a0,0x1
ffffffffc020155e:	22e50513          	addi	a0,a0,558 # ffffffffc0202788 <buddy_pmm_manager+0x420>
ffffffffc0201562:	bebfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201566:	0009b503          	ld	a0,0(s3)
ffffffffc020156a:	16050a63          	beqz	a0,ffffffffc02016de <slub_check+0x2a8>
    if (cache->freelist != NULL) {
ffffffffc020156e:	6924                	ld	s1,80(a0)
ffffffffc0201570:	12048163          	beqz	s1,ffffffffc0201692 <slub_check+0x25c>
        cache->alloc_count++;
ffffffffc0201574:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc0201576:	6098                	ld	a4,0(s1)
        cache->alloc_count++;
ffffffffc0201578:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc020157a:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc020157c:	f13c                	sd	a5,96(a0)
    if (kmalloc_caches[index] == NULL) {
ffffffffc020157e:	0189b503          	ld	a0,24(s3)
ffffffffc0201582:	10050f63          	beqz	a0,ffffffffc02016a0 <slub_check+0x26a>
    if (cache->freelist != NULL) {
ffffffffc0201586:	6920                	ld	s0,80(a0)
ffffffffc0201588:	14040563          	beqz	s0,ffffffffc02016d2 <slub_check+0x29c>
        cache->alloc_count++;
ffffffffc020158c:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc020158e:	6018                	ld	a4,0(s0)
        cache->alloc_count++;
ffffffffc0201590:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc0201592:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc0201594:	f13c                	sd	a5,96(a0)
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201596:	0289b503          	ld	a0,40(s3)
ffffffffc020159a:	10050863          	beqz	a0,ffffffffc02016aa <slub_check+0x274>
    if (cache->freelist != NULL) {
ffffffffc020159e:	05053903          	ld	s2,80(a0)
ffffffffc02015a2:	12090463          	beqz	s2,ffffffffc02016ca <slub_check+0x294>
        cache->alloc_count++;
ffffffffc02015a6:	713c                	ld	a5,96(a0)
        cache->freelist = *(void **)obj;
ffffffffc02015a8:	00093703          	ld	a4,0(s2)
        cache->alloc_count++;
ffffffffc02015ac:	0785                	addi	a5,a5,1
        cache->freelist = *(void **)obj;
ffffffffc02015ae:	e938                	sd	a4,80(a0)
        cache->alloc_count++;
ffffffffc02015b0:	f13c                	sd	a5,96(a0)
    void *p_small = kmalloc(16);
    void *p_medium = kmalloc(512);
    void *p_large = kmalloc(2048);
    
    assert(p_small != NULL && p_medium != NULL && p_large != NULL);
ffffffffc02015b2:	0e048c63          	beqz	s1,ffffffffc02016aa <slub_check+0x274>
ffffffffc02015b6:	0e040a63          	beqz	s0,ffffffffc02016aa <slub_check+0x274>
ffffffffc02015ba:	0e090863          	beqz	s2,ffffffffc02016aa <slub_check+0x274>
    if (obj == NULL) {
ffffffffc02015be:	8526                	mv	a0,s1
ffffffffc02015c0:	d37ff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
ffffffffc02015c4:	8522                	mv	a0,s0
ffffffffc02015c6:	d31ff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
ffffffffc02015ca:	854a                	mv	a0,s2
ffffffffc02015cc:	d2bff0ef          	jal	ra,ffffffffc02012f6 <kfree.part.0>
    
    kfree(p_small);
    kfree(p_medium);
    kfree(p_large);
    cprintf("Test 3 Passed!\n");
ffffffffc02015d0:	00001517          	auipc	a0,0x1
ffffffffc02015d4:	a3850513          	addi	a0,a0,-1480 # ffffffffc0202008 <etext+0x472>
ffffffffc02015d8:	b75fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // Test 4: 缓存统计
    cprintf("Test 4: Cache statistics...\n");
ffffffffc02015dc:	00001517          	auipc	a0,0x1
ffffffffc02015e0:	20450513          	addi	a0,a0,516 # ffffffffc02027e0 <buddy_pmm_manager+0x478>
ffffffffc02015e4:	b69fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Cache Information:\n");
ffffffffc02015e8:	00001517          	auipc	a0,0x1
ffffffffc02015ec:	21850513          	addi	a0,a0,536 # ffffffffc0202800 <buddy_pmm_manager+0x498>
    return listelm->next;
ffffffffc02015f0:	00005497          	auipc	s1,0x5
ffffffffc02015f4:	49048493          	addi	s1,s1,1168 # ffffffffc0206a80 <kmem_cache_list>
ffffffffc02015f8:	b55fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02015fc:	6480                	ld	s0,8(s1)
    list_entry_t *le = &kmem_cache_list;
    while ((le = list_next(le)) != &kmem_cache_list) {
ffffffffc02015fe:	02940463          	beq	s0,s1,ffffffffc0201626 <slub_check+0x1f0>
        struct kmem_cache *cache = to_struct(le, struct kmem_cache, list);
        cprintf("  %s: alloc=%lu, free=%lu, partial=%lu\n",
ffffffffc0201602:	00001917          	auipc	s2,0x1
ffffffffc0201606:	21690913          	addi	s2,s2,534 # ffffffffc0202818 <buddy_pmm_manager+0x4b0>
ffffffffc020160a:	fd843703          	ld	a4,-40(s0)
ffffffffc020160e:	ff843683          	ld	a3,-8(s0)
ffffffffc0201612:	ff043603          	ld	a2,-16(s0)
ffffffffc0201616:	f9043583          	ld	a1,-112(s0)
ffffffffc020161a:	854a                	mv	a0,s2
ffffffffc020161c:	b31fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201620:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != &kmem_cache_list) {
ffffffffc0201622:	fe9414e3          	bne	s0,s1,ffffffffc020160a <slub_check+0x1d4>
                cache->name, cache->alloc_count, cache->free_count, 
                cache->nr_partial);
    }
    cprintf("Test 4 Passed!\n");
ffffffffc0201626:	00001517          	auipc	a0,0x1
ffffffffc020162a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0202038 <etext+0x4a2>
ffffffffc020162e:	b1ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    cprintf("SLUB: All tests passed!\n");
}
ffffffffc0201632:	7446                	ld	s0,112(sp)
ffffffffc0201634:	70e6                	ld	ra,120(sp)
ffffffffc0201636:	74a6                	ld	s1,104(sp)
ffffffffc0201638:	7906                	ld	s2,96(sp)
ffffffffc020163a:	69e6                	ld	s3,88(sp)
    cprintf("SLUB: All tests passed!\n");
ffffffffc020163c:	00001517          	auipc	a0,0x1
ffffffffc0201640:	20450513          	addi	a0,a0,516 # ffffffffc0202840 <buddy_pmm_manager+0x4d8>
}
ffffffffc0201644:	6109                	addi	sp,sp,128
    cprintf("SLUB: All tests passed!\n");
ffffffffc0201646:	b07fe06f          	j	ffffffffc020014c <cprintf>
ffffffffc020164a:	981ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc020164e:	84aa                	mv	s1,a0
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201650:	0089b503          	ld	a0,8(s3)
ffffffffc0201654:	e20517e3          	bnez	a0,ffffffffc0201482 <slub_check+0x4c>
ffffffffc0201658:	0109b503          	ld	a0,16(s3)
        return NULL;
ffffffffc020165c:	4401                	li	s0,0
    if (kmalloc_caches[index] == NULL) {
ffffffffc020165e:	e2051ee3          	bnez	a0,ffffffffc020149a <slub_check+0x64>
    assert(p1 != NULL && p2 != NULL && p3 != NULL);
ffffffffc0201662:	00001697          	auipc	a3,0x1
ffffffffc0201666:	09e68693          	addi	a3,a3,158 # ffffffffc0202700 <buddy_pmm_manager+0x398>
ffffffffc020166a:	00000617          	auipc	a2,0x0
ffffffffc020166e:	79660613          	addi	a2,a2,1942 # ffffffffc0201e00 <etext+0x26a>
ffffffffc0201672:	1d500593          	li	a1,469
ffffffffc0201676:	00001517          	auipc	a0,0x1
ffffffffc020167a:	00a50513          	addi	a0,a0,10 # ffffffffc0202680 <buddy_pmm_manager+0x318>
ffffffffc020167e:	b45fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0201682:	949ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc0201686:	892a                	mv	s2,a0
ffffffffc0201688:	b51d                	j	ffffffffc02014ae <slub_check+0x78>
ffffffffc020168a:	941ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc020168e:	842a                	mv	s0,a0
ffffffffc0201690:	b509                	j	ffffffffc0201492 <slub_check+0x5c>
ffffffffc0201692:	939ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc0201696:	84aa                	mv	s1,a0
    if (kmalloc_caches[index] == NULL) {
ffffffffc0201698:	0189b503          	ld	a0,24(s3)
ffffffffc020169c:	ee0515e3          	bnez	a0,ffffffffc0201586 <slub_check+0x150>
ffffffffc02016a0:	0289b503          	ld	a0,40(s3)
        return NULL;
ffffffffc02016a4:	4401                	li	s0,0
    if (kmalloc_caches[index] == NULL) {
ffffffffc02016a6:	ee051ce3          	bnez	a0,ffffffffc020159e <slub_check+0x168>
    assert(p_small != NULL && p_medium != NULL && p_large != NULL);
ffffffffc02016aa:	00001697          	auipc	a3,0x1
ffffffffc02016ae:	0fe68693          	addi	a3,a3,254 # ffffffffc02027a8 <buddy_pmm_manager+0x440>
ffffffffc02016b2:	00000617          	auipc	a2,0x0
ffffffffc02016b6:	74e60613          	addi	a2,a2,1870 # ffffffffc0201e00 <etext+0x26a>
ffffffffc02016ba:	1f000593          	li	a1,496
ffffffffc02016be:	00001517          	auipc	a0,0x1
ffffffffc02016c2:	fc250513          	addi	a0,a0,-62 # ffffffffc0202680 <buddy_pmm_manager+0x318>
ffffffffc02016c6:	afdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02016ca:	901ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc02016ce:	892a                	mv	s2,a0
ffffffffc02016d0:	b5cd                	j	ffffffffc02015b2 <slub_check+0x17c>
ffffffffc02016d2:	8f9ff0ef          	jal	ra,ffffffffc0200fca <kmem_cache_alloc.part.0>
ffffffffc02016d6:	842a                	mv	s0,a0
ffffffffc02016d8:	bd7d                	j	ffffffffc0201596 <slub_check+0x160>
        return NULL;
ffffffffc02016da:	4481                	li	s1,0
ffffffffc02016dc:	bb79                	j	ffffffffc020147a <slub_check+0x44>
ffffffffc02016de:	4481                	li	s1,0
ffffffffc02016e0:	bd79                	j	ffffffffc020157e <slub_check+0x148>
    assert(p1 != p2 && p2 != p3 && p1 != p3);
ffffffffc02016e2:	00001697          	auipc	a3,0x1
ffffffffc02016e6:	04668693          	addi	a3,a3,70 # ffffffffc0202728 <buddy_pmm_manager+0x3c0>
ffffffffc02016ea:	00000617          	auipc	a2,0x0
ffffffffc02016ee:	71660613          	addi	a2,a2,1814 # ffffffffc0201e00 <etext+0x26a>
ffffffffc02016f2:	1d600593          	li	a1,470
ffffffffc02016f6:	00001517          	auipc	a0,0x1
ffffffffc02016fa:	f8a50513          	addi	a0,a0,-118 # ffffffffc0202680 <buddy_pmm_manager+0x318>
ffffffffc02016fe:	ac5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201702 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201702:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201706:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201708:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020170c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020170e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201712:	f022                	sd	s0,32(sp)
ffffffffc0201714:	ec26                	sd	s1,24(sp)
ffffffffc0201716:	e84a                	sd	s2,16(sp)
ffffffffc0201718:	f406                	sd	ra,40(sp)
ffffffffc020171a:	e44e                	sd	s3,8(sp)
ffffffffc020171c:	84aa                	mv	s1,a0
ffffffffc020171e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201720:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201724:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201726:	03067e63          	bgeu	a2,a6,ffffffffc0201762 <printnum+0x60>
ffffffffc020172a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020172c:	00805763          	blez	s0,ffffffffc020173a <printnum+0x38>
ffffffffc0201730:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201732:	85ca                	mv	a1,s2
ffffffffc0201734:	854e                	mv	a0,s3
ffffffffc0201736:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201738:	fc65                	bnez	s0,ffffffffc0201730 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020173a:	1a02                	slli	s4,s4,0x20
ffffffffc020173c:	00001797          	auipc	a5,0x1
ffffffffc0201740:	19478793          	addi	a5,a5,404 # ffffffffc02028d0 <buddy_pmm_manager+0x568>
ffffffffc0201744:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201748:	9a3e                	add	s4,s4,a5
}
ffffffffc020174a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020174c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201750:	70a2                	ld	ra,40(sp)
ffffffffc0201752:	69a2                	ld	s3,8(sp)
ffffffffc0201754:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201756:	85ca                	mv	a1,s2
ffffffffc0201758:	87a6                	mv	a5,s1
}
ffffffffc020175a:	6942                	ld	s2,16(sp)
ffffffffc020175c:	64e2                	ld	s1,24(sp)
ffffffffc020175e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201760:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201762:	03065633          	divu	a2,a2,a6
ffffffffc0201766:	8722                	mv	a4,s0
ffffffffc0201768:	f9bff0ef          	jal	ra,ffffffffc0201702 <printnum>
ffffffffc020176c:	b7f9                	j	ffffffffc020173a <printnum+0x38>

ffffffffc020176e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020176e:	7119                	addi	sp,sp,-128
ffffffffc0201770:	f4a6                	sd	s1,104(sp)
ffffffffc0201772:	f0ca                	sd	s2,96(sp)
ffffffffc0201774:	ecce                	sd	s3,88(sp)
ffffffffc0201776:	e8d2                	sd	s4,80(sp)
ffffffffc0201778:	e4d6                	sd	s5,72(sp)
ffffffffc020177a:	e0da                	sd	s6,64(sp)
ffffffffc020177c:	fc5e                	sd	s7,56(sp)
ffffffffc020177e:	f06a                	sd	s10,32(sp)
ffffffffc0201780:	fc86                	sd	ra,120(sp)
ffffffffc0201782:	f8a2                	sd	s0,112(sp)
ffffffffc0201784:	f862                	sd	s8,48(sp)
ffffffffc0201786:	f466                	sd	s9,40(sp)
ffffffffc0201788:	ec6e                	sd	s11,24(sp)
ffffffffc020178a:	892a                	mv	s2,a0
ffffffffc020178c:	84ae                	mv	s1,a1
ffffffffc020178e:	8d32                	mv	s10,a2
ffffffffc0201790:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201792:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201796:	5b7d                	li	s6,-1
ffffffffc0201798:	00001a97          	auipc	s5,0x1
ffffffffc020179c:	16ca8a93          	addi	s5,s5,364 # ffffffffc0202904 <buddy_pmm_manager+0x59c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017a0:	00001b97          	auipc	s7,0x1
ffffffffc02017a4:	340b8b93          	addi	s7,s7,832 # ffffffffc0202ae0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017a8:	000d4503          	lbu	a0,0(s10)
ffffffffc02017ac:	001d0413          	addi	s0,s10,1
ffffffffc02017b0:	01350a63          	beq	a0,s3,ffffffffc02017c4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02017b4:	c121                	beqz	a0,ffffffffc02017f4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02017b6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017b8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02017ba:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017bc:	fff44503          	lbu	a0,-1(s0)
ffffffffc02017c0:	ff351ae3          	bne	a0,s3,ffffffffc02017b4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017c4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02017c8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02017cc:	4c81                	li	s9,0
ffffffffc02017ce:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02017d0:	5c7d                	li	s8,-1
ffffffffc02017d2:	5dfd                	li	s11,-1
ffffffffc02017d4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02017d8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017da:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02017de:	0ff5f593          	zext.b	a1,a1
ffffffffc02017e2:	00140d13          	addi	s10,s0,1
ffffffffc02017e6:	04b56263          	bltu	a0,a1,ffffffffc020182a <vprintfmt+0xbc>
ffffffffc02017ea:	058a                	slli	a1,a1,0x2
ffffffffc02017ec:	95d6                	add	a1,a1,s5
ffffffffc02017ee:	4194                	lw	a3,0(a1)
ffffffffc02017f0:	96d6                	add	a3,a3,s5
ffffffffc02017f2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02017f4:	70e6                	ld	ra,120(sp)
ffffffffc02017f6:	7446                	ld	s0,112(sp)
ffffffffc02017f8:	74a6                	ld	s1,104(sp)
ffffffffc02017fa:	7906                	ld	s2,96(sp)
ffffffffc02017fc:	69e6                	ld	s3,88(sp)
ffffffffc02017fe:	6a46                	ld	s4,80(sp)
ffffffffc0201800:	6aa6                	ld	s5,72(sp)
ffffffffc0201802:	6b06                	ld	s6,64(sp)
ffffffffc0201804:	7be2                	ld	s7,56(sp)
ffffffffc0201806:	7c42                	ld	s8,48(sp)
ffffffffc0201808:	7ca2                	ld	s9,40(sp)
ffffffffc020180a:	7d02                	ld	s10,32(sp)
ffffffffc020180c:	6de2                	ld	s11,24(sp)
ffffffffc020180e:	6109                	addi	sp,sp,128
ffffffffc0201810:	8082                	ret
            padc = '0';
ffffffffc0201812:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201814:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201818:	846a                	mv	s0,s10
ffffffffc020181a:	00140d13          	addi	s10,s0,1
ffffffffc020181e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201822:	0ff5f593          	zext.b	a1,a1
ffffffffc0201826:	fcb572e3          	bgeu	a0,a1,ffffffffc02017ea <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020182a:	85a6                	mv	a1,s1
ffffffffc020182c:	02500513          	li	a0,37
ffffffffc0201830:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201832:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201836:	8d22                	mv	s10,s0
ffffffffc0201838:	f73788e3          	beq	a5,s3,ffffffffc02017a8 <vprintfmt+0x3a>
ffffffffc020183c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201840:	1d7d                	addi	s10,s10,-1
ffffffffc0201842:	ff379de3          	bne	a5,s3,ffffffffc020183c <vprintfmt+0xce>
ffffffffc0201846:	b78d                	j	ffffffffc02017a8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201848:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020184c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201850:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201852:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201856:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020185a:	02d86463          	bltu	a6,a3,ffffffffc0201882 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020185e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201862:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201866:	0186873b          	addw	a4,a3,s8
ffffffffc020186a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020186e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201870:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201874:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201876:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020187a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020187e:	fed870e3          	bgeu	a6,a3,ffffffffc020185e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201882:	f40ddce3          	bgez	s11,ffffffffc02017da <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201886:	8de2                	mv	s11,s8
ffffffffc0201888:	5c7d                	li	s8,-1
ffffffffc020188a:	bf81                	j	ffffffffc02017da <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020188c:	fffdc693          	not	a3,s11
ffffffffc0201890:	96fd                	srai	a3,a3,0x3f
ffffffffc0201892:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201896:	00144603          	lbu	a2,1(s0)
ffffffffc020189a:	2d81                	sext.w	s11,s11
ffffffffc020189c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020189e:	bf35                	j	ffffffffc02017da <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02018a0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018a4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02018a8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018aa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02018ac:	bfd9                	j	ffffffffc0201882 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02018ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02018b0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02018b4:	01174463          	blt	a4,a7,ffffffffc02018bc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02018b8:	1a088e63          	beqz	a7,ffffffffc0201a74 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02018bc:	000a3603          	ld	a2,0(s4)
ffffffffc02018c0:	46c1                	li	a3,16
ffffffffc02018c2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02018c4:	2781                	sext.w	a5,a5
ffffffffc02018c6:	876e                	mv	a4,s11
ffffffffc02018c8:	85a6                	mv	a1,s1
ffffffffc02018ca:	854a                	mv	a0,s2
ffffffffc02018cc:	e37ff0ef          	jal	ra,ffffffffc0201702 <printnum>
            break;
ffffffffc02018d0:	bde1                	j	ffffffffc02017a8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02018d2:	000a2503          	lw	a0,0(s4)
ffffffffc02018d6:	85a6                	mv	a1,s1
ffffffffc02018d8:	0a21                	addi	s4,s4,8
ffffffffc02018da:	9902                	jalr	s2
            break;
ffffffffc02018dc:	b5f1                	j	ffffffffc02017a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02018de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02018e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02018e4:	01174463          	blt	a4,a7,ffffffffc02018ec <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02018e8:	18088163          	beqz	a7,ffffffffc0201a6a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02018ec:	000a3603          	ld	a2,0(s4)
ffffffffc02018f0:	46a9                	li	a3,10
ffffffffc02018f2:	8a2e                	mv	s4,a1
ffffffffc02018f4:	bfc1                	j	ffffffffc02018c4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018f6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02018fa:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018fe:	bdf1                	j	ffffffffc02017da <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201900:	85a6                	mv	a1,s1
ffffffffc0201902:	02500513          	li	a0,37
ffffffffc0201906:	9902                	jalr	s2
            break;
ffffffffc0201908:	b545                	j	ffffffffc02017a8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020190a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020190e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201910:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201912:	b5e1                	j	ffffffffc02017da <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201914:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201916:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020191a:	01174463          	blt	a4,a7,ffffffffc0201922 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020191e:	14088163          	beqz	a7,ffffffffc0201a60 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201922:	000a3603          	ld	a2,0(s4)
ffffffffc0201926:	46a1                	li	a3,8
ffffffffc0201928:	8a2e                	mv	s4,a1
ffffffffc020192a:	bf69                	j	ffffffffc02018c4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020192c:	03000513          	li	a0,48
ffffffffc0201930:	85a6                	mv	a1,s1
ffffffffc0201932:	e03e                	sd	a5,0(sp)
ffffffffc0201934:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201936:	85a6                	mv	a1,s1
ffffffffc0201938:	07800513          	li	a0,120
ffffffffc020193c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020193e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201940:	6782                	ld	a5,0(sp)
ffffffffc0201942:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201944:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201948:	bfb5                	j	ffffffffc02018c4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020194a:	000a3403          	ld	s0,0(s4)
ffffffffc020194e:	008a0713          	addi	a4,s4,8
ffffffffc0201952:	e03a                	sd	a4,0(sp)
ffffffffc0201954:	14040263          	beqz	s0,ffffffffc0201a98 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201958:	0fb05763          	blez	s11,ffffffffc0201a46 <vprintfmt+0x2d8>
ffffffffc020195c:	02d00693          	li	a3,45
ffffffffc0201960:	0cd79163          	bne	a5,a3,ffffffffc0201a22 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201964:	00044783          	lbu	a5,0(s0)
ffffffffc0201968:	0007851b          	sext.w	a0,a5
ffffffffc020196c:	cf85                	beqz	a5,ffffffffc02019a4 <vprintfmt+0x236>
ffffffffc020196e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201972:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201976:	000c4563          	bltz	s8,ffffffffc0201980 <vprintfmt+0x212>
ffffffffc020197a:	3c7d                	addiw	s8,s8,-1
ffffffffc020197c:	036c0263          	beq	s8,s6,ffffffffc02019a0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201980:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201982:	0e0c8e63          	beqz	s9,ffffffffc0201a7e <vprintfmt+0x310>
ffffffffc0201986:	3781                	addiw	a5,a5,-32
ffffffffc0201988:	0ef47b63          	bgeu	s0,a5,ffffffffc0201a7e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020198c:	03f00513          	li	a0,63
ffffffffc0201990:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201992:	000a4783          	lbu	a5,0(s4)
ffffffffc0201996:	3dfd                	addiw	s11,s11,-1
ffffffffc0201998:	0a05                	addi	s4,s4,1
ffffffffc020199a:	0007851b          	sext.w	a0,a5
ffffffffc020199e:	ffe1                	bnez	a5,ffffffffc0201976 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02019a0:	01b05963          	blez	s11,ffffffffc02019b2 <vprintfmt+0x244>
ffffffffc02019a4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02019a6:	85a6                	mv	a1,s1
ffffffffc02019a8:	02000513          	li	a0,32
ffffffffc02019ac:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02019ae:	fe0d9be3          	bnez	s11,ffffffffc02019a4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02019b2:	6a02                	ld	s4,0(sp)
ffffffffc02019b4:	bbd5                	j	ffffffffc02017a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02019b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02019b8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02019bc:	01174463          	blt	a4,a7,ffffffffc02019c4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02019c0:	08088d63          	beqz	a7,ffffffffc0201a5a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02019c4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02019c8:	0a044d63          	bltz	s0,ffffffffc0201a82 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02019cc:	8622                	mv	a2,s0
ffffffffc02019ce:	8a66                	mv	s4,s9
ffffffffc02019d0:	46a9                	li	a3,10
ffffffffc02019d2:	bdcd                	j	ffffffffc02018c4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02019d4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019d8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02019da:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02019dc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02019e0:	8fb5                	xor	a5,a5,a3
ffffffffc02019e2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019e6:	02d74163          	blt	a4,a3,ffffffffc0201a08 <vprintfmt+0x29a>
ffffffffc02019ea:	00369793          	slli	a5,a3,0x3
ffffffffc02019ee:	97de                	add	a5,a5,s7
ffffffffc02019f0:	639c                	ld	a5,0(a5)
ffffffffc02019f2:	cb99                	beqz	a5,ffffffffc0201a08 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02019f4:	86be                	mv	a3,a5
ffffffffc02019f6:	00001617          	auipc	a2,0x1
ffffffffc02019fa:	f0a60613          	addi	a2,a2,-246 # ffffffffc0202900 <buddy_pmm_manager+0x598>
ffffffffc02019fe:	85a6                	mv	a1,s1
ffffffffc0201a00:	854a                	mv	a0,s2
ffffffffc0201a02:	0ce000ef          	jal	ra,ffffffffc0201ad0 <printfmt>
ffffffffc0201a06:	b34d                	j	ffffffffc02017a8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201a08:	00001617          	auipc	a2,0x1
ffffffffc0201a0c:	ee860613          	addi	a2,a2,-280 # ffffffffc02028f0 <buddy_pmm_manager+0x588>
ffffffffc0201a10:	85a6                	mv	a1,s1
ffffffffc0201a12:	854a                	mv	a0,s2
ffffffffc0201a14:	0bc000ef          	jal	ra,ffffffffc0201ad0 <printfmt>
ffffffffc0201a18:	bb41                	j	ffffffffc02017a8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201a1a:	00001417          	auipc	s0,0x1
ffffffffc0201a1e:	ece40413          	addi	s0,s0,-306 # ffffffffc02028e8 <buddy_pmm_manager+0x580>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a22:	85e2                	mv	a1,s8
ffffffffc0201a24:	8522                	mv	a0,s0
ffffffffc0201a26:	e43e                	sd	a5,8(sp)
ffffffffc0201a28:	0fc000ef          	jal	ra,ffffffffc0201b24 <strnlen>
ffffffffc0201a2c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201a30:	01b05b63          	blez	s11,ffffffffc0201a46 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201a34:	67a2                	ld	a5,8(sp)
ffffffffc0201a36:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a3a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201a3c:	85a6                	mv	a1,s1
ffffffffc0201a3e:	8552                	mv	a0,s4
ffffffffc0201a40:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a42:	fe0d9ce3          	bnez	s11,ffffffffc0201a3a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a46:	00044783          	lbu	a5,0(s0)
ffffffffc0201a4a:	00140a13          	addi	s4,s0,1
ffffffffc0201a4e:	0007851b          	sext.w	a0,a5
ffffffffc0201a52:	d3a5                	beqz	a5,ffffffffc02019b2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a54:	05e00413          	li	s0,94
ffffffffc0201a58:	bf39                	j	ffffffffc0201976 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201a5a:	000a2403          	lw	s0,0(s4)
ffffffffc0201a5e:	b7ad                	j	ffffffffc02019c8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201a60:	000a6603          	lwu	a2,0(s4)
ffffffffc0201a64:	46a1                	li	a3,8
ffffffffc0201a66:	8a2e                	mv	s4,a1
ffffffffc0201a68:	bdb1                	j	ffffffffc02018c4 <vprintfmt+0x156>
ffffffffc0201a6a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201a6e:	46a9                	li	a3,10
ffffffffc0201a70:	8a2e                	mv	s4,a1
ffffffffc0201a72:	bd89                	j	ffffffffc02018c4 <vprintfmt+0x156>
ffffffffc0201a74:	000a6603          	lwu	a2,0(s4)
ffffffffc0201a78:	46c1                	li	a3,16
ffffffffc0201a7a:	8a2e                	mv	s4,a1
ffffffffc0201a7c:	b5a1                	j	ffffffffc02018c4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201a7e:	9902                	jalr	s2
ffffffffc0201a80:	bf09                	j	ffffffffc0201992 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201a82:	85a6                	mv	a1,s1
ffffffffc0201a84:	02d00513          	li	a0,45
ffffffffc0201a88:	e03e                	sd	a5,0(sp)
ffffffffc0201a8a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201a8c:	6782                	ld	a5,0(sp)
ffffffffc0201a8e:	8a66                	mv	s4,s9
ffffffffc0201a90:	40800633          	neg	a2,s0
ffffffffc0201a94:	46a9                	li	a3,10
ffffffffc0201a96:	b53d                	j	ffffffffc02018c4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201a98:	03b05163          	blez	s11,ffffffffc0201aba <vprintfmt+0x34c>
ffffffffc0201a9c:	02d00693          	li	a3,45
ffffffffc0201aa0:	f6d79de3          	bne	a5,a3,ffffffffc0201a1a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201aa4:	00001417          	auipc	s0,0x1
ffffffffc0201aa8:	e4440413          	addi	s0,s0,-444 # ffffffffc02028e8 <buddy_pmm_manager+0x580>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201aac:	02800793          	li	a5,40
ffffffffc0201ab0:	02800513          	li	a0,40
ffffffffc0201ab4:	00140a13          	addi	s4,s0,1
ffffffffc0201ab8:	bd6d                	j	ffffffffc0201972 <vprintfmt+0x204>
ffffffffc0201aba:	00001a17          	auipc	s4,0x1
ffffffffc0201abe:	e2fa0a13          	addi	s4,s4,-465 # ffffffffc02028e9 <buddy_pmm_manager+0x581>
ffffffffc0201ac2:	02800513          	li	a0,40
ffffffffc0201ac6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201aca:	05e00413          	li	s0,94
ffffffffc0201ace:	b565                	j	ffffffffc0201976 <vprintfmt+0x208>

ffffffffc0201ad0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ad0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201ad2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ad6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201ad8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ada:	ec06                	sd	ra,24(sp)
ffffffffc0201adc:	f83a                	sd	a4,48(sp)
ffffffffc0201ade:	fc3e                	sd	a5,56(sp)
ffffffffc0201ae0:	e0c2                	sd	a6,64(sp)
ffffffffc0201ae2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201ae4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201ae6:	c89ff0ef          	jal	ra,ffffffffc020176e <vprintfmt>
}
ffffffffc0201aea:	60e2                	ld	ra,24(sp)
ffffffffc0201aec:	6161                	addi	sp,sp,80
ffffffffc0201aee:	8082                	ret

ffffffffc0201af0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201af0:	4781                	li	a5,0
ffffffffc0201af2:	00004717          	auipc	a4,0x4
ffffffffc0201af6:	51e73703          	ld	a4,1310(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201afa:	88ba                	mv	a7,a4
ffffffffc0201afc:	852a                	mv	a0,a0
ffffffffc0201afe:	85be                	mv	a1,a5
ffffffffc0201b00:	863e                	mv	a2,a5
ffffffffc0201b02:	00000073          	ecall
ffffffffc0201b06:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201b08:	8082                	ret

ffffffffc0201b0a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201b0a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201b0e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201b10:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201b12:	cb81                	beqz	a5,ffffffffc0201b22 <strlen+0x18>
        cnt ++;
ffffffffc0201b14:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201b16:	00a707b3          	add	a5,a4,a0
ffffffffc0201b1a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201b1e:	fbfd                	bnez	a5,ffffffffc0201b14 <strlen+0xa>
ffffffffc0201b20:	8082                	ret
    }
    return cnt;
}
ffffffffc0201b22:	8082                	ret

ffffffffc0201b24 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201b24:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b26:	e589                	bnez	a1,ffffffffc0201b30 <strnlen+0xc>
ffffffffc0201b28:	a811                	j	ffffffffc0201b3c <strnlen+0x18>
        cnt ++;
ffffffffc0201b2a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b2c:	00f58863          	beq	a1,a5,ffffffffc0201b3c <strnlen+0x18>
ffffffffc0201b30:	00f50733          	add	a4,a0,a5
ffffffffc0201b34:	00074703          	lbu	a4,0(a4)
ffffffffc0201b38:	fb6d                	bnez	a4,ffffffffc0201b2a <strnlen+0x6>
ffffffffc0201b3a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201b3c:	852e                	mv	a0,a1
ffffffffc0201b3e:	8082                	ret

ffffffffc0201b40 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b40:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b44:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b48:	cb89                	beqz	a5,ffffffffc0201b5a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201b4a:	0505                	addi	a0,a0,1
ffffffffc0201b4c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b4e:	fee789e3          	beq	a5,a4,ffffffffc0201b40 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b52:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201b56:	9d19                	subw	a0,a0,a4
ffffffffc0201b58:	8082                	ret
ffffffffc0201b5a:	4501                	li	a0,0
ffffffffc0201b5c:	bfed                	j	ffffffffc0201b56 <strcmp+0x16>

ffffffffc0201b5e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201b5e:	c20d                	beqz	a2,ffffffffc0201b80 <strncmp+0x22>
ffffffffc0201b60:	962e                	add	a2,a2,a1
ffffffffc0201b62:	a031                	j	ffffffffc0201b6e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201b64:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201b66:	00e79a63          	bne	a5,a4,ffffffffc0201b7a <strncmp+0x1c>
ffffffffc0201b6a:	00b60b63          	beq	a2,a1,ffffffffc0201b80 <strncmp+0x22>
ffffffffc0201b6e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201b72:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201b74:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201b78:	f7f5                	bnez	a5,ffffffffc0201b64 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b7a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201b7e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b80:	4501                	li	a0,0
ffffffffc0201b82:	8082                	ret

ffffffffc0201b84 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201b84:	ca01                	beqz	a2,ffffffffc0201b94 <memset+0x10>
ffffffffc0201b86:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201b88:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201b8a:	0785                	addi	a5,a5,1
ffffffffc0201b8c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201b90:	fec79de3          	bne	a5,a2,ffffffffc0201b8a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201b94:	8082                	ret
