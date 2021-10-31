---
title: MIT 6.828 Lab 1 - Booting a PC
author: qiaoin
date: '2019-04-07'
slug: mit-6-828-lab-1-booting-a-pc
categories:
  - 操作系统
  - 公开课
tags: []
---

> 重学操作系统系列，MIT 6.828 课程实验

---

{{< toc >}}

---

> [Lab1: Booting a PC](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/)
>
> - 【实验一于2019年4月3日开始做，环境配置及 Exercises，于4月6日完成，初稿报告4月7日】
> - 【2019年11月2日 第一次 review，发现了很多地方描述不清楚，需要补充上学习操作系统遇到的问题，痛点是什么？】
> - 【TODO】完善 lab1 实验笔记，只剩下 ex12 符号表部分内容

实验分为三个部分：

- 1）`bootstrap` 执行流程，熟悉 x86 汇编，QEMU x86 模拟器，PC's power；
- 2）`lab/boot` 目录，bootloader；
- 3）`lab/kernel` 目录，JOS 内核初始化模块。

## Part 1: PC Bootstrap

---

> **Exercise 1**：熟悉内联汇编。

---

阅读 [Brennan's Guide to Inline Assembly](http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html)，JOS 里面会使用 AT&T 语法。另外还有更详细的参考资料：

- [80386 Programmer's Reference Manual](https://pdos.csail.mit.edu/6.828/2018/readings/i386/toc.htm) 包含在 6.828 中将要使用到的所有处理器特性的介绍；
- [IA-32 Intel Architecture Software Developer's Manuals](https://software.intel.com/en-us/articles/intel-sdm)；
- [AMD64 Architecture Programmer's Manual](https://developer.amd.com/resources/developer-guides-manuals/)；
- 推荐阅读 [最牛 X 的 GCC 内联汇编](https://www.linuxprobe.com/gcc-how-to.html)，查看更完整的内容，整理的内容足够阅读内联汇编代码。

**【准备工作】为了进行下面的实验，需要进行一些配置**：

1. 按照 [Tools Used in 6.828](https://pdos.csail.mit.edu/6.828/2018/tools.html) 进行配置，macOS 需要按照网页说明安装定制化的 QEMU 模拟器：
    - 安装 QEMU 的依赖文件，`brew install $(brew deps qemu)`；
    - 安装定制的 QEMU，假设安装在用户主目录下的 `~/opt/` 下，即 `./configure` 时指定 `--prefix=/Users/xxxx/opt`；
    - Install 步骤 `PATH=${PATH}:/usr/local/opt/gettext/bin make install`；
2. 安装 `i386` 相关依赖包 `brew install i386-elf-binutils i386-elf-gcc i386-elf-gdb`；
3. 不修改各个实验的 Makefile，转而修改用户主目录（`~`）下的 `.zshenv` (或者对应的 `.bashrc`)，这是对当前用户环境变量的全局修改：
    - 找到 QEMU 可执行文件，`export PATH="/Users/xxxx/opt/bin:$PATH"`；
    - 添加 `GCCPREFIX`，`export GCCPREFIX="i386-elf-"`；
    - 添加 `gdb` 同名，`alias gdb="i386-elf-gdb"`。

---

> **Exercise 2**：使用 GDB 进行调试，跟踪 ROM BIOS 指令的执行。

---

1. 打开两个终端，`cd ~/6.828/lab`，到达相同的目录；
2. 一个终端启动 QEMU 模拟器的 GDB 模式执行 `make qemu-nox-gdb`，QEMU 在第一条指令之前暂停，等待 GDB 的连接；
3. 另一个终端执行 `gdb`（这里不是如 [Lab 1](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/) 官网说明的执行 `make gdb`，而是执行 `gdb`，需要注意）。

最开始是一条跳转指令，跳转到 `0xfe05b` 进行执行：

```c
[f000:fff0]    0xffff0:  ljmp   $0xf000,$0xe05b  # 跳转指令
```

使用 `si` 单步执行：

```c
[f000:d15f]    0xfd15f:   cli                    # 关闭中断
[f000:d171]    0xfd171:   lidtw  %cs:0x6ab8
[f000:d177]    0xfd177:   lgdtw  %cs:0x6a74      #
[f000:d17d]    0xfd17d:   mov    %cr0,%eax
[f000:d180]    0xfd180:   or     $0x1,%eax
[f000:d184]    0xfd184:   mov    %eax,%cr0       # cr0 最低位置 0
```

BIOS 建立中断描述符表和初始化一系列硬件设备，进行一些检验工作，之后搜索可启动的设备，**加载该存储设备上的第一个扇区的 512 字节到内存的 0x7C00**（这是 BIOS 固件完成的），然后跳转到 `@0x7C00` 的第一条指令开始执行（**将控制权转移给 bootloader**）。

设置断点在 `0x7c00`，`b *0x7c00`，继续执行 `c(ontinue)`：

```c
[   0:7c00] => 0x7c00:    cli
[   0:7c01] => 0x7c01:    cld

[   0:7c1e] => 0x7c1e:    lgdtw  0x7c64
[   0:7c23] => 0x7c23:    mov    %cr0,%eax
[   0:7c26] => 0x7c26:    or     $0x1,%eax
[   0:7c2a] => 0x7c2a:    mov    %eax,%cr0
[   0:7c2d] => 0x7c2d:    ljmp   $0x8,$0x7c32
```

执行 `x/Ni ADDR` 打印从 `ADDR` 地址开始的连续 `N` 条汇编指令（以上关于 BIOS 的部分不是 6.828 重点关注的部分，执行时单步跟踪能够看出一点端倪，具体在 lab 实验目录中没有源码对应）。

## Part 2: The Boot Loader

`bootloader` 主要做三件事：

- 1）从实模式（real mode）切换到保护模式（32-bit protected mode）。在实模式下只能寻址 1MB 的内存空间（2^20），在保护模式下能够寻址 4GB（2^32），这样就能够访问处理器全部的物理内存空间；
- 2）读取内核映像到内存中固定位置，ELF 文件格式（解析 ELF 文件，将内核需要加载进入内存的段 <有 LOAD 标记的段> 加载进内存，放置在指定的加载地址）；
- 3）把控制权转移给 JOS，即将 `CS:EIP` 的值指向操作系统内核所在内存中的起始点（`.text` 段中程序开始执行时的起始地址）。

两个源文件代码的阅读：

- **`boot/boot.S`**：执行 `start` 函数，进行一定的初始化，完成从实模式到保护模式的切换（`CR0` 最低位设置为 1），并调用 `bootmain` 函数，具体细节参见 `bootloader` 实模式切换到保护模式（Google 一下）；
- **`boot/main.c`**：`bootloader` 让 CPU 进入保护模式后，下一步的工作就是**从硬盘上加载并运行 OS**。考虑到实现的简单性，`bootloader` 访问硬盘都是 LBA 模式 的 **PIO**（Program IO）方式，即**所有的 IO 操作是通过 CPU 访问硬盘的 IO 地址寄存器完成**。当前硬盘数据是储存到硬盘扇区中，一个扇区大小为 512 字节。读一个扇区的流程（可参看 `readsect` 函数实现，大致理解就可以）大致如下：
    1. 等待磁盘准备好；
    2. 发出读取扇区的命令；
    3. 等待磁盘准备好；
    4. 把磁盘扇区数据读到指定内存。

主要查看 `bootmain` 函数实现：

```c
#define SECTSIZE    512                      // 扇区大小 512 字节
#define ELFHDR      ((struct Elf *) 0x10000) // 将 0x10000 设置为内核起始地址

void bootmain(void)
{
    struct Proghdr *ph, *eph;

    // 从硬盘的第一个扇区（偏移为 0）读取 8*512=4096byte （4KB）的内容到内存单元 ELFHDR 处
    readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);  // 1.

    // is this a valid ELF?
    if (ELFHDR->e_magic != ELF_MAGIC)
        goto bad;

    // load each program segment (ignores ph flags)
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);  // 2.
    eph = ph + ELFHDR->e_phnum;  // program header 的个数
    for (; ph < eph; ph++)
        // p_pa is the load address of this segment (as well
        // as the physical address)
        readseg(ph->p_pa, ph->p_memsz, ph->p_offset);  // 3.

    // call the entry point from the ELF header
    // note: does not return!
    ((void (*)(void)) (ELFHDR->e_entry))();  // 4.
}
```

关键的几行代码已经标注序号，需要结合下面 ELF 文件格式来进行理解。

1. 将 kernel 从磁盘中读取到内存的指定位置 `ELFHDR`，`0x10000`；
2. 对 `ELFHDR` 处的 ELF header 进行解析，得到 program header table 的起始地址存放在 `ph` 中，结束地址存放在 `eph` 中。这里将 `ELFHDR` 进行转型为 `uint8_t` 指针，这样在进行指针加法时，这个指针变量按照 byte 的偏移来加，得到 program header table 的起始地址，并转换为 `struct Proghdr` 类型指针：

    ```c
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    ```

3. 根据每个 program header 的信息从磁盘读取各个段进入内存指定位置，从 `ph->p_offset` 处开始拷贝 `ph->p_memsz` 个 bytes 到 `ph->p_pa`：

    ```c
    readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    ```

4. 在将内核加载到内存中后，转移到 entry point 开始执行，即 JOS 开始运行时要执行的第一条指令的地址。这里将 `e_entry` 转换为一个无参数无返回值的函数，并执行函数调用：

    ```c
    ((void (*)(void)) (ELFHDR->e_entry))();
    ```

---

> **Exercise 3**：使用 GDB 单步跟踪执行。

---

设置断点在 `0x7c00`，`b *0x7c00`，另外还设置两个断点：

- 1）`b *0x7d56`，`bootmain` 函数 `for` 循环开始处；
- 2）`b *0x7d71`，ELF 调用 entry point 处。

继续执行 `c(ontinue)`，就可以看到 `for` 循环处的断点 hit 3 次（最后一次是判断 `for` 循环条件不成立），说明根据 ELF header 信息读入了另外 2 个段（`.text`/`.data`，可以使用 `i386-elf-objdump -x obj/kern/kernel` 命令查看到 Program Header）。执行到达 `0x7d71` 处时，对应汇编指令为：

```c
0x7d71: call   *0x10018
```

但 `si` 单步执行的真实地址为 `0x10000c`：

```c
(gdb) x/10i 0x10000c
=> 0x10000c:    movw   $0x1234,0x472
   0x100015:    mov    $0x110000,%eax
   0x10001a:    mov    %eax,%cr3
   0x10001d:    mov    %cr0,%eax
   0x100020:    or     $0x80010001,%eax
   0x100025:    mov    %eax,%cr0
   0x100028:    mov    $0xf010002f,%eax
   0x10002d:    jmp    *%eax                <- 0xf010002f <relocated>
   0x10002f:    mov    $0x0,%ebp
   0x100034:    mov    $0xf0110000,%esp
```

回答以下 4 个问题：

1. 在哪个时间点处理器开始执行 32-bit 代码？导致从 16-bit 切换到 32-bit 的关键操作是什么？

    使能保护模式（置 `CR0` 最低位为 1）和段机制（建立好全局描述符表 `GDT`）。执行一条长跳转指令 `ljmp cs:eip` 转而执行 32-bit 模式。

2. `bootloader` 执行的最后一条指令是什么？kernel 在加载之后，执行的第一条指令是什么？

    ```c
    call   *0x10018
    0x10000c:  movw   $0x1234,0x472
    ```

    这两个地址不相同，这是为什么？因为开启了**分页机制**，虚拟地址与物理地址之间的映射关系已建立好。

3. kernel 执行的第一条指令的地址是多少？

    `0x10000c`

4. 为了将整个 kernel 从磁盘加载到内存中，`bootloader` 是如何确定需要读入的扇区数目的？这些信息存储在哪里？

    ```c
    // load each program segment (ignores ph flags)
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);  // ii
    eph = ph + ELFHDR->e_phnum;

    for (; ph < eph; ph++)
        // p_pa is the load address of this segment (as well
        // as the physical address)
        readseg(ph->p_pa, ph->p_memsz, ph->p_offset);  // 3.
    ```

    在 ELF 文件的 program header 中包含总共需要读取的数据大小，同时对于需加载进内存中的各个段，也标注了在磁盘上的偏移位置和大小。
  
---

> **Exercise 4**：C 语言中的指针。

---

C 程序设计语言 第 5 章 数组与指针 5.1 - 5.5（待读，之前已经看过好几遍了）。

### ELF 文件格式

> （没有很明白，20191102晚上11点57分）

ELF header + 待加载的信息（包含连续的多个段，数据段和代码段等，这些段需要从磁盘加载到内存的指定地址）。`bootloader` 不会去修改数据段和代码段，只是将它们加载进内存，然后将控制权转移给这些程序进行执行。

ELF header 长度固定（fixed-length），后跟可变长度（variable-length）的 program header，列出了要加载的各个程序段（program sections）。`inc/elf.h` 定义了 `ELF header`：

```c
struct Elf {            // ELF 文件头
    uint32_t e_magic;   // must equal ELF_MAGIC
    uint8_t e_elf[12];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint32_t e_entry;   // 程序开始执行的起始地址
    uint32_t e_phoff;   // program header table 的起始位置
    uint32_t e_shoff;   // section header 的起始位置
    uint32_t e_flags;
    uint16_t e_ehsize;  // ELF 文件本身的大小
    uint16_t e_phentsize;
    uint16_t e_phnum;   // program header 的个数
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
};

struct Proghdr {        // program header table
    uint32_t p_type;
    uint32_t p_offset;
    uint32_t p_va;      // 虚拟地址
    uint32_t p_pa;      // 物理地址
    uint32_t p_filesz;  // 段在文件中的大小
    uint32_t p_memsz;   // 段在内存中的大小
    uint32_t p_flags;   // 读写执行权限
    uint32_t p_align;
};
```

【TODO】这里为什么需要 `p_filesz`、`p_memsz` 两个长度呢？在之后会介绍到，`.bss` 在磁盘上没有存储空间，在内存中程序需要为其分配空间。

`bootloader` 利用 ELF program header 来决定如何加载各 program sections，而 program header 指定应该读取 ELF 对象的哪个部分进内存，以及应该放在哪里。

![elf-layout](images/elf-layout.png)

在 6.828 实验中将用到的 program sections：

- **`.text`**：代码段。程序的可执行指令；
- `.rodata`：只读数据段。例如 C 编译器产生的 ASCII 字符串常量；
- **`.stab`**：符号表部分，在程序报错时提供错误信息；
- **`.stabstr`**：符号表字符串部分；
- **`.data`**：数据段。已初始化的全局变量和局部静态变量；
- `.bss`：为未初始化的全局变量和局部静态变量预留位置，但并没有内容，因此在文件中也不占据磁盘空间（因此需要 `p_filesz`、`p_memsz` 两个长度）。由于未初始化的全局变量和局部静态变量默认值都是 0，本来它们也可以被放在 `.data` 段里，但是因为它们都是 0，为它们在 `.data` 段分配空间并存放数据 0 是没有必要的；
- ...

```c
i386-elf-objdump -h obj/kern/kernel

obj/kern/kernel:     file format elf32-i386
Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         0000171e  f0100000  00100000  00001000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata       00000714  f0101720  00101720  00002720  2**5
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         000040ed  f0101e34  00101e34  00002e34  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .stabstr      00001957  f0105f21  00105f21  00006f21  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .data         0000a300  f0108000  00108000  00009000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  5 .bss          00000648  f0112300  00112300  00013300  2**5
                  CONTENTS, ALLOC, LOAD, DATA
  6 .debug ......
  ......
```

得到 ELF 文件各个段的基本信息，可以知道很多段都是 Debug 信息（program loader 不会将这些段加载进内存）。

查看更详细的信息：

```c
i386-elf-objdump -x obj/kern/kernel

obj/kern/kernel:     file format elf32-i386
obj/kern/kernel
architecture: i386, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x0010000c

Program Header:
    LOAD off    0x00001000 vaddr 0xf0100000 paddr 0x00100000 align 2**12
         filesz 0x00007878 memsz 0x00007878 flags r-x
    LOAD off    0x00009000 vaddr 0xf0108000 paddr 0x00108000 align 2**12
         filesz 0x0000a948 memsz 0x0000a948 flags rw-

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         0000171e  f0100000  00100000  00001000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata       ...
  2 .stab         ...
  3 .stabstr      ...
  4 .data         0000a300  f0108000  00108000  00009000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  ......
```

对于内核映像，其链接地址和加载地址不同，内核希望 `bootloader` 将其加载到低物理地址处（**`0x00100000`** 最下面的 `1MB` 处），但是期望在高地址（虚拟地址）处进行执行（**`0xf0100000`**）。这里带标识 `LOAD` 的 Program Header 段（可能一个段包含多个 Sections，`.data`/`.text`/etc.），即多个 Sections 被同时加载进入内存。

### 链接地址和加载地址（link address and load address）

我们关注 `.text` 段的 `VMA`(or link address，虚拟地址) 和 `LMA`(or load address，物理地址)。段的 `LMA`(load address)指定了将这个段加载进内存时需要放置的物理地址。段的 `VMA`(link address)指定了程序执行时这个段需要放置在内存中的虚拟地址。为了保证程序能够正常的执行，需要进行链接。

**链接地址实际上就是程序假设自己在内存中被存放的位置，即编译器在编译的时候会认定程序将会连续的存放在从链接地址起始处开始的内存空间。而加载地址是可执行程序在物理内存中真正存放的位置**，在 JOS 中，`bootloader` 是被 BIOS 装载到内存的，由于 BIOS 实际上规定 `bootloader` 要被存放在物理内存的 `0x7c00` 处，于是不论程序的链接地址怎么改变，它装载在内存中的位置（加载地址）都不会变化。

**链接地址是指令运行时的地址，加载地址是指令加载到内存中的地址。实模式下这两个地址是一样的，因为没有开启分页机制，指令执行的时候就没有地址映射关系**。

我们可以看到 `bootloader` 的链接地址和加载地址是相等的，为 `0x7c00`：

```c
i386-elf-objdump -h obj/boot/boot.out

obj/boot/boot.out:     file format elf32-i386
Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         0000018c  00007c00  00007c00  00000054  2**2
                  CONTENTS, ALLOC, LOAD, CODE
  1 .eh_frame     0000009c  00007d8c  00007d8c  000001e0  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         00000744  00000000  00000000  0000027c  2**2
                  CONTENTS, READONLY, DEBUGGING
  3 .stabstr      000008e1  00000000  00000000  000009c0  2**0
                  CONTENTS, READONLY, DEBUGGING
  4 .comment      00000011  00000000  00000000  000012a1  2**0
                  CONTENTS, READONLY
```

---

> **Exercise 5**：修改 `boot/Makefrag`，将 bootloader 的 link address 改为非 `0x7c00` 的数值，看看会出现什么问题？

---

在 `boot/Makefrag` 中指定了 `bootloader` 的链接地址 `-Ttext 0x7C00`，现在我们将链接地址修改为 `0x8C00`，重新编译：

1. 设置断点 `b *0x7c00`，BIOS 一定会将 `bootloader` 加载到这个位置；
2. `si` 单步跟踪执行，执行到 `0x7c2d: ljmp $0x8,$0x8c32` 指令时发生错误；
3. 查看编译同时生成的反汇编文件 `obj/boot/boot.asm`，其中显示了汇编指令和相应的链接地址，由于我们修改了 bootloader 的链接地址为 `0x8c00`，`“ljmp   $0x8,$0x8c32”` 这条指令在 `boot.asm` 文件中显示的实际汇编地址为 `0x8c2d`，其后的 `protcseg` 标识的指令的链接地址为 `0x8c32`，即 `si` 单步执行到 `0x8c2d` 处需要跳转到的标识符地址；
4. CPU 报错？为什么会报错呢？链接是怎么做的？

`VMA`/`LMA` 是给加载器做参考，告诉加载器“需要将某个段加载到某某地址”，但现在连操作系统都还没有运行起来，更不会有加载器。因此，`bootloader` 的源代码还是会被加载到内存的 `0x7c00` 处（因为 BIOS 在 ROM，里面的程序代码是在出厂时就已经规定好了的，将磁盘的第一个扇区加载到内存的 `0x7c00` 处）。链接最重要的一步是符号重定位（symbol relocation），在源代码 `boot/boot.S` 中：

```c
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
```

这里的 `protcseg` 符号（symbol）用来标记位置，可以是一段子程序的起始地址，也可以是一个变量的起始地址。在这里 `protcseg` 表示一段程序的起始地址，在编译生成可重定位目标文件（relocatable object file）时其值是不确定的。在链接时，链接器会对这些符号进行替换（因为程序已经链接好了）。

现在的问题是，链接器按照 `0x8C00` 的链接起始地址对这些符号进行替换，但 BIOS 还是将 bootloader 读到了内存中的 `0x7C00` 处，实模式下（仅开启了段机制），加载地址和链接地址应该是相同的。而现在，`ljmp` 指令要跳转到 `0x8c32` 处，本来应该跳转到下一条指令 `0x7c32` 处。【TODO 需要更加细致的分析！】

```c
(gdb) x/10i 0x7c1e
   0x7c1e: lgdtw  -0x739c
   0x7c23: mov    %cr0,%eax
   0x7c26: or     $0x1,%eax
   0x7c2a: mov    %eax,%cr0
=> 0x7c2d: ljmp   $0x8,$0x8c32
   0x7c32: mov    $0xd88e0010,%eax
   0x7c38: mov    %ax,%es
   0x7c3a: mov    %ax,%fs
   0x7c3c: mov    %ax,%gs
   0x7c3e: mov    %ax,%ss
```

---

> **Exercise 6**：执行 `x/Nx ADDR` 打印从 `ADDR` 开始的 `N` 个 word（在 GNU 汇编标准中，1 word = 2 bytes）。在两个不同的时刻检查 `0x00100000` 出的 8 个 word，1）BIOS 将控制权转移给 `bootloader` 和 2）`bootloader` 将 JOS 内核映像读入内存之后，将控制权转移给 JOS（entry point），有什么不一样，并且为什么这 8 个 word 会不一样？

---

1. 关闭 QEMU 和 GDB，重新运行；
2. 设置断点 `b *0x7c00`（BIOS 将控制权转移给 `bootloader`）和 `b *0x7d71`（`bootloader` 将控制权转移给 JOS）。

![ex-6](images/ex-6.png)

前后两次执行 `x/Nx ADDR` 结果不一样，第二次是因为我们使用 `bootloader` 将 JOS 的程序段（Program Header 中有 `LOAD` 标记的段）加载到了 `0x100000` 处，因此，从 `0x100000` 开始都存放着 **JOS 内核映像**。

## Part 3：The Kernel

操作系统内核一般链接地址都比较大，会选择在高虚拟地址空间上运行，将低虚拟地址空间留给用户程序使用（在 Lab2 中会进行更清晰的解释）。

很多机器的物理内存空间地址都不会到达 **`0xf010002f`**，因此 JOS 内核映像不会真实存储于此，而是，我们使用处理器的内存管理硬件（memory management hardware）将高虚拟地址空间 **`0xf0100000`**（内核的链接地址，期望运行的虚拟地址）映射到实际的低物理地址空间 **`0x00100000`**（内核的加载地址，`bootloader` 将内核映像加载进内存中的地址），`bootloader` 加载磁盘上的内核映像存放在内存中的地址为 **`0x00100000`**（刚好在 BIOS ROM 的上面，从 1MB 地址往上），可以查看命令 `i386-elf-objdump -x obj/kern/kernel` 的返回内容。

`kern/entrypgdir.c` 中已经建立好了虚拟地址和物理地址的映射关系 `entry_pgdir`：

- Map VA's [0, 4MB) to PA's [0, 4MB)
- Map VA's [`KERNBASE`, `KERNBASE`+4MB) to PA's [0, 4MB) 其中，`KERNBASE=0xF0000000`

在 `kern/entry.S` 中会对 `CR0_PG` flag 进行设置，在此设置之前，代码中对内存的引用（memory references）都会被解释为物理地址（更准确的说是线性地址，在 `boot/boot.S` 中仅开启段机制，线性地址与物理地址相等），当对 `CR0_PG` 设置之后，对内存的引用将被解释为虚拟地址（即开启页机制），再由 `entry_pgdir` 翻译为对应的物理地址：

- 将 `0xf0000000 ~ 0xf0400000` 虚拟地址翻译为对应的物理地址 `0x00000000 ~ 0x00400000`
- 将 `0x00000000 ~ 0x00400000` 虚拟地址翻译为对应的物理地址 `0x00000000 ~ 0x00400000`

在内核被加载到内存后系统便立即跳转开始执行 `kern/entry.S` 的代码，这个文件中的程序相当于内核的入口程序：

```c
.globl      _start
_start = RELOC(entry)

.globl entry
entry:
    movw    $0x1234,0x472           # warm boot

    # We haven't set up virtual memory yet, so we're running from
    # the physical address the boot loader loaded the kernel at: 1MB
    # (plus a few bytes).  However, the C code is linked to run at
    # KERNBASE+1MB.  Hence, we set up a trivial page directory that
    # translates virtual addresses [KERNBASE, KERNBASE+4MB) to
    # physical addresses [0, 4MB).  This 4MB region will be
    # sufficient until we set up our real page table in mem_init
    # in lab 2.

    # Load the physical address of entry_pgdir into cr3.  entry_pgdir
    # is defined in entrypgdir.c.
    movl    $(RELOC(entry_pgdir)), %eax
    movl    %eax, %cr3
    # Turn on paging. 开启页机制
    movl    %cr0, %eax
    orl $(CR0_PE|CR0_PG|CR0_WP), %eax
    movl    %eax, %cr0

    # Now paging is enabled, but we're still running at a low EIP
    # (why is this okay?).  Jump up above KERNBASE before entering
    # C code.
    mov $relocated, %eax  # $relocated 为链接地址，因此需要重定位
    jmp *%eax
relocated:

    # Clear the frame pointer register (EBP)
    # so that once we get into debugging C code,
    # stack backtraces will be terminated properly.
    movl    $0x0,%ebp           # nuke frame pointer

    # Set the stack pointer
    movl    $(bootstacktop),%esp

    # now to C code
    call    i386_init
```

---

> **Exercise 7**：使用 QEMU 和 GDB 单步跟踪 JOS，执行到 `movl %eax, %cr0`，检查在执行这条汇编指令前后内存单元 `0x00100000` 和 `0xf0100000` 的内容。

---

1. 设置断点 `b *0x7d71`（`bootloader` 将控制权转移给 JOS）；
2. `si` 单步跟踪执行。

```c
=> 0x100025:    mov    %eax,%cr0
(gdb) x/8x 0x00100000
0x100000:                       0x1badb002 0x00000000 0xe4524ffe 0x7205c766
0x100010:                       0x34000004 0x0000b812 0x220f0011 0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>: 0x00000000 0x00000000 0x00000000 0x00000000
0xf0100010 <entry+4>:           0x00000000 0x00000000 0x00000000 0x00000000
(gdb) si
=> 0x100028:    mov    $0xf010002f,%eax
(gdb) x/8x 0x00100000
0x100000:                       0x1badb002 0x00000000 0xe4524ffe 0x7205c766
0x100010:                       0x34000004 0x0000b812 0x220f0011 0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>: 0x1badb002 0x00000000 0xe4524ffe 0x7205c766
0xf0100010 <entry+4>:           0x34000004 0x0000b812 0x220f0011 0xc0200fd8
```

执行 `mov %eax, %cr0` 之后，建立好了虚拟地址和物理地址的映射关系。如果将这条指令给注释掉，重新编译执行，同样设置断点，在 `0xf010002c <relocated>: add %al,(%eax)` 处 QEMU 出错退出，出错信息为：“qemu: fatal: Trying to execute code outside RAM or ROM at 0xf010002c”。

### `cprintf` 函数的实现（C 语言中常用的 `printf` 函数）

三个源文件代码的阅读：【TODO 分析并实现 `printf` 函数，包括实现浮点数打印】

- `kern/printf.c`：封装格式化输出函数，提供 `cprintf` 函数接口；
- `lib/printfmt.c`：格式化字符串输出，需好好学习这个源码文件；
- `kern/console.c`：实现基本的 I/O 操作，提供 `cputchar`/`getchar` 供 `readline`/`cprinf` 使用。

---

> **Exercise 8**：填充代码，支持使用 "%o" 打印八进制数（这个很简单，模仿着写，但需理解）。

---

```c
        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
            base = 8;
            goto number;
```

在 `kern/init.c i386_init()` 函数中添加测试代码。

### 栈

几条与栈相关的汇编指令解释：

| 汇编指令       | |解释           |
| ------------- |-| ------------- |
| `pushl %eax`    | ______ | `subl $4, %esp; movl %eax, (%esp)` |
| `popl %eax`     | ______ | `movl (%esp), %eax; addl $4, %esp` |
| `call 0x1234`   | ______ | `pushl %eip; movl 0x1234, %eip`    |
| `ret`           | ______ | `popl %eip`                        |

（注：这里为了解释清晰，右侧指令大都不规范。）

**栈的生长方向是高地址到低地址**，`esp` 指向栈顶（低地址），`ebp` 指向栈底（高地址）。

1. 当进入一个函数（`callee`）进行执行时，将调用者（`caller`）的 `ebp` 压入栈；
2. 给 `ebp` 赋新值为当前 `esp`（`ebp` 为 `callee` 的栈帧栈底）。

![my-func-enter-call](images/my-func-enter-call.png)

现在就建立好了一个**函数调用的链接关系**（类似链表），根据当前正在执行的函数找到 `ebp` 的值，其为一个地址，该地址中存储的值为调用者的 `ebp`：

```c
uint32_* ebp = (uint32_t*)read_ebp();  // 得到 callee 的 ebp
while (ebp) {  // 这里可以直接这样写，因为最开始给 ebp 初始化的值为 NULL
    ......     // 得到返回值和函数调用的参数，进行处理
    ebp = (uint32_t*)(*ebp);  // 对当前 ebp 存储地址解引用就能够得到存储的 caller 的 ebp
}
```

![stack-frame](images/stack-frame.png)

---

> **Exercise 9**：确定栈是怎么初始化的？

---

1. 设置断点 `b *0x7d71`，`si` 单步执行，对应的源码在 `kern/entry.S`；
2. 对 `CR0` 进行设置，开启分页机制，然后执行跳转到 `relocated` 标识处开始运行；
3. **将 `ebp` 设置为 `NULL`**（在进行函数调用栈分析的时候使用 `NULL` 作为结束标识），在 `.data` 段设置的栈顶地址给 `esp`（高地址，`0xf0110000`，虚拟地址），预留了栈空间。这里定义了两个全局变量 `bootstack` 和 `bootstacktop`，`bootstack` 标识了内存中的一个位置，表示从这里开始的 `KSTKSIZE` 个字节的区域都是属于这个临时堆栈的（`KSTKSIZE` 在 `inc/memlayout.h` 中定义为 32K），`bootstacktop` 指向这段区域后的第一个字节，由于刚开始堆栈是空的，所以栈顶便是 `bootstacktop` 所指向的位置【TODO 这里还是有点模糊】。

    ```c
        relocated:

            # Clear the frame pointer register (EBP)
            # so that once we get into debugging C code,
            # stack backtraces will be terminated properly.
            movl    $0x0,%ebp           # nuke frame pointer

            # Set the stack pointer
            movl    $(bootstacktop),%esp

            # now to C code
            call    i386_init

        .data
        # boot stack
           .p2align    PGSHIFT     # 强制四字节对齐
           .globl      bootstack
        bootstack:
            .space      KSTKSIZE
           .globl      bootstacktop
        bootstacktop:
    ```

4. 调用 `i386_init` 函数会将下一条指令的地址压入栈（spin，程序不会运行到这里），同时将旧的 `ebp` 压栈，`ebp` 指向 `esp` 的当前位置，这样就设置好了 JOS 调用第一个 C 函数的栈帧。

---

> **Exercise 10**：单步调试查看 `backtrace` 函数是怎么递归调用的？

---

`mon_backtrace` 函数是在 `test_backtrace` 函数中被调用的：

![recursion](images/recursion.png)

---

> **Exercise 11**：`mon_backtrace` 功能实现（查看函数调用栈），将 `backtrace` 功能加入 JOS monitor 中。

---

函数参数的入栈顺序是从右到左的，即对于函数参数，最后一个参数先入栈，从右至左，第一个参数最后入栈：

![func-args-push-order](images/func-args-push-order.png)

正在执行的函数有自己的一个 `ebp` 值，而这个 `ebp` 作为指针（对应的那块内存）又指向调用该函数的函数的 `ebp` 的值，即 **callee 的 `ebp` 作为指针指向 caller 的 `ebp` 值**。这样我们使用 `ebp` 不断回溯就能够打印出函数的调用栈了。

```c
int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
    size_t i;
    const size_t N = 4;
    uint32_t args[N];
    uint32_t* ebp = (uint32_t*)read_ebp();
    while(ebp) {             // 这个循环终止条件在 ex9 中有解释，movl $0x0,%ebp 
        uint32_t eip = *(ebp + 1);
        for (i = 0; i < N; ++i)
            args[i] = *(ebp + 2 + i);  // 依次得到各个参数
        cprintf("ebp %08x eip %08x args", ebp, eip);
        for (i = 0; i < N; ++i)
            cprintf(" %08x", args[i]);
        cprintf("\n");

        ebp = (uint32_t*) (*ebp);
    }

    return 0;
}
```

JOS 启动后会出现“`K>`”等待用户输入命令，已经提供了“`help`”和“`kerninfo`”两个，这里我们需要添加“`backtrace`”命令。实现原理：

```c
struct Command {
    const char *name;  // 命令名
    const char *desc;  // 命令作用，help 时展示
    // return -1 to force monitor to exit
    int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
    { "help", "Display this list of commands", mon_help },
    { "kerninfo", "Display information about the kernel", mon_kerninfo },
    { "backtrace", "Display stack backtrace", mon_backtrace },
};
```

在 `kern/monitor.c` 中定义一个 `Command` 结构体，包含能够使用的交互命令。主要是第三个参数，表示在 monitor 中键入命令时具体调用的处理函数。

当用户在 monitor 中键入命令时是如何进行处理的呢？

1. `monitor` 函数中调用 `readline` 读入一个命令，`buf` 指向命令字符串：

```c
while (1) {
    buf = readline("K> ");
    if (buf != NULL)
        if (runcmd(buf, tf) < 0)
            break;
}
```

2. `runcmd` 处理命令，接受两个参数，第一个就是命令字符串，第二个参数先不做讨论（跳过）。接下来分析 `runcmd` 函数的实现：（**这个函数实现要好好学习，Redis 中也有这样的命令查表操作**）

- i) 变量声明与初始化，`argv` 是一个指针数组，每个数组项指向一个字符串。一个命令分为命令名+命令参数，因此一个命令字符串一般可以分为多个子字符串，`argv` 的每个数组项指向一个子字符串。`argc` 代表命令参数的个数：

```c
#define WHITESPACE "\t\r\n "

static int runcmd(char *buf, struct Trapframe *tf)
{
    int argc;
    char *argv[MAXARGS];
    int i;

    // Parse the command buffer into whitespace-separated arguments
    argc = 0;
    argv[argc] = 0;
```

- ii) 在 `argv` 中保存每一个子字符串，并且将命令字符串中的空格都换成空字符（因为我们在输入命令是，命令名和参数之间、参数和参数之间都是使用空格间隔的），这样处理之后每个子字符串的结尾便都是一个空字符，方便处理；【这个实现需要好好学习】

```c
    while (1) {
        // gobble whitespace
        while (*buf && strchr(WHITESPACE, *buf))
            *buf++ = 0;    // 把所有空格字符都置为空字符
        if (*buf == 0)
            break;         // 命令结束

        // save and scan past next arg
        if (argc == MAXARGS-1) {
            cprintf("Too many arguments (max %d)\n", MAXARGS);
            return 0;
        }
        argv[argc++] = buf;// 指向子字符串
        while (*buf && !strchr(WHITESPACE, *buf))
            buf++;         // 跳过非空格的字符
    }
    argv[argc] = 0;
```

![runcmd-argv-argc](images/runcmd-argv-argc.png)

- iii) 获取到 `argc` 和 `argv` 两个参数后，就可以开始处理命令了。在所有可以执行的命令表中查找对应的函数，调用执行：

```c
    // Lookup and invoke the command
    if (argc == 0)  return 0;
    for (i = 0; i < ARRAY_SIZE(commands); i++) {
        if (strcmp(argv[0], commands[i].name) == 0)
            return commands[i].func(argc, argv, tf);
    }
    cprintf("Unknown command '%s'\n", argv[0]);
    return 0;
}
```

---

> **Exercise 12**：修改 `mon_backtrace` 使得其能够打印出当前所在的文件、行号和函数（更方便的查看函数调用栈，以及当程序出错时能够更方便的知道哪些函数可能存在 bug）。

---

【TODO】符号表理解，这个如何做的，通过查看 `debuginfo_eip` 函数实现大致知道怎么处理，但为什么是这样的呢？需要理解。

1. `debuginfo_eip` 函数中添加行号查找：

```c
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[lline].n_desc;
    } else {
        return -1;
    }
```

2. 在 `mon_trace` 函数中加入：

```c
    // 打印额外的信息：所在文件:行数:所在函数
    struct Eipdebuginfo info;
    if (debuginfo_eip(eip, &info) == 0)
        cprintf("    %s:%d: %.*s+%u\n", info.eip_file, info.eip_line,
            info.eip_fn_namelen, info.eip_fn_name,
            (uint32_t)(eip - info.eip_fn_addr));
    else
        cprintf("Error happened when reading symbol table\n");
```

## 总结遇到的问题

## References

- 主要参考 [系统启动与初始化](http://grid.hust.edu.cn/zyshao/Teaching_Material/OSEngineering/Chapter3.pdf)，为华科的一个老师的课程讲义，现地址已不能访问
- [程序员的自我修养：装载、链接与库](https://book.douban.com/subject/3652388/) 国人写的一本书，分析的很详细，很有实践意义
  - 第 2 章 编译与链接 2.4 模块拼装——静态链接
  - 第 3 章 目标文件里有什么
  - 第 4 章 静态链接
- [深入理解计算机系统](https://book.douban.com/subject/26912767/) 第 7 章 链接 之前看过好几遍，需要理解
- [Linux 内核应该怎么去学习？](https://www.zhihu.com/question/58121772/answer/156287959) 如陈硕所说，“学习操作系统要注意区分共性与平台特性”
- [C函数调用过程原理及函数栈帧分析](https://segmentfault.com/a/1190000007977460) 函数调用和栈帧讲解的很清晰
- [Using the GNU Debugger](https://pdos.csail.mit.edu/6.828/2018/lec/gdb_slides.pdf) MIT 6.828 LEC 3 课程讲义
- [mit6.828-lab1 系统启动](https://www.jianshu.com/p/af9d7eee635e) 简单的过了一遍，之后可以仔细梳理一下

## 附录

### 附录 1：`cprintf()` 函数的实现

```c
int cprintf(const char *fmt, ...)
{
    va_list ap;
    int cnt;

    va_start(ap, fmt);
    cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
```

这里引用 K&R 7.3 变长参数表，省略号表示参数表中的数量和类型是可变的，只能出现在参数表的尾部。如何去处理一个没有名字的参数表呢？头文件 `<inc/stdarg.h>` 中包含一组宏定义，对如何遍历参数表进行了定义（该头文件的实现因不同的机器而不同，但提供的接口是一致的）

- **`va_list`** 类型用于声明一个变量，变量 `ap`（argument pointer，参数指针）将依次引用各参数，宏 **`va_start`** 将 `ap` 初始化为指向第一个无名参数的指针；
- 在使用 `ap` 之前，宏 **`va_start`** 必须被调用一次；
- 参数表必须至少包括一个有名参数（例如这里的 `fmt`，它是第一个有名参数，同时也是最后一个有名参数，其后就是无名参数了），宏 **`va_start`** 将最后一个有名参数作为起点；
- 每次调用 **`va_arg`** 该函数都将返回一个参数，并将 `ap` 指向下一个参数。宏 **`va_arg`** 使用一个类型名来决定返回的对象类型、指针移动的步长；
- 最后，必须在函数返回前调用宏 **`va_end`**，以完成一些必要的清理工作。

函数的参数实际上都是存放在内存的堆栈中的，**函数参数从右向左依次入栈**（由于内存栈的增长方向是从高地址到低地址，因此参数表前面的有名参数在堆栈的较低地址处），每个参数根据参数类型分配相应大小的栈空间。使用 **`va_start`** 宏初始化 `ap` 之后，`ap` 就指向第一个可变参数。其后我们就可以通过调用 **`va_arg`** 宏一次读取之后的可变参数。

![cprintf-ap](images/cprintf-ap.png)

```c
int vcprintf(const char *fmt, va_list ap)
{
    int cnt = 0;

    vprintfmt((void*)putch, &cnt, fmt, ap);
    return cnt;
}
```

函数 `vprintfmt` 各参数依次为：

- 函数指针，这里指向 putch，将一个字符输出在屏幕上
- 输出的字符数
- 格式化字符串指针
- 可变参数指针

```c
static void putch(int ch, int *cnt)
{
    cputchar(ch);
    *cnt++;
}
```

`ch` 代表要输出的字符，`int` 类型变量 32 位，而一个 ASCII 字符只需要 8 位，因此 `int` 类型的低 8 位表示字符对应的 ASCII 码，而第 8 到 15 位表示输出字符的格式（高 16 位是没有用的）；`cnt` 指向一个 `int` 变量，每次往屏幕上输出一个字符就加 1（记录输出字符的个数）

为了在屏幕上输出一个字符，依次调用函数 `putch -> cputchar -> cons_putc -> lpt_putc -> cga_putc`

- `lpt_putc` 做一些输出字符前的准备工作（硬件初始化）
- `cga_putc` 在屏幕上打印一个字符，接受 `int` 类型的参数，没有返回值

【TODO】需要查看 `vprintfmt` 是怎么实现的？

### 附录 2：大端和小端

> 程序员的自我修养——链接、装载与库 附录 A.1  字节序（Byte Order）

在不同的计算机体系结构中，对于数据（比特、字节、字）等的存储和传输机制有所不同，因而引发了计算机领域中一个潜在但是又重要的问题，即通信双方交流的信息单元应该以怎样的顺序进行传送。目前在各种体系的计算机中通常采用的字节存储机制主要有两种：大端（big-endian）和小端（little-endian）。

首先我们需要理解两个概念：`MSB`（Most Significant Bit/Byte）最重要的位或最重要的字节，对应的，`LSB`（Least Significant Bit/Byte）最不重要的位或最不重要的字节

比如对于一个十六进制整数 `0x12345678`，`0x12` 就是 `MSB`，`0x78` 就是 `LSB`。对于 `0x78` 这个字节，二进制表示为 `01111000`，最左边的 `0` 就是 `MSB`，最右边的 `0` 就是 `LSB`

- 大端（big-endian）规定：`MSB` 在存储时放在低地址，在传输时 `MSB` 放在流的开始；`LSB` 在存储时放在高地址，在传输时 `LSB` 放在流的末尾
- 小端（little-endian）规定：`MSB` 在存储时放在高地址，在传输时 `MSB` 放在流的末尾；`LSB` 在存储时放在低地址，在传输时 `LSB` 放在流的开始

### 附录 3：`bootloader` 实模式切换到保护模式

```c
.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
  cld                         # String operations increment

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
  movw    %ax,%ds             # -> Data Segment
  movw    %ax,%es             # -> Extra Segment
  movw    %ax,%ss             # -> Stack Segment
```

`.code16` 表示为 16 位的实模式，`cli` 表示屏蔽系统中断，`cld` 置 DF (Direction Flag) 标识位为 0，表示内存地址向高地址增加，之后清空 DS 、ES 、SS 等段寄存器中的内容为 0。

```c
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  # 表示从0x64端口读取一个字节的数据存入al寄存器中，0x64作为状态寄存器，
  # 保存了当前状态，判断读取的数据位1（索引从0开始）是否等于1，如果为1则说明
  # 输入缓冲器满（0x60/64口有给8042的数据）（注：testb测试字节，与操作）
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  # 表示写8042的输出端口P2，将al的数据写入0x64端口
  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  # 写入P2，A20 Gate置为1，至此就开通了A20地址线
  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60
```

Intel 推出 x86 架构已近 30 年，刚开始推出的 8086 处理器是一款 16 位的处理器，它标识着 x86 架构的诞生，这种 16 位处理器的数据总线是 16 位的，而地址总线是 20 位的，最多可以寻址 1M 的地址空间。这里有一个为难的问题了，20 根地址总线，所以可以访问的地址是 `2^20 = 1MB`，但由于是 16 位地址模式，能够表示的地址范围是 0-64KB，为了在 8086 下能够访问 1MB 内存，Intel 采取了分段的模式，即 16 位段基地址，16 位偏移。但这个方式有一个问题，其最大的访问空间为 `0xFFFF` : `0xFFFF = 0x10FFEF = 1MB + 64KB - 16Bytes`，8086 只有 20 根地址线，如果访问 `100000h - 10FFEFh` 之间的内存单元，则必须有第 21 根地址线。因此，设置的机制为，当程序员给出超过 1MB（`100000h - 10FFEFh`）的地址时，系统不会认为其访问越界而产生异常，而是自动重新从 0 开始计算。之后的 80286 处理器也是 16 位，但地址总线有 24 位，而且从 80286 开始 CPU 演变出两种工作模式：实模式和保护模式。在实模式下，80286 和其后续系统所表现的行为应该和 8086 所表现的完全一样（向后兼容），但是，80286 芯片却存在一个 Bug：如果程序员访问 `100000h - 10FFEFh` 之间的内存单元，系统会实际访问这块内存，而不是重新从 0 开始。为了解决这个问题，IBM 使用键盘控制器上剩余的一些输出线来管理第 21 根地址线，即 A20 Gate。如果 A20 Gate 被打开, 则当程序员给出 `100000h - 10FFEFh` 之间的地址时，系统将真正访问这块内存区域；如果 A20 Gate 被禁止，则当程序员给出 `100000h - 10FFEFh` 之间的地址的时候,系统仍然使用 8086 的方式。

从 80286 开始，系统出现了一种新的机制，被称为保护模式。那为什么进入保护模式一定要打开 A20 呢，它对保护模式有什么影响？如果 A20 Gate 被禁止，对于 80286 来说，其地址为 24bit，其地址表示为 `EFFFFF`；对于 80386 极其随后的 32-bit 芯片来说，其地址表示为 `FFEFFFFF`。这种表示的意思是，如果 A20 Gate 被禁止，则其第 20-bit 在 CPU 做地址访问的时候是无效的，永远只能被作为 0；如果 A20 Gate 被打开，则其第 20-bit 是有效的，其值既可以为 0，也可以为 1。

至此，我们跟踪历史，明晰了当从实模式切换至保护模式时需要将 A20 Gate 打开，上述代码实现了如何打开 A20 地址线。

```c
  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses
  # identical to their physical addresses, so that the
  # effective memory map does not change during the switch.
  lgdt    gdtdesc    # 将GDT表的首地址加载到GDTR

# Bootstrap GDT
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULL                                # null seg
  SEG(STA_X|STA_R, 0x0, 0xffffffff)       # code seg
  SEG(STA_W, 0x0, 0xffffffff)             # data seg

gdtdesc:
  .word   0x17                            # sizeof(gdt) - 1
  .long   gdt                             # address gdt
```

定义 GDT 全局描述符表。首先我们可以看到 GDT 表的存放位置是 4 字节对齐的，也就是说 GDT 表的物理首地址是 4 的倍数。然后 `gdt` 标识了 3 个 GDT 表项，使用宏 `SEG_NULL` 和 `SEG`。

```c
#define SEG_NULL                        \
    .word 0, 0;                         \
    .byte 0, 0, 0, 0
#define SEG(type,base,lim)              \
    .word (((lim) >> 12) & 0xffff), ((base) & 0xffff);  \
    .byte (((base) >> 16) & 0xff), (0x90 | (type)),     \
        (0xC0 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)
```

`SEG_NULL` 定义连续 8 个值为 0 的字节，这就表示一个空的 GDT 表项。`SEG` 宏 `type` 表示段属性，`base` 表示段基址，`lim` 则表示段长的界限，给出这三个参数就可以用这个宏来定义一个 GDT 表项（具体含义略过）。

```c
.set CR0_PE_ON,      0x1         # protected mode enable flag

  movl    %cr0, %eax
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0
```

使能保护模式，将一个特定的寄存器，系统寄存器 `CR0` 其第 0 号位置成 1。这里的 `orl` 是“按位或”操作指令，常用来测试两个操作数是否同时为0，或者用来置位某些位，置位就是将一个位数据设置为 1。

```c
.set PROT_MODE_CSEG, 0x8         # kernel code segment selector

  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
```

最后，用一个跳转指令让系统开始使用 32 位的寻址模式。可以看到最后一句长跳转指令实际上是在系统进入保护模式后执行的。于是在这里 `$PROT_MODE_CSEG` ，代表的是段选择子，从前面的 GDT 表中可以看到基地址是 `0x0`，而偏移地址是`$protcseg`，`$protcseg` 实际上代表的是接下来指令的链接地址，也就是可执行程序在内存中的虚拟地址，只是刚好在这里编译生成的可执行程序 `boot` 的加载地址与链接地址是一致的，于是 `$protcseg` 就相当于指令在内存中存放位置的物理地址，所以这个长跳转可以成功的跳转到下一条指令的位置。

```c
.set PROT_MODE_DSEG, 0x10         # kernel data segment selector

  .code32                         # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS
  movw    %ax, %ss                # -> SS: Stack Segment

  # Set up the stack pointer and call into C.
  movl    $start, %esp
  call bootmain
```

在进入保护模式后，程序在重新对段寄存器进行了初始化后，设置栈的指针并转入 C 函数 `bootmain` 执行（`ebp <- 0`、`esp <- 0x7c00` 栈 从高地址向低地址顺序存放 ）。可以看到，在 `call bootmain` 之后便是一个无限循环的跳转指令，之所以是无限循环就是这个函数调用永远都不会有返回的可能性，这句程序仅仅只是让整个代码看起来有完整性。

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
